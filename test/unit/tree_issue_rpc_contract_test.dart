import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('report_tree_issue payload uses exact enum and tree names', () {
    const payload = TreeIssueDraft(
      treeId: 'tree',
      type: TreeIssueType.excessIrrigation,
      severity: IssueSeverity.high,
      description: 'Pooling water',
    );
    expect(payload.toRpcParameters(), <String, Object?>{
      'p_tree_id': 'tree',
      'p_issue_type': 'excess_irrigation',
      'p_severity': 'high',
      'p_description': 'Pooling water',
      'p_photo_storage_path': null,
    });
  });

  test('issue types match the database enum (merged 2026-10-14)', () {
    expect(
      TreeIssueType.values.map((type) => type.wireValue),
      <String>[
        'insufficient_irrigation',
        'excess_irrigation',
        'clogged_dripper',
        'harmful_weed',
        'pest_or_disease',
        'tree_damage',
        'other',
      ],
    );
    for (final type in TreeIssueType.values) {
      expect(TreeIssueType.fromJson(type.wireValue), type);
    }
  });

  test('the retired leak type reads as a dripper problem', () {
    expect(
      TreeIssueType.fromJson('leak_or_dripper_damage'),
      TreeIssueType.dripperProblem,
    );
  });
}
