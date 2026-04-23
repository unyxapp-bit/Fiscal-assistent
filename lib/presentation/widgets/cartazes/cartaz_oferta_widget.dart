import 'package:flutter/material.dart';
import '../../../data/models/cartaz_form_data.dart';

const _ofRed = Color(0xFFCC0000);
const _ofYellow = Color(0xFFF4C430);

class CartazOfertaWidget extends StatelessWidget {
  final CartazFormData data;

  const CartazOfertaWidget({super.key, required this.data});

  static const double baseW = 397;
  static const double baseH = 560;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: baseW,
      height: baseH,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDDDDD), width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBanner(),
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (data.tituloLinha1.isNotEmpty)
                  Text(
                    data.tituloLinha1.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 58,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      height: 0.92,
                      letterSpacing: -1,
                    ),
                  ),
                if (data.tituloLinha2.isNotEmpty)
                  Text(
                    data.tituloLinha2.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      height: 1,
                    ),
                  ),
                if (data.subtitulo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      data.subtitulo.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          _PriceBandOferta(preco: data.preco),
          if ((data.detalhe ?? '').isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Text(
                data.detalhe!.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          _buildRodape(),
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      height: 72,
      color: _ofRed,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        decoration: BoxDecoration(
          color: _ofYellow,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'OFERTA',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: _ofRed,
            letterSpacing: 4,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildRodape() {
    final validade = (data.validade ?? '').trim();
    return Container(
      color: _ofYellow,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Text(
        validade.isNotEmpty ? validade.toUpperCase() : '',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}

// ─── Price Band ───────────────────────────────────────────────────────────────

class _PriceBandOferta extends StatelessWidget {
  final String preco;

  const _PriceBandOferta({required this.preco});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: CustomPaint(
        painter: _YellowBandOfertaPainter(),
        child: Stack(
          children: [
            const Positioned(
              left: 16, top: 20,
              child: Text('R\$', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black, height: 1)),
            ),
            Positioned(
              left: 16, top: 0, right: 12, bottom: 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(preco, style: const TextStyle(fontSize: 108, fontWeight: FontWeight.w900, color: _ofRed, height: 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YellowBandOfertaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.32)
      ..lineTo(size.width * 0.07, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = _ofYellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
