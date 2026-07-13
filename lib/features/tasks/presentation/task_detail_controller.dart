import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:flutter/foundation.dart';

enum TaskDetailStatus { idle, loading, ready, failure }

enum TaskMutationStage {
  idle,
  starting,
  assigning,
  pickingEvidence,
  uploadingEvidence,
  registeringEvidence,
  completing,
}

class TaskDetailController extends ChangeNotifier {
  TaskDetailController({
    required TaskRepository repository,
    required TaskEvidencePicker evidencePicker,
    required TaskEvidenceStorage evidenceStorage,
    required this.taskId,
    required this.farmId,
    required this.userId,
    this.onMutated,
  })  : _repository = repository,
        _evidencePicker = evidencePicker,
        _evidenceStorage = evidenceStorage;

  final TaskRepository _repository;
  final TaskEvidencePicker _evidencePicker;
  final TaskEvidenceStorage _evidenceStorage;
  final String taskId;
  final String farmId;
  final String userId;
  final AsyncCallback? onMutated;

  TaskDetailStatus _status = TaskDetailStatus.idle;
  TaskMutationStage _stage = TaskMutationStage.idle;
  TaskDetails? _details;
  PreparedTaskEvidence? _evidence;
  String? _uploadedPath;
  bool _evidenceRegistered = false;
  String Function(AppLocalizations)? _message;

  TaskDetailStatus get status => _status;
  TaskMutationStage get stage => _stage;
  TaskDetails? get details => _details;
  PreparedTaskEvidence? get evidence => _evidence;
  String Function(AppLocalizations)? get message => _message;
  bool get isBusy => _stage != TaskMutationStage.idle;

  Future<void> load() async {
    _status = TaskDetailStatus.loading;
    _message = null;
    notifyListeners();
    try {
      _details = await _repository.loadDetails(taskId);
      _status = TaskDetailStatus.ready;
    } catch (error) {
      _status = TaskDetailStatus.failure;
      _message = _messageFor(error, (l10n) => l10n.unableToLoadTask);
    }
    notifyListeners();
  }

  Future<void> pickEvidence(TaskEvidenceSource source) async {
    if (isBusy) return;
    _setStage(TaskMutationStage.pickingEvidence);
    try {
      final selected = await _evidencePicker.pick(source);
      if (selected != null) {
        _evidence = selected;
        _uploadedPath = null;
        _evidenceRegistered = false;
      }
      _message = null;
    } catch (error) {
      _message = _messageFor(error, (l10n) => l10n.errEvidencePrepare);
    }
    _setStage(TaskMutationStage.idle);
  }

  void removeEvidence() {
    if (isBusy || _evidenceRegistered) return;
    _evidence = null;
    _uploadedPath = null;
    _message = null;
    notifyListeners();
  }

  Future<bool> start({String? note}) async {
    if (isBusy) return false;
    _setStage(TaskMutationStage.starting);
    try {
      await _repository.start(taskId, note: note);
      await _afterMutation((l10n) => l10n.msgTaskStarted);
      return true;
    } catch (error) {
      _message = _messageFor(error, (l10n) => l10n.errTaskStart);
      _setStage(TaskMutationStage.idle);
      return false;
    }
  }

  Future<bool> setAssignments(List<String> profileIds) async {
    if (isBusy) return false;
    _setStage(TaskMutationStage.assigning);
    try {
      await _repository.setAssignments(taskId, profileIds);
      await _afterMutation((l10n) => l10n.msgAssignmentsUpdated);
      return true;
    } catch (error) {
      _message = _messageFor(error, (l10n) => l10n.errAssignmentsUpdate);
      _setStage(TaskMutationStage.idle);
      return false;
    }
  }

  Future<bool> addEvidence({
    required TaskPhotoType type,
    String? caption,
  }) async {
    if (isBusy || _evidence == null) return false;
    try {
      await _registerEvidence(type: type, caption: caption);
      _evidence = null;
      _uploadedPath = null;
      _evidenceRegistered = false;
      await _afterMutation((l10n) => l10n.msgTaskEvidenceSaved);
      return true;
    } catch (error) {
      _message = _messageFor(error, (l10n) => l10n.errEvidenceRegister);
      _setStage(TaskMutationStage.idle);
      return false;
    }
  }

  Future<bool> complete({
    String? note,
    bool requiresEngineerReview = false,
    TaskPhotoType evidenceType = TaskPhotoType.after,
    String? evidenceCaption,
  }) async {
    if (isBusy) return false;
    try {
      if (_evidence != null && !_evidenceRegistered) {
        await _registerEvidence(
          type: evidenceType,
          caption: evidenceCaption,
        );
      }
      _setStage(TaskMutationStage.completing);
      await _repository.complete(
        taskId,
        note: note,
        requiresEngineerReview: requiresEngineerReview,
      );
      _evidence = null;
      _uploadedPath = null;
      _evidenceRegistered = false;
      final String Function(AppLocalizations) fallbackMessage =
          requiresEngineerReview
              ? (l10n) => l10n.msgTaskCompletedReview
              : (l10n) => l10n.msgTaskCompleted;
      await _afterMutation(
        fallbackMessage,
        resolveMessage: (details) =>
            details?.task.status == TaskStatus.needsEngineerReview
                ? (l10n) => l10n.msgTaskCompletedReview
                : fallbackMessage,
      );
      return true;
    } catch (error) {
      _message = _evidenceRegistered
          ? ((l10n) => l10n.errCompletionUnconfirmed)
          : _messageFor(error, (l10n) => l10n.errTaskComplete);
      _setStage(TaskMutationStage.idle);
      return false;
    }
  }

  Future<void> _registerEvidence({
    required TaskPhotoType type,
    String? caption,
  }) async {
    final evidence = _evidence!;
    var path = _uploadedPath;
    if (path == null) {
      _setStage(TaskMutationStage.uploadingEvidence);
      path = await _evidenceStorage.upload(
        userId: userId,
        farmId: farmId,
        taskId: taskId,
        evidence: evidence,
      );
      _uploadedPath = path;
    }

    _setStage(TaskMutationStage.registeringEvidence);
    try {
      await _repository.addPhoto(
        TaskEvidenceRegistration(
          taskId: taskId,
          storagePath: path,
          type: type,
          caption: _optionalText(caption),
        ),
      );
      _evidenceRegistered = true;
    } catch (_) {
      if (!await _pathIsRegistered(path)) rethrow;
      _evidenceRegistered = true;
    }
  }

  Future<bool> _pathIsRegistered(String path) async {
    try {
      final latest = await _repository.loadDetails(taskId);
      _details = latest;
      return latest.hasPhotoPath(path);
    } catch (_) {
      return false;
    }
  }

  Future<void> _afterMutation(
    String Function(AppLocalizations) message, {
    String Function(AppLocalizations) Function(TaskDetails?)? resolveMessage,
  }) async {
    try {
      _details = await _repository.loadDetails(taskId);
      _status = TaskDetailStatus.ready;
    } catch (_) {
      // The mutation already committed. Keep the last known detail instead of
      // reporting the action as failed because a non-transactional refresh did.
    }
    _message = resolveMessage?.call(_details) ?? message;
    try {
      await onMutated?.call();
    } catch (_) {
      // The RPC already committed; list refresh failure is non-transactional.
    }
    _setStage(TaskMutationStage.idle);
  }

  void _setStage(TaskMutationStage next) {
    _stage = next;
    notifyListeners();
  }
}

String Function(AppLocalizations) _messageFor(
  Object error,
  String Function(AppLocalizations) fallback,
) =>
    error is OperationFailure ? ((_) => error.message) : fallback;

String? _optionalText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
