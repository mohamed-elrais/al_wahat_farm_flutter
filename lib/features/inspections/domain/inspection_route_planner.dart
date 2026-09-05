import 'dart:math' as math;

import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route.dart';

/// Builds a deterministic walking snapshot from live tree coordinates.
///
/// `rowNumber` is useful for finding trees that share a physical row, but it is
/// never used as identity: repeated row numbers are split by large coordinate
/// gaps. Tree code and tree id remain the stable identities.
class InspectionRoutePlanner {
  const InspectionRoutePlanner({
    this.routeVersion = 2,
    this.blockGapMultiplier = 3.25,
  });

  final int routeVersion;
  final double blockGapMultiplier;

  InspectionRoute plan({
    required FarmSection section,
    required Iterable<FarmTreeRecord> trees,
  }) {
    final sectionTrees = trees
        .where((tree) => tree.sectionId == section.id && tree.isActive)
        .toList(growable: false);
    if (sectionTrees.isEmpty) {
      throw const InspectionRouteException(
        'The section has no active trees to inspect.',
      );
    }
    if (sectionTrees.any(
      (tree) => tree.latitude == null || tree.longitude == null,
    )) {
      throw const InspectionRouteException(
        'Every inspected tree needs map coordinates.',
      );
    }
    if (sectionTrees.any((tree) => tree.rowNumber == null)) {
      throw const InspectionRouteException(
        'Every inspected tree needs a source row number.',
      );
    }

    final numberedTrees = sectionTrees
        .map((tree) => (tree: tree, number: _treeCodeNumber(tree.treeCode)))
        .where((entry) => entry.number != null)
        .toList(growable: false);
    final numberOne = numberedTrees
        .where((entry) => entry.number == 1)
        .map((entry) => entry.tree)
        .toList(growable: false);
    if (numberOne.length > 1 || numberedTrees.isEmpty) {
      throw InspectionRouteException(
        'Section ${section.code} needs unique numbered tree codes.',
      );
    }
    final minimumNumber =
        numberedTrees.map((entry) => entry.number!).reduce(math.min);
    final fallback = numberedTrees
        .where((entry) => entry.number == minimumNumber)
        .map((entry) => entry.tree)
        .toList(growable: false);
    if (numberOne.isEmpty && fallback.length != 1) {
      throw InspectionRouteException(
        'Section ${section.code} needs one unambiguous starting tree.',
      );
    }
    // Most sections begin at 001. A partially planted section such as G may
    // begin later, so anchor it to its lowest existing tree number—the closest
    // planted position to the approved tree-number-1 starting edge.
    final anchor = numberOne.isNotEmpty ? numberOne.single : fallback.single;
    final points = _project(sectionTrees);
    var axis = _dominantRowAxis(points);
    final gapThreshold = _blockGapThreshold(points, axis);
    var lanes = _splitPhysicalLanes(points, axis, gapThreshold);
    final anchorLane = lanes.singleWhere(
      (lane) => lane.points.any((point) => point.tree.id == anchor.id),
    );

    final anchorProjection = anchorLane.points
        .singleWhere((point) => point.tree.id == anchor.id)
        .dot(axis);
    final laneProjections = anchorLane.points
        .map((point) => point.dot(axis))
        .toList(growable: false)
      ..sort();
    final distanceToStart = (anchorProjection - laneProjections.first).abs();
    final distanceToEnd = (laneProjections.last - anchorProjection).abs();
    if (distanceToEnd < distanceToStart) axis = -axis;

    // Start with the 001 lane, pair it with the nearest physical lane, then
    // continue to the nearest remaining block. This avoids pairing duplicate
    // row labels that sit in distant physical blocks.
    lanes = _walkingLaneOrder(lanes, anchorLane);

    final routeItems = <InspectionRouteItem>[];
    var sequence = 1;
    var station = 1;
    for (var laneIndex = 0; laneIndex < lanes.length; laneIndex += 2) {
      final corridor = laneIndex ~/ 2 + 1;
      final firstLane = lanes[laneIndex];
      final secondLane =
          laneIndex + 1 < lanes.length ? lanes[laneIndex + 1] : null;
      final direction = corridor.isOdd ? axis : -axis;
      final first = _sorted(firstLane.points, direction);
      final second = secondLane == null
          ? const <_ProjectedTree>[]
          : _sorted(secondLane.points, direction);
      final count = math.max(first.length, second.length);

      final firstSide = secondLane == null
          ? InspectionRouteSide.single
          : _sideForLane(firstLane, secondLane, direction);
      final secondSide = secondLane == null
          ? null
          : (firstSide == InspectionRouteSide.left
              ? InspectionRouteSide.right
              : InspectionRouteSide.left);

      for (var index = 0; index < count; index++) {
        final stationTrees = <({
          _ProjectedTree point,
          InspectionRouteSide side,
        })>[];
        if (index < first.length) {
          stationTrees.add((point: first[index], side: firstSide));
        }
        if (index < second.length) {
          stationTrees.add((point: second[index], side: secondSide!));
        }
        if (station == 1) {
          stationTrees.sort(
            (a, b) => a.point.tree.id == anchor.id
                ? -1
                : b.point.tree.id == anchor.id
                    ? 1
                    : a.side.index.compareTo(b.side.index),
          );
        } else {
          stationTrees.sort((a, b) => a.side.index.compareTo(b.side.index));
        }
        for (final entry in stationTrees) {
          routeItems.add(
            entry.point.tree.toInspectionRouteItem(
              sequenceIndex: sequence++,
              corridorIndex: corridor,
              stationIndex: station,
              side: entry.side,
            ),
          );
        }
        station++;
      }
    }

    if (routeItems.first.treeId != anchor.id ||
        routeItems.map((item) => item.treeId).toSet().length !=
            sectionTrees.length) {
      throw const InspectionRouteException(
        'The generated route did not cover the section safely.',
      );
    }
    return InspectionRoute(
      sectionId: section.id,
      startingTreeId: anchor.id,
      routeVersion: routeVersion,
      items: routeItems,
    );
  }

  List<_ProjectedTree> _project(List<FarmTreeRecord> trees) {
    final latitudeOrigin = trees
            .map((tree) => tree.latitude!)
            .reduce((left, right) => left + right) /
        trees.length;
    final longitudeOrigin = trees
            .map((tree) => tree.longitude!)
            .reduce((left, right) => left + right) /
        trees.length;
    final longitudeScale = math.cos(latitudeOrigin * math.pi / 180);
    return trees
        .map(
          (tree) => _ProjectedTree(
            tree: tree,
            x: (tree.longitude! - longitudeOrigin) * longitudeScale,
            y: tree.latitude! - latitudeOrigin,
          ),
        )
        .toList(growable: false);
  }

  _Vector _dominantRowAxis(List<_ProjectedTree> points) {
    var doubledX = 0.0;
    var doubledY = 0.0;
    for (final point in points) {
      _ProjectedTree? nearest;
      var nearestDistance = double.infinity;
      for (final candidate in points) {
        if (identical(point, candidate) ||
            candidate.tree.rowNumber != point.tree.rowNumber) {
          continue;
        }
        final distance = point.distanceTo(candidate);
        if (distance < nearestDistance) {
          nearest = candidate;
          nearestDistance = distance;
        }
      }
      if (nearest == null || nearestDistance == 0) continue;
      final angle = math.atan2(nearest.y - point.y, nearest.x - point.x);
      doubledX += math.cos(2 * angle);
      doubledY += math.sin(2 * angle);
    }
    if (doubledX == 0 && doubledY == 0) {
      throw const InspectionRouteException(
        'Tree coordinates cannot establish a physical row direction.',
      );
    }
    final angle = math.atan2(doubledY, doubledX) / 2;
    return _Vector(math.cos(angle), math.sin(angle));
  }

  double _blockGapThreshold(
    List<_ProjectedTree> points,
    _Vector axis,
  ) {
    final byRow = _groupBySourceRow(points);
    final consecutiveGaps = <double>[];
    for (final rowPoints in byRow.values) {
      final sorted = _sorted(rowPoints, axis);
      for (var index = 1; index < sorted.length; index++) {
        final gap =
            (sorted[index].dot(axis) - sorted[index - 1].dot(axis)).abs();
        if (gap > 1e-12) consecutiveGaps.add(gap);
      }
    }
    if (consecutiveGaps.isEmpty) {
      throw const InspectionRouteException(
        'Tree spacing cannot establish physical row blocks.',
      );
    }
    consecutiveGaps.sort();
    final median = consecutiveGaps[consecutiveGaps.length ~/ 2];
    return median * blockGapMultiplier;
  }

  List<_Lane> _splitPhysicalLanes(
    List<_ProjectedTree> points,
    _Vector axis,
    double gapThreshold,
  ) {
    final byRow = _groupBySourceRow(points);
    final normal = _Vector(-axis.y, axis.x);
    final lanes = <_Lane>[];
    for (final rowPoints in byRow.values) {
      // Imported row numbers can restart in another physical block. Those
      // blocks may overlap along the row direction (Section A does), so first
      // separate them across the rows, then handle gaps along each row.
      final crossRowBlocks = _splitAtProjectionGaps(
        rowPoints,
        normal,
        gapThreshold,
      );
      for (final block in crossRowBlocks) {
        for (final lane in _splitAtProjectionGaps(
          block,
          axis,
          gapThreshold,
        )) {
          lanes.add(_Lane(lane));
        }
      }
    }
    return lanes;
  }

  Map<int, List<_ProjectedTree>> _groupBySourceRow(
    List<_ProjectedTree> points,
  ) {
    final byRow = <int, List<_ProjectedTree>>{};
    for (final point in points) {
      byRow
          .putIfAbsent(point.tree.rowNumber!, () => <_ProjectedTree>[])
          .add(point);
    }
    return byRow;
  }

  List<List<_ProjectedTree>> _splitAtProjectionGaps(
    List<_ProjectedTree> points,
    _Vector direction,
    double gapThreshold,
  ) {
    final sorted = _sorted(points, direction);
    final groups = <List<_ProjectedTree>>[];
    var current = <_ProjectedTree>[sorted.first];
    for (var index = 1; index < sorted.length; index++) {
      final previous = sorted[index - 1].dot(direction);
      final next = sorted[index].dot(direction);
      if ((next - previous).abs() > gapThreshold) {
        groups.add(current);
        current = <_ProjectedTree>[];
      }
      current.add(sorted[index]);
    }
    groups.add(current);
    return groups;
  }

  List<_Lane> _walkingLaneOrder(List<_Lane> lanes, _Lane anchorLane) {
    final remaining = lanes.where((lane) => lane != anchorLane).toList();
    final ordered = <_Lane>[anchorLane];
    var reference = anchorLane.centroid;
    while (remaining.isNotEmpty) {
      remaining.sort(
        (left, right) => left.centroid
            .distanceTo(reference)
            .compareTo(right.centroid.distanceTo(reference)),
      );
      final next = remaining.removeAt(0);
      ordered.add(next);
      if (ordered.length.isEven) {
        reference = _Point(
          (ordered[ordered.length - 2].centroid.x + next.centroid.x) / 2,
          (ordered[ordered.length - 2].centroid.y + next.centroid.y) / 2,
        );
      } else {
        reference = next.centroid;
      }
    }
    return ordered;
  }

  List<_ProjectedTree> _sorted(
    Iterable<_ProjectedTree> points,
    _Vector direction,
  ) =>
      points.toList(growable: false)
        ..sort((left, right) =>
            left.dot(direction).compareTo(right.dot(direction)));

  InspectionRouteSide _sideForLane(
    _Lane first,
    _Lane second,
    _Vector direction,
  ) {
    final pathMidpoint = _Point(
      (first.centroid.x + second.centroid.x) / 2,
      (first.centroid.y + second.centroid.y) / 2,
    );
    final offset = _Vector(
      first.centroid.x - pathMidpoint.x,
      first.centroid.y - pathMidpoint.y,
    );
    final cross = direction.x * offset.y - direction.y * offset.x;
    return cross >= 0 ? InspectionRouteSide.left : InspectionRouteSide.right;
  }
}

int? _treeCodeNumber(String code) {
  final match = RegExp(r'(?:^|-)(\d+)$').firstMatch(code);
  return match == null ? null : int.tryParse(match.group(1)!);
}

class _Vector {
  const _Vector(this.x, this.y);

  final double x;
  final double y;

  _Vector operator -() => _Vector(-x, -y);
}

class _Point {
  const _Point(this.x, this.y);

  final double x;
  final double y;

  double distanceTo(_Point other) =>
      math.sqrt(math.pow(x - other.x, 2) + math.pow(y - other.y, 2));
}

class _ProjectedTree extends _Point {
  const _ProjectedTree({
    required this.tree,
    required double x,
    required double y,
  }) : super(x, y);

  final FarmTreeRecord tree;

  double dot(_Vector vector) => x * vector.x + y * vector.y;
}

class _Lane {
  _Lane(List<_ProjectedTree> points)
      : points = List<_ProjectedTree>.unmodifiable(points),
        centroid = _Point(
          points.map((point) => point.x).reduce((a, b) => a + b) /
              points.length,
          points.map((point) => point.y).reduce((a, b) => a + b) /
              points.length,
        );

  final List<_ProjectedTree> points;
  final _Point centroid;
}
