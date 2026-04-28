import 'package:flutter/material.dart';

import '../../../data/models/cartaz_form_data.dart';
import 'poster_canvas.dart';
import 'poster_template_background.dart';

const _pvOrange = Color(0xFFF08A00);
const _pvRed = Color(0xFFE11A1A);

class CartazProximoVencimentoWidget extends StatelessWidget {
  final CartazFormData data;

  const CartazProximoVencimentoWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return PosterCanvas(
      tamanho: data.tamanho,
      safePadding: EdgeInsets.zero,
      builder: (context, safeSize) {
        final w = safeSize.width;
        final h = safeSize.height;
        final priceText = _priceWithoutCurrency(data.preco);

        return Stack(
          children: [
            const Positioned.fill(
              child: PosterTemplateBackground(
                tipo: CartazTemplateTipo.proximoVencimento,
              ),
            ),
            Positioned(
              left: w * 0.07,
              right: w * 0.07,
              top: h * 0.225,
              height: h * 0.295,
              child: _ProximoTextBlock(data: data),
            ),
            if (priceText.isNotEmpty)
              Positioned(
                left: w * 0.05,
                right: w * 0.80,
                top: h * 0.615,
                height: h * 0.085,
                child: const _FitTextBox(
                  text: 'R\$',
                  alignment: Alignment.centerLeft,
                  style: TextStyle(
                    fontSize: 58,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1,
                    letterSpacing: -2.2,
                  ),
                ),
              ),
            Positioned(
              left: w * 0.17,
              right: w * 0.06,
              top: h * 0.61,
              height: h * 0.305,
              child: _PriceLayer(
                text: priceText,
                color: _pvRed,
                shadowColor: Colors.black.withAlpha(45),
                outlineColor: Colors.white,
              ),
            ),
            if (data.unidade.trim().isNotEmpty)
              Positioned(
                left: w * 0.72,
                right: w * 0.05,
                bottom: h * 0.125,
                height: h * 0.05,
                child: _FitTextBox(
                  text: data.unidade.toUpperCase(),
                  alignment: Alignment.bottomRight,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

String _priceWithoutCurrency(String value) {
  return value
      .replaceAll(RegExp(r'R\$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), '')
      .trim();
}

class _ProximoTextBlock extends StatelessWidget {
  final CartazFormData data;

  const _ProximoTextBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 42,
          child: _FitTextBox(
            text: data.tituloLinha1.toUpperCase(),
            alignment: Alignment.center,
            style: const TextStyle(
              fontSize: 146,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 0.84,
              letterSpacing: -4.8,
            ),
          ),
        ),
        Expanded(
          flex: 34,
          child: _FitTextBox(
            text: data.tituloLinha2.toUpperCase(),
            alignment: Alignment.center,
            style: const TextStyle(
              fontSize: 130,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 0.84,
              letterSpacing: -4.2,
            ),
          ),
        ),
        Expanded(
          flex: 24,
          child: _FitTextBox(
            text: data.subtitulo.toUpperCase(),
            alignment: Alignment.center,
            style: const TextStyle(
              fontSize: 92,
              fontWeight: FontWeight.w900,
              color: _pvOrange,
              height: 0.9,
              letterSpacing: -2.2,
            ),
          ),
        ),
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

class _PriceLayer extends StatelessWidget {
  final String text;
  final Color color;
  final Color shadowColor;
  final Color outlineColor;

  const _PriceLayer({
    required this.text,
    required this.color,
    required this.shadowColor,
    required this.outlineColor,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.bottomLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.bottomLeft,
        child: Stack(
          children: [
            Transform.translate(
              offset: const Offset(4, 7),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 235,
                  fontWeight: FontWeight.w900,
                  color: shadowColor,
                  height: 0.82,
                  letterSpacing: -8.5,
                ),
              ),
            ),
            Text(
              text,
              style: TextStyle(
                fontSize: 235,
                fontWeight: FontWeight.w900,
                height: 0.82,
                letterSpacing: -8.5,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 7
                  ..color = outlineColor,
              ),
            ),
            Text(
              text,
              style: TextStyle(
                fontSize: 235,
                fontWeight: FontWeight.w900,
                color: color,
                height: 0.82,
                letterSpacing: -8.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
