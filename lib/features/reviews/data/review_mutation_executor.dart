import 'package:al_wahat_farm_flutter/features/reviews/data/engineer_review_repository.dart';
import 'package:al_wahat_farm_flutter/features/reviews/domain/engineer_review.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';

/// Replays a queued review decision. The task already exists (real id), so this
/// is a single op: upload the optional review photo to the task path, then call
/// `review_task` with the resulting path and the op id as `p_op_id`. The
/// backend ledger dedups a retry after a lost response, and a re-upload is
/// avoided by reusing the stored path. A successful replay refreshes the cached
/// task detail so the UI converges to server truth.
class ReviewMutationExecutor implements MutationExecutor {
  const ReviewMutationExecutor({
    required EngineerReviewRepository reviewRepository,
    required TaskEvidenceStorage evidenceStorage,
    required PendingPhotoStore pendingPhotos,
    TaskRepository? taskRepository,
  })  : _reviewRepository = reviewRepository,
        _evidenceStorage = evidenceStorage,
        _pendingPhotos = pendingPhotos,
        _taskRepository = taskRepository;

  final EngineerReviewRepository _reviewRepository;
  final TaskEvidenceStorage _evidenceStorage;
  final PendingPhotoStore _pendingPhotos;
  final TaskRepository? _taskRepository;

  @override
  Future<void> execute(PendingMutation mutation) async {
    if (mutation.kind != PendingMutationKind.reviewTask) {
      throw StateError('ReviewMutationExecutor cannot run ${mutation.kind}');
    }
    var draft = ReviewTaskDraft.fromJson(
      Map<String, Object?>.from(mutation.payload['draft']! as Map),
    );

    final photo = await _pendingPhotos.get(mutation.opId);
    if (photo != null) {
      var path = photo.uploadedPath;
      if (path == null) {
        path = await _evidenceStorage.upload(
          userId: photo.userId,
          farmId: photo.farmId,
          taskId: draft.taskId,
          evidence: PreparedTaskEvidence(
            bytes: photo.bytes,
            filename: photo.filename,
            contentType: photo.contentType,
          ),
        );
        await _pendingPhotos.markUploaded(mutation.opId, path);
      }
      draft = draft.withPhotoStoragePath(path);
    }

    await _reviewRepository.review(draft, opId: mutation.opId);
    if (photo != null) await _pendingPhotos.delete(mutation.opId);

    try {
      await _taskRepository?.loadDetails(draft.taskId);
    } catch (_) {
      // A refresh failure is non-transactional; the review already committed.
    }
  }
}
