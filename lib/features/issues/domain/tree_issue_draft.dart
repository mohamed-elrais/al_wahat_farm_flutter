enum TreeIssueType {
  insufficientIrrigation,
  excessIrrigation,

  /// Clogged, leaking or damaged dripper. "Clogged dripper" and "Leak or
  /// dripper damage" were merged into it on 2026-10-14; it keeps the
  /// clogged_dripper wire value, and the retired leak value still reads as it.
  dripperProblem,
  harmfulWeed,
  pestOrDisease,
  treeDamage,
  other;

  String get wireValue => switch (this) {
        insufficientIrrigation => 'insufficient_irrigation',
        excessIrrigation => 'excess_irrigation',
        dripperProblem => 'clogged_dripper',
        harmfulWeed => 'harmful_weed',
        pestOrDisease => 'pest_or_disease',
        treeDamage => 'tree_damage',
        other => 'other',
      };

  factory TreeIssueType.fromJson(String value) => switch (value) {
        'insufficient_irrigation' => insufficientIrrigation,
        'excess_irrigation' => excessIrrigation,
        'clogged_dripper' || 'leak_or_dripper_damage' => dripperProblem,
        'harmful_weed' => harmfulWeed,
        'pest_or_disease' => pestOrDisease,
        'tree_damage' => treeDamage,
        'other' => other,
        _ => throw FormatException('Unknown tree issue type: $value'),
      };

  String get label => switch (this) {
        insufficientIrrigation => 'Insufficient irrigation',
        excessIrrigation => 'Too much water',
        dripperProblem => 'Dripper problem',
        harmfulWeed => 'Harmful weed',
        pestOrDisease => 'Pest or disease',
        treeDamage => 'Tree damage',
        other => 'Other',
      };
}

enum IssueSeverity {
  low,
  medium,
  high,
  urgent;

  factory IssueSeverity.fromJson(String value) => switch (value) {
        'low' => low,
        'medium' => medium,
        'high' => high,
        'urgent' => urgent,
        _ => throw FormatException('Unknown issue severity: $value'),
      };

  String get label => switch (this) {
        low => 'Low',
        medium => 'Medium',
        high => 'High',
        urgent => 'Urgent',
      };
}

class TreeIssueDraft {
  const TreeIssueDraft({
    required this.treeId,
    required this.type,
    required this.severity,
    this.description,
    this.photoStoragePath,
  });

  final String treeId;
  final TreeIssueType type;
  final IssueSeverity severity;
  final String? description;
  final String? photoStoragePath;

  String? validate() {
    if (treeId.trim().isEmpty) return 'Tree identity is required';
    if (description != null && description!.trim().length > 2000) {
      return 'Observation must be 2,000 characters or fewer';
    }
    return null;
  }

  Map<String, Object?> toRpcParameters() => <String, Object?>{
        'p_tree_id': treeId,
        'p_issue_type': type.wireValue,
        'p_severity': severity.name,
        'p_description': description,
        'p_photo_storage_path': photoStoragePath,
      };

  /// Round-trippable serialization used to carry a queued offline report in the
  /// outbox payload (distinct from [toRpcParameters]). Kept in sync with
  /// [TreeIssueDraft.fromJson].
  Map<String, Object?> toJson() => <String, Object?>{
        'tree_id': treeId,
        'issue_type': type.wireValue,
        'severity': severity.name,
        'description': description,
        'photo_storage_path': photoStoragePath,
      };

  factory TreeIssueDraft.fromJson(Map<String, Object?> json) => TreeIssueDraft(
        treeId: json['tree_id']! as String,
        type: TreeIssueType.fromJson(json['issue_type']! as String),
        severity: IssueSeverity.fromJson(json['severity']! as String),
        description: json['description'] as String?,
        photoStoragePath: json['photo_storage_path'] as String?,
      );
}
