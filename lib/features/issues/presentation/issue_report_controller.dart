import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/tree_issue_repository.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_photo.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:flutter/foundation.dart';

enum IssueSubmissionStage {
  idle,
  pickingPhoto,
  reporting,
  uploadingPhoto,
  registeringPhoto,
  success,
  partialSuccess,
  failure,
}

class IssueReportController extends ChangeNotifier {
  IssueReportController({
    required TreeIssueRepository repository,
    required IssuePhotoPicker photoPicker,
    required IssuePhotoStorage photoStorage,
    required this.userId,
    required this.farmId,
    required this.treeId,
    this.onPersisted,
  })  : _repository = repository,
        _photoPicker = photoPicker,
        _photoStorage = photoStorage;

  final TreeIssueRepository _repository;
  final IssuePhotoPicker _photoPicker;
  final IssuePhotoStorage _photoStorage;
  final String userId;
  final String farmId;
  final String treeId;
  final AsyncCallback? onPersisted;

  IssueSubmissionStage _stage = IssueSubmissionStage.idle;
  PreparedIssuePhoto? _photo;
  ReportedTreeIssue? _result;
  String? _uploadedPhotoPath;
  String? _message;

  IssueSubmissionStage get stage => _stage;
  PreparedIssuePhoto? get photo => _photo;
  ReportedTreeIssue? get result => _result;
  String? get message => _message;
  bool get isBusy => switch (_stage) {
        IssueSubmissionStage.pickingPhoto ||
        IssueSubmissionStage.reporting ||
        IssueSubmissionStage.uploadingPhoto ||
        IssueSubmissionStage.registeringPhoto =>
          true,
        _ => false,
      };
  bool get canSubmit => !isBusy && _result == null;

  Future<void> pickPhoto(IssuePhotoSource source) async {
    if (isBusy || _result != null) return;
    _setStage(IssueSubmissionStage.pickingPhoto);
    try {
      final selected = await _photoPicker.pick(source);
      if (selected != null) _photo = selected;
      _message = null;
      _setStage(IssueSubmissionStage.idle);
    } catch (error) {
      _message = _messageFor(error, fallback: 'Unable to prepare that photo.');
      _setStage(IssueSubmissionStage.failure);
    }
  }

  void removePhoto() {
    if (isBusy || _result != null) return;
    _photo = null;
    _message = null;
    _setStage(IssueSubmissionStage.idle);
  }

  Future<bool> submit({
    required TreeIssueType type,
    required IssueSeverity severity,
    String? description,
  }) async {
    if (!canSubmit) return false;
    _message = null;
    _setStage(IssueSubmissionStage.reporting);
    try {
      final draft = TreeIssueDraft(
        treeId: treeId,
        type: type,
        severity: severity,
        description: _optionalText(description),
      );
      final validation = draft.validate();
      if (validation != null) {
        throw OperationFailure(
          OperationFailureKind.invalidInput,
          validation,
        );
      }
      _result = await _repository.report(draft);
      await _refreshSilently();
      if (_photo == null) {
        _message = 'Issue reported and engineer review task created.';
        _setStage(IssueSubmissionStage.success);
        return true;
      }
      return _uploadSelectedPhoto();
    } catch (error) {
      _message = _messageFor(
        error,
        fallback: 'The issue could not be reported. Check your connection.',
      );
      _setStage(IssueSubmissionStage.failure);
      return false;
    }
  }

  Future<bool> retryPhoto() async {
    if (isBusy || _result == null || _photo == null) return false;
    _message = null;
    return _uploadSelectedPhoto();
  }

  Future<bool> _uploadSelectedPhoto() async {
    final result = _result!;
    final photo = _photo!;
    try {
      var path = _uploadedPhotoPath;
      if (path == null) {
        _setStage(IssueSubmissionStage.uploadingPhoto);
        path = await _photoStorage.upload(
          userId: userId,
          farmId: farmId,
          taskId: result.taskId,
          photo: photo,
        );
        _uploadedPhotoPath = path;
      }
      _setStage(IssueSubmissionStage.registeringPhoto);
      await _repository.addPhoto(
        issueId: result.issueId,
        storagePath: path,
      );
      await _refreshSilently();
      _message = 'Issue, review task, and photo evidence saved.';
      _setStage(IssueSubmissionStage.success);
      return true;
    } catch (error) {
      _message = 'The issue and review task were saved, but photo registration '
          'was not confirmed. '
          '${_messageFor(error, fallback: 'You can safely retry the photo.')}';
      _setStage(IssueSubmissionStage.partialSuccess);
      return false;
    }
  }

  void _setStage(IssueSubmissionStage value) {
    _stage = value;
    notifyListeners();
  }

  Future<void> _refreshSilently() async {
    try {
      await onPersisted?.call();
    } catch (_) {
      // Refresh failure cannot roll back an RPC that has already committed.
    }
  }
}

String? _optionalText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String _messageFor(Object error, {required String fallback}) =>
    error is OperationFailure ? error.message : fallback;
