import 'dart:convert';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/logging/safe_log.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';

/// Wraps a [TaskRepository] so the role-filtered task list and each task detail
/// are cached after a successful read and served from cache when a later read
/// fails (for example while offline). Mutations always pass straight through to
/// the backend; nothing is written from cache, so no non-idempotent RPC is ever
/// replayed from local state.
class CachingTaskRepository implements TaskRepository {
  const CachingTaskRepository({
    required TaskRepository inner,
    required LocalCacheStore store,
  })  : _inner = inner,
        _store = store;

  static const listKeyPrefix = '${privateCachePrefix}tasks:';
  static const detailKeyPrefix = '${privateCachePrefix}task_detail:';

  final TaskRepository _inner;
  final LocalCacheStore _store;

  static String listKeyFor(String farmId) => '$listKeyPrefix$farmId';
  static String detailKeyFor(String taskId) => '$detailKeyPrefix$taskId';

  @override
  Future<List<FarmTask>> listForFarm(String farmId) async {
    try {
      final tasks = await _inner.listForFarm(farmId);
      await _store.write(
        listKeyFor(farmId),
        jsonEncode(tasks.map((task) => task.toJson()).toList(growable: false)),
      );
      return tasks;
    } catch (error) {
      final cached = await _readList(farmId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<TaskDetails> loadDetails(String taskId) async {
    try {
      final details = await _inner.loadDetails(taskId);
      await _store.write(
        detailKeyFor(taskId),
        jsonEncode(details.toCacheJson()),
      );
      return details;
    } catch (error) {
      final cached = await _readDetail(taskId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<FarmTask>?> _readList(String farmId) async {
    final raw = await _store.read(listKeyFor(farmId));
    if (raw == null) return null;
    try {
      final rows = jsonDecode(raw) as List<Object?>;
      return List<FarmTask>.unmodifiable(
        rows.map(
          (row) => FarmTask.fromJson(Map<String, Object?>.from(row! as Map)),
        ),
      );
    } catch (error) {
      SafeLog.event(
        'task_list_cache_dropped',
        data: <String, Object?>{'error': error.runtimeType},
      );
      await _store.remove(listKeyFor(farmId));
      return null;
    }
  }

  Future<TaskDetails?> _readDetail(String taskId) async {
    final raw = await _store.read(detailKeyFor(taskId));
    if (raw == null) return null;
    try {
      return TaskDetails.fromCacheJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    } catch (error) {
      SafeLog.event(
        'task_detail_cache_dropped',
        data: <String, Object?>{'error': error.runtimeType},
      );
      await _store.remove(detailKeyFor(taskId));
      return null;
    }
  }

  @override
  Future<List<TaskAssignee>> listAssignableMembers(String farmId) =>
      _inner.listAssignableMembers(farmId);

  @override
  Future<String> create(TaskDraft draft, {String? opId}) =>
      _inner.create(draft, opId: opId);

  @override
  Future<void> setAssignments(String taskId, List<String> profileIds) =>
      _inner.setAssignments(taskId, profileIds);

  @override
  Future<void> start(String taskId, {String? note}) =>
      _inner.start(taskId, note: note);

  @override
  Future<void> complete(
    String taskId, {
    String? note,
    bool requiresEngineerReview = false,
  }) =>
      _inner.complete(
        taskId,
        note: note,
        requiresEngineerReview: requiresEngineerReview,
      );

  @override
  Future<String> addPhoto(TaskEvidenceRegistration registration) =>
      _inner.addPhoto(registration);
}
