import 'package:uuid/uuid.dart';
import '../../entities/colaborador.dart';
import '../../enums/departamento_tipo.dart';
import '../../../data/repositories/colaborador_repository.dart';

/// Use Case: Criar novo colaborador
class CreateColaborador {
  final ColaboradorRepository _repository;

  CreateColaborador(this._repository);

  /// Executa o use case
  Future<Colaborador> call({
    required String fiscalId,
    required String nome,
    required DepartamentoTipo departamento,
    String? observacoes,
    bool ativo = true,
    String? cpf,
    String? telefone,
    String? cargo,
    DateTime? dataAdmissao,
  }) async {
    // Validações
    if (nome.trim().isEmpty) {
      throw Exception('Nome do colaborador não pode ser vazio');
    }

    if (nome.trim().length < 3) {
      throw Exception('Nome deve ter pelo menos 3 caracteres');
    }

    // Criar colaborador
    const uuid = Uuid();
    final agora = DateTime.now();

    final novoColaborador = Colaborador(
      id: uuid.v4(),
      fiscalId: fiscalId,
      nome: nome.trim(),
      departamento: departamento,
      avatarIniciais: _gerarIniciais(nome),
      ativo: ativo,
      observacoes: observacoes?.trim(),
      createdAt: agora,
      updatedAt: agora,
      cpf: cpf?.trim(),
      telefone: telefone?.trim(),
      cargo: cargo?.trim(),
      dataAdmissao: dataAdmissao,
    );

    return await _repository.createColaborador(novoColaborador);
  }

  /// Gera iniciais do nome (ex: "Francielly Rocha" → "FR")
  String _gerarIniciais(String nome) {
    final palavras = nome.trim().split(' ');
    if (palavras.isEmpty) return 'XX';

    if (palavras.length == 1) {
      final palavra = palavras[0];
      if (palavra.length >= 2) {
        return palavra.substring(0, 2).toUpperCase();
      }
      return ('${palavra}X').substring(0, 2).toUpperCase();
    }

    return (palavras[0][0] + palavras[1][0]).toUpperCase();
  }
}
