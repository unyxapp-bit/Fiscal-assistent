enum CartazTemplateTipo {
  proximoVencimento,
  aproveiteAgora,
  oferta,
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
      case CartazTamanho.a6: return 'A6';
      case CartazTamanho.a4: return 'A4';
      case CartazTamanho.a3: return 'A3';
      case CartazTamanho.a2: return 'A2';
    }
  }

  String get descricao {
    switch (this) {
      case CartazTamanho.a6: return 'Gôndola / prateleira';
      case CartazTamanho.a4: return 'Cartaz padrão da loja';
      case CartazTamanho.a3: return 'Ilha / ponta de gôndola';
      case CartazTamanho.a2: return 'Entrada / corredor';
    }
  }
}

extension CartazTemplateTipoExt on CartazTemplateTipo {
  String get label {
    switch (this) {
      case CartazTemplateTipo.proximoVencimento: return 'Próximo do vencimento';
      case CartazTemplateTipo.aproveiteAgora: return 'Aproveite agora';
      case CartazTemplateTipo.oferta: return 'Oferta';
    }
  }
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
  });
}
