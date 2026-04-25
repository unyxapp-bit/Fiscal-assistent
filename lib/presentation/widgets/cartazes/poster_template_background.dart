import 'package:flutter/widgets.dart';

import '../../../data/models/cartaz_form_data.dart';

String posterTemplateAssetPath(CartazTemplateTipo tipo) {
  switch (tipo) {
    case CartazTemplateTipo.proximoVencimento:
      return 'templates/ChatGPT Image 25 de abr. de 2026, 16_22_07.png';
    case CartazTemplateTipo.aproveiteAgora:
      return 'templates/ChatGPT Image 25 de abr. de 2026, 16_25_37.png';
    case CartazTemplateTipo.oferta:
      return 'templates/ChatGPT Image 25 de abr. de 2026, 16_34_21.png';
  }
}

class PosterTemplateBackground extends StatelessWidget {
  final CartazTemplateTipo tipo;

  const PosterTemplateBackground({
    super.key,
    required this.tipo,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      posterTemplateAssetPath(tipo),
      fit: BoxFit.fill,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.high,
      alignment: Alignment.center,
    );
  }
}
