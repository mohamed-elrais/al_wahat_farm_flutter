import 'dart:async';
import 'dart:convert';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/logging/safe_log.dart';
import 'package:al_wahat_farm_flutter/features/reviews/domain/engineer_review.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_photo.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/caching_task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:uuid/uuid.dart';

/// Queues a review decision captured offline: the draft goes into a `review_task`
/// op and any captured review photo's bytes go to the pending-photo blob store,
/// both keyed by the same op id. The cached task detail is patched optimistically
/// to the decided status so the reviewer sees the task leave the queue. The
/// SyncEngine's [ReviewMutationExecutor] uploads the photo and records the
/// decision on reconnect.
abstract interface class OfflineReviewQueue {
  Future<void> queueReview({
    required ReviewTaskDraft draft,
    required String userId,
    required String farmId,
    PreparedTaskEvidence? photo,
  });
}

class OutboxReviewQueue implements OfflineReviewQueue {
  OutboxReviewQueue({
    required OutboxStore outbox,
    required PendingPhotoStore pendingPhotos,
    required SyncEngine syncEngine,
    required LocalCacheStore cache,
    Uuid uuid = const Uuid(),
    int Function()? clock,
  })  : _outbox = outbox,
        _pendingPhotos = pendingPhotos,
        _syncEngine = syncEngine,
        _cache = cache,
        _uuid = uuid,
        _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final OutboxStore _outbox;
  final PendingPhotoStore _pendingPhotos;
  final SyncEngine _syncEngine;
  final LocalCacheStore _cache;
  final Uuid _uuid;
  final int Function() _clock;

  @override
  Future<void> queueReview({
    required ReviewTaskDraft draft,
    required String userId,
    required String farmId,
    PreparedTaskEvidence? photo,
  }) async {
    final opId = _uuid.v4();
    final now = _clock();
    if (photo != null) {
      await _pendingPhotos.put(
        PendingPhoto(
          opId: opId,
          taskId: draft.taskId, // real id — the task already exists
          userId: userId,
          farmId: farmId,
          photoType: TaskPhotoType.review.wireValue,
          filename: photo.filename,
          contentType: photo.contentType,
          bytes: photo.bytes,
          createdAt: now,
        ),
      );
    }
    await _outbox.enqueue(
      PendingMutation(
        opId: opId,
        kind: PendingMutationKind.reviewTask,
        payload: <String, Object?>{'draft': draft.toJson()},
        createdAt: now,
      ),
    );
    await _patchCachedStatus(draft.taskId, _statusFor(draft.decision));
    unawaited(_syncEngine.sync()); // refresh counts; drains when online
  }

  TaskStatus _statusFor(EngineerReviewDecision decision) => switch (decision) {
        EngineerReviewDecision.approved => TaskStatus.approved,
        EngineerReviewDecision.returnedForCorrection => TaskStatus.returned,
        EngineerReviewDecision.followUpRequired =>
          TaskStatus.needsEngineerReview,
      };

  /// Optimistically reflects the decision in the cached task detail so the
  /// review screen updates and the task leaves the review queue immediately.
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
      SafeLog.event('offline_review_patch_failed',
          data: <String, Object?>{'error': error.runtimeType});
    }
  }
}
