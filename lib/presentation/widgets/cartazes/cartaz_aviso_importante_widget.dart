import 'package:flutter/material.dart';

import '../../../data/models/cartaz_form_data.dart';
import 'cartaz_promo_text.dart';
import 'cartaz_text_adjustments.dart';
import 'poster_canvas.dart';
import 'poster_template_background.dart';

class CartazAvisoImportanteWidget extends StatelessWidget {
  final CartazFormData data;
  final CartazTextAdjustments? textAdjustments;
  final CartazTextElement? selectedElement;
  final bool showSelection;

  const CartazAvisoImportanteWidget({
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
      builder: (context, canvasSize) {
        final w = canvasSize.width;
        final h = canvasSize.height;
        final message = (data.mensagem ?? '').trim();
        final detalhe = (data.detalhe ?? '').trim();

        return Stack(
          children: [
            const Positioned.fill(
              child: PosterTemplateBackground(
                tipo: CartazTemplateTipo.avisoImportante,
              ),
            ),
            CartazTextSlot(
              canvasSize: canvasSize,
              element: CartazTextElement.mensagem,
              adjustments: textAdjustments,
              selected: _isSelected(CartazTextElement.mensagem),
              left: w * 0.10,
              top: h * 0.36,
              width: w * 0.80,
              height: h * 0.34,
              scaleAlignment: Alignment.center,
              child: _NoticeMessage(text: message),
            ),
            if (detalhe.isNotEmpty)
              CartazTextSlot(
                canvasSize: canvasSize,
                element: CartazTextElement.detalhe,
                adjustments: textAdjustments,
                selected: _isSelected(CartazTextElement.detalhe),
                left: w * 0.13,
                top: h * 0.73,
                width: w * 0.74,
                height: h * 0.10,
                child: CartazFitTextBox(
                  text: detalhe.toUpperCase(),
                  alignment: Alignment.center,
                  style: const TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC72D2D),
                    height: 1,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NoticeMessage extends StatelessWidget {
  final String text;

  const _NoticeMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Text(
                text.toUpperCase(),
                maxLines: 5,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 78,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  height: 1.05,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
