import 'package:flutter/material.dart';

import '../../../data/models/cartaz_form_data.dart';
import 'cartaz_text_adjustments.dart';
import 'poster_canvas.dart';
import 'poster_template_background.dart';

const _aaPink = Color(0xFFE91B72);

class CartazAproveiteAgoraWidget extends StatelessWidget {
  final CartazFormData data;
  final CartazTextAdjustments? textAdjustments;
  final CartazTextElement? selectedElement;
  final bool showSelection;

  const CartazAproveiteAgoraWidget({
    super.key,
    required this.data,
    this.textAdjustments,
    this.selectedElement,
    this.showSelection = false,
  });

  bool _isSelected(CartazTextElement element) {
    return showSelection && selectedElement == element;
  }

  @override
  Widget build(BuildContext context) {
    return PosterCanvas(
      tamanho: data.tamanho,
      safePadding: EdgeInsets.zero,
      builder: (context, safeSize) {
        final w = safeSize.width;
        final h = safeSize.height;
        final hasDetalhe = (data.detalhe ?? '').trim().isNotEmpty;
        final canvasSize = Size(w, h);
        final priceText = _priceWithoutCurrency(data.preco);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: PosterTemplateBackground(
                tipo: CartazTemplateTipo.aproveiteAgora,
              ),
            ),
            ..._buildProductSlots(canvasSize, hasDetalhe),
            CartazTextSlot(
              canvasSize: canvasSize,
              element: CartazTextElement.preco,
              adjustments: textAdjustments,
              selected: _isSelected(CartazTextElement.preco),
              left: w * 0.18,
              top: h * 0.64,
              width: w * 0.74,
              height: h * 0.23,
              scaleAlignment: Alignment.topLeft,
              child: _PriceLayer(
                text: priceText,
                color: _aaPink,
                shadowColor: Colors.black.withAlpha(42),
                alignment: Alignment.topLeft,
                fontSize: 220,
                letterSpacing: -8,
              ),
            ),
            if (data.unidade.trim().isNotEmpty)
              CartazTextSlot(
                canvasSize: canvasSize,
                element: CartazTextElement.unidade,
                adjustments: textAdjustments,
                selected: _isSelected(CartazTextElement.unidade),
                left: w * 0.74,
                top: h * 0.82,
                width: w * 0.19,
                height: h * 0.05,
                scaleAlignment: Alignment.bottomRight,
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

  List<Widget> _buildProductSlots(Size canvasSize, bool hasDetalhe) {
    final w = canvasSize.width;
    final h = canvasSize.height;
    final detalhe = (data.detalhe ?? '').trim();
    final lines = <_AproveiteLineSpec>[
      _AproveiteLineSpec(
        element: CartazTextElement.tituloLinha1,
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
        element: CartazTextElement.tituloLinha2,
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
        element: CartazTextElement.subtitulo,
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
          element: CartazTextElement.detalhe,
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

    final top = h * 0.215;
    final height = hasDetalhe ? h * 0.30 : h * 0.255;
    final left = w * 0.08;
    final width = w * 0.84;
    final totalFlex = lines.fold<int>(0, (sum, line) => sum + line.flex);
    var lineTop = top;
    final slots = <Widget>[];

    for (final line in lines) {
      final lineHeight = height * line.flex / totalFlex;
      slots.add(
        CartazTextSlot(
          canvasSize: canvasSize,
          element: line.element,
          adjustments: textAdjustments,
          selected: _isSelected(line.element),
          left: left,
          top: lineTop,
          width: width,
          height: lineHeight,
          child: _FitTextBox(
            text: line.text,
            alignment: line.alignment,
            style: line.style,
          ),
        ),
      );
      lineTop += lineHeight;
    }

    return slots;
  }
}

class _AproveiteLineSpec {
  final CartazTextElement element;
  final String text;
  final Alignment alignment;
  final TextStyle style;
  final int flex;

  const _AproveiteLineSpec({
    required this.element,
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

String _priceWithoutCurrency(String value) {
  return value
      .replaceAll(RegExp(r'R\$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), '')
      .trim();
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
