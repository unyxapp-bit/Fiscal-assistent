import '../../entities/colaborador.dart';
import '../../enums/departamento_tipo.dart';
import '../../../data/repositories/colaborador_repository.dart';

/// Use Case: Obter lista de colaboradores
class GetColaboradores {
  final ColaboradorRepository _repository;

  GetColaboradores(this._repository);

  /// Executa o use case - retorna todos os colaboradores
  Future<List<Colaborador>> call(String fiscalId) async {
    return await _repository.getColaboradores(fiscalId);
  }

  /// Stream de mudanças em tempo real
  Stream<List<Colaborador>> watch(String fiscalId) {
    return _repository.watchColaboradores(fiscalId);
  }

  /// Busca colaboradores por departamento
  Future<List<Colaborador>> byDepartamento(
    String fiscalId,
    DepartamentoTipo departamento,
  ) async {
    return await _repository.getColaboradoresByDepartamento(
      fiscalId,
      departamento,
    );
  }

  /// Busca colaborador por ID
  Future<Colaborador?> byId(String id) async {
    return await _repository.getColaboradorById(id);
  }
}
