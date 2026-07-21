import 'package:al_wahat_farm_flutter/features/schedules/data/schedule_repository.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';

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
      taskGrouping: draft.taskGrouping,
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
