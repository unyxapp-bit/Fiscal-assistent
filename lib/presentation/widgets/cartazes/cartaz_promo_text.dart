import 'package:flutter/material.dart';

import 'cartaz_text_adjustments.dart';

class CartazFitTextBox extends StatelessWidget {
  final String text;
  final Alignment alignment;
  final TextAlign textAlign;
  final TextStyle style;

  const CartazFitTextBox({
    super.key,
    required this.text,
    required this.alignment,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final resolvedAlignment = cartazAdjustedAlignment(context, alignment);
    final resolvedTextAlign = cartazAdjustedTextAlign(context, textAlign);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: resolvedAlignment,
      child: Text(
        text,
        maxLines: 1,
        textAlign: resolvedTextAlign,
        style: cartazAdjustedTextStyle(context, style),
      ),
    );
  }
}

class CartazPreviousPriceBox extends StatelessWidget {
  final String preco;
  final Alignment alignment;
  final TextStyle style;

  const CartazPreviousPriceBox({
    super.key,
    required this.preco,
    required this.alignment,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final displayPrice = cartazPriceWithCurrency(preco);
    if (displayPrice.isEmpty) {
      return const SizedBox.shrink();
    }

    return CartazFitTextBox(
      text: 'DE $displayPrice',
      alignment: alignment,
      style: style,
    );
  }
}

class CartazPromoInfoBox extends StatelessWidget {
  final List<String> lines;
  final Alignment alignment;
  final TextAlign textAlign;
  final TextStyle style;
  final double spacing;

  const CartazPromoInfoBox({
    super.key,
    required this.lines,
    required this.alignment,
    required this.style,
    this.textAlign = TextAlign.center,
    this.spacing = 2,
  });

  @override
  Widget build(BuildContext context) {
    final visibleLines = lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (visibleLines.isEmpty) {
      return const SizedBox.shrink();
    }

    final resolvedAlignment = cartazAdjustedAlignment(context, alignment);
    final resolvedTextAlign = cartazAdjustedTextAlign(context, textAlign);
    final resolvedStyle = cartazAdjustedTextStyle(context, style);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: resolvedAlignment,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: resolvedAlignment,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: _crossAxisAlignment(resolvedTextAlign),
                children: [
                  for (var index = 0; index < visibleLines.length; index++) ...[
                    if (index > 0) SizedBox(height: spacing),
                    Text(
                      visibleLines[index].toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      textAlign: resolvedTextAlign,
                      style: resolvedStyle,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  CrossAxisAlignment _crossAxisAlignment(TextAlign alignment) {
    switch (alignment) {
      case TextAlign.start:
      case TextAlign.left:
        return CrossAxisAlignment.start;
      case TextAlign.end:
      case TextAlign.right:
        return CrossAxisAlignment.end;
      case TextAlign.center:
      case TextAlign.justify:
        return CrossAxisAlignment.center;
    }
  }
}

String cartazPriceWithCurrency(String value) {
  final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (clean.isEmpty) return '';
  if (clean.toUpperCase().startsWith('R\$')) return clean;
  return 'R\$ $clean';
}
