import 'dart:async';

import 'package:al_wahat_farm_flutter/features/issues/data/tree_issue_repository.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_photo.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_photo.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:uuid/uuid.dart';

/// Queues a tree-issue report captured offline: the draft goes into a
/// `report_tree_issue` op and any captured photo bytes go to the pending-photo
/// blob store, both keyed by the same op id. The SyncEngine's
/// [IssueMutationExecutor] reports then uploads/registers the photo on
/// reconnect. Returns provisional temp ids so the caller can treat the report
/// as accepted.
abstract interface class OfflineIssueQueue {
  Future<ReportedTreeIssue> queueReport({
    required TreeIssueDraft draft,
    required String userId,
    required String farmId,
    PreparedIssuePhoto? photo,
  });
}

class OutboxIssueQueue implements OfflineIssueQueue {
  OutboxIssueQueue({
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

  // Provisional id prefix for a report queued offline (mirrors task creation).
  static const localIdPrefix = 'local:';

  final OutboxStore _outbox;
  final PendingPhotoStore _pendingPhotos;
  final SyncEngine _syncEngine;
  final Uuid _uuid;
  final int Function() _clock;

  @override
  Future<ReportedTreeIssue> queueReport({
    required TreeIssueDraft draft,
    required String userId,
    required String farmId,
    PreparedIssuePhoto? photo,
  }) async {
    final opId = _uuid.v4();
    final now = _clock();
    if (photo != null) {
      await _pendingPhotos.put(
        PendingPhoto(
          opId: opId,
          // The real task id is unknown until the report replays; the executor
          // uploads with the id `report_tree_issue` returns, so this is unused.
          taskId: '',
          userId: userId,
          farmId: farmId,
          photoType: 'issue',
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
        kind: PendingMutationKind.reportIssue,
        payload: <String, Object?>{'draft': draft.toJson()},
        createdAt: now,
      ),
    );
    unawaited(_syncEngine.sync()); // refresh counts; drains when online
    return ReportedTreeIssue(
      issueId: '$localIdPrefix$opId',
      taskId: '$localIdPrefix$opId',
    );
  }
}
