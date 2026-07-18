import 'package:al_wahat_farm_flutter/features/sync/domain/mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';

/// Replays queued task transitions against the backend. Given the caching task
/// repository, a successful replay also refreshes the cached detail so the UI
/// converges to server truth after sync.
class TaskMutationExecutor implements MutationExecutor {
  const TaskMutationExecutor(this._repository);

  final TaskRepository _repository;

  @override
  Future<void> execute(PendingMutation mutation) async {
    final taskId = mutation.payload['taskId']! as String;
    switch (mutation.kind) {
      case PendingMutationKind.startTask:
        await _repository.start(
          taskId,
          note: mutation.payload['note'] as String?,
        );
      case PendingMutationKind.completeTask:
        await _repository.complete(
          taskId,
          note: mutation.payload['note'] as String?,
          requiresEngineerReview:
              (mutation.payload['requiresEngineerReview'] as bool?) ?? false,
        );
      case PendingMutationKind.setAssignments:
        await _repository.setAssignments(
          taskId,
          (mutation.payload['profileIds']! as List<Object?>).cast<String>(),
        );
    }
    // Refresh the cached detail so a synced task reflects authoritative state.
    try {
      await _repository.loadDetails(taskId);
    } catch (_) {
      // A refresh failure is non-transactional; the mutation already committed.
    }
  }
}
