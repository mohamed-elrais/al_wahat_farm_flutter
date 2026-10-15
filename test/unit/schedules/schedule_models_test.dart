import 'package:al_wahat_farm_flutter/features/inventory/domain/inventory_models.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 8, 1);

  OperationPlanDraft draft({
    PlanScheduleType schedule = PlanScheduleType.daily,
    List<int>? days,
    String? item,
    double? rate,
    RateBasis? basis,
    InventoryUnit? unit,
    OperationPlanType type = OperationPlanType.fertilization,
    DateTime? startsOn,
    DateTime? endsOn,
    List<PlanTarget> targets = const <PlanTarget>[PlanTarget()],
    TaskGrouping grouping = TaskGrouping.perTarget,
  }) =>
      OperationPlanDraft(
        farmId: 'farm-id',
        type: type,
        title: 'Plan',
        scheduleType: schedule,
        startsOn: startsOn ?? today,
        endsOn: endsOn ?? today.add(const Duration(days: 20)),
        daysOfWeek: days,
        targets: targets,
        inventoryItemId: item,
        applicationRate: rate,
        rateBasis: basis,
        rateUnit: unit,
        taskGrouping: grouping,
      );

  test('draft validation enforces recurrence and product rules', () {
    expect(draft().validate(today: today), isNull);
    expect(
      draft(schedule: PlanScheduleType.weekly).validate(today: today),
      ScheduleDraftError.weekdaysRequired,
    );
    expect(
      draft(schedule: PlanScheduleType.weekly, days: const <int>[5])
          .validate(today: today),
      isNull,
    );
    expect(
      draft(item: 'item-1', rate: 0).validate(today: today),
      ScheduleDraftError.ratePositive,
    );
    expect(
      draft(item: 'item-1', rate: 100).validate(today: today),
      ScheduleDraftError.rateDetailsRequired,
    );
    expect(
      draft(
        item: 'item-1',
        rate: 100,
        basis: RateBasis.perFeddan,
        unit: InventoryUnit.gram,
      ).validate(today: today),
      isNull,
    );
    expect(
      draft(type: OperationPlanType.irrigation, item: 'item-1')
          .validate(today: today),
      ScheduleDraftError.irrigationProduct,
    );
  });

  test('draft validation enforces the date rules', () {
    expect(
      OperationPlanDraft(
        farmId: 'farm-id',
        type: OperationPlanType.irrigation,
        title: 'No end',
        scheduleType: PlanScheduleType.daily,
        startsOn: today,
      ).validate(today: today),
      ScheduleDraftError.endRequired,
    );
    expect(
      draft(startsOn: today.subtract(const Duration(days: 1)))
          .validate(today: today),
      ScheduleDraftError.startInPast,
    );
    expect(
      draft(
        startsOn: today.add(const Duration(days: 5)),
        endsOn: today.add(const Duration(days: 2)),
      ).validate(today: today),
      ScheduleDraftError.endBeforeStart,
    );
    // The one-month cap is gone (owner, 2026-10-15): 45 days is fine, and
    // up to one year is allowed; more is treated as a typo.
    expect(
      draft(endsOn: today.add(const Duration(days: 45))).validate(today: today),
      isNull,
    );
    expect(
      draft(endsOn: DateTime(today.year + 1, today.month, today.day))
          .validate(today: today),
      isNull,
    );
    expect(
      draft(endsOn: DateTime(today.year + 1, today.month, today.day + 1))
          .validate(today: today),
      ScheduleDraftError.endTooLate,
    );
    expect(draft(endsOn: today).validate(today: today), isNull);
  });

  test('combined grouping needs multiple concrete same-kind targets', () {
    expect(
      draft(
        grouping: TaskGrouping.combined,
        targets: const <PlanTarget>[
          PlanTarget(irrigationZoneId: 'z1'),
          PlanTarget(irrigationZoneId: 'z2'),
        ],
      ).validate(today: today),
      isNull,
    );
    expect(
      draft(
        grouping: TaskGrouping.combined,
        targets: const <PlanTarget>[
          PlanTarget(sectionId: 's1'),
          PlanTarget(irrigationZoneId: 'z1'),
        ],
      ).validate(today: today),
      ScheduleDraftError.combinedSameKind,
    );
    expect(
      draft(grouping: TaskGrouping.combined).validate(today: today),
      ScheduleDraftError.combinedNeedsTargets,
    );
  });

  test('occurrences are inclusive of both boundary dates', () {
    // A one-day daily schedule runs exactly once.
    expect(
      planOccurrences(
        scheduleType: PlanScheduleType.daily,
        startsOn: today,
        endsOn: today,
      ),
      <DateTime>[today],
    );
    // Four inclusive days.
    expect(
      planOccurrences(
        scheduleType: PlanScheduleType.daily,
        startsOn: today,
        endsOn: today.add(const Duration(days: 3)),
      ).length,
      4,
    );
    // Weekly Fridays over a month window: 2026-08-01 is a Saturday, so
    // the Fridays are 7, 14, 21 and 28 August.
    final fridays = planOccurrences(
      scheduleType: PlanScheduleType.weekly,
      startsOn: today,
      endsOn: DateTime(2026, 8, 28),
      daysOfWeek: const <int>[DateTime.friday],
    );
    expect(fridays.length, 4);
    expect(fridays.first, DateTime(2026, 8, 7));
    expect(fridays.last, DateTime(2026, 8, 28));
    // `once` runs on its single start day.
    expect(
      planOccurrences(
        scheduleType: PlanScheduleType.once,
        startsOn: today,
        endsOn: today,
      ),
      <DateTime>[today],
    );
  });

  test('repetition and task counts drive the totals', () {
    final weekly = draft(
      schedule: PlanScheduleType.weekly,
      days: const <int>[DateTime.friday],
      endsOn: DateTime(2026, 8, 28),
      targets: const <PlanTarget>[
        PlanTarget(irrigationZoneId: 'z1'),
        PlanTarget(irrigationZoneId: 'z2'),
        PlanTarget(irrigationZoneId: 'z3'),
      ],
    );
    expect(weekly.repetitionCount, 4);
    expect(weekly.generatedTaskCount, 12); // per target: 4 dates x 3 targets
    final combined = draft(
      schedule: PlanScheduleType.weekly,
      days: const <int>[DateTime.friday],
      endsOn: DateTime(2026, 8, 28),
      grouping: TaskGrouping.combined,
      targets: const <PlanTarget>[
        PlanTarget(irrigationZoneId: 'z1'),
        PlanTarget(irrigationZoneId: 'z2'),
        PlanTarget(irrigationZoneId: 'z3'),
      ],
    );
    expect(combined.generatedTaskCount, 4); // one combined task per date
  });

  test('weekly plans compute the next occurrence dates', () {
    final plan = OperationPlan(
      id: 'p',
      farmId: 'f',
      type: OperationPlanType.fertilization,
      title: 'Fridays',
      status: OperationPlanStatus.active,
      scheduleType: PlanScheduleType.weekly,
      startsOn: DateTime(2026, 8, 1),
      endsOn: DateTime(2026, 10, 31),
      daysOfWeek: const <int>[5], // Friday
      targets: const <PlanTarget>[PlanTarget()],
      defaultAssigneeProfileIds: const <String>[],
    );

    final dates = plan.nextOccurrences(DateTime(2026, 8, 1), count: 3);
    expect(dates, <DateTime>[
      DateTime(2026, 8, 7),
      DateTime(2026, 8, 14),
      DateTime(2026, 8, 21),
    ]);
    for (final date in dates) {
      expect(date.weekday, DateTime.friday);
    }
  });

  test('once plans stop after their single date and respect ends_on', () {
    final once = OperationPlan(
      id: 'p',
      farmId: 'f',
      type: OperationPlanType.irrigation,
      title: 'Once',
      status: OperationPlanStatus.active,
      scheduleType: PlanScheduleType.once,
      startsOn: DateTime(2026, 8, 10),
      targets: const <PlanTarget>[PlanTarget()],
      defaultAssigneeProfileIds: const <String>[],
    );
    expect(once.nextOccurrences(DateTime(2026, 8, 1)), <DateTime>[
      DateTime(2026, 8, 10),
    ]);
    expect(once.nextOccurrences(DateTime(2026, 8, 11)), isEmpty);
  });

  test('draft serializes the documented RPC parameter shape', () {
    final params = OperationPlanDraft(
      farmId: 'farm-id',
      type: OperationPlanType.fertilization,
      title: ' Friday calcium ',
      scheduleType: PlanScheduleType.weekly,
      startsOn: DateTime(2026, 8, 1),
      endsOn: DateTime(2026, 10, 31),
      scheduledStartTime: '08:00:00',
      daysOfWeek: const <int>[5],
      targets: const <PlanTarget>[PlanTarget(irrigationZoneId: 'zone-1')],
      assigneeProfileIds: const <String>['worker-1'],
      inventoryItemId: 'item-1',
      applicationMethod: ApplicationMethod.fertigation,
      applicationRate: 100,
      rateBasis: RateBasis.perFeddan,
      rateUnit: InventoryUnit.gram,
    ).toRpcParameters();

    expect(params['p_title'], 'Friday calcium');
    expect(params['p_schedule_type'], 'weekly');
    expect(params['p_starts_on'], '2026-08-01');
    expect(params['p_ends_on'], '2026-10-31');
    expect(params['p_days_of_week'], const <int>[5]);
    expect(params['p_targets'], const [
      {'irrigation_zone_id': 'zone-1'},
    ]);
    expect(params['p_inventory_item_id'], 'item-1');
    expect(params['p_application_method'], 'fertigation');
    expect(params['p_rate_basis'], 'per_feddan');
    expect(params['p_rate_unit'], 'gram');
    expect(params['p_default_assignee_profile_ids'], const ['worker-1']);
    expect(params['p_task_grouping'], 'per_target');
  });

  test('combined grouping serializes to the RPC parameter', () {
    final params = draft(
      grouping: TaskGrouping.combined,
      targets: const <PlanTarget>[
        PlanTarget(irrigationZoneId: 'z1'),
        PlanTarget(irrigationZoneId: 'z2'),
      ],
    ).toRpcParameters();
    expect(params['p_task_grouping'], 'combined');
  });
}
