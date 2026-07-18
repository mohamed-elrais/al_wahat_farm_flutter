import 'dart:async';

import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/logging/safe_log.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/mutation_executor.dart';
import 'package:flutter/foundation.dart';

enum SyncOutcome { offline, alreadyRunning, drained, hadFailures, deferred }

/// Drains the [OutboxStore] in FIFO order when online. Each op runs through the
/// [MutationExecutor]:
/// - success  → removed from the queue.
/// - transient failure (offline / unexpected) → attempt counted; draining stops
///   so ordering is preserved and it retries on the next trigger. After
///   [maxAttempts] it becomes a terminal failure.
/// - terminal failure (authorization / invalid input / conflict / not found) →
///   marked failed and surfaced; draining continues with the next op.
///
/// A single sync runs at a time. Sync is triggered on connectivity regained,
/// after an enqueue while online, and manually.
class SyncEngine extends ChangeNotifier {
  SyncEngine({
    required OutboxStore outbox,
    required MutationExecutor executor,
    required ConnectivityController connectivity,
    this.maxAttempts = 5,
  })  : _outbox = outbox,
        _executor = executor,
        _connectivity = connectivity;

  final OutboxStore _outbox;
  final MutationExecutor _executor;
  final ConnectivityController _connectivity;
  final int maxAttempts;

  bool _running = false;
  bool _started = false;

  bool get isSyncing => _running;

  /// Begin reacting to connectivity: sync whenever the device comes back online.
  void start() {
    if (_started) return;
    _started = true;
    _connectivity.addListener(_onConnectivityChanged);
    unawaited(sync());
  }

  void _onConnectivityChanged() {
    if (_connectivity.isOnline) unawaited(sync());
  }

  Future<SyncOutcome> sync() async {
    if (_running) return SyncOutcome.alreadyRunning;
    if (_connectivity.isOffline) return SyncOutcome.offline;
    _running = true;
    notifyListeners();
    var hadFailures = false;
    var deferred = false;
    try {
      final pending = await _outbox.pending();
      for (final op in pending) {
        try {
          await _executor.execute(op);
          await _outbox.markDone(op.opId);
        } on OperationFailure catch (error) {
          if (_isTerminal(error.kind)) {
            await _outbox.markFailed(op.opId, error: error.message);
            hadFailures = true;
          } else if (op.attempts + 1 >= maxAttempts) {
            await _outbox.markFailed(op.opId, error: error.message);
            hadFailures = true;
          } else {
            await _outbox.recordAttempt(
              op.opId,
              attempts: op.attempts + 1,
              error: error.message,
            );
            deferred = true;
            break; // preserve order; retry on the next trigger
          }
        } catch (error) {
          // Unknown errors are treated as transient/retryable.
          if (op.attempts + 1 >= maxAttempts) {
            await _outbox.markFailed(op.opId, error: '$error');
            hadFailures = true;
          } else {
            await _outbox.recordAttempt(
              op.opId,
              attempts: op.attempts + 1,
              error: '$error',
            );
            deferred = true;
            break;
          }
        }
      }
    } catch (error) {
      SafeLog.event('sync_drain_error',
          data: <String, Object?>{'error': error.runtimeType});
    } finally {
      _running = false;
      notifyListeners();
    }
    if (deferred) return SyncOutcome.deferred;
    if (hadFailures) return SyncOutcome.hadFailures;
    return SyncOutcome.drained;
  }

  /// Requeue failed operations and try again.
  Future<SyncOutcome> retryFailed() async {
    await _outbox.retryFailed();
    notifyListeners();
    return sync();
  }

  static bool _isTerminal(OperationFailureKind kind) => switch (kind) {
        OperationFailureKind.authorization ||
        OperationFailureKind.invalidInput ||
        OperationFailureKind.conflict ||
        OperationFailureKind.notFound =>
          true,
        OperationFailureKind.offline ||
        OperationFailureKind.unexpected =>
          false,
      };

  @override
  void dispose() {
    if (_started) _connectivity.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
