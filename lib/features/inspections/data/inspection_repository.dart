import 'dart:async';
import 'dart:convert';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_models.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_photo.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/caching_task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract interface class InspectionRepository {
  Future<InspectionCreationResult> create(
    InspectionCreationDraft draft, {
    String? opId,
  });
  Future<InspectionDetails> loadByTask(String taskId);
  Future<void> setStatus(
    String sessionId,
    InspectionSessionStatus status, {
    String? opId,
  });
  Future<void> takeOver(String sessionId, {String? opId});
  Future<void> saveStation(
    String sessionId,
    int stationIndex,
    List<InspectionTreeResult> results, {
    String? opId,
    Map<String, PreparedTaskEvidence> photos = const {},
    String? userId,
    String? farmId,
    String? taskId,
  });
  Future<void> submit(String sessionId, {String? note, String? opId});
}

class SupabaseInspectionRepository implements InspectionRepository {
  const SupabaseInspectionRepository(this._client);

  static const sessionColumns =
      'id, farm_id, section_id, task_id, inspector_profile_id, '
      'created_by_profile_id, starting_tree_id, status, route_version, '
      'total_stations, total_trees, inspected_trees, requires_issue_photo, '
      'revision, started_at, paused_at, submitted_at, created_at, updated_at';
  static const itemColumns =
      'id, session_id, tree_id, sequence_index, corridor_index, station_index, '
      'side, tree_code, row_number, tree_number, latitude, longitude, status, '
      'no_new_issue_found, notes, observed_at';
  static const observationColumns =
      'id, session_id, item_id, tree_issue_id, issue_type, outcome, '
      'observed_severity, severity_changed, notes, photo_storage_path, '
      'observed_at';

  final SupabaseClient _client;

  @override
  Future<InspectionCreationResult> create(
    InspectionCreationDraft draft, {
    String? opId,
  }) =>
      _guard(() async {
        final result = await _client.rpc<Object?>(
          'create_section_inspection',
          params: <String, Object?>{
            'p_section_id': draft.route.sectionId,
            'p_inspector_profile_id': draft.inspectorProfileId,
            'p_title': draft.title.trim(),
            'p_route': draft.route.toRpcRoute(),
            'p_scheduled_for': draft.scheduledFor == null
                ? null
                : _dateOnly(draft.scheduledFor!),
            'p_priority': draft.priority,
            'p_requires_engineer_review': draft.requiresEngineerReview,
            'p_requires_issue_photo': draft.requiresIssuePhoto,
            'p_route_version': draft.route.routeVersion,
            if (opId != null) 'p_op_id': opId,
          },
        );
        final rows = result! as List<Object?>;
        final row = Map<String, Object?>.from(rows.first! as Map);
        return InspectionCreationResult(
          sessionId: row['inspection_session_id']! as String,
          taskId: row['task_id']! as String,
        );
      });

  @override
  Future<InspectionDetails> loadByTask(String taskId) => _guard(() async {
        final sessionJson = await _client
            .from('inspection_sessions')
            .select(sessionColumns)
            .eq('task_id', taskId)
            .single();
        final itemsJson = await _client
            .from('inspection_session_items')
            .select(itemColumns)
            .eq('session_id', sessionJson['id']! as String)
            .order('sequence_index');
        final observationsJson = await _client
            .from('inspection_issue_observations')
            .select(observationColumns)
            .eq('session_id', sessionJson['id']! as String)
            .order('observed_at');
        return InspectionDetails(
          session: InspectionSession.fromJson(sessionJson),
          items: itemsJson
              .map(InspectionSessionItem.fromJson)
              .toList(growable: false),
          observations: observationsJson
              .map(InspectionStationObservation.fromJson)
              .toList(growable: false),
        );
      });

  @override
  Future<void> setStatus(
    String sessionId,
    InspectionSessionStatus status, {
    String? opId,
  }) =>
      _voidRpc('set_inspection_session_status', <String, Object?>{
        'p_session_id': sessionId,
        'p_status': status.wireValue,
        if (opId != null) 'p_op_id': opId,
      });

  @override
  Future<void> takeOver(String sessionId, {String? opId}) =>
      _voidRpc('take_over_inspection', <String, Object?>{
        'p_session_id': sessionId,
        if (opId != null) 'p_op_id': opId,
      });

  @override
  Future<void> saveStation(
    String sessionId,
    int stationIndex,
    List<InspectionTreeResult> results, {
    String? opId,
    Map<String, PreparedTaskEvidence> photos = const {},
    String? userId,
    String? farmId,
    String? taskId,
  }) =>
      _voidRpc('save_inspection_station', <String, Object?>{
        'p_session_id': sessionId,
        'p_station_index': stationIndex,
        'p_results':
            results.map((item) => item.toJson()).toList(growable: false),
        if (opId != null) 'p_op_id': opId,
      });

  @override
  Future<void> submit(String sessionId, {String? note, String? opId}) =>
      _voidRpc('submit_inspection_session', <String, Object?>{
        'p_session_id': sessionId,
        'p_note': _optional(note),
        if (opId != null) 'p_op_id': opId,
      });

  Future<void> _voidRpc(String name, Map<String, Object?> params) =>
      _guard(() async {
        await _client.rpc<Object?>(name, params: params);
      });
}

/// Persists the immutable route/details and sends every assigned field action
/// through the shared outbox when disconnected. Inspection creation is queued
/// with the complete route snapshot; only issue self-claim is online-only.
class OfflineInspectionRepository implements InspectionRepository {
  OfflineInspectionRepository({
    required InspectionRepository inner,
    required LocalCacheStore cache,
    required OutboxStore outbox,
    required ConnectivityController connectivity,
    required SyncEngine syncEngine,
    required TaskEvidenceStorage evidenceStorage,
    required PendingPhotoStore pendingPhotos,
    required String userId,
    Uuid uuid = const Uuid(),
    int Function()? clock,
  })  : _inner = inner,
        _cache = cache,
        _outbox = outbox,
        _connectivity = connectivity,
        _syncEngine = syncEngine,
        _evidenceStorage = evidenceStorage,
        _pendingPhotos = pendingPhotos,
        _userId = userId,
        _uuid = uuid,
        _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  static const cachePrefix = '${privateCachePrefix}inspection_task:';
  static const sessionIndexPrefix = '${privateCachePrefix}inspection_session:';
  static const idMapPrefix = '${privateCachePrefix}inspection_id_map:';
  static const reverseSessionPrefix =
      '${privateCachePrefix}inspection_session_alias:';
  static const localPrefix = 'local:';

  final InspectionRepository _inner;
  final LocalCacheStore _cache;
  final OutboxStore _outbox;
  final ConnectivityController _connectivity;
  final SyncEngine _syncEngine;
  final TaskEvidenceStorage _evidenceStorage;
  final PendingPhotoStore _pendingPhotos;
  final String _userId;
  final Uuid _uuid;
  final int Function() _clock;

  static String cacheKey(String taskId) => '$cachePrefix$taskId';
  static String sessionIndexKey(String sessionId) =>
      '$sessionIndexPrefix$sessionId';
  static String idMapKey(String localId) => '$idMapPrefix$localId';
  static String reverseSessionKey(String remoteSessionId) =>
      '$reverseSessionPrefix$remoteSessionId';

  @override
  Future<InspectionCreationResult> create(
    InspectionCreationDraft draft, {
    String? opId,
  }) async {
    if (_connectivity.isOnline) {
      try {
        return await _inner.create(draft, opId: opId);
      } on OperationFailure catch (error) {
        if (error.kind != OperationFailureKind.offline) rethrow;
      }
    }
    final operationId = opId ?? _uuid.v4();
    final localId = '$localPrefix$operationId';
    final createdAt = _clock();
    await _writeProvisionalInspection(draft, localId, createdAt);
    try {
      await _outbox.enqueue(PendingMutation(
        opId: operationId,
        kind: PendingMutationKind.createInspection,
        payload: <String, Object?>{'draft': draft.toJson()},
        createdAt: createdAt,
      ));
    } catch (_) {
      await discardProvisional(_cache, draft.farmId, localId);
      rethrow;
    }
    unawaited(_syncEngine.sync());
    return InspectionCreationResult(
      sessionId: localId,
      taskId: localId,
    );
  }

  @override
  Future<InspectionDetails> loadByTask(String taskId) async {
    final resolvedTaskId = await resolveTaskId(_cache, taskId);
    try {
      final details = await _inner.loadByTask(resolvedTaskId);
      await _cacheDetails(_cache, details, aliases: <String>[taskId]);
      return details;
    } catch (_) {
      final raw = await _cache.read(cacheKey(taskId));
      if (raw == null) rethrow;
      return InspectionDetails.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    }
  }

  @override
  Future<void> setStatus(
    String sessionId,
    InspectionSessionStatus status, {
    String? opId,
  }) async {
    final resolvedSessionId = await resolveSessionId(_cache, sessionId);
    await _queueOrRun(
      forceQueue: _isUnresolvedLocal(sessionId, resolvedSessionId),
      kind: PendingMutationKind.setInspectionStatus,
      payload: <String, Object?>{
        'sessionId': sessionId,
        'status': status.wireValue,
      },
      online: () => _inner.setStatus(resolvedSessionId, status),
      optimistic: () => _patchSession(sessionId, status: status),
    );
  }

  @override
  Future<void> takeOver(String sessionId, {String? opId}) async {
    if (_connectivity.isOffline) {
      throw const OperationFailure(
        OperationFailureKind.offline,
        'Inspection takeover requires a connection.',
      );
    }
    final resolvedSessionId = await resolveSessionId(_cache, sessionId);
    if (_isUnresolvedLocal(sessionId, resolvedSessionId)) {
      throw const OperationFailure(
        OperationFailureKind.invalidInput,
        'Sync the inspection before taking it over.',
      );
    }
    await _inner.takeOver(resolvedSessionId, opId: opId);
    final taskId = await _cache.read(sessionIndexKey(sessionId));
    if (taskId != null) {
      await _refreshAndCache(await resolveTaskId(_cache, taskId));
    }
  }

  @override
  Future<void> saveStation(
    String sessionId,
    int stationIndex,
    List<InspectionTreeResult> results, {
    String? opId,
    Map<String, PreparedTaskEvidence> photos = const {},
    String? userId,
    String? farmId,
    String? taskId,
  }) async {
    final resolvedUserId = userId ?? _userId;
    if (photos.isNotEmpty && (farmId == null || taskId == null)) {
      throw const OperationFailure(
        OperationFailureKind.invalidInput,
        'Farm and task identity are required for inspection photos.',
      );
    }
    final resolvedSessionId = await resolveSessionId(_cache, sessionId);
    final resolvedTaskId =
        taskId == null ? null : await resolveTaskId(_cache, taskId);
    final forceQueue = _isUnresolvedLocal(sessionId, resolvedSessionId) ||
        (taskId != null && _isUnresolvedLocal(taskId, resolvedTaskId!));
    if (_connectivity.isOnline && !forceQueue) {
      final paths = <String, String>{};
      for (final entry in photos.entries) {
        paths[entry.key] = await _evidenceStorage.upload(
          userId: resolvedUserId,
          farmId: farmId!,
          taskId: resolvedTaskId!,
          evidence: entry.value,
        );
      }
      await _inner.saveStation(
        resolvedSessionId,
        stationIndex,
        _withInspectionPhotoPaths(results, paths),
      );
      await _refreshAndCache(resolvedTaskId!);
      return;
    }
    final operationId = _uuid.v4();
    final refs = <Map<String, Object?>>[];
    try {
      for (final entry in photos.entries) {
        final blobKey = '$operationId::${entry.key}';
        refs.add(<String, Object?>{
          'logical_key': entry.key,
          'blob_key': blobKey,
        });
        await _pendingPhotos.put(PendingPhoto(
          opId: blobKey,
          taskId: taskId!,
          userId: resolvedUserId,
          farmId: farmId!,
          photoType: 'issue',
          filename: entry.value.filename,
          contentType: entry.value.contentType,
          bytes: entry.value.bytes,
          createdAt: _clock(),
        ));
      }
      await _outbox.enqueue(PendingMutation(
        opId: operationId,
        kind: PendingMutationKind.saveInspectionStation,
        payload: <String, Object?>{
          'sessionId': sessionId,
          'stationIndex': stationIndex,
          'results':
              results.map((item) => item.toJson()).toList(growable: false),
          'photoRefs': refs,
        },
        createdAt: _clock(),
      ));
    } catch (_) {
      await _pendingPhotos.deleteForOperation(operationId);
      rethrow;
    }
    await _patchStation(
      sessionId,
      stationIndex,
      results,
      pendingPhotoRefs: <String, String>{
        for (final ref in refs)
          ref['logical_key']! as String: ref['blob_key']! as String,
      },
    );
    unawaited(_syncEngine.sync());
  }

  @override
  Future<void> submit(String sessionId, {String? note, String? opId}) async {
    final resolvedSessionId = await resolveSessionId(_cache, sessionId);
    await _queueOrRun(
      forceQueue: _isUnresolvedLocal(sessionId, resolvedSessionId),
      kind: PendingMutationKind.submitInspection,
      payload: <String, Object?>{'sessionId': sessionId, 'note': note},
      online: () => _inner.submit(resolvedSessionId, note: note),
      optimistic: () => _patchSession(
        sessionId,
        status: InspectionSessionStatus.submitted,
      ),
    );
  }

  Future<void> _queueOrRun({
    required PendingMutationKind kind,
    required Map<String, Object?> payload,
    required Future<void> Function() online,
    required Future<void> Function() optimistic,
    bool forceQueue = false,
  }) async {
    if (_connectivity.isOnline && !forceQueue) {
      try {
        await online();
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
    await optimistic();
    unawaited(_syncEngine.sync());
  }

  Future<void> _patchSession(
    String sessionId, {
    required InspectionSessionStatus status,
  }) async {
    final json = await _cachedJson(sessionId);
    if (json == null) return;
    final session = Map<String, Object?>.from(json['session']! as Map);
    session['status'] = status.wireValue;
    session['revision'] = (session['revision']! as num).toInt() + 1;
    json['session'] = session;
    await _writeCached(sessionId, json);
  }

  Future<void> _patchStation(
    String sessionId,
    int stationIndex,
    List<InspectionTreeResult> results, {
    Map<String, String> pendingPhotoRefs = const <String, String>{},
  }) async {
    final json = await _cachedJson(sessionId);
    if (json == null) return;
    final byTree = <String, InspectionTreeResult>{
      for (final result in results) result.treeId: result,
    };
    final items = (json['items']! as List<Object?>)
        .map((raw) => Map<String, Object?>.from(raw! as Map))
        .toList(growable: false);
    for (final item in items) {
      if ((item['station_index']! as num).toInt() != stationIndex) continue;
      final result = byTree[item['tree_id']! as String];
      if (result == null) continue;
      item['status'] = 'inspected';
      item['no_new_issue_found'] = result.noNewIssueFound;
      item['notes'] = result.notes;
      item['observed_at'] = result.clientObservedAt.toIso8601String();
    }
    json['items'] = items;
    final stationItemIds = items
        .where(
          (item) => (item['station_index']! as num).toInt() == stationIndex,
        )
        .map((item) => item['id']! as String)
        .toSet();
    final itemIdByTree = <String, String>{
      for (final item in items)
        if (stationItemIds.contains(item['id']))
          item['tree_id']! as String: item['id']! as String,
    };
    final observations =
        ((json['observations'] as List<Object?>?) ?? const <Object?>[])
            .map((raw) => Map<String, Object?>.from(raw! as Map))
            .where(
              (observation) => !stationItemIds.contains(observation['item_id']),
            )
            .toList();
    for (final result in results) {
      final itemId = itemIdByTree[result.treeId];
      if (itemId == null) continue;
      for (final issue in result.selectedIssues) {
        observations.add(<String, Object?>{
          'id': 'local:observation:$itemId:${issue.type.wireValue}',
          'session_id': sessionId,
          'item_id': itemId,
          'tree_issue_id': null,
          'issue_type': issue.type.wireValue,
          'outcome': 'confirmed',
          'observed_severity': issue.severity.name,
          'severity_changed': issue.severityChanged,
          'notes': issue.notes,
          'photo_storage_path': issue.photoStoragePath,
          if (pendingPhotoRefs['${result.treeId}|${issue.type.wireValue}']
              case final blobKey?)
            'local_photo_blob_key': blobKey,
          'observed_at': result.clientObservedAt.toIso8601String(),
        });
      }
    }
    json['observations'] = observations;
    final session = Map<String, Object?>.from(json['session']! as Map);
    session['inspected_trees'] =
        items.where((item) => item['status'] == 'inspected').length;
    session['revision'] = (session['revision']! as num).toInt() + 1;
    json['session'] = session;
    await _writeCached(sessionId, json);
  }

  Future<Map<String, Object?>?> _cachedJson(String sessionId) async {
    final taskId = await _cache.read(sessionIndexKey(sessionId));
    if (taskId == null) return null;
    final raw = await _cache.read(cacheKey(taskId));
    return raw == null
        ? null
        : Map<String, Object?>.from(jsonDecode(raw) as Map);
  }

  Future<void> _writeCached(
    String sessionId,
    Map<String, Object?> json,
  ) async {
    final taskId = await _cache.read(sessionIndexKey(sessionId));
    if (taskId != null) await _cache.write(cacheKey(taskId), jsonEncode(json));
  }

  Future<void> _writeProvisionalInspection(
    InspectionCreationDraft draft,
    String localId,
    int createdAtMillis,
  ) async {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      createdAtMillis,
      isUtc: true,
    );
    final details = InspectionDetails(
      session: InspectionSession(
        id: localId,
        farmId: draft.farmId,
        sectionId: draft.route.sectionId,
        taskId: localId,
        inspectorProfileId: draft.inspectorProfileId,
        createdByProfileId: _userId,
        startingTreeId: draft.route.startingTreeId,
        status: InspectionSessionStatus.notStarted,
        routeVersion: draft.route.routeVersion,
        totalStations: draft.route.stationCount,
        totalTrees: draft.route.treeCount,
        inspectedTrees: 0,
        requiresIssuePhoto: draft.requiresIssuePhoto,
        revision: 0,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      items: draft.route.items
          .map(
            (item) => InspectionSessionItem(
              id: '$localId:item:${item.sequenceIndex}',
              sessionId: localId,
              routeItem: item,
              status: InspectionItemStatus.pending,
              noNewIssueFound: false,
            ),
          )
          .toList(growable: false),
    );
    await _cacheDetails(_cache, details);

    final task = FarmTask(
      id: localId,
      farmId: draft.farmId,
      sectionId: draft.route.sectionId,
      type: TaskType.treeInspection,
      title: draft.title.trim(),
      priority: TaskPriority.fromJson(draft.priority),
      status: TaskStatus.assigned,
      scheduledFor: draft.scheduledFor,
      instructions: <String, Object?>{
        'inspection_route_version': draft.route.routeVersion,
        'inspection_requires_issue_photo': draft.requiresIssuePhoto,
      },
      requiresEngineerReview: draft.requiresEngineerReview,
      createdByProfileId: _userId,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final key = CachingTaskRepository.listKeyFor(draft.farmId);
    final raw = await _cache.read(key);
    var rows = <Object?>[];
    if (raw != null) {
      try {
        rows = List<Object?>.from(jsonDecode(raw) as List<Object?>);
      } catch (_) {
        rows = <Object?>[];
      }
    }
    rows.removeWhere((row) => row is Map && row['id'] == localId);
    rows.insert(0, task.toJson());
    await _cache.write(key, jsonEncode(rows));
  }

  Future<void> _refreshAndCache(String taskId) async {
    try {
      final details = await _inner.loadByTask(taskId);
      await _cacheDetails(_cache, details);
    } catch (_) {
      // The successful mutation is authoritative. A later read will refresh.
    }
  }

  static bool _isUnresolvedLocal(String original, String resolved) =>
      original.startsWith(localPrefix) && original == resolved;

  static Future<String> resolveTaskId(
    LocalCacheStore cache,
    String taskId,
  ) async {
    if (!taskId.startsWith(localPrefix)) return taskId;
    final mapping = await _readIdMapping(cache, taskId);
    return mapping?['task_id'] as String? ?? taskId;
  }

  static Future<String> resolveSessionId(
    LocalCacheStore cache,
    String sessionId,
  ) async {
    if (!sessionId.startsWith(localPrefix)) return sessionId;
    final mapping = await _readIdMapping(cache, sessionId);
    return mapping?['session_id'] as String? ?? sessionId;
  }

  static Future<Map<String, Object?>?> _readIdMapping(
    LocalCacheStore cache,
    String localId,
  ) async {
    final raw = await cache.read(idMapKey(localId));
    if (raw == null) return null;
    try {
      return Map<String, Object?>.from(jsonDecode(raw) as Map);
    } catch (_) {
      await cache.remove(idMapKey(localId));
      return null;
    }
  }

  static Future<void> _cacheDetails(
    LocalCacheStore cache,
    InspectionDetails details, {
    List<String> aliases = const <String>[],
  }) async {
    final encoded = jsonEncode(details.toJson());
    final taskIds = <String>{details.session.taskId, ...aliases};
    for (final taskId in taskIds) {
      await cache.write(cacheKey(taskId), encoded);
    }
    await cache.write(
      sessionIndexKey(details.session.id),
      details.session.taskId,
    );
  }

  static Future<void> discardProvisional(
    LocalCacheStore cache,
    String farmId,
    String localId,
  ) async {
    await cache.remove(cacheKey(localId));
    await cache.remove(sessionIndexKey(localId));
    await cache.remove(idMapKey(localId));
    final key = CachingTaskRepository.listKeyFor(farmId);
    final raw = await cache.read(key);
    if (raw == null) return;
    try {
      final rows = (jsonDecode(raw) as List<Object?>)
          .where((row) => row is! Map || row['id'] != localId)
          .toList(growable: false);
      await cache.write(key, jsonEncode(rows));
    } catch (_) {
      // CachingTaskRepository will discard malformed data on its next read.
    }
  }
}

class InspectionMutationExecutor implements MutationExecutor {
  const InspectionMutationExecutor(
    this._repository, {
    required TaskEvidenceStorage evidenceStorage,
    required PendingPhotoStore pendingPhotos,
    required LocalCacheStore cache,
    required TaskRepository taskRepository,
  })  : _evidenceStorage = evidenceStorage,
        _pendingPhotos = pendingPhotos,
        _cache = cache,
        _taskRepository = taskRepository;
  final InspectionRepository _repository;
  final TaskEvidenceStorage _evidenceStorage;
  final PendingPhotoStore _pendingPhotos;
  final LocalCacheStore _cache;
  final TaskRepository _taskRepository;

  @override
  Future<void> execute(PendingMutation mutation) => switch (mutation.kind) {
        PendingMutationKind.createInspection => _createInspection(mutation),
        PendingMutationKind.setInspectionStatus => _setStatus(mutation),
        PendingMutationKind.saveInspectionStation => _saveStation(mutation),
        PendingMutationKind.submitInspection => _submit(mutation),
        _ => throw StateError(
            'InspectionMutationExecutor cannot run ${mutation.kind}',
          ),
      };

  Future<void> _createInspection(PendingMutation mutation) async {
    final draft = InspectionCreationDraft.fromJson(
      Map<String, Object?>.from(mutation.payload['draft']! as Map),
    );
    final result = await _repository.create(draft, opId: mutation.opId);
    final localId =
        '${OfflineInspectionRepository.localPrefix}${mutation.opId}';
    await _cache.write(
      OfflineInspectionRepository.idMapKey(localId),
      jsonEncode(<String, Object?>{
        'local_id': localId,
        'task_id': result.taskId,
        'session_id': result.sessionId,
      }),
    );
    await _cache.write(
      OfflineInspectionRepository.reverseSessionKey(result.sessionId),
      localId,
    );
    await _migrateCachedDetails(localId, result);
    await _reconcileTaskList(draft.farmId, localId, result.taskId);
  }

  Future<void> _setStatus(PendingMutation mutation) async {
    final sessionId = await _resolvedSession(
      mutation.payload['sessionId']! as String,
    );
    await _repository.setStatus(
      sessionId,
      InspectionSessionStatus.fromWire(
        mutation.payload['status']! as String,
      ),
      opId: mutation.opId,
    );
  }

  Future<void> _submit(PendingMutation mutation) async {
    final sessionId = await _resolvedSession(
      mutation.payload['sessionId']! as String,
    );
    await _repository.submit(
      sessionId,
      note: mutation.payload['note'] as String?,
      opId: mutation.opId,
    );
  }

  Future<void> _saveStation(PendingMutation mutation) async {
    final results = (mutation.payload['results']! as List<Object?>)
        .map((item) => InspectionTreeResult.fromJson(
              Map<String, Object?>.from(item! as Map),
            ))
        .toList(growable: false);
    final paths = <String, String>{};
    final refs =
        (mutation.payload['photoRefs'] as List<Object?>?) ?? const <Object?>[];
    for (final raw in refs) {
      final ref = Map<String, Object?>.from(raw! as Map);
      final blobKey = ref['blob_key']! as String;
      final pending = await _pendingPhotos.get(blobKey);
      if (pending == null) {
        throw const OperationFailure(
          OperationFailureKind.notFound,
          'A queued inspection photo could not be found.',
        );
      }
      var path = pending.uploadedPath;
      if (path == null) {
        final taskId = await _resolvedTask(pending.taskId);
        path = await _evidenceStorage.upload(
          userId: pending.userId,
          farmId: pending.farmId,
          taskId: taskId,
          evidence: PreparedTaskEvidence(
            bytes: pending.bytes,
            filename: pending.filename,
            contentType: pending.contentType,
          ),
        );
        await _pendingPhotos.markUploaded(blobKey, path);
      }
      paths[ref['logical_key']! as String] = path;
    }
    final sessionId = await _resolvedSession(
      mutation.payload['sessionId']! as String,
    );
    await _repository.saveStation(
      sessionId,
      (mutation.payload['stationIndex']! as num).toInt(),
      _withInspectionPhotoPaths(results, paths),
      opId: mutation.opId,
    );
    await _pendingPhotos.deleteForOperation(mutation.opId);
  }

  Future<String> _resolvedTask(String id) async {
    final resolved = await OfflineInspectionRepository.resolveTaskId(
      _cache,
      id,
    );
    if (id.startsWith(OfflineInspectionRepository.localPrefix) &&
        resolved == id) {
      throw const OperationFailure(
        OperationFailureKind.unexpected,
        'Inspection creation is still waiting to sync.',
      );
    }
    return resolved;
  }

  Future<String> _resolvedSession(String id) async {
    final resolved = await OfflineInspectionRepository.resolveSessionId(
      _cache,
      id,
    );
    if (id.startsWith(OfflineInspectionRepository.localPrefix) &&
        resolved == id) {
      throw const OperationFailure(
        OperationFailureKind.unexpected,
        'Inspection creation is still waiting to sync.',
      );
    }
    return resolved;
  }

  Future<void> _migrateCachedDetails(
    String localId,
    InspectionCreationResult result,
  ) async {
    final raw =
        await _cache.read(OfflineInspectionRepository.cacheKey(localId));
    if (raw == null) return;
    try {
      final json = Map<String, Object?>.from(jsonDecode(raw) as Map);
      final session = Map<String, Object?>.from(json['session']! as Map);
      session['id'] = result.sessionId;
      session['task_id'] = result.taskId;
      json['session'] = session;
      json['items'] = (json['items']! as List<Object?>).map((rawItem) {
        final item = Map<String, Object?>.from(rawItem! as Map);
        item['session_id'] = result.sessionId;
        return item;
      }).toList(growable: false);
      json['observations'] =
          ((json['observations'] as List<Object?>?) ?? const <Object?>[])
              .map((rawObservation) {
        final observation = Map<String, Object?>.from(rawObservation! as Map);
        observation['session_id'] = result.sessionId;
        return observation;
      }).toList(growable: false);
      final details = InspectionDetails.fromJson(json);
      await OfflineInspectionRepository._cacheDetails(
        _cache,
        details,
        aliases: <String>[localId],
      );
      await _cache.write(
        OfflineInspectionRepository.sessionIndexKey(localId),
        localId,
      );
    } catch (_) {
      // The server detail refresh below can safely replace malformed cache.
    }
    try {
      final remote = await _repository.loadByTask(result.taskId);
      await OfflineInspectionRepository._cacheDetails(
        _cache,
        remote,
        aliases: <String>[localId],
      );
    } catch (_) {
      // The migrated snapshot remains usable until the next refresh.
    }
  }

  Future<void> _reconcileTaskList(
    String farmId,
    String localId,
    String remoteTaskId,
  ) async {
    try {
      final refreshed = await _taskRepository.listForFarm(farmId);
      if (refreshed.any((task) => task.id == remoteTaskId) &&
          refreshed.every((task) => task.id != localId)) {
        return;
      }
    } catch (_) {
      // Keep a usable fallback row if the follow-up refresh is interrupted.
    }
    final key = CachingTaskRepository.listKeyFor(farmId);
    final raw = await _cache.read(key);
    if (raw == null) return;
    try {
      final rows = (jsonDecode(raw) as List<Object?>).map((row) {
        final json = Map<String, Object?>.from(row! as Map);
        if (json['id'] == localId) json['id'] = remoteTaskId;
        return json;
      }).toList(growable: false);
      await _cache.write(key, jsonEncode(rows));
    } catch (_) {
      // CachingTaskRepository will discard malformed data on its next read.
    }
  }
}

List<InspectionTreeResult> _withInspectionPhotoPaths(
  List<InspectionTreeResult> results,
  Map<String, String> paths,
) =>
    results
        .map(
          (result) => InspectionTreeResult(
            treeId: result.treeId,
            noNewIssueFound: result.noNewIssueFound,
            clientObservedAt: result.clientObservedAt,
            notes: result.notes,
            selectedIssues: result.selectedIssues
                .map(
                  (issue) => InspectionSelectedIssue(
                    type: issue.type,
                    severity: issue.severity,
                    severityChanged: issue.severityChanged,
                    notes: issue.notes,
                    photoStoragePath:
                        paths['${result.treeId}|${issue.type.wireValue}'] ??
                            issue.photoStoragePath,
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);

Future<T> _guard<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on PostgrestException catch (error) {
    throw switch (error.code) {
      '42501' => OperationFailure(OperationFailureKind.authorization,
          'Your role is not authorized for this inspection action.',
          cause: error),
      '23514' => OperationFailure(
          OperationFailureKind.invalidInput, error.message,
          cause: error),
      '23505' => OperationFailure(OperationFailureKind.conflict,
          'This inspection changed on another device.',
          cause: error),
      'P0002' => OperationFailure(OperationFailureKind.notFound,
          'The inspection, task, section, or tree could not be found.',
          cause: error),
      'PGRST116' => OperationFailure(OperationFailureKind.notFound,
          'This task has no guided inspection session.',
          cause: error),
      _ => OperationFailure(OperationFailureKind.unexpected,
          'The farm could not save this inspection action.',
          cause: error),
    };
  }
}

String _dateOnly(DateTime value) => value.toIso8601String().split('T').first;

String? _optional(String? value) {
  final result = value?.trim();
  return result == null || result.isEmpty ? null : result;
}
