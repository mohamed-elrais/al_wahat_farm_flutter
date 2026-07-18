import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';

/// Applies a queued [PendingMutation] against the backend. Throws on failure;
/// the [SyncEngine] classifies the thrown error as transient or terminal.
abstract interface class MutationExecutor {
  Future<void> execute(PendingMutation mutation);
}
