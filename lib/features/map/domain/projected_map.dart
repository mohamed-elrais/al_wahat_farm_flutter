import 'dart:ui';

import 'package:al_wahat_farm_flutter/features/map/domain/farm_map_data.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/map_projection.dart';

class ProjectedShape {
  const ProjectedShape({
    required this.name,
    required this.path,
    required this.points,
    this.type,
    this.fillColor,
    this.strokeColor,
  });
  final String name;
  final Path path;
  final List<Offset> points;
  final String? type;
  final Color? fillColor;
  final Color? strokeColor;
}

class ProjectedSection {
  const ProjectedSection({
    required this.section,
    required this.path,
    required this.label,
    required this.bounds,
  });
  final FarmSectionGeometry section;
  final Path path;
  final Offset label;
  final Rect bounds;
}

class ProjectedBranchLine {
  const ProjectedBranchLine({required this.line, required this.points});
  final BranchLine line;
  final List<Offset> points;
}

class ProjectedValve {
  const ProjectedValve({
    required this.valve,
    required this.point,
    this.downstreamPoints,
  });
  final NetworkValve valve;
  final Offset point;

  /// Isolation valves only: the projected pipe geometry beyond the valve.
  final List<Offset>? downstreamPoints;
}

class ProjectedNetworkPoint {
  const ProjectedNetworkPoint({required this.feature, required this.point});
  final NetworkPoint feature;
  final Offset point;
}

class ProjectedSupplyLine {
  const ProjectedSupplyLine({required this.line, required this.points});
  final SupplyLine line;
  final List<Offset> points;
}

class ProjectedFarmMap {
  ProjectedFarmMap(this.data) : projection = MapProjection(data.bounds) {
    layout = data.layout.map(_shape).toList(growable: false);
    utilities = data.utilities.map(_shape).toList(growable: false);
    waterLines = data.waterLines.map(_shape).toList(growable: false);
    branchLines = data.branchLines
        .map(
          (line) => ProjectedBranchLine(
            line: line,
            points: line.coordinates
                .map(projection.project)
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
    valves = data.valves
        .map(
          (valve) => ProjectedValve(
            valve: valve,
            point: projection.project(
              GeoCoordinate(
                longitude: valve.longitude,
                latitude: valve.latitude,
              ),
            ),
            downstreamPoints: valve.downstreamLine
                ?.map(projection.project)
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
    flushValves = data.flushValves.map(_point).toList(growable: false);
    risers = data.risers.map(_point).toList(growable: false);
    supplyPoints = data.waterSupply.points.map(_point).toList(growable: false);
    supplyLines = data.waterSupply.lines
        .map(
          (line) => ProjectedSupplyLine(
            line: line,
            points: line.coordinates
                .map(projection.project)
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
    sections = data.sections.map((section) {
      final points =
          section.polygon.map(projection.project).toList(growable: false);
      return ProjectedSection(
        section: section,
        path: _closedPath(points),
        label: _center(points),
        bounds: projection.boundsFor(section.polygon),
      );
    }).toList(growable: false);
    trees = data.trees
        .map(
          (tree) => ProjectedTree(
            tree: tree,
            point: projection.project(
              GeoCoordinate(longitude: tree.longitude, latitude: tree.latitude),
            ),
          ),
        )
        .toList(growable: false);
    treeIndex = ProjectedTreeIndex(trees);
  }

  final FarmMapData data;
  final MapProjection projection;
  late final List<ProjectedShape> layout;
  late final List<ProjectedShape> utilities;
  late final List<ProjectedShape> waterLines;
  late final List<ProjectedBranchLine> branchLines;
  late final List<ProjectedValve> valves;
  late final List<ProjectedNetworkPoint> flushValves;
  late final List<ProjectedNetworkPoint> risers;
  late final List<ProjectedNetworkPoint> supplyPoints;
  late final List<ProjectedSupplyLine> supplyLines;
  late final List<ProjectedSection> sections;
  late final List<ProjectedTree> trees;
  late final ProjectedTreeIndex treeIndex;

  ProjectedShape _shape(GeoShape shape) {
    final points =
        shape.coordinates.map(projection.project).toList(growable: false);
    return ProjectedShape(
      name: shape.name,
      path: _closedPath(points),
      points: points,
      type: shape.type,
      fillColor: shape.fillColor,
      strokeColor: shape.strokeColor,
    );
  }

  ProjectedNetworkPoint _point(NetworkPoint feature) => ProjectedNetworkPoint(
        feature: feature,
        point: projection.project(
          GeoCoordinate(
            longitude: feature.longitude,
            latitude: feature.latitude,
          ),
        ),
      );
}

Path _closedPath(List<Offset> points) {
  final path = Path();
  if (points.isEmpty) return path;
  path.moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  path.close();
  return path;
}

Offset _center(List<Offset> points) {
  if (points.isEmpty) return Offset.zero;
  return points.fold<Offset>(Offset.zero, (sum, point) => sum + point) /
      points.length.toDouble();
}
