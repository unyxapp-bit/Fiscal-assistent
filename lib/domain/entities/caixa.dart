import 'package:equatable/equatable.dart';
import '../enums/tipo_caixa.dart';

/// Entidade que representa um Caixa (PDV ou Self Checkout)
class Caixa extends Equatable {
  final String id;
  final String fiscalId;
  final int numero; // 1-8 para PDVs, 11-13 para Self
  final TipoCaixa tipo;
  final bool ativo;
  final bool emManutencao;
  final String? observacoes;
  final String? colaboradorAlocadoId; // ID do colaborador atualmente alocado
  final String? colaboradorAlocadoNome; // Nome para exibição rápida
  final DateTime createdAt;
  final DateTime updatedAt;

  const Caixa({
    required this.id,
    required this.fiscalId,
    required this.numero,
    required this.tipo,
    this.ativo = true,
    this.emManutencao = false,
    this.observacoes,
    this.colaboradorAlocadoId,
    this.colaboradorAlocadoNome,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria uma cópia com alterações
  Caixa copyWith({
    String? id,
    String? fiscalId,
    int? numero,
    TipoCaixa? tipo,
    bool? ativo,
    bool? emManutencao,
    String? observacoes,
    String? colaboradorAlocadoId,
    String? colaboradorAlocadoNome,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Caixa(
      id: id ?? this.id,
      fiscalId: fiscalId ?? this.fiscalId,
      numero: numero ?? this.numero,
      tipo: tipo ?? this.tipo,
      ativo: ativo ?? this.ativo,
      emManutencao: emManutencao ?? this.emManutencao,
      observacoes: observacoes ?? this.observacoes,
      colaboradorAlocadoId: colaboradorAlocadoId ?? this.colaboradorAlocadoId,
      colaboradorAlocadoNome:
          colaboradorAlocadoNome ?? this.colaboradorAlocadoNome,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Nome para exibição (Ex: "Cx 1", "Self 1-3")
  String get nomeExibicao {
    if (tipo == TipoCaixa.self) {
      return 'Self 1-3';
    }
    return 'Cx $numero';
  }

  /// Verifica se o caixa está ocupado
  bool get isOcupado => colaboradorAlocadoId != null;

  /// Verifica se o caixa está disponível
  bool get isDisponivel => ativo && !emManutencao && !isOcupado;

  /// Verifica se é caixa rápido
  bool get isRapido => tipo == TipoCaixa.rapido;

  /// Verifica se é self checkout
  bool get isSelf => tipo == TipoCaixa.self;

  @override
  List<Object?> get props => [
        id,
        fiscalId,
        numero,
        tipo,
        ativo,
        emManutencao,
        observacoes,
        colaboradorAlocadoId,
        colaboradorAlocadoNome,
      ];
}
