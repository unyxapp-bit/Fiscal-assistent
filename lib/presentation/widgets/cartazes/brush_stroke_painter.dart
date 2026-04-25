import 'package:flutter/material.dart';

class BrushStrokePainter extends CustomPainter {
  final Color color;

  const BrushStrokePainter({
    this.color = const Color(0xFFF4D000),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseStroke = _distressPath(
      _buildRibbonPath(
        size,
        topOffset: 0,
        bottomOffset: 0,
        insetLeft: 0,
        insetRight: 0,
        crestLift: 0,
      ),
      size,
      biteScale: 1,
    );

    final middleStroke = _distressPath(
      _buildRibbonPath(
        size,
        topOffset: -size.height * 0.038,
        bottomOffset: -size.height * 0.012,
        insetLeft: size.width * 0.018,
        insetRight: size.width * 0.015,
        crestLift: -size.height * 0.02,
      ),
      size,
      biteScale: 0.78,
    );

    final upperStroke = _distressPath(
      _buildRibbonPath(
        size,
        topOffset: -size.height * 0.055,
        bottomOffset: -size.height * 0.03,
        insetLeft: size.width * 0.075,
        insetRight: size.width * 0.055,
        crestLift: -size.height * 0.03,
      ),
      size,
      biteScale: 0.4,
    );

    canvas.drawShadow(baseStroke, Colors.black.withAlpha(42), 9, false);

    canvas.drawPath(
      baseStroke,
      Paint()
        ..color = _shade(color, -0.04)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      middleStroke,
      Paint()
        ..color = color.withAlpha(242)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      upperStroke,
      Paint()
        ..color = _shade(color, 0.04).withAlpha(215)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      _buildBottomWeightPath(size),
      Paint()
        ..color = _shade(color, -0.12).withAlpha(78)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      _buildHighlightPath(size),
      Paint()
        ..color = _shade(color, 0.18).withAlpha(105)
        ..style = PaintingStyle.fill,
    );

    _drawDryStrokes(canvas, size);
    _drawBristles(canvas, size);
    _drawTailSplinters(canvas, size);
  }

  Path _buildRibbonPath(
    Size size, {
    required double topOffset,
    required double bottomOffset,
    required double insetLeft,
    required double insetRight,
    required double crestLift,
  }) {
    final top = <Offset>[
      Offset(size.width * 0.025 + insetLeft, size.height * 0.78 + bottomOffset),
      Offset(size.width * 0.055 + insetLeft, size.height * 0.59 + topOffset),
      Offset(size.width * 0.13 + insetLeft, size.height * 0.48 + topOffset),
      Offset(size.width * 0.26, size.height * 0.39 + topOffset + crestLift),
      Offset(size.width * 0.42, size.height * 0.29 + topOffset + crestLift),
      Offset(size.width * 0.6, size.height * 0.23 + topOffset),
      Offset(
          size.width * 0.79 - insetRight * 0.4, size.height * 0.17 + topOffset),
      Offset(size.width * 0.92 - insetRight, size.height * 0.12 + topOffset),
      Offset(size.width * 0.985 - insetRight, size.height * 0.2 + topOffset),
    ];

    final bottom = <Offset>[
      Offset(size.width * 0.95 - insetRight, size.height * 0.78 + bottomOffset),
      Offset(size.width * 0.86 - insetRight, size.height * 0.82 + bottomOffset),
      Offset(size.width * 0.72, size.height * 0.87 + bottomOffset),
      Offset(size.width * 0.56, size.height * 0.92 + bottomOffset),
      Offset(size.width * 0.38, size.height * 0.96 + bottomOffset),
      Offset(size.width * 0.19 + insetLeft * 0.7,
          size.height * 0.97 + bottomOffset),
      Offset(size.width * 0.07 + insetLeft, size.height * 0.92 + bottomOffset),
      Offset(size.width * 0.015 + insetLeft, size.height * 0.87 + bottomOffset),
    ];

    final outline = <Offset>[...top, ...bottom];
    return _smoothClosedPath(outline);
  }

  Path _distressPath(
    Path base,
    Size size, {
    required double biteScale,
  }) {
    final bites = Path();
    final scale = biteScale.clamp(0.0, 1.0);

    final leftCenters = <Offset>[
      Offset(size.width * 0.032, size.height * 0.77),
      Offset(size.width * 0.045, size.height * 0.84),
      Offset(size.width * 0.065, size.height * 0.9),
    ];

    for (var i = 0; i < leftCenters.length; i++) {
      bites.addOval(
        Rect.fromCenter(
          center: leftCenters[i],
          width: size.width * (0.03 - i * 0.003) * scale,
          height: size.height * (0.11 - i * 0.012) * scale,
        ),
      );
    }

    final rightCenters = <Offset>[
      Offset(size.width * 0.958, size.height * 0.24),
      Offset(size.width * 0.968, size.height * 0.36),
      Offset(size.width * 0.973, size.height * 0.49),
      Offset(size.width * 0.965, size.height * 0.64),
    ];

    for (var i = 0; i < rightCenters.length; i++) {
      bites.addOval(
        Rect.fromCenter(
          center: rightCenters[i],
          width: size.width * (0.026 - i * 0.002) * scale,
          height: size.height * (0.08 - i * 0.008) * scale,
        ),
      );
    }

    final topCenters = <Offset>[
      Offset(size.width * 0.16, size.height * 0.46),
      Offset(size.width * 0.32, size.height * 0.34),
      Offset(size.width * 0.57, size.height * 0.24),
      Offset(size.width * 0.8, size.height * 0.17),
    ];

    for (var i = 0; i < topCenters.length; i++) {
      bites.addOval(
        Rect.fromCenter(
          center: topCenters[i],
          width: size.width * 0.045 * scale,
          height: size.height * (0.018 + i * 0.002) * scale,
        ),
      );
    }

    return Path.combine(PathOperation.difference, base, bites);
  }

  Path _buildBottomWeightPath(Size size) {
    return _smoothOpenPath(<Offset>[
      Offset(size.width * 0.08, size.height * 0.9),
      Offset(size.width * 0.24, size.height * 0.91),
      Offset(size.width * 0.48, size.height * 0.89),
      Offset(size.width * 0.72, size.height * 0.84),
      Offset(size.width * 0.92, size.height * 0.77),
      Offset(size.width * 0.96, size.height * 0.74),
      Offset(size.width * 0.96, size.height * 0.82),
      Offset(size.width * 0.7, size.height * 0.9),
      Offset(size.width * 0.39, size.height * 0.97),
      Offset(size.width * 0.13, size.height * 0.95),
    ], close: true);
  }

  Path _buildHighlightPath(Size size) {
    return _smoothOpenPath(<Offset>[
      Offset(size.width * 0.12, size.height * 0.64),
      Offset(size.width * 0.23, size.height * 0.52),
      Offset(size.width * 0.42, size.height * 0.4),
      Offset(size.width * 0.62, size.height * 0.31),
      Offset(size.width * 0.83, size.height * 0.2),
      Offset(size.width * 0.88, size.height * 0.19),
      Offset(size.width * 0.84, size.height * 0.27),
      Offset(size.width * 0.66, size.height * 0.36),
      Offset(size.width * 0.45, size.height * 0.47),
      Offset(size.width * 0.2, size.height * 0.61),
    ], close: true);
  }

  void _drawDryStrokes(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = _shade(color, 0.06).withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final widths = <double>[0.042, 0.035, 0.03, 0.028, 0.024, 0.022];
    for (var i = 0; i < widths.length; i++) {
      strokePaint.strokeWidth = size.height * widths[i];

      final yShift = size.height * (0.03 + i * 0.06);
      final startX = size.width * (0.07 + (i.isEven ? 0.0 : 0.04));
      final endX = size.width * (0.9 - (i * 0.02));

      final path = Path()
        ..moveTo(startX, size.height * 0.79 - yShift)
        ..cubicTo(
          size.width * 0.26,
          size.height * (0.66 - i * 0.022),
          size.width * 0.52,
          size.height * (0.41 - i * 0.018),
          endX,
          size.height * (0.25 - i * 0.01),
        );

      canvas.drawPath(path, strokePaint);
    }

    final accentPaint = Paint()
      ..color = _shade(color, 0.2).withAlpha(95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.015
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(
            size.width * (0.56 + i * 0.055), size.height * (0.29 - i * 0.008)),
        Offset(
            size.width * (0.67 + i * 0.045), size.height * (0.25 - i * 0.012)),
        accentPaint,
      );
    }
  }

  void _drawBristles(Canvas canvas, Size size) {
    final bristlePaint = Paint()
      ..color = color.withAlpha(238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.012
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 13; i++) {
      final y = size.height * (0.29 + i * 0.05);

      canvas.drawLine(
        Offset(size.width * 0.018, y + size.height * 0.12),
        Offset(size.width * (0.05 + (i % 4) * 0.018), y + size.height * 0.018),
        bristlePaint,
      );
    }

    for (var i = 0; i < 14; i++) {
      final y = size.height * (0.15 + i * 0.043);

      canvas.drawLine(
        Offset(size.width * 0.956, y),
        Offset(size.width * (0.994 - (i % 4) * 0.016), y + size.height * 0.04),
        bristlePaint,
      );
    }
  }

  void _drawTailSplinters(Canvas canvas, Size size) {
    final splinterPaint = Paint()
      ..color = _shade(color, -0.02).withAlpha(220)
      ..style = PaintingStyle.fill;

    final splinters = <Path>[
      Path()
        ..moveTo(size.width * 0.012, size.height * 0.84)
        ..lineTo(size.width * 0.0, size.height * 0.89)
        ..lineTo(size.width * 0.03, size.height * 0.93)
        ..close(),
      Path()
        ..moveTo(size.width * 0.946, size.height * 0.19)
        ..lineTo(size.width * 0.985, size.height * 0.13)
        ..lineTo(size.width * 0.982, size.height * 0.23)
        ..close(),
      Path()
        ..moveTo(size.width * 0.94, size.height * 0.72)
        ..lineTo(size.width * 0.985, size.height * 0.75)
        ..lineTo(size.width * 0.95, size.height * 0.8)
        ..close(),
    ];

    for (final path in splinters) {
      canvas.drawPath(path, splinterPaint);
    }
  }

  Path _smoothClosedPath(List<Offset> points) {
    return _smoothOpenPath(points, close: true);
  }

  Path _smoothOpenPath(List<Offset> points, {required bool close}) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      if (!close && i == points.length - 1) {
        break;
      }

      final mid = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );

      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }

    if (close) {
      path.close();
    } else {
      path.lineTo(points.last.dx, points.last.dy);
    }

    return path;
  }

  Color _shade(Color source, double amount) {
    final hsl = HSLColor.fromColor(source);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  @override
  bool shouldRepaint(covariant BrushStrokePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
