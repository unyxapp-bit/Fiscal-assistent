import 'package:flutter/material.dart';

import '../../../data/models/cartaz_form_data.dart';
import 'cartaz_price_text.dart';
import 'cartaz_promo_text.dart';
import 'cartaz_text_adjustments.dart';
import 'poster_canvas.dart';
import 'poster_template_background.dart';

class CartazOfertaExtraWidget extends StatelessWidget {
  final CartazFormData data;
  final CartazTextAdjustments? textAdjustments;
  final CartazTextElement? selectedElement;
  final bool showSelection;

  const CartazOfertaExtraWidget({
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
    final layout = _layoutFor(data.tipo);

    return PosterCanvas(
      tamanho: data.tamanho,
      safePadding: EdgeInsets.zero,
      builder: (context, canvasSize) {
        final w = canvasSize.width;
        final h = canvasSize.height;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: PosterTemplateBackground(tipo: data.tipo),
            ),
            ..._buildProductSlots(canvasSize, layout),
            if ((data.precoAnterior ?? '').trim().isNotEmpty)
              CartazTextSlot(
                canvasSize: canvasSize,
                element: CartazTextElement.precoAnterior,
                adjustments: textAdjustments,
                selected: _isSelected(CartazTextElement.precoAnterior),
                left: w * layout.previousLeft,
                top: h * layout.previousTop,
                width: w * layout.previousWidth,
                height: h * layout.previousHeight,
                child: CartazPreviousPriceBox(
                  preco: data.precoAnterior!,
                  alignment: Alignment.center,
                  style: TextStyle(
                    fontSize: layout.previousFontSize,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    decoration: TextDecoration.lineThrough,
                    decorationThickness: 3,
                    height: 1,
                  ),
                ),
              ),
            CartazTextSlot(
              canvasSize: canvasSize,
              element: CartazTextElement.preco,
              adjustments: textAdjustments,
              selected: _isSelected(CartazTextElement.preco),
              left: w * layout.priceLeft,
              top: h * layout.priceTop,
              width: w * layout.priceWidth,
              height: h * layout.priceHeight,
              scaleAlignment: Alignment.centerLeft,
              child: _PriceBox(
                text: _priceWithoutCurrency(data.preco),
                centavosMenores: data.centavosMenores,
                color: layout.priceColor,
                fontSize: layout.priceFontSize,
              ),
            ),
            if (data.unidade.trim().isNotEmpty)
              CartazTextSlot(
                canvasSize: canvasSize,
                element: CartazTextElement.unidade,
                adjustments: textAdjustments,
                selected: _isSelected(CartazTextElement.unidade),
                left: w * layout.unitLeft,
                top: h * layout.unitTop,
                width: w * layout.unitWidth,
                height: h * layout.unitHeight,
                scaleAlignment: Alignment.centerLeft,
                child: CartazFitTextBox(
                  text: data.unidade.toUpperCase(),
                  alignment: Alignment.centerLeft,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: layout.unitFontSize,
                    fontWeight: FontWeight.w900,
                    color: layout.priceColor,
                    height: 1,
                  ),
                ),
              ),
            if (data.linhasInformacaoPromocional.isNotEmpty)
              CartazTextSlot(
                canvasSize: canvasSize,
                element: CartazTextElement.promocao,
                adjustments: textAdjustments,
                selected: _isSelected(CartazTextElement.promocao),
                left: w * layout.infoLeft,
                top: h * layout.infoTop,
                width: w * layout.infoWidth,
                height: h * layout.infoHeight,
                scaleAlignment: Alignment.topCenter,
                child: CartazPromoInfoBox(
                  lines: data.linhasInformacaoPromocional,
                  alignment: Alignment.topCenter,
                  style: TextStyle(
                    fontSize: layout.infoFontSize,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _buildProductSlots(Size canvasSize, _ExtraOfertaLayout layout) {
    final w = canvasSize.width;
    final h = canvasSize.height;
    final lines = <_ExtraOfertaLine>[
      _ExtraOfertaLine(
        element: CartazTextElement.tituloLinha1,
        text: data.tituloLinha1,
        fontSize: layout.titleFontSize,
        flex: 34,
      ),
      _ExtraOfertaLine(
        element: CartazTextElement.tituloLinha2,
        text: data.tituloLinha2,
        fontSize: layout.titleFontSize * 0.92,
        flex: 30,
      ),
      _ExtraOfertaLine(
        element: CartazTextElement.subtitulo,
        text: data.subtitulo,
        fontSize: layout.titleFontSize * 0.58,
        flex: 20,
      ),
      if ((data.detalhe ?? '').trim().isNotEmpty)
        _ExtraOfertaLine(
          element: CartazTextElement.detalhe,
          text: data.detalhe!,
          fontSize: layout.titleFontSize * 0.50,
          color: layout.priceColor,
          flex: 16,
        ),
    ];
    final totalFlex = lines.fold<int>(0, (sum, line) => sum + line.flex);
    var top = h * layout.productTop;
    final result = <Widget>[];

    for (final line in lines) {
      final height = h * layout.productHeight * line.flex / totalFlex;
      result.add(
        CartazTextSlot(
          canvasSize: canvasSize,
          element: line.element,
          adjustments: textAdjustments,
          selected: _isSelected(line.element),
          left: w * layout.productLeft,
          top: top,
          width: w * layout.productWidth,
          height: height,
          child: CartazFitTextBox(
            text: line.text.toUpperCase(),
            alignment: Alignment.center,
            style: TextStyle(
              fontSize: line.fontSize,
              fontWeight: FontWeight.w900,
              color: line.color ?? Colors.black,
              height: 0.90,
            ),
          ),
        ),
      );
      top += height;
    }

    return result;
  }
}

class _PriceBox extends StatelessWidget {
  final String text;
  final bool centavosMenores;
  final Color color;
  final double fontSize;

  const _PriceBox({
    required this.text,
    required this.centavosMenores,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: CartazPriceText(
          text: text,
          centavosMenores: centavosMenores,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: color,
            height: 0.84,
          ),
        ),
      ),
    );
  }
}

class _ExtraOfertaLine {
  final CartazTextElement element;
  final String text;
  final double fontSize;
  final Color? color;
  final int flex;

  const _ExtraOfertaLine({
    required this.element,
    required this.text,
    required this.fontSize,
    required this.flex,
    this.color,
  });
}

class _ExtraOfertaLayout {
  final double productLeft;
  final double productTop;
  final double productWidth;
  final double productHeight;
  final double titleFontSize;
  final double previousLeft;
  final double previousTop;
  final double previousWidth;
  final double previousHeight;
  final double previousFontSize;
  final double priceLeft;
  final double priceTop;
  final double priceWidth;
  final double priceHeight;
  final double priceFontSize;
  final Color priceColor;
  final double unitLeft;
  final double unitTop;
  final double unitWidth;
  final double unitHeight;
  final double unitFontSize;
  final double infoLeft;
  final double infoTop;
  final double infoWidth;
  final double infoHeight;
  final double infoFontSize;

  const _ExtraOfertaLayout({
    required this.productLeft,
    required this.productTop,
    required this.productWidth,
    required this.productHeight,
    required this.titleFontSize,
    required this.previousLeft,
    required this.previousTop,
    required this.previousWidth,
    required this.previousHeight,
    required this.previousFontSize,
    required this.priceLeft,
    required this.priceTop,
    required this.priceWidth,
    required this.priceHeight,
    required this.priceFontSize,
    required this.priceColor,
    required this.unitLeft,
    required this.unitTop,
    required this.unitWidth,
    required this.unitHeight,
    required this.unitFontSize,
    required this.infoLeft,
    required this.infoTop,
    required this.infoWidth,
    required this.infoHeight,
    required this.infoFontSize,
  });
}

_ExtraOfertaLayout _layoutFor(CartazTemplateTipo tipo) {
  switch (tipo) {
    case CartazTemplateTipo.cartazOferta:
      return const _ExtraOfertaLayout(
        productLeft: 0.09,
        productTop: 0.37,
        productWidth: 0.82,
        productHeight: 0.22,
        titleFontSize: 120,
        previousLeft: 0.12,
        previousTop: 0.64,
        previousWidth: 0.76,
        previousHeight: 0.045,
        previousFontSize: 46,
        priceLeft: 0.22,
        priceTop: 0.80,
        priceWidth: 0.67,
        priceHeight: 0.14,
        priceFontSize: 188,
        priceColor: Color(0xFFD52C1A),
        unitLeft: 0.67,
        unitTop: 0.91,
        unitWidth: 0.20,
        unitHeight: 0.03,
        unitFontSize: 28,
        infoLeft: 0.10,
        infoTop: 0.69,
        infoWidth: 0.80,
        infoHeight: 0.10,
        infoFontSize: 31,
      );
    case CartazTemplateTipo.ofertaDoDiaTradicional:
      return const _ExtraOfertaLayout(
        productLeft: 0.08,
        productTop: 0.30,
        productWidth: 0.84,
        productHeight: 0.17,
        titleFontSize: 108,
        previousLeft: 0.18,
        previousTop: 0.48,
        previousWidth: 0.68,
        previousHeight: 0.040,
        previousFontSize: 40,
        priceLeft: 0.18,
        priceTop: 0.52,
        priceWidth: 0.69,
        priceHeight: 0.15,
        priceFontSize: 184,
        priceColor: Color(0xFFB40000),
        unitLeft: 0.68,
        unitTop: 0.64,
        unitWidth: 0.18,
        unitHeight: 0.03,
        unitFontSize: 28,
        infoLeft: 0.10,
        infoTop: 0.70,
        infoWidth: 0.80,
        infoHeight: 0.15,
        infoFontSize: 31,
      );
    case CartazTemplateTipo.ofertaDoDiaMoeda:
      return const _ExtraOfertaLayout(
        productLeft: 0.08,
        productTop: 0.42,
        productWidth: 0.84,
        productHeight: 0.20,
        titleFontSize: 112,
        previousLeft: 0.14,
        previousTop: 0.66,
        previousWidth: 0.72,
        previousHeight: 0.042,
        previousFontSize: 42,
        priceLeft: 0.24,
        priceTop: 0.82,
        priceWidth: 0.62,
        priceHeight: 0.14,
        priceFontSize: 190,
        priceColor: Color(0xFFE60000),
        unitLeft: 0.68,
        unitTop: 0.93,
        unitWidth: 0.18,
        unitHeight: 0.03,
        unitFontSize: 28,
        infoLeft: 0.10,
        infoTop: 0.71,
        infoWidth: 0.80,
        infoHeight: 0.10,
        infoFontSize: 30,
      );
    case CartazTemplateTipo.superOfertaPercentual:
      return const _ExtraOfertaLayout(
        productLeft: 0.09,
        productTop: 0.37,
        productWidth: 0.82,
        productHeight: 0.22,
        titleFontSize: 114,
        previousLeft: 0.16,
        previousTop: 0.63,
        previousWidth: 0.68,
        previousHeight: 0.042,
        previousFontSize: 42,
        priceLeft: 0.28,
        priceTop: 0.81,
        priceWidth: 0.58,
        priceHeight: 0.14,
        priceFontSize: 190,
        priceColor: Color(0xFFFF1818),
        unitLeft: 0.68,
        unitTop: 0.93,
        unitWidth: 0.18,
        unitHeight: 0.03,
        unitFontSize: 28,
        infoLeft: 0.10,
        infoTop: 0.69,
        infoWidth: 0.80,
        infoHeight: 0.10,
        infoFontSize: 30,
      );
    case CartazTemplateTipo.proximoVencimento:
    case CartazTemplateTipo.aproveiteAgora:
    case CartazTemplateTipo.oferta:
    case CartazTemplateTipo.superOferta:
    case CartazTemplateTipo.avisoImportante:
      throw ArgumentError.value(tipo, 'tipo', 'Template nao usa layout extra');
  }
}

String _priceWithoutCurrency(String value) {
  return value
      .replaceAll(RegExp(r'R\$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), '')
      .trim();
}
