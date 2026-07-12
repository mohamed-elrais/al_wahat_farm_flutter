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
  });

  final ProjectedFarmMap map;
  final String? selectedSection;
  final String? selectedTreeId;
  final bool showTrees;
  final bool showIrrigation;
  final bool showUtilities;

  static const overviewTreeRadius = 2.7;
  static const sectionTreeRadius = 4.4;
  static const selectedTreeRadius = 6.8;

  @override
  void paint(Canvas canvas, Size size) {
    _drawGround(canvas, size);
    _drawLayout(canvas);
    _drawSections(canvas);
    if (showIrrigation) _drawIrrigation(canvas);
    if (showUtilities) _drawUtilities(canvas);
    _drawLabels(canvas);
    if (showTrees) _drawTrees(canvas);
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
  }

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
      oldDelegate.showUtilities != showUtilities;
}
