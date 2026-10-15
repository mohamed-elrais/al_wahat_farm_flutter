import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';

/// What happened on one run date of a schedule, for its history: the task
/// it created (one per target, or one combined task), or why none exists.
class PlanRunDay {
  const PlanRunDay({
    required this.date,
    required this.tasks,
    required this.blockedForStock,
  });

  final DateTime date;

  /// The tasks created for this date and their current status.
  final List<PlanRunTask> tasks;

  /// No task yet because the product's stock was too low.
  final bool blockedForStock;

  /// Builds one entry per date from `operation_plan_runs` rows and the
  /// statuses of their generated tasks.
  static List<PlanRunDay> fromRows(
    List<Map<String, Object?>> runs,
    Map<String, TaskStatus> taskStatuses,
  ) {
    final byDate = <DateTime, List<Map<String, Object?>>>{};
    for (final run in runs) {
      final date = DateTime.parse(run['operation_date']! as String);
      (byDate[date] ??= <Map<String, Object?>>[]).add(run);
    }
    final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
    return <PlanRunDay>[
      for (final date in dates)
        PlanRunDay(
          date: date,
          tasks: <PlanRunTask>[
            for (final taskId in byDate[date]!
                .map((run) => run['generated_task_id'] as String?)
                .whereType<String>()
                .toSet())
              if (taskStatuses[taskId] != null)
                PlanRunTask(taskId: taskId, status: taskStatuses[taskId]!),
          ],
          blockedForStock: byDate[date]!.any(
            (run) =>
                run['generated_task_id'] == null &&
                run['blocked_reason'] == 'insufficient_stock',
          ),
        ),
    ];
  }
}

class PlanRunTask {
  const PlanRunTask({required this.taskId, required this.status});

  final String taskId;
  final TaskStatus status;
}
