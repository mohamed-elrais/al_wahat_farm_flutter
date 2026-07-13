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
