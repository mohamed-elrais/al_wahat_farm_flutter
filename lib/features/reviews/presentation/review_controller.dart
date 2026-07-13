import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/reviews/data/engineer_review_repository.dart';
import 'package:al_wahat_farm_flutter/features/reviews/domain/engineer_review.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:flutter/foundation.dart';

enum ReviewStatus { idle, loading, ready, failure }

enum ReviewStage { idle, pickingPhoto, uploadingPhoto, submitting }

/// Owns the engineer/owner review of a single task: the persisted task detail,
/// its prior review decisions, and the mutation that records a new decision
/// through the `review_task` backend contract.
class ReviewController extends ChangeNotifier {
  ReviewController({
    required TaskRepository taskRepository,
    required EngineerReviewRepository reviewRepository,
    required TaskEvidencePicker evidencePicker,
    required TaskEvidenceStorage evidenceStorage,
    required this.taskId,
    required this.farmId,
    required this.userId,
    this.onReviewed,
  })  : _taskRepository = taskRepository,
        _reviewRepository = reviewRepository,
        _evidencePicker = evidencePicker,
        _evidenceStorage = evidenceStorage;

  final TaskRepository _taskRepository;
  final EngineerReviewRepository _reviewRepository;
  final TaskEvidencePicker _evidencePicker;
  final TaskEvidenceStorage _evidenceStorage;
  final String taskId;
  final String farmId;
  final String userId;
  final AsyncCallback? onReviewed;

  ReviewStatus _status = ReviewStatus.idle;
  ReviewStage _stage = ReviewStage.idle;
  TaskDetails? _details;
  List<EngineerReview> _reviews = const <EngineerReview>[];
  PreparedTaskEvidence? _photo;
  String? _uploadedPath;
  String? _message;

  ReviewStatus get status => _status;
  ReviewStage get stage => _stage;
  TaskDetails? get details => _details;
  List<EngineerReview> get reviews => _reviews;
  PreparedTaskEvidence? get photo => _photo;
  String? get message => _message;
  bool get isBusy => _stage != ReviewStage.idle;

  /// Whether the current task status accepts a review decision. The backend
  /// permits reviewing `completed` and `needs_engineer_review` tasks only.
  bool get canDecide {
    final status = _details?.task.status;
    return status == TaskStatus.completed ||
        status == TaskStatus.needsEngineerReview;
  }

  Future<void> load() async {
    _status = ReviewStatus.loading;
    _message = null;
    notifyListeners();
    try {
      final details = await _taskRepository.loadDetails(taskId);
      final reviews = await _reviewRepository.listForTask(taskId);
      _details = details;
      _reviews = List<EngineerReview>.unmodifiable(reviews);
      _status = ReviewStatus.ready;
    } catch (error) {
      _status = ReviewStatus.failure;
      _message = _messageFor(error, 'Unable to load this review.');
    }
    notifyListeners();
  }

  Future<void> pickPhoto(TaskEvidenceSource source) async {
    if (isBusy) return;
    _setStage(ReviewStage.pickingPhoto);
    try {
      final selected = await _evidencePicker.pick(source);
      if (selected != null) {
        _photo = selected;
        _uploadedPath = null;
      }
      _message = null;
    } catch (error) {
      _message = _messageFor(error, 'Unable to prepare that review photo.');
    }
    _setStage(ReviewStage.idle);
  }

  void removePhoto() {
    if (isBusy) return;
    _photo = null;
    _uploadedPath = null;
    _message = null;
    notifyListeners();
  }

  Future<bool> submit({
    required EngineerReviewDecision decision,
    String? notes,
  }) async {
    if (isBusy) return false;
    try {
      final photoPath = await _preparePhotoPath();
      _setStage(ReviewStage.submitting);
      await _reviewRepository.review(
        ReviewTaskDraft(
          taskId: taskId,
          decision: decision,
          notes: _optionalText(notes),
          photoStoragePath: photoPath,
        ),
      );
      _photo = null;
      _uploadedPath = null;
      await _afterReview('Review recorded: ${decision.label}.');
      return true;
    } catch (error) {
      _message = _uploadedPath != null
          ? 'The review photo is uploaded, but the decision was not confirmed. '
              'Retry without uploading again.'
          : _messageFor(error, 'The review decision could not be recorded.');
      _setStage(ReviewStage.idle);
      return false;
    }
  }

  /// Uploads any selected photo once, caching the path so a failed decision
  /// can be retried without re-uploading. Returns null when no photo is set.
  Future<String?> _preparePhotoPath() async {
    if (_photo == null) return null;
    final cached = _uploadedPath;
    if (cached != null) return cached;
    _setStage(ReviewStage.uploadingPhoto);
    final path = await _evidenceStorage.upload(
      userId: userId,
      farmId: farmId,
      taskId: taskId,
      evidence: _photo!,
    );
    _uploadedPath = path;
    return path;
  }

  Future<void> _afterReview(String message) async {
    try {
      _details = await _taskRepository.loadDetails(taskId);
      _reviews =
          List<EngineerReview>.unmodifiable(await _reviewRepository.listForTask(
        taskId,
      ));
      _status = ReviewStatus.ready;
    } catch (_) {
      // The review already committed; a non-transactional refresh failure must
      // not report the decision as failed.
    }
    _message = message;
    try {
      await onReviewed?.call();
    } catch (_) {
      // Workspace list refresh is non-transactional after a committed review.
    }
    _setStage(ReviewStage.idle);
  }

  void _setStage(ReviewStage next) {
    _stage = next;
    notifyListeners();
  }
}

String _messageFor(Object error, String fallback) =>
    error is OperationFailure ? error.message : fallback;

String? _optionalText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
