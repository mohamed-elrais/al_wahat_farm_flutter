enum TaskType {
  irrigation,
  fertilization,
  harmfulWeedControl,
  pestControl,
  diseaseControl,
  dripperMaintenance,
  treeInspection,
  engineerReview,
  general;

  String get wireValue => switch (this) {
        harmfulWeedControl => 'harmful_weed_control',
        pestControl => 'pest_control',
        diseaseControl => 'disease_control',
        dripperMaintenance => 'dripper_maintenance',
        treeInspection => 'tree_inspection',
        engineerReview => 'engineer_review',
        _ => name,
      };

  factory TaskType.fromJson(String value) => switch (value) {
        'irrigation' => irrigation,
        'fertilization' => fertilization,
        'harmful_weed_control' => harmfulWeedControl,
        'pest_control' => pestControl,
        'disease_control' => diseaseControl,
        'dripper_maintenance' => dripperMaintenance,
        'tree_inspection' => treeInspection,
        'engineer_review' => engineerReview,
        'general' => general,
        _ => throw FormatException('Unknown task type: $value'),
      };

  String get label => switch (this) {
        irrigation => 'Irrigation',
        fertilization => 'Fertilization',
        harmfulWeedControl => 'Harmful weed control',
        pestControl => 'Pest control',
        diseaseControl => 'Disease control',
        dripperMaintenance => 'Dripper maintenance',
        treeInspection => 'Tree inspection',
        engineerReview => 'Engineer review',
        general => 'General field work',
      };
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  factory TaskPriority.fromJson(String value) => switch (value) {
        'low' => low,
        'medium' => medium,
        'high' => high,
        'urgent' => urgent,
        _ => throw FormatException('Unknown task priority: $value'),
      };

  String get label => switch (this) {
        low => 'Low',
        medium => 'Medium',
        high => 'High',
        urgent => 'Urgent',
      };
}

/// One concrete target of a task (exactly one scope id set), mirroring a
/// `task_targets` row. All targets of one task must share the same kind —
/// the backend enforces this with a 23514.
class TaskTarget {
  const TaskTarget({this.sectionId, this.irrigationZoneId, this.treeId});

  final String? sectionId;
  final String? irrigationZoneId;
  final String? treeId;

  /// 'section' | 'zone' | 'tree' | null (null = invalid/empty target).
  String? get kind {
    if (sectionId != null) return 'section';
    if (irrigationZoneId != null) return 'zone';
    if (treeId != null) return 'tree';
    return null;
  }

  String? get entityId => sectionId ?? irrigationZoneId ?? treeId;

  bool get isValid =>
      <String?>[sectionId, irrigationZoneId, treeId]
          .where((id) => id != null)
          .length ==
      1;

  factory TaskTarget.fromJson(Map<String, Object?> json) => TaskTarget(
        sectionId: json['section_id'] as String?,
        irrigationZoneId: json['irrigation_zone_id'] as String?,
        treeId: json['tree_id'] as String?,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        if (sectionId != null) 'section_id': sectionId,
        if (irrigationZoneId != null) 'irrigation_zone_id': irrigationZoneId,
        if (treeId != null) 'tree_id': treeId,
      };
}

class TaskDraft {
  const TaskDraft({
    required this.farmId,
    required this.type,
    required this.title,
    this.description,
    this.sectionId,
    this.irrigationZoneId,
    this.treeId,
    this.targets = const <TaskTarget>[],
    this.scheduledFor,
    this.plannedStartTime,
    this.plannedDurationMinutes,
    this.dueAt,
    this.priority = TaskPriority.medium,
    this.instructions = const <String, Object?>{},
    this.requiresEngineerReview = false,
    this.relatedTreeIssueId,
    this.assigneeProfileIds = const <String>[],
  });

  final String farmId;
  final TaskType type;
  final String title;
  final String? description;
  final String? sectionId;
  final String? irrigationZoneId;
  final String? treeId;

  /// Multi-target list. When non-empty it is the task's target set (and the
  /// legacy single-target fields above must stay null); the backend mirrors
  /// the first entry onto the legacy columns.
  final List<TaskTarget> targets;

  final DateTime? scheduledFor;
  final String? plannedStartTime;
  final int? plannedDurationMinutes;
  final DateTime? dueAt;
  final TaskPriority priority;
  final Map<String, Object?> instructions;
  final bool requiresEngineerReview;
  final String? relatedTreeIssueId;
  final List<String> assigneeProfileIds;

  String? validate() {
    if (farmId.trim().isEmpty) return 'Farm identity is required';
    if (title.trim().isEmpty) return 'Task title is required';
    if (<String?>[
          sectionId,
          irrigationZoneId,
          treeId,
        ].where((id) => id != null).length >
        1) {
      return 'Choose only one specific target';
    }
    if (targets.isNotEmpty) {
      if (sectionId != null || irrigationZoneId != null || treeId != null) {
        return 'Use either the single target or the target list, not both';
      }
      if (targets.any((target) => !target.isValid)) {
        return 'Every target needs exactly one scope';
      }
      if (targets.map((target) => target.kind).toSet().length > 1) {
        return 'All targets must be of the same kind';
      }
      if (targets.map((target) => target.entityId).toSet().length !=
          targets.length) {
        return 'Targets must not repeat';
      }
    }
    if (plannedDurationMinutes != null && plannedDurationMinutes! <= 0) {
      return 'Planned duration must be positive';
    }
    if (assigneeProfileIds.any((id) => id.trim().isEmpty)) {
      return 'Every assignee must have a profile identity';
    }
    return null;
  }

  /// Round-trippable serialization used to carry a queued offline creation in
  /// the outbox payload (distinct from [toRpcParameters], which is the backend
  /// wire shape). Kept in sync with [TaskDraft.fromJson].
  Map<String, Object?> toJson() => <String, Object?>{
        'farm_id': farmId,
        'task_type': type.wireValue,
        'title': title,
        'description': description,
        'section_id': sectionId,
        'irrigation_zone_id': irrigationZoneId,
        'tree_id': treeId,
        'targets':
            targets.map((target) => target.toJson()).toList(growable: false),
        'scheduled_for': scheduledFor?.toIso8601String(),
        'planned_start_time': plannedStartTime,
        'planned_duration_minutes': plannedDurationMinutes,
        'due_at': dueAt?.toIso8601String(),
        'priority': priority.name,
        'instructions': instructions,
        'requires_engineer_review': requiresEngineerReview,
        'related_tree_issue_id': relatedTreeIssueId,
        'assignee_profile_ids': assigneeProfileIds,
      };

  factory TaskDraft.fromJson(Map<String, Object?> json) => TaskDraft(
        farmId: json['farm_id']! as String,
        type: TaskType.fromJson(json['task_type']! as String),
        title: json['title']! as String,
        description: json['description'] as String?,
        sectionId: json['section_id'] as String?,
        irrigationZoneId: json['irrigation_zone_id'] as String?,
        treeId: json['tree_id'] as String?,
        targets: ((json['targets'] as List<Object?>?) ?? const <Object?>[])
            .map((row) =>
                TaskTarget.fromJson(Map<String, Object?>.from(row! as Map)))
            .toList(growable: false),
        scheduledFor: json['scheduled_for'] == null
            ? null
            : DateTime.parse(json['scheduled_for']! as String),
        plannedStartTime: json['planned_start_time'] as String?,
        plannedDurationMinutes:
            (json['planned_duration_minutes'] as num?)?.toInt(),
        dueAt: json['due_at'] == null
            ? null
            : DateTime.parse(json['due_at']! as String),
        priority: TaskPriority.fromJson(json['priority']! as String),
        instructions: Map<String, Object?>.from(
          json['instructions'] as Map? ?? const <String, Object?>{},
        ),
        requiresEngineerReview:
            (json['requires_engineer_review'] as bool?) ?? false,
        relatedTreeIssueId: json['related_tree_issue_id'] as String?,
        assigneeProfileIds: ((json['assignee_profile_ids'] as List<Object?>?) ??
                const <Object?>[])
            .cast<String>(),
      );

  /// A single-entry target list collapses to the legacy scalar params (works
  /// against a backend that predates `p_targets`); two or more entries are
  /// sent as `p_targets` and the backend mirrors the first onto the legacy
  /// columns.
  Map<String, Object?> toRpcParameters() => <String, Object?>{
        'p_farm_id': farmId,
        'p_task_type': type.wireValue,
        'p_title': title.trim(),
        'p_description': description,
        'p_section_id':
            targets.length == 1 ? targets.first.sectionId : sectionId,
        'p_irrigation_zone_id': targets.length == 1
            ? targets.first.irrigationZoneId
            : irrigationZoneId,
        'p_tree_id': targets.length == 1 ? targets.first.treeId : treeId,
        if (targets.length > 1)
          'p_targets':
              targets.map((target) => target.toJson()).toList(growable: false),
        'p_scheduled_for': scheduledFor == null ? null : _date(scheduledFor!),
        'p_planned_start_time': plannedStartTime,
        'p_planned_duration_minutes': plannedDurationMinutes,
        'p_due_at': dueAt?.toUtc().toIso8601String(),
        'p_priority': priority.name,
        'p_instructions': instructions,
        'p_requires_engineer_review': requiresEngineerReview,
        'p_related_tree_issue_id': relatedTreeIssueId,
        'p_assignee_profile_ids': assigneeProfileIds,
      };
}

String _date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
