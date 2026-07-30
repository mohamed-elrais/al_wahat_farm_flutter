import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paints the Al Wahat launcher icon and keeps the source PNGs
/// reproducible: `assets/icon/app_icon.png` (full square) and
/// `assets/icon/app_icon_foreground.png` (transparent, Android adaptive
/// safe zone). `flutter_launcher_icons` fans these out to every platform
/// size. Regenerate with:
///   flutter test --update-goldens test/golden/app_icon_test.dart
///   flutter pub run flutter_launcher_icons
void main() {
  Future<void> render(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(child);
  }

  testWidgets('app icon source', (tester) async {
    await render(
      tester,
      const RepaintBoundary(
        child: CustomPaint(
          size: Size(1024, 1024),
          painter: AppIconPainter(),
        ),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('../../assets/icon/app_icon.png'),
    );
  });

  testWidgets('app icon adaptive foreground', (tester) async {
    await render(
      tester,
      const RepaintBoundary(
        child: CustomPaint(
          size: Size(1024, 1024),
          painter: AppIconPainter(foreground: true),
        ),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('../../assets/icon/app_icon_foreground.png'),
    );
  });
}

/// The launcher icon: the app's paper-and-ink design language — a bold
/// date palm in Wahat green over the cream grid paper, an orange date
/// cluster as the single accent, rooted on a sand dune.
class AppIconPainter extends CustomPainter {
  const AppIconPainter({this.foreground = false});

  /// Android adaptive foreground: transparent background, mark shrunk
  /// into the central safe zone.
  final bool foreground;

  static const paper = Color(0xFFF8F4E9);
  static const card = Color(0xFFFFFDF7);
  static const ink = Color(0xFF173D28);
  static const green = Color(0xFF285C36);
  static const orange = Color(0xFFCC6637);
  static const sand = Color(0xFFE8D6AE);
  static const line = Color(0xFFE5DCC8);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 1024;

    if (!foreground) {
      // Paper background with the app's subtle grid.
      canvas.drawRect(Offset.zero & size, Paint()..color = paper);
      final grid = Paint()
        ..color = line.withOpacity(0.55)
        ..strokeWidth = 2 * s;
      for (double x = 64 * s; x < size.width; x += 64 * s) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      }
      for (double y = 64 * s; y < size.height; y += 64 * s) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
      // Soft cream disc lifts the mark off the grid.
      canvas.drawCircle(
        Offset(512 * s, 512 * s),
        400 * s,
        Paint()..color = card.withOpacity(0.9),
      );
      canvas.drawCircle(
        Offset(512 * s, 512 * s),
        400 * s,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 * s,
      );
    } else {
      // Shrink the mark into the adaptive safe zone (~66% of canvas).
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(0.62);
      canvas.translate(-size.width / 2, -size.height / 2);
    }

    _paintMark(canvas, s);
  }

  void _paintMark(Canvas canvas, double s) {
    // Sand dune ground.
    final dune = Path()
      ..moveTo(178 * s, 828 * s)
      ..quadraticBezierTo(512 * s, 668 * s, 846 * s, 828 * s)
      ..quadraticBezierTo(512 * s, 776 * s, 178 * s, 828 * s)
      ..close();
    canvas.drawPath(dune, Paint()..color = sand);
    canvas.drawPath(
      dune,
      Paint()
        ..color = ink.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * s,
    );

    // Trunk: gently curved, tapering upward, with frond-scar chevrons.
    final trunk = Path()
      ..moveTo(478 * s, 790 * s)
      ..quadraticBezierTo(496 * s, 610 * s, 496 * s, 470 * s)
      ..lineTo(546 * s, 470 * s)
      ..quadraticBezierTo(552 * s, 610 * s, 584 * s, 790 * s)
      ..close();
    canvas.drawPath(trunk, Paint()..color = green);
    final scar = Paint()
      ..color = paper.withOpacity(0.55)
      ..strokeWidth = 7 * s
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final y = (740 - i * 58) * s;
      final inset = (6 + i * 3) * s;
      canvas.drawLine(
        Offset(486 * s + inset, y),
        Offset(524 * s, y - 20 * s),
        scar,
      );
      canvas.drawLine(
        Offset(524 * s, y - 20 * s),
        Offset(562 * s - inset, y),
        scar,
      );
    }

    // Fronds: nine crescent blades fanned around the crown, the outer
    // ones drooping below horizontal like a real date palm's canopy.
    const crownX = 521.0;
    const crownY = 462.0;
    final specs = <(double, double, Color)>[
      // (tip angle degrees from vertical, length, color)
      (-128, 280, ink),
      (-96, 320, green),
      (-62, 340, ink),
      (-27, 315, green),
      (3, 295, ink),
      (30, 315, green),
      (64, 340, ink),
      (98, 320, green),
      (130, 280, ink),
    ];
    for (final (angle, length, color) in specs) {
      _frond(canvas, s, crownX, crownY, angle, length, color);
    }

    // Crown base hides the frond roots.
    canvas.drawCircle(
      Offset(crownX * s, (crownY + 8) * s),
      34 * s,
      Paint()..color = ink,
    );

    // Orange date clusters hanging from the crown — the single accent.
    _dates(canvas, s, 458, 548);
    _dates(canvas, s, 586, 554);
  }

  void _frond(
    Canvas canvas,
    double s,
    double cx,
    double cy,
    double angleDeg,
    double length,
    Color color,
  ) {
    // A crescent blade: pointed at the crown and at the tip, bowing
    // upward over its chord so every frond arcs the way a palm's does.
    final phi = angleDeg * math.pi / 180;
    final origin = Offset(cx * s, cy * s);
    final l = length * s;
    final tip = origin + Offset(math.sin(phi) * l, -math.cos(phi) * l);
    final chord = tip - origin;
    var perp = angleDeg >= 0
        ? Offset(chord.dy, -chord.dx)
        : Offset(-chord.dy, chord.dx);
    perp = perp / chord.distance;
    final mid = origin + chord / 2;
    final bulge = l * 0.34;
    final thickness = l * 0.17;
    final controlOut = mid + perp * bulge;
    final controlIn = mid + perp * (bulge - thickness * 2);
    final blade = Path()
      ..moveTo(origin.dx, origin.dy)
      ..quadraticBezierTo(controlOut.dx, controlOut.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(controlIn.dx, controlIn.dy, origin.dx, origin.dy)
      ..close();
    canvas.drawPath(blade, Paint()..color = color);
  }

  void _dates(Canvas canvas, double s, double cx, double cy) {
    final stalk = Paint()
      ..color = orange
      ..strokeWidth = 9 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(521 * s, 486 * s),
      Offset(cx * s, (cy - 8) * s),
      stalk,
    );
    // Tight hexagonal bunch so it reads as a date cluster.
    final dot = Paint()..color = orange;
    const offsets = <Offset>[
      Offset(0, 0),
      Offset(-16, 12),
      Offset(16, 12),
      Offset(0, 24),
      Offset(-16, 36),
      Offset(16, 36),
      Offset(0, 48),
    ];
    for (final o in offsets) {
      canvas.drawCircle(
        Offset((cx + o.dx) * s, (cy + o.dy) * s),
        16 * s,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AppIconPainter oldDelegate) =>
      oldDelegate.foreground != foreground;
}
