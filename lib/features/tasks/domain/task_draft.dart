enum TaskType {
  irrigation,
  fertilization,
  harmfulWeedControl,
  dripperMaintenance,
  treeInspection,
  engineerReview,
  general;

  String get wireValue => switch (this) {
        harmfulWeedControl => 'harmful_weed_control',
        dripperMaintenance => 'dripper_maintenance',
        treeInspection => 'tree_inspection',
        engineerReview => 'engineer_review',
        _ => name,
      };

  factory TaskType.fromJson(String value) => switch (value) {
        'irrigation' => irrigation,
        'fertilization' => fertilization,
        'harmful_weed_control' => harmfulWeedControl,
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

class TaskDraft {
  const TaskDraft({
    required this.farmId,
    required this.type,
    required this.title,
    this.description,
    this.sectionId,
    this.irrigationZoneId,
    this.treeId,
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

  Map<String, Object?> toRpcParameters() => <String, Object?>{
        'p_farm_id': farmId,
        'p_task_type': type.wireValue,
        'p_title': title.trim(),
        'p_description': description,
        'p_section_id': sectionId,
        'p_irrigation_zone_id': irrigationZoneId,
        'p_tree_id': treeId,
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
