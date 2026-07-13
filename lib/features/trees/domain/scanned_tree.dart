class ScannedTree {
  const ScannedTree({
    required this.id,
    required this.farmId,
    required this.sectionId,
    required this.sectionCode,
    required this.sectionName,
    required this.code,
    required this.healthStatus,
    required this.type,
    this.irrigationZoneId,
    this.rowNumber,
    this.treeNumber,
  });

  final String id;
  final String farmId;
  final String sectionId;
  final String sectionCode;
  final String sectionName;
  final String? irrigationZoneId;
  final String code;
  final int? rowNumber;
  final int? treeNumber;
  final String healthStatus;
  final String type;

  factory ScannedTree.fromJson(Map<String, Object?> json) => ScannedTree(
        id: json['tree_id']! as String,
        farmId: json['farm_id']! as String,
        sectionId: json['section_id']! as String,
        sectionCode: json['section_code']! as String,
        sectionName: json['section_name']! as String,
        irrigationZoneId: json['irrigation_zone_id'] as String?,
        code: json['tree_code']! as String,
        rowNumber: (json['row_number'] as num?)?.toInt(),
        treeNumber: (json['tree_number'] as num?)?.toInt(),
        healthStatus: json['health_status']! as String,
        type: json['type']! as String,
      );
}
