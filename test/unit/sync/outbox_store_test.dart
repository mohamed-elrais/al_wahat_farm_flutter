import 'package:al_wahat_farm_flutter/core/database/app_database.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

PendingMutation _op(
  String id,
  PendingMutationKind kind, {
  int createdAt = 0,
  Map<String, Object?> payload = const <String, Object?>{},
}) =>
    PendingMutation(
        opId: id, kind: kind, payload: payload, createdAt: createdAt);

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase database;
  late SqfliteOutboxStore outbox;

  setUp(() async {
    database = await AppDatabase.open(filePath: inMemoryDatabasePath);
    outbox = SqfliteOutboxStore(database);
  });

  tearDown(() async => database.close());

  test('enqueues and returns pending in FIFO order', () async {
    await outbox.enqueue(_op('a', PendingMutationKind.startTask, createdAt: 1));
    await outbox
        .enqueue(_op('b', PendingMutationKind.completeTask, createdAt: 2));
    await outbox
        .enqueue(_op('c', PendingMutationKind.setAssignments, createdAt: 3));

    final pending = await outbox.pending();
    expect(pending.map((e) => e.opId), <String>['a', 'b', 'c']);
    expect(await outbox.pendingCount(), 3);
    expect(
      pending.first.payload,
      isEmpty,
    );
  });

  test('ignores a duplicate op_id (double tap)', () async {
    await outbox.enqueue(_op('a', PendingMutationKind.startTask));
    await outbox.enqueue(_op('a', PendingMutationKind.startTask));
    expect(await outbox.pendingCount(), 1);
  });

  test('preserves payload round-trip', () async {
    await outbox.enqueue(_op(
      'a',
      PendingMutationKind.setAssignments,
      payload: <String, Object?>{
        'taskId': 't1',
        'profileIds': <String>['p1', 'p2'],
      },
    ));
    final op = (await outbox.pending()).single;
    expect(op.kind, PendingMutationKind.setAssignments);
    expect(op.payload['taskId'], 't1');
    expect(op.payload['profileIds'], <String>['p1', 'p2']);
  });

  test('markDone removes the op', () async {
    await outbox.enqueue(_op('a', PendingMutationKind.startTask));
    await outbox.markDone('a');
    expect(await outbox.pendingCount(), 0);
  });

  test('recordAttempt updates count and error but keeps it pending', () async {
    await outbox.enqueue(_op('a', PendingMutationKind.startTask));
    await outbox.recordAttempt('a', attempts: 2, error: 'boom');
    final op = (await outbox.pending()).single;
    expect(op.attempts, 2);
    expect(op.lastError, 'boom');
    expect(op.status, PendingMutationStatus.pending);
  });

  test('markFailed moves it to failed; retryFailed requeues', () async {
    await outbox.enqueue(_op('a', PendingMutationKind.startTask));
    await outbox.markFailed('a', error: 'denied');
    expect(await outbox.pendingCount(), 0);
    expect(await outbox.failedCount(), 1);
    expect((await outbox.failed()).single.lastError, 'denied');

    await outbox.retryFailed();
    expect(await outbox.failedCount(), 0);
    final op = (await outbox.pending()).single;
    expect(op.attempts, 0);
    expect(op.lastError, isNull);
  });

  test('clear empties the outbox', () async {
    await outbox.enqueue(_op('a', PendingMutationKind.startTask));
    await outbox.enqueue(_op('b', PendingMutationKind.completeTask));
    await outbox.clear();
    expect(await outbox.pendingCount(), 0);
  });
}
