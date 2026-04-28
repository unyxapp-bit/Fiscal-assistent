import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/models/cartaz_form_data.dart';
import 'cartaz_template_specs.dart';

PosterTemplateAsset posterTemplateAsset(CartazTemplateTipo tipo) {
  return cartazTemplateSpec(tipo).asset;
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
