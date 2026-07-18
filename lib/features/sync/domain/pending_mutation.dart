/// The kinds of mutation the offline outbox can queue. O1 covers the
/// naturally-idempotent task transitions (safe to replay without backend op-id
/// dedup); later phases add creates/reviews/photos.
enum PendingMutationKind {
  startTask,
  completeTask,
  setAssignments,
  addTaskPhoto,
  createTask,
  reportIssue;

  factory PendingMutationKind.fromWire(String value) => switch (value) {
        'start_task' => startTask,
        'complete_task' => completeTask,
        'set_assignments' => setAssignments,
        'add_task_photo' => addTaskPhoto,
        'create_task' => createTask,
        'report_tree_issue' => reportIssue,
        _ => throw FormatException('Unknown mutation kind: $value'),
      };

  String get wireValue => switch (this) {
        startTask => 'start_task',
        completeTask => 'complete_task',
        setAssignments => 'set_assignments',
        addTaskPhoto => 'add_task_photo',
        createTask => 'create_task',
        reportIssue => 'report_tree_issue',
      };
}

enum PendingMutationStatus {
  pending,
  failed;

  factory PendingMutationStatus.fromWire(String value) => switch (value) {
        'pending' => pending,
        'failed' => failed,
        _ => throw FormatException('Unknown mutation status: $value'),
      };

  String get wireValue => name;
}

/// One queued write. [opId] is a client-generated UUID that will (from O2) be
/// sent to the backend for duplicate-safe replay; in O1 it is the local dedup
/// key and outbox identity.
class PendingMutation {
  const PendingMutation({
    required this.opId,
    required this.kind,
    required this.payload,
    required this.createdAt,
    this.status = PendingMutationStatus.pending,
    this.attempts = 0,
    this.lastError,
  });

  final String opId;
  final PendingMutationKind kind;
  final Map<String, Object?> payload;
  final PendingMutationStatus status;
  final int attempts;
  final String? lastError;
  final int createdAt;
}
