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

  test('approval payload omits optional notes and photo as null', () {
    const draft = ReviewTaskDraft(
      taskId: 'task-id',
      decision: EngineerReviewDecision.approved,
    );

    expect(draft.toRpcParameters(), <String, Object?>{
      'p_task_id': 'task-id',
      'p_decision': 'approved',
      'p_notes': null,
      'p_photo_storage_path': null,
    });
  });

  test('every decision maps to its final enum wire value', () {
    expect(EngineerReviewDecision.approved.wireValue, 'approved');
    expect(
      EngineerReviewDecision.returnedForCorrection.wireValue,
      'returned_for_correction',
    );
    expect(
      EngineerReviewDecision.followUpRequired.wireValue,
      'follow_up_required',
    );
  });

  test('decision json round-trips through the final wire values', () {
    for (final decision in EngineerReviewDecision.values) {
      expect(
        EngineerReviewDecision.fromJson(decision.wireValue),
        decision,
      );
    }
  });
}
