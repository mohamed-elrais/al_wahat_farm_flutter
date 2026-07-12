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

class FarmMapData {
  const FarmMapData({
    required this.generatedFrom,
    required this.bounds,
    required this.sections,
    required this.trees,
    required this.layout,
    required this.utilities,
    required this.waterLines,
  });

  final String generatedFrom;
  final FarmBounds bounds;
  final List<FarmSectionGeometry> sections;
  final List<FarmTree> trees;
  final List<GeoShape> layout;
  final List<GeoShape> utilities;
  final List<GeoShape> waterLines;

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
