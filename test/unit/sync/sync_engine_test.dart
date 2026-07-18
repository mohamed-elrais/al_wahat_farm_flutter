import 'dart:async';

import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService(this._status);
  NetworkStatus _status;
  final StreamController<NetworkStatus> _controller =
      StreamController<NetworkStatus>.broadcast();

  void emit(NetworkStatus status) {
    _status = status;
    _controller.add(status);
  }

  @override
  Future<NetworkStatus> current() async => _status;
  @override
  Stream<NetworkStatus> get changes => _controller.stream;
  Future<void> close() => _controller.close();
}

class _Executor implements MutationExecutor {
  _Executor(this.onExecute);
  final Future<void> Function(PendingMutation) onExecute;
  final List<String> succeeded = <String>[];
  int calls = 0;

  @override
  Future<void> execute(PendingMutation mutation) async {
    calls++;
    await onExecute(mutation);
    succeeded.add(mutation.opId);
  }
}

PendingMutation _op(String id) => PendingMutation(
      opId: id,
      kind: PendingMutationKind.startTask,
      payload: const <String, Object?>{},
      createdAt: 0,
    );

Future<(SyncEngine, ConnectivityController, _FakeConnectivityService)> _engine(
  OutboxStore outbox,
  MutationExecutor executor, {
  NetworkStatus status = NetworkStatus.online,
  int maxAttempts = 5,
}) async {
  final service = _FakeConnectivityService(status);
  final connectivity = ConnectivityController(service);
  await connectivity.start();
  final engine = SyncEngine(
    outbox: outbox,
    executor: executor,
    connectivity: connectivity,
    maxAttempts: maxAttempts,
  );
  return (engine, connectivity, service);
}

void main() {
  test('drains all pending ops in order and clears the queue', () async {
    final outbox = InMemoryOutboxStore();
    await outbox.enqueue(_op('a'));
    await outbox.enqueue(_op('b'));
    await outbox.enqueue(_op('c'));
    final executor = _Executor((_) async {});
    final (engine, connectivity, service) = await _engine(outbox, executor);
    addTearDown(connectivity.dispose);
    addTearDown(service.close);

    final outcome = await engine.sync();

    expect(outcome, SyncOutcome.drained);
    expect(executor.succeeded, <String>['a', 'b', 'c']);
    expect(await outbox.pendingCount(), 0);
  });

  test('does nothing while offline', () async {
    final outbox = InMemoryOutboxStore();
    await outbox.enqueue(_op('a'));
    final executor = _Executor((_) async {});
    final (engine, connectivity, service) =
        await _engine(outbox, executor, status: NetworkStatus.offline);
    addTearDown(connectivity.dispose);
    addTearDown(service.close);

    expect(await engine.sync(), SyncOutcome.offline);
    expect(executor.calls, 0);
    expect(await outbox.pendingCount(), 1);
  });

  test('transient failure stops the drain, preserves order, and resumes',
      () async {
    final outbox = InMemoryOutboxStore();
    await outbox.enqueue(_op('a'));
    await outbox.enqueue(_op('b'));
    var failFirst = true;
    final executor = _Executor((op) async {
      if (op.opId == 'a' && failFirst) {
        throw const OperationFailure(OperationFailureKind.offline, 'drop');
      }
    });
    final (engine, connectivity, service) = await _engine(outbox, executor);
    addTearDown(connectivity.dispose);
    addTearDown(service.close);

    final first = await engine.sync();
    expect(first, SyncOutcome.deferred);
    expect(executor.succeeded, isEmpty); // 'b' not attempted (order preserved)
    final aAfter = (await outbox.pending()).first;
    expect(aAfter.opId, 'a');
    expect(aAfter.attempts, 1);

    failFirst = false;
    final second = await engine.sync();
    expect(second, SyncOutcome.drained);
    expect(executor.succeeded, <String>['a', 'b']);
  });

  test('terminal failure is marked failed and draining continues', () async {
    final outbox = InMemoryOutboxStore();
    await outbox.enqueue(_op('a'));
    await outbox.enqueue(_op('b'));
    final executor = _Executor((op) async {
      if (op.opId == 'a') {
        throw const OperationFailure(
          OperationFailureKind.authorization,
          'denied',
        );
      }
    });
    final (engine, connectivity, service) = await _engine(outbox, executor);
    addTearDown(connectivity.dispose);
    addTearDown(service.close);

    final outcome = await engine.sync();

    expect(outcome, SyncOutcome.hadFailures);
    expect(executor.succeeded, <String>['b']); // b still processed
    expect(await outbox.failedCount(), 1);
    expect((await outbox.failed()).single.opId, 'a');
  });

  test('a transient op becomes failed after maxAttempts', () async {
    final outbox = InMemoryOutboxStore();
    await outbox.enqueue(_op('a'));
    final executor = _Executor((_) async {
      throw const OperationFailure(OperationFailureKind.unexpected, 'flaky');
    });
    final (engine, connectivity, service) =
        await _engine(outbox, executor, maxAttempts: 3);
    addTearDown(connectivity.dispose);
    addTearDown(service.close);

    await engine.sync(); // attempt 1
    await engine.sync(); // attempt 2
    expect(await outbox.pendingCount(), 1);
    await engine.sync(); // attempt 3 -> terminal
    expect(await outbox.pendingCount(), 0);
    expect(await outbox.failedCount(), 1);
  });

  test('a committed op is never re-executed on a later sync', () async {
    final outbox = InMemoryOutboxStore();
    await outbox.enqueue(_op('a'));
    final executor = _Executor((_) async {});
    final (engine, connectivity, service) = await _engine(outbox, executor);
    addTearDown(connectivity.dispose);
    addTearDown(service.close);

    await engine.sync();
    await engine.sync();
    await engine.sync();

    expect(executor.succeeded, <String>['a']); // exactly once
  });

  test('coming back online triggers a sync', () async {
    final outbox = InMemoryOutboxStore();
    await outbox.enqueue(_op('a'));
    final executor = _Executor((_) async {});
    final (engine, connectivity, service) =
        await _engine(outbox, executor, status: NetworkStatus.offline);
    addTearDown(connectivity.dispose);
    addTearDown(service.close);

    engine.start(); // subscribes; initial sync is a no-op while offline
    await Future<void>.delayed(Duration.zero);
    expect(await outbox.pendingCount(), 1);

    service.emit(NetworkStatus.online);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(executor.succeeded, <String>['a']);
  });
}
