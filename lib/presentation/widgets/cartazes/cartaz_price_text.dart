import 'package:flutter/material.dart';

import 'cartaz_text_adjustments.dart';

class CartazPriceText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final bool centavosMenores;
  final TextAlign textAlign;

  const CartazPriceText({
    super.key,
    required this.text,
    required this.style,
    this.centavosMenores = false,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = text.trim();
    final parts = _CartazPriceParts.from(displayText);
    final resolvedStyle = cartazAdjustedTextStyle(context, style);
    final resolvedTextAlign = cartazAdjustedTextAlign(context, textAlign);

    if (!centavosMenores || parts == null) {
      return Text(
        displayText,
        maxLines: 1,
        textAlign: resolvedTextAlign,
        style: resolvedStyle,
      );
    }

    final baseFontSize = resolvedStyle.fontSize ??
        DefaultTextStyle.of(context).style.fontSize ??
        14;
    final centsStyle = resolvedStyle.copyWith(
      fontSize: baseFontSize * 0.5,
      letterSpacing: (resolvedStyle.letterSpacing ?? 0) * 0.5,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          parts.reais,
          maxLines: 1,
          textAlign: resolvedTextAlign,
          style: resolvedStyle,
        ),
        Text(
          parts.centavos,
          maxLines: 1,
          textAlign: resolvedTextAlign,
          style: centsStyle,
        ),
      ],
    );
  }
}

class _CartazPriceParts {
  final String reais;
  final String centavos;

  const _CartazPriceParts({
    required this.reais,
    required this.centavos,
  });

  static _CartazPriceParts? from(String value) {
    final match = RegExp(r'^(.+)([,.]\d{1,2})$').firstMatch(value);
    if (match == null) return null;

    final reais = match.group(1);
    final centavos = match.group(2);
    if (reais == null ||
        centavos == null ||
        reais.trim().isEmpty ||
        centavos.length < 2) {
      return null;
    }

    return _CartazPriceParts(reais: reais, centavos: centavos);
  }
}
