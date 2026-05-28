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
  final bool showProduto;
  final bool requiresPreco;
  final bool showPromotionFields;
  final bool showDetalhe;
  final String detalheLabel;
  final String detalheHint;
  final bool showUnidade;
  final String unidadeHint;
  final bool showValidade;
  final String validadeHint;
  final bool showMensagem;
  final String mensagemLabel;
  final String mensagemHint;

  const CartazTemplateFieldHints({
    required this.linha1Hint,
    required this.linha2Hint,
    required this.subtituloLabel,
    required this.subtituloHint,
    this.showProduto = true,
    this.requiresPreco = true,
    this.showPromotionFields = true,
    this.showDetalhe = false,
    this.detalheLabel = 'Detalhe',
    this.detalheHint = '',
    this.showUnidade = true,
    this.unidadeHint = 'Ex: UNID.',
    this.showValidade = false,
    this.validadeHint = '',
    this.showMensagem = false,
    this.mensagemLabel = 'Mensagem',
    this.mensagemHint = '',
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
  final bool showInPicker;

  const CartazTemplateSpec({
    required this.tipo,
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.asset,
    required this.fields,
    this.iconColor = Colors.white,
    this.showInPicker = true,
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
  CartazTemplateSpec(
    tipo: CartazTemplateTipo.cartazOferta,
    title: 'Cartaz oferta',
    description: 'Oferta com faixa vermelha e preco em destaque',
    color: Color(0xFFD52C1A),
    icon: Icons.campaign_rounded,
    asset: PosterTemplateAsset(
      path: 'templates/Cartaz Oferta.svg',
      type: PosterTemplateAssetType.svg,
    ),
    fields: CartazTemplateFieldHints(
      linha1Hint: 'Ex: CAFE TORRADO',
      linha2Hint: 'Ex: MARCA DA CASA',
      subtituloLabel: 'Peso / volume',
      subtituloHint: 'Ex: 500G',
      showDetalhe: true,
      detalheLabel: 'Sabor / observacao',
      detalheHint: 'Ex: TRADICIONAL',
      unidadeHint: 'Ex: UN',
    ),
  ),
  CartazTemplateSpec(
    tipo: CartazTemplateTipo.ofertaDoDiaTradicional,
    title: 'Oferta do dia tradicional',
    description: 'Oferta do dia com selo de promocao',
    color: Color(0xFFB40000),
    icon: Icons.today_rounded,
    asset: PosterTemplateAsset(
      path: 'templates/Oferta do Dia Tradicional.svg',
      type: PosterTemplateAssetType.svg,
    ),
    fields: CartazTemplateFieldHints(
      linha1Hint: 'Ex: LEITE INTEGRAL',
      linha2Hint: 'Ex: MARCA FAVORITA',
      subtituloLabel: 'Peso / volume',
      subtituloHint: 'Ex: 1L',
      showDetalhe: true,
      detalheLabel: 'Detalhe',
      detalheHint: 'Ex: CADA UNIDADE',
      unidadeHint: 'Ex: UN',
    ),
  ),
  CartazTemplateSpec(
    tipo: CartazTemplateTipo.ofertaDoDiaMoeda,
    title: 'Oferta do dia moeda',
    description: 'Oferta do dia com moeda decorativa',
    color: Color(0xFFE60000),
    icon: Icons.monetization_on_rounded,
    asset: PosterTemplateAsset(
      path: 'templates/Cartaz oferta do dua.svg',
      type: PosterTemplateAssetType.svg,
    ),
    fields: CartazTemplateFieldHints(
      linha1Hint: 'Ex: REFRIGERANTE',
      linha2Hint: 'Ex: COLA ZERO',
      subtituloLabel: 'Peso / volume',
      subtituloHint: 'Ex: 2L',
      showDetalhe: true,
      detalheLabel: 'Detalhe',
      detalheHint: 'Ex: GELADO',
      unidadeHint: 'Ex: UN',
    ),
  ),
  CartazTemplateSpec(
    tipo: CartazTemplateTipo.superOfertaPercentual,
    title: 'Super oferta percentual',
    description: 'Super oferta com selo de desconto',
    color: Color(0xFFE41212),
    icon: Icons.percent_rounded,
    asset: PosterTemplateAsset(
      path: 'templates/Oferta (2).svg',
      type: PosterTemplateAssetType.svg,
    ),
    fields: CartazTemplateFieldHints(
      linha1Hint: 'Ex: SABAO EM PO',
      linha2Hint: 'Ex: LAVA BEM',
      subtituloLabel: 'Peso / volume',
      subtituloHint: 'Ex: 1,6KG',
      showDetalhe: true,
      detalheLabel: 'Detalhe',
      detalheHint: 'Ex: LEVE MAIS',
      unidadeHint: 'Ex: UN',
    ),
  ),
  CartazTemplateSpec(
    tipo: CartazTemplateTipo.carrosselPlus,
    title: 'Carrossel Plus',
    description: 'Oferta exclusiva para clientes do app',
    color: Color(0xFFFFC400),
    iconColor: Color(0xFF052F8D),
    icon: Icons.smartphone_rounded,
    asset: PosterTemplateAsset(
      path: 'templates/carrossel plus.svg',
      type: PosterTemplateAssetType.svg,
    ),
    fields: CartazTemplateFieldHints(
      linha1Hint: 'Ex: ARROZ TIPO 1',
      linha2Hint: 'Ex: CARROSSEL',
      subtituloLabel: 'Peso / volume',
      subtituloHint: 'Ex: PACOTE 5KG',
      showDetalhe: true,
      detalheLabel: 'Detalhe',
      detalheHint: 'Ex: CLIENTE APP',
      unidadeHint: 'Ex: UNID',
    ),
  ),
  CartazTemplateSpec(
    tipo: CartazTemplateTipo.avisoImportante,
    title: 'Aviso importante',
    description: 'Cartaz informativo com mensagem livre',
    color: Color(0xFFC72D2D),
    icon: Icons.notifications_active_rounded,
    asset: PosterTemplateAsset(
      path: 'templates/Aviso Importante.svg',
      type: PosterTemplateAssetType.svg,
    ),
    fields: CartazTemplateFieldHints(
      linha1Hint: '',
      linha2Hint: '',
      subtituloLabel: '',
      subtituloHint: '',
      showProduto: false,
      requiresPreco: false,
      showPromotionFields: false,
      showDetalhe: true,
      detalheLabel: 'Complemento',
      detalheHint: 'Ex: Procure um colaborador para ajuda',
      showUnidade: false,
      showMensagem: true,
      mensagemLabel: 'Mensagem principal *',
      mensagemHint: 'Ex: ATENCAO: BALCAO FECHADO PARA LIMPEZA',
    ),
  ),
  CartazTemplateSpec(
    tipo: CartazTemplateTipo.diaD,
    title: 'Dia D',
    description: 'Promoção impactante com visual chamativo',
    color: Color(0xFF1A1A1A),
    icon: Icons.calendar_today_rounded,
    asset: PosterTemplateAsset(
      path: 'templates/dia_d.svg',
      type: PosterTemplateAssetType.svg,
    ),
    fields: CartazTemplateFieldHints(
      linha1Hint: 'Ex: GRANDE OFERTA',
      linha2Hint: 'Ex: DO DIA',
      subtituloLabel: 'Produto',
      subtituloHint: 'Ex: TODOS OS PRODUTOS',
      showDetalhe: true,
      detalheLabel: 'Detalhe',
      detalheHint: 'Ex: DESCONTO ATE 50%',
      showPromotionFields: true,
      unidadeHint: 'Ex: UNID',
    ),
  ),
  CartazTemplateSpec(
    tipo: CartazTemplateTipo.templateImportado,
    title: 'Template importado',
    description: 'Fundo SVG escolhido no dispositivo',
    color: Color(0xFF374151),
    icon: Icons.upload_file_rounded,
    asset: PosterTemplateAsset(
      path: 'templates/oferta.svg',
      type: PosterTemplateAssetType.svg,
    ),
    fields: CartazTemplateFieldHints(
      linha1Hint: 'Ex: PRODUTO EM DESTAQUE',
      linha2Hint: 'Ex: MARCA / LINHA',
      subtituloLabel: 'Complemento',
      subtituloHint: 'Ex: 500G',
      showDetalhe: true,
      detalheLabel: 'Detalhe',
      detalheHint: 'Ex: OFERTA ESPECIAL',
      showPromotionFields: true,
      showValidade: true,
      validadeHint: 'Ex: OFERTA VALIDA ATE 30/05',
      unidadeHint: 'Ex: UNID',
    ),
    showInPicker: false,
  ),
];

CartazTemplateSpec cartazTemplateSpec(CartazTemplateTipo tipo) {
  return cartazTemplateSpecs.firstWhere((spec) => spec.tipo == tipo);
}
