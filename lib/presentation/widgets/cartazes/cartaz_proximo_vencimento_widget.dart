import 'package:flutter/material.dart';

import '../../../data/models/cartaz_form_data.dart';

const _pvYellow = Color(0xFFF5C400);
const _pvYellowDeep = Color(0xFFF1B300);
const _pvRed = Color(0xFFEA141A);
const _pvOrange = Color(0xFFF89B00);
const _pvBorder = Color(0xFFD8D8D8);

class CartazProximoVencimentoWidget extends StatelessWidget {
  final CartazFormData data;

  const CartazProximoVencimentoWidget({super.key, required this.data});

  static const double baseW = 397;
  static const double baseH = 560;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: baseW,
      height: baseH,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _pvBorder, width: 2),
      ),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              children: [
                Positioned(
                  left: w * 0.02,
                  top: h * 0.015,
                  width: w * 0.66,
                  height: h * 0.19,
                  child: const _PvHeaderBanner(),
                ),
                Positioned(
                  left: w * 0.72,
                  top: h * 0.018,
                  width: w * 0.23,
                  height: h * 0.17,
                  child: const _CartIllustration(),
                ),
                Positioned(
                  left: w * 0.035,
                  right: w * 0.035,
                  top: h * 0.24,
                  height: h * 0.125,
                  child: _FitLeftLine(
                    text: data.tituloLinha1.toUpperCase(),
                    color: Colors.black,
                    fontSize: 138,
                    letterSpacing: -4.6,
                  ),
                ),
                Positioned(
                  left: w * 0.04,
                  right: w * 0.46,
                  top: h * 0.385,
                  height: h * 0.09,
                  child: _FitLeftLine(
                    text: data.tituloLinha2.toUpperCase(),
                    color: Colors.black,
                    fontSize: 106,
                    letterSpacing: -3,
                  ),
                ),
                Positioned(
                  left: w * 0.04,
                  right: w * 0.50,
                  top: h * 0.48,
                  height: h * 0.09,
                  child: _FitLeftLine(
                    text: data.subtitulo.toUpperCase(),
                    color: _pvOrange,
                    fontSize: 100,
                    letterSpacing: -2.5,
                  ),
                ),
                Positioned(
                  left: w * 0.04,
                  right: w * 0.03,
                  bottom: h * 0.06,
                  height: h * 0.40,
                  child: const CustomPaint(painter: _PvPriceBandPainter()),
                ),
                Positioned(
                  left: w * 0.045,
                  top: h * 0.61,
                  width: w * 0.14,
                  height: h * 0.10,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'R\$',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1,
                        letterSpacing: -2,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: w * 0.18,
                  right: w * 0.05,
                  bottom: h * 0.07,
                  height: h * 0.31,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Stack(
                        children: [
                          Transform.translate(
                            offset: const Offset(4, 6),
                            child: Text(
                              data.preco,
                              style: TextStyle(
                                fontSize: 232,
                                fontWeight: FontWeight.w900,
                                color: Colors.red.shade900.withAlpha(55),
                                height: 0.82,
                                letterSpacing: -9,
                              ),
                            ),
                          ),
                          Text(
                            data.preco,
                            style: const TextStyle(
                              fontSize: 232,
                              fontWeight: FontWeight.w900,
                              color: _pvRed,
                              height: 0.82,
                              letterSpacing: -9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (data.unidade.trim().isNotEmpty)
                  Positioned(
                    right: w * 0.04,
                    bottom: h * 0.085,
                    width: w * 0.22,
                    height: h * 0.05,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          data.unidade.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            height: 1,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: w * 0.02,
                  right: w * 0.02,
                  bottom: h * 0.017,
                  height: h * 0.024,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _pvYellow,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PvHeaderBanner extends StatelessWidget {
  const _PvHeaderBanner();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _PvHeaderPainter(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return Stack(
            children: [
              Positioned(
                left: w * 0.05,
                right: w * 0.67,
                top: h * 0.29,
                height: h * 0.025,
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black),
                ),
              ),
              Positioned(
                left: w * 0.76,
                right: w * 0.05,
                top: h * 0.29,
                height: h * 0.025,
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black),
                ),
              ),
              Positioned(
                left: w * 0.31,
                right: w * 0.23,
                top: h * 0.12,
                height: h * 0.27,
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'PRÓXIMO DO',
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      height: 1,
                      letterSpacing: -1.4,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: w * 0.05,
                right: w * 0.06,
                top: h * 0.40,
                height: h * 0.42,
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'VENCIMENTO',
                    style: TextStyle(
                      fontSize: 88,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      height: 0.9,
                      letterSpacing: -3.5,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PvHeaderPainter extends CustomPainter {
  const _PvHeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.87, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_pvYellow, _pvYellowDeep],
      ).createShader(Offset.zero & size);

    canvas.drawShadow(path, Colors.black.withAlpha(28), 5, false);
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CartIllustration extends StatelessWidget {
  const _CartIllustration();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _CartPainter());
  }
}

class _CartPainter extends CustomPainter {
  const _CartPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = Colors.black.withAlpha(18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.20, size.height * 0.80, size.width * 0.60,
          size.height * 0.11),
      shadow,
    );

    final handle = Paint()
      ..color = const Color(0xFF2E2E2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03
      ..strokeCap = StrokeCap.round;

    final frame = Paint()
      ..color = const Color(0xFF151515)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.028
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final basket = Path()
      ..moveTo(size.width * 0.22, size.height * 0.20)
      ..lineTo(size.width * 0.79, size.height * 0.20)
      ..lineTo(size.width * 0.70, size.height * 0.58)
      ..lineTo(size.width * 0.33, size.height * 0.58)
      ..close();

    canvas.drawLine(
      Offset(size.width * 0.16, size.height * 0.13),
      Offset(size.width * 0.26, size.height * 0.20),
      handle,
    );
    canvas.drawLine(
      Offset(size.width * 0.11, size.height * 0.10),
      Offset(size.width * 0.16, size.height * 0.13),
      Paint()
        ..color = const Color(0xFFDC1A1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.055
        ..strokeCap = StrokeCap.round,
    );

    final fills = [
      (
        const Color(0xFFFFA400),
        Rect.fromLTWH(size.width * 0.28, size.height * 0.17, size.width * 0.10,
            size.height * 0.28)
      ),
      (
        const Color(0xFFFFD633),
        Rect.fromLTWH(size.width * 0.39, size.height * 0.16, size.width * 0.10,
            size.height * 0.30)
      ),
      (
        const Color(0xFFEF3B84),
        Rect.fromLTWH(size.width * 0.50, size.height * 0.18, size.width * 0.10,
            size.height * 0.26)
      ),
      (
        const Color(0xFF24A647),
        Rect.fromLTWH(size.width * 0.61, size.height * 0.19, size.width * 0.11,
            size.height * 0.24)
      ),
      (
        const Color(0xFFFFD847),
        Rect.fromLTWH(size.width * 0.69, size.height * 0.17, size.width * 0.08,
            size.height * 0.20)
      ),
    ];

    for (final item in fills) {
      final paint = Paint()..color = item.$1;
      canvas.drawRect(item.$2, paint);
      canvas.drawRect(
        item.$2,
        Paint()
          ..color = Colors.black.withAlpha(28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    canvas.drawPath(
      basket,
      Paint()
        ..color = Colors.white.withAlpha(130)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(basket, frame);

    for (var i = 1; i <= 4; i++) {
      final x = size.width * (0.28 + i * 0.10);
      canvas.drawLine(
        Offset(x, size.height * 0.21),
        Offset(x - size.width * 0.06, size.height * 0.58),
        frame,
      );
    }

    for (var i = 1; i <= 3; i++) {
      final y = size.height * (0.29 + i * 0.08);
      canvas.drawLine(
        Offset(size.width * 0.24, y),
        Offset(size.width * 0.76, y),
        Paint()
          ..color = const Color(0xFF5A5A5A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.012,
      );
    }

    canvas.drawLine(
      Offset(size.width * 0.40, size.height * 0.58),
      Offset(size.width * 0.28, size.height * 0.77),
      frame,
    );
    canvas.drawLine(
      Offset(size.width * 0.70, size.height * 0.58),
      Offset(size.width * 0.83, size.height * 0.77),
      frame,
    );
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.77),
      Offset(size.width * 0.84, size.height * 0.77),
      frame,
    );

    final wheelShadow = Paint()..color = Colors.black.withAlpha(35);
    final wheel = Paint()..color = const Color(0xFFD61A1A);
    final axle = Paint()..color = Colors.black;

    final leftCenter = Offset(size.width * 0.34, size.height * 0.83);
    final rightCenter = Offset(size.width * 0.80, size.height * 0.83);

    canvas.drawCircle(leftCenter, size.width * 0.065, wheelShadow);
    canvas.drawCircle(rightCenter, size.width * 0.065, wheelShadow);
    canvas.drawCircle(leftCenter, size.width * 0.052, wheel);
    canvas.drawCircle(rightCenter, size.width * 0.052, wheel);
    canvas.drawCircle(leftCenter, size.width * 0.022, axle);
    canvas.drawCircle(rightCenter, size.width * 0.022, axle);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FitLeftLine extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final double letterSpacing;

  const _FitLeftLine({
    required this.text,
    required this.color,
    required this.fontSize,
    required this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: color,
          height: 0.82,
          letterSpacing: letterSpacing,
        ),
      ),
    );
  }
}

class _PvPriceBandPainter extends CustomPainter {
  const _PvPriceBandPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.03, size.height * 0.64)
      ..lineTo(size.width * 0.09, size.height * 0.58)
      ..lineTo(size.width * 0.23, size.height * 0.49)
      ..lineTo(size.width * 0.55, size.height * 0.31)
      ..lineTo(size.width * 0.82, size.height * 0.14)
      ..lineTo(size.width * 0.95, size.height * 0.08)
      ..lineTo(size.width * 0.90, size.height * 0.16)
      ..lineTo(size.width * 0.98, size.height * 0.13)
      ..lineTo(size.width, size.height * 0.20)
      ..lineTo(size.width * 0.96, size.height * 0.27)
      ..lineTo(size.width, size.height * 0.32)
      ..lineTo(size.width * 0.96, size.height * 0.39)
      ..lineTo(size.width * 0.98, size.height * 0.46)
      ..lineTo(size.width * 0.95, size.height * 0.53)
      ..lineTo(size.width * 0.97, size.height * 0.59)
      ..lineTo(size.width * 0.92, size.height * 0.68)
      ..lineTo(size.width * 0.83, size.height * 0.78)
      ..lineTo(size.width * 0.69, size.height * 0.89)
      ..lineTo(size.width * 0.42, size.height * 0.98)
      ..lineTo(size.width * 0.15, size.height * 0.98)
      ..lineTo(size.width * 0.10, size.height)
      ..lineTo(size.width * 0.08, size.height * 0.94)
      ..lineTo(size.width * 0.05, size.height * 0.98)
      ..lineTo(size.width * 0.04, size.height * 0.91)
      ..lineTo(size.width * 0.01, size.height * 0.93)
      ..lineTo(size.width * 0.02, size.height * 0.86)
      ..lineTo(0, size.height * 0.84)
      ..lineTo(size.width * 0.02, size.height * 0.76)
      ..lineTo(0, size.height * 0.72)
      ..close();

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [_pvYellow, _pvYellowDeep],
      ).createShader(Offset.zero & size);

    canvas.drawShadow(path, Colors.black.withAlpha(42), 7, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
