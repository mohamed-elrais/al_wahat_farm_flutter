import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:flutter/foundation.dart';

enum TaskCreateStatus { idle, submitting, success, failure }

class TaskCreateController extends ChangeNotifier {
  TaskCreateController({
    required TaskRepository repository,
    this.onCreated,
  }) : _repository = repository;

  final TaskRepository _repository;
  final Future<void> Function()? onCreated;

  TaskCreateStatus _status = TaskCreateStatus.idle;
  String? _taskId;
  String? _message;

  TaskCreateStatus get status => _status;
  String? get taskId => _taskId;
  String? get message => _message;
  bool get isSubmitting => _status == TaskCreateStatus.submitting;

  Future<String?> submit(TaskDraft draft) async {
    if (isSubmitting || _taskId != null) return _taskId;
    final validation = draft.validate();
    if (validation != null) {
      _status = TaskCreateStatus.failure;
      _message = validation;
      notifyListeners();
      return null;
    }
    _status = TaskCreateStatus.submitting;
    _message = null;
    notifyListeners();
    try {
      _taskId = await _repository.create(draft);
      try {
        await onCreated?.call();
      } catch (_) {
        // The task is already committed; a refresh failure must not claim that
        // creation failed.
      }
      _status = TaskCreateStatus.success;
      _message = 'Task created and saved to the farm workflow.';
      notifyListeners();
      return _taskId;
    } catch (error) {
      _status = TaskCreateStatus.failure;
      _message = error is OperationFailure
          ? error.message
          : 'The task could not be created. Check your connection.';
      notifyListeners();
      return null;
    }
  }
}
