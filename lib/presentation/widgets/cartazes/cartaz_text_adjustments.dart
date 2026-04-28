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

CartazTextElement? cartazTextElementFromName(String? name) {
  for (final value in CartazTextElement.values) {
    if (value.name == name) return value;
  }
  return null;
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

  Map<String, dynamic> toJson() {
    return {
      'dx': offset.dx,
      'dy': offset.dy,
      'scale': scale,
    };
  }

  factory CartazTextAdjustment.fromJson(Map<String, dynamic> json) {
    return CartazTextAdjustment(
      offset: Offset(
        _doubleFromJson(json['dx'], 0),
        _doubleFromJson(json['dy'], 0),
      ),
      scale: _doubleFromJson(json['scale'], 1),
    );
  }
}

typedef CartazTextAdjustments = Map<CartazTextElement, CartazTextAdjustment>;

Map<String, dynamic> cartazTextAdjustmentsToJson(
  CartazTextAdjustments adjustments,
) {
  return {
    for (final entry in adjustments.entries)
      entry.key.name: entry.value.toJson(),
  };
}

CartazTextAdjustments cartazTextAdjustmentsFromJson(dynamic value) {
  if (value is! Map) return {};

  final adjustments = <CartazTextElement, CartazTextAdjustment>{};
  for (final entry in value.entries) {
    final element = cartazTextElementFromName(entry.key as String?);
    final rawAdjustment = entry.value;
    if (element == null || rawAdjustment is! Map) continue;

    adjustments[element] = CartazTextAdjustment.fromJson(
      Map<String, dynamic>.from(rawAdjustment),
    );
  }

  return adjustments;
}

double _doubleFromJson(dynamic value, double fallback) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

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
