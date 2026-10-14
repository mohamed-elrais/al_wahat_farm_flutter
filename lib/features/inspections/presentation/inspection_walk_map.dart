import 'dart:math' as math;

import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/location/location_service.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_walk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum InspectionTreeMark { pending, done, flagged }

/// The section's trees and walking route, north up, with inspected trees,
/// the current station and (when on) the inspector's GPS position.
///
/// Geometry never follows [TextDirection]: it is locked to LTR like the farm
/// map, so physical left and right stay put in Arabic.
class InspectionWalkMap extends StatelessWidget {
  const InspectionWalkMap({
    required this.walk,
    required this.marks,
    required this.currentStation,
    required this.semanticsLabel,
    this.fix,
    this.onTapStation,
    super.key,
  });

  final InspectionWalk walk;

  /// Inspection state per tree id; trees not listed are pending.
  final Map<String, InspectionTreeMark> marks;
  final int currentStation;
  final String semanticsLabel;
  final LocationFix? fix;

  /// When set, taps pick the station of the nearest tree.
  final ValueChanged<int>? onTapStation;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        image: true,
        label: semanticsLabel,
        child: ExcludeSemantics(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                final painter = CustomPaint(
                  size: size,
                  painter: _WalkPainter(
                    walk: walk,
                    marks: marks,
                    currentStation: currentStation,
                    fix: fix,
                  ),
                );
                final onTapStation = this.onTapStation;
                if (onTapStation == null) return painter;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final station = _WalkGeometry(walk, size).stationAt(
                      details.localPosition,
                      tolerance: 26 / _viewerScale(context),
                    );
                    if (station != null) onTapStation(station);
                  },
                  child: painter,
                );
              },
            ),
          ),
        ),
      );

  static double _viewerScale(BuildContext context) =>
      context
          .findAncestorWidgetOfExactType<InteractiveViewer>()
          ?.transformationController
          ?.value
          .getMaxScaleOnAxis() ??
      1;
}

/// Projects the route to a canvas of [size] with one uniform scale, so
/// distances and the GPS accuracy circle stay true.
class _WalkGeometry {
  factory _WalkGeometry(InspectionWalk walk, Size size) {
    final located = walk.items
        .where((item) => item.latitude != null && item.longitude != null)
        .toList(growable: false);
    if (located.isEmpty) {
      return _WalkGeometry._(walk, located, 0, 0, 1, 1, Offset.zero, size);
    }
    final latitude0 =
        located.map((item) => item.latitude!).reduce((a, b) => a + b) /
            located.length;
    final longitude0 =
        located.map((item) => item.longitude!).reduce((a, b) => a + b) /
            located.length;
    final cosine = math.cos(latitude0 * math.pi / 180);
    final points = located
        .map((item) => _meters(
            item.latitude!, item.longitude!, latitude0, longitude0, cosine))
        .toList(growable: false);
    final minX = points.map((p) => p.dx).reduce(math.min);
    final maxX = points.map((p) => p.dx).reduce(math.max);
    final minY = points.map((p) => p.dy).reduce(math.min);
    final maxY = points.map((p) => p.dy).reduce(math.max);
    const padding = 16.0;
    final width = math.max(maxX - minX, 1.0);
    final height = math.max(maxY - minY, 1.0);
    final scale = math.max(
      0.01,
      math.min(
        (size.width - padding * 2) / width,
        (size.height - padding * 2) / height,
      ),
    );
    final origin = Offset(
      (size.width - width * scale) / 2 - minX * scale,
      (size.height + height * scale) / 2 + minY * scale,
    );
    return _WalkGeometry._(
        walk, located, latitude0, longitude0, cosine, scale, origin, size);
  }

  const _WalkGeometry._(
    this.walk,
    this.located,
    this.latitude0,
    this.longitude0,
    this.cosine,
    this.scale,
    this.origin,
    this.size,
  );

  final InspectionWalk walk;
  final List<InspectionRouteItem> located;
  final double latitude0;
  final double longitude0;
  final double cosine;

  /// Pixels per metre.
  final double scale;
  final Offset origin;
  final Size size;

  static Offset _meters(
    double latitude,
    double longitude,
    double latitude0,
    double longitude0,
    double cosine,
  ) =>
      Offset(
        (longitude - longitude0) * cosine * 111320,
        (latitude - latitude0) * 111320,
      );

  Offset project(double latitude, double longitude) {
    final meters = _meters(latitude, longitude, latitude0, longitude0, cosine);
    return Offset(
      origin.dx + meters.dx * scale,
      origin.dy - meters.dy * scale,
    );
  }

  Offset? item(InspectionRouteItem item) =>
      item.latitude == null || item.longitude == null
          ? null
          : project(item.latitude!, item.longitude!);

  Offset? stationCenter(int station) {
    final center = walk.centerOf(station);
    return center == null ? null : project(center.latitude, center.longitude);
  }

  int? stationAt(Offset point, {required double tolerance}) {
    InspectionRouteItem? nearest;
    var best = tolerance;
    for (final item in located) {
      final distance = (this.item(item)! - point).distance;
      if (distance <= best) {
        best = distance;
        nearest = item;
      }
    }
    return nearest?.stationIndex;
  }
}

class _WalkPainter extends CustomPainter {
  const _WalkPainter({
    required this.walk,
    required this.marks,
    required this.currentStation,
    required this.fix,
  });

  final InspectionWalk walk;
  final Map<String, InspectionTreeMark> marks;
  final int currentStation;
  final LocationFix? fix;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = _WalkGeometry(walk, size);
    if (geometry.located.isEmpty) return;

    // Tree rows: one faint line per side of each aisle.
    final rows = <String, List<InspectionRouteItem>>{};
    for (final item in geometry.located) {
      rows
          .putIfAbsent('${item.corridorIndex}:${item.side.name}', () => [])
          .add(item);
    }
    final rowPaint = Paint()
      ..color = AppColors.green.withOpacity(0.16)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final row in rows.values) {
      row.sort((a, b) => a.stationIndex.compareTo(b.stationIndex));
      final path = Path();
      for (var index = 0; index < row.length; index++) {
        final point = geometry.item(row[index])!;
        index == 0
            ? path.moveTo(point.dx, point.dy)
            : path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, rowPaint);
    }

    // Walking path: walked part solid, the rest dashed.
    final centers = <int, Offset>{
      for (final station in walk.stations)
        if (geometry.stationCenter(station) case final center?) station: center,
    };
    final walked = Paint()
      ..color = AppColors.green.withOpacity(0.5)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final ahead = Paint()
      ..color = AppColors.orange.withOpacity(0.45)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    Offset? previous;
    for (final station in walk.stations) {
      final center = centers[station];
      if (center == null) continue;
      if (previous != null) {
        if (station <= currentStation) {
          canvas.drawLine(previous, center, walked);
        } else if (station > currentStation + 1) {
          _dashed(canvas, previous, center, ahead);
        }
      }
      previous = center;
    }

    // Trees.
    final spacing = 8 * geometry.scale;
    final radius = (spacing * 0.28).clamp(1.8, 7.0);
    final pending = Paint()..color = AppColors.muted.withOpacity(0.4);
    final done = Paint()..color = AppColors.green;
    final flagged = Paint()..color = AppColors.issue;
    for (final item in geometry.located) {
      if (item.stationIndex == currentStation) continue;
      final paint = switch (marks[item.treeId]) {
        InspectionTreeMark.done => done,
        InspectionTreeMark.flagged => flagged,
        _ => pending,
      };
      canvas.drawCircle(geometry.item(item)!, radius, paint);
    }

    // Arrow from the current station to the next one.
    final current = centers[currentStation];
    final index = walk.stations.indexOf(currentStation);
    if (current != null && index >= 0 && index + 1 < walk.stations.length) {
      final next = centers[walk.stations[index + 1]];
      if (next != null) _arrow(canvas, current, next);
    }

    // Current station on top.
    final currentFill = Paint()..color = AppColors.orange;
    final ring = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final item in walk.station(currentStation)) {
      final point = geometry.item(item);
      if (point == null) continue;
      canvas.drawCircle(point, radius + 2.6, currentFill);
      canvas.drawCircle(point, radius + 2.6, ring);
    }

    final fix = this.fix;
    if (fix != null) _you(canvas, geometry, fix);
  }

  void _you(Canvas canvas, _WalkGeometry geometry, LocationFix fix) {
    const blue = AppColors.waterMain;
    final point = geometry.project(fix.latitude, fix.longitude);
    final bounds = (Offset.zero & geometry.size).deflate(8);
    final inside = bounds.contains(point);
    final shown = Offset(
      point.dx.clamp(bounds.left, bounds.right),
      point.dy.clamp(bounds.top, bounds.bottom),
    );
    if (inside) {
      canvas.drawCircle(
        point,
        math.max(fix.accuracyMeters * geometry.scale, 8),
        Paint()..color = blue.withOpacity(0.14),
      );
      canvas.drawCircle(point, 7, Paint()..color = Colors.white);
      canvas.drawCircle(point, 5, Paint()..color = blue);
    } else {
      // Off the map: a hollow marker on the edge, towards the real position.
      canvas.drawCircle(shown, 7, Paint()..color = Colors.white);
      canvas.drawCircle(
        shown,
        5.5,
        Paint()
          ..color = blue
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _arrow(Canvas canvas, Offset from, Offset to) {
    final paint = Paint()
      ..color = AppColors.orange
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, paint);
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const head = 8.0;
    for (final turn in const <double>[-0.55, 0.55]) {
      canvas.drawLine(
        to,
        to - Offset(math.cos(angle + turn), math.sin(angle + turn)) * head,
        paint,
      );
    }
  }

  void _dashed(Canvas canvas, Offset start, Offset end, Paint paint) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance == 0) return;
    final direction = delta / distance;
    for (var travelled = 0.0; travelled < distance; travelled += 7) {
      canvas.drawLine(
        start + direction * travelled,
        start + direction * math.min(travelled + 3.5, distance),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WalkPainter oldDelegate) =>
      oldDelegate.walk != walk ||
      oldDelegate.marks != marks ||
      oldDelegate.currentStation != currentStation ||
      oldDelegate.fix != fix;
}

/// Colour key for [InspectionWalkMap].
class InspectionWalkMapLegend extends StatelessWidget {
  const InspectionWalkMapLegend({this.showYou = false, super.key});

  final bool showYou;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: <Widget>[
        _LegendDot(
            color: AppColors.orange, label: l10n.inspectionMapLegendCurrent),
        _LegendDot(color: AppColors.green, label: l10n.inspectionMapLegendDone),
        _LegendDot(
            color: AppColors.issue, label: l10n.inspectionMapLegendIssue),
        _LegendDot(
          color: AppColors.muted.withOpacity(0.4),
          label: l10n.inspectionMapLegendPending,
        ),
        if (showYou)
          _LegendDot(
            color: AppColors.waterMain,
            label: l10n.inspectionMapLegendYou,
          ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

/// Full-screen, zoomable [InspectionWalkMap]. Pops with the station the
/// inspector tapped, when [canOpenStation] allows it.
class InspectionWalkMapPage extends StatefulWidget {
  const InspectionWalkMapPage({
    required this.walk,
    required this.marks,
    required this.currentStation,
    required this.fix,
    required this.canOpenStation,
    required this.blockedMessage,
    super.key,
  });

  final InspectionWalk walk;
  final Map<String, InspectionTreeMark> marks;
  final int currentStation;
  final ValueListenable<LocationFix?> fix;

  /// Null when stations cannot be opened from the map (before starting).
  final bool Function(int station)? canOpenStation;
  final String blockedMessage;

  @override
  State<InspectionWalkMapPage> createState() => _InspectionWalkMapPageState();
}

class _InspectionWalkMapPageState extends State<InspectionWalkMapPage> {
  final _transformation = TransformationController();

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final walk = widget.walk;
    final currentStation = widget.currentStation;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.inspectionMapTitle)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ClipRect(
                child: InteractiveViewer(
                  key: const Key('inspection-walk-map-viewer'),
                  transformationController: _transformation,
                  maxScale: 8,
                  child: ValueListenableBuilder<LocationFix?>(
                    valueListenable: widget.fix,
                    builder: (context, fix, _) => InspectionWalkMap(
                      key: const Key('inspection-walk-map-full'),
                      walk: walk,
                      marks: widget.marks,
                      currentStation: currentStation,
                      fix: fix,
                      semanticsLabel: l10n.inspectionMapSemantics(
                        currentStation,
                        walk.stations.length,
                      ),
                      onTapStation: widget.canOpenStation == null
                          ? null
                          : (station) {
                              if (widget.canOpenStation!(station)) {
                                Navigator.of(context).pop(station);
                              } else {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                        content: Text(widget.blockedMessage)),
                                  );
                              }
                            },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ValueListenableBuilder<LocationFix?>(
                    valueListenable: widget.fix,
                    builder: (context, fix, _) =>
                        InspectionWalkMapLegend(showYou: fix != null),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.inspectionMapTapHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
