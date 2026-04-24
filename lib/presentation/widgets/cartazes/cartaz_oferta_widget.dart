import 'package:flutter/material.dart';

import '../../../data/models/cartaz_form_data.dart';
import 'brush_stroke_painter.dart';
import 'poster_canvas.dart';

const _ofRed = Color(0xFFD61E1E);
const _ofDarkRed = Color(0xFF8E1515);
const _ofYellow = Color(0xFFF5CC1C);
const _ofBorder = Color(0xFFD8D8D8);

class CartazOfertaWidget extends StatelessWidget {
  final CartazFormData data;

  const CartazOfertaWidget({super.key, required this.data});

  static const double baseW = 420;
  static const double baseH = 592;

  @override
  Widget build(BuildContext context) {
    return PosterCanvas(
      tamanho: data.tamanho,
      backgroundColor: Colors.white,
      borderColor: _ofBorder,
      borderWidth: 2,
      builder: (context, safeSize) {
        final w = safeSize.width;
        final h = safeSize.height;
        final detalhe = (data.detalhe ?? '').trim();
        final validade = (data.validade ?? '').trim();

        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: h * 0.16,
              child: const _OfertaHeader(),
            ),
            Positioned(
              left: w * 0.05,
              right: w * 0.05,
              top: h * 0.18,
              height: h * 0.13,
              child: _CenteredFitLine(
                text: data.tituloLinha1.toUpperCase(),
                color: Colors.black,
                fontSize: 130,
                letterSpacing: -4,
              ),
            ),
            Positioned(
              left: w * 0.07,
              right: w * 0.07,
              top: h * 0.31,
              height: h * 0.13,
              child: _CenteredFitLine(
                text: data.tituloLinha2.toUpperCase(),
                color: Colors.black,
                fontSize: 122,
                letterSpacing: -4,
              ),
            ),
            Positioned(
              left: w * 0.28,
              right: w * 0.28,
              top: h * 0.45,
              height: h * 0.06,
              child: _CenteredFitLine(
                text: data.subtitulo.toUpperCase(),
                color: Colors.black,
                fontSize: 72,
                letterSpacing: -2.2,
              ),
            ),
            Positioned(
              left: w * 0.03,
              right: w * 0.03,
              top: h * 0.55,
              height: h * 0.30,
              child: const CustomPaint(
                painter: BrushStrokePainter(color: _ofYellow),
              ),
            ),
            Positioned(
              left: w * 0.11,
              right: w * 0.11,
              top: h * 0.60,
              height: h * 0.26,
              child: Align(
                alignment: Alignment.topCenter,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Stack(
                    children: [
                      Transform.translate(
                        offset: const Offset(6, 7),
                        child: Text(
                          data.preco,
                          style: TextStyle(
                            fontSize: 188,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey.shade500.withAlpha(70),
                            height: 0.82,
                            letterSpacing: -8,
                          ),
                        ),
                      ),
                      Text(
                        data.preco,
                        style: TextStyle(
                          fontSize: 188,
                          fontWeight: FontWeight.w900,
                          height: 0.82,
                          letterSpacing: -8,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 8
                            ..color = Colors.white,
                        ),
                      ),
                      const Text(''),
                      Text(
                        data.preco,
                        style: const TextStyle(
                          fontSize: 188,
                          fontWeight: FontWeight.w900,
                          color: _ofRed,
                          height: 0.82,
                          letterSpacing: -8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (detalhe.isNotEmpty)
              Positioned(
                left: w * 0.15,
                right: w * 0.15,
                top: h * 0.84,
                height: h * 0.04,
                child: _CenteredFitLine(
                  text: detalhe.toUpperCase(),
                  color: Colors.black,
                  fontSize: 48,
                  letterSpacing: -1.4,
                ),
              ),
            if (data.unidade.trim().isNotEmpty)
              Positioned(
                left: w * 0.30,
                right: w * 0.30,
                bottom: h * 0.055,
                height: h * 0.065,
                child: _CenteredFitLine(
                  text: data.unidade.toUpperCase(),
                  color: Colors.black,
                  fontSize: 56,
                  letterSpacing: -1.4,
                ),
              ),
            if (validade.isNotEmpty)
              Positioned(
                left: w * 0.03,
                right: w * 0.38,
                bottom: h * 0.012,
                height: h * 0.05,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      validade.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OfertaHeader extends StatelessWidget {
  const _OfertaHeader();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _OfertaHeaderPainter(),
      child: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, 10, 28, 14),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Stack(
              children: [
                Positioned(
                  left: 7,
                  top: 8,
                  child: Text(
                    'OFERTA',
                    style: TextStyle(
                      fontSize: 92,
                      fontWeight: FontWeight.w900,
                      color: Colors.black54,
                      height: 0.88,
                      letterSpacing: -4.5,
                    ),
                  ),
                ),
                Text(
                  'OFERTA',
                  style: TextStyle(
                    fontSize: 92,
                    fontWeight: FontWeight.w900,
                    color: _ofYellow,
                    height: 0.88,
                    letterSpacing: -4.5,
                    shadows: [
                      Shadow(
                        color: Color(0x66000000),
                        offset: Offset(0, 3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfertaHeaderPainter extends CustomPainter {
  const _OfertaHeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_ofRed, Color(0xFFB51717)],
      ).createShader(rect);
    canvas.drawRect(rect, fill);

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.90, size.width, size.height * 0.06),
      Paint()..color = _ofDarkRed,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CenteredFitLine extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final double letterSpacing;

  const _CenteredFitLine({
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
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: color,
          height: 0.84,
          letterSpacing: letterSpacing,
        ),
      ),
    );
  }
}
