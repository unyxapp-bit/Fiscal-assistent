import 'package:flutter/material.dart';

import '../../../data/models/cartaz_form_data.dart';
import 'cartaz_text_adjustments.dart';
import 'poster_canvas.dart';
import 'poster_template_background.dart';

const _pvOrange = Color(0xFFF08A00);
const _pvRed = Color(0xFFE11A1A);

class CartazProximoVencimentoWidget extends StatelessWidget {
  final CartazFormData data;
  final CartazTextAdjustments? textAdjustments;
  final CartazTextElement? selectedElement;
  final bool showSelection;

  const CartazProximoVencimentoWidget({
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
        final priceText = _priceWithoutCurrency(data.preco);
        final canvasSize = Size(w, h);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: PosterTemplateBackground(
                tipo: CartazTemplateTipo.proximoVencimento,
              ),
            ),
            ..._buildProductSlots(canvasSize),
            if (priceText.isNotEmpty)
              CartazTextSlot(
                canvasSize: canvasSize,
                element: CartazTextElement.preco,
                adjustments: textAdjustments,
                selected: _isSelected(CartazTextElement.preco),
                left: w * 0.17,
                top: h * 0.61,
                width: w * 0.77,
                height: h * 0.305,
                scaleAlignment: Alignment.bottomLeft,
                child: _PriceLayer(
                  text: priceText,
                  color: _pvRed,
                  shadowColor: Colors.black.withAlpha(45),
                  outlineColor: Colors.white,
                ),
              ),
            if (data.unidade.trim().isNotEmpty)
              CartazTextSlot(
                canvasSize: canvasSize,
                element: CartazTextElement.unidade,
                adjustments: textAdjustments,
                selected: _isSelected(CartazTextElement.unidade),
                left: w * 0.72,
                top: h * 0.825,
                width: w * 0.23,
                height: h * 0.05,
                scaleAlignment: Alignment.bottomRight,
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

  List<Widget> _buildProductSlots(Size canvasSize) {
    final w = canvasSize.width;
    final h = canvasSize.height;
    final lines = <_ProximoLineSpec>[
      _ProximoLineSpec(
        element: CartazTextElement.tituloLinha1,
        text: data.tituloLinha1.toUpperCase(),
        alignment: Alignment.center,
        style: const TextStyle(
          fontSize: 146,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          height: 0.84,
          letterSpacing: -4.8,
        ),
        flex: 42,
      ),
      _ProximoLineSpec(
        element: CartazTextElement.tituloLinha2,
        text: data.tituloLinha2.toUpperCase(),
        alignment: Alignment.center,
        style: const TextStyle(
          fontSize: 130,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          height: 0.84,
          letterSpacing: -4.2,
        ),
        flex: 34,
      ),
      _ProximoLineSpec(
        element: CartazTextElement.subtitulo,
        text: data.subtitulo.toUpperCase(),
        alignment: Alignment.center,
        style: const TextStyle(
          fontSize: 92,
          fontWeight: FontWeight.w900,
          color: _pvOrange,
          height: 0.9,
          letterSpacing: -2.2,
        ),
        flex: 24,
      ),
    ];

    final top = h * 0.225;
    final height = h * 0.295;
    final left = w * 0.07;
    final width = w * 0.86;
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

String _priceWithoutCurrency(String value) {
  return value
      .replaceAll(RegExp(r'R\$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), '')
      .trim();
}

class _ProximoLineSpec {
  final CartazTextElement element;
  final String text;
  final Alignment alignment;
  final TextStyle style;
  final int flex;

  const _ProximoLineSpec({
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
