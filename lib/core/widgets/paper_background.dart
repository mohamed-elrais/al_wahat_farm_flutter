import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class PaperBackground extends StatelessWidget {
  const PaperBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: const _PaperGridPainter(), child: child);
}

class _PaperGridPainter extends CustomPainter {
  const _PaperGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(AppColors.paper, BlendMode.src);
    final paint = Paint()
      ..color = AppColors.green.withOpacity(0.035)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperGridPainter oldDelegate) => false;
}
