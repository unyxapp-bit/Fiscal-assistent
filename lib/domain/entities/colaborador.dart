import 'package:equatable/equatable.dart';
import '../enums/departamento_tipo.dart';
import '../enums/status_colaborador.dart';

/// Entidade que representa um Colaborador (dados cadastrais estáticos)
class Colaborador extends Equatable {
  final String id;
  final String fiscalId;
  final String nome;
  final DepartamentoTipo departamento;
  final String? avatarIniciais; // Ex: "FR" para Francielly
  final bool ativo;
  final String? observacoes;
  final StatusColaborador? statusAtual; // Status calculado em runtime
  final DateTime createdAt;
  final DateTime updatedAt;

  // Campos opcionais adicionais
  final String? cpf;
  final String? telefone;
  final String? cargo;
  final DateTime? dataAdmissao;

  const Colaborador({
    required this.id,
    required this.fiscalId,
    required this.nome,
    required this.departamento,
    this.avatarIniciais,
    this.ativo = true,
    this.observacoes,
    this.statusAtual,
    required this.createdAt,
    required this.updatedAt,
    this.cpf,
    this.telefone,
    this.cargo,
    this.dataAdmissao,
  });

  /// Cria uma cópia com alterações
  Colaborador copyWith({
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
    return Colaborador(
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

  /// Gera iniciais automaticamente a partir do nome
  String gerarIniciais() {
    if (avatarIniciais != null && avatarIniciais!.isNotEmpty) {
      return avatarIniciais!;
    }

    final palavras = nome.trim().split(' ');
    if (palavras.isEmpty) return 'XX';

    if (palavras.length == 1) {
      return palavras[0].substring(0, 2).toUpperCase();
    }

    return (palavras[0][0] + palavras[1][0]).toUpperCase();
  }

  /// Getter para iniciais (conveniência)
  String get iniciais => gerarIniciais();

  /// Verifica se é operador de self checkout
  bool get isSelfOperator => departamento == DepartamentoTipo.self;

  /// Verifica se é empacotador
  bool get isEmpacotador => departamento == DepartamentoTipo.pacote;

  /// Verifica se é operador de caixa
  bool get isCaixaOperator => departamento == DepartamentoTipo.caixa;

  @override
  List<Object?> get props => [
        id,
        fiscalId,
        nome,
        departamento,
        avatarIniciais,
        ativo,
        observacoes,
        statusAtual,
        cpf,
        telefone,
        cargo,
        dataAdmissao,
      ];
}
