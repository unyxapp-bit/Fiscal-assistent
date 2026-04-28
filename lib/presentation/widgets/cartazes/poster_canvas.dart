import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/cartaz_form_data.dart';

typedef PosterSafeBuilder = Widget Function(
    BuildContext context, Size safeSize);

double posterPreviewScaleFor({
  required Size posterSize,
  required BoxConstraints constraints,
  double horizontalPadding = 0,
  double verticalPadding = 0,
  double minScale = 0.08,
  double maxScale = 1.0,
}) {
  final usableWidth = math.max(1, constraints.maxWidth - horizontalPadding);
  final usableHeight = math.max(1, constraints.maxHeight - verticalPadding);
  final scaleByWidth = usableWidth / posterSize.width;
  final scaleByHeight = usableHeight / posterSize.height;

  return math.min(scaleByWidth, scaleByHeight).clamp(minScale, maxScale);
}

class PosterCanvas extends StatelessWidget {
  final CartazTamanho tamanho;
  final Color backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsets? safePadding;
  final PosterSafeBuilder builder;

  const PosterCanvas({
    super.key,
    required this.tamanho,
    required this.builder,
    this.backgroundColor = Colors.white,
    this.borderColor,
    this.borderWidth = 0,
    this.safePadding,
  });

  static Size canvasSizeFor(CartazTamanho tamanho) {
    switch (tamanho) {
      case CartazTamanho.a6:
        return const Size(420, 592);
      case CartazTamanho.a4:
        return const Size(840, 1188);
      case CartazTamanho.a3:
        return const Size(1188, 1680);
      case CartazTamanho.a2:
        return const Size(1680, 2376);
    }
  }

  static EdgeInsets safePaddingFor(CartazTamanho tamanho) {
    final size = canvasSizeFor(tamanho);
    return EdgeInsets.fromLTRB(
      size.width * 0.035,
      size.height * 0.028,
      size.width * 0.035,
      size.height * 0.028,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canvasSize = canvasSizeFor(tamanho);

    return SizedBox(
      width: canvasSize.width,
      height: canvasSize.height,
      child: ClipRect(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!, width: borderWidth),
          ),
          child: PosterSafeArea(
            tamanho: tamanho,
            padding: safePadding,
            builder: builder,
          ),
        ),
      ),
    );
  }
}

class PosterSafeArea extends StatelessWidget {
  final CartazTamanho tamanho;
  final EdgeInsets? padding;
  final PosterSafeBuilder builder;

  const PosterSafeArea({
    super.key,
    required this.tamanho,
    required this.builder,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = padding ?? PosterCanvas.safePaddingFor(tamanho);

    return Padding(
      padding: resolvedPadding,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox.expand(
              child: builder(context, constraints.biggest),
            );
          },
        ),
      ),
    );
  }
}
