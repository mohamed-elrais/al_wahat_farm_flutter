import 'dart:ui';

import 'package:al_wahat_farm_flutter/features/map/domain/farm_map_data.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/map_projection.dart';

class ProjectedShape {
  const ProjectedShape({
    required this.name,
    required this.path,
    required this.points,
  });
  final String name;
  final Path path;
  final List<Offset> points;
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

class ProjectedFarmMap {
  ProjectedFarmMap(this.data) : projection = MapProjection(data.bounds) {
    layout = data.layout.map(_shape).toList(growable: false);
    utilities = data.utilities.map(_shape).toList(growable: false);
    waterLines = data.waterLines.map(_shape).toList(growable: false);
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
    );
  }
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
