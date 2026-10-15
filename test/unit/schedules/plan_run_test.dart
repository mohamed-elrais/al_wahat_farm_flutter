import 'package:al_wahat_farm_flutter/features/schedules/domain/plan_run.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runs group by date, newest first, with each task once', () {
    final days = PlanRunDay.fromRows(
      <Map<String, Object?>>[
        // A combined task: two targets, one task.
        {
          'operation_date': '2026-10-21',
          'generated_task_id': 'task-1',
          'blocked_reason': null,
        },
        {
          'operation_date': '2026-10-21',
          'generated_task_id': 'task-1',
          'blocked_reason': null,
        },
        // Blocked for stock: no task yet.
        {
          'operation_date': '2026-11-04',
          'generated_task_id': null,
          'blocked_reason': 'insufficient_stock',
        },
      ],
      <String, TaskStatus>{'task-1': TaskStatus.completed},
    );

    expect(days.map((day) => day.date), <DateTime>[
      DateTime(2026, 11, 4),
      DateTime(2026, 10, 21),
    ]);
    expect(days.first.blockedForStock, isTrue);
    expect(days.first.tasks, isEmpty);
    expect(days.last.tasks.single.status, TaskStatus.completed);
    expect(days.last.blockedForStock, isFalse);
  });

  test('a task the manager cannot see any more is left out', () {
    final days = PlanRunDay.fromRows(
      <Map<String, Object?>>[
        {
          'operation_date': '2026-10-21',
          'generated_task_id': 'deleted',
          'blocked_reason': null,
        },
      ],
      const <String, TaskStatus>{},
    );
    expect(days.single.tasks, isEmpty);
    expect(days.single.blockedForStock, isFalse);
  });
}
