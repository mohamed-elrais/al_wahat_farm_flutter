import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';

/// Prefix of the temporary client id given to a task created while offline,
/// before it has synced and received its real server id. The suffix is the
/// outbox op id, so the provisional row and its queued `create_task` mutation
/// share one identity.
const String localTaskIdPrefix = 'local:';

enum TaskStatus {
  draft,
  assigned,
  inProgress,
  completed,
  needsEngineerReview,
  approved,
  returned,
  cancelled;

  factory TaskStatus.fromJson(String value) => switch (value) {
        'draft' => draft,
        'assigned' => assigned,
        'in_progress' => inProgress,
        'completed' => completed,
        'needs_engineer_review' => needsEngineerReview,
        'approved' => approved,
        'returned' => returned,
        'cancelled' => cancelled,
        _ => throw FormatException('Unknown task status: $value'),
      };

  String get label => switch (this) {
        draft => 'Draft',
        assigned => 'Assigned',
        inProgress => 'In progress',
        completed => 'Completed',
        needsEngineerReview => 'Needs review',
        approved => 'Approved',
        returned => 'Returned',
        cancelled => 'Cancelled',
      };

  String get wireValue => switch (this) {
        draft => 'draft',
        assigned => 'assigned',
        inProgress => 'in_progress',
        completed => 'completed',
        needsEngineerReview => 'needs_engineer_review',
        approved => 'approved',
        returned => 'returned',
        cancelled => 'cancelled',
      };

  bool get canStart => this == assigned || this == returned;

  bool get canComplete =>
      this == assigned || this == inProgress || this == returned;

  bool get isClosed =>
      this == completed || this == approved || this == cancelled;
}

enum TaskActivityAction {
  created,
  assigned,
  unassigned,
  started,
  completed,
  flaggedForReview,
  reviewedApproved,
  reviewedReturned,
  commented,
  cancelled,
  photoAdded;

  factory TaskActivityAction.fromJson(String value) => switch (value) {
        'created' => created,
        'assigned' => assigned,
        'unassigned' => unassigned,
        'started' => started,
        'completed' => completed,
        'flagged_for_review' => flaggedForReview,
        'reviewed_approved' => reviewedApproved,
        'reviewed_returned' => reviewedReturned,
        'commented' => commented,
        'cancelled' => cancelled,
        'photo_added' => photoAdded,
        _ => throw FormatException('Unknown task activity action: $value'),
      };

  String get label => switch (this) {
        created => 'Task created',
        assigned => 'Assignments updated',
        unassigned => 'Assignments cleared',
        started => 'Work started',
        completed => 'Work completed',
        flaggedForReview => 'Sent for engineer review',
        reviewedApproved => 'Work approved',
        reviewedReturned => 'Returned for correction',
        commented => 'Comment added',
        cancelled => 'Task cancelled',
        photoAdded => 'Evidence added',
      };

  String get wireValue => switch (this) {
        created => 'created',
        assigned => 'assigned',
        unassigned => 'unassigned',
        started => 'started',
        completed => 'completed',
        flaggedForReview => 'flagged_for_review',
        reviewedApproved => 'reviewed_approved',
        reviewedReturned => 'reviewed_returned',
        commented => 'commented',
        cancelled => 'cancelled',
        photoAdded => 'photo_added',
      };
}

enum TaskPhotoType {
  before,
  after,
  evidence,
  issue,
  review;

  factory TaskPhotoType.fromJson(String value) => switch (value) {
        'before' => before,
        'after' => after,
        'evidence' => evidence,
        'issue' => issue,
        'review' => review,
        _ => throw FormatException('Unknown task photo type: $value'),
      };

  String get wireValue => name;

  String get label => switch (this) {
        before => 'Before work',
        after => 'After work',
        evidence => 'Evidence',
        issue => 'Issue',
        review => 'Review',
      };
}

class TaskAssignee {
  const TaskAssignee({
    required this.profileId,
    required this.fullName,
    required this.role,
  });

  final String profileId;
  final String fullName;
  final String role;

  factory TaskAssignee.fromMembershipJson(Map<String, Object?> json) {
    final profile = Map<String, Object?>.from(json['profiles']! as Map);
    return TaskAssignee(
      profileId: json['profile_id']! as String,
      fullName: profile['full_name']! as String,
      role: json['role']! as String,
    );
  }
}

class FarmTask {
  const FarmTask({
    required this.id,
    required this.farmId,
    required this.type,
    required this.title,
    required this.priority,
    required this.status,
    required this.instructions,
    required this.requiresEngineerReview,
    required this.createdByProfileId,
    required this.createdAt,
    required this.updatedAt,
    this.sectionId,
    this.irrigationZoneId,
    this.treeId,
    this.relatedTreeIssueId,
    this.description,
    this.scheduledFor,
    this.plannedStartTime,
    this.plannedDurationMinutes,
    this.dueAt,
    this.completedByProfileId,
    this.completedAt,
    this.approvedByProfileId,
    this.approvedAt,
    this.cancelledByProfileId,
    this.cancelledAt,
    this.cancellationReason,
  });

  final String id;
  final String farmId;
  final String? sectionId;
  final String? irrigationZoneId;
  final String? treeId;
  final String? relatedTreeIssueId;
  final TaskType type;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? scheduledFor;
  final String? plannedStartTime;
  final int? plannedDurationMinutes;
  final DateTime? dueAt;
  final Map<String, Object?> instructions;
  final bool requiresEngineerReview;
  final String createdByProfileId;
  final String? completedByProfileId;
  final DateTime? completedAt;
  final String? approvedByProfileId;
  final DateTime? approvedAt;
  final String? cancelledByProfileId;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// True while this is a provisional row for a task created offline that has
  /// not yet synced (its [id] is still the local temp id). Such tasks are shown
  /// read-only until the queued creation replays and returns the real id.
  bool get isPendingSync => id.startsWith(localTaskIdPrefix);

  /// Only inspections created by the dedicated inspection workflow carry
  /// immutable route metadata and have a matching inspection session.
  bool get hasInspectionSetup =>
      type == TaskType.treeInspection &&
      sectionId != null &&
      instructions['inspection_route_version'] is num;

  factory FarmTask.fromJson(Map<String, Object?> json) => FarmTask(
        id: json['id']! as String,
        farmId: json['farm_id']! as String,
        sectionId: json['section_id'] as String?,
        irrigationZoneId: json['irrigation_zone_id'] as String?,
        treeId: json['tree_id'] as String?,
        relatedTreeIssueId: json['related_tree_issue_id'] as String?,
        type: TaskType.fromJson(json['task_type']! as String),
        title: json['title']! as String,
        description: json['description'] as String?,
        priority: TaskPriority.fromJson(json['priority']! as String),
        status: TaskStatus.fromJson(json['status']! as String),
        scheduledFor: _optionalDate(json['scheduled_for']),
        plannedStartTime: json['planned_start_time'] as String?,
        plannedDurationMinutes:
            (json['planned_duration_minutes'] as num?)?.toInt(),
        dueAt: _optionalDate(json['due_at']),
        instructions: Map<String, Object?>.unmodifiable(
          Map<String, Object?>.from(json['instructions']! as Map),
        ),
        requiresEngineerReview: json['requires_engineer_review']! as bool,
        createdByProfileId: json['created_by_profile_id']! as String,
        completedByProfileId: json['completed_by_profile_id'] as String?,
        completedAt: _optionalDate(json['completed_at']),
        approvedByProfileId: json['approved_by_profile_id'] as String?,
        approvedAt: _optionalDate(json['approved_at']),
        cancelledByProfileId: json['cancelled_by_profile_id'] as String?,
        cancelledAt: _optionalDate(json['cancelled_at']),
        cancellationReason: json['cancellation_reason'] as String?,
        createdAt: DateTime.parse(json['created_at']! as String),
        updatedAt: DateTime.parse(json['updated_at']! as String),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'farm_id': farmId,
        'section_id': sectionId,
        'irrigation_zone_id': irrigationZoneId,
        'tree_id': treeId,
        'related_tree_issue_id': relatedTreeIssueId,
        'task_type': type.wireValue,
        'title': title,
        'description': description,
        'priority': priority.name,
        'status': status.wireValue,
        'scheduled_for': scheduledFor?.toIso8601String(),
        'planned_start_time': plannedStartTime,
        'planned_duration_minutes': plannedDurationMinutes,
        'due_at': dueAt?.toIso8601String(),
        'instructions': instructions,
        'requires_engineer_review': requiresEngineerReview,
        'created_by_profile_id': createdByProfileId,
        'completed_by_profile_id': completedByProfileId,
        'completed_at': completedAt?.toIso8601String(),
        'approved_by_profile_id': approvedByProfileId,
        'approved_at': approvedAt?.toIso8601String(),
        'cancelled_by_profile_id': cancelledByProfileId,
        'cancelled_at': cancelledAt?.toIso8601String(),
        'cancellation_reason': cancellationReason,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class TaskAssignment {
  const TaskAssignment({
    required this.id,
    required this.taskId,
    required this.assigneeProfileId,
    required this.assignedByProfileId,
    required this.assignedAt,
    required this.isActive,
    required this.createdAt,
    this.unassignedAt,
  });

  final String id;
  final String taskId;
  final String assigneeProfileId;
  final String assignedByProfileId;
  final DateTime assignedAt;
  final bool isActive;
  final DateTime? unassignedAt;
  final DateTime createdAt;

  factory TaskAssignment.fromJson(Map<String, Object?> json) => TaskAssignment(
        id: json['id']! as String,
        taskId: json['task_id']! as String,
        assigneeProfileId: json['assignee_profile_id']! as String,
        assignedByProfileId: json['assigned_by_profile_id']! as String,
        assignedAt: DateTime.parse(json['assigned_at']! as String),
        isActive: json['is_active']! as bool,
        unassignedAt: _optionalDate(json['unassigned_at']),
        createdAt: DateTime.parse(json['created_at']! as String),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'task_id': taskId,
        'assignee_profile_id': assigneeProfileId,
        'assigned_by_profile_id': assignedByProfileId,
        'assigned_at': assignedAt.toIso8601String(),
        'is_active': isActive,
        'unassigned_at': unassignedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

class TaskActivity {
  const TaskActivity({
    required this.id,
    required this.taskId,
    required this.actorProfileId,
    required this.action,
    required this.metadata,
    required this.createdAt,
    this.oldStatus,
    this.newStatus,
    this.note,
  });

  final String id;
  final String taskId;
  final String actorProfileId;
  final TaskActivityAction action;
  final TaskStatus? oldStatus;
  final TaskStatus? newStatus;
  final String? note;
  final Map<String, Object?> metadata;
  final DateTime createdAt;

  factory TaskActivity.fromJson(Map<String, Object?> json) => TaskActivity(
        id: json['id']! as String,
        taskId: json['task_id']! as String,
        actorProfileId: json['actor_profile_id']! as String,
        action: TaskActivityAction.fromJson(json['action']! as String),
        oldStatus: _optionalTaskStatus(json['old_status']),
        newStatus: _optionalTaskStatus(json['new_status']),
        note: json['note'] as String?,
        metadata: Map<String, Object?>.unmodifiable(
          Map<String, Object?>.from(json['metadata']! as Map),
        ),
        createdAt: DateTime.parse(json['created_at']! as String),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'task_id': taskId,
        'actor_profile_id': actorProfileId,
        'action': action.wireValue,
        'old_status': oldStatus?.wireValue,
        'new_status': newStatus?.wireValue,
        'note': note,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
      };
}

class TaskPhoto {
  const TaskPhoto({
    required this.id,
    required this.taskId,
    required this.storageBucketId,
    required this.storagePath,
    required this.photoType,
    required this.uploadedByProfileId,
    required this.createdAt,
    this.taskActivityLogId,
    this.engineerReviewId,
    this.caption,
    this.takenAt,
  });

  final String id;
  final String taskId;
  final String? taskActivityLogId;
  final String? engineerReviewId;
  final String storageBucketId;
  final String storagePath;
  final TaskPhotoType photoType;
  final String? caption;
  final String uploadedByProfileId;
  final DateTime? takenAt;
  final DateTime createdAt;

  factory TaskPhoto.fromJson(Map<String, Object?> json) => TaskPhoto(
        id: json['id']! as String,
        taskId: json['task_id']! as String,
        taskActivityLogId: json['task_activity_log_id'] as String?,
        engineerReviewId: json['engineer_review_id'] as String?,
        storageBucketId: json['storage_bucket_id']! as String,
        storagePath: json['storage_path']! as String,
        photoType: TaskPhotoType.fromJson(json['photo_type']! as String),
        caption: json['caption'] as String?,
        uploadedByProfileId: json['uploaded_by_profile_id']! as String,
        takenAt: _optionalDate(json['taken_at']),
        createdAt: DateTime.parse(json['created_at']! as String),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'task_id': taskId,
        'task_activity_log_id': taskActivityLogId,
        'engineer_review_id': engineerReviewId,
        'storage_bucket_id': storageBucketId,
        'storage_path': storagePath,
        'photo_type': photoType.wireValue,
        'caption': caption,
        'uploaded_by_profile_id': uploadedByProfileId,
        'taken_at': takenAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

TaskStatus? _optionalTaskStatus(Object? value) =>
    value == null ? null : TaskStatus.fromJson(value as String);

DateTime? _optionalDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);
