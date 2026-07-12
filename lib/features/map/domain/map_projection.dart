import 'dart:math' as math;
import 'dart:ui';

import 'package:al_wahat_farm_flutter/features/map/domain/farm_map_data.dart';

class MapProjection {
  MapProjection(FarmBounds bounds)
      : _bounds = bounds,
        _longitudeCorrection = math.cos(
          ((bounds.minLatitude + bounds.maxLatitude) / 2) * math.pi / 180,
        ) {
    final longitudeSpan =
        (_bounds.maxLongitude - _bounds.minLongitude) * _longitudeCorrection;
    final latitudeSpan = _bounds.maxLatitude - _bounds.minLatitude;
    scale = math.min(
      (canvasSize.width - padding * 2) / longitudeSpan,
      (canvasSize.height - padding * 2) / latitudeSpan,
    );
    final contentWidth = longitudeSpan * scale;
    final contentHeight = latitudeSpan * scale;
    offsetX = (canvasSize.width - contentWidth) / 2;
    offsetY = (canvasSize.height - contentHeight) / 2;
  }

  static const canvasSize = Size(820, 880);
  static const padding = 24.0;

  final FarmBounds _bounds;
  final double _longitudeCorrection;
  late final double scale;
  late final double offsetX;
  late final double offsetY;

  Offset project(GeoCoordinate coordinate) => Offset(
        offsetX +
            (coordinate.longitude - _bounds.minLongitude) *
                _longitudeCorrection *
                scale,
        offsetY + (_bounds.maxLatitude - coordinate.latitude) * scale,
      );

  Rect boundsFor(Iterable<GeoCoordinate> coordinates, {double padding = 45}) {
    final points = coordinates.map(project).toList(growable: false);
    if (points.isEmpty) return Offset.zero & canvasSize;
    final left = points.map((p) => p.dx).reduce(math.min) - padding;
    final top = points.map((p) => p.dy).reduce(math.min) - padding;
    final right = points.map((p) => p.dx).reduce(math.max) + padding;
    final bottom = points.map((p) => p.dy).reduce(math.max) + padding;
    return Rect.fromLTRB(
      left.clamp(0, canvasSize.width).toDouble(),
      top.clamp(0, canvasSize.height).toDouble(),
      right.clamp(0, canvasSize.width).toDouble(),
      bottom.clamp(0, canvasSize.height).toDouble(),
    );
  }
}

class ProjectedTree {
  const ProjectedTree({required this.tree, required this.point});
  final FarmTree tree;
  final Offset point;
}

class ProjectedTreeIndex {
  ProjectedTreeIndex(Iterable<ProjectedTree> trees, {this.cellSize = 32}) {
    for (final tree in trees) {
      _cells.putIfAbsent(_cell(tree.point), () => <ProjectedTree>[]).add(tree);
    }
  }

  final double cellSize;
  final Map<(int, int), List<ProjectedTree>> _cells =
      <(int, int), List<ProjectedTree>>{};

  ProjectedTree? nearest(
    Offset point, {
    required double tolerance,
    String? section,
  }) {
    final radius = (tolerance / cellSize).ceil();
    final origin = _cell(point);
    ProjectedTree? best;
    var bestDistance = tolerance * tolerance;
    for (var x = origin.$1 - radius; x <= origin.$1 + radius; x++) {
      for (var y = origin.$2 - radius; y <= origin.$2 + radius; y++) {
        for (final candidate in _cells[(x, y)] ?? const <ProjectedTree>[]) {
          if (section != null && candidate.tree.section != section) continue;
          final delta = candidate.point - point;
          final distance = delta.distanceSquared;
          if (distance < bestDistance ||
              distance == bestDistance &&
                  best != null &&
                  candidate.tree.code.compareTo(best.tree.code) < 0) {
            bestDistance = distance;
            best = candidate;
          }
        }
      }
    }
    return best;
  }

  (int, int) _cell(Offset point) =>
      ((point.dx / cellSize).floor(), (point.dy / cellSize).floor());
}
