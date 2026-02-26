import 'package:equatable/equatable.dart';
import '../enums/tipo_caixa.dart';

/// Entidade que representa um Caixa (PDV ou Self Checkout)
class Caixa extends Equatable {
  final String id;
  final String fiscalId;
  final int numero;
  final TipoCaixa tipo;
  final String? loja;
  final String? localizacao;
  final bool ativo;
  final bool emManutencao;
  final String? observacoes;
  final String? colaboradorAlocadoId;
  final String? colaboradorAlocadoNome;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Caixa({
    required this.id,
    required this.fiscalId,
    required this.numero,
    required this.tipo,
    this.loja,
    this.localizacao,
    this.ativo = true,
    this.emManutencao = false,
    this.observacoes,
    this.colaboradorAlocadoId,
    this.colaboradorAlocadoNome,
    required this.createdAt,
    required this.updatedAt,
  });

  Caixa copyWith({
    String? id,
    String? fiscalId,
    int? numero,
    TipoCaixa? tipo,
    String? loja,
    String? localizacao,
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
      loja: loja ?? this.loja,
      localizacao: localizacao ?? this.localizacao,
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

  String get nomeExibicao {
    if (tipo == TipoCaixa.self) return 'Self $numero';
    if (tipo == TipoCaixa.balcao) return 'Balcão $numero';
    return 'Cx $numero';
  }

  bool get isOcupado => colaboradorAlocadoId != null;
  bool get isDisponivel => ativo && !emManutencao && !isOcupado;
  bool get isRapido => tipo == TipoCaixa.rapido;
  bool get isSelf => tipo == TipoCaixa.self;

  @override
  List<Object?> get props => [
        id,
        fiscalId,
        numero,
        tipo,
        loja,
        localizacao,
        ativo,
        emManutencao,
        observacoes,
        colaboradorAlocadoId,
        colaboradorAlocadoNome,
      ];
}
