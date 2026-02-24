import '../../entities/caixa.dart';
import '../../../data/repositories/caixa_repository.dart';

/// Use Case: Ativar/Desativar caixa
class ToggleCaixaStatus {
  final CaixaRepository _repository;

  ToggleCaixaStatus(this._repository);

  /// Executa - ativa ou desativa um caixa
  Future<Caixa> call(String caixaId, bool ativo) async {
    return await _repository.updateStatus(caixaId, ativo);
  }
}
