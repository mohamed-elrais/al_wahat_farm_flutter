import 'package:al_wahat_farm_flutter/features/schedules/data/schedule_repository.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/plan_run.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';

class FakeScheduleRepository implements ScheduleRepository {
  final List<OperationPlan> plans = <OperationPlan>[];
  final Map<String, List<PlanRunDay>> runs = <String, List<PlanRunDay>>{};
  final List<Map<String, Object?>> editCalls = <Map<String, Object?>>[];
  int generateCalls = 0;

  final Set<String> skippedForStock = <String>{};

  @override
  Future<List<OperationPlan>> listPlans(
    String farmId, {
    bool includeArchived = false,
  }) async =>
      plans
          .where((plan) =>
              includeArchived || plan.status != OperationPlanStatus.archived)
          .toList();

  @override
  Future<Set<String>> plansSkippedForStock(List<String> planIds) async =>
      skippedForStock.intersection(planIds.toSet());

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
      taskGrouping: draft.taskGrouping,
      repeatEvery: draft.repeatEvery,
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
  Future<void> editPlan(OperationPlan before, OperationPlanDraft after) async {
    editCalls.add(planUpdateParameters(before, after));
    final index = plans.indexWhere((plan) => plan.id == before.id);
    plans[index] = OperationPlan(
      id: before.id,
      farmId: before.farmId,
      type: before.type,
      title: after.title.trim(),
      description: after.description,
      status: before.status,
      scheduleType: after.scheduleType,
      startsOn: after.startsOn,
      endsOn: after.endsOn,
      scheduledStartTime: after.scheduledStartTime,
      plannedDurationMinutes: after.plannedDurationMinutes,
      daysOfWeek: after.daysOfWeek,
      targets: after.targets,
      defaultAssigneeProfileIds: after.assigneeProfileIds,
      inventoryItemId: after.inventoryItemId,
      applicationMethod: after.applicationMethod,
      applicationRate: after.applicationRate,
      rateBasis: after.rateBasis,
      rateUnit: after.rateUnit,
      taskGrouping: after.taskGrouping,
      repeatEvery: after.repeatEvery,
    );
  }

  @override
  Future<List<PlanRunDay>> listRuns(String planId) async =>
      runs[planId] ?? const <PlanRunDay>[];

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
