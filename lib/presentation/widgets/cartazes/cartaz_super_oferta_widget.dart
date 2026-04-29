import 'package:flutter/material.dart';

import '../../../data/models/cartaz_form_data.dart';
import 'cartaz_text_adjustments.dart';
import 'poster_canvas.dart';
import 'poster_template_background.dart';

const _soRed = Color(0xFFE52420);

class CartazSuperOfertaWidget extends StatelessWidget {
  final CartazFormData data;
  final CartazTextAdjustments? textAdjustments;
  final CartazTextElement? selectedElement;
  final bool showSelection;

  const CartazSuperOfertaWidget({
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
        final detalhe = (data.detalhe ?? '').trim();
        final priceText = _priceWithoutCurrency(data.preco);
        final canvasSize = Size(w, h);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: PosterTemplateBackground(
                tipo: CartazTemplateTipo.superOferta,
              ),
            ),
            ..._buildProductSlots(canvasSize, detalhe),
            if (priceText.isNotEmpty)
              CartazTextSlot(
                canvasSize: canvasSize,
                element: CartazTextElement.preco,
                adjustments: textAdjustments,
                selected: _isSelected(CartazTextElement.preco),
                left: w * 0.08,
                top: h * 0.565,
                width: w * 0.84,
                height: h * 0.29,
                scaleAlignment: Alignment.center,
                child: _SuperOfertaPriceGroup(text: priceText),
              ),
            if (data.unidade.trim().isNotEmpty)
              CartazTextSlot(
                canvasSize: canvasSize,
                element: CartazTextElement.unidade,
                adjustments: textAdjustments,
                selected: _isSelected(CartazTextElement.unidade),
                left: w * 0.66,
                top: h * 0.80,
                width: w * 0.24,
                height: h * 0.045,
                scaleAlignment: Alignment.bottomRight,
                child: _FitTextBox(
                  text: data.unidade.toUpperCase(),
                  alignment: Alignment.bottomRight,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _buildProductSlots(Size canvasSize, String detalhe) {
    final w = canvasSize.width;
    final h = canvasSize.height;
    final lines = <_SuperOfertaLineSpec>[
      _SuperOfertaLineSpec(
        element: CartazTextElement.tituloLinha1,
        text: data.tituloLinha1.toUpperCase(),
        alignment: Alignment.center,
        style: const TextStyle(
          fontSize: 128,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          height: 0.86,
        ),
        flex: detalhe.isEmpty ? 39 : 34,
      ),
      _SuperOfertaLineSpec(
        element: CartazTextElement.tituloLinha2,
        text: data.tituloLinha2.toUpperCase(),
        alignment: Alignment.center,
        style: const TextStyle(
          fontSize: 122,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          height: 0.86,
        ),
        flex: detalhe.isEmpty ? 36 : 31,
      ),
      _SuperOfertaLineSpec(
        element: CartazTextElement.subtitulo,
        text: data.subtitulo.toUpperCase(),
        alignment: Alignment.center,
        style: const TextStyle(
          fontSize: 76,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          height: 0.9,
        ),
        flex: detalhe.isEmpty ? 25 : 18,
      ),
      if (detalhe.isNotEmpty)
        _SuperOfertaLineSpec(
          element: CartazTextElement.detalhe,
          text: detalhe.toUpperCase(),
          alignment: Alignment.center,
          style: const TextStyle(
            fontSize: 54,
            fontWeight: FontWeight.w900,
            color: _soRed,
            height: 0.9,
          ),
          flex: 17,
        ),
    ];

    final top = h * 0.205;
    final height = detalhe.isEmpty ? h * 0.265 : h * 0.31;
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

class _SuperOfertaLineSpec {
  final CartazTextElement element;
  final String text;
  final Alignment alignment;
  final TextStyle style;
  final int flex;

  const _SuperOfertaLineSpec({
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

class _SuperOfertaPriceGroup extends StatelessWidget {
  final String text;

  const _SuperOfertaPriceGroup({required this.text});

  @override
  Widget build(BuildContext context) {
    final displayText = text.trim();

    if (displayText.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: h * 0.15,
              width: w * 0.20,
              height: h * 0.25,
              child: const _OutlinedTextBox(
                text: 'R\$',
                fontSize: 82,
                strokeWidth: 4,
                alignment: Alignment.bottomLeft,
              ),
            ),
            Positioned(
              left: w * 0.15,
              top: 0,
              width: w * 0.85,
              height: h * 0.88,
              child: _OutlinedTextBox(
                text: displayText,
                fontSize: 198,
                strokeWidth: 8,
                alignment: Alignment.topLeft,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OutlinedTextBox extends StatelessWidget {
  final String text;
  final double fontSize;
  final double strokeWidth;
  final Alignment alignment;

  const _OutlinedTextBox({
    required this.text,
    required this.fontSize,
    required this.strokeWidth,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Stack(
          children: [
            Transform.translate(
              offset: const Offset(5, 7),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withAlpha(45),
                  height: 0.82,
                ),
              ),
            ),
            Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                height: 0.82,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = strokeWidth
                  ..color = Colors.white,
              ),
            ),
            Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: _soRed,
                height: 0.82,
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
