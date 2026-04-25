import 'package:flutter/material.dart';

import '../../../data/models/cartaz_form_data.dart';
import 'poster_canvas.dart';
import 'poster_template_background.dart';

const _aaPink = Color(0xFFE91B72);

class CartazAproveiteAgoraWidget extends StatelessWidget {
  final CartazFormData data;

  const CartazAproveiteAgoraWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return PosterCanvas(
      tamanho: data.tamanho,
      safePadding: EdgeInsets.zero,
      builder: (context, safeSize) {
        final w = safeSize.width;
        final h = safeSize.height;

        return Stack(
          children: [
            const Positioned.fill(
              child: PosterTemplateBackground(
                tipo: CartazTemplateTipo.aproveiteAgora,
              ),
            ),
            Positioned(
              left: w * 0.05,
              right: w * 0.05,
              top: h * 0.24,
              height: h * 0.39,
              child: _AproveiteTextBlock(data: data),
            ),
            Positioned(
              left: w * 0.18,
              right: w * 0.06,
              bottom: h * 0.05,
              height: h * 0.31,
              child: _PriceLayer(
                text: data.preco,
                color: _aaPink,
                shadowColor: Colors.black.withAlpha(42),
              ),
            ),
            if (data.unidade.trim().isNotEmpty)
              Positioned(
                left: w * 0.74,
                right: w * 0.05,
                bottom: h * 0.038,
                height: h * 0.06,
                child: _FitTextBox(
                  text: data.unidade.toUpperCase(),
                  alignment: Alignment.bottomRight,
                  style: const TextStyle(
                    fontSize: 31,
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

class _AproveiteTextBlock extends StatelessWidget {
  final CartazFormData data;

  const _AproveiteTextBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    final detalhe = (data.detalhe ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 30,
          child: _FitTextBox(
            text: data.tituloLinha1.toUpperCase(),
            alignment: Alignment.center,
            style: const TextStyle(
              fontSize: 150,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 0.84,
              letterSpacing: -5,
            ),
          ),
        ),
        Expanded(
          flex: 28,
          child: _FitTextBox(
            text: data.tituloLinha2.toUpperCase(),
            alignment: Alignment.center,
            style: const TextStyle(
              fontSize: 142,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 0.84,
              letterSpacing: -4.8,
            ),
          ),
        ),
        Expanded(
          flex: 20,
          child: _FitTextBox(
            text: data.subtitulo.toUpperCase(),
            alignment: Alignment.center,
            style: const TextStyle(
              fontSize: 102,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 0.88,
              letterSpacing: -2.8,
            ),
          ),
        ),
        Expanded(
          flex: 22,
          child: _FitTextBox(
            text: detalhe.toUpperCase(),
            alignment: Alignment.centerLeft,
            style: const TextStyle(
              fontSize: 98,
              fontWeight: FontWeight.w900,
              color: _aaPink,
              height: 0.88,
              letterSpacing: -2.4,
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

  const _PriceLayer({
    required this.text,
    required this.color,
    required this.shadowColor,
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
                  fontSize: 238,
                  fontWeight: FontWeight.w900,
                  color: shadowColor,
                  height: 0.82,
                  letterSpacing: -9,
                ),
              ),
            ),
            Text(
              text,
              style: TextStyle(
                fontSize: 238,
                fontWeight: FontWeight.w900,
                color: color,
                height: 0.82,
                letterSpacing: -9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
