import 'dart:async';
import 'dart:convert';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/logging/safe_log.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/caching_task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:uuid/uuid.dart';

/// Makes the naturally-idempotent task transitions (start / complete /
/// set-assignments) work offline: when there is no connectivity the mutation is
/// queued in the outbox and the cached task detail is patched optimistically, so
/// the worker sees the change immediately and it replays on reconnect. Offline
/// task creation is queued too — a provisional `local:` row is written to the
/// cached list (shown read-only until it syncs) and a `create_task` op replays
/// with its op id as `p_op_id` on reconnect. Reads flow through the inner
/// (caching) repository unchanged.
class OfflineTaskRepository implements TaskRepository {
  OfflineTaskRepository({
    required TaskRepository inner,
    required OutboxStore outbox,
    required ConnectivityController connectivity,
    required LocalCacheStore cache,
    required SyncEngine syncEngine,
    Uuid uuid = const Uuid(),
    int Function()? clock,
  })  : _inner = inner,
        _outbox = outbox,
        _connectivity = connectivity,
        _cache = cache,
        _syncEngine = syncEngine,
        _uuid = uuid,
        _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final TaskRepository _inner;
  final OutboxStore _outbox;
  final ConnectivityController _connectivity;
  final LocalCacheStore _cache;
  final SyncEngine _syncEngine;
  final Uuid _uuid;
  final int Function() _clock;

  // Reads are unchanged (offline reads come from the cache inside the inner
  // repository).
  @override
  Future<List<FarmTask>> listForFarm(String farmId) =>
      _inner.listForFarm(farmId);

  @override
  Future<TaskDetails> loadDetails(String taskId) => _inner.loadDetails(taskId);

  @override
  Future<List<TaskAssignee>> listAssignableMembers(String farmId) =>
      _inner.listAssignableMembers(farmId);

  @override
  Future<String> create(TaskDraft draft, {String? opId}) async {
    if (_connectivity.isOnline) {
      try {
        return await _inner.create(draft, opId: opId);
      } on OperationFailure catch (error) {
        // Only fall through to the queue when the failure is connectivity;
        // authorization / validation must surface to the caller.
        if (error.kind != OperationFailureKind.offline) rethrow;
      }
    }
    // Offline: validate up front (there is no backend to reject it), mint a
    // temp id sharing the outbox op id, show a provisional read-only row, and
    // queue the creation for replay.
    final validation = draft.validate();
    if (validation != null) {
      throw OperationFailure(OperationFailureKind.invalidInput, validation);
    }
    final op = _uuid.v4();
    final tempId = '$localTaskIdPrefix$op';
    await _writeProvisional(draft, tempId);
    await _outbox.enqueue(
      PendingMutation(
        opId: op,
        kind: PendingMutationKind.createTask,
        payload: <String, Object?>{'draft': draft.toJson()},
        createdAt: _clock(),
      ),
    );
    unawaited(_syncEngine.sync());
    return tempId;
  }

  @override
  Future<String> addPhoto(TaskEvidenceRegistration registration) =>
      _inner.addPhoto(registration);

  // The online path deliberately omits [opId] (direct calls stay
  // deploy-independent); the outbox mints its own op id, which the executor
  // sends as `p_op_id` on replay.
  @override
  Future<void> start(String taskId, {String? note, String? opId}) => _mutate(
        online: () => _inner.start(taskId, note: note),
        kind: PendingMutationKind.startTask,
        payload: <String, Object?>{'taskId': taskId, 'note': note},
        taskId: taskId,
        optimisticStatus: TaskStatus.inProgress,
      );

  @override
  Future<void> complete(
    String taskId, {
    String? note,
    bool requiresEngineerReview = false,
    String? opId,
  }) =>
      _mutate(
        online: () => _inner.complete(
          taskId,
          note: note,
          requiresEngineerReview: requiresEngineerReview,
        ),
        kind: PendingMutationKind.completeTask,
        payload: <String, Object?>{
          'taskId': taskId,
          'note': note,
          'requiresEngineerReview': requiresEngineerReview,
        },
        taskId: taskId,
        optimisticStatus: requiresEngineerReview
            ? TaskStatus.needsEngineerReview
            : TaskStatus.completed,
      );

  @override
  Future<void> setAssignments(
    String taskId,
    List<String> profileIds, {
    String? opId,
  }) =>
      _mutate(
        online: () => _inner.setAssignments(taskId, profileIds),
        kind: PendingMutationKind.setAssignments,
        payload: <String, Object?>{
          'taskId': taskId,
          'profileIds': profileIds,
        },
        taskId: taskId,
        optimisticStatus: null,
      );

  Future<void> _mutate({
    required Future<void> Function() online,
    required PendingMutationKind kind,
    required Map<String, Object?> payload,
    required String taskId,
    required TaskStatus? optimisticStatus,
  }) async {
    if (_connectivity.isOnline) {
      try {
        await online();
        return;
      } on OperationFailure catch (error) {
        // Only fall through to the queue when the failure is connectivity;
        // authorization / validation / conflict must surface to the caller.
        if (error.kind != OperationFailureKind.offline) rethrow;
      }
    }
    await _outbox.enqueue(
      PendingMutation(
        opId: _uuid.v4(),
        kind: kind,
        payload: payload,
        createdAt: _clock(),
      ),
    );
    if (optimisticStatus != null) {
      await _patchCachedStatus(taskId, optimisticStatus);
    }
    unawaited(_syncEngine.sync()); // no-op while offline; drains when online
  }

  /// Inserts a provisional task at the front of the cached list so the offline
  /// creation is visible immediately. The row carries the temp id and is shown
  /// read-only until the queued creation replays and a refresh brings the real
  /// task from the server.
  Future<void> _writeProvisional(TaskDraft draft, String tempId) async {
    final key = CachingTaskRepository.listKeyFor(draft.farmId);
    final rows = <Object?>[];
    final raw = await _cache.read(key);
    if (raw != null) {
      try {
        rows.addAll(jsonDecode(raw) as List<Object?>);
      } catch (_) {
        rows.clear(); // corrupt cache: start fresh with just the provisional row
      }
    }
    final now = DateTime.fromMillisecondsSinceEpoch(_clock());
    final task = FarmTask(
      id: tempId,
      farmId: draft.farmId,
      type: draft.type,
      title: draft.title.trim(),
      priority: draft.priority,
      status: draft.assigneeProfileIds.isEmpty
          ? TaskStatus.draft
          : TaskStatus.assigned,
      instructions: draft.instructions,
      requiresEngineerReview: draft.requiresEngineerReview,
      createdByProfileId: '',
      createdAt: now,
      updatedAt: now,
      sectionId: draft.sectionId,
      irrigationZoneId: draft.irrigationZoneId,
      treeId: draft.treeId,
      relatedTreeIssueId: draft.relatedTreeIssueId,
      description: draft.description,
      scheduledFor: draft.scheduledFor,
      plannedStartTime: draft.plannedStartTime,
      plannedDurationMinutes: draft.plannedDurationMinutes,
      dueAt: draft.dueAt,
    );
    rows.insert(0, task.toJson());
    await _cache.write(key, jsonEncode(rows));
  }

  /// Optimistically reflects a status change in the cached task detail so the
  /// detail screen updates immediately while offline. The list cache converges
  /// on the next successful refresh after sync.
  Future<void> _patchCachedStatus(String taskId, TaskStatus status) async {
    final key = CachingTaskRepository.detailKeyFor(taskId);
    final raw = await _cache.read(key);
    if (raw == null) return;
    try {
      final json = Map<String, Object?>.from(jsonDecode(raw) as Map);
      final task = Map<String, Object?>.from(json['task']! as Map);
      task['status'] = status.wireValue;
      json['task'] = task;
      await _cache.write(key, jsonEncode(json));
    } catch (error) {
      SafeLog.event('offline_status_patch_failed',
          data: <String, Object?>{'error': error.runtimeType});
    }
  }
}
