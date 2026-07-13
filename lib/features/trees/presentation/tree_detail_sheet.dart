import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/tree_identity.dart';
import 'package:flutter/material.dart';

class TreeDetailSheet extends StatelessWidget {
  const TreeDetailSheet({
    required this.tree,
    required this.onReportIssue,
    this.onAttachTask,
    super.key,
  });

  final TreeIdentity tree;
  final VoidCallback? onAttachTask;
  final VoidCallback? onReportIssue;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.52,
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
              TreeDetailContent(tree: tree),
              const SizedBox(height: 16),
              if (onAttachTask != null)
                FilledButton.icon(
                  key: const Key('tree-attach-task'),
                  onPressed: onAttachTask,
                  icon: const Icon(Icons.assignment_add),
                  label: Text(context.l10n.attachTask),
                ),
              if (onReportIssue != null)
                OutlinedButton.icon(
                  key: const Key('tree-report-issue'),
                  onPressed: onReportIssue,
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
