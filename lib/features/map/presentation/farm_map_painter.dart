import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/planting_pits/domain/planting_pit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class FarmMapPainter extends CustomPainter {
  const FarmMapPainter({
    required this.map,
    required this.selectedSection,
    required this.selectedTreeId,
    required this.plantingPits,
    required this.selectedPlantingPitId,
    required this.showTrees,
    required this.showPlantingPits,
    required this.showIrrigation,
    required this.showUtilities,
    this.showValves = true,
    this.showFlushValves = false,
    this.showWaterSupply = false,
    this.selectedValveId,
    this.highlightZoneUuids,
    this.highlightSubmains,
    this.highlightLine,
    this.issueMarkers,
    this.issueSemanticLabels,
    this.issueSemanticsTextDirection = TextDirection.ltr,
    this.showIssueMatchesOnly = false,
  });

  final ProjectedFarmMap map;
  final String? selectedSection;
  final String? selectedTreeId;
  final List<ProjectedPlantingPit> plantingPits;
  final String? selectedPlantingPitId;
  final bool showTrees;
  final bool showPlantingPits;
  final bool showIrrigation;
  final bool showUtilities;
  final bool showValves;
  final bool showFlushValves;
  final bool showWaterSupply;

  /// Asset id of the tapped valve (haloed). When [highlightZoneUuids] is set,
  /// the zones' branch lines and trees keep full color while everything else
  /// recedes — a single zone for a zone control valve, every zone of the fed
  /// submain for a mainline isolation valve. [highlightSubmains] keeps that
  /// submain's risers and flush valves lit; [highlightLine] is the pipe fed
  /// through the selected valve, drawn emphasized.
  final String? selectedValveId;
  final Set<String>? highlightZoneUuids;
  final Set<String>? highlightSubmains;
  final List<Offset>? highlightLine;
  final Map<String, FarmMapIssueMarker>? issueMarkers;
  final Map<String, String>? issueSemanticLabels;
  final TextDirection issueSemanticsTextDirection;
  final bool showIssueMatchesOnly;

  static const overviewTreeRadius = 2.7;
  static const sectionTreeRadius = 4.4;
  static const selectedTreeRadius = 6.8;
  static const plantingPitRadius = 4.2;
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
    _drawHighlightLine(canvas);
    if (showFlushValves) _drawFlushValves(canvas);
    if (showTrees) _drawTrees(canvas);
    if (showPlantingPits) _drawPlantingPits(canvas);
    if (showValves) _drawValves(canvas);
  }

  /// The pipe fed through the selected valve, emphasized above the base
  /// network (drawn regardless of layer toggles so the selection always
  /// explains itself).
  void _drawHighlightLine(Canvas canvas) {
    final line = highlightLine;
    if (line == null || line.length < 2) return;
    canvas.drawPoints(
      PointMode.polygon,
      line,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5.4,
    );
    canvas.drawPoints(
      PointMode.polygon,
      line,
      Paint()
        ..color = AppColors.waterMain
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.2,
    );
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
    // Zone-recede mode only applies when highlighted zones are set (a zone
    // valve's own zone, or every zone downstream of an isolation valve).
    final zoneMode = highlightZoneUuids != null;
    for (final branch in map.branchLines) {
      final inZone = zoneMode &&
          branch.line.zoneUuid != null &&
          highlightZoneUuids!.contains(branch.line.zoneUuid);
      final dim = zoneMode ? !inZone : _dimmed(branch.line.section);
      canvas.drawPoints(
        PointMode.polygon,
        branch.points,
        Paint()
          ..color =
              (branch.line.color ?? AppColors.waterSubmain).withOpacity(dim
                  ? 0.12
                  : inZone
                      ? 1
                      : 0.8)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = inZone ? 2.4 : 1.1,
      );
    }
    for (final riser in map.risers) {
      final dim = _networkDimmed(riser.feature.submain, riser.feature.section);
      canvas.drawRect(
        Rect.fromCircle(center: riser.point, radius: riserRadius),
        Paint()..color = AppColors.waterMain.withOpacity(dim ? 0.2 : 1),
      );
    }
  }

  /// Dimming for submain-bound hardware (risers, flush valves): when a
  /// submain is highlighted only its own hardware stays lit; otherwise the
  /// section-scoped dimming applies.
  bool _networkDimmed(String? submain, String? section) {
    final submains = highlightSubmains;
    if (submains != null) {
      return submain == null || !submains.contains(submain);
    }
    return _dimmed(section);
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
      final dim = _networkDimmed(flush.feature.submain, flush.feature.section);
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
      final selected =
          selectedValveId != null && valve.assetId == selectedValveId;
      final dim =
          highlightZoneUuids != null ? !selected : _dimmed(valve.section);
      final zone = valve.isZoneControl;
      final fill =
          zone ? (valve.color ?? AppColors.waterMain) : const Color(0xFF32424E);
      final radius =
          (zone ? valveRadius : valveRadius - 0.7) + (selected ? 2.2 : 0);
      final center = projected.point;
      if (selected) {
        canvas.drawCircle(
          center,
          radius + 3.4,
          Paint()..color = Colors.white,
        );
      }
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
      // Gates are short surveyed line features, not buildings.
      if (utility.type == 'gate') {
        canvas.drawPoints(
          PointMode.polygon,
          utility.points,
          Paint()
            ..color = utility.strokeColor ?? const Color(0xFF263238)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 3,
        );
        continue;
      }
      // Surveyed style colors: water tanks blue, houses/mosque tan, solar
      // arrays indigo, pump room steel, warehouse brown. Fallback keeps the
      // legacy uniform building color for untyped shapes.
      canvas.drawPath(
        utility.path,
        Paint()
          ..color =
              (utility.fillColor ?? const Color(0xFF8B8065)).withOpacity(0.85),
      );
      canvas.drawPath(
        utility.path,
        Paint()
          ..color = utility.strokeColor ?? const Color(0xFFFFF5DF)
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
      final issueMode = issueMarkers != null;
      final marker = issueMarkers?[projected.tree.id];
      final hasIssue = marker != null;
      if (issueMode && showIssueMatchesOnly && !hasIssue && !selected) continue;
      final outsideZone = highlightZoneUuids != null &&
          !highlightZoneUuids!.contains(projected.tree.zoneId);
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
        Paint()
          ..color = outsideZone || (issueMode && !hasIssue)
              ? projected.tree.color.withOpacity(0.15)
              : projected.tree.color,
      );
      if (hasIssue) {
        canvas.drawCircle(
          projected.point,
          radius + 3.2,
          Paint()
            ..color = marker.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = selected ? 2.4 : 1.8,
        );
        _drawIssueBadge(canvas, projected.point, radius, marker);
      }
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

  void _drawIssueBadge(
    Canvas canvas,
    Offset treePoint,
    double treeRadius,
    FarmMapIssueMarker marker,
  ) {
    final badgeRadius = selectedSection == null ? 4.2 : 5.3;
    final center = treePoint.translate(treeRadius + 2.8, -treeRadius - 2.8);
    canvas.drawCircle(center, badgeRadius + 0.9, Paint()..color = Colors.white);
    canvas.drawCircle(center, badgeRadius, Paint()..color = marker.color);
    _text(
      canvas,
      marker.count > 99 ? '99+' : marker.count.toString(),
      center,
      marker.count > 9 ? 5.2 : 6.2,
      FontWeight.w900,
      Colors.white,
    );
  }

  void _drawPlantingPits(Canvas canvas) {
    for (final projected in plantingPits) {
      if (selectedSection != null && projected.sectionCode != selectedSection) {
        continue;
      }
      final selected = projected.pit.id == selectedPlantingPitId;
      final color = switch (projected.pit.status) {
        PlantingPitStatus.planned => const Color(0xFF7E745E),
        PlantingPitStatus.marked => const Color(0xFF4267A8),
        PlantingPitStatus.dug => const Color(0xFF8A5A32),
        PlantingPitStatus.prepared => AppColors.orange,
        PlantingPitStatus.completed => AppColors.green,
        PlantingPitStatus.cancelled => const Color(0xFF9D9A93),
      };
      final radius = selected ? plantingPitRadius + 2.2 : plantingPitRadius;
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
        Paint()
          ..color = color.withOpacity(
            projected.pit.status == PlantingPitStatus.cancelled ? 0.35 : 0.9,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2.4 : 1.7,
      );
      canvas.drawCircle(
        projected.point,
        1.2,
        Paint()..color = color,
      );
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
  SemanticsBuilderCallback get semanticsBuilder => (size) {
        if (!showTrees || issueSemanticLabels == null) {
          return const <CustomPainterSemantics>[];
        }
        return map.trees
            .where((tree) => issueSemanticLabels!.containsKey(tree.tree.id))
            .map(
              (tree) => CustomPainterSemantics(
                rect: Rect.fromCircle(center: tree.point, radius: 18),
                properties: SemanticsProperties(
                  label: issueSemanticLabels![tree.tree.id],
                  textDirection: issueSemanticsTextDirection,
                ),
              ),
            )
            .toList(growable: false);
      };

  @override
  bool shouldRepaint(covariant FarmMapPainter oldDelegate) =>
      oldDelegate.map != map ||
      oldDelegate.selectedSection != selectedSection ||
      oldDelegate.selectedTreeId != selectedTreeId ||
      oldDelegate.plantingPits != plantingPits ||
      oldDelegate.selectedPlantingPitId != selectedPlantingPitId ||
      oldDelegate.showTrees != showTrees ||
      oldDelegate.showPlantingPits != showPlantingPits ||
      oldDelegate.showIrrigation != showIrrigation ||
      oldDelegate.showUtilities != showUtilities ||
      oldDelegate.showValves != showValves ||
      oldDelegate.showFlushValves != showFlushValves ||
      oldDelegate.showWaterSupply != showWaterSupply ||
      oldDelegate.selectedValveId != selectedValveId ||
      oldDelegate.highlightZoneUuids != highlightZoneUuids ||
      oldDelegate.highlightSubmains != highlightSubmains ||
      oldDelegate.highlightLine != highlightLine ||
      oldDelegate.issueMarkers != issueMarkers ||
      oldDelegate.showIssueMatchesOnly != showIssueMatchesOnly;

  @override
  bool shouldRebuildSemantics(covariant FarmMapPainter oldDelegate) =>
      oldDelegate.map != map ||
      oldDelegate.showTrees != showTrees ||
      oldDelegate.issueSemanticsTextDirection != issueSemanticsTextDirection ||
      oldDelegate.issueSemanticLabels != issueSemanticLabels;
}

class FarmMapIssueMarker {
  const FarmMapIssueMarker({required this.count, required this.severity});

  final int count;
  final IssueSeverity severity;

  Color get color => switch (severity) {
        IssueSeverity.low => const Color(0xFFD19A2A),
        IssueSeverity.medium => const Color(0xFFE06C2E),
        IssueSeverity.high => const Color(0xFFC33E32),
        IssueSeverity.urgent => const Color(0xFF7E2033),
      };
}
