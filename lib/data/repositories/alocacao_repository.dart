import '../../domain/entities/alocacao.dart';
import '../datasources/remote/alocacao_remote_datasource.dart';
import '../models/alocacao_model.dart';

/// Repositório de Alocações — somente Supabase (sem cache local).
class AlocacaoRepository {
  final AlocacaoRemoteDataSource remoteDataSource;

  AlocacaoRepository({required this.remoteDataSource});

  Future<List<Alocacao>> getAlocacoesAtivas(String fiscalId) async {
    final remote = await remoteDataSource.getAlocacoesAtivas(fiscalId);
    return remote.map((m) => m.toEntity()).toList();
  }

  Future<Alocacao?> getAlocacaoAtivaColaborador(String colaboradorId) async {
    final remote =
        await remoteDataSource.getAlocacaoAtivaColaborador(colaboradorId);
    return remote?.toEntity();
  }

  Future<bool> jaUsouCaixaHoje(String colaboradorId, String caixaId) async {
    return remoteDataSource.jaUsouCaixaHoje(colaboradorId, caixaId);
  }

  Future<Alocacao> createAlocacao(AlocacaoModel alocacao) async {
    final remote = await remoteDataSource.createAlocacao(alocacao);
    return remote.toEntity();
  }

  Future<Alocacao> liberarAlocacao(
    String id,
    DateTime liberadoEm,
    String motivo,
  ) async {
    final remote =
        await remoteDataSource.liberarAlocacao(id, liberadoEm, motivo);
    return remote.toEntity();
  }

  Future<void> marcarIntervaloFeito(String alocacaoId) async {
    await remoteDataSource.marcarIntervaloFeito(alocacaoId);
  }

  Future<List<Alocacao>> getHistorico(String fiscalId) async {
    final remote = await remoteDataSource.getHistorico(fiscalId);
    return remote.map((m) => m.toEntity()).toList();
  }

  Stream<List<Alocacao>> watchAlocacoesAtivas(String fiscalId) {
    return remoteDataSource.watchAlocacoesAtivas(fiscalId).map(
          (list) => list.map((m) => m.toEntity()).toList(),
        );
  }
}
