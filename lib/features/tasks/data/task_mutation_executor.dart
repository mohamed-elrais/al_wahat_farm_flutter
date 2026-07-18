import 'dart:convert';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/caching_task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';

/// Replays queued task mutations against the backend. Given the caching task
/// repository, a successful replay also refreshes the cached detail so the UI
/// converges to server truth after sync. Photo ops additionally need the
/// evidence storage and the pending-photo blob store; create ops use the cache
/// store to drop the provisional list row once the real task exists.
class TaskMutationExecutor implements MutationExecutor {
  const TaskMutationExecutor(
    this._repository, {
    TaskEvidenceStorage? evidenceStorage,
    PendingPhotoStore? pendingPhotos,
    LocalCacheStore? cache,
  })  : _evidenceStorage = evidenceStorage,
        _pendingPhotos = pendingPhotos,
        _cache = cache;

  final TaskRepository _repository;
  final TaskEvidenceStorage? _evidenceStorage;
  final PendingPhotoStore? _pendingPhotos;
  final LocalCacheStore? _cache;

  @override
  Future<void> execute(PendingMutation mutation) async {
    switch (mutation.kind) {
      case PendingMutationKind.startTask:
        await _repository.start(
          mutation.payload['taskId']! as String,
          note: mutation.payload['note'] as String?,
        );
      case PendingMutationKind.completeTask:
        await _repository.complete(
          mutation.payload['taskId']! as String,
          note: mutation.payload['note'] as String?,
          requiresEngineerReview:
              (mutation.payload['requiresEngineerReview'] as bool?) ?? false,
        );
      case PendingMutationKind.setAssignments:
        await _repository.setAssignments(
          mutation.payload['taskId']! as String,
          (mutation.payload['profileIds']! as List<Object?>).cast<String>(),
        );
      case PendingMutationKind.addTaskPhoto:
        await _executePhoto(mutation);
        return; // _executePhoto refreshes the cache itself
      case PendingMutationKind.createTask:
        await _executeCreate(mutation);
        return; // _executeCreate reconciles the list cache itself
    }
    await _refresh(mutation.payload['taskId']! as String);
  }

  /// Replays an offline task creation: sends the draft with the outbox op id as
  /// `p_op_id` (duplicate-safe), then reconciles the cached list by dropping the
  /// provisional `local:` row and re-pulling server truth.
  Future<void> _executeCreate(PendingMutation mutation) async {
    final draft = TaskDraft.fromJson(
      Map<String, Object?>.from(mutation.payload['draft']! as Map),
    );
    await _repository.create(draft, opId: mutation.opId);
    await _dropProvisional(draft.farmId, '$localTaskIdPrefix${mutation.opId}');
    try {
      await _repository.listForFarm(draft.farmId);
    } catch (_) {
      // A refresh failure is non-transactional; the task already exists on the
      // server and the provisional row has been removed.
    }
  }

  Future<void> _dropProvisional(String farmId, String tempId) async {
    final cache = _cache;
    if (cache == null) return;
    final key = CachingTaskRepository.listKeyFor(farmId);
    final raw = await cache.read(key);
    if (raw == null) return;
    try {
      final rows = (jsonDecode(raw) as List<Object?>)
          .where((row) => (row! as Map)['id'] != tempId)
          .toList(growable: false);
      await cache.write(key, jsonEncode(rows));
    } catch (_) {
      // Corrupt cache is dropped on the next successful list refresh.
    }
  }

  Future<void> _executePhoto(PendingMutation mutation) async {
    final photos = _pendingPhotos;
    final storage = _evidenceStorage;
    if (photos == null || storage == null) {
      throw StateError('Photo executor is missing storage dependencies');
    }
    final photo = await photos.get(mutation.opId);
    if (photo == null) return; // already uploaded and cleaned up (idempotent)

    // Upload at most once; a register retry reuses the stored path so no
    // duplicate object is created under a fresh timestamped path.
    var path = photo.uploadedPath;
    if (path == null) {
      path = await storage.upload(
        userId: photo.userId,
        farmId: photo.farmId,
        taskId: photo.taskId,
        evidence: PreparedTaskEvidence(
          bytes: photo.bytes,
          filename: photo.filename,
          contentType: photo.contentType,
        ),
      );
      await photos.markUploaded(mutation.opId, path);
    }

    await _repository.addPhoto(
      TaskEvidenceRegistration(
        taskId: photo.taskId,
        storagePath: path,
        type: TaskPhotoType.fromJson(photo.photoType),
        caption: photo.caption,
      ),
    );
    await photos.delete(mutation.opId);
    await _refresh(photo.taskId);
  }

  Future<void> _refresh(String taskId) async {
    try {
      await _repository.loadDetails(taskId);
    } catch (_) {
      // A refresh failure is non-transactional; the mutation already committed.
    }
  }
}
