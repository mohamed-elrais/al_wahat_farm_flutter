import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/features/inspections/data/inspection_repository.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_photo.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:al_wahat_farm_flutter/features/sync/presentation/failed_ops_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/caching_task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopExecutor implements MutationExecutor {
  @override
  Future<void> execute(PendingMutation mutation) async {}
}

class _OfflineConnectivity implements ConnectivityService {
  @override
  Future<NetworkStatus> current() async => NetworkStatus.offline;
  @override
  Stream<NetworkStatus> get changes => const Stream<NetworkStatus>.empty();
}

Future<
    ({
      FailedOpsController controller,
      InMemoryOutboxStore outbox,
      InMemoryPendingPhotoStore photos,
      InMemoryCacheStore cache,
    })> _harness() async {
  final outbox = InMemoryOutboxStore();
  final photos = InMemoryPendingPhotoStore();
  final cache = InMemoryCacheStore();
  final connectivity = ConnectivityController(_OfflineConnectivity());
  await connectivity.start();
  addTearDown(connectivity.dispose);
  final engine = SyncEngine(
    outbox: outbox,
    executor: _NoopExecutor(),
    connectivity: connectivity,
  );
  final controller = FailedOpsController(
    syncEngine: engine,
    pendingPhotos: photos,
    cache: cache,
  );
  addTearDown(controller.dispose);
  return (controller: controller, outbox: outbox, photos: photos, cache: cache);
}

Future<void> _enqueueFailed(
    InMemoryOutboxStore outbox, PendingMutation op) async {
  await outbox.enqueue(op);
  await outbox.markFailed(op.opId, error: 'rejected');
}

void main() {
  test('load lists only the failed operations', () async {
    final h = await _harness();
    await _enqueueFailed(
      h.outbox,
      const PendingMutation(
        opId: 'f1',
        kind: PendingMutationKind.startTask,
        payload: <String, Object?>{'taskId': 't'},
        createdAt: 0,
      ),
    );
    await h.outbox.enqueue(const PendingMutation(
      opId: 'p1',
      kind: PendingMutationKind.completeTask,
      payload: <String, Object?>{'taskId': 't'},
      createdAt: 0,
    ));

    await h.controller.load();

    expect(h.controller.ops.map((o) => o.opId), <String>['f1']);
  });

  test('retry moves a failed op back to pending', () async {
    final h = await _harness();
    await _enqueueFailed(
      h.outbox,
      const PendingMutation(
        opId: 'f1',
        kind: PendingMutationKind.startTask,
        payload: <String, Object?>{'taskId': 't'},
        createdAt: 0,
      ),
    );
    await h.controller.load();

    await h.controller.retry('f1');

    expect(await h.outbox.failed(), isEmpty);
    expect((await h.outbox.pending()).single.opId, 'f1');
    expect(h.controller.ops, isEmpty);
  });

  test('discard removes the op, its photo blob, and its provisional row',
      () async {
    final h = await _harness();
    // A failed offline task creation with a captured photo + provisional row.
    await h.cache.write(
      CachingTaskRepository.listKeyFor('farm-id'),
      jsonEncode(<Object?>[
        <String, Object?>{'id': 'local:c1', 'title': 'Ghost'},
      ]),
    );
    await h.photos.put(PendingPhoto(
      opId: 'c1',
      taskId: '',
      userId: 'u',
      farmId: 'farm-id',
      photoType: 'issue',
      filename: 'x.jpg',
      contentType: 'image/jpeg',
      bytes: Uint8List.fromList(<int>[1]),
      createdAt: 0,
    ));
    await _enqueueFailed(
      h.outbox,
      const PendingMutation(
        opId: 'c1',
        kind: PendingMutationKind.createTask,
        payload: <String, Object?>{
          'draft': <String, Object?>{'farm_id': 'farm-id'},
        },
        createdAt: 0,
      ),
    );
    await h.controller.load();

    await h.controller.discard(h.controller.ops.single);

    expect(await h.outbox.failed(), isEmpty);
    expect(await h.photos.get('c1'), isNull);
    final rawList =
        await h.cache.read(CachingTaskRepository.listKeyFor('farm-id'));
    final rows = jsonDecode(rawList!) as List<Object?>;
    expect(rows, isEmpty); // ghost provisional row removed
    expect(h.controller.ops, isEmpty);
  });

  test('discard removes a failed provisional inspection and cached route',
      () async {
    final h = await _harness();
    const localId = 'local:inspection-create';
    await h.cache.write(
      CachingTaskRepository.listKeyFor('farm-id'),
      jsonEncode(<Object?>[
        <String, Object?>{'id': localId, 'title': 'Ghost inspection'},
      ]),
    );
    await h.cache.write(
      OfflineInspectionRepository.cacheKey(localId),
      '{"route":"cached"}',
    );
    await h.cache.write(
      OfflineInspectionRepository.sessionIndexKey(localId),
      localId,
    );
    await _enqueueFailed(
      h.outbox,
      const PendingMutation(
        opId: 'inspection-create',
        kind: PendingMutationKind.createInspection,
        payload: <String, Object?>{
          'draft': <String, Object?>{'farm_id': 'farm-id'},
        },
        createdAt: 0,
      ),
    );
    await h.controller.load();

    await h.controller.discard(h.controller.ops.single);

    expect(
      await h.cache.read(OfflineInspectionRepository.cacheKey(localId)),
      isNull,
    );
    expect(
      await h.cache.read(OfflineInspectionRepository.sessionIndexKey(localId)),
      isNull,
    );
    final rawList =
        await h.cache.read(CachingTaskRepository.listKeyFor('farm-id'));
    expect(jsonDecode(rawList!) as List<Object?>, isEmpty);
  });
}
