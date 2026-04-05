import 'package:flutter/material.dart';
import 'dart:math' as math;

class SwiftCartLuxuryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFD4AF37);
    final glowPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.12), 160, glowPaint..color = gold.withOpacity(0.15));
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.55), 200, glowPaint..color = gold.withOpacity(0.12));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.9), 140, glowPaint..color = gold.withOpacity(0.04));

    final streakPaint = Paint()..color = gold.withOpacity(0.15)..strokeWidth = 1.8..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final offset = i * 32.0;
      canvas.drawLine(Offset(size.width * 0.4 + offset, 0), Offset(size.width + 60, size.height * 0.45 + offset * 0.8), streakPaint);
    }

    final arcPaint = Paint()..color = gold.withOpacity(0.25)..style = PaintingStyle.stroke..strokeWidth = 2.5;
    canvas.drawArc(Rect.fromCircle(center: Offset(-30, size.height * 0.88), radius: 200), -math.pi / 2, math.pi, false, arcPaint);

    final dotPaint = Paint()..color = gold.withOpacity(0.20);
    for (double x = 18; x < size.width; x += 35) {
      for (double y = 18; y < size.height; y += 35) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}