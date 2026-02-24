import '../../entities/colaborador.dart';
import '../../../data/repositories/colaborador_repository.dart';

/// Use Case: Atualizar colaborador
class UpdateColaborador {
  final ColaboradorRepository _repository;

  UpdateColaborador(this._repository);

  /// Executa o use case
  Future<Colaborador> call(Colaborador colaborador) async {
    // Validações
    if (colaborador.nome.trim().isEmpty) {
      throw Exception('Nome do colaborador não pode ser vazio');
    }

    if (colaborador.nome.trim().length < 3) {
      throw Exception('Nome deve ter pelo menos 3 caracteres');
    }

    // Preparar colaborador atualizado
    final colaboradorAtualizado = colaborador.copyWith(
      nome: colaborador.nome.trim(),
      updatedAt: DateTime.now(),
    );

    return await _repository.updateColaborador(colaboradorAtualizado);
  }
}
