import '../../entities/caixa.dart';
import '../../../data/repositories/caixa_repository.dart';

/// Use Case: Marcar/Desmarcar manutenção de caixa
class ToggleCaixaManutencao {
  final CaixaRepository _repository;

  ToggleCaixaManutencao(this._repository);

  /// Executa - marca ou desmarca manutenção
  Future<Caixa> call(String caixaId, bool emManutencao) async {
    return await _repository.updateManutencao(caixaId, emManutencao);
  }
}
