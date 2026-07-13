import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/tree_identity.dart';
import 'package:al_wahat_farm_flutter/features/trees/presentation/tree_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TreeDetailScreen extends StatelessWidget {
  const TreeDetailScreen({required this.treeId, super.key});

  final String treeId;

  @override
  Widget build(BuildContext context) {
    final snapshot = FarmHierarchyScope.maybeOf(context);
    final hierarchy = snapshot?.hierarchy;
    final tree = hierarchy == null
        ? null
        : TreeIdentity.fromHierarchy(hierarchy, treeId);
    if (tree == null) return const _TreeUnavailableScreen();

    final canManageTasks = OperationalContextScope.maybeOf(context)
            ?.selectedMembership
            .role
            .canManageTasks ??
        false;
    return PaperBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              key: const Key('tree-detail-back'),
              tooltip: 'Back',
              onPressed: context.pop,
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          WahatCard(child: TreeDetailContent(tree: tree)),
          const SizedBox(height: 12),
          if (canManageTasks)
            FilledButton.icon(
              key: const Key('tree-detail-attach-task'),
              onPressed: () => context.go('/tasks/create?treeId=${tree.id}'),
              icon: const Icon(Icons.assignment_add),
              label: const Text('Attach a task'),
            ),
          OutlinedButton.icon(
            key: const Key('tree-detail-report-issue'),
            onPressed: () => context.push(
              '/map/tree/${tree.id}/report-issue',
            ),
            icon: const Icon(Icons.report_outlined),
            label: const Text('Report an issue'),
          ),
        ],
      ),
    );
  }
}

class _TreeUnavailableScreen extends StatelessWidget {
  const _TreeUnavailableScreen();

  @override
  Widget build(BuildContext context) => PaperBackground(
        child: Center(
          child: WahatCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.qr_code_2, size: 42),
                const SizedBox(height: 12),
                Text(
                  'Tree unavailable',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This tree is inactive or no longer visible to your farm.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: context.pop,
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
}
