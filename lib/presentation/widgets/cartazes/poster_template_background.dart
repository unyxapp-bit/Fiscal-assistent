import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/models/cartaz_form_data.dart';

enum PosterTemplateAssetType {
  raster,
  svg,
}

class PosterTemplateAsset {
  final String path;
  final PosterTemplateAssetType type;

  const PosterTemplateAsset({
    required this.path,
    required this.type,
  });
}

PosterTemplateAsset posterTemplateAsset(CartazTemplateTipo tipo) {
  switch (tipo) {
    case CartazTemplateTipo.proximoVencimento:
      return const PosterTemplateAsset(
        path: 'templates/proximo vencimento.svg',
        type: PosterTemplateAssetType.svg,
      );
    case CartazTemplateTipo.aproveiteAgora:
      return const PosterTemplateAsset(
        path: 'templates/aproveite agora.svg',
        type: PosterTemplateAssetType.svg,
      );
    case CartazTemplateTipo.oferta:
      return const PosterTemplateAsset(
        path: 'templates/oferta.svg',
        type: PosterTemplateAssetType.svg,
      );
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
    final asset = posterTemplateAsset(tipo);

    switch (asset.type) {
      case PosterTemplateAssetType.raster:
        return Image.asset(
          asset.path,
          fit: BoxFit.fill,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.high,
          alignment: Alignment.center,
        );
      case PosterTemplateAssetType.svg:
        return SvgPicture.asset(
          asset.path,
          fit: BoxFit.fill,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
        );
    }
  }
}
