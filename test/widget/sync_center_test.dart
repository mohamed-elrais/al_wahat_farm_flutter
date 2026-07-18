import 'dart:async';

import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:al_wahat_farm_flutter/features/sync/presentation/sync_scope.dart';
import 'package:al_wahat_farm_flutter/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService(this._status);
  final NetworkStatus _status;
  final StreamController<NetworkStatus> _controller =
      StreamController<NetworkStatus>.broadcast();
  @override
  Future<NetworkStatus> current() async => _status;
  @override
  Stream<NetworkStatus> get changes => _controller.stream;
  Future<void> close() => _controller.close();
}

class _NoopExecutor implements MutationExecutor {
  @override
  Future<void> execute(PendingMutation mutation) async {}
}

PendingMutation _op(String id) => PendingMutation(
      opId: id,
      kind: PendingMutationKind.startTask,
      payload: const <String, Object?>{'taskId': 't'},
      createdAt: 0,
    );

Future<SyncEngine> _engineWith(List<PendingMutation> ops,
    {List<PendingMutation> failed = const <PendingMutation>[]}) async {
  final outbox = InMemoryOutboxStore();
  for (final o in ops) {
    await outbox.enqueue(o);
  }
  for (final o in failed) {
    await outbox.enqueue(o);
    await outbox.markFailed(o.opId, error: 'x');
  }
  final engine = SyncEngine(
    outbox: outbox,
    executor: _NoopExecutor(),
    connectivity: ConnectivityController(_FakeConnectivityService(
      NetworkStatus.offline,
    )),
  );
  await engine.refresh();
  return engine;
}

Widget _host(SyncEngine engine) => MaterialApp(
      theme: AppTheme.light,
      home: SyncScope(engine: engine, child: const ProfileScreen()),
    );

void main() {
  testWidgets('shows all-synced with no queued changes', (tester) async {
    final engine = await _engineWith(const <PendingMutation>[]);
    addTearDown(engine.dispose);
    await tester.pumpWidget(_host(engine));
    await tester.pumpAndSettle();

    expect(find.text('All changes are synced'), findsOneWidget);
    expect(find.byKey(const Key('sync-now-button')), findsNothing);
  });

  testWidgets('shows pending count and a Sync now action', (tester) async {
    final engine = await _engineWith(<PendingMutation>[_op('a'), _op('b')]);
    addTearDown(engine.dispose);
    await tester.pumpWidget(_host(engine));
    await tester.pumpAndSettle();

    expect(find.text('2 changes waiting to sync'), findsOneWidget);
    expect(find.byKey(const Key('sync-now-button')), findsOneWidget);
    expect(find.byKey(const Key('sync-retry-failed-button')), findsNothing);
  });

  testWidgets('shows failed count with a retry action', (tester) async {
    final engine = await _engineWith(
      const <PendingMutation>[],
      failed: <PendingMutation>[_op('a')],
    );
    addTearDown(engine.dispose);
    await tester.pumpWidget(_host(engine));
    await tester.pumpAndSettle();

    expect(find.text('1 change failed to sync'), findsOneWidget);
    expect(find.byKey(const Key('sync-retry-failed-button')), findsOneWidget);
  });
}
