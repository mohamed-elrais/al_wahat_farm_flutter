import 'package:al_wahat_farm_flutter/features/inventory/domain/inventory_models.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('draft validation enforces recurrence and product rules', () {
    OperationPlanDraft draft({
      PlanScheduleType schedule = PlanScheduleType.daily,
      List<int>? days,
      String? item,
      double? rate,
      RateBasis? basis,
      InventoryUnit? unit,
      OperationPlanType type = OperationPlanType.fertilization,
    }) =>
        OperationPlanDraft(
          farmId: 'farm-id',
          type: type,
          title: 'Plan',
          scheduleType: schedule,
          startsOn: DateTime(2026, 8, 1),
          daysOfWeek: days,
          inventoryItemId: item,
          applicationRate: rate,
          rateBasis: basis,
          rateUnit: unit,
        );

    expect(draft().validate(), isNull);
    expect(
      draft(schedule: PlanScheduleType.weekly).validate(),
      contains('weekday'),
    );
    expect(
      draft(schedule: PlanScheduleType.weekly, days: const <int>[5]).validate(),
      isNull,
    );
    expect(
      draft(item: 'item-1', rate: 0).validate(),
      contains('positive'),
    );
    expect(
      draft(item: 'item-1', rate: 100).validate(),
      contains('basis'),
    );
    expect(
      draft(
        item: 'item-1',
        rate: 100,
        basis: RateBasis.perFeddan,
        unit: InventoryUnit.gram,
      ).validate(),
      isNull,
    );
    expect(
      draft(type: OperationPlanType.irrigation, item: 'item-1').validate(),
      contains('Irrigation'),
    );
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
  });
}
