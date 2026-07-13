import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
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
  String Function(AppLocalizations)? _message;

  TaskCreateStatus get status => _status;
  String? get taskId => _taskId;
  String Function(AppLocalizations)? get message => _message;
  bool get isSubmitting => _status == TaskCreateStatus.submitting;

  Future<String?> submit(TaskDraft draft) async {
    if (isSubmitting || _taskId != null) return _taskId;
    final validation = draft.validate();
    if (validation != null) {
      _status = TaskCreateStatus.failure;
      _message = (_) => validation;
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
      _message = (l10n) => l10n.msgTaskCreated;
      notifyListeners();
      return _taskId;
    } catch (error) {
      _status = TaskCreateStatus.failure;
      _message = error is OperationFailure
          ? ((_) => error.message)
          : ((l10n) => l10n.errTaskCreate);
      notifyListeners();
      return null;
    }
  }
}
