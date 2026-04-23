import 'package:flutter/material.dart';
import '../../../data/models/cartaz_form_data.dart';

const _pvRed = Color(0xFFCC0000);
const _pvYellow = Color(0xFFF4C430);

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
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBanner(),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.tituloLinha1.isNotEmpty)
                  Text(
                    data.tituloLinha1.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      height: 0.92,
                      letterSpacing: -1,
                    ),
                  ),
                if (data.tituloLinha2.isNotEmpty)
                  Text(
                    data.tituloLinha2.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      height: 0.92,
                      letterSpacing: -1,
                    ),
                  ),
              ],
            ),
          ),
          if (data.subtitulo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
              child: Text(
                data.subtitulo.toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          const Spacer(),
          _PriceBandPV(preco: data.preco, unidade: data.unidade),
          Container(height: 8, color: _pvYellow),
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      height: 80,
      color: _pvYellow,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'PRÓXIMO DO\nVENCIMENTO',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                height: 1.05,
              ),
            ),
          ),
          Icon(Icons.shopping_cart_rounded, size: 44, color: Colors.black),
        ],
      ),
    );
  }
}

// ─── Price Band ───────────────────────────────────────────────────────────────

class _PriceBandPV extends StatelessWidget {
  final String preco;
  final String unidade;

  const _PriceBandPV({required this.preco, required this.unidade});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: CustomPaint(
        painter: _YellowBandPVPainter(),
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
                  child: Text(preco, style: const TextStyle(fontSize: 108, fontWeight: FontWeight.w900, color: _pvRed, height: 1)),
                ),
              ),
            ),
            Positioned(
              right: 12, bottom: 12,
              child: Text(unidade.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

class _YellowBandPVPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.32)
      ..lineTo(size.width * 0.07, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = _pvYellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
