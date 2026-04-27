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
        final hasDetalhe = (data.detalhe ?? '').trim().isNotEmpty;

        return Stack(
          children: [
            const Positioned.fill(
              child: PosterTemplateBackground(
                tipo: CartazTemplateTipo.aproveiteAgora,
              ),
            ),
            Positioned(
              left: w * 0.08,
              right: w * 0.08,
              top: h * 0.215,
              height: hasDetalhe ? h * 0.30 : h * 0.255,
              child: _AproveiteTextBlock(data: data),
            ),
            Positioned(
              left: w * 0.18,
              right: w * 0.08,
              top: h * 0.64,
              height: h * 0.23,
              child: _PriceLayer(
                text: data.preco,
                color: _aaPink,
                shadowColor: Colors.black.withAlpha(42),
                alignment: Alignment.topLeft,
                fontSize: 220,
                letterSpacing: -8,
              ),
            ),
            if (data.unidade.trim().isNotEmpty)
              Positioned(
                left: w * 0.74,
                right: w * 0.07,
                bottom: h * 0.13,
                height: h * 0.05,
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
    final lines = <_AproveiteLineSpec>[
      _AproveiteLineSpec(
        text: data.tituloLinha1.toUpperCase(),
        alignment: Alignment.center,
        style: const TextStyle(
          fontSize: 144,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          height: 0.84,
          letterSpacing: -5,
        ),
        flex: detalhe.isEmpty ? 38 : 31,
      ),
      _AproveiteLineSpec(
        text: data.tituloLinha2.toUpperCase(),
        alignment: Alignment.center,
        style: const TextStyle(
          fontSize: 136,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          height: 0.84,
          letterSpacing: -4.8,
        ),
        flex: detalhe.isEmpty ? 34 : 28,
      ),
      _AproveiteLineSpec(
        text: data.subtitulo.toUpperCase(),
        alignment: Alignment.center,
        style: const TextStyle(
          fontSize: 94,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          height: 0.88,
          letterSpacing: -2.8,
        ),
        flex: detalhe.isEmpty ? 28 : 19,
      ),
      if (detalhe.isNotEmpty)
        _AproveiteLineSpec(
          text: detalhe.toUpperCase(),
          alignment: Alignment.center,
          style: const TextStyle(
            fontSize: 90,
            fontWeight: FontWeight.w900,
            color: _aaPink,
            height: 0.88,
            letterSpacing: -2.4,
          ),
          flex: 22,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines)
          Expanded(
            flex: line.flex,
            child: _FitTextBox(
              text: line.text,
              alignment: line.alignment,
              style: line.style,
            ),
          ),
      ],
    );
  }
}

class _AproveiteLineSpec {
  final String text;
  final Alignment alignment;
  final TextStyle style;
  final int flex;

  const _AproveiteLineSpec({
    required this.text,
    required this.alignment,
    required this.style,
    required this.flex,
  });
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
  final Alignment alignment;
  final double fontSize;
  final double letterSpacing;

  const _PriceLayer({
    required this.text,
    required this.color,
    required this.shadowColor,
    required this.alignment,
    required this.fontSize,
    required this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: alignment,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Stack(
          children: [
            Transform.translate(
              offset: const Offset(4, 7),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: shadowColor,
                  height: 0.82,
                  letterSpacing: letterSpacing,
                ),
              ),
            ),
            Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: color,
                height: 0.82,
                letterSpacing: letterSpacing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
