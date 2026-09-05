enum PlantingPitStatus {
  planned,
  marked,
  dug,
  prepared,
  completed,
  cancelled;

  factory PlantingPitStatus.fromJson(String value) => switch (value) {
        'planned' => planned,
        'marked' => marked,
        'dug' => dug,
        'prepared' => prepared,
        'completed' => completed,
        'cancelled' => cancelled,
        _ => throw FormatException('Unknown planting pit status: $value'),
      };

  String get wireValue => name;

  PlantingPitStatus? get next => switch (this) {
        planned => marked,
        marked => dug,
        dug => prepared,
        prepared => completed,
        completed || cancelled => null,
      };

  bool get canCancel => switch (this) {
        planned || marked || dug || prepared => true,
        completed || cancelled => false,
      };
}

class PlantingPit {
  const PlantingPit({
    required this.id,
    required this.farmId,
    required this.sectionId,
    required this.pitCode,
    required this.status,
    required this.createdByProfileId,
    required this.createdAt,
    required this.updatedAt,
    this.irrigationZoneId,
    this.rowNumber,
    this.pitNumber,
    this.latitude,
    this.longitude,
    this.plannedFor,
    this.markedAt,
    this.dugAt,
    this.preparedAt,
    this.completedAt,
    this.cancelledAt,
    this.notes,
  });

  final String id;
  final String farmId;
  final String sectionId;
  final String? irrigationZoneId;
  final String pitCode;
  final int? rowNumber;
  final int? pitNumber;
  final double? latitude;
  final double? longitude;
  final DateTime? plannedFor;
  final PlantingPitStatus status;
  final DateTime? markedAt;
  final DateTime? dugAt;
  final DateTime? preparedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? notes;
  final String createdByProfileId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory PlantingPit.fromJson(Map<String, Object?> json) => PlantingPit(
        id: json['id']! as String,
        farmId: json['farm_id']! as String,
        sectionId: json['section_id']! as String,
        irrigationZoneId: json['irrigation_zone_id'] as String?,
        pitCode: json['pit_code']! as String,
        rowNumber: (json['row_number'] as num?)?.toInt(),
        pitNumber: (json['pit_number'] as num?)?.toInt(),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        plannedFor: _optionalDate(json['planned_for']),
        status: PlantingPitStatus.fromJson(json['status']! as String),
        markedAt: _optionalDateTime(json['marked_at']),
        dugAt: _optionalDateTime(json['dug_at']),
        preparedAt: _optionalDateTime(json['prepared_at']),
        completedAt: _optionalDateTime(json['completed_at']),
        cancelledAt: _optionalDateTime(json['cancelled_at']),
        notes: json['notes'] as String?,
        createdByProfileId: json['created_by_profile_id']! as String,
        createdAt: DateTime.parse(json['created_at']! as String),
        updatedAt: DateTime.parse(json['updated_at']! as String),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'farm_id': farmId,
        'section_id': sectionId,
        'irrigation_zone_id': irrigationZoneId,
        'pit_code': pitCode,
        'row_number': rowNumber,
        'pit_number': pitNumber,
        'latitude': latitude,
        'longitude': longitude,
        'planned_for': _date(plannedFor),
        'status': status.wireValue,
        'marked_at': markedAt?.toIso8601String(),
        'dug_at': dugAt?.toIso8601String(),
        'prepared_at': preparedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'cancelled_at': cancelledAt?.toIso8601String(),
        'notes': notes,
        'created_by_profile_id': createdByProfileId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class PlantingPitDraft {
  const PlantingPitDraft({
    required this.farmId,
    required this.sectionId,
    required this.pitCode,
    this.irrigationZoneId,
    this.rowNumber,
    this.pitNumber,
    this.latitude,
    this.longitude,
    this.plannedFor,
    this.notes,
  });

  final String farmId;
  final String sectionId;
  final String? irrigationZoneId;
  final String pitCode;
  final int? rowNumber;
  final int? pitNumber;
  final double? latitude;
  final double? longitude;
  final DateTime? plannedFor;
  final String? notes;

  Map<String, Object?> toInsertJson() => <String, Object?>{
        'farm_id': farmId,
        'section_id': sectionId,
        if (irrigationZoneId != null) 'irrigation_zone_id': irrigationZoneId,
        'pit_code': pitCode.trim(),
        if (rowNumber != null) 'row_number': rowNumber,
        if (pitNumber != null) 'pit_number': pitNumber,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (plannedFor != null) 'planned_for': _date(plannedFor),
        if (notes?.trim().isNotEmpty ?? false) 'notes': notes!.trim(),
      };
}

DateTime? _optionalDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

DateTime? _optionalDateTime(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

String? _date(DateTime? value) => value == null
    ? null
    : '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
