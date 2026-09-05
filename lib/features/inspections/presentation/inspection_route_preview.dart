import 'dart:math' as math;

import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route.dart';
import 'package:flutter/material.dart';

/// A coordinate-based preview of the immutable route sent to the backend.
///
/// Geometry deliberately does not follow [TextDirection]: physical left and
/// right on the farm must stay unchanged when the surrounding UI is Arabic.
class InspectionRoutePreviewMap extends StatelessWidget {
  const InspectionRoutePreviewMap({
    required this.route,
    required this.semanticsLabel,
    super.key,
  });

  final InspectionRoute route;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
        key: const Key('inspection-route-preview-map'),
        container: true,
        image: true,
        label: semanticsLabel,
        child: ExcludeSemantics(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxWidth >= 600 ? 360.0 : 260.0;
              return SizedBox(
                width: double.infinity,
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: CustomPaint(
                      key: const Key('inspection-route-preview-painter'),
                      painter: _InspectionRoutePainter(route),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
}

class _InspectionRoutePainter extends CustomPainter {
  const _InspectionRoutePainter(this.route);

  final InspectionRoute route;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 24.0;
    final plotted = route.items
        .where((item) => item.latitude != null && item.longitude != null)
        .toList(growable: false);
    if (plotted.isEmpty) return;

    final minLat = plotted.map((item) => item.latitude!).reduce(math.min);
    final maxLat = plotted.map((item) => item.latitude!).reduce(math.max);
    final minLng = plotted.map((item) => item.longitude!).reduce(math.min);
    final maxLng = plotted.map((item) => item.longitude!).reduce(math.max);
    final latRange = math.max(maxLat - minLat, 0.000001);
    final lngRange = math.max(maxLng - minLng, 0.000001);

    Offset point(InspectionRouteItem item) => Offset(
          inset +
              ((item.longitude! - minLng) / lngRange) *
                  math.max(1, size.width - inset * 2),
          size.height -
              inset -
              ((item.latitude! - minLat) / latRange) *
                  math.max(1, size.height - inset * 2),
        );

    final rowPaint = Paint()
      ..color = AppColors.green.withOpacity(0.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final pathPaint = Paint()
      ..color = AppColors.orange
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final laneGroups = <String, List<InspectionRouteItem>>{};
    for (final item in plotted) {
      laneGroups
          .putIfAbsent('${item.corridorIndex}:${item.side.name}', () => [])
          .add(item);
    }
    for (final lane in laneGroups.values) {
      lane.sort((a, b) => a.stationIndex.compareTo(b.stationIndex));
      final path = Path()..moveTo(point(lane.first).dx, point(lane.first).dy);
      for (final item in lane.skip(1)) {
        final offset = point(item);
        path.lineTo(offset.dx, offset.dy);
      }
      canvas.drawPath(path, rowPaint);
    }

    final corridors = <int, List<int>>{};
    for (final item in plotted) {
      corridors
          .putIfAbsent(item.corridorIndex, () => <int>[])
          .add(item.stationIndex);
    }
    final orderedCorridors = corridors.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));
    Offset? previousCorridorEnd;
    for (final entry in orderedCorridors) {
      final stations = entry.value.toSet().toList()..sort();
      final centers = stations.map((station) {
        final items = plotted
            .where((item) =>
                item.corridorIndex == entry.key && item.stationIndex == station)
            .toList(growable: false);
        final points = items.map(point).toList(growable: false);
        return Offset(
          points.map((value) => value.dx).reduce((a, b) => a + b) /
              points.length,
          points.map((value) => value.dy).reduce((a, b) => a + b) /
              points.length,
        );
      }).toList(growable: false);
      if (previousCorridorEnd != null && centers.isNotEmpty) {
        _drawDashedLine(
          canvas,
          previousCorridorEnd,
          centers.first,
          pathPaint,
        );
      }
      for (var index = 0; index < centers.length - 1; index++) {
        if (index == centers.length - 2) {
          _drawArrow(canvas, centers[index], centers[index + 1], pathPaint);
        } else {
          _drawDashedLine(
            canvas,
            centers[index],
            centers[index + 1],
            pathPaint,
          );
        }
      }
      if (centers.isNotEmpty) previousCorridorEnd = centers.last;
    }

    final treePaint = Paint()..color = AppColors.green;
    for (final item in plotted) {
      canvas.drawCircle(point(item), item.sequenceIndex == 1 ? 6 : 3.2,
          item.sequenceIndex == 1 ? pathPaint : treePaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance == 0) return;
    final direction = delta / distance;
    for (var traveled = 0.0; traveled < distance; traveled += 12) {
      canvas.drawLine(
        start + direction * traveled,
        start + direction * math.min(traveled + 7, distance),
        paint,
      );
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    _drawDashedLine(canvas, from, to, paint);
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const arrow = 9.0;
    canvas.drawLine(
      to,
      to - Offset(math.cos(angle - 0.55), math.sin(angle - 0.55)) * arrow,
      paint,
    );
    canvas.drawLine(
      to,
      to - Offset(math.cos(angle + 0.55), math.sin(angle + 0.55)) * arrow,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _InspectionRoutePainter oldDelegate) =>
      oldDelegate.route != route;
}
