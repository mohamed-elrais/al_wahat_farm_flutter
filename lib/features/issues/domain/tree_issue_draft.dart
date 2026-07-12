enum TreeIssueType {
  insufficientIrrigation,
  cloggedDripper,
  leakOrDripperDamage,
  harmfulWeed,
  pestOrDisease,
  treeDamage,
  other;

  String get wireValue => switch (this) {
        insufficientIrrigation => 'insufficient_irrigation',
        cloggedDripper => 'clogged_dripper',
        leakOrDripperDamage => 'leak_or_dripper_damage',
        harmfulWeed => 'harmful_weed',
        pestOrDisease => 'pest_or_disease',
        treeDamage => 'tree_damage',
        other => 'other',
      };

  factory TreeIssueType.fromJson(String value) => switch (value) {
        'insufficient_irrigation' => insufficientIrrigation,
        'clogged_dripper' => cloggedDripper,
        'leak_or_dripper_damage' => leakOrDripperDamage,
        'harmful_weed' => harmfulWeed,
        'pest_or_disease' => pestOrDisease,
        'tree_damage' => treeDamage,
        'other' => other,
        _ => throw FormatException('Unknown tree issue type: $value'),
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

  Map<String, Object?> toRpcParameters() => <String, Object?>{
        'p_tree_id': treeId,
        'p_issue_type': type.wireValue,
        'p_severity': severity.name,
        'p_description': description,
        'p_photo_storage_path': photoStoragePath,
      };
}
