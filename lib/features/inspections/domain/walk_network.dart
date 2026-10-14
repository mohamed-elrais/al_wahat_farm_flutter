import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_walk.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/farm_map_data.dart';

/// The irrigation network around one inspection walk, taken from the farm
/// map asset (works offline): landmarks the inspector can see on the ground.
class WalkNetwork {
  const WalkNetwork({
    required this.mains,
    required this.submains,
    required this.branches,
    required this.zoneValves,
    required this.isolationValves,
    required this.flushValves,
  });

  /// Valves without a section count when they stand this close to a tree.
  static const nearbyMeters = 30.0;

  final List<List<GeoCoordinate>> mains;
  final List<List<GeoCoordinate>> submains;
  final List<List<GeoCoordinate>> branches;
  final List<GeoCoordinate> zoneValves;
  final List<GeoCoordinate> isolationValves;
  final List<GeoCoordinate> flushValves;

  bool get isEmpty =>
      branches.isEmpty &&
      zoneValves.isEmpty &&
      isolationValves.isEmpty &&
      flushValves.isEmpty;

  /// Points that should fit on the map along with the trees.
  Iterable<GeoCoordinate> get landmarks sync* {
    for (final line in branches) {
      yield* line;
    }
    yield* zoneValves;
    yield* isolationValves;
    yield* flushValves;
  }

  /// The section's branch lines, valves and flush valves, plus the farm's
  /// mainline and submains (drawn clipped to the map). The section is the
  /// one whose outline contains the walk's trees, so no hierarchy is needed.
  static WalkNetwork? forWalk(FarmMapData data, InspectionWalk walk) {
    final section = _sectionOf(data, walk);
    if (section == null) return null;
    bool near(double latitude, double longitude) {
      final located =
          walk.locate(latitude, longitude, current: walk.stations.first);
      return located != null && located.metersOutside <= nearbyMeters;
    }

    final valves = data.valves
        .where((valve) =>
            valve.section == section ||
            (valve.section == null && near(valve.latitude, valve.longitude)))
        .toList(growable: false);
    GeoCoordinate point(double latitude, double longitude) =>
        GeoCoordinate(longitude: longitude, latitude: latitude);
    return WalkNetwork(
      mains: <List<GeoCoordinate>>[
        for (final line in data.waterLines)
          if (line.name.contains('Mainline')) line.coordinates,
      ],
      submains: <List<GeoCoordinate>>[
        for (final line in data.waterLines)
          if (!line.name.contains('Mainline')) line.coordinates,
      ],
      branches: <List<GeoCoordinate>>[
        for (final branch in data.branchLines)
          if (branch.section == section) branch.coordinates,
      ],
      zoneValves: <GeoCoordinate>[
        for (final valve in valves)
          if (valve.isZoneControl) point(valve.latitude, valve.longitude),
      ],
      isolationValves: <GeoCoordinate>[
        for (final valve in valves)
          if (!valve.isZoneControl) point(valve.latitude, valve.longitude),
      ],
      flushValves: <GeoCoordinate>[
        for (final flush in data.flushValves)
          if (flush.section == section) point(flush.latitude, flush.longitude),
      ],
    );
  }

  static String? _sectionOf(FarmMapData data, InspectionWalk walk) {
    final located = walk.items
        .where((item) => item.latitude != null && item.longitude != null)
        .take(5);
    for (final item in located) {
      for (final section in data.sections) {
        if (_contains(section.polygon, item.latitude!, item.longitude!)) {
          return section.id;
        }
      }
    }
    return null;
  }

  /// Ray casting; the polygon is small enough to treat degrees as planar.
  static bool _contains(
    List<GeoCoordinate> polygon,
    double latitude,
    double longitude,
  ) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final a = polygon[i];
      final b = polygon[j];
      if ((a.latitude > latitude) != (b.latitude > latitude) &&
          longitude <
              (b.longitude - a.longitude) *
                      (latitude - a.latitude) /
                      (b.latitude - a.latitude) +
                  a.longitude) {
        inside = !inside;
      }
    }
    return inside;
  }
}
