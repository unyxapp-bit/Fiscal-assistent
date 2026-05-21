import 'package:flutter/material.dart';

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

    if (!centavosMenores || parts == null) {
      return Text(
        displayText,
        maxLines: 1,
        textAlign: textAlign,
        style: style,
      );
    }

    final baseFontSize =
        style.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 14;
    final centsStyle = style.copyWith(
      fontSize: baseFontSize * 0.5,
      letterSpacing: (style.letterSpacing ?? 0) * 0.5,
    );
    final centsLift = baseFontSize * 0.22;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: parts.reais, style: style),
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Transform.translate(
              offset: Offset(0, -centsLift),
              child: Text(
                parts.centavos,
                maxLines: 1,
                style: centsStyle,
              ),
            ),
          ),
        ],
      ),
      maxLines: 1,
      textAlign: textAlign,
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
