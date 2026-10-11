import 'dart:convert';

import 'package:al_wahat_farm_flutter/core/database/app_database.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:sqflite/sqflite.dart';

/// Durable queue of pending mutations. Ordering is FIFO by insertion.
abstract interface class OutboxStore {
  Future<void> enqueue(PendingMutation mutation);
  Future<List<PendingMutation>> pending();
  Future<List<PendingMutation>> failed();
  Future<int> pendingCount();
  Future<int> failedCount();
  Future<void> markDone(String opId);
  Future<void> recordAttempt(String opId,
      {required int attempts, String? error});
  Future<void> markFailed(String opId, {String? error});

  /// Requeues all failed operations for another sync attempt.
  Future<void> retryFailed();

  /// Requeues a single operation (by op id) for another sync attempt.
  Future<void> retryOne(String opId);

  /// Permanently removes a single operation (by op id) from the queue —
  /// discarding a change the user has chosen not to keep.
  Future<void> discard(String opId);

  /// Removes every queued operation (used on logout).
  Future<void> clear();
}

class SqfliteOutboxStore implements OutboxStore {
  const SqfliteOutboxStore(this._database);

  final AppDatabase _database;

  Database get _db => _database.db;

  @override
  Future<void> enqueue(PendingMutation mutation) =>
      enqueueWithExecutor(_db, mutation);

  static Future<void> enqueueWithExecutor(
    DatabaseExecutor executor,
    PendingMutation mutation,
  ) async {
    await executor.insert(
      AppDatabase.outboxTable,
      <String, Object?>{
        'op_id': mutation.opId,
        'kind': mutation.kind.wireValue,
        'payload': jsonEncode(mutation.payload),
        'status': mutation.status.wireValue,
        'attempts': mutation.attempts,
        'last_error': mutation.lastError,
        'created_at': mutation.createdAt,
      },
      // A repeated op_id (double tap) must not create a duplicate queue entry.
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<PendingMutation>> _byStatus(PendingMutationStatus status) async {
    final rows = await _db.query(
      AppDatabase.outboxTable,
      where: 'status = ?',
      whereArgs: <Object?>[status.wireValue],
      orderBy: 'seq ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<List<PendingMutation>> pending() =>
      _byStatus(PendingMutationStatus.pending);

  @override
  Future<List<PendingMutation>> failed() =>
      _byStatus(PendingMutationStatus.failed);

  Future<int> _count(PendingMutationStatus status) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${AppDatabase.outboxTable} WHERE status = ?',
      <Object?>[status.wireValue],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<int> pendingCount() => _count(PendingMutationStatus.pending);

  @override
  Future<int> failedCount() => _count(PendingMutationStatus.failed);

  @override
  Future<void> markDone(String opId) async {
    await _db.delete(
      AppDatabase.outboxTable,
      where: 'op_id = ?',
      whereArgs: <Object?>[opId],
    );
  }

  @override
  Future<void> recordAttempt(
    String opId, {
    required int attempts,
    String? error,
  }) async {
    await _db.update(
      AppDatabase.outboxTable,
      <String, Object?>{'attempts': attempts, 'last_error': error},
      where: 'op_id = ?',
      whereArgs: <Object?>[opId],
    );
  }

  @override
  Future<void> markFailed(String opId, {String? error}) async {
    await _db.update(
      AppDatabase.outboxTable,
      <String, Object?>{
        'status': PendingMutationStatus.failed.wireValue,
        'last_error': error,
      },
      where: 'op_id = ?',
      whereArgs: <Object?>[opId],
    );
  }

  @override
  Future<void> retryFailed() async {
    await _db.update(
      AppDatabase.outboxTable,
      <String, Object?>{
        'status': PendingMutationStatus.pending.wireValue,
        'attempts': 0,
        'last_error': null,
      },
      where: 'status = ?',
      whereArgs: <Object?>[PendingMutationStatus.failed.wireValue],
    );
  }

  @override
  Future<void> retryOne(String opId) async {
    await _db.update(
      AppDatabase.outboxTable,
      <String, Object?>{
        'status': PendingMutationStatus.pending.wireValue,
        'attempts': 0,
        'last_error': null,
      },
      where: 'op_id = ?',
      whereArgs: <Object?>[opId],
    );
  }

  @override
  Future<void> discard(String opId) async {
    await _db.delete(
      AppDatabase.outboxTable,
      where: 'op_id = ?',
      whereArgs: <Object?>[opId],
    );
  }

  @override
  Future<void> clear() async {
    await _db.delete(AppDatabase.outboxTable);
  }

  PendingMutation _fromRow(Map<String, Object?> row) => PendingMutation(
        opId: row['op_id']! as String,
        kind: PendingMutationKind.fromWire(row['kind']! as String),
        payload: Map<String, Object?>.from(
          jsonDecode(row['payload']! as String) as Map,
        ),
        status: PendingMutationStatus.fromWire(row['status']! as String),
        attempts: (row['attempts']! as num).toInt(),
        lastError: row['last_error'] as String?,
        createdAt: (row['created_at']! as num).toInt(),
      );
}

/// In-memory outbox for tests and for a graceful fallback when the database is
/// unavailable. Preserves insertion order.
class InMemoryOutboxStore implements OutboxStore {
  final List<PendingMutation> _entries = <PendingMutation>[];

  @override
  Future<void> enqueue(PendingMutation mutation) async {
    if (_entries.any((e) => e.opId == mutation.opId)) return;
    _entries.add(mutation);
  }

  List<PendingMutation> _byStatus(PendingMutationStatus status) =>
      _entries.where((e) => e.status == status).toList(growable: false);

  @override
  Future<List<PendingMutation>> pending() async =>
      _byStatus(PendingMutationStatus.pending);

  @override
  Future<List<PendingMutation>> failed() async =>
      _byStatus(PendingMutationStatus.failed);

  @override
  Future<int> pendingCount() async =>
      _byStatus(PendingMutationStatus.pending).length;

  @override
  Future<int> failedCount() async =>
      _byStatus(PendingMutationStatus.failed).length;

  @override
  Future<void> markDone(String opId) async {
    _entries.removeWhere((e) => e.opId == opId);
  }

  int _indexOf(String opId) => _entries.indexWhere((e) => e.opId == opId);

  @override
  Future<void> recordAttempt(
    String opId, {
    required int attempts,
    String? error,
  }) async {
    final i = _indexOf(opId);
    if (i < 0) return;
    _entries[i] = _copy(_entries[i], attempts: attempts, lastError: error);
  }

  @override
  Future<void> markFailed(String opId, {String? error}) async {
    final i = _indexOf(opId);
    if (i < 0) return;
    _entries[i] = _copy(
      _entries[i],
      status: PendingMutationStatus.failed,
      lastError: error,
    );
  }

  @override
  Future<void> retryFailed() async {
    for (var i = 0; i < _entries.length; i++) {
      if (_entries[i].status == PendingMutationStatus.failed) {
        _entries[i] = _copy(
          _entries[i],
          status: PendingMutationStatus.pending,
          attempts: 0,
          lastError: null,
          clearError: true,
        );
      }
    }
  }

  @override
  Future<void> retryOne(String opId) async {
    final i = _indexOf(opId);
    if (i < 0) return;
    _entries[i] = _copy(
      _entries[i],
      status: PendingMutationStatus.pending,
      attempts: 0,
      lastError: null,
      clearError: true,
    );
  }

  @override
  Future<void> discard(String opId) async {
    _entries.removeWhere((e) => e.opId == opId);
  }

  @override
  Future<void> clear() async => _entries.clear();

  PendingMutation _copy(
    PendingMutation m, {
    PendingMutationStatus? status,
    int? attempts,
    String? lastError,
    bool clearError = false,
  }) =>
      PendingMutation(
        opId: m.opId,
        kind: m.kind,
        payload: m.payload,
        createdAt: m.createdAt,
        status: status ?? m.status,
        attempts: attempts ?? m.attempts,
        lastError: clearError ? null : (lastError ?? m.lastError),
      );
}
