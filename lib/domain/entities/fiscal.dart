import 'package:equatable/equatable.dart';

/// Entidade que representa o Fiscal (usuário do app)
class Fiscal extends Equatable {
  final String id; // UUID - PRIMARY KEY (mesmo do auth.users)
  final String nome;
  final String email;
  final String? telefone;
  final String? loja; // Ex: "Baependi", "Caxambu", "Cruzília"
  final bool ativo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Fiscal({
    required this.id,
    required this.nome,
    required this.email,
    this.telefone,
    this.loja,
    this.ativo = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria uma cópia com alterações
  Fiscal copyWith({
    String? id,
    String? nome,
    String? email,
    String? telefone,
    String? loja,
    bool? ativo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Fiscal(
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

  @override
  List<Object?> get props => [
        id,
        nome,
        email,
        telefone,
        loja,
        ativo,
        createdAt,
        updatedAt,
      ];
}
