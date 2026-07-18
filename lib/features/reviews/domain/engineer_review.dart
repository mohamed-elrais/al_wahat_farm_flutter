enum EngineerReviewDecision {
  approved,
  returnedForCorrection,
  followUpRequired;

  factory EngineerReviewDecision.fromJson(String value) => switch (value) {
        'approved' => approved,
        'returned_for_correction' => returnedForCorrection,
        'follow_up_required' => followUpRequired,
        _ => throw FormatException('Unknown review decision: $value'),
      };

  String get wireValue => switch (this) {
        approved => 'approved',
        returnedForCorrection => 'returned_for_correction',
        followUpRequired => 'follow_up_required',
      };

  String get label => switch (this) {
        approved => 'Approved',
        returnedForCorrection => 'Returned for correction',
        followUpRequired => 'Follow-up required',
      };

  /// The action-button verb a reviewer taps to record this decision.
  String get actionLabel => switch (this) {
        approved => 'Approve',
        returnedForCorrection => 'Return for correction',
        followUpRequired => 'Request follow-up',
      };
}

class ReviewTaskDraft {
  const ReviewTaskDraft({
    required this.taskId,
    required this.decision,
    this.notes,
    this.photoStoragePath,
  });

  final String taskId;
  final EngineerReviewDecision decision;
  final String? notes;
  final String? photoStoragePath;

  Map<String, Object?> toRpcParameters() => <String, Object?>{
        'p_task_id': taskId,
        'p_decision': decision.wireValue,
        'p_notes': notes,
        'p_photo_storage_path': photoStoragePath,
      };

  ReviewTaskDraft withPhotoStoragePath(String? path) => ReviewTaskDraft(
        taskId: taskId,
        decision: decision,
        notes: notes,
        photoStoragePath: path,
      );

  /// Round-trippable serialization for carrying a queued offline review in the
  /// outbox payload. Kept in sync with [ReviewTaskDraft.fromJson].
  Map<String, Object?> toJson() => <String, Object?>{
        'task_id': taskId,
        'decision': decision.wireValue,
        'notes': notes,
        'photo_storage_path': photoStoragePath,
      };

  factory ReviewTaskDraft.fromJson(Map<String, Object?> json) =>
      ReviewTaskDraft(
        taskId: json['task_id']! as String,
        decision: EngineerReviewDecision.fromJson(json['decision']! as String),
        notes: json['notes'] as String?,
        photoStoragePath: json['photo_storage_path'] as String?,
      );
}

class EngineerReview {
  const EngineerReview({
    required this.id,
    required this.taskId,
    required this.reviewerProfileId,
    required this.decision,
    required this.reviewedAt,
    required this.createdAt,
    this.treeIssueId,
    this.notes,
  });

  final String id;
  final String taskId;
  final String? treeIssueId;
  final String reviewerProfileId;
  final EngineerReviewDecision decision;
  final String? notes;
  final DateTime reviewedAt;
  final DateTime createdAt;

  factory EngineerReview.fromJson(Map<String, Object?> json) => EngineerReview(
        id: json['id']! as String,
        taskId: json['task_id']! as String,
        treeIssueId: json['tree_issue_id'] as String?,
        reviewerProfileId: json['reviewer_profile_id']! as String,
        decision: EngineerReviewDecision.fromJson(json['decision']! as String),
        notes: json['notes'] as String?,
        reviewedAt: DateTime.parse(json['reviewed_at']! as String),
        createdAt: DateTime.parse(json['created_at']! as String),
      );
}
