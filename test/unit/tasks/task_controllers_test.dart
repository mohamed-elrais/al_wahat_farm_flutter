import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_create_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_detail_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/task_fakes.dart';

void main() {
  test('workspace exposes only worker assignments and filters today', () async {
    final store = InMemoryTaskStore();
    final manager = _manager(store);
    await manager.create(
      TaskDraft(
        farmId: 'farm-id',
        type: TaskType.irrigation,
        title: 'Assigned today',
        scheduledFor: DateTime(2026, 7, 13),
        assigneeProfileIds: const <String>['worker-id'],
      ),
    );
    await manager.create(
      TaskDraft(
        farmId: 'farm-id',
        type: TaskType.general,
        title: 'Manager only',
        scheduledFor: DateTime(2026, 7, 13),
      ),
    );
    final workspace = TaskWorkspaceController(
      repository: _worker(store),
      farmId: 'farm-id',
    );
    addTearDown(workspace.dispose);

    await workspace.load();

    expect(workspace.snapshot.status, TaskWorkspaceStatus.ready);
    expect(workspace.snapshot.tasks.map((task) => task.title),
        <String>['Assigned today']);
    expect(workspace.tasksForDay(DateTime(2026, 7, 13)), hasLength(1));
  });

  test('create controller validates and prevents duplicate submission',
      () async {
    final store = InMemoryTaskStore();
    final repository = _manager(store);
    final controller = TaskCreateController(repository: repository);
    addTearDown(controller.dispose);

    final invalid = await controller.submit(
      const TaskDraft(
        farmId: 'farm-id',
        type: TaskType.general,
        title: ' ',
      ),
    );
    expect(invalid, isNull);
    expect(controller.message, 'Task title is required');

    const draft = TaskDraft(
      farmId: 'farm-id',
      type: TaskType.treeInspection,
      title: 'Inspect tree',
      assigneeProfileIds: <String>['worker-id'],
    );
    final first = await controller.submit(draft);
    final retry = await controller.submit(draft);

    expect(first, retry);
    expect(repository.createCalls, 1);
    expect(controller.status, TaskCreateStatus.success);
  });

  test('ambiguous photo response reconciles committed storage path', () async {
    final store = InMemoryTaskStore();
    final taskId = await _createAssignedTask(store);
    final repository = _worker(store)
      ..addPhotoFailureAfterCommit = const OperationFailure(
        OperationFailureKind.unexpected,
        'Response lost.',
      );
    final picker = FakeTaskEvidencePicker();
    final storage = FakeTaskEvidenceStorage();
    final controller = _detail(
      repository: repository,
      picker: picker,
      storage: storage,
      taskId: taskId,
    );
    addTearDown(controller.dispose);
    await controller.load();

    await controller.pickEvidence(TaskEvidenceSource.gallery);
    final success = await controller.addEvidence(
      type: TaskPhotoType.evidence,
      caption: 'Flow restored',
    );

    expect(success, isTrue);
    expect(storage.uploadCount, 1);
    expect(repository.uploadRegistrations, 1);
    expect(store.photos[taskId], hasLength(1));
    expect(controller.message, 'Task evidence saved.');
  });

  test('manager assignment edit replaces active assignees and logs activity',
      () async {
    final store = InMemoryTaskStore();
    final repository = _manager(store);
    final taskId = await repository.create(
      const TaskDraft(
        farmId: 'farm-id',
        type: TaskType.general,
        title: 'Assign field work',
      ),
    );
    final controller = _detail(
      repository: repository,
      picker: FakeTaskEvidencePicker(),
      storage: FakeTaskEvidenceStorage(),
      taskId: taskId,
      userId: 'manager-id',
    );
    addTearDown(controller.dispose);
    await controller.load();

    expect(await controller.setAssignments(<String>['worker-id']), isTrue);

    expect(controller.details!.task.status, TaskStatus.assigned);
    expect(
      controller.details!.assignments
          .where((assignment) => assignment.isActive)
          .single
          .assigneeProfileId,
      'worker-id',
    );
    expect(
        controller.details!.activity.first.action, TaskActivityAction.assigned);
  });

  test('completion retry does not upload or register evidence twice', () async {
    final store = InMemoryTaskStore();
    final taskId = await _createAssignedTask(store);
    final repository = _worker(store)..completeFailuresRemaining = 1;
    final picker = FakeTaskEvidencePicker();
    final storage = FakeTaskEvidenceStorage();
    final controller = _detail(
      repository: repository,
      picker: picker,
      storage: storage,
      taskId: taskId,
    );
    addTearDown(controller.dispose);
    await controller.load();
    await controller.pickEvidence(TaskEvidenceSource.camera);

    expect(
      await controller.complete(
        note: 'Done',
        evidenceType: TaskPhotoType.after,
      ),
      isFalse,
    );
    expect(controller.message, contains('Evidence is saved'));
    expect(
      await controller.complete(
        note: 'Done',
        evidenceType: TaskPhotoType.after,
      ),
      isTrue,
    );

    expect(storage.uploadCount, 1);
    expect(repository.uploadRegistrations, 1);
    expect(store.photos[taskId], hasLength(1));
    expect(store.tasks[taskId]!.status, TaskStatus.completed);
  });

  test('committed transition remains successful when detail refresh fails',
      () async {
    final store = InMemoryTaskStore();
    final taskId = await _createAssignedTask(store);
    final repository = _worker(store);
    final controller = _detail(
      repository: repository,
      picker: FakeTaskEvidencePicker(),
      storage: FakeTaskEvidenceStorage(),
      taskId: taskId,
    );
    addTearDown(controller.dispose);
    await controller.load();
    repository.detailFailure = StateError('read failed after commit');

    expect(await controller.start(), isTrue);
    expect(store.tasks[taskId]!.status, TaskStatus.inProgress);
    expect(controller.message, 'Task started.');
  });
}

FakeTaskRepository _manager(InMemoryTaskStore store) => FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    );

FakeTaskRepository _worker(InMemoryTaskStore store) => FakeTaskRepository(
      store: store,
      viewerProfileId: 'worker-id',
      canManage: false,
    );

Future<String> _createAssignedTask(InMemoryTaskStore store) =>
    _manager(store).create(
      TaskDraft(
        farmId: 'farm-id',
        type: TaskType.irrigation,
        title: 'Check irrigation',
        scheduledFor: DateTime(2026, 7, 13),
        assigneeProfileIds: const <String>['worker-id'],
      ),
    );

TaskDetailController _detail({
  required FakeTaskRepository repository,
  required FakeTaskEvidencePicker picker,
  required FakeTaskEvidenceStorage storage,
  required String taskId,
  String userId = 'worker-id',
}) =>
    TaskDetailController(
      repository: repository,
      evidencePicker: picker,
      evidenceStorage: storage,
      taskId: taskId,
      farmId: 'farm-id',
      userId: userId,
    );
