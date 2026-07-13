import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_widgets.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The role-gated queue of tasks awaiting an owner/engineer review decision.
/// Only tasks flagged `needs_engineer_review` are queued here; the review
/// action itself is authorized again at the RPC boundary.
class ReviewQueueScreen extends StatelessWidget {
  const ReviewQueueScreen({
    this.controller,
    this.role,
    this.hierarchy,
    this.onOpenReview,
    super.key,
  });

  final TaskWorkspaceController? controller;
  final FarmRole? role;
  final FarmHierarchy? hierarchy;
  final ValueChanged<String>? onOpenReview;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller ?? TaskWorkspaceScope.maybeOf(context);
    final role = this.role ??
        OperationalContextScope.maybeOf(context)?.selectedMembership.role;
    final hierarchy =
        this.hierarchy ?? FarmHierarchyScope.maybeOf(context)?.hierarchy;

    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: _body(context, controller, role, hierarchy),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    TaskWorkspaceController? controller,
    FarmRole? role,
    FarmHierarchy? hierarchy,
  ) {
    if (role == null || controller == null) {
      return _QueueMessage(
        icon: Icons.sync_problem_outlined,
        title: context.l10n.reviewQueueUnavailableTitle,
        message: context.l10n.reviewQueueUnavailableMessage,
      );
    }
    if (!role.canReview) {
      return _QueueMessage(
        key: const Key('review-queue-denied'),
        icon: Icons.lock_outline,
        title: context.l10n.reviewDeniedTitle,
        message: context.l10n.reviewDeniedMessage,
      );
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _buildList(context, controller, hierarchy),
    );
  }

  Widget _buildList(
    BuildContext context,
    TaskWorkspaceController controller,
    FarmHierarchy? hierarchy,
  ) {
    final snapshot = controller.snapshot;
    final pending = snapshot.tasks
        .where((task) => task.status == TaskStatus.needsEngineerReview)
        .toList(growable: false);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        key: const Key('review-queue-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                tooltip: context.l10n.backToTasks,
                onPressed: () => context.go('/tasks'),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Eyebrow(context.l10n.reviewQueueEyebrow),
                    Text(
                      context.l10n.reviewQueueTitle,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.reviewQueuePending(pending.length),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (snapshot.isRefreshing) ...<Widget>[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 14),
          if (snapshot.status == TaskWorkspaceStatus.loading &&
              snapshot.tasks.isEmpty)
            _QueueMessage(
              icon: Icons.cloud_sync_outlined,
              title: context.l10n.reviewQueueLoadingTitle,
              message: context.l10n.reviewQueueLoadingMessage,
              progress: true,
            )
          else if (snapshot.status == TaskWorkspaceStatus.failure &&
              snapshot.tasks.isEmpty)
            _QueueMessage(
              icon: Icons.sync_problem_outlined,
              title: context.l10n.reviewQueueFailedTitle,
              message: taskFailureMessage(context.l10n, snapshot.error),
              action: OutlinedButton(
                onPressed: controller.refresh,
                child: Text(context.l10n.commonRetry),
              ),
            )
          else if (pending.isEmpty)
            _QueueMessage(
              icon: Icons.verified_outlined,
              title: context.l10n.reviewQueueEmptyTitle,
              message: context.l10n.reviewQueueEmptyMessage,
            )
          else
            for (final task in pending) ...<Widget>[
              _ReviewTile(
                task: task,
                hierarchy: hierarchy,
                onTap: () {
                  final callback = onOpenReview;
                  if (callback != null) {
                    callback(task.id);
                  } else {
                    context.go('/tasks/reviews/${task.id}');
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
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
          key: Key('review-${task.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        taskTargetLabel(context.l10n, task, hierarchy),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          TaskStatusBadge(task.status),
                          if (task.relatedTreeIssueId != null) ...<Widget>[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.report_problem_outlined,
                              size: 16,
                              color: AppColors.issue,
                            ),
                          ],
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

class _QueueMessage extends StatelessWidget {
  const _QueueMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.progress = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final bool progress;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: WahatCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
          ),
        ),
      );
}
