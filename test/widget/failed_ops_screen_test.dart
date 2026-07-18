import 'dart:async';

import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:al_wahat_farm_flutter/features/sync/presentation/failed_ops_controller.dart';
import 'package:al_wahat_farm_flutter/features/sync/presentation/failed_ops_screen.dart';
import 'package:flutter/material.dart';
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

Future<FailedOpsController> _controllerWith(
    List<PendingMutation> failed) async {
  final outbox = InMemoryOutboxStore();
  for (final op in failed) {
    await outbox.enqueue(op);
    await outbox.markFailed(op.opId, error: 'Farm role not authorized');
  }
  final connectivity = ConnectivityController(_OfflineConnectivity());
  await connectivity.start();
  addTearDown(connectivity.dispose);
  final engine = SyncEngine(
    outbox: outbox,
    executor: _NoopExecutor(),
    connectivity: connectivity,
  );
  return FailedOpsController(
    syncEngine: engine,
    pendingPhotos: InMemoryPendingPhotoStore(),
  );
}

void main() {
  testWidgets('lists a failed op with its label and error', (tester) async {
    final controller = await _controllerWith(const <PendingMutation>[
      PendingMutation(
        opId: 'r1',
        kind: PendingMutationKind.reviewTask,
        payload: <String, Object?>{'draft': <String, Object?>{}},
        createdAt: 0,
      ),
    ]);
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: FailedOpsScreen(controller: controller),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('failed-op-r1')), findsOneWidget);
    expect(find.text('Review decision'), findsOneWidget);
    expect(find.text('Farm role not authorized'), findsOneWidget);
  });

  testWidgets('discarding a failed op removes it after confirmation',
      (tester) async {
    final controller = await _controllerWith(const <PendingMutation>[
      PendingMutation(
        opId: 'r1',
        kind: PendingMutationKind.startTask,
        payload: <String, Object?>{'taskId': 't'},
        createdAt: 0,
      ),
    ]);
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: FailedOpsScreen(controller: controller),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('failed-op-discard-r1')));
    await tester.pumpAndSettle();
    // Confirm in the dialog.
    await tester.tap(find.text('Discard').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('failed-op-r1')), findsNothing);
    expect(find.text('No failed changes'), findsOneWidget);
  });
}
