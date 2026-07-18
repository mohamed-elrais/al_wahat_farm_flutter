import 'dart:async';
import 'dart:convert';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/caching_task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/offline_task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_create_controller.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/task_fakes.dart';

final _en = AppLocalizationsEn();

class _FixedConnectivity implements ConnectivityService {
  _FixedConnectivity(this.status);
  final NetworkStatus status;
  @override
  Future<NetworkStatus> current() async => status;
  @override
  Stream<NetworkStatus> get changes => const Stream<NetworkStatus>.empty();
}

Future<ConnectivityController> _connectivity(NetworkStatus status) async {
  final controller = ConnectivityController(_FixedConnectivity(status));
  await controller.start();
  return controller;
}

const _draft = TaskDraft(
  farmId: 'farm-id',
  type: TaskType.irrigation,
  title: 'Open valve 4',
  assigneeProfileIds: <String>['worker-id'],
);

({
  OfflineTaskRepository repository,
  CachingTaskRepository caching,
  FakeTaskRepository base,
  InMemoryCacheStore cache,
  InMemoryOutboxStore outbox,
}) _harness(ConnectivityController connectivity) {
  final base = FakeTaskRepository(
    store: InMemoryTaskStore(),
    viewerProfileId: 'manager-id',
    canManage: true,
  );
  final cache = InMemoryCacheStore();
  final caching = CachingTaskRepository(inner: base, store: cache);
  final outbox = InMemoryOutboxStore();
  final syncEngine = SyncEngine(
    outbox: outbox,
    executor: TaskMutationExecutor(caching, cache: cache),
    connectivity: connectivity,
  );
  final repository = OfflineTaskRepository(
    inner: caching,
    outbox: outbox,
    connectivity: connectivity,
    cache: cache,
    syncEngine: syncEngine,
  );
  return (
    repository: repository,
    caching: caching,
    base: base,
    cache: cache,
    outbox: outbox,
  );
}

void main() {
  test('offline create queues a create_task op and a provisional list row',
      () async {
    final connectivity = await _connectivity(NetworkStatus.offline);
    addTearDown(connectivity.dispose);
    final h = _harness(connectivity);

    final id = await h.repository.create(_draft);

    expect(id, startsWith(localTaskIdPrefix));
    expect(h.base.createCalls, 0); // nothing hit the backend while offline

    final pending = await h.outbox.pending();
    expect(pending, hasLength(1));
    expect(pending.single.kind, PendingMutationKind.createTask);
    expect(id, '$localTaskIdPrefix${pending.single.opId}');

    final rawList =
        await h.cache.read(CachingTaskRepository.listKeyFor('farm-id'));
    final rows = (jsonDecode(rawList!) as List<Object?>)
        .map((row) => Map<String, Object?>.from(row! as Map))
        .toList();
    expect(rows, hasLength(1));
    expect(rows.single['id'], id);
    expect(rows.single['title'], 'Open valve 4');
    expect(rows.single['status'], 'assigned'); // has an assignee
    expect(FarmTask.fromJson(rows.single).isPendingSync, isTrue);
  });

  test('replaying the create_task op sends the op id and drops the temp row',
      () async {
    final connectivity = await _connectivity(NetworkStatus.offline);
    addTearDown(connectivity.dispose);
    final h = _harness(connectivity);

    final tempId = await h.repository.create(_draft);
    final op = (await h.outbox.pending()).single;

    final executor = TaskMutationExecutor(h.caching, cache: h.cache);
    await executor.execute(op);

    expect(h.base.createCalls, 1);
    expect(h.base.lastCreateOpId, op.opId); // p_op_id sent for dedup
    expect(h.base.store.tasks.values.single.title, 'Open valve 4');

    final rawList =
        await h.cache.read(CachingTaskRepository.listKeyFor('farm-id'));
    final rows = (jsonDecode(rawList!) as List<Object?>)
        .map((row) => Map<String, Object?>.from(row! as Map))
        .toList();
    expect(rows.any((row) => row['id'] == tempId), isFalse); // provisional gone
    expect(rows.single['id'], isNot(startsWith(localTaskIdPrefix)));
  });

  test('online create passes through without an op id or a queued mutation',
      () async {
    final connectivity = await _connectivity(NetworkStatus.online);
    addTearDown(connectivity.dispose);
    final h = _harness(connectivity);

    final id = await h.repository.create(_draft);

    expect(id, isNot(startsWith(localTaskIdPrefix)));
    expect(h.base.createCalls, 1);
    expect(
        h.base.lastCreateOpId, isNull); // direct calls stay deploy-independent
    expect(await h.outbox.pending(), isEmpty);
  });

  test('create controller reports the offline message for a queued creation',
      () async {
    final connectivity = await _connectivity(NetworkStatus.offline);
    addTearDown(connectivity.dispose);
    final h = _harness(connectivity);
    final controller = TaskCreateController(repository: h.repository);
    addTearDown(controller.dispose);

    final id = await controller.submit(_draft);

    expect(id, startsWith(localTaskIdPrefix));
    expect(controller.status, TaskCreateStatus.success);
    expect(controller.message?.call(_en), _en.msgTaskCreatedOffline);
  });
}
