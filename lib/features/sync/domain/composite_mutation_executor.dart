import 'package:al_wahat_farm_flutter/features/sync/domain/mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';

/// Routes each queued mutation to the executor registered for its kind, so the
/// single [SyncEngine] can drain a mixed outbox (task transitions/creates/photos
/// and tree-issue reports) while each domain keeps its own executor.
class CompositeMutationExecutor implements MutationExecutor {
  const CompositeMutationExecutor(this._byKind);

  final Map<PendingMutationKind, MutationExecutor> _byKind;

  @override
  Future<void> execute(PendingMutation mutation) {
    final executor = _byKind[mutation.kind];
    if (executor == null) {
      throw StateError(
        'No executor registered for ${mutation.kind.wireValue}',
      );
    }
    return executor.execute(mutation);
  }
}
