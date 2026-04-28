import 'package:flutter/material.dart';

enum CartazTextElement {
  tituloLinha1,
  tituloLinha2,
  subtitulo,
  detalhe,
  preco,
  unidade,
  validade,
}

extension CartazTextElementLabel on CartazTextElement {
  String get label {
    switch (this) {
      case CartazTextElement.tituloLinha1:
        return 'Linha 1';
      case CartazTextElement.tituloLinha2:
        return 'Linha 2';
      case CartazTextElement.subtitulo:
        return 'Subtitulo';
      case CartazTextElement.detalhe:
        return 'Detalhe';
      case CartazTextElement.preco:
        return 'Preco';
      case CartazTextElement.unidade:
        return 'Unidade';
      case CartazTextElement.validade:
        return 'Validade';
    }
  }
}

class CartazTextAdjustment {
  final Offset offset;
  final double scale;

  const CartazTextAdjustment({
    this.offset = Offset.zero,
    this.scale = 1,
  });

  CartazTextAdjustment copyWith({
    Offset? offset,
    double? scale,
  }) {
    return CartazTextAdjustment(
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
    );
  }
}

typedef CartazTextAdjustments = Map<CartazTextElement, CartazTextAdjustment>;

CartazTextAdjustment cartazTextAdjustmentFor(
  CartazTextAdjustments? adjustments,
  CartazTextElement element,
) {
  return adjustments?[element] ?? const CartazTextAdjustment();
}

class CartazTextSlot extends StatelessWidget {
  final Size canvasSize;
  final CartazTextElement element;
  final CartazTextAdjustments? adjustments;
  final bool selected;
  final double left;
  final double top;
  final double width;
  final double height;
  final Alignment scaleAlignment;
  final Widget child;

  const CartazTextSlot({
    super.key,
    required this.canvasSize,
    required this.element,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.child,
    this.adjustments,
    this.selected = false,
    this.scaleAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final adjustment = cartazTextAdjustmentFor(adjustments, element);

    return Positioned(
      left: left + adjustment.offset.dx * canvasSize.width,
      top: top + adjustment.offset.dy * canvasSize.height,
      width: width,
      height: height,
      child: Transform.scale(
        scale: adjustment.scale,
        alignment: scaleAlignment,
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            child,
            if (selected)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF1565C0),
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
