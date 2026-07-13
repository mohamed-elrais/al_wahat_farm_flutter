import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
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
                  label: const Text('Attach a task'),
                ),
              if (onReportIssue != null)
                OutlinedButton.icon(
                  key: const Key('tree-report-issue'),
                  onPressed: onReportIssue,
                  icon: const Icon(Icons.report_outlined),
                  label: const Text('Report an issue'),
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
        const Eyebrow('Selected tree'),
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
            _Detail(label: 'Section', value: tree.sectionCode),
            _Detail(
              label: 'Row / tree',
              value: '${tree.rowNumber ?? '—'} / ${tree.treeNumber ?? '—'}',
            ),
            _Detail(label: 'Health', value: tree.healthStatus),
            _Detail(label: 'Type', value: tree.type),
            _Detail(label: 'Zone', value: tree.zoneLabel ?? 'Unassigned'),
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
  Widget build(BuildContext context) => const WahatCard(
        child: Text(
          'This geometry point is not available in live farm data, so operational actions are disabled.',
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
