import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_evidence_service.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
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

  test('task repository names exact lifecycle RPC contracts', () {
    expect(SupabaseTaskRepository.createRpc, 'create_farm_task');
    expect(SupabaseTaskRepository.assignmentsRpc, 'set_task_assignments');
    expect(SupabaseTaskRepository.startRpc, 'start_assigned_task');
    expect(SupabaseTaskRepository.completeRpc, 'complete_task');
    expect(SupabaseTaskRepository.addPhotoRpc, 'add_task_photo');
  });

  test('task evidence metadata uses exact add_task_photo parameter names', () {
    const registration = TaskEvidenceRegistration(
      taskId: 'task-id',
      storagePath: 'user/farm/task/evidence.jpg',
      type: TaskPhotoType.after,
      caption: 'Emitter now flowing',
    );

    expect(registration.toRpcParameters(), <String, Object?>{
      'p_task_id': 'task-id',
      'p_storage_path': 'user/farm/task/evidence.jpg',
      'p_photo_type': 'after',
      'p_caption': 'Emitter now flowing',
    });
  });

  test('task transition capabilities match lifecycle entry points', () {
    expect(TaskStatus.assigned.canStart, isTrue);
    expect(TaskStatus.returned.canStart, isTrue);
    expect(TaskStatus.inProgress.canStart, isFalse);
    expect(TaskStatus.assigned.canComplete, isTrue);
    expect(TaskStatus.inProgress.canComplete, isTrue);
    expect(TaskStatus.completed.canComplete, isFalse);
  });

  test('task evidence path follows authenticated user/farm/task scope', () {
    expect(
      TaskEvidencePath.build(
        userId: 'user-id',
        farmId: 'farm-id',
        taskId: 'task-id',
        filename: 'after photo.jpg',
        timestamp: 123,
      ),
      'user-id/farm-id/task-id/123_after-photo.jpg',
    );
  });
}
