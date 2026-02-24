import 'package:flutter/material.dart';

/// Tipos de caixa (PDV) disponíveis
enum TipoCaixa {
  rapido('Caixa Rápido', '15 volumes', Color(0xFF4CAF50), Icons.flash_on),
  normal('Caixa Normal', 'Sem limite', Color(0xFF2196F3), Icons.shopping_cart),
  self('Self Checkout', 'Autoatendimento', Color(0xFF9C27B0), Icons.computer);

  const TipoCaixa(this.nome, this.descricao, this.cor, this.icone);

  final String nome;
  final String descricao;
  final Color cor;
  final IconData icone;

  /// Converte string para enum
  static TipoCaixa fromString(String value) {
    switch (value.toLowerCase()) {
      case 'rapido':
        return TipoCaixa.rapido;
      case 'normal':
        return TipoCaixa.normal;
      case 'self':
      case 'self_service':
      case 'selfcheckout':
        return TipoCaixa.self;
      default:
        // Fallback para não crashar com valores desconhecidos do banco
        return TipoCaixa.normal;
    }
  }

  /// Converte enum para string para salvar no banco
  String toJson() => name;

  /// Verifica se é caixa rápido
  bool get isRapido => this == TipoCaixa.rapido;

  /// Verifica se é self checkout
  bool get isSelf => this == TipoCaixa.self;

  /// Retorna limite de volumes (null = sem limite)
  int? get limiteVolumes => isRapido ? 15 : null;
}
