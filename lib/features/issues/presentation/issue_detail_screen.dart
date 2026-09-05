import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_workspace.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_photo_viewer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IssueDetailScreen extends StatefulWidget {
  const IssueDetailScreen({
    required this.issueId,
    this.photoUrls,
    super.key,
  });

  final String issueId;
  final TaskPhotoUrlProvider? photoUrls;

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  TreeIssueDetails? _details;
  Object? _error;
  bool _busy = false;
  bool _loaded = false;
  TaskPhotoUrlProvider? _photoUrls;
  bool _photoUrlsResolved = false;

  TaskPhotoUrlProvider? get _photoUrlProvider {
    if (!_photoUrlsResolved) {
      _photoUrlsResolved = true;
      try {
        _photoUrls = widget.photoUrls ??
            SupabaseTaskPhotoUrlProvider(Supabase.instance.client);
      } catch (_) {
        _photoUrls = widget.photoUrls;
      }
    }
    return _photoUrls;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded && !_busy) _load();
  }

  @override
  void didUpdateWidget(IssueDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.issueId != widget.issueId) {
      _details = null;
      _error = null;
      _loaded = false;
      _load();
    }
  }

  Future<void> _load() async {
    final controller = IssueWorkspaceScope.maybeOf(context);
    if (controller == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final details = await controller.loadDetails(widget.issueId);
      if (mounted) {
        setState(() {
          _details = details;
          _loaded = true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loaded = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PaperBackground(
          child: SafeArea(
            child: _details == null && _busy
                ? const Center(child: CircularProgressIndicator())
                : _details == null
                    ? _Failure(error: _error, onRetry: _load)
                    : _body(_details!),
          ),
        ),
      );

  Widget _body(TreeIssueDetails details) {
    final issue = details.issue;
    final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
    final tree = _treeById(hierarchy, issue.treeId);
    final section =
        tree == null ? null : hierarchy?.sectionById(tree.sectionId);
    final canManage = OperationalContextScope.maybeOf(context)
            ?.selectedMembership
            .role
            .canManageTasks ??
        false;
    final isActive = issue.status == TreeIssueStatus.open ||
        issue.status == TreeIssueStatus.inReview;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        key: const Key('issue-detail-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          Row(
            children: <Widget>[
              WahatBackButton(
                tooltip: context.l10n.commonBack,
                onPressed: () => context.go('/issues'),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.l10n.issueDetailTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Chip(label: Text(issue.status.localizedLabel(context.l10n))),
            ],
          ),
          if (_busy) ...<Widget>[
            const SizedBox(height: 10),
            const LinearProgressIndicator(),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(_errorMessage(_error!),
                style: const TextStyle(color: AppColors.issue)),
          ],
          const SizedBox(height: 14),
          WahatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.report_problem_outlined,
                        color: AppColors.issue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue.type.localizedLabel(context.l10n),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Chip(
                      label: Text(issue.severity.localizedLabel(context.l10n)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(context.l10n.issuesTreeLocation(
                  section?.code ?? '—',
                  tree?.treeCode ?? issue.treeId,
                )),
                const Divider(height: 24),
                Text(
                  context.l10n.issueDetailDescription,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  issue.description?.trim().isNotEmpty == true
                      ? issue.description!
                      : context.l10n.issueDetailNoDescription,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: () => context.go('/map/tree/${issue.treeId}'),
                      icon: const Icon(Icons.park_outlined),
                      label: Text(context.l10n.issuesOpenTree),
                    ),
                  ],
                ),
                if (canManage && isActive) ...<Widget>[
                  const Divider(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      FilledButton.tonalIcon(
                        key: const Key('change-issue-severity-button'),
                        onPressed: _busy ? null : () => _changeSeverity(issue),
                        icon: const Icon(Icons.priority_high),
                        label: Text(context.l10n.issueDetailChangeSeverity),
                      ),
                      OutlinedButton.icon(
                        key: const Key('dismiss-issue-button'),
                        onPressed: _busy ? null : () => _dismiss(issue),
                        icon: const Icon(Icons.cancel_outlined),
                        label: Text(context.l10n.issueDetailDismiss),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.issueDetailObservations,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (details.observations.isEmpty)
            WahatCard(child: Text(context.l10n.issueDetailNoObservations))
          else
            for (final observation in details.observations) ...<Widget>[
              _ObservationCard(observation: observation),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 6),
          _LinkedTasksCard(tasks: details.linkedTasks),
          const SizedBox(height: 14),
          _IssueEvidenceCard(
            photos: details.evidence,
            urls: _photoUrlProvider,
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.issueDetailHistory,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (details.events.isEmpty)
            WahatCard(child: Text(context.l10n.issueDetailNoHistory))
          else
            for (final event in details.events) ...<Widget>[
              _EventCard(event: event),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Future<void> _changeSeverity(TreeIssue issue) async {
    final change = await _severityDialog(issue.severity);
    if (change == null || !mounted) return;
    await _act(() => IssueWorkspaceScope.maybeOf(context)!.changeSeverity(
          issue.id,
          change.severity,
          notes: change.notes,
        ));
  }

  Future<void> _dismiss(TreeIssue issue) async {
    final notes = await _dismissDialog();
    if (notes == null || !mounted) return;
    await _act(
      () => IssueWorkspaceScope.maybeOf(context)!.dismiss(issue.id, notes),
    );
  }

  Future<void> _act(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.issueDetailActionSaved)),
      );
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<_SeverityChange?> _severityDialog(IssueSeverity current) async {
    var selected = current;
    final notes = TextEditingController();
    final result = await showDialog<_SeverityChange>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.l10n.issueDetailChangeSeverity),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<IssueSeverity>(
                value: selected,
                items: IssueSeverity.values
                    .map(
                      (severity) => DropdownMenuItem<IssueSeverity>(
                        value: severity,
                        child: Text(severity.localizedLabel(context.l10n)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selected = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notes,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.l10n.issueWorkNotes,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: selected == current
                  ? null
                  : () => Navigator.of(dialogContext).pop(
                        _SeverityChange(selected, notes.text.trim()),
                      ),
              child: Text(context.l10n.commonSave),
            ),
          ],
        ),
      ),
    );
    notes.dispose();
    return result;
  }

  Future<String?> _dismissDialog() async {
    final notes = TextEditingController();
    var showError = false;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.l10n.issueDetailDismiss),
          content: TextField(
            controller: notes,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context.l10n.issueDetailDismissPrompt,
              errorText:
                  showError ? context.l10n.issueDetailDismissRequired : null,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final value = notes.text.trim();
                if (value.isEmpty) {
                  setDialogState(() => showError = true);
                  return;
                }
                Navigator.of(dialogContext).pop(value);
              },
              child: Text(context.l10n.issueDetailDismiss),
            ),
          ],
        ),
      ),
    );
    notes.dispose();
    return result;
  }

  String _errorMessage(Object error) => error is OperationFailure
      ? error.message
      : context.l10n.issueDetailLoadFailed;
}

class _ObservationCard extends StatelessWidget {
  const _ObservationCard({required this.observation});

  final InspectionIssueObservation observation;

  @override
  Widget build(BuildContext context) {
    final local = observation.observedAt.toLocal();
    final material = MaterialLocalizations.of(context);
    return WahatCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.fact_check_outlined, color: AppColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  observation.outcome.localizedLabel(context.l10n),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${material.formatShortDate(local)} · '
                  '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (observation.observedSeverity != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(observation.observedSeverity!
                        .localizedLabel(context.l10n)),
                  ),
                ],
                if (observation.severityChanged) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.issueObservationSeverityChanged,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
                if (observation.notes?.trim().isNotEmpty == true) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(observation.notes!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedTasksCard extends StatelessWidget {
  const _LinkedTasksCard({required this.tasks});

  final List<IssueLinkedTask> tasks;

  @override
  Widget build(BuildContext context) => WahatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              context.l10n.issueDetailLinkedTasks,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (tasks.isEmpty)
              Text(context.l10n.issueDetailNoLinkedTasks)
            else
              for (final task in tasks)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.assignment_outlined),
                  title: Text(task.title),
                  subtitle: Text(
                    task.canOpen
                        ? task.status.localizedLabel(context.l10n)
                        : context.l10n.issueDetailTaskRestricted,
                  ),
                  trailing:
                      task.canOpen ? const Icon(Icons.chevron_right) : null,
                  onTap: task.canOpen
                      ? () => context.go('/tasks/${task.taskId}')
                      : null,
                ),
          ],
        ),
      );
}

class _IssueEvidenceCard extends StatelessWidget {
  const _IssueEvidenceCard({required this.photos, required this.urls});

  final List<TaskPhoto> photos;
  final TaskPhotoUrlProvider? urls;

  @override
  Widget build(BuildContext context) => WahatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              context.l10n.issueDetailEvidence(photos.length),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (photos.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(context.l10n.noEvidence),
              )
            else
              for (var index = 0; index < photos.length; index++)
                ListTile(
                  key: Key('issue-evidence-$index'),
                  contentPadding: EdgeInsets.zero,
                  leading: TaskPhotoThumbnail(
                    photo: photos[index],
                    urls: urls,
                  ),
                  title: Text(
                    photos[index].caption ??
                        photos[index].photoType.localizedLabel(context.l10n),
                  ),
                  subtitle: Text(
                    photos[index].photoType.localizedLabel(context.l10n),
                  ),
                  trailing:
                      urls == null ? null : const Icon(Icons.chevron_right),
                  onTap: urls == null
                      ? null
                      : () => TaskPhotoViewer.open(
                            context,
                            photos: photos,
                            initialIndex: index,
                            urls: urls!,
                          ),
                ),
          ],
        ),
      );
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final TreeIssueEvent event;

  @override
  Widget build(BuildContext context) {
    final local = event.createdAt.toLocal();
    final material = MaterialLocalizations.of(context);
    final severity = event.newSeverity ?? event.observedSeverity;
    return WahatCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(_eventIcon(event.type), color: AppColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  event.type.localizedLabel(context.l10n),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${material.formatShortDate(local)} · '
                  '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (severity != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(severity.localizedLabel(context.l10n)),
                  ),
                ],
                if (event.notes?.trim().isNotEmpty == true) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(event.notes!),
                ],
                if (event.taskId != null) ...<Widget>[
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () => context.go('/tasks/${event.taskId}'),
                    icon: const Icon(Icons.assignment_outlined, size: 17),
                    label: Text(context.l10n.issueDetailOpenTask),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: WahatCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(error is OperationFailure
                  ? (error! as OperationFailure).message
                  : context.l10n.issueDetailLoadFailed),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
      );
}

class _SeverityChange {
  const _SeverityChange(this.severity, this.notes);

  final IssueSeverity severity;
  final String notes;
}

IconData _eventIcon(TreeIssueEventType type) => switch (type) {
      TreeIssueEventType.detected => Icons.search,
      TreeIssueEventType.confirmed => Icons.verified_outlined,
      TreeIssueEventType.notObserved => Icons.visibility_off_outlined,
      TreeIssueEventType.severityChanged => Icons.priority_high,
      TreeIssueEventType.resolutionSubmitted => Icons.rate_review_outlined,
      TreeIssueEventType.resolved => Icons.check_circle_outline,
      TreeIssueEventType.unableToFix => Icons.build_circle_outlined,
      TreeIssueEventType.dismissed => Icons.cancel_outlined,
      TreeIssueEventType.reviewReturned => Icons.undo_outlined,
    };

FarmTreeRecord? _treeById(FarmHierarchy? hierarchy, String treeId) {
  if (hierarchy == null) return null;
  for (final tree in hierarchy.trees) {
    if (tree.id == treeId) return tree;
  }
  return null;
}
