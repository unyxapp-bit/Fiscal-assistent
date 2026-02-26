import 'package:flutter/material.dart';

/// Tipos de caixa (PDV) disponíveis
enum TipoCaixa {
  normal(
    'Caixa Normal',
    'Sem limite de volumes',
    Color(0xFF2196F3),
    Icons.shopping_cart,
  ),
  rapido(
    'Caixa Rápido',
    'Até 15 volumes',
    Color(0xFF4CAF50),
    Icons.flash_on,
  ),
  preferencial(
    'Preferencial',
    'Idosos, gestantes e PCD',
    Color(0xFFFF9800),
    Icons.accessible_forward,
  ),
  self(
    'Self Checkout',
    'Autoatendimento',
    Color(0xFF9C27B0),
    Icons.computer,
  );

  const TipoCaixa(this.nome, this.descricao, this.cor, this.icone);

  final String nome;
  final String descricao;
  final Color cor;
  final IconData icone;

  /// Converte string do banco para enum
  static TipoCaixa fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'rapido':
        return TipoCaixa.rapido;
      case 'preferencial':
        return TipoCaixa.preferencial;
      case 'self':
      case 'self_service':
      case 'selfcheckout':
        return TipoCaixa.self;
      case 'normal':
      case 'pdv':
      default:
        return TipoCaixa.normal;
    }
  }

  /// Converte enum para string compatível com o banco
  String toJson() {
    switch (this) {
      case TipoCaixa.normal:
        return 'pdv';
      case TipoCaixa.rapido:
        return 'rapido';
      case TipoCaixa.preferencial:
        return 'preferencial';
      case TipoCaixa.self:
        return 'self_service';
    }
  }

  bool get isRapido => this == TipoCaixa.rapido;
  bool get isSelf => this == TipoCaixa.self;
  bool get isPreferencial => this == TipoCaixa.preferencial;

  int? get limiteVolumes => isRapido ? 15 : null;
}
