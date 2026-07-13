import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/reviews/presentation/review_controller.dart';
import 'package:al_wahat_farm_flutter/features/reviews/presentation/review_detail_screen.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/task_fakes.dart';

void main() {
  testWidgets('manager approves a task from the review detail', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = InMemoryTaskStore();
    final taskId = await _taskAwaitingReview(store);
    final controller = ReviewController(
      taskRepository: _manager(store),
      reviewRepository: FakeEngineerReviewRepository(
        store: store,
        reviewerProfileId: 'manager-id',
        canReview: true,
      ),
      evidencePicker: FakeTaskEvidencePicker(),
      evidenceStorage: FakeTaskEvidenceStorage(),
      taskId: taskId,
      farmId: 'farm-id',
      userId: 'manager-id',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ReviewDetailScreen(
          taskId: taskId,
          controller: controller,
          role: FarmRole.owner,
          hierarchy: _hierarchy,
          userId: 'manager-id',
          farmId: 'farm-id',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('review-approve-button')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('review-approve-button')));
    await tester.tap(find.byKey(const Key('review-approve-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('review-confirm-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('review-confirm-button')));
    await tester.pumpAndSettle();

    expect(store.tasks[taskId]!.status, TaskStatus.approved);
    expect(controller.details!.task.status, TaskStatus.approved);
    expect(controller.reviews, hasLength(1));
  });

  testWidgets('worker cannot see review actions', (tester) async {
    final store = InMemoryTaskStore();
    final taskId = await _taskAwaitingReview(store);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ReviewDetailScreen(
          taskId: taskId,
          role: FarmRole.worker,
          userId: 'worker-id',
          farmId: 'farm-id',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('review-detail-denied')), findsOneWidget);
    expect(find.byKey(const Key('review-approve-button')), findsNothing);
    expect(find.byKey(const Key('review-return-button')), findsNothing);
    expect(find.byKey(const Key('review-follow-up-button')), findsNothing);
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

final _hierarchy = FarmHierarchy(
  farmId: 'farm-id',
  sections: const <FarmSection>[],
  zones: const <IrrigationZone>[],
  trees: const <FarmTreeRecord>[],
);
