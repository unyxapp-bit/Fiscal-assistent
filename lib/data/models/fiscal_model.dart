import '../../domain/entities/fiscal.dart';

/// Model para Fiscal - Conversão JSON ↔ Entity
class FiscalModel extends Fiscal {
  const FiscalModel({
    required super.id,
    required super.nome,
    required super.email,
    super.telefone,
    super.loja,
    super.ativo,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Cria FiscalModel a partir de JSON (Supabase)
  factory FiscalModel.fromJson(Map<String, dynamic> json) {
    return FiscalModel(
      id: json['id'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      telefone: json['telefone'] as String?,
      loja: json['loja'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converte FiscalModel para JSON (Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'loja': loja,
      'ativo': ativo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Converte Entity para Model
  factory FiscalModel.fromEntity(Fiscal entity) {
    return FiscalModel(
      id: entity.id,
      nome: entity.nome,
      email: entity.email,
      telefone: entity.telefone,
      loja: entity.loja,
      ativo: entity.ativo,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Converte Model para Entity
  Fiscal toEntity() {
    return Fiscal(
      id: id,
      nome: nome,
      email: email,
      telefone: telefone,
      loja: loja,
      ativo: ativo,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Cria cópia com alterações
  @override
  FiscalModel copyWith({
    String? id,
    String? nome,
    String? email,
    String? telefone,
    String? loja,
    bool? ativo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FiscalModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      loja: loja ?? this.loja,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
