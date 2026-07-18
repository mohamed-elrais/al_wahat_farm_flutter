import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/features/reviews/data/offline_review_queue.dart';
import 'package:al_wahat_farm_flutter/features/reviews/data/review_mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/reviews/domain/engineer_review.dart';
import 'package:al_wahat_farm_flutter/features/reviews/presentation/review_controller.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_photo.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/caching_task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/task_fakes.dart';

final _en = AppLocalizationsEn();

class _OfflineConnectivity implements ConnectivityService {
  @override
  Future<NetworkStatus> current() async => NetworkStatus.offline;
  @override
  Stream<NetworkStatus> get changes => const Stream<NetworkStatus>.empty();
}

Future<ConnectivityController> _offline() async {
  final controller = ConnectivityController(_OfflineConnectivity());
  await controller.start();
  return controller;
}

FarmTask _completedTask(InMemoryTaskStore store) {
  final task = FarmTask(
    id: 'task-1',
    farmId: 'farm-id',
    type: TaskType.treeInspection,
    title: 'Inspect canopy',
    priority: TaskPriority.medium,
    status: TaskStatus.completed,
    instructions: const <String, Object?>{},
    requiresEngineerReview: true,
    createdByProfileId: 'worker-id',
    createdAt: store.now,
    updatedAt: store.now,
  );
  store.tasks[task.id] = task;
  return task;
}

PreparedTaskEvidence _photo() => PreparedTaskEvidence(
      bytes: Uint8List.fromList(<int>[4, 5, 6]),
      filename: 'review.jpg',
      contentType: 'image/jpeg',
    );

void main() {
  test('replaying a review sends the op id and drives the task status',
      () async {
    final store = InMemoryTaskStore();
    _completedTask(store);
    final repo = FakeEngineerReviewRepository(
      store: store,
      reviewerProfileId: 'engineer-id',
      canReview: true,
    );
    final executor = ReviewMutationExecutor(
      reviewRepository: repo,
      evidenceStorage: FakeTaskEvidenceStorage(),
      pendingPhotos: InMemoryPendingPhotoStore(),
    );

    await executor.execute(PendingMutation(
      opId: 'op1',
      kind: PendingMutationKind.reviewTask,
      payload: <String, Object?>{
        'draft': const ReviewTaskDraft(
          taskId: 'task-1',
          decision: EngineerReviewDecision.approved,
        ).toJson(),
      },
      createdAt: 0,
    ));

    expect(repo.reviewCalls, 1);
    expect(repo.lastReviewOpId, 'op1'); // p_op_id sent for ledger dedup
    expect(store.tasks['task-1']!.status, TaskStatus.approved);
  });

  test('replaying a review uploads the photo and registers its path', () async {
    final store = InMemoryTaskStore();
    _completedTask(store);
    final repo = FakeEngineerReviewRepository(
      store: store,
      reviewerProfileId: 'engineer-id',
      canReview: true,
    );
    final storage = FakeTaskEvidenceStorage();
    final photos = InMemoryPendingPhotoStore();
    await photos.put(PendingPhoto(
      opId: 'op2',
      taskId: 'task-1',
      userId: 'engineer-id',
      farmId: 'farm-id',
      photoType: TaskPhotoType.review.wireValue,
      filename: 'review.jpg',
      contentType: 'image/jpeg',
      bytes: Uint8List.fromList(<int>[4, 5, 6]),
      createdAt: 0,
    ));
    final executor = ReviewMutationExecutor(
      reviewRepository: repo,
      evidenceStorage: storage,
      pendingPhotos: photos,
    );

    await executor.execute(PendingMutation(
      opId: 'op2',
      kind: PendingMutationKind.reviewTask,
      payload: <String, Object?>{
        'draft': const ReviewTaskDraft(
          taskId: 'task-1',
          decision: EngineerReviewDecision.returnedForCorrection,
        ).toJson(),
      },
      createdAt: 0,
    ));

    expect(storage.uploadCount, 1);
    expect(store.tasks['task-1']!.status, TaskStatus.returned);
    final reviewPhotos = store.photos['task-1']!
        .where((photo) => photo.photoType == TaskPhotoType.review);
    expect(reviewPhotos, hasLength(1)); // photo path recorded with the review
    expect(await photos.get('op2'), isNull); // blob cleared after registration
  });

  test('offline queueReview enqueues the op, stores the photo, patches cache',
      () async {
    final connectivity = await _offline();
    addTearDown(connectivity.dispose);
    final outbox = InMemoryOutboxStore();
    final photos = InMemoryPendingPhotoStore();
    final cache = InMemoryCacheStore();
    // Seed the cached detail so the optimistic patch has something to update.
    final store = InMemoryTaskStore();
    final task = _completedTask(store);
    await cache.write(
      CachingTaskRepository.detailKeyFor('task-1'),
      jsonEncode(TaskDetails(
        task: task,
        assignments: const [],
        activity: const [],
        photos: const [],
      ).toCacheJson()),
    );
    final syncEngine = SyncEngine(
      outbox: outbox,
      executor: ReviewMutationExecutor(
        reviewRepository: FakeEngineerReviewRepository(
          store: store,
          reviewerProfileId: 'engineer-id',
          canReview: true,
        ),
        evidenceStorage: FakeTaskEvidenceStorage(),
        pendingPhotos: photos,
      ),
      connectivity: connectivity,
    );
    final queue = OutboxReviewQueue(
      outbox: outbox,
      pendingPhotos: photos,
      syncEngine: syncEngine,
      cache: cache,
    );

    await queue.queueReview(
      draft: const ReviewTaskDraft(
        taskId: 'task-1',
        decision: EngineerReviewDecision.approved,
      ),
      userId: 'engineer-id',
      farmId: 'farm-id',
      photo: _photo(),
    );

    final pending = await outbox.pending();
    expect(pending, hasLength(1));
    expect(pending.single.kind, PendingMutationKind.reviewTask);
    expect(await photos.get(pending.single.opId), isNotNull);

    final rawDetail =
        await cache.read(CachingTaskRepository.detailKeyFor('task-1'));
    final cached = TaskDetails.fromCacheJson(
      Map<String, Object?>.from(jsonDecode(rawDetail!) as Map),
    );
    expect(cached.task.status, TaskStatus.approved); // optimistic patch applied
  });

  test('offline submit queues the review and shows the offline message',
      () async {
    final connectivity = await _offline();
    addTearDown(connectivity.dispose);
    final store = InMemoryTaskStore();
    _completedTask(store);
    final TaskRepository taskRepo = FakeTaskRepository(
      store: store,
      viewerProfileId: 'engineer-id',
      canManage: true,
    );
    final reviewRepo = FakeEngineerReviewRepository(
      store: store,
      reviewerProfileId: 'engineer-id',
      canReview: true,
    );
    final outbox = InMemoryOutboxStore();
    final photos = InMemoryPendingPhotoStore();
    final cache = InMemoryCacheStore();
    final syncEngine = SyncEngine(
      outbox: outbox,
      executor: ReviewMutationExecutor(
        reviewRepository: reviewRepo,
        evidenceStorage: FakeTaskEvidenceStorage(),
        pendingPhotos: photos,
      ),
      connectivity: connectivity,
    );
    final controller = ReviewController(
      taskRepository: taskRepo,
      reviewRepository: reviewRepo,
      evidencePicker: FakeTaskEvidencePicker(),
      evidenceStorage: FakeTaskEvidenceStorage(),
      taskId: 'task-1',
      farmId: 'farm-id',
      userId: 'engineer-id',
      connectivity: connectivity,
      offlineQueue: OutboxReviewQueue(
        outbox: outbox,
        pendingPhotos: photos,
        syncEngine: syncEngine,
        cache: cache,
      ),
    );
    addTearDown(controller.dispose);

    await controller.load();
    final ok = await controller.submit(
      decision: EngineerReviewDecision.approved,
    );

    expect(ok, isTrue);
    expect(reviewRepo.reviewCalls, 0); // nothing hit the backend while offline
    expect(
        (await outbox.pending()).single.kind, PendingMutationKind.reviewTask);
    expect(controller.message?.call(_en), _en.msgReviewRecordedOffline);
  });
}
