import 'package:al_wahat_farm_flutter/features/issues/data/issue_photo_service.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/tree_issue_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('issue evidence client uses the requested backend contract', () {
    expect(SupabaseTreeIssueRepository.addPhotoRpc, 'add_tree_issue_photo');
  });

  test('issue evidence path includes authenticated user, farm, and task', () {
    expect(
      IssuePhotoPath.build(
        userId: 'user-id',
        farmId: 'farm-id',
        taskId: 'task-id',
        filename: '../damaged tree?.jpg',
        timestamp: 42,
      ),
      'user-id/farm-id/task-id/42_damaged-tree-.jpg',
    );
  });
}
