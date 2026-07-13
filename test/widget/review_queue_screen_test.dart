import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/reviews/presentation/review_queue_screen.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/task_fakes.dart';

void main() {
  testWidgets('manager sees tasks awaiting review and can open one',
      (tester) async {
    final store = InMemoryTaskStore();
    final taskId = await _taskAwaitingReview(store);
    final workspace = TaskWorkspaceController(
      repository: _manager(store),
      farmId: 'farm-id',
    );
    addTearDown(workspace.dispose);
    await workspace.load();
    final opened = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ReviewQueueScreen(
          controller: workspace,
          role: FarmRole.owner,
          hierarchy: _hierarchy,
          onOpenReview: opened.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('review-queue-list')), findsOneWidget);
    expect(find.text('Inspect north palms'), findsOneWidget);

    await tester.tap(find.byKey(Key('review-$taskId')));
    await tester.pumpAndSettle();
    expect(opened, <String>[taskId]);
  });

  testWidgets('completed tasks not flagged for review are not queued',
      (tester) async {
    final store = InMemoryTaskStore();
    await _completedTask(store);
    final workspace = TaskWorkspaceController(
      repository: _manager(store),
      farmId: 'farm-id',
    );
    addTearDown(workspace.dispose);
    await workspace.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ReviewQueueScreen(
          controller: workspace,
          role: FarmRole.agriculturalEngineer,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No tasks are waiting'), findsOneWidget);
    expect(find.text('Clear the south path'), findsNothing);
  });

  testWidgets('worker is denied the review queue', (tester) async {
    final store = InMemoryTaskStore();
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
        home: ReviewQueueScreen(
          controller: workspace,
          role: FarmRole.worker,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('review-queue-denied')), findsOneWidget);
    expect(find.byKey(const Key('review-queue-list')), findsNothing);
  });
}

FakeTaskRepository _manager(InMemoryTaskStore store) => FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    );

Future<String> _taskAwaitingReview(InMemoryTaskStore store) async {
  final taskId = await _manager(store).create(
    const TaskDraft(
      farmId: 'farm-id',
      type: TaskType.treeInspection,
      title: 'Inspect north palms',
      assigneeProfileIds: <String>['worker-id'],
    ),
  );
  final worker = FakeTaskRepository(
    store: store,
    viewerProfileId: 'worker-id',
    canManage: false,
  );
  await worker.start(taskId);
  await worker.complete(taskId, requiresEngineerReview: true);
  return taskId;
}

Future<String> _completedTask(InMemoryTaskStore store) async {
  final taskId = await _manager(store).create(
    const TaskDraft(
      farmId: 'farm-id',
      type: TaskType.general,
      title: 'Clear the south path',
      assigneeProfileIds: <String>['worker-id'],
    ),
  );
  final worker = FakeTaskRepository(
    store: store,
    viewerProfileId: 'worker-id',
    canManage: false,
  );
  await worker.start(taskId);
  await worker.complete(taskId);
  return taskId;
}

final _hierarchy = FarmHierarchy(
  farmId: 'farm-id',
  sections: const <FarmSection>[],
  zones: const <IrrigationZone>[],
  trees: const <FarmTreeRecord>[],
);
