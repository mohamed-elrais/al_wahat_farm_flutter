import 'package:al_wahat_farm_flutter/features/issues/data/tree_issue_repository.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_photo.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';

/// Replays a queued tree-issue report. `report_tree_issue` is idempotent on its
/// op id (backend ledger), so a retry after a lost response returns the same
/// issue/task ids; the optional captured photo is then uploaded to the real
/// task path and registered against the real issue id — all in one op, which
/// avoids any temp→real id reconciliation across the outbox.
class IssueMutationExecutor implements MutationExecutor {
  const IssueMutationExecutor({
    required TreeIssueRepository repository,
    required IssuePhotoStorage photoStorage,
    required PendingPhotoStore pendingPhotos,
  })  : _repository = repository,
        _photoStorage = photoStorage,
        _pendingPhotos = pendingPhotos;

  final TreeIssueRepository _repository;
  final IssuePhotoStorage _photoStorage;
  final PendingPhotoStore _pendingPhotos;

  @override
  Future<void> execute(PendingMutation mutation) async {
    if (mutation.kind != PendingMutationKind.reportIssue) {
      throw StateError('IssueMutationExecutor cannot run ${mutation.kind}');
    }
    final draft = TreeIssueDraft.fromJson(
      Map<String, Object?>.from(mutation.payload['draft']! as Map),
    );
    final result = await _repository.report(draft, opId: mutation.opId);

    final photo = await _pendingPhotos.get(mutation.opId);
    if (photo == null) return; // no photo, or already uploaded and cleaned up

    // Upload at most once; a register retry reuses the stored path. The upload
    // path is keyed by the real task id the report just returned.
    var path = photo.uploadedPath;
    if (path == null) {
      path = await _photoStorage.upload(
        userId: photo.userId,
        farmId: photo.farmId,
        taskId: result.taskId,
        photo: PreparedIssuePhoto(
          bytes: photo.bytes,
          filename: photo.filename,
          contentType: photo.contentType,
        ),
      );
      await _pendingPhotos.markUploaded(mutation.opId, path);
    }
    await _repository.addPhoto(
      issueId: result.issueId,
      storagePath: path,
      caption: photo.caption,
    );
    await _pendingPhotos.delete(mutation.opId);
  }
}
