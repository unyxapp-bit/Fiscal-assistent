import '../../domain/entities/caixa.dart';
import '../../domain/enums/tipo_caixa.dart';

/// Model para Caixa - Conversão JSON ↔ Entity
class CaixaModel extends Caixa {
  const CaixaModel({
    required super.id,
    required super.fiscalId,
    required super.numero,
    required super.tipo,
    super.loja,
    super.localizacao,
    super.ativo,
    super.emManutencao,
    super.observacoes,
    super.colaboradorAlocadoId,
    super.colaboradorAlocadoNome,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Cria CaixaModel a partir de JSON (Supabase)
  factory CaixaModel.fromJson(Map<String, dynamic> json) {
    return CaixaModel(
      id: json['id'] as String,
      fiscalId: json['fiscal_id'] as String,
      numero: json['numero'] as int,
      tipo: TipoCaixa.fromString(json['tipo'] as String),
      loja: json['loja'] as String?,
      localizacao: json['localizacao'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      emManutencao: json['em_manutencao'] as bool? ?? false,
      observacoes: json['observacoes'] as String?,
      colaboradorAlocadoId: json['colaborador_alocado_id'] as String?,
      colaboradorAlocadoNome: json['colaborador_alocado_nome'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converte CaixaModel para JSON (Supabase)
  Map<String, dynamic> toJson() {
    final String status;
    if (!ativo) {
      status = 'inativo';
    } else if (emManutencao) {
      status = 'manutencao';
    } else {
      status = 'disponivel';
    }

    return {
      'id': id,
      'fiscal_id': fiscalId,
      'numero': numero,
      'tipo': tipo.toJson(),
      'loja': loja,
      'localizacao': localizacao,
      'status': status,
      'ativo': ativo,
      'em_manutencao': emManutencao,
      'observacoes': observacoes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Cria CaixaModel a partir de CaixaTable (Drift)
  factory CaixaModel.fromDatabase(dynamic table) {
    return CaixaModel(
      id: table.id as String,
      fiscalId: table.fiscalId as String,
      numero: table.numero as int,
      tipo: TipoCaixa.fromString(table.tipo as String),
      loja: null,
      localizacao: null,
      ativo: table.ativo as bool? ?? true,
      emManutencao: table.emManutencao as bool? ?? false,
      observacoes: table.observacoes as String?,
      colaboradorAlocadoId: null,
      colaboradorAlocadoNome: null,
      createdAt: table.createdAt as DateTime,
      updatedAt: table.updatedAt as DateTime,
    );
  }

  /// Converte Entity para Model
  factory CaixaModel.fromEntity(Caixa entity) {
    return CaixaModel(
      id: entity.id,
      fiscalId: entity.fiscalId,
      numero: entity.numero,
      tipo: entity.tipo,
      loja: entity.loja,
      localizacao: entity.localizacao,
      ativo: entity.ativo,
      emManutencao: entity.emManutencao,
      observacoes: entity.observacoes,
      colaboradorAlocadoId: entity.colaboradorAlocadoId,
      colaboradorAlocadoNome: entity.colaboradorAlocadoNome,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Converte Model para Entity
  Caixa toEntity() {
    return Caixa(
      id: id,
      fiscalId: fiscalId,
      numero: numero,
      tipo: tipo,
      loja: loja,
      localizacao: localizacao,
      ativo: ativo,
      emManutencao: emManutencao,
      observacoes: observacoes,
      colaboradorAlocadoId: colaboradorAlocadoId,
      colaboradorAlocadoNome: colaboradorAlocadoNome,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  CaixaModel copyWith({
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
    return CaixaModel(
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
}
