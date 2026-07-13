import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:flutter/material.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({this.initialTreeId, super.key});

  final String? initialTreeId;

  @override
  Widget build(BuildContext context) {
    final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
    String? treeCode;
    if (hierarchy != null && initialTreeId != null) {
      for (final tree in hierarchy.trees) {
        if (tree.id == initialTreeId) {
          treeCode = tree.treeCode;
          break;
        }
      }
    }
    return PaperBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 110),
        children: <Widget>[
          const Eyebrow('Field operations'),
          const SizedBox(height: 6),
          Text('Today’s tasks',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 18),
          WahatCard(
            child: Column(
              children: <Widget>[
                Icon(
                  treeCode == null
                      ? Icons.cloud_sync_outlined
                      : Icons.park_outlined,
                  size: 38,
                ),
                const SizedBox(height: 12),
                Text(
                  treeCode == null
                      ? 'Task repository is waiting for an authenticated farm context.'
                      : '$treeCode is selected for task creation. The complete task form is delivered in Phase 5.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
