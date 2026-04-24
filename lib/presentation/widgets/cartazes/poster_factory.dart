import 'package:flutter/widgets.dart';

import '../../../data/models/cartaz_form_data.dart';
import 'cartaz_aproveite_agora_widget.dart';
import 'cartaz_oferta_widget.dart';
import 'cartaz_proximo_vencimento_widget.dart';

Widget buildPosterWidget(CartazFormData data) {
  switch (data.tipo) {
    case CartazTemplateTipo.aproveiteAgora:
      return CartazAproveiteAgoraWidget(data: data);
    case CartazTemplateTipo.proximoVencimento:
      return CartazProximoVencimentoWidget(data: data);
    case CartazTemplateTipo.oferta:
      return CartazOfertaWidget(data: data);
  }
}
