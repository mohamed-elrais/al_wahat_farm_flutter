import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_workspace.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/tree_identity.dart';
import 'package:flutter/material.dart';

class TreeDetailSheet extends StatefulWidget {
  const TreeDetailSheet({
    required this.tree,
    required this.onReportIssue,
    this.activeIssues = const <TreeIssueSummary>[],
    this.loadHistory,
    this.onOpenIssue,
    this.onAttachTask,
    super.key,
  });

  final TreeIdentity tree;
  final List<TreeIssueSummary> activeIssues;
  final Future<List<TreeIssueOccurrence>> Function()? loadHistory;
  final ValueChanged<String>? onOpenIssue;
  final VoidCallback? onAttachTask;
  final VoidCallback? onReportIssue;

  @override
  State<TreeDetailSheet> createState() => _TreeDetailSheetState();
}

class _TreeDetailSheetState extends State<TreeDetailSheet> {
  Future<List<TreeIssueOccurrence>>? _history;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _history = widget.loadHistory?.call();
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.64,
        minChildSize: 0.3,
        maxChildSize: 0.88,
        expand: false,
        builder: (_, controller) => DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TreeDetailContent(tree: widget.tree),
              if (widget.activeIssues.isNotEmpty) ...<Widget>[
                const SizedBox(height: 18),
                _ActiveIssues(
                  issues: widget.activeIssues,
                  onOpenIssue: widget.onOpenIssue,
                ),
              ],
              if (_history != null) ...<Widget>[
                const SizedBox(height: 18),
                _TreeIssueHistory(
                  history: _history!,
                  onOpenIssue: widget.onOpenIssue,
                  onRetry: () => setState(_loadHistory),
                ),
              ],
              const SizedBox(height: 16),
              if (widget.onAttachTask != null)
                FilledButton.icon(
                  key: const Key('tree-attach-task'),
                  onPressed: widget.onAttachTask,
                  icon: const Icon(Icons.assignment_add),
                  label: Text(context.l10n.attachTask),
                ),
              if (widget.onReportIssue != null)
                OutlinedButton.icon(
                  key: const Key('tree-report-issue'),
                  onPressed: widget.onReportIssue,
                  icon: const Icon(Icons.report_outlined),
                  label: Text(context.l10n.reportAnIssue),
                )
              else
                const _UnavailableTreeMessage(),
            ],
          ),
        ),
      );
}

class _ActiveIssues extends StatelessWidget {
  const _ActiveIssues({required this.issues, required this.onOpenIssue});

  final List<TreeIssueSummary> issues;
  final ValueChanged<String>? onOpenIssue;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: context.l10n.treeActiveIssuesSemantics(issues.length),
        child: Column(
          key: const Key('tree-active-issues'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              context.l10n.treeActiveIssues(issues.length),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final issue in issues) ...<Widget>[
              _IssueOccurrence(
                type: issue.type,
                severity: issue.severity,
                status: issue.status,
                date: issue.reportedAt,
                onTap: issue.canViewDetails && onOpenIssue != null
                    ? () => onOpenIssue!(issue.id)
                    : null,
              ),
              const SizedBox(height: 7),
            ],
          ],
        ),
      );
}

class _TreeIssueHistory extends StatelessWidget {
  const _TreeIssueHistory({
    required this.history,
    required this.onOpenIssue,
    required this.onRetry,
  });

  final Future<List<TreeIssueOccurrence>> history;
  final ValueChanged<String>? onOpenIssue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
        key: const Key('tree-issue-history'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            context.l10n.treeIssueHistory,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<TreeIssueOccurrence>>(
            future: history,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return OutlinedButton.icon(
                  key: const Key('tree-issue-history-retry'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.treeIssueHistoryLoadFailed),
                );
              }
              final occurrences =
                  (snapshot.data ?? const <TreeIssueOccurrence>[])
                      .where((issue) =>
                          issue.status == TreeIssueStatus.resolved ||
                          issue.status == TreeIssueStatus.dismissed)
                      .toList(growable: false);
              if (occurrences.isEmpty) {
                return Text(context.l10n.treeIssueHistoryEmpty);
              }
              return Semantics(
                container: true,
                label:
                    context.l10n.treeIssueHistorySemantics(occurrences.length),
                child: Column(
                  children: <Widget>[
                    for (final issue in occurrences) ...<Widget>[
                      _IssueOccurrence(
                        type: issue.type,
                        severity: issue.severity,
                        status: issue.status,
                        date: issue.reportedAt,
                        closedAt: issue.closedAt,
                        onTap: onOpenIssue == null
                            ? null
                            : () => onOpenIssue!(issue.id),
                      ),
                      const SizedBox(height: 7),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      );
}

class _IssueOccurrence extends StatelessWidget {
  const _IssueOccurrence({
    required this.type,
    required this.severity,
    required this.status,
    required this.date,
    this.closedAt,
    required this.onTap,
  });

  final TreeIssueType type;
  final IssueSeverity severity;
  final TreeIssueStatus status;
  final DateTime date;
  final DateTime? closedAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateLabel = MaterialLocalizations.of(context).formatShortDate(date);
    final closedDateLabel = closedAt == null
        ? null
        : MaterialLocalizations.of(context).formatShortDate(closedAt!);
    final datesLabel = closedDateLabel == null
        ? l10n.treeIssueReportedDate(dateLabel)
        : l10n.treeIssueOccurrenceDates(dateLabel, closedDateLabel);
    final semanticLabel = l10n.treeIssueOccurrenceSemantics(
      type.localizedLabel(l10n),
      severity.localizedLabel(l10n),
      status.localizedLabel(l10n),
      datesLabel,
    );
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFFF1EADC),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: <Widget>[
                const Icon(Icons.report_problem_outlined,
                    color: AppColors.issue),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        type.localizedLabel(l10n),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${severity.localizedLabel(l10n)} · '
                        '${status.localizedLabel(l10n)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        datesLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (onTap != null) const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TreeDetailContent extends StatelessWidget {
  const TreeDetailContent({required this.tree, super.key});

  final TreeIdentity tree;

  @override
  Widget build(BuildContext context) {
    final latitude = tree.latitude;
    final longitude = tree.longitude;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Eyebrow(context.l10n.selectedTree),
        Text(
          tree.code,
          key: const Key('tree-detail-code'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Divider(height: 24),
        Wrap(
          spacing: 18,
          runSpacing: 12,
          children: <Widget>[
            _Detail(
                label: context.l10n.treeDetailSection, value: tree.sectionCode),
            _Detail(
              label: context.l10n.treeDetailRowTree,
              value: '${tree.rowNumber ?? '—'} / ${tree.treeNumber ?? '—'}',
            ),
            _Detail(
                label: context.l10n.treeDetailHealth, value: tree.healthStatus),
            _Detail(label: context.l10n.detailType, value: tree.type),
            _Detail(
              label: context.l10n.treeDetailZone,
              value: tree.zoneLabel ?? context.l10n.treeZoneUnassigned,
            ),
          ],
        ),
        if (latitude != null && longitude != null) ...<Widget>[
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF1EADC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                '${latitude.toStringAsFixed(7)}, ${longitude.toStringAsFixed(7)}',
                key: const Key('tree-detail-coordinates'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _UnavailableTreeMessage extends StatelessWidget {
  const _UnavailableTreeMessage();

  @override
  Widget build(BuildContext context) => WahatCard(
        child: Text(
          context.l10n.treeUnavailableActions,
          textAlign: TextAlign.center,
        ),
      );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 8,
                letterSpacing: 0.8,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}
