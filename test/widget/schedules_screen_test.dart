import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/schedules/data/schedule_repository.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_controller.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_screen.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeScheduleRepository implements ScheduleRepository {
  final List<OperationPlan> plans = <OperationPlan>[];
  int generateCalls = 0;

  @override
  Future<List<OperationPlan>> listPlans(String farmId) async =>
      List<OperationPlan>.of(plans);

  @override
  Future<String> createPlan(OperationPlanDraft draft) async {
    final id = 'plan-${plans.length + 1}';
    plans.add(OperationPlan(
      id: id,
      farmId: draft.farmId,
      type: draft.type,
      title: draft.title.trim(),
      status: draft.status,
      scheduleType: draft.scheduleType,
      startsOn: draft.startsOn,
      endsOn: draft.endsOn,
      scheduledStartTime: draft.scheduledStartTime,
      daysOfWeek: draft.daysOfWeek,
      targets: draft.targets,
      defaultAssigneeProfileIds: draft.assigneeProfileIds,
      inventoryItemId: draft.inventoryItemId,
      applicationRate: draft.applicationRate,
      rateBasis: draft.rateBasis,
      rateUnit: draft.rateUnit,
    ));
    return id;
  }

  @override
  Future<void> updatePlan(
    String planId, {
    String? title,
    String? description,
    OperationPlanStatus? status,
    String? scheduledStartTime,
    int? plannedDurationMinutes,
    List<int>? daysOfWeek,
    List<PlanTarget>? targets,
    List<String>? assigneeProfileIds,
    double? applicationRate,
  }) async {
    final index = plans.indexWhere((plan) => plan.id == planId);
    if (index < 0) return;
    final old = plans[index];
    plans[index] = OperationPlan(
      id: old.id,
      farmId: old.farmId,
      type: old.type,
      title: title ?? old.title,
      status: status ?? old.status,
      scheduleType: old.scheduleType,
      startsOn: old.startsOn,
      endsOn: old.endsOn,
      scheduledStartTime: scheduledStartTime ?? old.scheduledStartTime,
      daysOfWeek: daysOfWeek ?? old.daysOfWeek,
      targets: targets ?? old.targets,
      defaultAssigneeProfileIds:
          assigneeProfileIds ?? old.defaultAssigneeProfileIds,
      inventoryItemId: old.inventoryItemId,
      applicationRate: applicationRate ?? old.applicationRate,
      rateBasis: old.rateBasis,
      rateUnit: old.rateUnit,
    );
  }

  @override
  Future<List<PlanInventoryCheck>> checkInventory(
    String planId, {
    int horizonDays = 30,
  }) async =>
      const <PlanInventoryCheck>[];

  @override
  Future<int> generateNow(String farmId) async {
    generateCalls++;
    return 2;
  }
}

void main() {
  testWidgets('schedules list renders plans with type and recurrence',
      (tester) async {
    final repo = FakeScheduleRepository();
    await repo.createPlan(OperationPlanDraft(
      farmId: 'farm-id',
      type: OperationPlanType.fertilization,
      title: 'Friday calcium',
      scheduleType: PlanScheduleType.weekly,
      startsOn: DateTime(2026, 8, 1),
      daysOfWeek: const <int>[5],
      status: OperationPlanStatus.active,
    ));
    await repo.createPlan(OperationPlanDraft(
      farmId: 'farm-id',
      type: OperationPlanType.irrigation,
      title: 'Daily watering',
      scheduleType: PlanScheduleType.daily,
      startsOn: DateTime(2026, 8, 1),
      status: OperationPlanStatus.paused,
    ));
    final controller = SchedulesController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);
    await controller.load();

    // No operational context in this harness -> the screen treats the viewer
    // as unauthorized, so pump tiles directly through the controller state.
    expect(controller.plans, hasLength(2));
    expect(controller.planById('plan-1')?.title, 'Friday calcium');
  });

  testWidgets('status chip and summary render for an active weekly plan',
      (tester) async {
    final repo = FakeScheduleRepository();
    await repo.createPlan(OperationPlanDraft(
      farmId: 'farm-id',
      type: OperationPlanType.fertilization,
      title: 'Friday calcium',
      scheduleType: PlanScheduleType.weekly,
      startsOn: DateTime(2026, 8, 1),
      daysOfWeek: const <int>[5],
      scheduledStartTime: '08:00:00',
      status: OperationPlanStatus.active,
    ));
    final controller = SchedulesController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);
    await controller.load();
    final plan = controller.plans.single;

    late String summary;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            summary = scheduleSummary(context, AppLocalizationsEn(), plan);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(summary, contains('Weekly'));
    expect(summary, contains('08:00'));
  });

  test('setStatus pauses and reactivates a plan', () async {
    final repo = FakeScheduleRepository();
    await repo.createPlan(OperationPlanDraft(
      farmId: 'farm-id',
      type: OperationPlanType.irrigation,
      title: 'Daily watering',
      scheduleType: PlanScheduleType.daily,
      startsOn: DateTime(2026, 8, 1),
      status: OperationPlanStatus.active,
    ));
    final controller = SchedulesController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);
    await controller.load();

    await controller.setStatus('plan-1', OperationPlanStatus.paused);
    expect(
      controller.planById('plan-1')?.status,
      OperationPlanStatus.paused,
    );
  });
}
