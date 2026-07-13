import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
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
  String? _message;

  TaskDetailStatus get status => _status;
  TaskMutationStage get stage => _stage;
  TaskDetails? get details => _details;
  PreparedTaskEvidence? get evidence => _evidence;
  String? get message => _message;
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
      _message = _messageFor(error, 'Unable to load this task.');
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
      _message = _messageFor(error, 'Unable to prepare that evidence photo.');
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
      await _afterMutation('Task started.');
      return true;
    } catch (error) {
      _message = _messageFor(error, 'The task could not be started.');
      _setStage(TaskMutationStage.idle);
      return false;
    }
  }

  Future<bool> setAssignments(List<String> profileIds) async {
    if (isBusy) return false;
    _setStage(TaskMutationStage.assigning);
    try {
      await _repository.setAssignments(taskId, profileIds);
      await _afterMutation('Assignments updated.');
      return true;
    } catch (error) {
      _message = _messageFor(error, 'Assignments could not be updated.');
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
      await _afterMutation('Task evidence saved.');
      return true;
    } catch (error) {
      _message = _messageFor(
        error,
        'Evidence registration was not confirmed. You can safely retry.',
      );
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
      final fallbackMessage = requiresEngineerReview
          ? 'Task completed and sent for engineer review.'
          : 'Task completed.';
      await _afterMutation(
        fallbackMessage,
        resolveMessage: (details) =>
            details?.task.status == TaskStatus.needsEngineerReview
                ? 'Task completed and sent for engineer review.'
                : fallbackMessage,
      );
      return true;
    } catch (error) {
      _message = _evidenceRegistered
          ? 'Evidence is saved, but task completion was not confirmed. Retry completion without uploading again.'
          : _messageFor(error, 'The task could not be completed.');
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
    String message, {
    String Function(TaskDetails?)? resolveMessage,
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

String _messageFor(Object error, String fallback) =>
    error is OperationFailure ? error.message : fallback;

String? _optionalText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
