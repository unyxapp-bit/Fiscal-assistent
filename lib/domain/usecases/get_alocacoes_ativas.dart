import '../../domain/entities/alocacao.dart';
import '../../data/repositories/alocacao_repository.dart';

/// Use case para obter alocações ativas do fiscal
class GetAlocacoesAtivas {
  final AlocacaoRepository alocacaoRepository;

  GetAlocacoesAtivas({required this.alocacaoRepository});

  /// Busca alocações ativas (não liberadas) do fiscal
  Future<List<Alocacao>> call(String fiscalId) async {
    return await alocacaoRepository.getAlocacoesAtivas(fiscalId);
  }

  /// Stream de alocações ativas em tempo real
  Stream<List<Alocacao>> watch(String fiscalId) {
    return alocacaoRepository.watchAlocacoesAtivas(fiscalId);
  }
}
