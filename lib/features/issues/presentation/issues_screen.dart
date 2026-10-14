import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/app/theme/app_visuals.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/option_visuals.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_workspace.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IssuesScreen extends StatelessWidget {
  const IssuesScreen({this.connectivity, super.key});

  final ConnectivityController? connectivity;

  @override
  Widget build(BuildContext context) {
    final controller = IssueWorkspaceScope.maybeOf(context);
    final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
    final role =
        OperationalContextScope.maybeOf(context)?.selectedMembership.role;
    final taskWorkspace = TaskWorkspaceScope.maybeOf(context);
    if (controller == null || hierarchy == null || role == null) {
      return Scaffold(
        body: Center(child: Text(context.l10n.issuesUnavailable)),
      );
    }
    final network =
        connectivity ?? AppServicesScope.maybeOf(context)?.connectivity;
    final screenListenable = network == null
        ? controller
        : Listenable.merge(<Listenable>[controller, network]);
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: screenListenable,
            builder: (context, _) => RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                key: const Key('issues-list'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: <Widget>[
                  _Header(count: controller.activeCount),
                  const SizedBox(height: 14),
                  if (role.canManageTasks) ...<Widget>[
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OutlinedButton.icon(
                        key: const Key('issues-create-inspection'),
                        onPressed: () => context.go('/tasks/create-inspection'),
                        icon: const Icon(Icons.route_outlined),
                        label: Text(context.l10n.inspectionCreateTitle),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _WorkspaceViewSwitch(controller: controller),
                    const SizedBox(height: 14),
                  ],
                  _Filters(
                    controller: controller,
                    sections: hierarchy.sections,
                    isManager: role.canManageTasks,
                  ),
                  const SizedBox(height: 14),
                  if (controller.error != null)
                    _ErrorBanner(error: controller.error!),
                  if (controller.status == IssueWorkspaceStatus.loading &&
                      controller.issues.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (controller.issues.isEmpty)
                    _Empty(
                      onRefresh: controller.load,
                      history: role.canManageTasks &&
                          controller.view == IssueWorkspaceView.history,
                    )
                  else
                    for (final issue in controller.issues) ...<Widget>[
                      _IssueCard(
                        issue: issue,
                        tree: _treeById(hierarchy, issue.treeId),
                        section: _sectionForTree(hierarchy, issue.treeId),
                        canClaim: role == FarmRole.worker &&
                            !issue.isClaimed &&
                            issue.status.name == 'open' &&
                            !(network?.isOffline ?? false),
                        claimRequiresConnection: role == FarmRole.worker &&
                            !issue.isClaimed &&
                            issue.status.name == 'open' &&
                            (network?.isOffline ?? false),
                        canAssign: role.canManageTasks &&
                            !issue.isClaimed &&
                            issue.status == TreeIssueStatus.open &&
                            !(network?.isOffline ?? false),
                        assignmentRequiresConnection: role.canManageTasks &&
                            !issue.isClaimed &&
                            issue.status == TreeIssueStatus.open &&
                            (network?.isOffline ?? false),
                        showManagerMetadata: role.canManageTasks,
                        busy: controller.busyIssueId == issue.id,
                        onOpenTree: () =>
                            context.go('/map/tree/${issue.treeId}'),
                        onOpenDetails: issue.canViewDetails
                            ? () => context.go('/issues/${issue.id}')
                            : null,
                        onClaim: () async {
                          final taskId = await controller.claim(issue);
                          if (taskId != null && context.mounted) {
                            context.go('/tasks/$taskId');
                          }
                        },
                        onAssign: taskWorkspace == null
                            ? null
                            : () => _assignIssue(
                                  context,
                                  controller,
                                  taskWorkspace,
                                  issue,
                                ),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspaceViewSwitch extends StatelessWidget {
  const _WorkspaceViewSwitch({required this.controller});

  final IssueWorkspaceController controller;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        child: Row(
          children: <Widget>[
            Expanded(
              child: ChoiceChip(
                key: const Key('issues-active-view'),
                selected: controller.view == IssueWorkspaceView.active,
                avatar: const Icon(Icons.report_problem_outlined, size: 18),
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    context.l10n.issuesActiveTab(controller.activeCount),
                    textAlign: TextAlign.center,
                  ),
                ),
                onSelected: (_) =>
                    controller.setView(IssueWorkspaceView.active),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChoiceChip(
                key: const Key('issues-history-view'),
                selected: controller.view == IssueWorkspaceView.history,
                avatar: const Icon(Icons.history, size: 18),
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    context.l10n.issuesHistoryTab(controller.historyCount),
                    textAlign: TextAlign.center,
                  ),
                ),
                onSelected: (_) =>
                    controller.setView(IssueWorkspaceView.history),
              ),
            ),
          ],
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          WahatBackButton(
            tooltip: context.l10n.commonBack,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Eyebrow(context.l10n.issuesEyebrow),
                Text(
                  context.l10n.issuesTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          Badge(
            label: Text('$count'),
            backgroundColor: AppColors.issue,
            child: const Icon(Icons.report_problem_outlined, size: 30),
          ),
        ],
      );
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.controller,
    required this.sections,
    required this.isManager,
  });
  final IssueWorkspaceController controller;
  final List<FarmSection> sections;
  final bool isManager;

  @override
  Widget build(BuildContext context) => WahatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(context.l10n.issuesFilters,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = constraints.maxWidth >= 680
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: <Widget>[
                    SizedBox(
                      width: fieldWidth,
                      child: _typeFilter(context),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: _severityFilter(context),
                    ),
                    if (isManager) ...<Widget>[
                      SizedBox(
                          width: fieldWidth, child: _statusFilter(context)),
                      SizedBox(
                          width: fieldWidth, child: _sectionFilter(context)),
                      SizedBox(width: fieldWidth, child: _ageFilter(context)),
                      SizedBox(
                        width: fieldWidth,
                        child: _assignmentFilter(context),
                      ),
                      SizedBox(
                          width: fieldWidth, child: _sourceFilter(context)),
                    ],
                  ],
                );
              },
            ),
            if (isManager)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  key: const Key('issues-reset-filters'),
                  onPressed: controller.resetManagerFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: Text(context.l10n.issuesResetFilters),
                ),
              )
            else
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: controller.onlyUnclaimed,
                title: Text(context.l10n.issuesOnlyUnclaimed),
                onChanged: controller.setOnlyUnclaimed,
              ),
          ],
        ),
      );

  Widget _typeFilter(BuildContext context) =>
      DropdownButtonFormField<TreeIssueType?>(
        value: controller.typeFilter,
        isExpanded: true,
        decoration: InputDecoration(labelText: context.l10n.issueTypeLabel),
        items: <DropdownMenuItem<TreeIssueType?>>[
          DropdownMenuItem(
              value: null, child: Text(context.l10n.issuesAllTypes)),
          for (final type in TreeIssueType.values)
            DropdownMenuItem(
              value: type,
              child: OptionLabel(
                type.visual,
                type.localizedLabel(context.l10n),
                size: 24,
                maxLines: 1,
              ),
            ),
        ],
        onChanged: controller.setType,
      );

  Widget _severityFilter(BuildContext context) =>
      DropdownButtonFormField<IssueSeverity?>(
        value: controller.severityFilter,
        isExpanded: true,
        decoration: InputDecoration(labelText: context.l10n.issueSeverityLabel),
        items: <DropdownMenuItem<IssueSeverity?>>[
          DropdownMenuItem(
            value: null,
            child: Text(context.l10n.issuesAllSeverities),
          ),
          for (final severity in IssueSeverity.values)
            DropdownMenuItem(
              value: severity,
              child: BarsLabel(
                severity.visual,
                severity.localizedLabel(context.l10n),
                fontSize: 14,
              ),
            ),
        ],
        onChanged: controller.setSeverity,
      );

  Widget _statusFilter(BuildContext context) {
    final statuses = controller.view == IssueWorkspaceView.active
        ? const <TreeIssueStatus>[
            TreeIssueStatus.open,
            TreeIssueStatus.inReview,
          ]
        : const <TreeIssueStatus>[
            TreeIssueStatus.resolved,
            TreeIssueStatus.dismissed,
          ];
    return DropdownButtonFormField<TreeIssueStatus?>(
      value: controller.issueStatusFilter,
      isExpanded: true,
      decoration: InputDecoration(labelText: context.l10n.issuesStatusFilter),
      items: <DropdownMenuItem<TreeIssueStatus?>>[
        DropdownMenuItem(
          value: null,
          child: Text(context.l10n.issuesAllStatuses),
        ),
        for (final status in statuses)
          DropdownMenuItem(
            value: status,
            child: OptionLabel(
              status.visual,
              status.localizedLabel(context.l10n),
              size: 24,
              maxLines: 1,
            ),
          ),
      ],
      onChanged: controller.setStatus,
    );
  }

  Widget _sectionFilter(BuildContext context) =>
      DropdownButtonFormField<String?>(
        value: controller.sectionFilter,
        isExpanded: true,
        decoration:
            InputDecoration(labelText: context.l10n.issuesSectionFilter),
        items: <DropdownMenuItem<String?>>[
          DropdownMenuItem(
            value: null,
            child: Text(context.l10n.issuesAllSections),
          ),
          for (final section in sections)
            DropdownMenuItem(value: section.id, child: Text(section.code)),
        ],
        onChanged: controller.setSection,
      );

  Widget _ageFilter(BuildContext context) =>
      DropdownButtonFormField<IssueAgeFilter>(
        value: controller.ageFilter,
        isExpanded: true,
        decoration: InputDecoration(labelText: context.l10n.issuesAgeFilter),
        items: <DropdownMenuItem<IssueAgeFilter>>[
          DropdownMenuItem(
            value: IssueAgeFilter.any,
            child: Text(context.l10n.issuesAnyAge),
          ),
          DropdownMenuItem(
            value: IssueAgeFilter.sevenDays,
            child: Text(context.l10n.issuesAgeSevenDays),
          ),
          DropdownMenuItem(
            value: IssueAgeFilter.thirtyDays,
            child: Text(context.l10n.issuesAgeThirtyDays),
          ),
          DropdownMenuItem(
            value: IssueAgeFilter.ninetyDays,
            child: Text(context.l10n.issuesAgeNinetyDays),
          ),
        ],
        onChanged: (value) {
          if (value != null) controller.setAge(value);
        },
      );

  Widget _assignmentFilter(BuildContext context) =>
      DropdownButtonFormField<IssueAssignmentFilter>(
        value: controller.assignmentFilter,
        isExpanded: true,
        decoration:
            InputDecoration(labelText: context.l10n.issuesAssignmentFilter),
        items: <DropdownMenuItem<IssueAssignmentFilter>>[
          DropdownMenuItem(
            value: IssueAssignmentFilter.all,
            child: Text(context.l10n.issuesAllAssignments),
          ),
          DropdownMenuItem(
            value: IssueAssignmentFilter.assigned,
            child: Text(context.l10n.issuesAssigned),
          ),
          DropdownMenuItem(
            value: IssueAssignmentFilter.unassigned,
            child: Text(context.l10n.issuesUnassigned),
          ),
        ],
        onChanged: (value) {
          if (value != null) controller.setAssignment(value);
        },
      );

  Widget _sourceFilter(BuildContext context) =>
      DropdownButtonFormField<IssueSource?>(
        value: controller.sourceFilter,
        isExpanded: true,
        decoration: InputDecoration(labelText: context.l10n.issuesSourceFilter),
        items: <DropdownMenuItem<IssueSource?>>[
          DropdownMenuItem(
            value: null,
            child: Text(context.l10n.issuesAllSources),
          ),
          DropdownMenuItem(
            value: IssueSource.inspection,
            child: Text(context.l10n.issueSourceInspection),
          ),
          DropdownMenuItem(
            value: IssueSource.quickReport,
            child: Text(context.l10n.issueSourceQuickReport),
          ),
        ],
        onChanged: controller.setSource,
      );
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.issue,
    required this.tree,
    required this.section,
    required this.canClaim,
    required this.claimRequiresConnection,
    required this.canAssign,
    required this.assignmentRequiresConnection,
    required this.showManagerMetadata,
    required this.busy,
    required this.onOpenTree,
    required this.onOpenDetails,
    required this.onClaim,
    required this.onAssign,
  });

  final TreeIssueSummary issue;
  final FarmTreeRecord? tree;
  final FarmSection? section;
  final bool canClaim;
  final bool claimRequiresConnection;
  final bool canAssign;
  final bool assignmentRequiresConnection;
  final bool showManagerMetadata;
  final bool busy;
  final VoidCallback onOpenTree;
  final VoidCallback? onOpenDetails;
  final VoidCallback onClaim;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) => WahatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                OptionBadge(issue.type.visual, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        issue.type.localizedLabel(context.l10n),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        context.l10n.issuesTreeLocation(
                          section?.code ?? issue.sectionCode,
                          tree?.treeCode ?? issue.treeCode,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                StatusPill(
                  issue.severity.visual,
                  issue.severity.localizedLabel(context.l10n),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (showManagerMetadata) ...<Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  StatusPill(
                    issue.status.visual,
                    issue.status.localizedLabel(context.l10n),
                  ),
                  if (issue.source != null)
                    Chip(
                      avatar: Icon(
                        issue.source == IssueSource.inspection
                            ? Icons.fact_check_outlined
                            : Icons.add_comment_outlined,
                        size: 16,
                      ),
                      label: Text(
                        issue.source == IssueSource.inspection
                            ? context.l10n.issueSourceInspection
                            : context.l10n.issueSourceQuickReport,
                      ),
                    ),
                  if (issue.assignedName != null)
                    Chip(
                      avatar: const Icon(Icons.person_outline, size: 16),
                      label: Text(
                        context.l10n.issuesAssignedTo(issue.assignedName!),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                issue.closedAt == null
                    ? context.l10n.issuesReportedOn(
                        _issueDateLabel(context, issue.reportedAt),
                      )
                    : '${context.l10n.issuesReportedOn(_issueDateLabel(context, issue.reportedAt))} · '
                        '${context.l10n.issuesClosedOn(_issueDateLabel(context, issue.closedAt!))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onOpenTree,
                  icon: const Icon(Icons.park_outlined, size: 18),
                  label: Text(context.l10n.issuesOpenTree),
                ),
                if (onOpenDetails != null)
                  OutlinedButton.icon(
                    key: Key('issue-details-${issue.id}'),
                    onPressed: onOpenDetails,
                    icon: const Icon(Icons.history, size: 18),
                    label: Text(context.l10n.issueDetailViewHistory),
                  ),
                if (canClaim)
                  FilledButton.icon(
                    onPressed: busy ? null : onClaim,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.assignment_ind_outlined, size: 18),
                    label: Text(context.l10n.issuesClaim),
                  )
                else if (canAssign && onAssign != null)
                  FilledButton.icon(
                    key: Key('issue-assign-${issue.id}'),
                    onPressed: busy ? null : onAssign,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.assignment_ind_outlined, size: 18),
                    label: Text(context.l10n.issuesAssign),
                  )
                else if (claimRequiresConnection)
                  OutlinedButton.icon(
                    key: Key('issue-claim-offline-${issue.id}'),
                    onPressed: null,
                    icon: const Icon(Icons.cloud_off_outlined, size: 18),
                    label: Text(context.l10n.issuesClaimOnlineOnly),
                  )
                else if (assignmentRequiresConnection)
                  OutlinedButton.icon(
                    key: Key('issue-assign-offline-${issue.id}'),
                    onPressed: null,
                    icon: const Icon(Icons.cloud_off_outlined, size: 18),
                    label: Text(context.l10n.issuesAssignmentOnlineOnly),
                  )
                else
                  Chip(
                    avatar: Icon(
                      issue.claimedByCurrentUser
                          ? Icons.person_outline
                          : issue.isClaimed
                              ? Icons.lock_outline
                              : Icons.visibility_outlined,
                      size: 16,
                    ),
                    label: Text(
                      issue.claimedByCurrentUser
                          ? context.l10n.issuesClaimedByYou
                          : issue.isClaimed
                              ? context.l10n.issuesClaimed
                              : issue.canViewDetails
                                  ? context.l10n.issuesDetailsAvailable
                                  : context.l10n.issuesSummaryOnly,
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: MaterialBanner(
          content: Text(
            switch (error) {
              OperationFailure(kind: OperationFailureKind.offline) =>
                context.l10n.issuesClaimOnlineOnly,
              OperationFailure(:final message) => message,
              _ => context.l10n.issuesLoadFailed,
            },
          ),
          actions: const <Widget>[SizedBox.shrink()],
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onRefresh, required this.history});
  final VoidCallback onRefresh;
  final bool history;

  @override
  Widget build(BuildContext context) => WahatCard(
        child: Column(
          children: <Widget>[
            const Icon(Icons.check_circle_outline,
                color: AppColors.green, size: 42),
            const SizedBox(height: 10),
            Text(
                history
                    ? context.l10n.issuesHistoryEmpty
                    : context.l10n.issuesEmpty,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
}

FarmTreeRecord? _treeById(FarmHierarchy hierarchy, String treeId) {
  for (final tree in hierarchy.trees) {
    if (tree.id == treeId) return tree;
  }
  return null;
}

FarmSection? _sectionForTree(FarmHierarchy hierarchy, String treeId) {
  final tree = _treeById(hierarchy, treeId);
  return tree == null ? null : hierarchy.sectionById(tree.sectionId);
}

String _issueDateLabel(BuildContext context, DateTime value) =>
    MaterialLocalizations.of(context).formatCompactDate(value.toLocal());

Future<void> _assignIssue(
  BuildContext context,
  IssueWorkspaceController issueWorkspace,
  TaskWorkspaceController taskWorkspace,
  TreeIssueSummary issue,
) async {
  await taskWorkspace.loadAssignableMembers();
  if (!context.mounted) return;

  if (taskWorkspace.membersError != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          taskFailureMessage(context.l10n, taskWorkspace.membersError),
        ),
      ),
    );
    return;
  }
  final members = taskWorkspace.assignableMembers;
  if (members.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.issuesNoAssignableMembers)),
    );
    return;
  }

  var selectedId = members.first.profileId;
  var requiresReview = true;
  final choice = await showDialog<_AssignmentChoice>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(context.l10n.issuesAssignTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                context.l10n.issuesTreeLocation(
                  issue.sectionCode,
                  issue.treeCode,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('issue-assignee-field'),
                value: selectedId,
                isExpanded: true,
                decoration:
                    InputDecoration(labelText: context.l10n.issuesAssignTo),
                items: <DropdownMenuItem<String>>[
                  for (final member in members)
                    DropdownMenuItem(
                      value: member.profileId,
                      child: Text(member.fullName),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => selectedId = value);
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                key: const Key('issue-assignment-review-switch'),
                contentPadding: EdgeInsets.zero,
                value: requiresReview,
                title: Text(context.l10n.issuesRequireEngineerReview),
                onChanged: (value) => setState(() => requiresReview = value),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('issue-assignment-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(
              _AssignmentChoice(
                profileId: selectedId,
                requiresEngineerReview: requiresReview,
              ),
            ),
            child: Text(context.l10n.issuesAssign),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  final taskId = await issueWorkspace.assign(
    issue,
    assigneeProfileId: choice.profileId,
    requiresEngineerReview: choice.requiresEngineerReview,
  );
  if (taskId == null || !context.mounted) return;
  await taskWorkspace.refresh();
  if (context.mounted) context.go('/tasks/$taskId');
}

class _AssignmentChoice {
  const _AssignmentChoice({
    required this.profileId,
    required this.requiresEngineerReview,
  });

  final String profileId;
  final bool requiresEngineerReview;
}
