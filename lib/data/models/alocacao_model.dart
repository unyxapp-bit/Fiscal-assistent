import 'package:equatable/equatable.dart';

import '../../domain/entities/alocacao.dart';

/// Model para Alocacao - Registro de colaborador em caixa
class AlocacaoModel extends Equatable {
  final String id;
  final String colaboradorId;
  final String caixaId;
  final String? turnoEscalaId;
  final DateTime alocadoEm;
  final DateTime? liberadoEm;
  final String? motivoLiberacao;
  final String? alocadoPor;
  final String? observacoes;
  final DateTime createdAt;
  final bool intervaloMarcadoFeito;

  const AlocacaoModel({
    required this.id,
    required this.colaboradorId,
    required this.caixaId,
    this.turnoEscalaId,
    required this.alocadoEm,
    this.liberadoEm,
    this.motivoLiberacao,
    this.alocadoPor,
    this.observacoes,
    required this.createdAt,
    this.intervaloMarcadoFeito = false,
  });

  /// Cria AlocacaoModel a partir de JSON (Supabase)
  factory AlocacaoModel.fromJson(Map<String, dynamic> json) {
    return AlocacaoModel(
      id: json['id'] as String,
      colaboradorId: json['colaborador_id'] as String,
      caixaId: json['caixa_id'] as String,
      turnoEscalaId: json['turno_escala_id'] as String?,
      // Suporta tanto o nome novo (alocado_em) quanto o antigo (horario_inicio)
      alocadoEm: json['alocado_em'] != null
          ? DateTime.parse(json['alocado_em'] as String)
          : DateTime.parse(json['horario_inicio'] as String),
      // Suporta tanto liberado_em quanto horario_fim
      liberadoEm: json['liberado_em'] != null
          ? DateTime.parse(json['liberado_em'] as String)
          : (json['horario_fim'] != null
              ? DateTime.parse(json['horario_fim'] as String)
              : null),
      motivoLiberacao: json['motivo_liberacao'] as String?,
      alocadoPor: json['alocado_por'] as String?,
      observacoes: json['observacoes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      intervaloMarcadoFeito: json['intervalo_marcado_feito'] as bool? ?? false,
    );
  }

  factory AlocacaoModel.fromEntity(Alocacao entity) {
    return AlocacaoModel(
      id: entity.id,
      colaboradorId: entity.colaboradorId,
      caixaId: entity.caixaId,
      turnoEscalaId: entity.turnoEscalaId,
      alocadoEm: entity.alocadoEm,
      liberadoEm: entity.liberadoEm,
      motivoLiberacao: entity.motivoLiberacao,
      alocadoPor: entity.alocadoPor,
      observacoes: entity.observacoes,
      createdAt: entity.createdAt,
      intervaloMarcadoFeito: entity.intervaloMarcadoFeito,
    );
  }

  /// Converte AlocacaoModel para JSON (Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'colaborador_id': colaboradorId,
      'caixa_id': caixaId,
      'turno_escala_id': turnoEscalaId,
      // Envia para ambas as colunas para compatibilidade
      'alocado_em': alocadoEm.toIso8601String(),
      'horario_inicio': alocadoEm.toIso8601String(),
      'data_alocacao': alocadoEm.toIso8601String().split('T')[0],
      'liberado_em': liberadoEm?.toIso8601String(),
      'horario_fim': liberadoEm?.toIso8601String(),
      'status': liberadoEm == null ? 'ativo' : 'finalizado',
      'motivo_liberacao': motivoLiberacao,
      'alocado_por': alocadoPor,
      'observacoes': observacoes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converte Model para Entity
  Alocacao toEntity() {
    return Alocacao(
      id: id,
      colaboradorId: colaboradorId,
      caixaId: caixaId,
      turnoEscalaId: turnoEscalaId,
      alocadoEm: alocadoEm,
      liberadoEm: liberadoEm,
      motivoLiberacao: motivoLiberacao,
      alocadoPor: alocadoPor,
      observacoes: observacoes,
      createdAt: createdAt,
      intervaloMarcadoFeito: intervaloMarcadoFeito,
    );
  }

  /// Cria copia com alteracoes
  AlocacaoModel copyWith({
    String? id,
    String? colaboradorId,
    String? caixaId,
    String? turnoEscalaId,
    DateTime? alocadoEm,
    DateTime? liberadoEm,
    String? motivoLiberacao,
    String? alocadoPor,
    String? observacoes,
    DateTime? createdAt,
    bool? intervaloMarcadoFeito,
  }) {
    return AlocacaoModel(
      id: id ?? this.id,
      colaboradorId: colaboradorId ?? this.colaboradorId,
      caixaId: caixaId ?? this.caixaId,
      turnoEscalaId: turnoEscalaId ?? this.turnoEscalaId,
      alocadoEm: alocadoEm ?? this.alocadoEm,
      liberadoEm: liberadoEm ?? this.liberadoEm,
      motivoLiberacao: motivoLiberacao ?? this.motivoLiberacao,
      alocadoPor: alocadoPor ?? this.alocadoPor,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      intervaloMarcadoFeito: intervaloMarcadoFeito ?? this.intervaloMarcadoFeito,
    );
  }

  bool get isAtiva => liberadoEm == null;

  @override
  List<Object?> get props => [
        id,
        colaboradorId,
        caixaId,
        turnoEscalaId,
        alocadoEm,
        liberadoEm,
        motivoLiberacao,
      ];
}
