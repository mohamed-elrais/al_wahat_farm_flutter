import 'package:al_wahat_farm_flutter/features/reviews/domain/engineer_review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('review_task payload uses the final exact parameter names', () {
    const draft = ReviewTaskDraft(
      taskId: 'task-id',
      decision: EngineerReviewDecision.returnedForCorrection,
      notes: 'Add a clearer after photo',
      photoStoragePath: 'user/farm/task/review.jpg',
    );

    expect(draft.toRpcParameters(), <String, Object?>{
      'p_task_id': 'task-id',
      'p_decision': 'returned_for_correction',
      'p_notes': 'Add a clearer after photo',
      'p_photo_storage_path': 'user/farm/task/review.jpg',
    });
  });
}
