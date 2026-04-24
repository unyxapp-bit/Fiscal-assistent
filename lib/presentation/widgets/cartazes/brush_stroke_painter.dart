import 'package:flutter/material.dart';

class BrushStrokePainter extends CustomPainter {
  final Color color;

  const BrushStrokePainter({
    this.color = const Color(0xFFF4D000),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPath = _buildStrokePath(
      size,
      topLift: 0.0,
      tailDrop: 0.0,
      inset: 0.0,
    );

    canvas.drawShadow(shadowPath, Colors.black.withAlpha(35), 7, false);

    final basePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(shadowPath, basePaint);

    final midPath = _buildStrokePath(
      size,
      topLift: -size.height * 0.03,
      tailDrop: size.height * 0.015,
      inset: size.width * 0.012,
    );
    canvas.drawPath(
      midPath,
      Paint()
        ..color = color.withAlpha(225)
        ..style = PaintingStyle.fill,
    );

    final topTexture = _buildTopTexturePath(size);
    canvas.drawPath(
      topTexture,
      Paint()
        ..color = color.withAlpha(170)
        ..style = PaintingStyle.fill,
    );

    final dryPaint = Paint()
      ..color = color.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.045
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 9; i++) {
      final y = size.height * (0.30 + i * 0.052);
      final startX = size.width * (0.03 + (i.isEven ? 0.00 : 0.035));
      final endX = size.width * (0.97 - (i.isEven ? 0.02 : 0.00));

      final line = Path()
        ..moveTo(startX, y + size.height * 0.09)
        ..quadraticBezierTo(
          size.width * 0.48,
          y - size.height * 0.05,
          endX,
          y,
        );

      canvas.drawPath(line, dryPaint);
    }

    final highlightPaint = Paint()
      ..color = color.withAlpha(90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.018
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.18 + i * 0.055);
      canvas.drawLine(
        Offset(size.width * (0.62 + i * 0.05), y + size.height * 0.03),
        Offset(size.width * (0.76 + i * 0.05), y),
        highlightPaint,
      );
    }

    final bristlePaint = Paint()
      ..color = color.withAlpha(235)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.013
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 14; i++) {
      final y = size.height * (0.22 + i * 0.045);

      canvas.drawLine(
        Offset(size.width * 0.01, y + size.height * 0.12),
        Offset(size.width * (0.045 + (i % 3) * 0.023), y),
        bristlePaint,
      );

      canvas.drawLine(
        Offset(size.width * 0.955, y),
        Offset(size.width * (0.995 - (i % 3) * 0.018), y + size.height * 0.04),
        bristlePaint,
      );
    }
  }

  Path _buildStrokePath(
    Size size, {
    required double topLift,
    required double tailDrop,
    required double inset,
  }) {
    return Path()
      ..moveTo(size.width * 0.02 + inset, size.height * 0.62 + tailDrop)
      ..cubicTo(
        size.width * 0.11 + inset,
        size.height * 0.31 + topLift,
        size.width * 0.31 + inset,
        size.height * 0.22 + topLift,
        size.width * 0.55,
        size.height * 0.18 + topLift,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.14 + topLift,
        size.width * 0.92 - inset,
        size.height * 0.08 + topLift,
        size.width * 0.98 - inset,
        size.height * 0.18 + topLift,
      )
      ..lineTo(size.width * 0.94 - inset, size.height * 0.72 + tailDrop)
      ..cubicTo(
        size.width * 0.77,
        size.height * 0.82 + tailDrop,
        size.width * 0.44,
        size.height * 0.90 + tailDrop,
        size.width * 0.11 + inset,
        size.height * 0.88 + tailDrop,
      )
      ..cubicTo(
        size.width * 0.02 + inset,
        size.height * 0.82 + tailDrop,
        size.width * 0.00 + inset,
        size.height * 0.72 + tailDrop,
        size.width * 0.02 + inset,
        size.height * 0.62 + tailDrop,
      )
      ..close();
  }

  Path _buildTopTexturePath(Size size) {
    return Path()
      ..moveTo(size.width * 0.10, size.height * 0.53)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.40,
        size.width * 0.48,
        size.height * 0.30,
        size.width * 0.75,
        size.height * 0.19,
      )
      ..lineTo(size.width * 0.86, size.height * 0.17)
      ..lineTo(size.width * 0.83, size.height * 0.25)
      ..cubicTo(
        size.width * 0.57,
        size.height * 0.34,
        size.width * 0.37,
        size.height * 0.44,
        size.width * 0.15,
        size.height * 0.58,
      )
      ..close();
  }

  @override
  bool shouldRepaint(covariant BrushStrokePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
