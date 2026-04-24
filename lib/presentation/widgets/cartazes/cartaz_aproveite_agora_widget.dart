import 'package:flutter/material.dart';

import '../../../data/models/cartaz_form_data.dart';
import 'brush_stroke_painter.dart';
import 'poster_canvas.dart';

const _aaPink = Color(0xFFE91B72);
const _aaDarkPink = Color(0xFFA20D51);
const _aaGreen = Color(0xFF1F9A1B);
const _aaDarkGreen = Color(0xFF146812);
const _aaYellow = Color(0xFFF9C400);
const _aaGrey = Color(0xFFB7B7B7);
const _aaBorder = Color(0xFFD8D8D8);

class CartazAproveiteAgoraWidget extends StatelessWidget {
  final CartazFormData data;

  const CartazAproveiteAgoraWidget({super.key, required this.data});

  static const double baseW = 420;
  static const double baseH = 592;

  @override
  Widget build(BuildContext context) {
    return PosterCanvas(
      tamanho: data.tamanho,
      backgroundColor: Colors.white,
      borderColor: _aaBorder,
      borderWidth: 2,
      builder: (context, safeSize) {
        final w = safeSize.width;
        final h = safeSize.height;

        return Stack(
          children: [
            Positioned(
              left: w * 0.05,
              right: w * 0.05,
              top: h * 0.015,
              height: h * 0.22,
              child: const _AproveiteHeader(),
            ),
            Positioned(
              left: w * 0.06,
              right: w * 0.06,
              top: h * 0.25,
              height: h * 0.35,
              child: _AproveiteProductBlock(data: data),
            ),
            Positioned(
              left: w * 0.04,
              right: w * 0.03,
              bottom: h * 0.03,
              height: h * 0.40,
              child: const CustomPaint(
                painter: BrushStrokePainter(color: _aaYellow),
              ),
            ),
            Positioned(
              left: w * 0.045,
              right: w * 0.815,
              top: h * 0.67,
              height: h * 0.10,
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'R\$',
                  style: TextStyle(
                    fontSize: 58,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1,
                    letterSpacing: -2.2,
                  ),
                ),
              ),
            ),
            Positioned(
              left: w * 0.18,
              right: w * 0.06,
              bottom: h * 0.05,
              height: h * 0.33,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    data.preco,
                    style: const TextStyle(
                      fontSize: 238,
                      fontWeight: FontWeight.w900,
                      color: _aaPink,
                      height: 0.82,
                      letterSpacing: -9,
                    ),
                  ),
                ),
              ),
            ),
            if (data.unidade.trim().isNotEmpty)
              Positioned(
                left: w * 0.74,
                right: w * 0.04,
                bottom: h * 0.04,
                height: h * 0.065,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      data.unidade.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 30,
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
              left: w * 0.012,
              right: w * 0.012,
              bottom: h * 0.012,
              height: h * 0.025,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFD7D7D7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AproveiteHeader extends StatelessWidget {
  const _AproveiteHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _HeaderFramePainter()),
            ),
            Positioned(
              left: 0,
              right: w * 0.88,
              top: h * 0.18,
              height: h * 0.44,
              child: const _DollarColumn(),
            ),
            Positioned(
              left: w * 0.88,
              right: 0,
              top: h * 0.18,
              height: h * 0.44,
              child: const _DollarColumn(),
            ),
            Positioned(
              left: w * 0.16,
              right: w * 0.70,
              top: h * 0.22,
              height: h * 0.32,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _aaDarkPink,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      offset: const Offset(6, 6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: w * 0.13,
              right: w * 0.79,
              top: h * 0.44,
              height: h * 0.06,
              child: const _AccentBar(color: _aaGreen),
            ),
            Positioned(
              left: w * 0.17,
              right: w * 0.71,
              top: h * 0.46,
              height: h * 0.08,
              child: const _AccentBar(color: _aaYellow),
            ),
            Positioned(
              left: w * 0.79,
              right: w * 0.09,
              top: h * 0.12,
              height: h * 0.09,
              child: const _AccentBar(color: _aaYellow),
            ),
            Positioned(
              left: w * 0.90,
              right: w * 0.02,
              top: h * 0.15,
              height: h * 0.05,
              child: const _AccentBar(color: _aaGreen),
            ),
            Positioned(
              left: w * 0.82,
              right: w * 0.10,
              top: h * 0.54,
              height: h * 0.05,
              child: const _AccentBar(color: _aaYellow),
            ),
            Positioned(
              left: w * 0.86,
              right: w * 0.03,
              top: h * 0.56,
              height: h * 0.07,
              child: const _AccentBar(color: _aaPink),
            ),
            Positioned(
              left: w * 0.935,
              right: w * 0.005,
              top: h * 0.565,
              height: h * 0.07,
              child: const _DoubleAccent(),
            ),
            Positioned(
              left: w * 0.18,
              right: w * 0.13,
              top: h * 0.11,
              height: h * 0.42,
              child: const _HeaderBanner(
                color: _aaPink,
                shadowColor: _aaDarkPink,
                text: 'APROVEITE',
                fontSize: 60,
                letterSpacing: -1.4,
              ),
            ),
            Positioned(
              left: w * 0.30,
              right: w * 0.25,
              top: h * 0.42,
              height: h * 0.24,
              child: const _HeaderBanner(
                color: _aaGreen,
                shadowColor: _aaDarkGreen,
                text: 'AGORA',
                fontSize: 48,
                letterSpacing: -1,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeaderFramePainter extends CustomPainter {
  const _HeaderFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final pink = Paint()
      ..color = _aaPink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final green = Paint()
      ..color = _aaGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final yellow = Paint()
      ..color = _aaYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final outer = Path()
      ..moveTo(size.width * 0.16, size.height * 0.15)
      ..lineTo(size.width * 0.27, size.height * 0.15)
      ..lineTo(size.width * 0.27, size.height * 0.03)
      ..lineTo(size.width * 0.40, size.height * 0.03)
      ..moveTo(size.width * 0.84, size.height * 0.03)
      ..lineTo(size.width * 0.96, size.height * 0.03)
      ..lineTo(size.width * 0.94, size.height * 0.15)
      ..moveTo(size.width * 0.16, size.height * 0.15)
      ..lineTo(size.width * 0.14, size.height * 0.86)
      ..lineTo(size.width * 0.93, size.height * 0.83);
    canvas.drawPath(outer, pink);

    final inner = Path()
      ..moveTo(size.width * 0.19, size.height * 0.60)
      ..lineTo(size.width * 0.19, size.height * 0.28)
      ..lineTo(size.width * 0.83, size.height * 0.28)
      ..lineTo(size.width * 0.79, size.height * 0.71)
      ..lineTo(size.width * 0.19, size.height * 0.71)
      ..close();
    canvas.drawPath(inner, green);

    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.71),
      Offset(size.width * 0.69, size.height * 0.71),
      yellow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DollarColumn extends StatelessWidget {
  const _DollarColumn();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '\$',
            style: TextStyle(
              fontSize: 54,
              fontWeight: FontWeight.w400,
              color: _aaGrey,
              height: 1,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '\$',
            style: TextStyle(
              fontSize: 54,
              fontWeight: FontWeight.w400,
              color: _aaGrey,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccentBar extends StatelessWidget {
  final Color color;

  const _AccentBar({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarPainter(color: color),
    );
  }
}

class _DoubleAccent extends StatelessWidget {
  const _DoubleAccent();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(width: 8, child: _AccentBar(color: _aaPink)),
        SizedBox(width: 8, child: _AccentBar(color: _aaPink)),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  final Color color;

  const _BarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.12, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.88, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(path, Colors.black.withAlpha(30), 4, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _HeaderBanner extends StatelessWidget {
  final Color color;
  final Color shadowColor;
  final String text;
  final double fontSize;
  final double letterSpacing;

  const _HeaderBanner({
    required this.color,
    required this.shadowColor,
    required this.text,
    required this.fontSize,
    required this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: CustomPaint(
            painter: _ParallelogramPainter(color: color),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: CustomPaint(
            painter: _ParallelogramShadowPainter(color: shadowColor),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Stack(
                children: [
                  Transform.translate(
                    offset: const Offset(4, 6),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withAlpha(90),
                        height: 0.9,
                        letterSpacing: letterSpacing,
                      ),
                    ),
                  ),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      height: 0.9,
                      letterSpacing: letterSpacing,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 5
                        ..color = Colors.black,
                    ),
                  ),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 0.9,
                      letterSpacing: letterSpacing,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ParallelogramPainter extends CustomPainter {
  final Color color;

  const _ParallelogramPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.08, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.92, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(path, Colors.black.withAlpha(45), 6, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ParallelogramPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _ParallelogramShadowPainter extends CustomPainter {
  final Color color;

  const _ParallelogramShadowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.10, size.height * 0.12)
      ..lineTo(size.width, size.height * 0.12)
      ..lineTo(size.width * 0.92, size.height)
      ..lineTo(size.width * 0.02, size.height)
      ..close();

    canvas.drawPath(
      path.shift(const Offset(-6, 8)),
      Paint()..color = color.withAlpha(185),
    );
  }

  @override
  bool shouldRepaint(covariant _ParallelogramShadowPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _AproveiteProductBlock extends StatelessWidget {
  final CartazFormData data;

  const _AproveiteProductBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    final detalhe = (data.detalhe ?? '').trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: h * 0.34,
              child: _FitProductLine(
                text: data.tituloLinha1.toUpperCase(),
                color: Colors.black,
                fontSize: 162,
                letterSpacing: -5.5,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: h * 0.33,
              height: h * 0.34,
              child: _FitProductLine(
                text: data.tituloLinha2.toUpperCase(),
                color: Colors.black,
                fontSize: 162,
                letterSpacing: -5.5,
              ),
            ),
            Positioned(
              left: 0,
              right: w * 0.35,
              top: h * 0.68,
              height: h * 0.16,
              child: _FitProductLine(
                text: data.subtitulo.toUpperCase(),
                color: Colors.black,
                fontSize: 112,
                letterSpacing: -3.5,
              ),
            ),
            Positioned(
              left: 0,
              right: w * 0.26,
              top: h * 0.84,
              height: h * 0.16,
              child: _FitProductLine(
                text: detalhe.toUpperCase(),
                color: _aaPink,
                fontSize: 108,
                letterSpacing: -3.2,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FitProductLine extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final double letterSpacing;

  const _FitProductLine({
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
          height: 0.78,
          letterSpacing: letterSpacing,
        ),
      ),
    );
  }
}
