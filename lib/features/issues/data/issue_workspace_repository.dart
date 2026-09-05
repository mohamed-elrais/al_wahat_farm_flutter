import 'dart:async';
import 'dart:convert';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/logging/safe_log.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_workspace.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_photo.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_photo.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract interface class IssueWorkspaceRepository {
  Future<List<TreeIssueSummary>> listSummaries(
    String farmId, {
    IssueSummaryFilter filter = const IssueSummaryFilter(),
  });
  Future<List<TreeIssueSummary>> listManagerIssues(String farmId);
  Future<List<TreeIssueOccurrence>> listTreeHistory(String treeId);
  Future<TreeIssueDetails> loadDetails(String issueId);
  Future<List<TaskTreeIssueWork>> listTaskWork(String taskId);

  /// Claims are deliberately online-only because the backend arbitrates one
  /// active claimant atomically.
  Future<String> claim(String issueId);
  Future<String> assign({
    required String issueId,
    required String assigneeProfileId,
    required bool requiresEngineerReview,
  });

  Future<void> changeSeverity(
    String issueId,
    IssueSeverity severity, {
    String? notes,
    String? opId,
  });
  Future<void> dismiss(String issueId, String notes, {String? opId});
  Future<void> resolve({
    required String taskId,
    required String issueId,
    String? notes,
    String? photoStoragePath,
    PreparedIssuePhoto? preparedPhoto,
    String? userId,
    String? farmId,
    String? opId,
  });
  Future<void> unableToFix({
    required String taskId,
    required String issueId,
    required TreeIssueUnableReason reason,
    String? notes,
    String? photoStoragePath,
    PreparedIssuePhoto? preparedPhoto,
    String? userId,
    String? farmId,
    String? opId,
  });
}

class SupabaseIssueWorkspaceRepository implements IssueWorkspaceRepository {
  const SupabaseIssueWorkspaceRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<TreeIssueOccurrence>> listTreeHistory(String treeId) =>
      _guard(() async {
        final result = await _client
            .from('tree_issues')
            .select(
              'id, issue_type, severity, status, reported_at, resolved_at',
            )
            .eq('tree_id', treeId)
            .order('reported_at', ascending: false);
        return result.map(TreeIssueOccurrence.fromJson).toList(growable: false);
      });

  @override
  Future<TreeIssueDetails> loadDetails(String issueId) => _guard(() async {
        final result = await _client.rpc<Object?>(
          'get_tree_issue_details',
          params: <String, Object?>{'p_tree_issue_id': issueId},
        );
        return TreeIssueDetails.fromJson(
          Map<String, Object?>.from(result! as Map),
        );
      });

  @override
  Future<List<TaskTreeIssueWork>> listTaskWork(String taskId) =>
      _guard(() async {
        final result = await _client
            .from('task_tree_issues')
            .select(
              'task_id, tree_issue_id, work_state, resolution_photo_required, '
              'resolution_notes, unable_reason, '
              'tree_issues!inner(tree_id, issue_type, severity, status)',
            )
            .eq('task_id', taskId)
            .order('created_at');
        return result.map(TaskTreeIssueWork.fromJson).toList(growable: false);
      });

  @override
  Future<List<TreeIssueSummary>> listSummaries(
    String farmId, {
    IssueSummaryFilter filter = const IssueSummaryFilter(),
  }) =>
      _guard(() async {
        final result = await _client.rpc<Object?>(
          'list_tree_issue_summaries',
          params: <String, Object?>{
            'p_farm_id': farmId,
            'p_issue_type': filter.type?.wireValue,
            'p_severity': filter.severity?.name,
            'p_only_unclaimed': filter.onlyUnclaimed,
          },
        );
        return (result! as List<Object?>)
            .map((row) => TreeIssueSummary.fromJson(
                  Map<String, Object?>.from(row! as Map),
                ))
            .toList(growable: false);
      });

  @override
  Future<List<TreeIssueSummary>> listManagerIssues(String farmId) =>
      _guard(() async {
        final result = await _client.rpc<Object?>(
          'list_manager_tree_issues',
          params: <String, Object?>{'p_farm_id': farmId},
        );
        return (result! as List<Object?>)
            .map((row) => TreeIssueSummary.fromJson(
                  Map<String, Object?>.from(row! as Map),
                ))
            .toList(growable: false);
      });

  @override
  Future<String> claim(String issueId) => _guard(() async {
        final result = await _client.rpc<Object?>(
          'claim_tree_issue',
          params: <String, Object?>{'p_tree_issue_id': issueId},
        );
        return result! as String;
      });

  @override
  Future<String> assign({
    required String issueId,
    required String assigneeProfileId,
    required bool requiresEngineerReview,
  }) =>
      _guard(() async {
        final result = await _client.rpc<Object?>(
          'assign_tree_issue',
          params: <String, Object?>{
            'p_tree_issue_id': issueId,
            'p_assignee_profile_id': assigneeProfileId,
            'p_requires_engineer_review': requiresEngineerReview,
          },
        );
        return result! as String;
      });

  @override
  Future<void> changeSeverity(
    String issueId,
    IssueSeverity severity, {
    String? notes,
    String? opId,
  }) =>
      _voidRpc('change_tree_issue_severity', <String, Object?>{
        'p_tree_issue_id': issueId,
        'p_severity': severity.name,
        'p_notes': _optional(notes),
        if (opId != null) 'p_op_id': opId,
      });

  @override
  Future<void> dismiss(String issueId, String notes, {String? opId}) =>
      _voidRpc('dismiss_tree_issue', <String, Object?>{
        'p_tree_issue_id': issueId,
        'p_notes': notes.trim(),
        if (opId != null) 'p_op_id': opId,
      });

  @override
  Future<void> resolve({
    required String taskId,
    required String issueId,
    String? notes,
    String? photoStoragePath,
    PreparedIssuePhoto? preparedPhoto,
    String? userId,
    String? farmId,
    String? opId,
  }) =>
      _voidRpc('resolve_tree_issue', <String, Object?>{
        'p_task_id': taskId,
        'p_tree_issue_id': issueId,
        'p_notes': _optional(notes),
        'p_photo_storage_path': photoStoragePath,
        if (opId != null) 'p_op_id': opId,
      });

  @override
  Future<void> unableToFix({
    required String taskId,
    required String issueId,
    required TreeIssueUnableReason reason,
    String? notes,
    String? photoStoragePath,
    PreparedIssuePhoto? preparedPhoto,
    String? userId,
    String? farmId,
    String? opId,
  }) =>
      _voidRpc('mark_tree_issue_unable_to_fix', <String, Object?>{
        'p_task_id': taskId,
        'p_tree_issue_id': issueId,
        'p_reason': reason.wireValue,
        'p_notes': _optional(notes),
        'p_photo_storage_path': photoStoragePath,
        if (opId != null) 'p_op_id': opId,
      });

  Future<void> _voidRpc(String name, Map<String, Object?> params) =>
      _guard(() async {
        await _client.rpc<Object?>(name, params: params);
      });
}

/// Adds private read caching and queues safe, idempotent field mutations. The
/// online-only claim method never enters the outbox.
class OfflineIssueWorkspaceRepository implements IssueWorkspaceRepository {
  OfflineIssueWorkspaceRepository({
    required IssueWorkspaceRepository inner,
    required LocalCacheStore cache,
    required OutboxStore outbox,
    required ConnectivityController connectivity,
    required SyncEngine syncEngine,
    required IssuePhotoStorage photoStorage,
    required PendingPhotoStore pendingPhotos,
    required String userId,
    Uuid uuid = const Uuid(),
    int Function()? clock,
  })  : _inner = inner,
        _cache = cache,
        _outbox = outbox,
        _connectivity = connectivity,
        _syncEngine = syncEngine,
        _photoStorage = photoStorage,
        _pendingPhotos = pendingPhotos,
        _userId = userId,
        _uuid = uuid,
        _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  static const cachePrefix = '${privateCachePrefix}issue_summaries:';
  static const taskWorkCachePrefix = '${privateCachePrefix}issue_task_work:';
  static const detailCachePrefix = '${privateCachePrefix}issue_detail:';
  static const treeHistoryCachePrefix =
      '${privateCachePrefix}issue_tree_history:';
  static const managerCachePrefix =
      '${privateCachePrefix}manager_issue_register:';

  final IssueWorkspaceRepository _inner;
  final LocalCacheStore _cache;
  final OutboxStore _outbox;
  final ConnectivityController _connectivity;
  final SyncEngine _syncEngine;
  final IssuePhotoStorage _photoStorage;
  final PendingPhotoStore _pendingPhotos;
  final String _userId;
  final Uuid _uuid;
  final int Function() _clock;

  static String cacheKey(String farmId) => '$cachePrefix$farmId';
  static String managerCacheKey(String farmId) => '$managerCachePrefix$farmId';

  @override
  Future<List<TreeIssueOccurrence>> listTreeHistory(String treeId) async {
    final key = '$treeHistoryCachePrefix$treeId';
    try {
      final history = await _inner.listTreeHistory(treeId);
      await _cache.write(
        key,
        jsonEncode(
            history.map((item) => item.toJson()).toList(growable: false)),
      );
      return history;
    } catch (_) {
      final raw = await _cache.read(key);
      if (raw == null) rethrow;
      try {
        return (jsonDecode(raw) as List<Object?>)
            .map((item) => TreeIssueOccurrence.fromJson(
                  Map<String, Object?>.from(item! as Map),
                ))
            .toList(growable: false);
      } catch (error) {
        SafeLog.event(
          'issue_tree_history_cache_dropped',
          data: <String, Object?>{'error': error.runtimeType},
        );
        await _cache.remove(key);
        rethrow;
      }
    }
  }

  @override
  Future<TreeIssueDetails> loadDetails(String issueId) async {
    final key = '$detailCachePrefix$issueId';
    try {
      final details = await _inner.loadDetails(issueId);
      await _cache.write(key, jsonEncode(details.toJson()));
      return details;
    } catch (_) {
      final raw = await _cache.read(key);
      if (raw == null) rethrow;
      try {
        return TreeIssueDetails.fromJson(
          Map<String, Object?>.from(jsonDecode(raw) as Map),
        );
      } catch (error) {
        SafeLog.event(
          'issue_detail_cache_dropped',
          data: <String, Object?>{'error': error.runtimeType},
        );
        await _cache.remove(key);
        rethrow;
      }
    }
  }

  @override
  Future<List<TaskTreeIssueWork>> listTaskWork(String taskId) async {
    final key = '$taskWorkCachePrefix$taskId';
    try {
      final work = await _inner.listTaskWork(taskId);
      await _cache.write(
        key,
        jsonEncode(work.map((item) => item.toJson()).toList(growable: false)),
      );
      return work;
    } catch (_) {
      final raw = await _cache.read(key);
      if (raw == null) rethrow;
      return (jsonDecode(raw) as List<Object?>)
          .map((item) => TaskTreeIssueWork.fromJson(
                Map<String, Object?>.from(item! as Map),
              ))
          .toList(growable: false);
    }
  }

  @override
  Future<List<TreeIssueSummary>> listSummaries(
    String farmId, {
    IssueSummaryFilter filter = const IssueSummaryFilter(),
  }) async {
    try {
      final all = await _inner.listSummaries(farmId);
      await _cache.write(
        cacheKey(farmId),
        jsonEncode(all.map((item) => item.toJson()).toList(growable: false)),
      );
      return _filter(all, filter);
    } catch (_) {
      final raw = await _cache.read(cacheKey(farmId));
      if (raw == null) rethrow;
      try {
        final cached = (jsonDecode(raw) as List<Object?>)
            .map((row) => TreeIssueSummary.fromJson(
                  Map<String, Object?>.from(row! as Map),
                ))
            .toList(growable: false);
        return _filter(cached, filter);
      } catch (error) {
        SafeLog.event('issue_summary_cache_dropped',
            data: <String, Object?>{'error': error.runtimeType});
        await _cache.remove(cacheKey(farmId));
        rethrow;
      }
    }
  }

  @override
  Future<List<TreeIssueSummary>> listManagerIssues(String farmId) async {
    final key = managerCacheKey(farmId);
    try {
      final issues = await _inner.listManagerIssues(farmId);
      await _cache.write(
        key,
        jsonEncode(issues.map((item) => item.toJson()).toList(growable: false)),
      );
      return issues;
    } catch (_) {
      final raw = await _cache.read(key);
      if (raw == null) rethrow;
      try {
        return (jsonDecode(raw) as List<Object?>)
            .map((row) => TreeIssueSummary.fromJson(
                  Map<String, Object?>.from(row! as Map),
                ))
            .toList(growable: false);
      } catch (error) {
        SafeLog.event(
          'manager_issue_register_cache_dropped',
          data: <String, Object?>{'error': error.runtimeType},
        );
        await _cache.remove(key);
        rethrow;
      }
    }
  }

  @override
  Future<String> claim(String issueId) async {
    if (_connectivity.isOffline) {
      throw const OperationFailure(
        OperationFailureKind.offline,
        'Issue claiming requires an internet connection.',
      );
    }
    return _inner.claim(issueId);
  }

  @override
  Future<String> assign({
    required String issueId,
    required String assigneeProfileId,
    required bool requiresEngineerReview,
  }) async {
    if (_connectivity.isOffline) {
      throw const OperationFailure(
        OperationFailureKind.offline,
        'Issue assignment requires an internet connection.',
      );
    }
    return _inner.assign(
      issueId: issueId,
      assigneeProfileId: assigneeProfileId,
      requiresEngineerReview: requiresEngineerReview,
    );
  }

  @override
  Future<void> changeSeverity(
    String issueId,
    IssueSeverity severity, {
    String? notes,
    String? opId,
  }) =>
      _queueOrRun(
        kind: PendingMutationKind.changeIssueSeverity,
        payload: <String, Object?>{
          'issueId': issueId,
          'severity': severity.name,
          'notes': notes,
        },
        online: () => _inner.changeSeverity(issueId, severity, notes: notes),
      );

  @override
  Future<void> dismiss(String issueId, String notes, {String? opId}) =>
      _queueOrRun(
        kind: PendingMutationKind.dismissIssue,
        payload: <String, Object?>{'issueId': issueId, 'notes': notes},
        online: () => _inner.dismiss(issueId, notes),
      );

  @override
  Future<void> resolve({
    required String taskId,
    required String issueId,
    String? notes,
    String? photoStoragePath,
    PreparedIssuePhoto? preparedPhoto,
    String? userId,
    String? farmId,
    String? opId,
  }) =>
      _photoQueueOrRun(
        preparedPhoto: preparedPhoto,
        userId: userId ?? _userId,
        farmId: farmId,
        taskId: taskId,
        kind: PendingMutationKind.resolveIssue,
        payload: <String, Object?>{
          'taskId': taskId,
          'issueId': issueId,
          'notes': notes,
          'photoStoragePath': photoStoragePath,
        },
        online: (uploadedPath) => _inner.resolve(
          taskId: taskId,
          issueId: issueId,
          notes: notes,
          photoStoragePath: uploadedPath,
        ),
        optimistic: () => _patchTaskWork(
          taskId,
          issueId,
          workState: 'resolution_submitted',
          notes: notes,
        ),
      );

  Future<void> _photoQueueOrRun({
    required PreparedIssuePhoto? preparedPhoto,
    required String userId,
    required String? farmId,
    required String taskId,
    required PendingMutationKind kind,
    required Map<String, Object?> payload,
    required Future<void> Function(String? uploadedPath) online,
    Future<void> Function()? optimistic,
  }) async {
    if (_connectivity.isOnline) {
      var uploadedPath = payload['photoStoragePath'] as String?;
      if (preparedPhoto != null) {
        if (farmId == null) {
          throw const OperationFailure(
            OperationFailureKind.invalidInput,
            'Farm identity is required for resolution evidence.',
          );
        }
        uploadedPath = await _photoStorage.upload(
          userId: userId,
          farmId: farmId,
          taskId: taskId,
          photo: preparedPhoto,
        );
      }
      try {
        await online(uploadedPath);
        await optimistic?.call();
        return;
      } on OperationFailure catch (error) {
        if (error.kind != OperationFailureKind.offline) rethrow;
      }
    }
    if (preparedPhoto != null && farmId == null) {
      throw const OperationFailure(
        OperationFailureKind.invalidInput,
        'Farm identity is required for offline resolution evidence.',
      );
    }
    final opId = _uuid.v4();
    if (preparedPhoto != null) {
      await _pendingPhotos.put(PendingPhoto(
        opId: opId,
        taskId: taskId,
        userId: userId,
        farmId: farmId!,
        photoType: 'after',
        filename: preparedPhoto.filename,
        contentType: preparedPhoto.contentType,
        bytes: preparedPhoto.bytes,
        createdAt: _clock(),
      ));
      payload['hasPendingPhoto'] = true;
    }
    await _outbox.enqueue(PendingMutation(
      opId: opId,
      kind: kind,
      payload: payload,
      createdAt: _clock(),
    ));
    await optimistic?.call();
    unawaited(_syncEngine.sync());
  }

  @override
  Future<void> unableToFix({
    required String taskId,
    required String issueId,
    required TreeIssueUnableReason reason,
    String? notes,
    String? photoStoragePath,
    PreparedIssuePhoto? preparedPhoto,
    String? userId,
    String? farmId,
    String? opId,
  }) =>
      _photoQueueOrRun(
        preparedPhoto: preparedPhoto,
        userId: userId ?? _userId,
        farmId: farmId,
        taskId: taskId,
        kind: PendingMutationKind.unableToFixIssue,
        payload: <String, Object?>{
          'taskId': taskId,
          'issueId': issueId,
          'reason': reason.wireValue,
          'notes': notes,
          'photoStoragePath': photoStoragePath,
        },
        online: (uploadedPath) => _inner.unableToFix(
          taskId: taskId,
          issueId: issueId,
          reason: reason,
          notes: notes,
          photoStoragePath: uploadedPath,
        ),
        optimistic: () => _patchTaskWork(
          taskId,
          issueId,
          workState: 'unable_to_fix',
          notes: notes,
          unableReason: reason.wireValue,
        ),
      );

  Future<void> _queueOrRun({
    required PendingMutationKind kind,
    required Map<String, Object?> payload,
    required Future<void> Function() online,
    Future<void> Function()? optimistic,
  }) async {
    if (_connectivity.isOnline) {
      try {
        await online();
        await optimistic?.call();
        return;
      } on OperationFailure catch (error) {
        if (error.kind != OperationFailureKind.offline) rethrow;
      }
    }
    await _outbox.enqueue(PendingMutation(
      opId: _uuid.v4(),
      kind: kind,
      payload: payload,
      createdAt: _clock(),
    ));
    await optimistic?.call();
    unawaited(_syncEngine.sync());
  }

  Future<void> _patchTaskWork(
    String taskId,
    String issueId, {
    required String workState,
    String? notes,
    String? unableReason,
  }) async {
    final key = '$taskWorkCachePrefix$taskId';
    final raw = await _cache.read(key);
    if (raw == null) return;
    final rows = (jsonDecode(raw) as List<Object?>)
        .map((item) => Map<String, Object?>.from(item! as Map))
        .toList(growable: false);
    for (final row in rows) {
      if (row['tree_issue_id'] != issueId) continue;
      row['work_state'] = workState;
      row['resolution_notes'] = notes;
      row['unable_reason'] = unableReason;
    }
    await _cache.write(key, jsonEncode(rows));
  }

  List<TreeIssueSummary> _filter(
    List<TreeIssueSummary> items,
    IssueSummaryFilter filter,
  ) =>
      items
          .where((item) =>
              (filter.type == null || item.type == filter.type) &&
              (filter.severity == null || item.severity == filter.severity) &&
              (!filter.onlyUnclaimed || !item.isClaimed))
          .toList(growable: false);
}

class IssueWorkspaceMutationExecutor implements MutationExecutor {
  const IssueWorkspaceMutationExecutor(
    this._repository, {
    required IssuePhotoStorage photoStorage,
    required PendingPhotoStore pendingPhotos,
  })  : _photoStorage = photoStorage,
        _pendingPhotos = pendingPhotos;

  final IssueWorkspaceRepository _repository;
  final IssuePhotoStorage _photoStorage;
  final PendingPhotoStore _pendingPhotos;

  @override
  Future<void> execute(PendingMutation mutation) => switch (mutation.kind) {
        PendingMutationKind.changeIssueSeverity => _repository.changeSeverity(
            mutation.payload['issueId']! as String,
            IssueSeverity.fromJson(mutation.payload['severity']! as String),
            notes: mutation.payload['notes'] as String?,
            opId: mutation.opId,
          ),
        PendingMutationKind.dismissIssue => _repository.dismiss(
            mutation.payload['issueId']! as String,
            mutation.payload['notes']! as String,
            opId: mutation.opId,
          ),
        PendingMutationKind.resolveIssue => _resolve(mutation),
        PendingMutationKind.unableToFixIssue => _unableToFix(mutation),
        _ => throw StateError(
            'IssueWorkspaceMutationExecutor cannot run ${mutation.kind}',
          ),
      };

  Future<void> _resolve(PendingMutation mutation) async {
    final path = await _uploadedPath(mutation);
    await _repository.resolve(
      taskId: mutation.payload['taskId']! as String,
      issueId: mutation.payload['issueId']! as String,
      notes: mutation.payload['notes'] as String?,
      photoStoragePath: path,
      opId: mutation.opId,
    );
    await _pendingPhotos.delete(mutation.opId);
  }

  Future<void> _unableToFix(PendingMutation mutation) async {
    final path = await _uploadedPath(mutation);
    await _repository.unableToFix(
      taskId: mutation.payload['taskId']! as String,
      issueId: mutation.payload['issueId']! as String,
      reason: TreeIssueUnableReason.fromWire(
        mutation.payload['reason']! as String,
      ),
      notes: mutation.payload['notes'] as String?,
      photoStoragePath: path,
      opId: mutation.opId,
    );
    await _pendingPhotos.delete(mutation.opId);
  }

  Future<String?> _uploadedPath(PendingMutation mutation) async {
    var path = mutation.payload['photoStoragePath'] as String?;
    final pending = await _pendingPhotos.get(mutation.opId);
    if (pending == null) return path;
    path = pending.uploadedPath;
    if (path == null) {
      path = await _photoStorage.upload(
        userId: pending.userId,
        farmId: pending.farmId,
        taskId: pending.taskId,
        photo: PreparedIssuePhoto(
          bytes: pending.bytes,
          filename: pending.filename,
          contentType: pending.contentType,
        ),
      );
      await _pendingPhotos.markUploaded(mutation.opId, path);
    }
    return path;
  }
}

Future<T> _guard<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on PostgrestException catch (error) {
    throw switch (error.code) {
      '42501' => OperationFailure(OperationFailureKind.authorization,
          'Your role is not authorized for this issue action.',
          cause: error),
      '23514' => OperationFailure(
          OperationFailureKind.invalidInput, error.message,
          cause: error),
      '23505' => OperationFailure(OperationFailureKind.conflict,
          'This issue was changed or claimed by another worker.',
          cause: error),
      'P0002' => OperationFailure(OperationFailureKind.notFound,
          'The issue, task, or tree could not be found.',
          cause: error),
      _ => OperationFailure(OperationFailureKind.unexpected,
          'The farm could not save this issue action.',
          cause: error),
    };
  }
}

String? _optional(String? value) {
  final result = value?.trim();
  return result == null || result.isEmpty ? null : result;
}
