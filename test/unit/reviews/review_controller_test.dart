import 'package:al_wahat_farm_flutter/features/reviews/domain/engineer_review.dart';
import 'package:al_wahat_farm_flutter/features/reviews/presentation/review_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/task_fakes.dart';

void main() {
  group('ReviewController', () {
    test('approval records a review, approves the task, and refreshes',
        () async {
      final store = InMemoryTaskStore();
      final taskId = await _taskAwaitingReview(store);
      var refreshes = 0;
      final reviewRepo = _reviewer(store);
      final controller = _controller(
        store: store,
        reviewRepo: reviewRepo,
        taskId: taskId,
        onReviewed: () async => refreshes++,
      );
      addTearDown(controller.dispose);
      await controller.load();

      expect(controller.status, ReviewStatus.ready);
      expect(controller.canDecide, isTrue);

      final ok = await controller.submit(
        decision: EngineerReviewDecision.approved,
        notes: 'Clean work, approved.',
      );

      expect(ok, isTrue);
      expect(reviewRepo.reviewCalls, 1);
      expect(refreshes, 1);
      expect(store.tasks[taskId]!.status, TaskStatus.approved);
      expect(store.tasks[taskId]!.approvedByProfileId, 'manager-id');
      expect(controller.reviews, hasLength(1));
      expect(
          controller.reviews.first.decision, EngineerReviewDecision.approved);
      expect(controller.details!.task.status, TaskStatus.approved);
      expect(
        controller.details!.activity.first.action,
        TaskActivityAction.reviewedApproved,
      );
      expect(controller.canDecide, isFalse);
    });

    test('return for correction moves the task to returned', () async {
      final store = InMemoryTaskStore();
      final taskId = await _taskAwaitingReview(store);
      final controller = _controller(
        store: store,
        reviewRepo: _reviewer(store),
        taskId: taskId,
      );
      addTearDown(controller.dispose);
      await controller.load();

      final ok = await controller.submit(
        decision: EngineerReviewDecision.returnedForCorrection,
        notes: 'Add a clearer after photo.',
      );

      expect(ok, isTrue);
      expect(store.tasks[taskId]!.status, TaskStatus.returned);
      expect(store.tasks[taskId]!.approvedByProfileId, isNull);
      expect(
        controller.details!.activity.first.action,
        TaskActivityAction.reviewedReturned,
      );
    });

    test('follow-up required keeps the task in engineer review', () async {
      final store = InMemoryTaskStore();
      final taskId = await _taskAwaitingReview(store);
      final controller = _controller(
        store: store,
        reviewRepo: _reviewer(store),
        taskId: taskId,
      );
      addTearDown(controller.dispose);
      await controller.load();

      final ok = await controller.submit(
        decision: EngineerReviewDecision.followUpRequired,
        notes: 'Schedule a follow-up inspection.',
      );

      expect(ok, isTrue);
      expect(store.tasks[taskId]!.status, TaskStatus.needsEngineerReview);
      expect(controller.canDecide, isTrue);
      expect(controller.reviews.first.decision,
          EngineerReviewDecision.followUpRequired);
    });

    test('worker review is denied at the backend boundary', () async {
      final store = InMemoryTaskStore();
      final taskId = await _taskAwaitingReview(store);
      final reviewRepo = FakeEngineerReviewRepository(
        store: store,
        reviewerProfileId: 'worker-id',
        canReview: false,
      );
      // A manager task repository still resolves the detail; the denial must
      // come from the review RPC itself, not from reading the task.
      final controller = _controller(
        store: store,
        reviewRepo: reviewRepo,
        taskId: taskId,
      );
      addTearDown(controller.dispose);
      await controller.load();

      final ok = await controller.submit(
        decision: EngineerReviewDecision.approved,
      );

      expect(ok, isFalse);
      expect(reviewRepo.reviewCalls, 0);
      expect(store.tasks[taskId]!.status, TaskStatus.needsEngineerReview);
      expect(controller.message, contains('owner or agricultural engineer'));
    });

    test('review photo uploads once and retries without re-uploading',
        () async {
      final store = InMemoryTaskStore();
      final taskId = await _taskAwaitingReview(store);
      final reviewRepo = _reviewer(store)..reviewFailuresRemaining = 1;
      final storage = FakeTaskEvidenceStorage();
      final controller = _controller(
        store: store,
        reviewRepo: reviewRepo,
        taskId: taskId,
        storage: storage,
      );
      addTearDown(controller.dispose);
      await controller.load();
      await controller.pickPhoto(TaskEvidenceSource.camera);

      final first = await controller.submit(
        decision: EngineerReviewDecision.approved,
      );
      expect(first, isFalse);
      expect(controller.message, contains('photo is uploaded'));

      final second = await controller.submit(
        decision: EngineerReviewDecision.approved,
      );

      expect(second, isTrue);
      expect(storage.uploadCount, 1);
      expect(store.tasks[taskId]!.status, TaskStatus.approved);
      final photos = store.photos[taskId]!;
      expect(photos.where((photo) => photo.photoType == TaskPhotoType.review),
          hasLength(1));
    });

    test('reviewing a completed task that never required review is allowed',
        () async {
      final store = InMemoryTaskStore();
      final taskId = await _completedTask(store);
      final controller = _controller(
        store: store,
        reviewRepo: _reviewer(store),
        taskId: taskId,
      );
      addTearDown(controller.dispose);
      await controller.load();

      expect(controller.canDecide, isTrue);
      expect(
        await controller.submit(decision: EngineerReviewDecision.approved),
        isTrue,
      );
      expect(store.tasks[taskId]!.status, TaskStatus.approved);
    });
  });
}

FakeEngineerReviewRepository _reviewer(InMemoryTaskStore store) =>
    FakeEngineerReviewRepository(
      store: store,
      reviewerProfileId: 'manager-id',
      canReview: true,
    );

ReviewController _controller({
  required InMemoryTaskStore store,
  required FakeEngineerReviewRepository reviewRepo,
  required String taskId,
  FakeTaskEvidenceStorage? storage,
  Future<void> Function()? onReviewed,
}) =>
    ReviewController(
      taskRepository: FakeTaskRepository(
        store: store,
        viewerProfileId: 'manager-id',
        canManage: true,
      ),
      reviewRepository: reviewRepo,
      evidencePicker: FakeTaskEvidencePicker(),
      evidenceStorage: storage ?? FakeTaskEvidenceStorage(),
      taskId: taskId,
      farmId: 'farm-id',
      userId: 'manager-id',
      onReviewed: onReviewed,
    );

/// Creates a task that a worker completed and flagged for engineer review.
Future<String> _taskAwaitingReview(InMemoryTaskStore store) async {
  final manager = FakeTaskRepository(
    store: store,
    viewerProfileId: 'manager-id',
    canManage: true,
  );
  final taskId = await manager.create(
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

/// Creates a task a worker completed without requiring review.
Future<String> _completedTask(InMemoryTaskStore store) async {
  final manager = FakeTaskRepository(
    store: store,
    viewerProfileId: 'manager-id',
    canManage: true,
  );
  final taskId = await manager.create(
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
