import 'package:flutter/material.dart';
import '../../../data/models/cartaz_form_data.dart';

const _kPink = Color(0xFFD6166A);
const _kYellow = Color(0xFFF4C430);
const _kGreen = Color(0xFF1D7A2F);
const _kGrey = Color(0xFFBBBBBB);

class CartazAproveiteAgoraWidget extends StatelessWidget {
  final CartazFormData data;

  const CartazAproveiteAgoraWidget({super.key, required this.data});

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
          _Header(),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 4),
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
          if (data.subtitulo.isNotEmpty || (data.detalhe ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.subtitulo.isNotEmpty)
                    Text(
                      data.subtitulo.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  if ((data.detalhe ?? '').isNotEmpty)
                    Text(
                      data.detalhe!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _kPink,
                      ),
                    ),
                ],
              ),
            ),
          const Spacer(),
          _PriceBand(preco: data.preco, unidade: data.unidade),
          Container(height: 10, color: const Color(0xFFCCCCCC)),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Stack(
        children: [
          const Positioned(left: 8, top: 18, child: _DollarSigns()),
          const Positioned(right: 8, top: 18, child: _DollarSigns()),
          Positioned(
            top: 6, left: 48, right: 48, bottom: 6,
            child: _AproveiteAgoraLogo(),
          ),
        ],
      ),
    );
  }
}

class _DollarSigns extends StatelessWidget {
  const _DollarSigns();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: _kGrey, height: 1.2);
    return const Column(children: [Text('\$', style: style), Text('\$', style: style)]);
  }
}

class _AproveiteAgoraLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LogoBgPainter(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'APROVEITE',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
              shadows: [Shadow(color: Color(0x55000000), offset: Offset(1, 2), blurRadius: 2)],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            color: _kGreen,
            child: const Text(
              'AGORA',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 3,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pink = Paint()..color = _kPink;
    final yellow = Paint()..color = _kYellow;

    final main = Path()
      ..moveTo(size.width * 0.08, 0)
      ..lineTo(size.width * 0.92, size.height * 0.03)
      ..lineTo(size.width * 0.97, size.height * 0.52)
      ..lineTo(size.width * 0.89, size.height * 0.95)
      ..lineTo(size.width * 0.11, size.height * 0.92)
      ..lineTo(0, size.height * 0.48)
      ..close();
    canvas.drawPath(main, pink);

    canvas.drawRect(Rect.fromLTWH(-3, size.height * 0.10, size.width * 0.13, size.height * 0.17), yellow);
    canvas.drawRect(Rect.fromLTWH(-3, size.height * 0.35, size.width * 0.09, size.height * 0.12), yellow);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.88, size.height * 0.07, size.width * 0.14, size.height * 0.18), yellow);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.92, size.height * 0.36, size.width * 0.10, size.height * 0.12), yellow);

    final darkBorder = Paint()..color = const Color(0xFF9C0E4D);
    final borderPath = Path()
      ..moveTo(size.width * 0.08, 0)
      ..lineTo(size.width * 0.92, size.height * 0.03)
      ..lineTo(size.width * 0.91, size.height * 0.03 + 5)
      ..lineTo(size.width * 0.09, 5)
      ..close();
    canvas.drawPath(borderPath, darkBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Price Band ───────────────────────────────────────────────────────────────

class _PriceBand extends StatelessWidget {
  final String preco;
  final String unidade;

  const _PriceBand({required this.preco, required this.unidade});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: CustomPaint(
        painter: _YellowBandPainter(),
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
                  child: Text(preco, style: const TextStyle(fontSize: 108, fontWeight: FontWeight.w900, color: _kPink, height: 1)),
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

class _YellowBandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.32)
      ..lineTo(size.width * 0.07, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = _kYellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
