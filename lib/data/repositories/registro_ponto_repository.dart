import '../datasources/remote/registro_ponto_remote_datasource.dart';
import '../models/registro_ponto_model.dart';
import '../../domain/entities/registro_ponto.dart';

/// Repositório de Registros de Ponto — somente Supabase.
class RegistroPontoRepository {
  final RegistroPontoRemoteDataSource _remoteDataSource;

  RegistroPontoRepository(
      {required RegistroPontoRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<List<RegistroPonto>> getRegistrosPorColaborador(
      String colaboradorId) async {
    final remote =
        await _remoteDataSource.getRegistrosPorColaborador(colaboradorId);
    return remote.map((m) => m.toEntity()).toList();
  }

  Future<RegistroPonto> createRegistroPonto(RegistroPonto registro) async {
    final model = RegistroPontoModel.fromEntity(registro);
    final remote = await _remoteDataSource.createRegistroPonto(model);
    return remote.toEntity();
  }

  Future<RegistroPonto> updateRegistroPonto(RegistroPonto registro) async {
    final model = RegistroPontoModel.fromEntity(registro);
    final remote = await _remoteDataSource.updateRegistroPonto(model);
    return remote.toEntity();
  }

  Future<void> deleteRegistroPonto(String id) async {
    await _remoteDataSource.deleteRegistroPonto(id);
  }

  /// Insere uma lista de registros em lote. Retorna quantos foram inseridos.
  Future<int> importarBatch(List<RegistroPonto> registros) async {
    final maps = registros.map((r) {
      final m = RegistroPontoModel.fromEntity(r).toJson();
      m.remove('id');
      return m;
    }).toList();
    await _remoteDataSource.createBatchRegistros(maps);
    return maps.length;
  }
}
