import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/reviews/domain/engineer_review.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const timestamp = '2026-07-13T08:30:00.000Z';

  test('parses a tree-targeted farm task using final columns', () {
    final task = FarmTask.fromJson(<String, Object?>{
      'id': 'task',
      'farm_id': 'farm',
      'section_id': null,
      'irrigation_zone_id': null,
      'tree_id': 'tree',
      'related_tree_issue_id': 'issue',
      'task_type': 'tree_inspection',
      'title': 'Inspect TREE-A-001',
      'description': null,
      'priority': 'high',
      'status': 'needs_engineer_review',
      'scheduled_for': '2026-07-13',
      'planned_start_time': '08:30:00',
      'planned_duration_minutes': 45,
      'due_at': timestamp,
      'instructions': <String, Object?>{'check': 'leaves'},
      'requires_engineer_review': true,
      'created_by_profile_id': 'manager',
      'completed_by_profile_id': null,
      'completed_at': null,
      'approved_by_profile_id': null,
      'approved_at': null,
      'cancelled_by_profile_id': null,
      'cancelled_at': null,
      'cancellation_reason': null,
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    expect(task.type, TaskType.treeInspection);
    expect(task.priority, TaskPriority.high);
    expect(task.status, TaskStatus.needsEngineerReview);
    expect(task.treeId, 'tree');
    expect(task.instructions, <String, Object?>{'check': 'leaves'});
  });

  test('parses immutable activity and photo metadata', () {
    final activity = TaskActivity.fromJson(<String, Object?>{
      'id': 'activity',
      'task_id': 'task',
      'actor_profile_id': 'worker',
      'action': 'photo_added',
      'old_status': 'in_progress',
      'new_status': 'completed',
      'note': 'Done',
      'metadata': <String, Object?>{'photo_type': 'after'},
      'created_at': timestamp,
    });
    final photo = TaskPhoto.fromJson(<String, Object?>{
      'id': 'photo',
      'task_id': 'task',
      'task_activity_log_id': 'activity',
      'engineer_review_id': null,
      'storage_bucket_id': 'farm-evidence',
      'storage_path': 'user/farm/task/after.jpg',
      'photo_type': 'after',
      'caption': null,
      'uploaded_by_profile_id': 'worker',
      'taken_at': timestamp,
      'created_at': timestamp,
    });

    expect(activity.action, TaskActivityAction.photoAdded);
    expect(activity.oldStatus, TaskStatus.inProgress);
    expect(photo.photoType, TaskPhotoType.after);
    expect(photo.storageBucketId, 'farm-evidence');
  });

  test('parses final tree issue and engineer review terminology', () {
    final issue = TreeIssue.fromJson(<String, Object?>{
      'id': 'issue',
      'farm_id': 'farm',
      'tree_id': 'tree',
      'issue_type': 'tree_damage',
      'severity': 'urgent',
      'status': 'in_review',
      'description': 'Broken branch',
      'reported_by_profile_id': 'worker',
      'reported_at': timestamp,
      'reviewed_by_profile_id': null,
      'reviewed_at': null,
      'resolved_by_profile_id': null,
      'resolved_at': null,
      'resolution_notes': null,
      'linked_task_id': 'task',
      'created_at': timestamp,
      'updated_at': timestamp,
    });
    final review = EngineerReview.fromJson(<String, Object?>{
      'id': 'review',
      'task_id': 'task',
      'tree_issue_id': 'issue',
      'reviewer_profile_id': 'engineer',
      'decision': 'follow_up_required',
      'notes': 'Inspect again tomorrow',
      'reviewed_at': timestamp,
      'created_at': timestamp,
    });

    expect(issue.type, TreeIssueType.treeDamage);
    expect(issue.status, TreeIssueStatus.inReview);
    expect(review.decision, EngineerReviewDecision.followUpRequired);
    expect(review.treeIssueId, 'issue');
  });

  test('rejects obsolete enum values', () {
    expect(() => TaskType.fromJson('palm_inspection'), throwsFormatException);
    expect(() => TreeIssueType.fromJson('palm_damage'), throwsFormatException);
  });
}
