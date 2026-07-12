import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';

enum TreeIssueStatus {
  open,
  inReview,
  resolved,
  dismissed;

  factory TreeIssueStatus.fromJson(String value) => switch (value) {
        'open' => open,
        'in_review' => inReview,
        'resolved' => resolved,
        'dismissed' => dismissed,
        _ => throw FormatException('Unknown tree issue status: $value'),
      };
}

class TreeIssue {
  const TreeIssue({
    required this.id,
    required this.farmId,
    required this.treeId,
    required this.type,
    required this.severity,
    required this.status,
    required this.reportedByProfileId,
    required this.reportedAt,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.reviewedByProfileId,
    this.reviewedAt,
    this.resolvedByProfileId,
    this.resolvedAt,
    this.resolutionNotes,
    this.linkedTaskId,
  });

  final String id;
  final String farmId;
  final String treeId;
  final TreeIssueType type;
  final IssueSeverity severity;
  final TreeIssueStatus status;
  final String? description;
  final String reportedByProfileId;
  final DateTime reportedAt;
  final String? reviewedByProfileId;
  final DateTime? reviewedAt;
  final String? resolvedByProfileId;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final String? linkedTaskId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TreeIssue.fromJson(Map<String, Object?> json) => TreeIssue(
        id: json['id']! as String,
        farmId: json['farm_id']! as String,
        treeId: json['tree_id']! as String,
        type: TreeIssueType.fromJson(json['issue_type']! as String),
        severity: IssueSeverity.fromJson(json['severity']! as String),
        status: TreeIssueStatus.fromJson(json['status']! as String),
        description: json['description'] as String?,
        reportedByProfileId: json['reported_by_profile_id']! as String,
        reportedAt: DateTime.parse(json['reported_at']! as String),
        reviewedByProfileId: json['reviewed_by_profile_id'] as String?,
        reviewedAt: _optionalDate(json['reviewed_at']),
        resolvedByProfileId: json['resolved_by_profile_id'] as String?,
        resolvedAt: _optionalDate(json['resolved_at']),
        resolutionNotes: json['resolution_notes'] as String?,
        linkedTaskId: json['linked_task_id'] as String?,
        createdAt: DateTime.parse(json['created_at']! as String),
        updatedAt: DateTime.parse(json['updated_at']! as String),
      );
}

DateTime? _optionalDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);
