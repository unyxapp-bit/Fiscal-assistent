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
        final preco = _priceWithoutCurrency(data.preco);

        return Stack(
          children: [
            const Positioned.fill(
              child: PosterTemplateBackground(
                tipo: CartazTemplateTipo.oferta,
              ),
            ),
            Positioned(
              left: w * 0.10,
              right: w * 0.10,
              top: h * 0.245,
              height: hasDetalhe ? h * 0.25 : h * 0.30,
              child: _OfertaTextBlock(data: data),
            ),
            if (detalhe.isNotEmpty)
              Positioned(
                left: w * 0.14,
                right: w * 0.14,
                top: h * 0.525,
                height: h * 0.044,
                child: _FitTextBox(
                  text: detalhe.toUpperCase(),
                  alignment: Alignment.center,
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 0.9,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            Positioned(
              left: w * 0.21,
              right: w * 0.08,
              top: h * 0.625,
              height: h * 0.27,
              child: _OfferPriceLayer(text: preco),
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
          flex: 32,
          child: _FitTextBox(
            text: data.tituloLinha1.toUpperCase(),
            alignment: Alignment.center,
            style: const TextStyle(
              fontSize: 124,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 0.86,
              letterSpacing: -3.2,
            ),
          ),
        ),
        Expanded(
          flex: 32,
          child: _FitTextBox(
            text: data.tituloLinha2.toUpperCase(),
            alignment: Alignment.center,
            style: const TextStyle(
              fontSize: 122,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 0.86,
              letterSpacing: -3.0,
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
        const Spacer(flex: 18),
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
    final displayText = text.trim();

    if (displayText.isEmpty) {
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
                displayText,
                style: TextStyle(
                  fontSize: 188,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withAlpha(35),
                  height: 0.82,
                  letterSpacing: -6.5,
                ),
              ),
            ),
            Text(
              displayText,
              style: TextStyle(
                fontSize: 188,
                fontWeight: FontWeight.w900,
                height: 0.82,
                letterSpacing: -6.5,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 9
                  ..color = Colors.white,
              ),
            ),
            Text(
              displayText,
              style: const TextStyle(
                fontSize: 188,
                fontWeight: FontWeight.w900,
                color: _ofRed,
                height: 0.82,
                letterSpacing: -6.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _priceWithoutCurrency(String value) {
  return value
      .replaceAll(RegExp(r'R\$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), '')
      .trim();
}
