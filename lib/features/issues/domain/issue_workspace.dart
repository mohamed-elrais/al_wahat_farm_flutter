import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';

enum TreeIssueEventType {
  detected,
  confirmed,
  notObserved,
  severityChanged,
  resolutionSubmitted,
  resolved,
  unableToFix,
  dismissed,
  reviewReturned;

  String get wireValue => switch (this) {
        notObserved => 'not_observed',
        severityChanged => 'severity_changed',
        resolutionSubmitted => 'resolution_submitted',
        unableToFix => 'unable_to_fix',
        reviewReturned => 'review_returned',
        _ => name,
      };

  factory TreeIssueEventType.fromWire(String value) => switch (value) {
        'detected' => detected,
        'confirmed' => confirmed,
        'not_observed' => notObserved,
        'severity_changed' => severityChanged,
        'resolution_submitted' => resolutionSubmitted,
        'resolved' => resolved,
        'unable_to_fix' => unableToFix,
        'dismissed' => dismissed,
        'review_returned' => reviewReturned,
        _ => throw FormatException('Unknown tree issue event type: $value'),
      };
}

class TreeIssueEvent {
  const TreeIssueEvent({
    required this.id,
    required this.issueId,
    required this.treeId,
    required this.actorProfileId,
    required this.type,
    required this.createdAt,
    this.previousStatus,
    this.newStatus,
    this.observedSeverity,
    this.newSeverity,
    this.taskId,
    this.inspectionSessionId,
    this.unableReason,
    this.notes,
    this.clientObservedAt,
  });

  final String id;
  final String issueId;
  final String treeId;
  final String actorProfileId;
  final TreeIssueEventType type;
  final TreeIssueStatus? previousStatus;
  final TreeIssueStatus? newStatus;
  final IssueSeverity? observedSeverity;
  final IssueSeverity? newSeverity;
  final String? taskId;
  final String? inspectionSessionId;
  final TreeIssueUnableReason? unableReason;
  final String? notes;
  final DateTime? clientObservedAt;
  final DateTime createdAt;

  factory TreeIssueEvent.fromJson(Map<String, Object?> json) => TreeIssueEvent(
        id: json['id']! as String,
        issueId: json['tree_issue_id']! as String,
        treeId: json['tree_id']! as String,
        actorProfileId: json['actor_profile_id']! as String,
        type: TreeIssueEventType.fromWire(json['event_type']! as String),
        previousStatus: _status(json['previous_status']),
        newStatus: _status(json['new_status']),
        observedSeverity: _severity(json['observed_severity']),
        newSeverity: _severity(json['new_severity']),
        taskId: json['task_id'] as String?,
        inspectionSessionId: json['inspection_session_id'] as String?,
        unableReason: json['unable_reason'] == null
            ? null
            : TreeIssueUnableReason.fromWire(json['unable_reason']! as String),
        notes: json['notes'] as String?,
        clientObservedAt: _date(json['client_observed_at']),
        createdAt: DateTime.parse(json['created_at']! as String),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'tree_issue_id': issueId,
        'tree_id': treeId,
        'actor_profile_id': actorProfileId,
        'event_type': type.wireValue,
        'previous_status': _statusWire(previousStatus),
        'new_status': _statusWire(newStatus),
        'observed_severity': observedSeverity?.name,
        'new_severity': newSeverity?.name,
        'task_id': taskId,
        'inspection_session_id': inspectionSessionId,
        'unable_reason': unableReason?.wireValue,
        'notes': notes,
        'client_observed_at': clientObservedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

class TreeIssueDetails {
  TreeIssueDetails({
    required this.issue,
    required List<TreeIssueEvent> events,
    List<InspectionIssueObservation> observations =
        const <InspectionIssueObservation>[],
    List<IssueLinkedTask> linkedTasks = const <IssueLinkedTask>[],
    List<TaskPhoto> evidence = const <TaskPhoto>[],
  })  : events = List<TreeIssueEvent>.unmodifiable(events),
        observations =
            List<InspectionIssueObservation>.unmodifiable(observations),
        linkedTasks = List<IssueLinkedTask>.unmodifiable(linkedTasks),
        evidence = List<TaskPhoto>.unmodifiable(evidence);

  final TreeIssue issue;
  final List<TreeIssueEvent> events;
  final List<InspectionIssueObservation> observations;
  final List<IssueLinkedTask> linkedTasks;
  final List<TaskPhoto> evidence;

  factory TreeIssueDetails.fromJson(Map<String, Object?> json) =>
      TreeIssueDetails(
        issue: TreeIssue.fromJson(
          Map<String, Object?>.from(json['issue']! as Map),
        ),
        events: (json['events']! as List<Object?>)
            .map((event) => TreeIssueEvent.fromJson(
                  Map<String, Object?>.from(event! as Map),
                ))
            .toList(growable: false),
        observations:
            (json['observations'] as List<Object?>? ?? const <Object?>[])
                .map((observation) => InspectionIssueObservation.fromJson(
                      Map<String, Object?>.from(observation! as Map),
                    ))
                .toList(growable: false),
        linkedTasks:
            (json['linked_tasks'] as List<Object?>? ?? const <Object?>[])
                .map((task) => IssueLinkedTask.fromJson(
                      Map<String, Object?>.from(task! as Map),
                    ))
                .toList(growable: false),
        evidence: (json['evidence'] as List<Object?>? ?? const <Object?>[])
            .map((photo) => TaskPhoto.fromJson(
                  Map<String, Object?>.from(photo! as Map),
                ))
            .toList(growable: false),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'issue': issue.toJson(),
        'events': events.map((event) => event.toJson()).toList(growable: false),
        'observations': observations
            .map((observation) => observation.toJson())
            .toList(growable: false),
        'linked_tasks':
            linkedTasks.map((task) => task.toJson()).toList(growable: false),
        'evidence':
            evidence.map((photo) => photo.toJson()).toList(growable: false),
      };
}

enum InspectionObservationOutcome {
  detected,
  confirmed,
  notObserved;

  String get wireValue => this == notObserved ? 'not_observed' : name;

  factory InspectionObservationOutcome.fromWire(String value) =>
      switch (value) {
        'detected' => detected,
        'confirmed' => confirmed,
        'not_observed' => notObserved,
        _ => throw FormatException('Unknown inspection outcome: $value'),
      };
}

class InspectionIssueObservation {
  const InspectionIssueObservation({
    required this.id,
    required this.sessionId,
    required this.itemId,
    required this.issueId,
    required this.type,
    required this.outcome,
    required this.severityChanged,
    required this.observedByProfileId,
    required this.observedAt,
    required this.createdAt,
    this.observedSeverity,
    this.notes,
    this.photoStoragePath,
  });

  final String id;
  final String sessionId;
  final String itemId;
  final String issueId;
  final TreeIssueType type;
  final InspectionObservationOutcome outcome;
  final IssueSeverity? observedSeverity;
  final bool severityChanged;
  final String? notes;
  final String? photoStoragePath;
  final String observedByProfileId;
  final DateTime observedAt;
  final DateTime createdAt;

  factory InspectionIssueObservation.fromJson(Map<String, Object?> json) =>
      InspectionIssueObservation(
        id: json['id']! as String,
        sessionId: json['session_id']! as String,
        itemId: json['item_id']! as String,
        issueId: json['tree_issue_id']! as String,
        type: TreeIssueType.fromJson(json['issue_type']! as String),
        outcome: InspectionObservationOutcome.fromWire(
          json['outcome']! as String,
        ),
        observedSeverity: _severity(json['observed_severity']),
        severityChanged: json['severity_changed']! as bool,
        notes: json['notes'] as String?,
        photoStoragePath: json['photo_storage_path'] as String?,
        observedByProfileId: json['observed_by_profile_id']! as String,
        observedAt: DateTime.parse(json['observed_at']! as String),
        createdAt: DateTime.parse(json['created_at']! as String),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'session_id': sessionId,
        'item_id': itemId,
        'tree_issue_id': issueId,
        'issue_type': type.wireValue,
        'outcome': outcome.wireValue,
        'observed_severity': observedSeverity?.name,
        'severity_changed': severityChanged,
        'notes': notes,
        'photo_storage_path': photoStoragePath,
        'observed_by_profile_id': observedByProfileId,
        'observed_at': observedAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

class IssueLinkedTask {
  const IssueLinkedTask({
    required this.taskId,
    required this.title,
    required this.status,
    required this.taskType,
    required this.canOpen,
  });

  final String taskId;
  final String title;
  final TaskStatus status;
  final String taskType;
  final bool canOpen;

  factory IssueLinkedTask.fromJson(Map<String, Object?> json) =>
      IssueLinkedTask(
        taskId: json['task_id']! as String,
        title: json['title']! as String,
        status: TaskStatus.fromJson(json['status']! as String),
        taskType: json['task_type']! as String,
        canOpen: json['can_open']! as bool,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'task_id': taskId,
        'title': title,
        'status': status.wireValue,
        'task_type': taskType,
        'can_open': canOpen,
      };
}

class TreeIssueSummary {
  const TreeIssueSummary({
    required this.id,
    required this.farmId,
    required this.treeId,
    required this.treeCode,
    required this.sectionId,
    required this.sectionCode,
    required this.type,
    required this.severity,
    required this.status,
    required this.reportedAt,
    required this.activeIssueCount,
    required this.isClaimed,
    required this.claimedByCurrentUser,
    required this.canViewDetails,
    this.closedAt,
    this.assignedProfileId,
    this.assignedName,
    this.source,
  });

  final String id;
  final String farmId;
  final String treeId;
  final String treeCode;
  final String sectionId;
  final String sectionCode;
  final TreeIssueType type;
  final IssueSeverity severity;
  final TreeIssueStatus status;
  final DateTime reportedAt;
  final int activeIssueCount;
  final bool isClaimed;
  final bool claimedByCurrentUser;
  final bool canViewDetails;
  final DateTime? closedAt;
  final String? assignedProfileId;
  final String? assignedName;
  final IssueSource? source;

  bool get isActive =>
      status == TreeIssueStatus.open || status == TreeIssueStatus.inReview;

  bool get hasAssignment => assignedProfileId != null || isClaimed;

  factory TreeIssueSummary.fromJson(Map<String, Object?> json) =>
      TreeIssueSummary(
        id: (json['tree_issue_id'] ?? json['id'])! as String,
        farmId: json['farm_id']! as String,
        treeId: json['tree_id']! as String,
        treeCode: json['tree_code']! as String,
        sectionId: json['section_id']! as String,
        sectionCode: json['section_code']! as String,
        type: TreeIssueType.fromJson(json['issue_type']! as String),
        severity: IssueSeverity.fromJson(json['severity']! as String),
        status: TreeIssueStatus.fromJson(json['status']! as String),
        reportedAt: DateTime.parse(json['reported_at']! as String),
        activeIssueCount: (json['active_issue_count'] as num? ?? 0).toInt(),
        isClaimed: json['is_claimed']! as bool,
        claimedByCurrentUser: json['claimed_by_current_user'] as bool? ?? false,
        canViewDetails: json['can_view_details'] as bool? ?? true,
        closedAt: _date(json['resolved_at']),
        assignedProfileId: json['assigned_profile_id'] as String?,
        assignedName: json['assigned_name'] as String?,
        source: json['issue_source'] == null
            ? null
            : IssueSource.fromWire(json['issue_source']! as String),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'tree_issue_id': id,
        'farm_id': farmId,
        'tree_id': treeId,
        'tree_code': treeCode,
        'section_id': sectionId,
        'section_code': sectionCode,
        'issue_type': type.wireValue,
        'severity': severity.name,
        'status':
            status == TreeIssueStatus.inReview ? 'in_review' : status.name,
        'reported_at': reportedAt.toIso8601String(),
        'active_issue_count': activeIssueCount,
        'is_claimed': isClaimed,
        'claimed_by_current_user': claimedByCurrentUser,
        'can_view_details': canViewDetails,
        'resolved_at': closedAt?.toIso8601String(),
        'assigned_profile_id': assignedProfileId,
        'assigned_name': assignedName,
        'issue_source': source?.wireValue,
      };
}

/// RLS-authorized, non-sensitive metadata for one past or active occurrence on
/// a tree. Descriptions, actor ids, notes, task links, and evidence deliberately
/// remain in [TreeIssueDetails] and are never copied into the tree-history list
/// cache.
class TreeIssueOccurrence {
  const TreeIssueOccurrence({
    required this.id,
    required this.type,
    required this.severity,
    required this.status,
    required this.reportedAt,
    this.closedAt,
  });

  final String id;
  final TreeIssueType type;
  final IssueSeverity severity;
  final TreeIssueStatus status;
  final DateTime reportedAt;
  final DateTime? closedAt;

  factory TreeIssueOccurrence.fromJson(Map<String, Object?> json) =>
      TreeIssueOccurrence(
        id: json['id']! as String,
        type: TreeIssueType.fromJson(json['issue_type']! as String),
        severity: IssueSeverity.fromJson(json['severity']! as String),
        status: TreeIssueStatus.fromJson(json['status']! as String),
        reportedAt: DateTime.parse(json['reported_at']! as String),
        closedAt: _date(json['resolved_at']),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'issue_type': type.wireValue,
        'severity': severity.name,
        'status':
            status == TreeIssueStatus.inReview ? 'in_review' : status.name,
        'reported_at': reportedAt.toIso8601String(),
        'resolved_at': closedAt?.toIso8601String(),
      };
}

enum TreeIssueUnableReason {
  replacementPartRequired,
  specialistRequired,
  additionalWorkerRequired,
  equipmentUnavailable,
  treeInaccessible,
  suspectedIncorrectIssue,
  other;

  String get wireValue => switch (this) {
        replacementPartRequired => 'replacement_part_required',
        specialistRequired => 'specialist_required',
        additionalWorkerRequired => 'additional_worker_required',
        equipmentUnavailable => 'equipment_unavailable',
        treeInaccessible => 'tree_inaccessible',
        suspectedIncorrectIssue => 'suspected_incorrect_issue',
        other => 'other',
      };

  factory TreeIssueUnableReason.fromWire(String value) => switch (value) {
        'replacement_part_required' => replacementPartRequired,
        'specialist_required' => specialistRequired,
        'additional_worker_required' => additionalWorkerRequired,
        'equipment_unavailable' => equipmentUnavailable,
        'tree_inaccessible' => treeInaccessible,
        'suspected_incorrect_issue' => suspectedIncorrectIssue,
        'other' => other,
        _ => throw FormatException('Unknown unable reason: $value'),
      };
}

class IssueSummaryFilter {
  const IssueSummaryFilter({
    this.type,
    this.severity,
    this.onlyUnclaimed = false,
  });

  final TreeIssueType? type;
  final IssueSeverity? severity;
  final bool onlyUnclaimed;
}

enum IssueWorkspaceView { active, history }

enum IssueAssignmentFilter { all, assigned, unassigned }

enum IssueSource {
  quickReport,
  inspection;

  String get wireValue => switch (this) {
        quickReport => 'quick_report',
        inspection => 'inspection',
      };

  factory IssueSource.fromWire(String value) => switch (value) {
        'quick_report' => quickReport,
        'inspection' => inspection,
        _ => throw FormatException('Unknown issue source: $value'),
      };
}

enum IssueAgeFilter {
  any,
  sevenDays,
  thirtyDays,
  ninetyDays;

  int? get minimumDays => switch (this) {
        any => null,
        sevenDays => 7,
        thirtyDays => 30,
        ninetyDays => 90,
      };
}

enum TaskTreeIssueWorkState {
  pending,
  resolutionSubmitted,
  resolved,
  unableToFix,
  returned;

  factory TaskTreeIssueWorkState.fromWire(String value) => switch (value) {
        'pending' => pending,
        'resolution_submitted' => resolutionSubmitted,
        'resolved' => resolved,
        'unable_to_fix' => unableToFix,
        'returned' => returned,
        _ => throw FormatException('Unknown issue work state: $value'),
      };
}

class TaskTreeIssueWork {
  const TaskTreeIssueWork({
    required this.taskId,
    required this.issueId,
    required this.treeId,
    required this.type,
    required this.severity,
    required this.issueStatus,
    required this.workState,
    required this.resolutionPhotoRequired,
    this.resolutionNotes,
    this.unableReason,
  });

  final String taskId;
  final String issueId;
  final String treeId;
  final TreeIssueType type;
  final IssueSeverity severity;
  final TreeIssueStatus issueStatus;
  final TaskTreeIssueWorkState workState;
  final bool resolutionPhotoRequired;
  final String? resolutionNotes;
  final TreeIssueUnableReason? unableReason;

  factory TaskTreeIssueWork.fromJson(Map<String, Object?> json) {
    final issue = Map<String, Object?>.from(json['tree_issues']! as Map);
    return TaskTreeIssueWork(
      taskId: json['task_id']! as String,
      issueId: json['tree_issue_id']! as String,
      treeId: issue['tree_id']! as String,
      type: TreeIssueType.fromJson(issue['issue_type']! as String),
      severity: IssueSeverity.fromJson(issue['severity']! as String),
      issueStatus: TreeIssueStatus.fromJson(issue['status']! as String),
      workState: TaskTreeIssueWorkState.fromWire(json['work_state']! as String),
      resolutionPhotoRequired: json['resolution_photo_required']! as bool,
      resolutionNotes: json['resolution_notes'] as String?,
      unableReason: json['unable_reason'] == null
          ? null
          : TreeIssueUnableReason.fromWire(json['unable_reason']! as String),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'task_id': taskId,
        'tree_issue_id': issueId,
        'work_state': switch (workState) {
          TaskTreeIssueWorkState.resolutionSubmitted => 'resolution_submitted',
          TaskTreeIssueWorkState.unableToFix => 'unable_to_fix',
          _ => workState.name,
        },
        'resolution_photo_required': resolutionPhotoRequired,
        'resolution_notes': resolutionNotes,
        'unable_reason': unableReason?.wireValue,
        'tree_issues': <String, Object?>{
          'tree_id': treeId,
          'issue_type': type.wireValue,
          'severity': severity.name,
          'status': issueStatus == TreeIssueStatus.inReview
              ? 'in_review'
              : issueStatus.name,
        },
      };
}

TreeIssueStatus? _status(Object? value) =>
    value == null ? null : TreeIssueStatus.fromJson(value as String);

IssueSeverity? _severity(Object? value) =>
    value == null ? null : IssueSeverity.fromJson(value as String);

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

String? _statusWire(TreeIssueStatus? value) => switch (value) {
      TreeIssueStatus.inReview => 'in_review',
      null => null,
      _ => value.name,
    };
