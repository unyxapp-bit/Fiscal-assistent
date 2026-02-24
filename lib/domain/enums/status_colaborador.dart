import 'package:flutter/material.dart';

/// Status atual do colaborador durante o turno
enum StatusColaborador {
  trabalhando('Trabalhando', Colors.green, Icons.work),
  intervalo('Intervalo', Color(0xFF795548), Icons.restaurant),
  cafe('Café', Color(0xFFFF9800), Icons.coffee),
  ausente('Ausente', Color(0xFFF44336), Icons.person_off),
  aChegar('A Chegar', Color(0xFF2196F3), Icons.schedule),
  encerrou('Encerrou', Color(0xFF9E9E9E), Icons.check_circle),
  folga('Folga', Color(0xFF9E9E9E), Icons.beach_access);

  const StatusColaborador(this.label, this.cor, this.icone);

  final String label;
  final Color cor;
  final IconData icone;

  /// Converte string para enum
  static StatusColaborador fromString(String value) {
    switch (value.toLowerCase()) {
      case 'trabalhando':
        return StatusColaborador.trabalhando;
      case 'intervalo':
        return StatusColaborador.intervalo;
      case 'cafe':
        return StatusColaborador.cafe;
      case 'ausente':
        return StatusColaborador.ausente;
      case 'a_chegar':
        return StatusColaborador.aChegar;
      case 'encerrou':
        return StatusColaborador.encerrou;
      case 'folga':
        return StatusColaborador.folga;
      default:
        throw ArgumentError('Status inválido: $value');
    }
  }

  /// Converte enum para string para salvar no banco
  String toJson() => name;

  /// Verifica se é um status ativo (trabalhando)
  bool get isAtivo => this == StatusColaborador.trabalhando;

  /// Verifica se está em pausa (intervalo ou café)
  bool get isEmPausa =>
      this == StatusColaborador.intervalo || this == StatusColaborador.cafe;
}
