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
/// It mirrors the database rule `private.plan_runs_on`.
///
/// Both [startsOn] and [endsOn] are INCLUSIVE: a one-day schedule
/// (startsOn == endsOn) has exactly one occurrence when its recurrence
/// matches that day. `once` schedules occur only on [startsOn].
///
/// [repeatEvery] skips days or weeks: daily every N days counted from the
/// start date; weekly every N weeks counted from the week of the first run
/// (so "every 2 weeks on Wednesday" always starts on the first Wednesday).
List<DateTime> planOccurrences({
  required PlanScheduleType scheduleType,
  required DateTime startsOn,
  DateTime? endsOn,
  List<int>? daysOfWeek,
  int repeatEvery = 1,
  DateTime? from,
  int? limit,
}) {
  final start = DateTime(startsOn.year, startsOn.month, startsOn.day);
  var day = from == null ? start : DateTime(from.year, from.month, from.day);
  if (day.isBefore(start)) day = start;
  final end = endsOn == null
      ? DateTime(day.year, day.month, day.day + 366)
      : DateTime(endsOn.year, endsOn.month, endsOn.day);
  final every = repeatEvery < 1 ? 1 : repeatEvery;
  final days = daysOfWeek ?? const <int>[];
  final anchorWeek = _dayNumber(_firstRunMonday(start, days));
  final result = <DateTime>[];
  while (!day.isAfter(end) && (limit == null || result.length < limit)) {
    final matches = switch (scheduleType) {
      PlanScheduleType.once => day == start,
      PlanScheduleType.daily =>
        (_dayNumber(day) - _dayNumber(start)) % every == 0,
      PlanScheduleType.weekly => days.contains(day.weekday) &&
          ((_dayNumber(_monday(day)) - anchorWeek) ~/ 7) % every == 0,
    };
    if (matches) result.add(day);
    if (scheduleType == PlanScheduleType.once) break;
    // Calendar days, not 24 hours: Egypt's daylight-saving changes would
    // otherwise shift local midnight.
    day = DateTime(day.year, day.month, day.day + 1);
  }
  return result;
}

/// Days since the epoch for a calendar date, independent of daylight saving.
int _dayNumber(DateTime day) =>
    DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

DateTime _monday(DateTime day) =>
    DateTime(day.year, day.month, day.day - (day.weekday - 1));

/// Monday of the week holding the first chosen weekday on/after [start].
DateTime _firstRunMonday(DateTime start, List<int> days) {
  if (days.isEmpty) return _monday(start);
  final offset = days
      .map((day) => (day - start.weekday + 7) % 7)
      .reduce((a, b) => a < b ? a : b);
  return _monday(DateTime(start.year, start.month, start.day + offset));
}

/// The longest a schedule may run (a typo guard; the owner removed the
/// one-month limit on 2026-10-15). Mirrors `assert_plan_schedule_dates`.
DateTime scheduleLatestEnd(DateTime startsOn) =>
    DateTime(startsOn.year + 1, startsOn.month, startsOn.day);

/// Why a schedule draft cannot be saved; the form shows it in the user's
/// language, [message] is the English text for logs and errors.
enum ScheduleDraftError {
  titleRequired('Schedule title is required'),
  weekdaysRequired('Weekly schedules need at least one weekday'),
  repeatOutOfRange('A schedule repeats every 1 to 12 days or weeks'),
  endRequired('Schedules need an end date'),
  startInPast('The start date cannot be in the past'),
  endBeforeStart('End date must be on or after the start date'),
  endTooLate('The end date cannot be more than one year after the start date'),
  ratePositive('Application rate must be positive'),
  rateDetailsRequired('Rate basis and unit are required with a product'),
  irrigationProduct('Irrigation schedules cannot carry a product'),
  targetsRequired('Choose at least one target'),
  combinedNeedsTargets('A combined task needs specific targets'),
  combinedSameKind('A combined task can only group targets of the same kind');

  const ScheduleDraftError(this.message);

  final String message;
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
    this.repeatEvery = 1,
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

  /// Every N days (daily) or weeks (weekly); 1 for every day or week.
  final int repeatEvery;

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
        // Absent in rows/caches from before repeat-every support.
        repeatEvery: (json['repeat_every'] as num?)?.toInt() ?? 1,
      );

  /// The next [count] occurrence dates on/after [from], per the recurrence.
  List<DateTime> nextOccurrences(DateTime from, {int count = 5}) =>
      planOccurrences(
        scheduleType: scheduleType,
        startsOn: startsOn,
        endsOn: endsOn,
        daysOfWeek: daysOfWeek,
        repeatEvery: repeatEvery,
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
    this.repeatEvery = 1,
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
  final int repeatEvery;

  /// Every date this schedule will run (start and end inclusive).
  List<DateTime> occurrences() => planOccurrences(
        scheduleType: scheduleType,
        startsOn: startsOn,
        endsOn: endsOn,
        daysOfWeek: daysOfWeek,
        repeatEvery: repeatEvery,
      );

  /// How many times the schedule runs; drives the total-quantity math.
  int get repetitionCount => occurrences().length;

  /// Tasks the schedule will create over its whole life: one per date for
  /// a combined plan, one per target and date otherwise.
  int get generatedTaskCount =>
      repetitionCount *
      (taskGrouping == TaskGrouping.combined ? 1 : targets.length);

  /// [keepStart] is the saved start date when editing: an unchanged start
  /// date may be in the past (the schedule is already running).
  ScheduleDraftError? validate({DateTime? today, DateTime? keepStart}) {
    final now = today ?? DateTime.now();
    final floorToday = DateTime(now.year, now.month, now.day);
    if (title.trim().isEmpty) return ScheduleDraftError.titleRequired;
    if (scheduleType == PlanScheduleType.weekly &&
        (daysOfWeek == null || daysOfWeek!.isEmpty)) {
      return ScheduleDraftError.weekdaysRequired;
    }
    if (repeatEvery < 1 || repeatEvery > 12) {
      return ScheduleDraftError.repeatOutOfRange;
    }
    if (endsOn == null) return ScheduleDraftError.endRequired;
    if (startsOn.isBefore(floorToday) &&
        !(keepStart != null && _sameDay(startsOn, keepStart))) {
      return ScheduleDraftError.startInPast;
    }
    if (endsOn!.isBefore(startsOn)) return ScheduleDraftError.endBeforeStart;
    if (endsOn!.isAfter(scheduleLatestEnd(startsOn))) {
      return ScheduleDraftError.endTooLate;
    }
    if (type.carriesProduct && inventoryItemId != null) {
      if (applicationRate == null || applicationRate! <= 0) {
        return ScheduleDraftError.ratePositive;
      }
      if (rateBasis == null || rateUnit == null) {
        return ScheduleDraftError.rateDetailsRequired;
      }
    }
    if (!type.carriesProduct && inventoryItemId != null) {
      return ScheduleDraftError.irrigationProduct;
    }
    if (targets.isEmpty) return ScheduleDraftError.targetsRequired;
    if (taskGrouping == TaskGrouping.combined) {
      if (targets.any((target) => target.isFarmWide)) {
        return ScheduleDraftError.combinedNeedsTargets;
      }
      final kinds = targets
          .map((target) => target.sectionId != null
              ? 'section'
              : target.irrigationZoneId != null
                  ? 'zone'
                  : 'tree')
          .toSet();
      if (kinds.length > 1) return ScheduleDraftError.combinedSameKind;
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
        'p_repeat_every':
            scheduleType == PlanScheduleType.once ? 1 : repeatEvery,
      };
}

/// The changes from [before] to [after] as `update_operation_plan`
/// parameters. Dates and targets are sent only when they change: an
/// unchanged past start date must not trip the "not in the past" rule, and
/// unchanged targets keep their rows (and the generated-task history).
Map<String, Object?> planUpdateParameters(
  OperationPlan before,
  OperationPlanDraft after,
) {
  String scope(PlanTarget target) => '${target.sectionId}|'
      '${target.irrigationZoneId}|${target.treeId}';
  final targetsChanged = before.targets.map(scope).toSet().length !=
          after.targets.length ||
      !after.targets.map(scope).toSet().containsAll(before.targets.map(scope));
  final weekly = after.scheduleType == PlanScheduleType.weekly;
  final description = after.description?.trim();
  return <String, Object?>{
    'p_operation_plan_id': before.id,
    'p_title': after.title.trim(),
    'p_description':
        description == null || description.isEmpty ? null : description,
    'p_clear_description': description == null || description.isEmpty,
    'p_schedule_type': after.scheduleType.wireValue,
    'p_starts_on': _sameDay(after.startsOn, before.startsOn)
        ? null
        : _date(after.startsOn),
    'p_ends_on': after.endsOn == null ||
            (before.endsOn != null && _sameDay(after.endsOn!, before.endsOn!))
        ? null
        : _date(after.endsOn!),
    'p_scheduled_start_time': after.scheduledStartTime,
    'p_clear_scheduled_start_time': after.scheduledStartTime == null,
    'p_planned_duration_minutes': after.plannedDurationMinutes,
    'p_clear_planned_duration_minutes': after.plannedDurationMinutes == null,
    'p_days_of_week': weekly ? after.daysOfWeek : null,
    'p_clear_days_of_week': !weekly,
    'p_replace_targets': targetsChanged,
    'p_targets': targetsChanged
        ? after.targets.map((target) => target.toRpcJson()).toList()
        : null,
    'p_inventory_item_id': after.inventoryItemId,
    'p_application_method': after.applicationMethod?.wireValue,
    'p_application_rate': after.applicationRate,
    'p_rate_basis': after.rateBasis?.wireValue,
    'p_rate_unit': after.rateUnit?.wireValue,
    'p_clear_product': after.inventoryItemId == null,
    'p_default_assignee_profile_ids': after.assigneeProfileIds,
    'p_task_grouping': after.taskGrouping.wireValue,
    'p_repeat_every':
        after.scheduleType == PlanScheduleType.once ? 1 : after.repeatEvery,
  };
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

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
