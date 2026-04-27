import 'package:flutter/material.dart';

import '../../../data/models/cartaz_form_data.dart';
import 'poster_canvas.dart';
import 'poster_template_background.dart';

const _ofRed = Color(0xFFD61E1E);

class CartazOfertaWidget extends StatelessWidget {
  final CartazFormData data;

  const CartazOfertaWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return PosterCanvas(
      tamanho: data.tamanho,
      safePadding: EdgeInsets.zero,
      builder: (context, safeSize) {
        final w = safeSize.width;
        final h = safeSize.height;
        final detalhe = (data.detalhe ?? '').trim();
        final validade = (data.validade ?? '').trim();
        final hasDetalhe = detalhe.isNotEmpty;

        return Stack(
          children: [
            const Positioned.fill(
              child: PosterTemplateBackground(
                tipo: CartazTemplateTipo.oferta,
              ),
            ),
            Positioned(
              left: w * 0.08,
              right: w * 0.08,
              top: h * 0.205,
              height: hasDetalhe ? h * 0.28 : h * 0.32,
              child: _OfertaTextBlock(data: data),
            ),
            if (detalhe.isNotEmpty)
              Positioned(
                left: w * 0.14,
                right: w * 0.14,
                top: h * 0.505,
                height: h * 0.048,
                child: _FitTextBox(
                  text: detalhe.toUpperCase(),
                  alignment: Alignment.center,
                  style: const TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 0.9,
                    letterSpacing: -1.4,
                  ),
                ),
              ),
            Positioned(
              left: w * 0.19,
              right: w * 0.08,
              top: h * 0.605,
              height: h * 0.285,
              child: _OfferPriceLayer(text: data.preco),
            ),
            if (data.unidade.trim().isNotEmpty)
              Positioned(
                left: w * 0.32,
                right: w * 0.32,
                bottom: h * 0.105,
                height: h * 0.052,
                child: _FitTextBox(
                  text: data.unidade.toUpperCase(),
                  alignment: Alignment.center,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
            if (validade.isNotEmpty)
              Positioned(
                left: w * 0.06,
                right: w * 0.06,
                bottom: h * 0.012,
                height: h * 0.032,
                child: _FitTextBox(
                  text: validade.toUpperCase(),
                  alignment: Alignment.bottomCenter,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OfertaTextBlock extends StatelessWidget {
  final CartazFormData data;

  const _OfertaTextBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 34,
          child: _FitTextBox(
            text: data.tituloLinha1.toUpperCase(),
            alignment: Alignment.center,
            style: const TextStyle(
              fontSize: 136,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 0.84,
              letterSpacing: -4.4,
            ),
          ),
        ),
        Expanded(
          flex: 34,
          child: _FitTextBox(
            text: data.tituloLinha2.toUpperCase(),
            alignment: Alignment.center,
            style: const TextStyle(
              fontSize: 132,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 0.84,
              letterSpacing: -4.2,
            ),
          ),
        ),
        Expanded(
          flex: 18,
          child: _FitTextBox(
            text: data.subtitulo.toUpperCase(),
            alignment: Alignment.center,
            style: const TextStyle(
              fontSize: 74,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 0.9,
              letterSpacing: -2.2,
            ),
          ),
        ),
        const Spacer(flex: 14),
      ],
    );
  }
}

class _FitTextBox extends StatelessWidget {
  final String text;
  final Alignment alignment;
  final TextStyle style;

  const _FitTextBox({
    required this.text,
    required this.alignment,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        text,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}

class _OfferPriceLayer extends StatelessWidget {
  final String text;

  const _OfferPriceLayer({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.topCenter,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: Stack(
          children: [
            Transform.translate(
              offset: const Offset(6, 8),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 196,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withAlpha(35),
                  height: 0.82,
                  letterSpacing: -8,
                ),
              ),
            ),
            Text(
              text,
              style: TextStyle(
                fontSize: 196,
                fontWeight: FontWeight.w900,
                height: 0.82,
                letterSpacing: -8,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 10
                  ..color = Colors.white,
              ),
            ),
            Text(
              text,
              style: const TextStyle(
                fontSize: 196,
                fontWeight: FontWeight.w900,
                color: _ofRed,
                height: 0.82,
                letterSpacing: -8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
