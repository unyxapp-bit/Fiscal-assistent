import '../../domain/entities/alocacao.dart';
import '../../data/repositories/alocacao_repository.dart';

/// Use case para liberar (desalocar) um colaborador
class LiberarAlocacao {
  final AlocacaoRepository alocacaoRepository;

  LiberarAlocacao({required this.alocacaoRepository});

  /// Marca uma alocação como liberada
  ///
  /// Parâmetros:
  /// - [alocacaoId]: ID da alocação a liberar
  /// - [motivo]: Motivo da liberação (ex: "Fim do turno", "Troca de caixa")
  ///
  /// Retorna a alocação atualizada
  Future<Alocacao> call({
    required String alocacaoId,
    required String motivo,
  }) async {
    return await alocacaoRepository.liberarAlocacao(
      alocacaoId,
      DateTime.now(),
      motivo,
    );
  }
}
