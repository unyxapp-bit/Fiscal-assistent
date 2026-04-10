import 'package:flutter/material.dart';

/// Prioridade da notificação
enum PrioridadeNotificacao {
  baixa('Baixa', Color(0xFF2196F3), Icons.info),
  media('Média', Color(0xFFFFC107), Icons.warning),
  alta('Alta', Color(0xFFFF9800), Icons.priority_high),
  critica('Crítica', Color(0xFFF44336), Icons.error);

  const PrioridadeNotificacao(this.label, this.cor, this.icone);

  final String label;
  final Color cor;
  final IconData icone;

  /// Converte string para enum
  static PrioridadeNotificacao fromString(String value) {
    switch (value.toLowerCase()) {
      case 'baixa':
        return PrioridadeNotificacao.baixa;
      case 'media':
        return PrioridadeNotificacao.media;
      case 'alta':
        return PrioridadeNotificacao.alta;
      case 'critica':
        return PrioridadeNotificacao.critica;
      default:
        throw ArgumentError('Prioridade inválida: $value');
    }
  }

  /// Converte enum para string para salvar no banco
  String toJson() => name;

  /// Retorna se deve tocar som
  bool get deveTocarSom =>
      this == PrioridadeNotificacao.alta ||
      this == PrioridadeNotificacao.critica;

  /// Retorna se deve vibrar
  bool get deveVibrar => this != PrioridadeNotificacao.baixa;
}
