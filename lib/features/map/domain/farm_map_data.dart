import 'dart:ui';

class GeoCoordinate {
  const GeoCoordinate({required this.longitude, required this.latitude});

  final double longitude;
  final double latitude;

  factory GeoCoordinate.fromJson(Object? value) {
    final pair = (value as List<Object?>);
    if (pair.length < 2) {
      throw const FormatException('Coordinate needs longitude and latitude');
    }
    return GeoCoordinate(
      longitude: (pair[0] as num).toDouble(),
      latitude: (pair[1] as num).toDouble(),
    );
  }
}

class FarmBounds {
  const FarmBounds({
    required this.minLongitude,
    required this.maxLongitude,
    required this.minLatitude,
    required this.maxLatitude,
  });

  final double minLongitude;
  final double maxLongitude;
  final double minLatitude;
  final double maxLatitude;

  factory FarmBounds.fromJson(Map<String, Object?> json) => FarmBounds(
        minLongitude: (json['minLng']! as num).toDouble(),
        maxLongitude: (json['maxLng']! as num).toDouble(),
        minLatitude: (json['minLat']! as num).toDouble(),
        maxLatitude: (json['maxLat']! as num).toDouble(),
      );
}

class FarmSectionGeometry {
  const FarmSectionGeometry({
    required this.id,
    required this.name,
    required this.area,
    required this.planted,
    required this.treeCount,
    required this.polygon,
  });

  final String id;
  final String name;
  final double area;
  final bool planted;
  final int treeCount;
  final List<GeoCoordinate> polygon;

  factory FarmSectionGeometry.fromJson(Map<String, Object?> json) =>
      FarmSectionGeometry(
        id: json['id']! as String,
        name: json['name']! as String,
        area: (json['area']! as num).toDouble(),
        planted: json['planted']! as bool,
        treeCount: (json['treeCount']! as num).toInt(),
        polygon: _coordinates(json['polygon']),
      );
}

class FarmTree {
  const FarmTree({
    required this.id,
    required this.code,
    required this.section,
    required this.zoneId,
    required this.row,
    required this.number,
    required this.latitude,
    required this.longitude,
    required this.health,
    required this.type,
    required this.color,
  });

  final String id;
  final String code;
  final String section;
  final String zoneId;
  final int row;
  final int number;
  final double latitude;
  final double longitude;
  final String health;
  final String type;
  final Color color;

  factory FarmTree.fromJson(Map<String, Object?> json) => FarmTree(
        id: json['id']! as String,
        code: json['code']! as String,
        section: json['section']! as String,
        zoneId: json['zoneId']! as String,
        row: (json['row']! as num).toInt(),
        number: (json['number']! as num).toInt(),
        latitude: (json['lat']! as num).toDouble(),
        longitude: (json['lng']! as num).toDouble(),
        health: json['health']! as String,
        type: json['type']! as String,
        color: _parseColor(json['color']! as String),
      );
}

class GeoShape {
  const GeoShape({required this.name, required this.coordinates});

  final String name;
  final List<GeoCoordinate> coordinates;

  factory GeoShape.fromJson(Map<String, Object?> json) => GeoShape(
        name: json['name']! as String,
        coordinates: _coordinates(json['coordinates']),
      );
}

/// A single-coordinate irrigation-network feature: flush valve, distribution
/// riser, pump, well, pipe bend/takeoff.
class NetworkPoint {
  const NetworkPoint({
    required this.assetId,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.section,
    this.submain,
    this.status,
  });

  final String assetId;
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final String? section;
  final String? submain;
  final String? status;

  factory NetworkPoint.fromJson(Map<String, Object?> json) => NetworkPoint(
        assetId: json['assetId']! as String,
        name: json['name']! as String,
        type: json['type']! as String,
        latitude: (json['lat']! as num).toDouble(),
        longitude: (json['lng']! as num).toDouble(),
        section: json['section'] as String?,
        submain: json['submain'] as String?,
        status: json['status'] as String?,
      );
}

/// A zone control valve or mainline isolation valve. Zone control valves are
/// the irrigation-zone markers: [zoneUuid] matches the live zone id carried by
/// the trees they irrigate, and [color] matches those trees' zone color.
class NetworkValve {
  const NetworkValve({
    required this.assetId,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.section,
    this.submain,
    this.zoneId,
    this.zoneUuid,
    this.color,
    this.zoneTreeCount,
    this.status,
    this.downstreamSubmains,
    this.downstreamLine,
  });

  final String assetId;
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final String? section;
  final String? submain;
  final String? zoneId;
  final String? zoneUuid;
  final Color? color;
  final int? zoneTreeCount;
  final String? status;

  /// Isolation valves only: the submains fed through this valve and the pipe
  /// geometry beyond it (derived from the surveyed mainline topology by the
  /// asset generator).
  final List<String>? downstreamSubmains;
  final List<GeoCoordinate>? downstreamLine;

  bool get isZoneControl => type == 'zone_control_valve';

  factory NetworkValve.fromJson(Map<String, Object?> json) => NetworkValve(
        assetId: json['assetId']! as String,
        name: json['name']! as String,
        type: json['type']! as String,
        latitude: (json['lat']! as num).toDouble(),
        longitude: (json['lng']! as num).toDouble(),
        section: json['section'] as String?,
        submain: json['submain'] as String?,
        zoneId: json['zoneId'] as String?,
        zoneUuid: json['zoneUuid'] as String?,
        color: json['color'] == null
            ? null
            : _parseColor(json['color']! as String),
        zoneTreeCount: (json['zoneTreeCount'] as num?)?.toInt(),
        status: json['status'] as String?,
        downstreamSubmains:
            (json['downstreamSubmains'] as List<Object?>?)?.cast<String>(),
        downstreamLine: json['downstreamLine'] == null
            ? null
            : _coordinates(json['downstreamLine']),
      );
}

/// An irrigation branch line, colored and keyed by the zone (ZCV) feeding it.
class BranchLine {
  const BranchLine({
    required this.assetId,
    required this.name,
    required this.section,
    required this.submain,
    required this.coordinates,
    this.zoneId,
    this.zoneUuid,
    this.color,
    this.status,
  });

  final String assetId;
  final String name;
  final String section;
  final String submain;
  final List<GeoCoordinate> coordinates;
  final String? zoneId;
  final String? zoneUuid;
  final Color? color;
  final String? status;

  factory BranchLine.fromJson(Map<String, Object?> json) => BranchLine(
        assetId: json['assetId']! as String,
        name: json['name']! as String,
        section: json['section']! as String,
        submain: json['submain']! as String,
        coordinates: _coordinates(json['coordinates']),
        zoneId: json['zoneId'] as String?,
        zoneUuid: json['zoneUuid'] as String?,
        color: json['color'] == null
            ? null
            : _parseColor(json['color']! as String),
        status: json['status'] as String?,
      );
}

/// A water-supply line (tank transfer, well/tank discharge, mosque supply).
class SupplyLine {
  const SupplyLine({
    required this.assetId,
    required this.name,
    required this.type,
    required this.coordinates,
    this.diameterIn,
    this.status,
  });

  final String assetId;
  final String name;
  final String type;
  final List<GeoCoordinate> coordinates;
  final double? diameterIn;
  final String? status;

  factory SupplyLine.fromJson(Map<String, Object?> json) => SupplyLine(
        assetId: json['assetId']! as String,
        name: json['name']! as String,
        type: json['type']! as String,
        coordinates: _coordinates(json['coordinates']),
        diameterIn: (json['diameterIn'] as num?)?.toDouble(),
        status: json['status'] as String?,
      );
}

/// The water source & supply layer: well/pumps/bends as points, transfer and
/// discharge pipes as lines (tank/mainline shapes already live in the legacy
/// utilities/waterLines layers).
class WaterSupply {
  const WaterSupply({
    this.points = const <NetworkPoint>[],
    this.lines = const <SupplyLine>[],
    this.polygons = const <SupplyLine>[],
  });

  final List<NetworkPoint> points;
  final List<SupplyLine> lines;
  final List<SupplyLine> polygons;

  factory WaterSupply.fromJson(Map<String, Object?> json) => WaterSupply(
        points: _objectList(
          json['points'] ?? const <Object?>[],
        ).map(NetworkPoint.fromJson).toList(growable: false),
        lines: _objectList(
          json['lines'] ?? const <Object?>[],
        ).map(SupplyLine.fromJson).toList(growable: false),
        polygons: _objectList(
          json['polygons'] ?? const <Object?>[],
        ).map(SupplyLine.fromJson).toList(growable: false),
      );
}

class FarmMapData {
  const FarmMapData({
    required this.generatedFrom,
    required this.bounds,
    required this.sections,
    required this.trees,
    required this.layout,
    required this.utilities,
    required this.waterLines,
    this.branchLines = const <BranchLine>[],
    this.valves = const <NetworkValve>[],
    this.flushValves = const <NetworkPoint>[],
    this.risers = const <NetworkPoint>[],
    this.waterSupply = const WaterSupply(),
  });

  final String generatedFrom;
  final FarmBounds bounds;
  final List<FarmSectionGeometry> sections;
  final List<FarmTree> trees;
  final List<GeoShape> layout;
  final List<GeoShape> utilities;
  final List<GeoShape> waterLines;
  final List<BranchLine> branchLines;
  final List<NetworkValve> valves;
  final List<NetworkPoint> flushValves;
  final List<NetworkPoint> risers;
  final WaterSupply waterSupply;

  factory FarmMapData.fromJson(Map<String, Object?> json) {
    final data = FarmMapData(
      generatedFrom: json['generatedFrom']! as String,
      bounds: FarmBounds.fromJson(json['bounds']! as Map<String, Object?>),
      sections: _objectList(
        json['sections'],
      ).map(FarmSectionGeometry.fromJson).toList(growable: false),
      trees: _objectList(
        json['trees'],
      ).map(FarmTree.fromJson).toList(growable: false),
      layout: _objectList(
        json['layout'],
      ).map(GeoShape.fromJson).toList(growable: false),
      utilities: _objectList(
        json['utilities'],
      ).map(GeoShape.fromJson).toList(growable: false),
      waterLines: _objectList(
        json['waterLines'],
      ).map(GeoShape.fromJson).toList(growable: false),
      branchLines: _objectList(
        json['branchLines'] ?? const <Object?>[],
      ).map(BranchLine.fromJson).toList(growable: false),
      valves: _objectList(
        json['valves'] ?? const <Object?>[],
      ).map(NetworkValve.fromJson).toList(growable: false),
      flushValves: _objectList(
        json['flushValves'] ?? const <Object?>[],
      ).map(NetworkPoint.fromJson).toList(growable: false),
      risers: _objectList(
        json['risers'] ?? const <Object?>[],
      ).map(NetworkPoint.fromJson).toList(growable: false),
      waterSupply: json['waterSupply'] == null
          ? const WaterSupply()
          : WaterSupply.fromJson(json['waterSupply']! as Map<String, Object?>),
    );
    data.validateReferenceContract();
    return data;
  }

  void validateReferenceContract() {
    const counts = <String, int>{
      'A': 298,
      'B': 330,
      'C': 168,
      'D': 303,
      'E': 0,
      'F': 360,
      'G': 108,
      'L': 0,
      'M': 0,
      'N': 0,
      'O': 0,
      'Q': 0,
    };
    if (sections.length != 12 || trees.length != 1567) {
      throw FormatException(
        'Expected 12 sections and 1567 trees; got ${sections.length} and ${trees.length}',
      );
    }
    for (final section in sections) {
      if (counts[section.id] != section.treeCount) {
        throw FormatException(
          'Section ${section.id} expected ${counts[section.id]} trees, got ${section.treeCount}',
        );
      }
      final actual = trees.where((tree) => tree.section == section.id).length;
      if (actual != section.treeCount) {
        throw FormatException(
          'Section ${section.id} metadata/tree row mismatch: ${section.treeCount}/$actual',
        );
      }
    }
  }
}

List<Map<String, Object?>> _objectList(Object? value) =>
    (value! as List<Object?>)
        .map((item) => item! as Map<String, Object?>)
        .toList(growable: false);

List<GeoCoordinate> _coordinates(Object? value) => (value! as List<Object?>)
    .map(GeoCoordinate.fromJson)
    .toList(growable: false);

Color _parseColor(String hex) {
  final value = int.parse(hex.substring(1), radix: 16);
  return Color(0xFF000000 | value);
}
