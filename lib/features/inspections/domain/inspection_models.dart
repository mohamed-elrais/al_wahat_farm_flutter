import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';

enum InspectionSessionStatus {
  notStarted,
  inProgress,
  paused,
  submitted,
  cancelled;

  String get wireValue => switch (this) {
        notStarted => 'not_started',
        inProgress => 'in_progress',
        paused => 'paused',
        submitted => 'submitted',
        cancelled => 'cancelled',
      };

  factory InspectionSessionStatus.fromWire(String value) => switch (value) {
        'not_started' => notStarted,
        'in_progress' => inProgress,
        'paused' => paused,
        'submitted' => submitted,
        'cancelled' => cancelled,
        _ => throw FormatException('Unknown inspection status: $value'),
      };
}

enum InspectionItemStatus {
  pending,
  inspected;

  factory InspectionItemStatus.fromWire(String value) => switch (value) {
        'pending' => pending,
        'inspected' => inspected,
        _ => throw FormatException('Unknown inspection item status: $value'),
      };
}

enum InspectionStationObservationOutcome {
  detected,
  confirmed,
  notObserved;

  String get wireValue => switch (this) {
        detected => 'detected',
        confirmed => 'confirmed',
        notObserved => 'not_observed',
      };

  factory InspectionStationObservationOutcome.fromWire(String value) =>
      switch (value) {
        'detected' => detected,
        'confirmed' => confirmed,
        'not_observed' => notObserved,
        _ => throw FormatException('Unknown inspection outcome: $value'),
      };
}

class InspectionSession {
  const InspectionSession({
    required this.id,
    required this.farmId,
    required this.sectionId,
    required this.taskId,
    required this.inspectorProfileId,
    required this.createdByProfileId,
    required this.startingTreeId,
    required this.status,
    required this.routeVersion,
    required this.totalStations,
    required this.totalTrees,
    required this.inspectedTrees,
    required this.requiresIssuePhoto,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.pausedAt,
    this.submittedAt,
  });

  final String id;
  final String farmId;
  final String sectionId;
  final String taskId;
  final String inspectorProfileId;
  final String createdByProfileId;
  final String startingTreeId;
  final InspectionSessionStatus status;
  final int routeVersion;
  final int totalStations;
  final int totalTrees;
  final int inspectedTrees;
  final bool requiresIssuePhoto;
  final int revision;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final DateTime? submittedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory InspectionSession.fromJson(Map<String, Object?> json) =>
      InspectionSession(
        id: json['id']! as String,
        farmId: json['farm_id']! as String,
        sectionId: json['section_id']! as String,
        taskId: json['task_id']! as String,
        inspectorProfileId: json['inspector_profile_id']! as String,
        createdByProfileId: json['created_by_profile_id']! as String,
        startingTreeId: json['starting_tree_id']! as String,
        status: InspectionSessionStatus.fromWire(json['status']! as String),
        routeVersion: (json['route_version']! as num).toInt(),
        totalStations: (json['total_stations']! as num).toInt(),
        totalTrees: (json['total_trees']! as num).toInt(),
        inspectedTrees: (json['inspected_trees']! as num).toInt(),
        requiresIssuePhoto: json['requires_issue_photo']! as bool,
        revision: (json['revision']! as num).toInt(),
        startedAt: _date(json['started_at']),
        pausedAt: _date(json['paused_at']),
        submittedAt: _date(json['submitted_at']),
        createdAt: DateTime.parse(json['created_at']! as String),
        updatedAt: DateTime.parse(json['updated_at']! as String),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'farm_id': farmId,
        'section_id': sectionId,
        'task_id': taskId,
        'inspector_profile_id': inspectorProfileId,
        'created_by_profile_id': createdByProfileId,
        'starting_tree_id': startingTreeId,
        'status': status.wireValue,
        'route_version': routeVersion,
        'total_stations': totalStations,
        'total_trees': totalTrees,
        'inspected_trees': inspectedTrees,
        'requires_issue_photo': requiresIssuePhoto,
        'revision': revision,
        'started_at': startedAt?.toIso8601String(),
        'paused_at': pausedAt?.toIso8601String(),
        'submitted_at': submittedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class InspectionSessionItem {
  const InspectionSessionItem({
    required this.id,
    required this.sessionId,
    required this.routeItem,
    required this.status,
    required this.noNewIssueFound,
    this.notes,
    this.observedAt,
  });

  final String id;
  final String sessionId;
  final InspectionRouteItem routeItem;
  final InspectionItemStatus status;
  final bool noNewIssueFound;
  final String? notes;
  final DateTime? observedAt;

  factory InspectionSessionItem.fromJson(Map<String, Object?> json) =>
      InspectionSessionItem(
        id: json['id']! as String,
        sessionId: json['session_id']! as String,
        routeItem: InspectionRouteItem.fromJson(json),
        status: InspectionItemStatus.fromWire(json['status']! as String),
        noNewIssueFound: json['no_new_issue_found']! as bool,
        notes: json['notes'] as String?,
        observedAt: _date(json['observed_at']),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'session_id': sessionId,
        ...routeItem.toJson(),
        'status': status.name,
        'no_new_issue_found': noNewIssueFound,
        'notes': notes,
        'observed_at': observedAt?.toIso8601String(),
      };
}

class InspectionDetails {
  InspectionDetails({
    required this.session,
    required List<InspectionSessionItem> items,
    List<InspectionStationObservation> observations =
        const <InspectionStationObservation>[],
  })  : items = List<InspectionSessionItem>.unmodifiable(items),
        observations =
            List<InspectionStationObservation>.unmodifiable(observations);

  final InspectionSession session;
  final List<InspectionSessionItem> items;
  final List<InspectionStationObservation> observations;

  List<InspectionSessionItem> station(int stationIndex) => items
      .where((item) => item.routeItem.stationIndex == stationIndex)
      .toList(growable: false);

  List<InspectionStationObservation> observationsForItem(String itemId) =>
      observations
          .where((observation) => observation.itemId == itemId)
          .toList(growable: false);

  Map<String, Object?> toJson() => <String, Object?>{
        'session': session.toJson(),
        'items': items.map((item) => item.toJson()).toList(growable: false),
        'observations': observations
            .map((observation) => observation.toJson())
            .toList(growable: false),
      };

  factory InspectionDetails.fromJson(Map<String, Object?> json) =>
      InspectionDetails(
        session: InspectionSession.fromJson(
          Map<String, Object?>.from(json['session']! as Map),
        ),
        items: (json['items']! as List<Object?>)
            .map((item) => InspectionSessionItem.fromJson(
                  Map<String, Object?>.from(item! as Map),
                ))
            .toList(growable: false),
        observations:
            ((json['observations'] as List<Object?>?) ?? const <Object?>[])
                .map((item) => InspectionStationObservation.fromJson(
                      Map<String, Object?>.from(item! as Map),
                    ))
                .toList(growable: false),
      );
}

class InspectionStationObservation {
  const InspectionStationObservation({
    required this.id,
    required this.sessionId,
    required this.itemId,
    required this.type,
    required this.outcome,
    required this.severityChanged,
    required this.observedAt,
    this.treeIssueId,
    this.observedSeverity,
    this.notes,
    this.photoStoragePath,
    this.localPhotoBlobKey,
  });

  final String id;
  final String sessionId;
  final String itemId;
  final String? treeIssueId;
  final TreeIssueType type;
  final InspectionStationObservationOutcome outcome;
  final IssueSeverity? observedSeverity;
  final bool severityChanged;
  final String? notes;
  final String? photoStoragePath;
  final String? localPhotoBlobKey;
  final DateTime observedAt;

  factory InspectionStationObservation.fromJson(Map<String, Object?> json) =>
      InspectionStationObservation(
        id: json['id']! as String,
        sessionId: json['session_id']! as String,
        itemId: json['item_id']! as String,
        treeIssueId: json['tree_issue_id'] as String?,
        type: TreeIssueType.fromJson(json['issue_type']! as String),
        outcome: InspectionStationObservationOutcome.fromWire(
          json['outcome']! as String,
        ),
        observedSeverity: json['observed_severity'] == null
            ? null
            : IssueSeverity.fromJson(json['observed_severity']! as String),
        severityChanged: json['severity_changed']! as bool,
        notes: json['notes'] as String?,
        photoStoragePath: json['photo_storage_path'] as String?,
        localPhotoBlobKey: json['local_photo_blob_key'] as String?,
        observedAt: DateTime.parse(json['observed_at']! as String),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'session_id': sessionId,
        'item_id': itemId,
        'tree_issue_id': treeIssueId,
        'issue_type': type.wireValue,
        'outcome': outcome.wireValue,
        'observed_severity': observedSeverity?.name,
        'severity_changed': severityChanged,
        'notes': notes,
        'photo_storage_path': photoStoragePath,
        if (localPhotoBlobKey != null)
          'local_photo_blob_key': localPhotoBlobKey,
        'observed_at': observedAt.toIso8601String(),
      };
}

class InspectionCreationResult {
  const InspectionCreationResult(
      {required this.sessionId, required this.taskId});
  final String sessionId;
  final String taskId;
}

class InspectionCreationDraft {
  const InspectionCreationDraft({
    required this.farmId,
    required this.inspectorProfileId,
    required this.title,
    required this.route,
    this.scheduledFor,
    this.priority = 'medium',
    this.requiresEngineerReview = true,
    this.requiresIssuePhoto = false,
  });

  final String farmId;
  final String inspectorProfileId;
  final String title;
  final InspectionRoute route;
  final DateTime? scheduledFor;
  final String priority;
  final bool requiresEngineerReview;
  final bool requiresIssuePhoto;

  Map<String, Object?> toJson() => <String, Object?>{
        'farm_id': farmId,
        'inspector_profile_id': inspectorProfileId,
        'title': title,
        'route': route.toJson(),
        'scheduled_for': scheduledFor?.toIso8601String(),
        'priority': priority,
        'requires_engineer_review': requiresEngineerReview,
        'requires_issue_photo': requiresIssuePhoto,
      };

  factory InspectionCreationDraft.fromJson(Map<String, Object?> json) =>
      InspectionCreationDraft(
        farmId: json['farm_id']! as String,
        inspectorProfileId: json['inspector_profile_id']! as String,
        title: json['title']! as String,
        route: InspectionRoute.fromJson(
          Map<String, Object?>.from(json['route']! as Map),
        ),
        scheduledFor: _date(json['scheduled_for']),
        priority: json['priority']! as String,
        requiresEngineerReview: json['requires_engineer_review']! as bool,
        requiresIssuePhoto: json['requires_issue_photo']! as bool,
      );
}

class InspectionSelectedIssue {
  const InspectionSelectedIssue({
    required this.type,
    required this.severity,
    this.severityChanged = false,
    this.notes,
    this.photoStoragePath,
  });

  final TreeIssueType type;
  final IssueSeverity severity;
  final bool severityChanged;
  final String? notes;
  final String? photoStoragePath;

  Map<String, Object?> toJson() => <String, Object?>{
        'issue_type': type.wireValue,
        'severity': severity.name,
        'severity_changed': severityChanged,
        'notes': notes,
        'photo_storage_path': photoStoragePath,
      };

  factory InspectionSelectedIssue.fromJson(Map<String, Object?> json) =>
      InspectionSelectedIssue(
        type: TreeIssueType.fromJson(json['issue_type']! as String),
        severity: IssueSeverity.fromJson(json['severity']! as String),
        severityChanged: json['severity_changed']! as bool,
        notes: json['notes'] as String?,
        photoStoragePath: json['photo_storage_path'] as String?,
      );
}

class InspectionTreeResult {
  const InspectionTreeResult({
    required this.treeId,
    required this.noNewIssueFound,
    required this.selectedIssues,
    required this.clientObservedAt,
    this.notes,
  });

  final String treeId;
  final bool noNewIssueFound;
  final List<InspectionSelectedIssue> selectedIssues;
  final DateTime clientObservedAt;
  final String? notes;

  Map<String, Object?> toJson() => <String, Object?>{
        'tree_id': treeId,
        'no_new_issue_found': noNewIssueFound,
        'notes': notes,
        'client_observed_at': clientObservedAt.toUtc().toIso8601String(),
        'selected_issues':
            selectedIssues.map((item) => item.toJson()).toList(growable: false),
      };

  factory InspectionTreeResult.fromJson(Map<String, Object?> json) =>
      InspectionTreeResult(
        treeId: json['tree_id']! as String,
        noNewIssueFound: json['no_new_issue_found']! as bool,
        notes: json['notes'] as String?,
        clientObservedAt: DateTime.parse(json['client_observed_at']! as String),
        selectedIssues: (json['selected_issues']! as List<Object?>)
            .map((item) => InspectionSelectedIssue.fromJson(
                  Map<String, Object?>.from(item! as Map),
                ))
            .toList(growable: false),
      );
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.parse(value as String);
