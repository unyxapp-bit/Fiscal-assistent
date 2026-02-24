import 'package:flutter/foundation.dart' show kDebugMode;

/// Tipos de departamento disponíveis no sistema
enum DepartamentoTipo {
  caixa('Caixa', 'Operador(a) de Caixa'),
  fiscal('Fiscal', 'Fiscal de Loja'),
  pacote('Pacote', 'Empacotador(a)'),
  self('Self', 'Operador(a) Self Checkout'),
  gerencia('Gerência', 'Gerente de Loja'),
  acougue('Açougue', 'Atendente de Açougue'),
  padaria('Padaria', 'Padeiro'),
  hortifruti('Hortifruti', 'Operador Hortifruti'),
  deposito('Depósito', 'Operador de Depósito'),
  limpeza('Limpeza', 'Collaborador de Limpeza'),
  seguranca('Segurança', 'Agente de Segurança');

  const DepartamentoTipo(this.nome, this.descricao);

  final String nome;
  final String descricao;

  /// Converte string para enum
  static DepartamentoTipo fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'caixa':
        return DepartamentoTipo.caixa;
      case 'fiscal':
        return DepartamentoTipo.fiscal;
      case 'pacote':
        return DepartamentoTipo.pacote;
      case 'self':
      case 'self_service':
        return DepartamentoTipo.self;
      case 'gerencia':
      case 'gerência':
        return DepartamentoTipo.gerencia;
      case 'acougue':
      case 'açougue':
        return DepartamentoTipo.acougue;
      case 'padaria':
        return DepartamentoTipo.padaria;
      case 'hortifruti':
        return DepartamentoTipo.hortifruti;
      case 'deposito':
      case 'depósito':
        return DepartamentoTipo.deposito;
      case 'limpeza':
        return DepartamentoTipo.limpeza;
      case 'seguranca':
      case 'segurança':
        return DepartamentoTipo.seguranca;
      default:
        if (kDebugMode) {
          print('[DepartamentoTipo] Departamento desconhecido: $value, usando fiscal como padrão');
        }
        return DepartamentoTipo.fiscal; // Fallback seguro
    }
  }

  /// Converte enum para string para salvar no banco
  String toJson() => name;
}
