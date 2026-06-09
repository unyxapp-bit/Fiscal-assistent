import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/models/cartaz_form_data.dart';
import 'cartaz_template_specs.dart';

PosterTemplateAsset posterTemplateAsset(CartazTemplateTipo tipo) {
  return cartazTemplateSpec(tipo).asset;
}

class PosterTemplateBackground extends StatelessWidget {
  final CartazTemplateTipo tipo;
  final String? customSvg;

  const PosterTemplateBackground({
    super.key,
    required this.tipo,
    this.customSvg,
  });

  @override
  Widget build(BuildContext context) {
    final svg = (customSvg ?? '').trim();
    if (svg.isNotEmpty) {
      return SvgPicture.string(
        svg,
        fit: BoxFit.fill,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        placeholderBuilder: (_) => const _TemplateLoadingBackground(),
        errorBuilder: (_, __, ___) => _TemplateFallbackBackground(tipo: tipo),
      );
    }

    final asset = posterTemplateAsset(tipo);

    switch (asset.type) {
      case PosterTemplateAssetType.generated:
        return const _ProximoVencimentoTemplateBackground();
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
          placeholderBuilder: (_) => const _TemplateLoadingBackground(),
          errorBuilder: (_, __, ___) => _TemplateFallbackBackground(tipo: tipo),
        );
    }
  }
}

class _TemplateLoadingBackground extends StatelessWidget {
  const _TemplateLoadingBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _TemplateFallbackBackground extends StatelessWidget {
  final CartazTemplateTipo tipo;

  const _TemplateFallbackBackground({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final spec = cartazTemplateSpec(tipo);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.color.withValues(alpha: 0.10),
        border: Border.all(color: spec.color.withValues(alpha: 0.24)),
      ),
      child: Center(
        child: Icon(
          spec.icon,
          color: spec.color,
          size: 42,
        ),
      ),
    );
  }
}

class _ProximoVencimentoTemplateBackground extends StatelessWidget {
  const _ProximoVencimentoTemplateBackground();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFFFFF6D7)),
            ),
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: h * 0.20,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFF4C430)),
              ),
            ),
            Positioned(
              left: 0,
              top: h * 0.162,
              right: 0,
              height: h * 0.037,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFF08A00)),
              ),
            ),
            Positioned(
              left: w * 0.055,
              top: h * 0.225,
              right: w * 0.055,
              height: h * 0.014,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFE11A1A),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Positioned(
              left: w * 0.074,
              top: h * 0.240,
              right: w * 0.074,
              height: h * 0.318,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(w * 0.043),
                  border: Border.all(
                    color: const Color(0xFFF08A00),
                    width: w * 0.012,
                  ),
                ),
              ),
            ),
            Positioned(
              left: w * 0.067,
              top: h * 0.595,
              right: w * 0.067,
              bottom: h * 0.078,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(w * 0.048),
                  border: Border.all(
                    color: const Color(0xFFE11A1A),
                    width: w * 0.014,
                  ),
                ),
              ),
            ),
            Positioned(
              left: w * 0.10,
              right: w * 0.10,
              bottom: h * 0.024,
              height: h * 0.041,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4C430),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    'CONSULTE A VALIDADE NA EMBALAGEM',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: w * 0.034,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: w * 0.057,
              top: h * 0.034,
              width: w * 0.134,
              height: w * 0.134,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFFE11A1A),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: w * 0.088,
                    height: w * 0.088,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF6D7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      color: const Color(0xFFE11A1A),
                      size: w * 0.062,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: w * 0.22,
              top: h * 0.050,
              right: w * 0.04,
              child: Text(
                'PROXIMO DO',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: w * 0.073,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              left: w * 0.22,
              top: h * 0.108,
              right: w * 0.04,
              child: Text(
                'VENCIMENTO',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFFE11A1A),
                  fontSize: w * 0.087,
                  fontWeight: FontWeight.w900,
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
