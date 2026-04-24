import 'package:flutter/material.dart';
import '../../../data/models/cartaz_form_data.dart';

const _kPink = Color(0xFFD41870);
const _kYellow = Color(0xFFEFB90A);
const _kGreen = Color(0xFF1D7A2F);
const _kGrey = Color(0xFFBBBBBB);
const _kDarkPink = Color(0xFF8E0A46);

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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
              child: _ProductArea(data: data),
            ),
          ),
          _PriceBand(preco: data.preco, unidade: data.unidade),
          Container(height: 10, color: const Color(0xFFD0D0D0)),
        ],
      ),
    );
  }
}

// ─── Product Area ─────────────────────────────────────────────────────────────

class _ProductArea extends StatelessWidget {
  final CartazFormData data;
  const _ProductArea({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (data.tituloLinha1.isNotEmpty) _ProductLine(data.tituloLinha1.toUpperCase()),
        if (data.tituloLinha2.isNotEmpty) _ProductLine(data.tituloLinha2.toUpperCase()),
        if (data.subtitulo.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              data.subtitulo.toUpperCase(),
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                height: 1.0,
                letterSpacing: -0.5,
              ),
            ),
          ),
        if ((data.detalhe ?? '').isNotEmpty)
          Text(
            data.detalhe!.toUpperCase(),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: _kPink,
              height: 1.05,
              letterSpacing: 0.5,
            ),
          ),
      ],
    );
  }
}

class _ProductLine extends StatelessWidget {
  final String text;
  const _ProductLine(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 92,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            height: 0.88,
            letterSpacing: -2.0,
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Left dollar column
          const Positioned(left: 5, top: 14, child: _DollarColumn()),
          // Right dollar column
          const Positioned(right: 5, top: 14, child: _DollarColumn()),
          // Badge
          Positioned(
            top: 6, left: 42, right: 42, bottom: 4,
            child: _BadgeLogo(),
          ),
        ],
      ),
    );
  }
}

class _DollarColumn extends StatelessWidget {
  const _DollarColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Text('\$',
            style: TextStyle(
                fontSize: 30, fontWeight: FontWeight.w300, color: _kGrey, height: 1.1)),
        SizedBox(height: 6),
        Text('\$',
            style: TextStyle(
                fontSize: 23, fontWeight: FontWeight.w300, color: _kGrey, height: 1.1)),
      ],
    );
  }
}

class _BadgeLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BadgePainter(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          const Text(
            'APROVEITE',
            style: TextStyle(
              fontSize: 43,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
              letterSpacing: 1.5,
              shadows: [
                Shadow(color: Color(0x88000000), offset: Offset(1, 2), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: _kGreen,
            child: const Center(
              child: Text(
                'AGORA',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 5,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    // Yellow accents behind the pink — painted first
    final yellow = Paint()..color = _kYellow;
    canvas.drawRect(Rect.fromLTWH(-5, H * 0.07, W * 0.16, H * 0.22), yellow);
    canvas.drawRect(Rect.fromLTWH(-5, H * 0.34, W * 0.11, H * 0.15), yellow);
    canvas.drawRect(Rect.fromLTWH(W * 0.86, H * 0.05, W * 0.18, H * 0.22), yellow);
    canvas.drawRect(Rect.fromLTWH(W * 0.91, H * 0.33, W * 0.13, H * 0.15), yellow);

    // Green accent strips
    final green = Paint()..color = _kGreen;
    canvas.drawRect(Rect.fromLTWH(-5, H * 0.62, W * 0.08, H * 0.12), green);
    canvas.drawRect(Rect.fromLTWH(W * 0.88, H * 0.60, W * 0.16, H * 0.12), green);

    // Main pink polygon
    final pink = Paint()..color = _kPink;
    final main = Path()
      ..moveTo(W * 0.09, 0)
      ..lineTo(W * 0.91, H * 0.02)
      ..lineTo(W, H * 0.50)
      ..lineTo(W * 0.91, H * 0.97)
      ..lineTo(W * 0.09, H * 0.95)
      ..lineTo(0, H * 0.48)
      ..close();
    canvas.drawPath(main, pink);

    // Dark pink bevel top edge
    final bevel = Paint()..color = _kDarkPink;
    final bevelPath = Path()
      ..moveTo(W * 0.09, 0)
      ..lineTo(W * 0.91, H * 0.02)
      ..lineTo(W * 0.90, H * 0.02 + 7)
      ..lineTo(W * 0.10, 7)
      ..close();
    canvas.drawPath(bevelPath, bevel);

    // Thin white frame inside the pink shape
    final frame = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final framePath = Path()
      ..moveTo(W * 0.12, 8)
      ..lineTo(W * 0.88, H * 0.05)
      ..lineTo(W * 0.96, H * 0.50)
      ..lineTo(W * 0.88, H * 0.92)
      ..lineTo(W * 0.12, H * 0.90)
      ..lineTo(W * 0.04, H * 0.48)
      ..close();
    canvas.drawPath(framePath, frame);
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
      height: 162,
      child: CustomPaint(
        painter: _YellowBandPainter(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // R$
            const Positioned(
              left: 14,
              top: 26,
              child: Text(
                'R\$',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  height: 1,
                ),
              ),
            ),
            // Price number — dominant element
            Positioned(
              left: 54,
              top: 0,
              right: 10,
              bottom: 20,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  preco,
                  style: const TextStyle(
                    fontSize: 148,
                    fontWeight: FontWeight.w900,
                    color: _kPink,
                    height: 1.0,
                  ),
                ),
              ),
            ),
            // UNID.
            Positioned(
              right: 14,
              bottom: 12,
              child: Text(
                unidade.toUpperCase(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
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
    final W = size.width;
    final H = size.height;
    final path = Path()
      ..moveTo(0, H * 0.30)
      ..lineTo(W * 0.10, 0)
      ..lineTo(W, 0)
      ..lineTo(W, H)
      ..lineTo(0, H)
      ..close();
    canvas.drawPath(path, Paint()..color = _kYellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
