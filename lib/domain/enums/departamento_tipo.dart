import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

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
          print(
              '[DepartamentoTipo] Departamento desconhecido: $value, usando fiscal como padrão');
        }
        return DepartamentoTipo.fiscal; // Fallback seguro
    }
  }

  /// Converte enum para string compatível com o banco
  String toJson() {
    switch (this) {
      case DepartamentoTipo.self:
        return 'self_service';
      default:
        return name;
    }
  }
}

extension DepartamentoTipoExtension on DepartamentoTipo {
  Color get cor {
    switch (this) {
      case DepartamentoTipo.caixa:
        return const Color(0xFF2196F3);
      case DepartamentoTipo.fiscal:
        return const Color(0xFFFF9800);
      case DepartamentoTipo.pacote:
        return const Color(0xFF4CAF50);
      case DepartamentoTipo.self:
        return const Color(0xFF9C27B0);
      case DepartamentoTipo.gerencia:
        return const Color(0xFFF44336);
      case DepartamentoTipo.acougue:
        return const Color(0xFF795548);
      case DepartamentoTipo.padaria:
        return const Color(0xFFFFC107);
      case DepartamentoTipo.hortifruti:
        return const Color(0xFF69F0AE);
      case DepartamentoTipo.deposito:
        return const Color(0xFF9E9E9E);
      case DepartamentoTipo.limpeza:
        return const Color(0xFF607D8B);
      case DepartamentoTipo.seguranca:
        return const Color(0xFF3F51B5);
    }
  }

  IconData get icone {
    switch (this) {
      case DepartamentoTipo.caixa:
        return Icons.point_of_sale;
      case DepartamentoTipo.fiscal:
        return Icons.security;
      case DepartamentoTipo.pacote:
        return Icons.inventory_2;
      case DepartamentoTipo.self:
        return Icons.self_improvement;
      case DepartamentoTipo.gerencia:
        return Icons.manage_accounts;
      case DepartamentoTipo.acougue:
        return Icons.set_meal;
      case DepartamentoTipo.padaria:
        return Icons.bakery_dining;
      case DepartamentoTipo.hortifruti:
        return Icons.eco;
      case DepartamentoTipo.deposito:
        return Icons.warehouse;
      case DepartamentoTipo.limpeza:
        return Icons.cleaning_services;
      case DepartamentoTipo.seguranca:
        return Icons.shield;
    }
  }
}
