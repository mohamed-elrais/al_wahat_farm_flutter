import 'dart:math' as math;

import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route.dart';

/// Where a station sits on the walk, in terms an inspector can use in the
/// field: the aisle (the planner's corridor between two tree rows), the
/// position along it, and what comes next.
class InspectionWalkStep {
  const InspectionWalkStep({
    required this.station,
    required this.items,
    required this.aisle,
    required this.aisleCount,
    required this.stationInAisle,
    required this.stationsInAisle,
    required this.next,
  });

  final int station;
  final List<InspectionRouteItem> items;
  final int aisle;
  final int aisleCount;

  /// 1-based position of [station] within its aisle.
  final int stationInAisle;
  final int stationsInAisle;

  /// The trees of the following station; empty at the end of the walk.
  final List<InspectionRouteItem> next;

  bool get startsAisle => stationInAisle == 1;
  bool get endsAisle => stationInAisle == stationsInAisle;

  /// The aisle the walk continues into after this station, when it changes.
  int? get nextAisle =>
      endsAisle && next.isNotEmpty ? next.first.corridorIndex : null;

  /// Source row numbers of this station's trees, left side first.
  List<int> get rows => _rows(items);

  static List<int> _rows(List<InspectionRouteItem> items) {
    final sorted = List<InspectionRouteItem>.of(items)
      ..sort((a, b) => a.side.index.compareTo(b.side.index));
    final rows = <int>[];
    for (final item in sorted) {
      final row = item.rowNumber;
      if (row != null && !rows.contains(row)) rows.add(row);
    }
    return rows;
  }
}

/// Where a GPS fix puts the inspector relative to the current station.
class InspectionWalkFix {
  const InspectionWalkFix({
    required this.metersToStation,
    required this.nearestStation,
    required this.nearestAisle,
    required this.metersOutside,
  });

  /// Distance from the fix to the current station's centre.
  final double metersToStation;

  /// The station whose centre is closest to the fix.
  final int nearestStation;
  final int nearestAisle;

  /// How far the fix is from the nearest tree of the section, used to tell
  /// "you are not in this section" apart from "you are off by a few trees".
  final double metersOutside;
}

/// The walking route as aisles and stations, with flat-earth geometry that is
/// accurate to centimetres over a farm section.
class InspectionWalk {
  InspectionWalk(Iterable<InspectionRouteItem> items)
      : items = List<InspectionRouteItem>.unmodifiable(
          List<InspectionRouteItem>.of(items)
            ..sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex)),
        ) {
    for (final item in this.items) {
      _byStation.putIfAbsent(item.stationIndex, () => []).add(item);
    }
    stations = _byStation.keys.toList(growable: false)..sort();
    for (final station in stations) {
      final aisle = _byStation[station]!.first.corridorIndex;
      _aisles.putIfAbsent(aisle, () => []).add(station);
      final located = _byStation[station]!
          .where((item) => item.latitude != null && item.longitude != null)
          .toList(growable: false);
      if (located.isNotEmpty) {
        _centers[station] = (
          latitude: located.map((item) => item.latitude!).reduce(_sum) /
              located.length,
          longitude: located.map((item) => item.longitude!).reduce(_sum) /
              located.length,
        );
      }
    }
  }

  final List<InspectionRouteItem> items;
  late final List<int> stations;
  final Map<int, List<InspectionRouteItem>> _byStation = {};
  final Map<int, List<int>> _aisles = {};
  final Map<int, ({double latitude, double longitude})> _centers = {};

  int get aisleCount => _aisles.length;

  /// Whether any tree has map coordinates, i.e. whether a map can be drawn.
  bool get hasCoordinates => _centers.isNotEmpty;

  ({double latitude, double longitude})? centerOf(int station) =>
      _centers[station];

  int aisleOf(int station) => _byStation[station]!.first.corridorIndex;

  InspectionWalkStep step(int current) {
    final aisle = aisleOf(current);
    final aisleStations = _aisles[aisle]!;
    final index = stations.indexOf(current);
    final next = index + 1 < stations.length
        ? station(stations[index + 1])
        : const <InspectionRouteItem>[];
    return InspectionWalkStep(
      station: current,
      items: station(current),
      aisle: aisle,
      aisleCount: aisleCount,
      stationInAisle: aisleStations.indexOf(current) + 1,
      stationsInAisle: aisleStations.length,
      next: next,
    );
  }

  /// Station trees ordered left side first, which is how they are shown.
  List<InspectionRouteItem> station(int station) =>
      List<InspectionRouteItem>.of(_byStation[station] ?? const [])
        ..sort((a, b) => a.side.index.compareTo(b.side.index));

  /// Relates a GPS fix to [current]. Null when no station has coordinates.
  InspectionWalkFix? locate(
    double latitude,
    double longitude, {
    required int current,
  }) {
    if (_centers.isEmpty) return null;
    int? nearest;
    var nearestMeters = double.infinity;
    for (final entry in _centers.entries) {
      final meters = distanceMeters(
        latitude,
        longitude,
        entry.value.latitude,
        entry.value.longitude,
      );
      if (meters < nearestMeters) {
        nearest = entry.key;
        nearestMeters = meters;
      }
    }
    var outside = double.infinity;
    for (final item in items) {
      if (item.latitude == null || item.longitude == null) continue;
      outside = math.min(
        outside,
        distanceMeters(latitude, longitude, item.latitude!, item.longitude!),
      );
    }
    final center = _centers[current];
    return InspectionWalkFix(
      metersToStation: center == null
          ? nearestMeters
          : distanceMeters(
              latitude, longitude, center.latitude, center.longitude),
      nearestStation: nearest!,
      nearestAisle: aisleOf(nearest),
      metersOutside: outside,
    );
  }

  /// Equirectangular distance; well under 1% error across a farm.
  static double distanceMeters(
    double latitudeA,
    double longitudeA,
    double latitudeB,
    double longitudeB,
  ) {
    const metersPerDegree = 111320.0;
    final x = (longitudeB - longitudeA) *
        math.cos((latitudeA + latitudeB) / 2 * math.pi / 180);
    final y = latitudeB - latitudeA;
    return math.sqrt(x * x + y * y) * metersPerDegree;
  }
}

double _sum(double a, double b) => a + b;
