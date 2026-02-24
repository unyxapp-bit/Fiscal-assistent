import '../../domain/entities/colaborador.dart';
import '../../domain/enums/departamento_tipo.dart';
import '../../domain/enums/status_colaborador.dart';

/// Model para Colaborador - Conversão JSON ↔ Entity
class ColaboradorModel extends Colaborador {
  const ColaboradorModel({
    required super.id,
    required super.fiscalId,
    required super.nome,
    required super.departamento,
    super.avatarIniciais,
    super.ativo,
    super.observacoes,
    super.statusAtual,
    required super.createdAt,
    required super.updatedAt,
    super.cpf,
    super.telefone,
    super.cargo,
    super.dataAdmissao,
  });

  /// Cria ColaboradorModel a partir de JSON (Supabase)
  factory ColaboradorModel.fromJson(Map<String, dynamic> json) {
    return ColaboradorModel(
      id: json['id'] as String,
      fiscalId: json['fiscal_id'] as String? ?? '',
      nome: json['nome'] as String,
      departamento: DepartamentoTipo.fromString(json['departamento'] as String),
      avatarIniciais: json['avatar_iniciais'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      observacoes: json['observacoes'] as String?,
      statusAtual: json['status_atual'] != null
          ? StatusColaborador.fromString(json['status_atual'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      cpf: json['cpf'] as String?,
      telefone: json['telefone'] as String?,
      cargo: json['cargo'] as String?,
      dataAdmissao: json['data_admissao'] != null
          ? DateTime.parse(json['data_admissao'] as String)
          : null,
    );
  }

  /// Converte ColaboradorModel para JSON (Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fiscal_id': fiscalId,
      'nome': nome,
      'departamento': departamento.toJson(),
      'avatar_iniciais': avatarIniciais,
      'ativo': ativo,
      'observacoes': observacoes,
      // status_atual não é salvo no banco (calculado em runtime)
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'cpf': cpf,
      'telefone': telefone,
      'cargo': cargo,
      'data_admissao': dataAdmissao != null
          ? '${dataAdmissao!.year}-${dataAdmissao!.month.toString().padLeft(2, '0')}-${dataAdmissao!.day.toString().padLeft(2, '0')}'
          : null,
    };
  }

  /// Converte Entity para Model
  factory ColaboradorModel.fromEntity(Colaborador entity) {
    return ColaboradorModel(
      id: entity.id,
      fiscalId: entity.fiscalId,
      nome: entity.nome,
      departamento: entity.departamento,
      avatarIniciais: entity.avatarIniciais,
      ativo: entity.ativo,
      observacoes: entity.observacoes,
      statusAtual: entity.statusAtual,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      cpf: entity.cpf,
      telefone: entity.telefone,
      cargo: entity.cargo,
      dataAdmissao: entity.dataAdmissao,
    );
  }

  /// Converte Model para Entity
  Colaborador toEntity() {
    return Colaborador(
      id: id,
      fiscalId: fiscalId,
      nome: nome,
      departamento: departamento,
      avatarIniciais: avatarIniciais,
      ativo: ativo,
      observacoes: observacoes,
      statusAtual: statusAtual,
      createdAt: createdAt,
      updatedAt: updatedAt,
      cpf: cpf,
      telefone: telefone,
      cargo: cargo,
      dataAdmissao: dataAdmissao,
    );
  }

  /// Cria cópia com alterações
  @override
  ColaboradorModel copyWith({
    String? id,
    String? fiscalId,
    String? nome,
    DepartamentoTipo? departamento,
    String? avatarIniciais,
    bool? ativo,
    String? observacoes,
    StatusColaborador? statusAtual,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cpf,
    String? telefone,
    String? cargo,
    DateTime? dataAdmissao,
  }) {
    return ColaboradorModel(
      id: id ?? this.id,
      fiscalId: fiscalId ?? this.fiscalId,
      nome: nome ?? this.nome,
      departamento: departamento ?? this.departamento,
      avatarIniciais: avatarIniciais ?? this.avatarIniciais,
      ativo: ativo ?? this.ativo,
      observacoes: observacoes ?? this.observacoes,
      statusAtual: statusAtual ?? this.statusAtual,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cpf: cpf ?? this.cpf,
      telefone: telefone ?? this.telefone,
      cargo: cargo ?? this.cargo,
      dataAdmissao: dataAdmissao ?? this.dataAdmissao,
    );
  }
}
