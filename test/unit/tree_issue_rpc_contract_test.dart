import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('report_tree_issue payload uses exact enum and tree names', () {
    const payload = TreeIssueDraft(
      treeId: 'tree',
      type: TreeIssueType.leakOrDripperDamage,
      severity: IssueSeverity.high,
      description: 'Broken line',
    );
    expect(payload.toRpcParameters(), <String, Object?>{
      'p_tree_id': 'tree',
      'p_issue_type': 'leak_or_dripper_damage',
      'p_severity': 'high',
      'p_description': 'Broken line',
      'p_photo_storage_path': null,
    });
  });
}
