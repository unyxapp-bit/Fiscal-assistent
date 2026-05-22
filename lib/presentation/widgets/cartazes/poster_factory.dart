import 'package:flutter/widgets.dart';

import '../../../data/models/cartaz_form_data.dart';
import 'cartaz_aproveite_agora_widget.dart';
import 'cartaz_aviso_importante_widget.dart';
import 'cartaz_oferta_extra_widget.dart';
import 'cartaz_oferta_widget.dart';
import 'cartaz_proximo_vencimento_widget.dart';
import 'cartaz_super_oferta_widget.dart';
import 'cartaz_text_adjustments.dart';

Widget buildPosterWidget(
  CartazFormData data, {
  CartazTextAdjustments? textAdjustments,
  CartazTextElement? selectedElement,
  bool showSelection = false,
}) {
  switch (data.tipo) {
    case CartazTemplateTipo.aproveiteAgora:
      return CartazAproveiteAgoraWidget(
        data: data,
        textAdjustments: textAdjustments,
        selectedElement: selectedElement,
        showSelection: showSelection,
      );
    case CartazTemplateTipo.proximoVencimento:
      return CartazProximoVencimentoWidget(
        data: data,
        textAdjustments: textAdjustments,
        selectedElement: selectedElement,
        showSelection: showSelection,
      );
    case CartazTemplateTipo.oferta:
      return CartazOfertaWidget(
        data: data,
        textAdjustments: textAdjustments,
        selectedElement: selectedElement,
        showSelection: showSelection,
      );
    case CartazTemplateTipo.superOferta:
      return CartazSuperOfertaWidget(
        data: data,
        textAdjustments: textAdjustments,
        selectedElement: selectedElement,
        showSelection: showSelection,
      );
    case CartazTemplateTipo.cartazOferta:
    case CartazTemplateTipo.ofertaDoDiaTradicional:
    case CartazTemplateTipo.ofertaDoDiaMoeda:
    case CartazTemplateTipo.superOfertaPercentual:
      return CartazOfertaExtraWidget(
        data: data,
        textAdjustments: textAdjustments,
        selectedElement: selectedElement,
        showSelection: showSelection,
      );
    case CartazTemplateTipo.avisoImportante:
      return CartazAvisoImportanteWidget(
        data: data,
        textAdjustments: textAdjustments,
        selectedElement: selectedElement,
        showSelection: showSelection,
      );
  }
}
