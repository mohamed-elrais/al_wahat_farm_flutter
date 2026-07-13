import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_widgets.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum TaskListView { today, all }

class TasksScreen extends StatefulWidget {
  const TasksScreen({
    this.controller,
    this.role,
    this.hierarchy,
    this.now,
    this.onOpenTask,
    this.onCreateTask,
    this.onOpenReviews,
    super.key,
  });

  final TaskWorkspaceController? controller;
  final FarmRole? role;
  final FarmHierarchy? hierarchy;
  final DateTime Function()? now;
  final ValueChanged<String>? onOpenTask;
  final VoidCallback? onCreateTask;
  final VoidCallback? onOpenReviews;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskListView _view = TaskListView.today;

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
            ? const Center(child: Text('Task workspace is unavailable.'))
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
    final now = (widget.now ?? DateTime.now)();
    final tasks = _view == TaskListView.today
        ? controller.tasksForDay(now)
        : snapshot.tasks;
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
                    const Eyebrow('Field operations'),
                    const SizedBox(height: 6),
                    Text(
                      'Farm tasks',
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
                  label: const Text('Create'),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            children: <Widget>[
              ChoiceChip(
                key: const Key('tasks-today-filter'),
                label: const Text('Today'),
                selected: _view == TaskListView.today,
                onSelected: (_) => setState(() => _view = TaskListView.today),
              ),
              ChoiceChip(
                key: const Key('tasks-all-filter'),
                label: Text('All (${snapshot.tasks.length})'),
                selected: _view == TaskListView.all,
                onSelected: (_) => setState(() => _view = TaskListView.all),
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
            const _TaskMessage(
              icon: Icons.cloud_sync_outlined,
              title: 'Loading farm tasks',
              message: 'Checking your role-filtered task queue…',
              progress: true,
            )
          else if (snapshot.status == TaskWorkspaceStatus.failure &&
              snapshot.tasks.isEmpty)
            _TaskMessage(
              icon: Icons.sync_problem_outlined,
              title: 'Tasks could not be loaded',
              message: taskFailureMessage(snapshot.error),
              action: OutlinedButton(
                onPressed: controller.refresh,
                child: const Text('Retry'),
              ),
            )
          else ...<Widget>[
            if (snapshot.status == TaskWorkspaceStatus.failure)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MaterialBanner(
                  content: Text(taskFailureMessage(snapshot.error)),
                  actions: <Widget>[
                    TextButton(
                      onPressed: controller.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            if (tasks.isEmpty)
              _TaskMessage(
                icon: Icons.task_alt_outlined,
                title: _view == TaskListView.today
                    ? 'No tasks scheduled today'
                    : 'No visible tasks',
                message: role.canManageTasks
                    ? 'Create a task or switch the date and assignment in Supabase.'
                    : 'Only active tasks assigned to you appear here.',
              )
            else
              for (final task in tasks) ...<Widget>[
                _TaskTile(
                  task: task,
                  hierarchy: hierarchy,
                  onTap: () {
                    final callback = widget.onOpenTask;
                    if (callback != null) {
                      callback(task.id);
                    } else {
                      context.go('/tasks/${task.id}');
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
          ],
        ],
      ),
    );
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
                        '${taskTargetLabel(task, hierarchy)} · ${taskScheduleLabel(task)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          TaskStatusBadge(task.status),
                          Text(
                            task.priority.label,
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
                const Icon(Icons.chevron_right),
              ],
            ),
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
                        'Review queue',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        count == 0
                            ? 'No tasks awaiting review'
                            : '$count task${count == 1 ? '' : 's'} awaiting review',
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
      TaskType.dripperMaintenance => Icons.plumbing_outlined,
      TaskType.treeInspection => Icons.park_outlined,
      TaskType.engineerReview => Icons.engineering_outlined,
      TaskType.general => Icons.assignment_outlined,
    };
