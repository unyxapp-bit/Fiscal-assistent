import '../../entities/registro_ponto.dart';
import '../../../data/repositories/registro_ponto_repository.dart';

/// Use Case: Obter registros de ponto de um colaborador
class GetRegistrosPonto {
  final RegistroPontoRepository _repository;

  GetRegistrosPonto(this._repository);

  Future<List<RegistroPonto>> call(String colaboradorId) async {
    return await _repository.getRegistrosPorColaborador(colaboradorId);
  }
}
