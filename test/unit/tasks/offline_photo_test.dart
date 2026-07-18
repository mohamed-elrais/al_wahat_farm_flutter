import 'dart:async';

import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_photo.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/offline_evidence_queue.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_detail_controller.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/task_fakes.dart';

final _en = AppLocalizationsEn();

class _OfflineConnectivity implements ConnectivityService {
  @override
  Future<NetworkStatus> current() async => NetworkStatus.offline;
  @override
  Stream<NetworkStatus> get changes => const Stream<NetworkStatus>.empty();
}

Future<ConnectivityController> _offline() async {
  final c = ConnectivityController(_OfflineConnectivity());
  await c.start();
  return c;
}

Future<String> _assignedTask(InMemoryTaskStore store) => FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    ).create(
      const TaskDraft(
        farmId: 'farm-id',
        type: TaskType.irrigation,
        title: 'Valve',
        assigneeProfileIds: <String>['worker-id'],
      ),
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('executor uploads, registers, and clears a queued photo', () async {
    final store = InMemoryTaskStore();
    final taskId = await _assignedTask(store);
    final repo = FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    );
    final storage = FakeTaskEvidenceStorage();
    final photos = InMemoryPendingPhotoStore();
    await photos.put(PendingPhoto(
      opId: 'p1',
      taskId: taskId,
      userId: 'manager-id',
      farmId: 'farm-id',
      photoType: TaskPhotoType.after.wireValue,
      filename: 'e.jpg',
      contentType: 'image/jpeg',
      bytes: FakeTaskEvidencePicker().evidence!.bytes,
      createdAt: 0,
    ));
    final executor = TaskMutationExecutor(
      repo,
      evidenceStorage: storage,
      pendingPhotos: photos,
    );

    await executor.execute(PendingMutation(
      opId: 'p1',
      kind: PendingMutationKind.addTaskPhoto,
      payload: <String, Object?>{'taskId': taskId},
      createdAt: 0,
    ));

    expect(storage.uploadCount, 1);
    expect(store.photos[taskId], hasLength(1));
    expect(store.photos[taskId]!.single.photoType, TaskPhotoType.after);
    expect(await photos.get('p1'), isNull); // blob cleared after registration
  });

  test('offline addEvidence queues a photo instead of uploading', () async {
    final store = InMemoryTaskStore();
    final taskId = await _assignedTask(store);
    final repo = FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    );
    final storage = FakeTaskEvidenceStorage();
    final outbox = InMemoryOutboxStore();
    final photos = InMemoryPendingPhotoStore();
    final connectivity = await _offline();
    addTearDown(connectivity.dispose);
    final syncEngine = SyncEngine(
      outbox: outbox,
      executor: TaskMutationExecutor(repo,
          evidenceStorage: storage, pendingPhotos: photos),
      connectivity: connectivity,
    );
    final controller = TaskDetailController(
      repository: repo,
      evidencePicker: FakeTaskEvidencePicker(),
      evidenceStorage: storage,
      taskId: taskId,
      farmId: 'farm-id',
      userId: 'manager-id',
      connectivity: connectivity,
      offlineEvidence: OutboxEvidenceQueue(
        outbox: outbox,
        pendingPhotos: photos,
        syncEngine: syncEngine,
      ),
    );
    addTearDown(controller.dispose);

    await controller.load();
    await controller.pickEvidence(TaskEvidenceSource.camera);
    final ok = await controller.addEvidence(type: TaskPhotoType.after);

    expect(ok, isTrue);
    expect(storage.uploadCount, 0); // not uploaded while offline
    final pending = await outbox.pending();
    expect(pending, hasLength(1));
    expect(pending.single.kind, PendingMutationKind.addTaskPhoto);
    expect(await photos.get(pending.single.opId), isNotNull); // blob stored
    expect(
      controller.message?.call(_en),
      _en.msgEvidenceQueuedOffline,
    );
  });
}
