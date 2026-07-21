import 'package:al_wahat_farm_flutter/features/inventory/domain/inventory_models.dart';

/// Mirrors `public.operation_plan_type`.
enum OperationPlanType {
  irrigation,
  fertilization,
  harmfulWeedControl,
  pestControl,
  diseaseControl;

  String get wireValue => switch (this) {
        irrigation => 'irrigation',
        fertilization => 'fertilization',
        harmfulWeedControl => 'harmful_weed_control',
        pestControl => 'pest_control',
        diseaseControl => 'disease_control',
      };

  factory OperationPlanType.fromJson(String value) => switch (value) {
        'irrigation' => irrigation,
        'fertilization' => fertilization,
        'harmful_weed_control' => harmfulWeedControl,
        'pest_control' => pestControl,
        'disease_control' => diseaseControl,
        _ => throw FormatException('Unknown plan type: $value'),
      };

  bool get carriesProduct => this != irrigation;
}

/// Mirrors `public.operation_plan_status`.
enum OperationPlanStatus {
  draft,
  active,
  paused,
  completed,
  archived;

  String get wireValue => name;

  factory OperationPlanStatus.fromJson(String value) => switch (value) {
        'draft' => draft,
        'active' => active,
        'paused' => paused,
        'completed' => completed,
        'archived' => archived,
        _ => throw FormatException('Unknown plan status: $value'),
      };
}

/// Mirrors `public.operation_schedule_type`.
enum PlanScheduleType {
  once,
  daily,
  weekly;

  String get wireValue => name;

  factory PlanScheduleType.fromJson(String value) => switch (value) {
        'once' => once,
        'daily' => daily,
        'weekly' => weekly,
        _ => throw FormatException('Unknown schedule type: $value'),
      };
}

/// Mirrors `operation_plans.task_grouping`: whether the generator creates
/// one task per target and date (default) or one combined multi-target
/// task per date.
enum TaskGrouping {
  perTarget,
  combined;

  String get wireValue => switch (this) {
        perTarget => 'per_target',
        combined => 'combined',
      };

  factory TaskGrouping.fromJson(String value) => switch (value) {
        'per_target' => perTarget,
        'combined' => combined,
        _ => throw FormatException('Unknown task grouping: $value'),
      };
}

/// The single source of truth for schedule occurrence dates, shared by the
/// form preview, the review section, and [OperationPlan.nextOccurrences].
///
/// Both [startsOn] and [endsOn] are INCLUSIVE: a one-day schedule
/// (startsOn == endsOn) has exactly one occurrence when its recurrence
/// matches that day. `once` schedules occur only on [startsOn].
List<DateTime> planOccurrences({
  required PlanScheduleType scheduleType,
  required DateTime startsOn,
  DateTime? endsOn,
  List<int>? daysOfWeek,
  DateTime? from,
  int? limit,
}) {
  final start = DateTime(startsOn.year, startsOn.month, startsOn.day);
  var day = from == null ? start : DateTime(from.year, from.month, from.day);
  if (day.isBefore(start)) day = start;
  final end = endsOn == null
      ? day.add(const Duration(days: 366))
      : DateTime(endsOn.year, endsOn.month, endsOn.day);
  final result = <DateTime>[];
  while (!day.isAfter(end) && (limit == null || result.length < limit)) {
    final matches = switch (scheduleType) {
      PlanScheduleType.once => day == start,
      PlanScheduleType.daily => true,
      PlanScheduleType.weekly =>
        (daysOfWeek ?? const <int>[]).contains(day.weekday),
    };
    if (matches) result.add(day);
    if (scheduleType == PlanScheduleType.once) break;
    day = day.add(const Duration(days: 1));
  }
  return result;
}

/// Mirrors `public.application_rate_basis` (feddan is the farm's dosing
/// unit; 60 trees = 1 feddan by default).
enum RateBasis {
  perFeddan,
  perTree,
  absolute;

  String get wireValue => switch (this) {
        perFeddan => 'per_feddan',
        perTree => 'per_tree',
        absolute => 'absolute',
      };

  factory RateBasis.fromJson(String value) => switch (value) {
        'per_feddan' => perFeddan,
        'per_tree' => perTree,
        'absolute' => absolute,
        _ => throw FormatException('Unknown rate basis: $value'),
      };
}

/// Mirrors `public.fertilizer_application_method`.
enum ApplicationMethod {
  fertigation,
  soilApplication,
  foliarSpray,
  manualApplication;

  String get wireValue => switch (this) {
        fertigation => 'fertigation',
        soilApplication => 'soil_application',
        foliarSpray => 'foliar_spray',
        manualApplication => 'manual_application',
      };

  factory ApplicationMethod.fromJson(String value) => switch (value) {
        'fertigation' => fertigation,
        'soil_application' => soilApplication,
        'foliar_spray' => foliarSpray,
        'manual_application' => manualApplication,
        _ => throw FormatException('Unknown application method: $value'),
      };
}

/// One target row of a plan; at most one scope id is set (all-null =
/// whole farm), mirroring `operation_plan_targets`.
class PlanTarget {
  const PlanTarget({
    this.id,
    this.sectionId,
    this.irrigationZoneId,
    this.treeId,
  });

  final String? id;
  final String? sectionId;
  final String? irrigationZoneId;
  final String? treeId;

  bool get isFarmWide =>
      sectionId == null && irrigationZoneId == null && treeId == null;

  factory PlanTarget.fromJson(Map<String, Object?> json) => PlanTarget(
        id: json['id'] as String?,
        sectionId: json['section_id'] as String?,
        irrigationZoneId: json['irrigation_zone_id'] as String?,
        treeId: json['tree_id'] as String?,
      );

  Map<String, Object?> toRpcJson() => <String, Object?>{
        if (sectionId != null) 'section_id': sectionId,
        if (irrigationZoneId != null) 'irrigation_zone_id': irrigationZoneId,
        if (treeId != null) 'tree_id': treeId,
      };
}

class OperationPlan {
  const OperationPlan({
    required this.id,
    required this.farmId,
    required this.type,
    required this.title,
    required this.status,
    required this.scheduleType,
    required this.startsOn,
    required this.targets,
    required this.defaultAssigneeProfileIds,
    this.description,
    this.endsOn,
    this.scheduledStartTime,
    this.plannedDurationMinutes,
    this.daysOfWeek,
    this.inventoryItemId,
    this.applicationMethod,
    this.applicationRate,
    this.rateBasis,
    this.rateUnit,
    this.taskGrouping = TaskGrouping.perTarget,
  });

  final String id;
  final String farmId;
  final OperationPlanType type;
  final String title;
  final String? description;
  final OperationPlanStatus status;
  final PlanScheduleType scheduleType;
  final DateTime startsOn;
  final DateTime? endsOn;
  final String? scheduledStartTime;
  final int? plannedDurationMinutes;
  final List<int>? daysOfWeek;
  final List<PlanTarget> targets;
  final List<String> defaultAssigneeProfileIds;
  final String? inventoryItemId;
  final ApplicationMethod? applicationMethod;
  final double? applicationRate;
  final RateBasis? rateBasis;
  final InventoryUnit? rateUnit;
  final TaskGrouping taskGrouping;

  factory OperationPlan.fromJson(
    Map<String, Object?> json, {
    List<PlanTarget> targets = const <PlanTarget>[],
  }) =>
      OperationPlan(
        id: json['id']! as String,
        farmId: json['farm_id']! as String,
        type: OperationPlanType.fromJson(json['operation_type']! as String),
        title: json['title']! as String,
        description: json['description'] as String?,
        status: OperationPlanStatus.fromJson(json['status']! as String),
        scheduleType:
            PlanScheduleType.fromJson(json['schedule_type']! as String),
        startsOn: DateTime.parse(json['starts_on']! as String),
        endsOn: json['ends_on'] == null
            ? null
            : DateTime.parse(json['ends_on']! as String),
        scheduledStartTime: json['scheduled_start_time'] as String?,
        plannedDurationMinutes:
            (json['planned_duration_minutes'] as num?)?.toInt(),
        daysOfWeek: (json['days_of_week'] as List<Object?>?)
            ?.map((day) => (day! as num).toInt())
            .toList(growable: false),
        targets: targets,
        defaultAssigneeProfileIds:
            ((json['default_assignee_profile_ids'] as List<Object?>?) ??
                    const <Object?>[])
                .cast<String>(),
        inventoryItemId: json['inventory_item_id'] as String?,
        applicationMethod: json['application_method'] == null
            ? null
            : ApplicationMethod.fromJson(json['application_method']! as String),
        applicationRate: (json['application_rate'] as num?)?.toDouble(),
        rateBasis: json['rate_basis'] == null
            ? null
            : RateBasis.fromJson(json['rate_basis']! as String),
        rateUnit: json['rate_unit'] == null
            ? null
            : InventoryUnit.fromJson(json['rate_unit']! as String),
        // Absent in rows/caches from before combined-task support.
        taskGrouping: json['task_grouping'] == null
            ? TaskGrouping.perTarget
            : TaskGrouping.fromJson(json['task_grouping']! as String),
      );

  /// The next [count] occurrence dates on/after [from], per the recurrence.
  List<DateTime> nextOccurrences(DateTime from, {int count = 5}) =>
      planOccurrences(
        scheduleType: scheduleType,
        startsOn: startsOn,
        endsOn: endsOn,
        daysOfWeek: daysOfWeek,
        from: from,
        limit: count,
      );
}

class OperationPlanDraft {
  const OperationPlanDraft({
    required this.farmId,
    required this.type,
    required this.title,
    required this.scheduleType,
    required this.startsOn,
    this.description,
    this.status = OperationPlanStatus.active,
    this.endsOn,
    this.scheduledStartTime,
    this.plannedDurationMinutes,
    this.daysOfWeek,
    this.targets = const <PlanTarget>[PlanTarget()],
    this.assigneeProfileIds = const <String>[],
    this.inventoryItemId,
    this.applicationMethod,
    this.applicationRate,
    this.rateBasis,
    this.rateUnit,
    this.taskGrouping = TaskGrouping.perTarget,
  });

  final String farmId;
  final OperationPlanType type;
  final String title;
  final String? description;
  final OperationPlanStatus status;
  final PlanScheduleType scheduleType;
  final DateTime startsOn;
  final DateTime? endsOn;
  final String? scheduledStartTime;
  final int? plannedDurationMinutes;
  final List<int>? daysOfWeek;
  final List<PlanTarget> targets;
  final List<String> assigneeProfileIds;
  final String? inventoryItemId;
  final ApplicationMethod? applicationMethod;
  final double? applicationRate;
  final RateBasis? rateBasis;
  final InventoryUnit? rateUnit;
  final TaskGrouping taskGrouping;

  /// Every date this schedule will run (start and end inclusive).
  List<DateTime> occurrences() => planOccurrences(
        scheduleType: scheduleType,
        startsOn: startsOn,
        endsOn: endsOn,
        daysOfWeek: daysOfWeek,
      );

  /// How many times the schedule runs; drives the total-quantity math.
  int get repetitionCount => occurrences().length;

  /// Tasks the schedule will create over its whole life: one per date for
  /// a combined plan, one per target and date otherwise.
  int get generatedTaskCount =>
      repetitionCount *
      (taskGrouping == TaskGrouping.combined ? 1 : targets.length);

  String? validate({DateTime? today}) {
    final now = today ?? DateTime.now();
    final floorToday = DateTime(now.year, now.month, now.day);
    if (title.trim().isEmpty) return 'Schedule title is required';
    if (scheduleType == PlanScheduleType.weekly &&
        (daysOfWeek == null || daysOfWeek!.isEmpty)) {
      return 'Weekly schedules need at least one weekday';
    }
    if (endsOn == null) return 'Schedules need an end date';
    if (startsOn.isBefore(floorToday)) {
      return 'The start date cannot be in the past';
    }
    if (endsOn!.isBefore(startsOn)) {
      return 'End date must be on or after the start date';
    }
    final monthCap = DateTime(startsOn.year, startsOn.month + 1, startsOn.day);
    if (endsOn!.isAfter(monthCap)) {
      return 'The end date cannot be more than one month after the start date';
    }
    if (type.carriesProduct && inventoryItemId != null) {
      if (applicationRate == null || applicationRate! <= 0) {
        return 'Application rate must be positive';
      }
      if (rateBasis == null || rateUnit == null) {
        return 'Rate basis and unit are required with a product';
      }
    }
    if (!type.carriesProduct && inventoryItemId != null) {
      return 'Irrigation schedules cannot carry a product';
    }
    if (targets.isEmpty) return 'Choose at least one target';
    if (taskGrouping == TaskGrouping.combined) {
      if (targets.any((target) => target.isFarmWide)) {
        return 'A combined task needs specific targets';
      }
      final kinds = targets
          .map((target) => target.sectionId != null
              ? 'section'
              : target.irrigationZoneId != null
                  ? 'zone'
                  : 'tree')
          .toSet();
      if (kinds.length > 1) {
        return 'A combined task can only group targets of the same kind';
      }
    }
    return null;
  }

  Map<String, Object?> toRpcParameters() => <String, Object?>{
        'p_farm_id': farmId,
        'p_operation_type': type.wireValue,
        'p_title': title.trim(),
        'p_schedule_type': scheduleType.wireValue,
        'p_starts_on': _date(startsOn),
        'p_description': description,
        'p_status': status.wireValue,
        'p_ends_on': endsOn == null ? null : _date(endsOn!),
        'p_scheduled_start_time': scheduledStartTime,
        'p_planned_duration_minutes': plannedDurationMinutes,
        'p_days_of_week': daysOfWeek,
        'p_targets':
            targets.map((target) => target.toRpcJson()).toList(growable: false),
        'p_inventory_item_id': inventoryItemId,
        'p_application_method': applicationMethod?.wireValue,
        'p_application_rate': applicationRate,
        'p_rate_basis': rateBasis?.wireValue,
        'p_rate_unit': rateUnit?.wireValue,
        'p_default_assignee_profile_ids': assigneeProfileIds,
        'p_task_grouping': taskGrouping.wireValue,
      };
}

/// One row of `check_operation_plan_inventory`.
class PlanInventoryCheck {
  const PlanInventoryCheck({
    required this.operationDate,
    required this.requiredTotal,
    required this.available,
    required this.sufficient,
    this.applicationsCovered,
  });

  final DateTime operationDate;
  final double requiredTotal;
  final double available;
  final bool sufficient;
  final int? applicationsCovered;

  factory PlanInventoryCheck.fromJson(Map<String, Object?> json) =>
      PlanInventoryCheck(
        operationDate: DateTime.parse(json['operation_date']! as String),
        requiredTotal: (json['required_total']! as num).toDouble(),
        available: (json['available']! as num).toDouble(),
        sufficient: json['sufficient']! as bool,
        applicationsCovered: (json['applications_covered'] as num?)?.toInt(),
      );
}

String _date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
