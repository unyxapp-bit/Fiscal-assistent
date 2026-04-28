import 'package:flutter/material.dart';

import '../../../data/models/cartaz_form_data.dart';
import 'cartaz_text_adjustments.dart';
import 'poster_canvas.dart';
import 'poster_template_background.dart';

const _ofRed = Color(0xFFD61E1E);

class CartazOfertaWidget extends StatelessWidget {
  final CartazFormData data;
  final CartazTextAdjustments? textAdjustments;
  final CartazTextElement? selectedElement;
  final bool showSelection;

  const CartazOfertaWidget({
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
        final validade = (data.validade ?? '').trim();
        final hasDetalhe = detalhe.isNotEmpty;
        final preco = _priceWithoutCurrency(data.preco);
        final canvasSize = Size(w, h);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: PosterTemplateBackground(
                tipo: CartazTemplateTipo.oferta,
              ),
            ),
            ..._buildProductSlots(canvasSize, hasDetalhe),
            if (detalhe.isNotEmpty)
              CartazTextSlot(
                canvasSize: canvasSize,
                element: CartazTextElement.detalhe,
                adjustments: textAdjustments,
                selected: _isSelected(CartazTextElement.detalhe),
                left: w * 0.14,
                top: h * 0.525,
                width: w * 0.72,
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
            CartazTextSlot(
              canvasSize: canvasSize,
              element: CartazTextElement.preco,
              adjustments: textAdjustments,
              selected: _isSelected(CartazTextElement.preco),
              left: w * 0.21,
              top: h * 0.625,
              width: w * 0.71,
              height: h * 0.27,
              scaleAlignment: Alignment.topCenter,
              child: _OfferPriceLayer(text: preco),
            ),
            if (data.unidade.trim().isNotEmpty)
              CartazTextSlot(
                canvasSize: canvasSize,
                element: CartazTextElement.unidade,
                adjustments: textAdjustments,
                selected: _isSelected(CartazTextElement.unidade),
                left: w * 0.32,
                top: h * 0.843,
                width: w * 0.36,
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
              CartazTextSlot(
                canvasSize: canvasSize,
                element: CartazTextElement.validade,
                adjustments: textAdjustments,
                selected: _isSelected(CartazTextElement.validade),
                left: w * 0.06,
                top: h * 0.956,
                width: w * 0.88,
                height: h * 0.032,
                scaleAlignment: Alignment.bottomCenter,
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

  List<Widget> _buildProductSlots(Size canvasSize, bool hasDetalhe) {
    final w = canvasSize.width;
    final h = canvasSize.height;
    final lines = <_OfertaLineSpec>[
      _OfertaLineSpec(
        element: CartazTextElement.tituloLinha1,
        text: data.tituloLinha1.toUpperCase(),
        alignment: Alignment.center,
        style: const TextStyle(
          fontSize: 124,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          height: 0.86,
          letterSpacing: -3.2,
        ),
        flex: 32,
      ),
      _OfertaLineSpec(
        element: CartazTextElement.tituloLinha2,
        text: data.tituloLinha2.toUpperCase(),
        alignment: Alignment.center,
        style: const TextStyle(
          fontSize: 122,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          height: 0.86,
          letterSpacing: -3.0,
        ),
        flex: 32,
      ),
      _OfertaLineSpec(
        element: CartazTextElement.subtitulo,
        text: data.subtitulo.toUpperCase(),
        alignment: Alignment.center,
        style: const TextStyle(
          fontSize: 74,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          height: 0.9,
          letterSpacing: -2.2,
        ),
        flex: 18,
      ),
    ];

    final top = h * 0.245;
    final height = hasDetalhe ? h * 0.25 : h * 0.30;
    final left = w * 0.10;
    final width = w * 0.80;
    const totalFlex = 100;
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

class _OfertaLineSpec {
  final CartazTextElement element;
  final String text;
  final Alignment alignment;
  final TextStyle style;
  final int flex;

  const _OfertaLineSpec({
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
