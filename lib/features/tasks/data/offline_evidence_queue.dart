import 'dart:async';

import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_photo.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:uuid/uuid.dart';

/// Queues photo evidence captured offline: the bytes go to the pending-photo
/// blob store and an `add_task_photo` op is enqueued, both keyed by the same op
/// id. The SyncEngine's [TaskMutationExecutor] uploads and registers them on
/// reconnect.
abstract interface class OfflineEvidenceQueue {
  Future<void> queueTaskPhoto({
    required String userId,
    required String farmId,
    required String taskId,
    required PreparedTaskEvidence evidence,
    required TaskPhotoType type,
    String? caption,
  });
}

class OutboxEvidenceQueue implements OfflineEvidenceQueue {
  OutboxEvidenceQueue({
    required OutboxStore outbox,
    required PendingPhotoStore pendingPhotos,
    required SyncEngine syncEngine,
    Uuid uuid = const Uuid(),
    int Function()? clock,
  })  : _outbox = outbox,
        _pendingPhotos = pendingPhotos,
        _syncEngine = syncEngine,
        _uuid = uuid,
        _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final OutboxStore _outbox;
  final PendingPhotoStore _pendingPhotos;
  final SyncEngine _syncEngine;
  final Uuid _uuid;
  final int Function() _clock;

  @override
  Future<void> queueTaskPhoto({
    required String userId,
    required String farmId,
    required String taskId,
    required PreparedTaskEvidence evidence,
    required TaskPhotoType type,
    String? caption,
  }) async {
    final opId = _uuid.v4();
    final now = _clock();
    await _pendingPhotos.put(
      PendingPhoto(
        opId: opId,
        taskId: taskId,
        userId: userId,
        farmId: farmId,
        photoType: type.wireValue,
        filename: evidence.filename,
        contentType: evidence.contentType,
        bytes: evidence.bytes,
        caption: caption,
        createdAt: now,
      ),
    );
    await _outbox.enqueue(
      PendingMutation(
        opId: opId,
        kind: PendingMutationKind.addTaskPhoto,
        payload: <String, Object?>{'taskId': taskId},
        createdAt: now,
      ),
    );
    unawaited(_syncEngine.sync()); // refresh counts; drains when online
  }
}
