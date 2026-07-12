import 'package:al_wahat_farm_flutter/features/issues/data/tree_issue_repository.dart';
import 'package:al_wahat_farm_flutter/features/reviews/data/engineer_review_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('operational reads use final tree-based columns', () {
    expect(SupabaseTaskRepository.taskColumns, contains('tree_id'));
    expect(
      SupabaseTaskRepository.taskColumns,
      contains('related_tree_issue_id'),
    );
    expect(SupabaseTreeIssueRepository.issueColumns, contains('tree_id'));
    expect(
      SupabaseEngineerReviewRepository.reviewColumns,
      contains('tree_issue_id'),
    );

    final allColumns = <String>[
      SupabaseTaskRepository.taskColumns,
      SupabaseTreeIssueRepository.issueColumns,
      SupabaseEngineerReviewRepository.reviewColumns,
    ].join(',');
    expect(allColumns, isNot(contains('palm')));
  });
}
