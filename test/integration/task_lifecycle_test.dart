import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_create_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_detail_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/task_fakes.dart';

void main() {
  test(
      'task survives restart, reaches assignee, transitions, and records evidence',
      () async {
    final store = InMemoryTaskStore();
    final managerRepository = FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    );
    final managerWorkspace = TaskWorkspaceController(
      repository: managerRepository,
      farmId: 'farm-id',
    );
    final creator = TaskCreateController(
      repository: managerRepository,
      onCreated: managerWorkspace.refresh,
    );
    addTearDown(managerWorkspace.dispose);
    addTearDown(creator.dispose);

    final taskId = await creator.submit(
      TaskDraft(
        farmId: 'farm-id',
        type: TaskType.dripperMaintenance,
        title: 'Replace blocked dripper',
        treeId: 'tree-id',
        scheduledFor: DateTime(2026, 7, 13),
        assigneeProfileIds: const <String>['worker-id'],
      ),
    );
    expect(taskId, isNotNull);

    final firstSession = TaskWorkspaceController(
      repository: FakeTaskRepository(
        store: store,
        viewerProfileId: 'worker-id',
        canManage: false,
      ),
      farmId: 'farm-id',
    );
    await firstSession.load();
    expect(firstSession.taskById(taskId!), isNotNull);
    firstSession.dispose();

    final restartedRepository = FakeTaskRepository(
      store: store,
      viewerProfileId: 'worker-id',
      canManage: false,
    );
    final restartedWorkspace = TaskWorkspaceController(
      repository: restartedRepository,
      farmId: 'farm-id',
    );
    addTearDown(restartedWorkspace.dispose);
    await restartedWorkspace.load();
    expect(restartedWorkspace.taskById(taskId), isNotNull);

    final storage = FakeTaskEvidenceStorage();
    final detail = TaskDetailController(
      repository: restartedRepository,
      evidencePicker: FakeTaskEvidencePicker(),
      evidenceStorage: storage,
      taskId: taskId,
      farmId: 'farm-id',
      userId: 'worker-id',
      onMutated: restartedWorkspace.refresh,
    );
    addTearDown(detail.dispose);
    await detail.load();
    expect(await detail.start(note: 'Beginning repair'), isTrue);
    await detail.pickEvidence(TaskEvidenceSource.camera);
    expect(
      await detail.complete(
        note: 'Dripper replaced',
        evidenceType: TaskPhotoType.after,
        evidenceCaption: 'New dripper flowing',
      ),
      isTrue,
    );

    final persisted = await managerRepository.loadDetails(taskId);
    expect(persisted.task.status, TaskStatus.completed);
    expect(persisted.photos, hasLength(1));
    expect(persisted.photos.single.caption, 'New dripper flowing');
    expect(
      persisted.activity.map((item) => item.action),
      containsAll(<TaskActivityAction>[
        TaskActivityAction.created,
        TaskActivityAction.started,
        TaskActivityAction.photoAdded,
        TaskActivityAction.completed,
      ]),
    );
    expect(storage.uploadCount, 1);
  });
}
