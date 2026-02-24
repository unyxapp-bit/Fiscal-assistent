import '../../entities/caixa.dart';
import '../../../data/repositories/caixa_repository.dart';

/// Use Case: Obter lista de caixas
class GetCaixas {
  final CaixaRepository _repository;

  GetCaixas(this._repository);

  /// Busca todos os caixas
  Future<List<Caixa>> call(String fiscalId) async {
    return await _repository.getCaixas(fiscalId);
  }

  /// Busca apenas caixas ativos
  Future<List<Caixa>> getAtivos(String fiscalId) async {
    return await _repository.getCaixasAtivos(fiscalId);
  }

  /// Stream de caixas com atualizações em tempo real
  Stream<List<Caixa>> watch(String fiscalId) {
    return _repository.watchCaixas(fiscalId);
  }
}
