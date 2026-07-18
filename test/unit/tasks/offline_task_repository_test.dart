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
import 'package:flutter_test/flutter_test.dart';

import '../../support/task_fakes.dart';

class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService(this._status);
  NetworkStatus _status;
  final StreamController<NetworkStatus> _controller =
      StreamController<NetworkStatus>.broadcast();
  void emit(NetworkStatus s) {
    _status = s;
    _controller.add(s);
  }

  @override
  Future<NetworkStatus> current() async => _status;
  @override
  Stream<NetworkStatus> get changes => _controller.stream;
  Future<void> close() => _controller.close();
}

class _Harness {
  _Harness(this.store, this.outbox, this.inner, this.connectivity, this.service,
      this.offline, this.syncEngine);
  final InMemoryCacheStore store;
  final InMemoryOutboxStore outbox;
  final FakeTaskRepository inner;
  final ConnectivityController connectivity;
  final _FakeConnectivityService service;
  final OfflineTaskRepository offline;
  final SyncEngine syncEngine;

  /// Deterministically brings the device online and drains the outbox. (The
  /// automatic connectivity-triggered sync is covered in sync_engine_test.)
  Future<void> reconnectAndSync() async {
    service.emit(NetworkStatus.online);
    await Future<void>.delayed(Duration.zero);
    await syncEngine.sync();
  }

  Future<TaskStatus?> cachedStatus(String taskId) async {
    final raw = await store.read(CachingTaskRepository.detailKeyFor(taskId));
    if (raw == null) return null;
    final json = Map<String, Object?>.from(jsonDecode(raw) as Map);
    final task = Map<String, Object?>.from(json['task']! as Map);
    return TaskStatus.fromJson(task['status']! as String);
  }
}

Future<_Harness> _harness({required NetworkStatus status}) async {
  final store = InMemoryCacheStore();
  final outbox = InMemoryOutboxStore();
  final fake = FakeTaskRepository(
    store: InMemoryTaskStore(),
    viewerProfileId: 'manager-id',
    canManage: true,
  );
  final caching = CachingTaskRepository(inner: fake, store: store);
  final service = _FakeConnectivityService(status);
  final connectivity = ConnectivityController(service);
  await connectivity.start();
  final syncEngine = SyncEngine(
    outbox: outbox,
    executor: TaskMutationExecutor(caching),
    connectivity: connectivity,
  );
  final offline = OfflineTaskRepository(
    inner: caching,
    outbox: outbox,
    connectivity: connectivity,
    cache: store,
    syncEngine: syncEngine,
  );
  return _Harness(
      store, outbox, fake, connectivity, service, offline, syncEngine);
}

Future<String> _seedAssignedTask(_Harness h) async {
  final taskId = await h.inner.create(
    const TaskDraft(
      farmId: 'farm-id',
      type: TaskType.irrigation,
      title: 'Open north valve',
      assigneeProfileIds: <String>['worker-id'],
    ),
  );
  await h.offline.loadDetails(taskId); // populate the detail cache
  return taskId;
}

void main() {
  test('online start passes straight through and queues nothing', () async {
    final h = await _harness(status: NetworkStatus.online);
    addTearDown(h.connectivity.dispose);
    addTearDown(h.service.close);
    final taskId = await _seedAssignedTask(h);

    await h.offline.start(taskId);

    expect(h.inner.store.tasks[taskId]!.status, TaskStatus.inProgress);
    expect(await h.outbox.pendingCount(), 0);
  });

  test('offline start queues the op and patches the cached status', () async {
    final h = await _harness(status: NetworkStatus.offline);
    addTearDown(h.connectivity.dispose);
    addTearDown(h.service.close);
    final taskId = await _seedAssignedTask(h);

    await h.offline.start(taskId);

    // Backend not touched, op queued, cached detail optimistically updated.
    expect(h.inner.store.tasks[taskId]!.status, TaskStatus.assigned);
    final pending = await h.outbox.pending();
    expect(pending, hasLength(1));
    expect(pending.single.kind, PendingMutationKind.startTask);
    expect(pending.single.payload['taskId'], taskId);
    expect(await h.cachedStatus(taskId), TaskStatus.inProgress);
  });

  test('queued transition replays once connectivity returns', () async {
    final h = await _harness(status: NetworkStatus.offline);
    addTearDown(h.connectivity.dispose);
    addTearDown(h.service.close);
    final taskId = await _seedAssignedTask(h);
    await h.offline.start(taskId);

    await h.reconnectAndSync();

    expect(h.inner.store.tasks[taskId]!.status, TaskStatus.inProgress);
    expect(await h.outbox.pendingCount(), 0);
  });

  test('offline complete then reconnect drives the task to completed',
      () async {
    final h = await _harness(status: NetworkStatus.offline);
    addTearDown(h.connectivity.dispose);
    addTearDown(h.service.close);
    final taskId = await _seedAssignedTask(h);

    await h.offline.complete(taskId, note: 'done');
    expect(await h.cachedStatus(taskId), TaskStatus.completed);

    await h.reconnectAndSync();

    expect(h.inner.store.tasks[taskId]!.status, TaskStatus.completed);
    expect(await h.outbox.pendingCount(), 0);
  });
}
