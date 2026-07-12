import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('create_farm_task payload uses final tree parameter names', () {
    final payload = TaskDraft(
      farmId: 'farm',
      type: TaskType.treeInspection,
      title: ' Inspect tree ',
      treeId: 'tree',
      scheduledFor: DateTime(2026, 7, 12),
      priority: TaskPriority.urgent,
      assigneeProfileIds: const <String>['worker'],
    ).toRpcParameters();

    expect(payload['p_tree_id'], 'tree');
    expect(payload['p_task_type'], 'tree_inspection');
    expect(payload['p_title'], 'Inspect tree');
    expect(payload['p_scheduled_for'], '2026-07-12');
    expect(payload['p_priority'], 'urgent');
    expect(payload, isNot(contains('p_palm_tree_id')));
    expect(payload, contains('p_related_tree_issue_id'));
  });

  test('rejects multiple specific scopes', () {
    const draft = TaskDraft(
      farmId: 'farm',
      type: TaskType.general,
      title: 'Invalid target',
      sectionId: 'section',
      treeId: 'tree',
    );
    expect(draft.validate(), 'Choose only one specific target');
  });
}
