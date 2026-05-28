import 'package:flutter/material.dart';

enum CartazTextElement {
  tituloLinha1,
  tituloLinha2,
  subtitulo,
  detalhe,
  preco,
  precoAnterior,
  unidade,
  promocao,
  validade,
  mensagem,
}

enum CartazTextAlignOption {
  left,
  center,
  right,
}

class CartazFontOption {
  final String label;
  final String? family;

  const CartazFontOption({
    required this.label,
    required this.family,
  });
}

const cartazFontOptions = <CartazFontOption>[
  CartazFontOption(label: 'Padrao', family: null),
  CartazFontOption(label: 'Sans', family: 'sans-serif'),
  CartazFontOption(label: 'Serif', family: 'serif'),
  CartazFontOption(label: 'Mono', family: 'monospace'),
];

CartazTextElement? cartazTextElementFromName(String? name) {
  for (final value in CartazTextElement.values) {
    if (value.name == name) return value;
  }
  return null;
}

CartazTextAlignOption? cartazTextAlignOptionFromName(String? name) {
  for (final value in CartazTextAlignOption.values) {
    if (value.name == name) return value;
  }
  return null;
}

extension CartazTextAlignOptionExt on CartazTextAlignOption {
  TextAlign get textAlign {
    switch (this) {
      case CartazTextAlignOption.left:
        return TextAlign.left;
      case CartazTextAlignOption.center:
        return TextAlign.center;
      case CartazTextAlignOption.right:
        return TextAlign.right;
    }
  }

  IconData get icon {
    switch (this) {
      case CartazTextAlignOption.left:
        return Icons.format_align_left_rounded;
      case CartazTextAlignOption.center:
        return Icons.format_align_center_rounded;
      case CartazTextAlignOption.right:
        return Icons.format_align_right_rounded;
    }
  }
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
      case CartazTextElement.precoAnterior:
        return 'Preco anterior';
      case CartazTextElement.unidade:
        return 'Unidade';
      case CartazTextElement.promocao:
        return 'Promocao';
      case CartazTextElement.validade:
        return 'Validade';
      case CartazTextElement.mensagem:
        return 'Mensagem';
    }
  }
}

class CartazTextAdjustment {
  final Offset offset;
  final double scale;
  final int? colorValue;
  final String? fontFamily;
  final int? fontWeightValue;
  final CartazTextAlignOption? textAlign;

  const CartazTextAdjustment({
    this.offset = Offset.zero,
    this.scale = 1,
    this.colorValue,
    this.fontFamily,
    this.fontWeightValue,
    this.textAlign,
  });

  Color? get color {
    final value = colorValue;
    return value == null ? null : Color(value);
  }

  FontWeight? get fontWeight {
    switch (fontWeightValue) {
      case 400:
        return FontWeight.w400;
      case 700:
        return FontWeight.w700;
      case 900:
        return FontWeight.w900;
    }
    return null;
  }

  CartazTextAdjustment copyWith({
    Offset? offset,
    double? scale,
    int? colorValue,
    bool clearColor = false,
    String? fontFamily,
    bool clearFontFamily = false,
    int? fontWeightValue,
    bool clearFontWeight = false,
    CartazTextAlignOption? textAlign,
    bool clearTextAlign = false,
  }) {
    return CartazTextAdjustment(
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
      colorValue: clearColor ? null : colorValue ?? this.colorValue,
      fontFamily: clearFontFamily ? null : fontFamily ?? this.fontFamily,
      fontWeightValue:
          clearFontWeight ? null : fontWeightValue ?? this.fontWeightValue,
      textAlign: clearTextAlign ? null : textAlign ?? this.textAlign,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'dx': offset.dx,
      'dy': offset.dy,
      'scale': scale,
    };
    if (colorValue != null) json['color'] = colorValue;
    if ((fontFamily ?? '').trim().isNotEmpty) {
      json['fontFamily'] = fontFamily;
    }
    if (fontWeightValue != null) json['fontWeight'] = fontWeightValue;
    if (textAlign != null) json['textAlign'] = textAlign!.name;
    return json;
  }

  factory CartazTextAdjustment.fromJson(Map<String, dynamic> json) {
    return CartazTextAdjustment(
      offset: Offset(
        _doubleFromJson(json['dx'], 0),
        _doubleFromJson(json['dy'], 0),
      ),
      scale: _doubleFromJson(json['scale'], 1),
      colorValue: _intFromJson(json['color']),
      fontFamily: json['fontFamily'] as String?,
      fontWeightValue: _intFromJson(json['fontWeight']),
      textAlign: cartazTextAlignOptionFromName(json['textAlign'] as String?),
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

int? _intFromJson(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

CartazTextAdjustment cartazTextAdjustmentFor(
  CartazTextAdjustments? adjustments,
  CartazTextElement element,
) {
  return adjustments?[element] ?? const CartazTextAdjustment();
}

class CartazTextStyleScope extends InheritedWidget {
  final CartazTextAdjustment adjustment;

  const CartazTextStyleScope({
    super.key,
    required this.adjustment,
    required super.child,
  });

  static CartazTextAdjustment? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CartazTextStyleScope>()
        ?.adjustment;
  }

  @override
  bool updateShouldNotify(CartazTextStyleScope oldWidget) {
    return adjustment != oldWidget.adjustment;
  }
}

TextStyle cartazAdjustedTextStyle(BuildContext context, TextStyle base) {
  final adjustment = CartazTextStyleScope.maybeOf(context);
  if (adjustment == null) return base;

  var style = base;
  final family = (adjustment.fontFamily ?? '').trim();
  if (family.isNotEmpty) {
    style = style.copyWith(fontFamily: family);
  }

  final fontWeight = adjustment.fontWeight;
  if (fontWeight != null) {
    style = style.copyWith(fontWeight: fontWeight);
  }

  final color = adjustment.color;
  if (color != null && style.foreground == null) {
    style = style.copyWith(color: color);
  }

  return style;
}

TextAlign cartazAdjustedTextAlign(
  BuildContext context,
  TextAlign fallback,
) {
  return CartazTextStyleScope.maybeOf(context)?.textAlign?.textAlign ??
      fallback;
}

Alignment cartazAdjustedAlignment(
  BuildContext context,
  Alignment fallback,
) {
  final textAlign = CartazTextStyleScope.maybeOf(context)?.textAlign;
  if (textAlign == null) return fallback;

  switch (textAlign) {
    case CartazTextAlignOption.left:
      return Alignment(-1, fallback.y);
    case CartazTextAlignOption.center:
      return Alignment(0, fallback.y);
    case CartazTextAlignOption.right:
      return Alignment(1, fallback.y);
  }
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
      child: CartazTextStyleScope(
        adjustment: adjustment,
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
      ),
    );
  }
}
