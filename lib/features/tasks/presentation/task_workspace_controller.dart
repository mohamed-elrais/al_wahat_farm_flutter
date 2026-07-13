import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:flutter/widgets.dart';

enum TaskWorkspaceStatus { idle, loading, ready, failure }

class TaskWorkspaceSnapshot {
  TaskWorkspaceSnapshot({
    required this.status,
    required List<FarmTask> tasks,
    this.error,
    this.isRefreshing = false,
  }) : tasks = List<FarmTask>.unmodifiable(tasks);

  const TaskWorkspaceSnapshot.idle()
      : status = TaskWorkspaceStatus.idle,
        tasks = const <FarmTask>[],
        error = null,
        isRefreshing = false;

  final TaskWorkspaceStatus status;
  final List<FarmTask> tasks;
  final Object? error;
  final bool isRefreshing;
}

class TaskWorkspaceController extends ChangeNotifier {
  TaskWorkspaceController({
    required TaskRepository repository,
    required this.farmId,
  }) : _repository = repository;

  final TaskRepository _repository;
  final String farmId;

  TaskWorkspaceSnapshot _snapshot = const TaskWorkspaceSnapshot.idle();
  List<TaskAssignee> _assignableMembers = const <TaskAssignee>[];
  bool _membersLoading = false;
  Object? _membersError;

  TaskRepository get repository => _repository;
  TaskWorkspaceSnapshot get snapshot => _snapshot;
  List<TaskAssignee> get assignableMembers => _assignableMembers;
  bool get membersLoading => _membersLoading;
  Object? get membersError => _membersError;

  Future<void> load() async {
    _snapshot = TaskWorkspaceSnapshot(
      status: TaskWorkspaceStatus.loading,
      tasks: _snapshot.tasks,
    );
    notifyListeners();
    await _fetch();
  }

  Future<void> refresh() async {
    if (_snapshot.status == TaskWorkspaceStatus.loading ||
        _snapshot.isRefreshing) {
      return;
    }
    _snapshot = TaskWorkspaceSnapshot(
      status: _snapshot.tasks.isEmpty
          ? TaskWorkspaceStatus.loading
          : TaskWorkspaceStatus.ready,
      tasks: _snapshot.tasks,
      isRefreshing: _snapshot.tasks.isNotEmpty,
    );
    notifyListeners();
    await _fetch();
  }

  Future<void> loadAssignableMembers() async {
    if (_membersLoading || _assignableMembers.isNotEmpty) return;
    _membersLoading = true;
    _membersError = null;
    notifyListeners();
    try {
      _assignableMembers = List<TaskAssignee>.unmodifiable(
        await _repository.listAssignableMembers(farmId),
      );
    } catch (error) {
      _membersError = error;
    } finally {
      _membersLoading = false;
      notifyListeners();
    }
  }

  List<FarmTask> tasksForDay(DateTime day) => _snapshot.tasks.where((task) {
        final scheduled = task.scheduledFor;
        final due = task.dueAt?.toLocal();
        return (scheduled != null && _sameDay(scheduled, day)) ||
            (scheduled == null && due != null && _sameDay(due, day));
      }).toList(growable: false);

  FarmTask? taskById(String id) {
    for (final task in _snapshot.tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  Future<void> _fetch() async {
    try {
      _snapshot = TaskWorkspaceSnapshot(
        status: TaskWorkspaceStatus.ready,
        tasks: await _repository.listForFarm(farmId),
      );
    } catch (error) {
      _snapshot = TaskWorkspaceSnapshot(
        status: TaskWorkspaceStatus.failure,
        tasks: _snapshot.tasks,
        error: error,
      );
    }
    notifyListeners();
  }
}

class TaskWorkspaceScope extends InheritedWidget {
  const TaskWorkspaceScope({
    required this.controller,
    required super.child,
    super.key,
  });

  final TaskWorkspaceController controller;

  static TaskWorkspaceController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<TaskWorkspaceScope>()
      ?.controller;

  @override
  bool updateShouldNotify(TaskWorkspaceScope oldWidget) =>
      oldWidget.controller != controller;
}

class TaskWorkspaceProvider extends StatefulWidget {
  const TaskWorkspaceProvider({
    required this.farmId,
    required this.repository,
    required this.child,
    super.key,
  });

  final String farmId;
  final TaskRepository repository;
  final Widget child;

  @override
  State<TaskWorkspaceProvider> createState() => _TaskWorkspaceProviderState();
}

class _TaskWorkspaceProviderState extends State<TaskWorkspaceProvider> {
  late TaskWorkspaceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _createController();
  }

  @override
  void didUpdateWidget(TaskWorkspaceProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.farmId != widget.farmId ||
        oldWidget.repository != widget.repository) {
      _controller.dispose();
      _controller = _createController();
    }
  }

  TaskWorkspaceController _createController() => TaskWorkspaceController(
        repository: widget.repository,
        farmId: widget.farmId,
      )..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TaskWorkspaceScope(
        controller: _controller,
        child: widget.child,
      );
}

String taskFailureMessage(AppLocalizations l10n, Object? error) =>
    switch (error) {
      OperationFailure(:final message) => message,
      _ => l10n.tasksFailureDefault,
    };

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
