import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TaskDraft draft({
    List<TaskTarget> targets = const <TaskTarget>[],
    String? sectionId,
  }) =>
      TaskDraft(
        farmId: 'farm-id',
        type: TaskType.irrigation,
        title: 'Task',
        targets: targets,
        sectionId: sectionId,
      );

  test('target list validation enforces the same-kind rule', () {
    expect(draft().validate(), isNull);
    expect(
      draft(targets: const <TaskTarget>[TaskTarget(treeId: 't1')]).validate(),
      isNull,
    );
    expect(
      draft(
        targets: const <TaskTarget>[
          TaskTarget(treeId: 't1'),
          TaskTarget(sectionId: 's1'),
        ],
      ).validate(),
      contains('same kind'),
    );
    expect(
      draft(
        targets: const <TaskTarget>[
          TaskTarget(treeId: 't1'),
          TaskTarget(treeId: 't1'),
        ],
      ).validate(),
      contains('repeat'),
    );
    expect(
      draft(targets: const <TaskTarget>[TaskTarget()]).validate(),
      contains('exactly one scope'),
    );
    expect(
      draft(
        targets: const <TaskTarget>[TaskTarget(treeId: 't1')],
        sectionId: 's1',
      ).validate(),
      contains('not both'),
    );
  });

  test('a single-entry target list collapses to the legacy RPC params', () {
    final params = draft(
      targets: const <TaskTarget>[TaskTarget(irrigationZoneId: 'zone-1')],
    ).toRpcParameters();
    expect(params['p_irrigation_zone_id'], 'zone-1');
    expect(params.containsKey('p_targets'), isFalse);
  });

  test('two or more targets are sent as p_targets with the first mirrored', () {
    final params = draft(
      targets: const <TaskTarget>[
        TaskTarget(treeId: 'tree-1'),
        TaskTarget(treeId: 'tree-2'),
        TaskTarget(treeId: 'tree-3'),
      ],
    ).toRpcParameters();
    expect(params['p_tree_id'], isNull);
    expect(params['p_targets'], <Map<String, Object?>>[
      <String, Object?>{'tree_id': 'tree-1'},
      <String, Object?>{'tree_id': 'tree-2'},
      <String, Object?>{'tree_id': 'tree-3'},
    ]);
  });

  test('targets survive the outbox toJson/fromJson round trip', () {
    final original = draft(
      targets: const <TaskTarget>[
        TaskTarget(sectionId: 'sec-1'),
        TaskTarget(sectionId: 'sec-2'),
      ],
    );
    final revived = TaskDraft.fromJson(original.toJson());
    expect(
      revived.targets.map((target) => target.sectionId),
      <String>['sec-1', 'sec-2'],
    );
    expect(revived.validate(), isNull);
  });
}
