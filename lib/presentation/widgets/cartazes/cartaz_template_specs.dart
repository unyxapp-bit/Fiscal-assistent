import 'package:flutter/material.dart';

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

class CartazTemplateFieldHints {
  final String linha1Hint;
  final String linha2Hint;
  final String subtituloLabel;
  final String subtituloHint;
  final bool showDetalhe;
  final String detalheLabel;
  final String detalheHint;
  final bool showUnidade;
  final String unidadeHint;
  final bool showValidade;
  final String validadeHint;

  const CartazTemplateFieldHints({
    required this.linha1Hint,
    required this.linha2Hint,
    required this.subtituloLabel,
    required this.subtituloHint,
    this.showDetalhe = false,
    this.detalheLabel = 'Detalhe',
    this.detalheHint = '',
    this.showUnidade = true,
    this.unidadeHint = 'Ex: UNID.',
    this.showValidade = false,
    this.validadeHint = '',
  });
}

class CartazTemplateSpec {
  final CartazTemplateTipo tipo;
  final String title;
  final String description;
  final Color color;
  final Color iconColor;
  final IconData icon;
  final PosterTemplateAsset asset;
  final CartazTemplateFieldHints fields;

  const CartazTemplateSpec({
    required this.tipo,
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.asset,
    required this.fields,
    this.iconColor = Colors.white,
  });
}

const cartazTemplateSpecs = <CartazTemplateSpec>[
  CartazTemplateSpec(
    tipo: CartazTemplateTipo.aproveiteAgora,
    title: 'Aproveite agora',
    description: 'Promoções gerais e ofertas',
    color: Color(0xFFD6166A),
    icon: Icons.local_offer_rounded,
    asset: PosterTemplateAsset(
      path: 'templates/aproveite agora.svg',
      type: PosterTemplateAssetType.svg,
    ),
    fields: CartazTemplateFieldHints(
      linha1Hint: 'Ex: LAVA ROUPAS',
      linha2Hint: 'Ex: LIQ. CLASSE A',
      subtituloLabel: 'Peso / volume',
      subtituloHint: 'Ex: REFIL 900ML',
      showDetalhe: true,
      detalheLabel: 'Fragrância / sabor',
      detalheHint: 'Ex: FRAGRANCIAS',
      unidadeHint: 'Ex: UN',
    ),
  ),
  CartazTemplateSpec(
    tipo: CartazTemplateTipo.proximoVencimento,
    title: 'Próximo do vencimento',
    description: 'Produtos com validade próxima',
    color: Color(0xFFF4C430),
    iconColor: Colors.black,
    icon: Icons.schedule_rounded,
    asset: PosterTemplateAsset(
      path: 'templates/proximo vencimento.svg',
      type: PosterTemplateAssetType.svg,
    ),
    fields: CartazTemplateFieldHints(
      linha1Hint: 'Ex: TERERE LEAO',
      linha2Hint: 'Ex: 500G',
      subtituloLabel: 'Sabor / tipo',
      subtituloHint: 'Ex: ABACAXI',
      unidadeHint: 'Ex: UN',
    ),
  ),
  CartazTemplateSpec(
    tipo: CartazTemplateTipo.oferta,
    title: 'Oferta',
    description: 'Oferta simples com validade',
    color: Color(0xFFCC0000),
    icon: Icons.sell_rounded,
    asset: PosterTemplateAsset(
      path: 'templates/oferta.svg',
      type: PosterTemplateAssetType.svg,
    ),
    fields: CartazTemplateFieldHints(
      linha1Hint: 'Ex: BISCOITO RECHEADO',
      linha2Hint: 'Ex: DANY SABORES',
      subtituloLabel: 'Peso / volume',
      subtituloHint: 'Ex: 130G',
      showDetalhe: true,
      detalheLabel: 'Detalhe / observação',
      detalheHint: 'Ex: CADA 130 GRAMAS',
      showUnidade: false,
      showValidade: true,
      validadeHint: 'Ex: VALIDO ATE 26/04/2026',
    ),
  ),
  CartazTemplateSpec(
    tipo: CartazTemplateTipo.superOferta,
    title: 'Super oferta',
    description: 'Oferta destacada com faixa amarela',
    color: Color(0xFFE52420),
    icon: Icons.local_fire_department_rounded,
    asset: PosterTemplateAsset(
      path: 'templates/super oferta.svg',
      type: PosterTemplateAssetType.svg,
    ),
    fields: CartazTemplateFieldHints(
      linha1Hint: 'Ex: ARROZ TIO JOAO',
      linha2Hint: 'Ex: TIPO 1',
      subtituloLabel: 'Peso / volume',
      subtituloHint: 'Ex: 5KG',
      showDetalhe: true,
      detalheLabel: 'Detalhe / observacao',
      detalheHint: 'Ex: CADA UNIDADE',
      unidadeHint: 'Ex: UNID',
    ),
  ),
];

CartazTemplateSpec cartazTemplateSpec(CartazTemplateTipo tipo) {
  switch (tipo) {
    case CartazTemplateTipo.aproveiteAgora:
      return cartazTemplateSpecs[0];
    case CartazTemplateTipo.proximoVencimento:
      return cartazTemplateSpecs[1];
    case CartazTemplateTipo.oferta:
      return cartazTemplateSpecs[2];
    case CartazTemplateTipo.superOferta:
      return cartazTemplateSpecs[3];
  }
}
