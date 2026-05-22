enum CartazTemplateTipo {
  proximoVencimento,
  aproveiteAgora,
  oferta,
  superOferta,
  cartazOferta,
  ofertaDoDiaTradicional,
  ofertaDoDiaMoeda,
  superOfertaPercentual,
  avisoImportante,
}

enum CartazTamanho {
  a6,
  a4,
  a3,
  a2,
}

extension CartazTamanhoExt on CartazTamanho {
  String get label {
    switch (this) {
      case CartazTamanho.a6:
        return 'A6';
      case CartazTamanho.a4:
        return 'A4';
      case CartazTamanho.a3:
        return 'A3';
      case CartazTamanho.a2:
        return 'A2';
    }
  }

  String get descricao {
    switch (this) {
      case CartazTamanho.a6:
        return 'Gôndola / prateleira';
      case CartazTamanho.a4:
        return 'Cartaz padrão da loja';
      case CartazTamanho.a3:
        return 'Ilha / ponta de gôndola';
      case CartazTamanho.a2:
        return 'Entrada / corredor';
    }
  }
}

extension CartazTemplateTipoExt on CartazTemplateTipo {
  String get label {
    switch (this) {
      case CartazTemplateTipo.proximoVencimento:
        return 'Próximo do vencimento';
      case CartazTemplateTipo.aproveiteAgora:
        return 'Aproveite agora';
      case CartazTemplateTipo.oferta:
        return 'Oferta';
      case CartazTemplateTipo.superOferta:
        return 'Super oferta';
      case CartazTemplateTipo.cartazOferta:
        return 'Cartaz oferta';
      case CartazTemplateTipo.ofertaDoDiaTradicional:
        return 'Oferta do dia tradicional';
      case CartazTemplateTipo.ofertaDoDiaMoeda:
        return 'Oferta do dia moeda';
      case CartazTemplateTipo.superOfertaPercentual:
        return 'Super oferta percentual';
      case CartazTemplateTipo.avisoImportante:
        return 'Aviso importante';
    }
  }

  bool get isInformativo => this == CartazTemplateTipo.avisoImportante;
}

class CartazFormData {
  final CartazTemplateTipo tipo;
  final CartazTamanho tamanho;
  final String tituloLinha1;
  final String tituloLinha2;
  final String subtitulo;
  final String? detalhe;
  final String preco;
  final String unidade;
  final String? validade;
  final bool centavosMenores;
  final String? precoAnterior;
  final String? precoPorMedida;
  final String? condicaoPromocao;
  final String? limiteCliente;
  final String? validadeOferta;
  final String? validadeProduto;
  final String? mensagem;

  const CartazFormData({
    required this.tipo,
    required this.tamanho,
    required this.tituloLinha1,
    required this.tituloLinha2,
    required this.subtitulo,
    this.detalhe,
    required this.preco,
    required this.unidade,
    this.validade,
    this.centavosMenores = false,
    this.precoAnterior,
    this.precoPorMedida,
    this.condicaoPromocao,
    this.limiteCliente,
    this.validadeOferta,
    this.validadeProduto,
    this.mensagem,
  });

  List<String> get linhasInformacaoPromocional {
    return [
      precoPorMedida,
      condicaoPromocao,
      limiteCliente,
      validadeOferta,
      validadeProduto,
    ].whereType<String>().map((line) => line.trim()).where((line) {
      return line.isNotEmpty;
    }).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo.name,
      'tamanho': tamanho.name,
      'tituloLinha1': tituloLinha1,
      'tituloLinha2': tituloLinha2,
      'subtitulo': subtitulo,
      'detalhe': detalhe,
      'preco': preco,
      'unidade': unidade,
      'validade': validade,
      'centavosMenores': centavosMenores,
      'precoAnterior': precoAnterior,
      'precoPorMedida': precoPorMedida,
      'condicaoPromocao': condicaoPromocao,
      'limiteCliente': limiteCliente,
      'validadeOferta': validadeOferta,
      'validadeProduto': validadeProduto,
      'mensagem': mensagem,
    };
  }

  factory CartazFormData.fromJson(Map<String, dynamic> json) {
    return CartazFormData(
      tipo: _cartazTemplateTipoFromName(
        json['tipo'] as String?,
        CartazTemplateTipo.aproveiteAgora,
      ),
      tamanho: _cartazTamanhoFromName(
        json['tamanho'] as String?,
        CartazTamanho.a6,
      ),
      tituloLinha1: json['tituloLinha1'] as String? ?? '',
      tituloLinha2: json['tituloLinha2'] as String? ?? '',
      subtitulo: json['subtitulo'] as String? ?? '',
      detalhe: json['detalhe'] as String? ?? '',
      preco: json['preco'] as String? ?? '',
      unidade: json['unidade'] as String? ?? '',
      validade: json['validade'] as String? ?? '',
      centavosMenores: json['centavosMenores'] as bool? ?? false,
      precoAnterior: json['precoAnterior'] as String? ?? '',
      precoPorMedida: json['precoPorMedida'] as String? ?? '',
      condicaoPromocao: json['condicaoPromocao'] as String? ?? '',
      limiteCliente: json['limiteCliente'] as String? ?? '',
      validadeOferta: json['validadeOferta'] as String? ?? '',
      validadeProduto: json['validadeProduto'] as String? ?? '',
      mensagem: json['mensagem'] as String? ?? '',
    );
  }
}

CartazTemplateTipo _cartazTemplateTipoFromName(
  String? name,
  CartazTemplateTipo fallback,
) {
  for (final value in CartazTemplateTipo.values) {
    if (value.name == name) return value;
  }
  return fallback;
}

CartazTamanho _cartazTamanhoFromName(
  String? name,
  CartazTamanho fallback,
) {
  for (final value in CartazTamanho.values) {
    if (value.name == name) return value;
  }
  return fallback;
}
