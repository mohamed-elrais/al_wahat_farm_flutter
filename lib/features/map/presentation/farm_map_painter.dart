import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:flutter/material.dart';

class FarmMapPainter extends CustomPainter {
  const FarmMapPainter({
    required this.map,
    required this.selectedSection,
    required this.selectedTreeId,
    required this.showTrees,
    required this.showIrrigation,
    required this.showUtilities,
    this.showValves = true,
    this.showFlushValves = false,
    this.showWaterSupply = false,
  });

  final ProjectedFarmMap map;
  final String? selectedSection;
  final String? selectedTreeId;
  final bool showTrees;
  final bool showIrrigation;
  final bool showUtilities;
  final bool showValves;
  final bool showFlushValves;
  final bool showWaterSupply;

  static const overviewTreeRadius = 2.7;
  static const sectionTreeRadius = 4.4;
  static const selectedTreeRadius = 6.8;
  static const valveRadius = 4.2;
  static const riserRadius = 1.9;
  static const flushValveRadius = 2.6;

  @override
  void paint(Canvas canvas, Size size) {
    _drawGround(canvas, size);
    _drawLayout(canvas);
    _drawSections(canvas);
    if (showIrrigation) _drawIrrigation(canvas);
    if (showWaterSupply) _drawWaterSupply(canvas);
    if (showUtilities) _drawUtilities(canvas);
    _drawLabels(canvas);
    if (showFlushValves) _drawFlushValves(canvas);
    if (showTrees) _drawTrees(canvas);
    if (showValves) _drawValves(canvas);
  }

  void _drawGround(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.sand);
    final grid = Paint()
      ..color = const Color(0x29BDA77C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  void _drawLayout(Canvas canvas) {
    for (final shape in map.layout) {
      final boundary = shape.name == 'Farm Boundary';
      final road = shape.name.contains('Road');
      canvas.drawPath(
        shape.path,
        Paint()
          ..color = boundary
              ? const Color(0x59EEE0BE)
              : road
                  ? AppColors.road
                  : const Color(0xFFD7C49D)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        shape.path,
        Paint()
          ..color = boundary
              ? const Color(0xFF705E3F)
              : road
                  ? const Color(0xFF96815A)
                  : const Color(0xFFA9946E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = boundary ? 2.2 : 1,
      );
    }
  }

  void _drawSections(Canvas canvas) {
    for (final section in map.sections) {
      final dim =
          selectedSection != null && selectedSection != section.section.id;
      final fill = section.section.planted
          ? const Color(0x99DDE2BB)
          : const Color(0xA3F5EBD0);
      canvas.drawPath(
        section.path,
        Paint()..color = dim ? fill.withOpacity(0.17) : fill,
      );
      canvas.drawPath(
        section.path,
        Paint()
          ..color = (section.section.planted
                  ? const Color(0xFF5E734C)
                  : const Color(0xFF7E745E))
              .withOpacity(dim ? 0.25 : 1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  void _drawIrrigation(Canvas canvas) {
    for (final line in map.waterLines) {
      final main = line.name.contains('Mainline');
      final paint = Paint()
        ..color = main ? AppColors.waterMain : AppColors.waterSubmain
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = main ? 3 : 1.5;
      if (main) {
        canvas.drawPoints(PointMode.polygon, line.points, paint);
      } else {
        _drawDashedPolyline(canvas, line.points, paint);
      }
    }
    // Branch lines in their zone color, so each zone's reach is visible.
    for (final branch in map.branchLines) {
      final dim = _dimmed(branch.line.section);
      canvas.drawPoints(
        PointMode.polygon,
        branch.points,
        Paint()
          ..color = (branch.line.color ?? AppColors.waterSubmain)
              .withOpacity(dim ? 0.15 : 0.8)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.1,
      );
    }
    for (final riser in map.risers) {
      final dim = _dimmed(riser.feature.section);
      canvas.drawRect(
        Rect.fromCircle(center: riser.point, radius: riserRadius),
        Paint()..color = AppColors.waterMain.withOpacity(dim ? 0.2 : 1),
      );
    }
  }

  void _drawWaterSupply(Canvas canvas) {
    final linePaint = Paint()
      ..color = const Color(0xFF3E7C96)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    for (final line in map.supplyLines) {
      _drawDashedPolyline(canvas, line.points, linePaint);
    }
    for (final point in map.supplyPoints) {
      canvas.drawCircle(
        point.point,
        3.4,
        Paint()..color = const Color(0xFF2E5E73),
      );
      canvas.drawCircle(
        point.point,
        3.4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _drawFlushValves(Canvas canvas) {
    for (final flush in map.flushValves) {
      final dim = _dimmed(flush.feature.section);
      final paint = Paint()
        ..color = const Color(0xFF8A6D4F).withOpacity(dim ? 0.2 : 0.95);
      final center = flush.point;
      final path = Path()
        ..moveTo(center.dx, center.dy - flushValveRadius)
        ..lineTo(center.dx + flushValveRadius, center.dy + flushValveRadius)
        ..lineTo(center.dx - flushValveRadius, center.dy + flushValveRadius)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawValves(Canvas canvas) {
    for (final projected in map.valves) {
      final valve = projected.valve;
      final dim = _dimmed(valve.section);
      final zone = valve.isZoneControl;
      final fill =
          zone ? (valve.color ?? AppColors.waterMain) : const Color(0xFF32424E);
      final radius = zone ? valveRadius : valveRadius - 0.7;
      final center = projected.point;
      final diamond = Path()
        ..moveTo(center.dx, center.dy - radius)
        ..lineTo(center.dx + radius, center.dy)
        ..lineTo(center.dx, center.dy + radius)
        ..lineTo(center.dx - radius, center.dy)
        ..close();
      canvas.drawPath(
        diamond,
        Paint()..color = fill.withOpacity(dim ? 0.2 : 1),
      );
      canvas.drawPath(
        diamond,
        Paint()
          ..color = Colors.white.withOpacity(dim ? 0.25 : 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  /// Section-scoped dimming for network features (features with no section,
  /// like mainline hardware, stay visible when a section is selected).
  bool _dimmed(String? section) =>
      selectedSection != null && section != null && section != selectedSection;

  void _drawUtilities(Canvas canvas) {
    for (final utility in map.utilities) {
      canvas.drawPath(utility.path, Paint()..color = const Color(0xFF8B8065));
      canvas.drawPath(
        utility.path,
        Paint()
          ..color = const Color(0xFFFFF5DF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  void _drawLabels(Canvas canvas) {
    for (final section in map.sections) {
      final dim =
          selectedSection != null && selectedSection != section.section.id;
      if (dim) continue;
      final rect = Rect.fromCenter(
        center: section.label,
        width: 44,
        height: 34,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        Paint()..color = const Color(0xFFFFFAF0),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        Paint()
          ..color = const Color(0xFFBAA98A)
          ..style = PaintingStyle.stroke,
      );
      _text(
        canvas,
        section.section.id,
        section.label.translate(0, -7),
        13,
        FontWeight.w900,
        AppColors.green,
      );
      _text(
        canvas,
        section.section.treeCount == 0 ? '—' : '${section.section.treeCount}',
        section.label.translate(0, 8),
        7,
        FontWeight.w700,
        const Color(0xFF897E6B),
      );
    }
  }

  void _drawTrees(Canvas canvas) {
    for (final projected in map.trees) {
      if (selectedSection != null &&
          projected.tree.section != selectedSection) {
        continue;
      }
      final selected = projected.tree.id == selectedTreeId;
      final radius = selected
          ? selectedTreeRadius
          : selectedSection == null
              ? overviewTreeRadius
              : sectionTreeRadius;
      if (selected) {
        canvas.drawCircle(
          projected.point,
          radius + 2.5,
          Paint()..color = Colors.white,
        );
      }
      canvas.drawCircle(
        projected.point,
        radius,
        Paint()..color = projected.tree.color,
      );
      if (!selected) {
        canvas.drawCircle(
          projected.point,
          radius,
          Paint()
            ..color = Colors.white.withOpacity(0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.75,
        );
      }
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    FontWeight weight,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: size, fontWeight: weight, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _drawDashedPolyline(Canvas canvas, List<Offset> points, Paint paint) {
    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final vector = end - start;
      final length = vector.distance;
      if (length == 0) continue;
      final direction = vector / length;
      for (double distance = 0; distance < length; distance += 5) {
        canvas.drawLine(
          start + direction * distance,
          start + direction * math.min(distance + 3, length),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant FarmMapPainter oldDelegate) =>
      oldDelegate.map != map ||
      oldDelegate.selectedSection != selectedSection ||
      oldDelegate.selectedTreeId != selectedTreeId ||
      oldDelegate.showTrees != showTrees ||
      oldDelegate.showIrrigation != showIrrigation ||
      oldDelegate.showUtilities != showUtilities ||
      oldDelegate.showValves != showValves ||
      oldDelegate.showFlushValves != showFlushValves ||
      oldDelegate.showWaterSupply != showWaterSupply;
}
