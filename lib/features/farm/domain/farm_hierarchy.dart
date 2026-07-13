enum TreeHealthStatus {
  healthy,
  needsMonitoring,
  needsEngineerReview,
  inactive;

  factory TreeHealthStatus.fromJson(String value) => switch (value) {
        'healthy' => healthy,
        'needs_monitoring' => needsMonitoring,
        'needs_engineer_review' => needsEngineerReview,
        'inactive' => inactive,
        _ => throw FormatException('Unknown tree health status: $value'),
      };

  String get wireValue => switch (this) {
        healthy => 'healthy',
        needsMonitoring => 'needs_monitoring',
        needsEngineerReview => 'needs_engineer_review',
        inactive => 'inactive',
      };
}

class FarmSection {
  const FarmSection({
    required this.id,
    required this.farmId,
    required this.code,
    required this.name,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.areaM2,
    this.notes,
  });

  final String id;
  final String farmId;
  final String code;
  final String name;
  final int sortOrder;
  final double? areaM2;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FarmSection.fromJson(Map<String, Object?> json) => FarmSection(
        id: json['id']! as String,
        farmId: json['farm_id']! as String,
        code: json['code']! as String,
        name: json['name']! as String,
        sortOrder: (json['sort_order']! as num).toInt(),
        areaM2: (json['area_m2'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        isActive: json['is_active']! as bool,
        createdAt: DateTime.parse(json['created_at']! as String),
        updatedAt: DateTime.parse(json['updated_at']! as String),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'farm_id': farmId,
        'code': code,
        'name': name,
        'sort_order': sortOrder,
        'area_m2': areaM2,
        'notes': notes,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class IrrigationZone {
  const IrrigationZone({
    required this.id,
    required this.sectionId,
    required this.code,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.valveCode,
    this.notes,
  });

  final String id;
  final String sectionId;
  final String code;
  final String name;
  final String? valveCode;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory IrrigationZone.fromJson(Map<String, Object?> json) => IrrigationZone(
        id: json['id']! as String,
        sectionId: json['section_id']! as String,
        code: json['code']! as String,
        name: json['name']! as String,
        valveCode: json['valve_code'] as String?,
        notes: json['notes'] as String?,
        isActive: json['is_active']! as bool,
        createdAt: DateTime.parse(json['created_at']! as String),
        updatedAt: DateTime.parse(json['updated_at']! as String),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'section_id': sectionId,
        'code': code,
        'name': name,
        'valve_code': valveCode,
        'notes': notes,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class FarmTreeRecord {
  const FarmTreeRecord({
    required this.id,
    required this.farmId,
    required this.sectionId,
    required this.treeCode,
    required this.healthStatus,
    required this.type,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.irrigationZoneId,
    this.rowNumber,
    this.treeNumber,
    this.plantedOn,
    this.latitude,
    this.longitude,
    this.notes,
  });

  final String id;
  final String farmId;
  final String sectionId;
  final String? irrigationZoneId;
  final String treeCode;
  final int? rowNumber;
  final int? treeNumber;
  final DateTime? plantedOn;
  final double? latitude;
  final double? longitude;
  final TreeHealthStatus healthStatus;
  final String type;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FarmTreeRecord.fromJson(Map<String, Object?> json) => FarmTreeRecord(
        id: json['id']! as String,
        farmId: json['farm_id']! as String,
        sectionId: json['section_id']! as String,
        irrigationZoneId: json['irrigation_zone_id'] as String?,
        treeCode: json['tree_code']! as String,
        rowNumber: (json['row_number'] as num?)?.toInt(),
        treeNumber: (json['tree_number'] as num?)?.toInt(),
        plantedOn: _optionalDate(json['planted_on']),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        healthStatus:
            TreeHealthStatus.fromJson(json['health_status']! as String),
        type: json['type']! as String,
        notes: json['notes'] as String?,
        isActive: json['is_active']! as bool,
        createdAt: DateTime.parse(json['created_at']! as String),
        updatedAt: DateTime.parse(json['updated_at']! as String),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'farm_id': farmId,
        'section_id': sectionId,
        'irrigation_zone_id': irrigationZoneId,
        'tree_code': treeCode,
        'row_number': rowNumber,
        'tree_number': treeNumber,
        'planted_on': plantedOn?.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'health_status': healthStatus.wireValue,
        'type': type,
        'notes': notes,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class FarmHierarchy {
  FarmHierarchy({
    required this.farmId,
    required List<FarmSection> sections,
    required List<IrrigationZone> zones,
    required List<FarmTreeRecord> trees,
  })  : sections = List<FarmSection>.unmodifiable(sections),
        zones = List<IrrigationZone>.unmodifiable(zones),
        trees = List<FarmTreeRecord>.unmodifiable(trees) {
    _validateRelationships();
  }

  final String farmId;
  final List<FarmSection> sections;
  final List<IrrigationZone> zones;
  final List<FarmTreeRecord> trees;

  FarmSection? sectionByCode(String code) {
    for (final section in sections) {
      if (section.code == code) return section;
    }
    return null;
  }

  FarmSection? sectionById(String id) {
    for (final section in sections) {
      if (section.id == id) return section;
    }
    return null;
  }

  /// A cache-safe representation that round-trips through [fromCacheJson] using
  /// the same column names the Supabase `fromJson` factories read.
  Map<String, Object?> toCacheJson() => <String, Object?>{
        'farm_id': farmId,
        'sections':
            sections.map((section) => section.toJson()).toList(growable: false),
        'zones': zones.map((zone) => zone.toJson()).toList(growable: false),
        'trees': trees.map((tree) => tree.toJson()).toList(growable: false),
      };

  factory FarmHierarchy.fromCacheJson(Map<String, Object?> json) =>
      FarmHierarchy(
        farmId: json['farm_id']! as String,
        sections: (json['sections']! as List<Object?>)
            .map((row) => FarmSection.fromJson(
                  Map<String, Object?>.from(row! as Map),
                ))
            .toList(growable: false),
        zones: (json['zones']! as List<Object?>)
            .map((row) => IrrigationZone.fromJson(
                  Map<String, Object?>.from(row! as Map),
                ))
            .toList(growable: false),
        trees: (json['trees']! as List<Object?>)
            .map((row) => FarmTreeRecord.fromJson(
                  Map<String, Object?>.from(row! as Map),
                ))
            .toList(growable: false),
      );

  void _validateRelationships() {
    final sectionIds = <String>{};
    final sectionCodes = <String>{};
    for (final section in sections) {
      if (section.farmId != farmId) {
        throw FormatException('Section ${section.id} belongs to another farm');
      }
      if (!sectionIds.add(section.id) || !sectionCodes.add(section.code)) {
        throw FormatException(
            'Duplicate section ${section.id}/${section.code}');
      }
    }

    final zoneIds = <String>{};
    for (final zone in zones) {
      if (!sectionIds.contains(zone.sectionId)) {
        throw FormatException('Zone ${zone.id} references an unknown section');
      }
      if (!zoneIds.add(zone.id)) {
        throw FormatException('Duplicate irrigation zone ${zone.id}');
      }
    }

    final treeIds = <String>{};
    final treeCodes = <String>{};
    for (final tree in trees) {
      if (tree.farmId != farmId || !sectionIds.contains(tree.sectionId)) {
        throw FormatException('Tree ${tree.id} has an invalid farm hierarchy');
      }
      final zoneId = tree.irrigationZoneId;
      if (zoneId != null && !zoneIds.contains(zoneId)) {
        throw FormatException('Tree ${tree.id} references an unknown zone');
      }
      if (!treeIds.add(tree.id) || !treeCodes.add(tree.treeCode)) {
        throw FormatException('Duplicate tree ${tree.id}/${tree.treeCode}');
      }
    }
  }
}

DateTime? _optionalDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);
