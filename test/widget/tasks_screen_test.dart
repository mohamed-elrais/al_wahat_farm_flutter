import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/tasks_screen.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/task_fakes.dart';

void main() {
  testWidgets('manager sees role-filtered tasks and create action',
      (tester) async {
    final store = InMemoryTaskStore();
    final repository = _manager(store);
    final taskId = await repository.create(
      TaskDraft(
        farmId: 'farm-id',
        type: TaskType.irrigation,
        title: 'Inspect irrigation line',
        scheduledFor: DateTime(2026, 7, 13),
      ),
    );
    final workspace = TaskWorkspaceController(
      repository: repository,
      farmId: 'farm-id',
    );
    addTearDown(workspace.dispose);
    await workspace.load();
    String? opened;
    var createTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TasksScreen(
          controller: workspace,
          role: FarmRole.owner,
          hierarchy: _hierarchy,
          now: () => DateTime(2026, 7, 13),
          onOpenTask: (value) => opened = value,
          onCreateTask: () => createTapped = true,
        ),
      ),
    );

    expect(find.text('Inspect irrigation line'), findsOneWidget);
    expect(find.byKey(const Key('create-task-button')), findsOneWidget);
    await tester.tap(find.byKey(Key('task-$taskId')));
    expect(opened, taskId);
    await tester.tap(find.byKey(const Key('create-task-button')));
    expect(createTapped, isTrue);
  });

  testWidgets('a task pending sync shows the badge and is not openable',
      (tester) async {
    final store = InMemoryTaskStore();
    final createdAt = DateTime(2026, 7, 13);
    store.tasks['${localTaskIdPrefix}op1'] = FarmTask(
      id: '${localTaskIdPrefix}op1',
      farmId: 'farm-id',
      type: TaskType.irrigation,
      title: 'Queued offline task',
      priority: TaskPriority.medium,
      status: TaskStatus.assigned,
      instructions: const <String, Object?>{},
      requiresEngineerReview: false,
      createdByProfileId: '',
      createdAt: createdAt,
      updatedAt: createdAt,
      scheduledFor: createdAt,
    );
    final workspace = TaskWorkspaceController(
      repository: _manager(store),
      farmId: 'farm-id',
    );
    addTearDown(workspace.dispose);
    await workspace.load();
    var openedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TasksScreen(
            controller: workspace,
            role: FarmRole.owner,
            hierarchy: _hierarchy,
            now: () => createdAt,
            onOpenTask: (_) => openedCount++,
          ),
        ),
      ),
    );

    expect(find.text('Queued offline task'), findsOneWidget);
    expect(find.byKey(const Key('task-pending-sync-badge')), findsOneWidget);

    await tester.tap(find.byKey(const Key('task-${localTaskIdPrefix}op1')));
    await tester.pump();
    expect(openedCount, 0); // pending tasks do not navigate
    expect(find.text('This task opens once it syncs to the farm.'),
        findsOneWidget);
  });

  testWidgets('worker does not see manager create action', (tester) async {
    final store = InMemoryTaskStore();
    await _manager(store).create(
      TaskDraft(
        farmId: 'farm-id',
        type: TaskType.general,
        title: 'Assigned work',
        scheduledFor: DateTime(2026, 7, 13),
        assigneeProfileIds: const <String>['worker-id'],
      ),
    );
    final workspace = TaskWorkspaceController(
      repository: FakeTaskRepository(
        store: store,
        viewerProfileId: 'worker-id',
        canManage: false,
      ),
      farmId: 'farm-id',
    );
    addTearDown(workspace.dispose);
    await workspace.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TasksScreen(
          controller: workspace,
          role: FarmRole.worker,
          hierarchy: _hierarchy,
          now: () => DateTime(2026, 7, 13),
          onOpenTask: (_) {},
        ),
      ),
    );

    expect(find.text('Assigned work'), findsOneWidget);
    expect(find.byKey(const Key('create-task-button')), findsNothing);
  });
}

FakeTaskRepository _manager(InMemoryTaskStore store) => FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    );

final _hierarchy = FarmHierarchy(
  farmId: 'farm-id',
  sections: const <FarmSection>[],
  zones: const <IrrigationZone>[],
  trees: const <FarmTreeRecord>[],
);
