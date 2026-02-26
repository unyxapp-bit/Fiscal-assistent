import '../datasources/remote/pacote_plantao_remote_datasource.dart';
import '../../domain/entities/pacote_plantao.dart';

/// Repositório para Plantão de Empacotadores
class PacotePlantaoRepository {
  final PacotePlantaoRemoteDataSource remoteDataSource;

  PacotePlantaoRepository({required this.remoteDataSource});

  /// Retorna os empacotadores no plantão de hoje
  Future<List<PacotePlantao>> getPlantaoHoje(String fiscalId) async {
    final data = await remoteDataSource.getPlantaoHoje(fiscalId);
    return data.map(_fromMap).toList();
  }

  /// Adiciona empacotador ao plantão de hoje
  Future<PacotePlantao> addPlantao(
    String fiscalId,
    String colaboradorId,
  ) async {
    final data = await remoteDataSource.addPlantao(fiscalId, colaboradorId);
    return _fromMap(data);
  }

  /// Remove empacotador do plantão
  Future<void> removePlantao(String id) async {
    await remoteDataSource.removePlantao(id);
  }

  PacotePlantao _fromMap(Map<String, dynamic> map) {
    return PacotePlantao(
      id: map['id'] as String,
      fiscalId: map['fiscal_id'] as String,
      colaboradorId: map['colaborador_id'] as String,
      data: DateTime.parse(map['data'] as String),
      criadoEm: DateTime.parse(map['criado_em'] as String),
    );
  }
}
