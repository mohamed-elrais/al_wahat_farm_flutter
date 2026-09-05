import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/section_refresh.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_month_calendar.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_widgets.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum TaskListView { today, all }

enum TaskPageView { list, calendar }

class TasksScreen extends StatefulWidget {
  const TasksScreen({
    this.controller,
    this.role,
    this.hierarchy,
    this.now,
    this.onOpenTask,
    this.onOpenInspection,
    this.onCreateTask,
    this.onOpenReviews,
    super.key,
  });

  final TaskWorkspaceController? controller;
  final FarmRole? role;
  final FarmHierarchy? hierarchy;
  final DateTime Function()? now;
  final ValueChanged<String>? onOpenTask;
  final ValueChanged<String>? onOpenInspection;
  final VoidCallback? onCreateTask;
  final VoidCallback? onOpenReviews;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SectionReturnAware {
  TaskListView _view = TaskListView.today;
  TaskPageView _pageView = TaskPageView.list;
  late DateTime _selectedDate;
  late DateTime _visibleMonth;
  final GlobalKey _calendarResultsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedDate = _currentDate();
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  /// Returning to the Tasks section re-pulls the list (new/updated tasks
  /// from schedules, reviews or other members) while keeping the current
  /// data on screen — refresh() no-ops when one is already in flight.
  @override
  void onSectionReturn() {
    (widget.controller ?? TaskWorkspaceScope.maybeOf(context))?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller ?? TaskWorkspaceScope.maybeOf(context);
    final role = widget.role ??
        OperationalContextScope.maybeOf(context)?.selectedMembership.role;
    final hierarchy =
        widget.hierarchy ?? FarmHierarchyScope.maybeOf(context)?.hierarchy;

    return PaperBackground(
      child: Material(
        type: MaterialType.transparency,
        child: controller == null || role == null
            ? Center(child: Text(context.l10n.taskWorkspaceUnavailable))
            : ListenableBuilder(
                listenable: controller,
                builder: (context, _) => _buildList(
                  context,
                  controller,
                  role,
                  hierarchy,
                ),
              ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    TaskWorkspaceController controller,
    FarmRole role,
    FarmHierarchy? hierarchy,
  ) {
    final snapshot = controller.snapshot;
    final today = _currentDate();
    final listTasks = _view == TaskListView.today
        ? controller.tasksForDay(today)
        : snapshot.tasks;
    final calendarTasks = controller.tasksForDay(_selectedDate);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        key: const Key('tasks-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 110),
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Eyebrow(context.l10n.tasksEyebrow),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.tasksTitle,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
              if (role.canManageTasks)
                FilledButton.icon(
                  key: const Key('create-task-button'),
                  onPressed:
                      widget.onCreateTask ?? () => context.go('/tasks/create'),
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.tasksCreate),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (role.canManageTasks) ...<Widget>[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                key: const Key('create-inspection-button'),
                onPressed: () => context.go('/tasks/create-inspection'),
                icon: const Icon(Icons.route_outlined),
                label: Text(context.l10n.inspectionCreateTitle),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SegmentedButton<TaskPageView>(
                key: const Key('tasks-view-switch'),
                segments: <ButtonSegment<TaskPageView>>[
                  ButtonSegment<TaskPageView>(
                    value: TaskPageView.list,
                    icon: const Icon(Icons.view_list_outlined),
                    label: Text(
                      context.l10n.tasksViewList,
                      key: const Key('tasks-list-view'),
                    ),
                  ),
                  ButtonSegment<TaskPageView>(
                    value: TaskPageView.calendar,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      context.l10n.tasksViewCalendar,
                      key: const Key('tasks-calendar-view'),
                    ),
                  ),
                ],
                selected: <TaskPageView>{_pageView},
                onSelectionChanged: (selection) {
                  setState(() => _pageView = selection.single);
                },
              ),
              if (_pageView == TaskPageView.list) ...<Widget>[
                ChoiceChip(
                  key: const Key('tasks-today-filter'),
                  label: Text(context.l10n.tasksFilterToday),
                  selected: _view == TaskListView.today,
                  onSelected: (_) => setState(() => _view = TaskListView.today),
                ),
                ChoiceChip(
                  key: const Key('tasks-all-filter'),
                  label:
                      Text(context.l10n.tasksFilterAll(snapshot.tasks.length)),
                  selected: _view == TaskListView.all,
                  onSelected: (_) => setState(() => _view = TaskListView.all),
                ),
              ],
              OutlinedButton.icon(
                key: const Key('tasks-issues-shortcut'),
                onPressed: () => context.go('/issues'),
                icon: const Icon(Icons.report_problem_outlined, size: 18),
                label: Text(context.l10n.issuesTitle),
              ),
            ],
          ),
          if (role.canReview) ...<Widget>[
            const SizedBox(height: 10),
            _ReviewQueueEntry(
              count: snapshot.tasks
                  .where(
                      (task) => task.status == TaskStatus.needsEngineerReview)
                  .length,
              onTap: widget.onOpenReviews ?? () => context.go('/tasks/reviews'),
            ),
          ],
          if (snapshot.isRefreshing) ...<Widget>[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 14),
          if (snapshot.status == TaskWorkspaceStatus.loading &&
              snapshot.tasks.isEmpty)
            _TaskMessage(
              icon: Icons.cloud_sync_outlined,
              title: context.l10n.tasksLoadingTitle,
              message: context.l10n.tasksLoadingMessage,
              progress: true,
            )
          else if (snapshot.status == TaskWorkspaceStatus.failure &&
              snapshot.tasks.isEmpty)
            _TaskMessage(
              icon: Icons.sync_problem_outlined,
              title: context.l10n.tasksLoadFailedTitle,
              message: taskFailureMessage(context.l10n, snapshot.error),
              action: OutlinedButton(
                onPressed: controller.refresh,
                child: Text(context.l10n.commonRetry),
              ),
            )
          else ...<Widget>[
            if (snapshot.status == TaskWorkspaceStatus.failure)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MaterialBanner(
                  content:
                      Text(taskFailureMessage(context.l10n, snapshot.error)),
                  actions: <Widget>[
                    TextButton(
                      onPressed: controller.refresh,
                      child: Text(context.l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            if (_pageView == TaskPageView.list) ...<Widget>[
              if (listTasks.isEmpty)
                _TaskMessage(
                  icon: Icons.task_alt_outlined,
                  title: _view == TaskListView.today
                      ? context.l10n.tasksEmptyTodayTitle
                      : context.l10n.tasksEmptyAllTitle,
                  message: role.canManageTasks
                      ? context.l10n.tasksEmptyManager
                      : context.l10n.tasksEmptyWorker,
                )
              else
                ..._taskTiles(context, listTasks, hierarchy),
            ] else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TaskMonthCalendar(
                    visibleMonth: _visibleMonth,
                    selectedDate: _selectedDate,
                    today: today,
                    taskCounts: controller.taskCountsForMonth(_visibleMonth),
                    onDateSelected: _selectCalendarDate,
                    onPreviousMonth: () => _moveMonth(-1),
                    onNextMonth: () => _moveMonth(1),
                    onToday: _showToday,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    key: _calendarResultsKey,
                    width: double.infinity,
                    child: Text(
                      context.l10n.tasksCalendarTasksForDate(
                        MaterialLocalizations.of(context)
                            .formatFullDate(_selectedDate),
                      ),
                      key: const Key('tasks-calendar-selected-date-title'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (calendarTasks.isEmpty)
                    _TaskMessage(
                      icon: Icons.event_available_outlined,
                      title: context.l10n.tasksCalendarNoTasksTitle,
                      message: role.canManageTasks
                          ? context.l10n.tasksCalendarNoTasksManager
                          : context.l10n.tasksCalendarNoTasksWorker,
                    )
                  else
                    ..._taskTiles(context, calendarTasks, hierarchy),
                ],
              ),
          ],
        ],
      ),
    );
  }

  List<Widget> _taskTiles(
    BuildContext context,
    List<FarmTask> tasks,
    FarmHierarchy? hierarchy,
  ) =>
      <Widget>[
        for (final task in tasks) ...<Widget>[
          _TaskTile(
            task: task,
            hierarchy: hierarchy,
            onTap: () => _openTask(context, task),
          ),
          const SizedBox(height: 10),
        ],
      ];

  void _openTask(BuildContext context, FarmTask task) {
    if (task.isPendingSync) {
      if (task.hasInspectionSetup) {
        final callback = widget.onOpenInspection;
        if (callback != null) {
          callback(task.id);
        } else {
          context.go('/tasks/${task.id}/inspection');
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.taskPendingSyncOpen)),
      );
      return;
    }
    final callback = widget.onOpenTask;
    if (callback != null) {
      callback(task.id);
    } else {
      context.go('/tasks/${task.id}');
    }
  }

  void _selectCalendarDate(DateTime date) {
    setState(() => _selectedDate = date);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final resultsContext = _calendarResultsKey.currentContext;
      if (resultsContext == null) return;
      Scrollable.ensureVisible(
        resultsContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    });
  }

  void _moveMonth(int offset) {
    final month = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + offset,
    );
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final selectedDay =
        _selectedDate.day > lastDay ? lastDay : _selectedDate.day;
    setState(() {
      _visibleMonth = month;
      _selectedDate = DateTime(month.year, month.month, selectedDay);
    });
  }

  void _showToday() {
    final today = _currentDate();
    setState(() {
      _selectedDate = today;
      _visibleMonth = DateTime(today.year, today.month);
    });
  }

  DateTime _currentDate() {
    final value = (widget.now ?? DateTime.now)();
    return DateTime(value.year, value.month, value.day);
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.hierarchy,
    required this.onTap,
  });

  final FarmTask task;
  final FarmHierarchy? hierarchy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => WahatCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          key: Key('task-${task.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: AppColors.softGreen,
                  foregroundColor: AppColors.green,
                  child: Icon(_taskIcon(task.type)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${taskTargetLabel(context.l10n, task, hierarchy)} · '
                        '${taskScheduleLabel(context.l10n, task)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          TaskStatusBadge(task.status),
                          if (task.isPendingSync) const _PendingSyncBadge(),
                          Text(
                            task.priority.localizedLabel(context.l10n),
                            style: TextStyle(
                              color: task.priority == TaskPriority.urgent
                                  ? AppColors.issue
                                  : AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  task.isPendingSync ? Icons.sync : Icons.chevron_right,
                  color: task.isPendingSync ? AppColors.orange : null,
                ),
              ],
            ),
          ),
        ),
      );
}

class _PendingSyncBadge extends StatelessWidget {
  const _PendingSyncBadge();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        key: const Key('task-pending-sync-badge'),
        decoration: BoxDecoration(
          color: AppColors.orange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.orange.withOpacity(0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.sync, size: 12, color: AppColors.orange),
              const SizedBox(width: 4),
              Text(
                context.l10n.taskPendingSyncBadge,
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
}

class _ReviewQueueEntry extends StatelessWidget {
  const _ReviewQueueEntry({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => WahatCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          key: const Key('open-review-queue-button'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                const CircleAvatar(
                  backgroundColor: AppColors.softGreen,
                  foregroundColor: AppColors.green,
                  child: Icon(Icons.fact_check_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.l10n.reviewQueueEntryTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        count == 0
                            ? context.l10n.reviewQueueEntryNone
                            : context.l10n.reviewQueueEntryCount(count),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (count > 0)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.issue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: AppColors.issue.withOpacity(0.35),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: AppColors.issue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      );
}

class _TaskMessage extends StatelessWidget {
  const _TaskMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.progress = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final bool progress;

  @override
  Widget build(BuildContext context) => WahatCard(
        child: Column(
          children: <Widget>[
            Icon(icon, size: 38, color: AppColors.green),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            if (progress) ...<Widget>[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
            if (action != null) ...<Widget>[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      );
}

IconData _taskIcon(TaskType type) => switch (type) {
      TaskType.irrigation => Icons.water_drop_outlined,
      TaskType.fertilization => Icons.compost_outlined,
      TaskType.harmfulWeedControl => Icons.grass_outlined,
      TaskType.pestControl => Icons.pest_control_outlined,
      TaskType.diseaseControl => Icons.coronavirus_outlined,
      TaskType.dripperMaintenance => Icons.plumbing_outlined,
      TaskType.treeInspection => Icons.park_outlined,
      TaskType.engineerReview => Icons.engineering_outlined,
      TaskType.general => Icons.assignment_outlined,
    };
