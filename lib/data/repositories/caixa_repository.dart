import '../../domain/entities/caixa.dart';
import '../datasources/remote/caixa_remote_datasource.dart';
import '../models/caixa_model.dart';
import '../../core/errors/exceptions.dart';

/// Repositório de Caixas — somente Supabase.
class CaixaRepository {
  final CaixaRemoteDataSource remoteDataSource;

  CaixaRepository({required this.remoteDataSource});

  Future<List<Caixa>> getCaixas(String fiscalId) async {
    final remote = await remoteDataSource.getCaixas(fiscalId);
    return remote.map((m) => m.toEntity()).toList();
  }

  Future<List<Caixa>> getCaixasAtivos(String fiscalId) async {
    final all = await getCaixas(fiscalId);
    return all.where((c) => c.ativo && !c.emManutencao).toList();
  }

  Future<Caixa?> getCaixaById(String id) async {
    final remote = await remoteDataSource.getCaixaById(id);
    return remote?.toEntity();
  }

  Future<void> upsertCaixa(Caixa caixa) async {
    await remoteDataSource.upsertCaixa(CaixaModel.fromEntity(caixa));
  }

  Future<String> insertCaixa(Caixa caixa) async {
    await remoteDataSource.upsertCaixa(CaixaModel.fromEntity(caixa));
    return caixa.id;
  }

  Future<void> updateCaixa(Caixa caixa) async {
    await remoteDataSource.upsertCaixa(CaixaModel.fromEntity(caixa));
  }

  Future<void> deleteCaixa(String id) async {
    await remoteDataSource.deleteCaixa(id);
  }

  Future<List<String>> getCaixasUsadosHoje(String colaboradorId) async {
    return remoteDataSource.getCaixasUsadosHoje(colaboradorId);
  }

  Stream<List<Caixa>> watchCaixas(String fiscalId) {
    return remoteDataSource
        .watchCaixas(fiscalId)
        .map((list) => list.map((m) => m.toEntity()).toList());
  }

  Future<Caixa> updateStatus(String caixaId, bool ativo) async {
    final caixa = await getCaixaById(caixaId);
    if (caixa == null) throw CacheException('Caixa não encontrado');
    final updated = CaixaModel.fromEntity(caixa).copyWith(
      ativo: ativo,
      updatedAt: DateTime.now(),
    );
    await remoteDataSource.upsertCaixa(updated);
    return updated.toEntity();
  }

  Future<Caixa> updateManutencao(String caixaId, bool emManutencao) async {
    final caixa = await getCaixaById(caixaId);
    if (caixa == null) throw CacheException('Caixa não encontrado');
    final updated = CaixaModel.fromEntity(caixa).copyWith(
      emManutencao: emManutencao,
      updatedAt: DateTime.now(),
    );
    await remoteDataSource.upsertCaixa(updated);
    return updated.toEntity();
  }
}
