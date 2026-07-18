import 'dart:convert';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/caching_task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:flutter/foundation.dart';

/// Backs the failed-ops review screen: lists the operations that failed
/// terminally and lets the user retry or discard each (or all). Discarding also
/// cleans up an op's side effects — a captured photo blob and, for a task
/// creation, its provisional `local:` list row.
class FailedOpsController extends ChangeNotifier {
  FailedOpsController({
    required SyncEngine syncEngine,
    required PendingPhotoStore pendingPhotos,
    LocalCacheStore? cache,
  })  : _syncEngine = syncEngine,
        _pendingPhotos = pendingPhotos,
        _cache = cache;

  final SyncEngine _syncEngine;
  final PendingPhotoStore _pendingPhotos;
  final LocalCacheStore? _cache;

  List<PendingMutation> _ops = const <PendingMutation>[];
  bool _loading = false;
  bool _busy = false;

  List<PendingMutation> get ops => _ops;
  bool get isLoading => _loading;
  bool get isBusy => _busy;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _ops = List<PendingMutation>.unmodifiable(await _syncEngine.failedOps());
    _loading = false;
    notifyListeners();
  }

  Future<void> retry(String opId) => _guard(() async {
        await _syncEngine.retryOne(opId);
      });

  Future<void> retryAll() => _guard(() async {
        await _syncEngine.retryFailed();
      });

  Future<void> discard(PendingMutation op) => _guard(() async {
        // Remove the op's side effects before dropping it from the queue.
        await _pendingPhotos.delete(op.opId);
        if (op.kind == PendingMutationKind.createTask) {
          await _dropProvisional(op);
        }
        await _syncEngine.discard(op.opId);
      });

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _busy = false;
    }
    await load(); // reflects the new failed set + resets busy
  }

  /// Removes the provisional `local:<opId>` row a discarded offline creation
  /// left in the cached task list.
  Future<void> _dropProvisional(PendingMutation op) async {
    final cache = _cache;
    if (cache == null) return;
    final draft = op.payload['draft'];
    if (draft is! Map) return;
    final farmId = draft['farm_id'];
    if (farmId is! String) return;
    final key = CachingTaskRepository.listKeyFor(farmId);
    final raw = await cache.read(key);
    if (raw == null) return;
    final tempId = '$localTaskIdPrefix${op.opId}';
    try {
      final rows = (jsonDecode(raw) as List<Object?>)
          .where((row) => (row! as Map)['id'] != tempId)
          .toList(growable: false);
      await cache.write(key, jsonEncode(rows));
    } catch (_) {
      // Corrupt cache is dropped on the next successful list refresh.
    }
  }
}
