import '../datasources/remote/colaborador_remote_datasource.dart';
import '../models/colaborador_model.dart';
import '../../domain/entities/colaborador.dart';
import '../../domain/enums/departamento_tipo.dart';

/// Repositório de Colaboradores — somente Supabase.
class ColaboradorRepository {
  final ColaboradorRemoteDataSource _remoteDataSource;

  ColaboradorRepository({required ColaboradorRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<List<Colaborador>> getColaboradores(String fiscalId) async {
    final remote = await _remoteDataSource.getColaboradores(fiscalId);
    return remote.map((m) => m.toEntity()).toList();
  }

  Future<List<Colaborador>> getColaboradoresByDepartamento(
    String fiscalId,
    DepartamentoTipo departamento,
  ) async {
    final remote = await _remoteDataSource.getColaboradoresByDepartamento(
        fiscalId, departamento.toJson());
    return remote.map((m) => m.toEntity()).toList();
  }

  Future<Colaborador?> getColaboradorById(String id) async {
    final remote = await _remoteDataSource.getColaboradorById(id);
    return remote?.toEntity();
  }

  Future<Colaborador> createColaborador(Colaborador colaborador) async {
    final model = ColaboradorModel.fromEntity(colaborador);
    final remote = await _remoteDataSource.createColaborador(model);
    return remote.toEntity();
  }

  Future<Colaborador> updateColaborador(Colaborador colaborador) async {
    final model = ColaboradorModel.fromEntity(colaborador);
    final remote = await _remoteDataSource.updateColaborador(model);
    return remote.toEntity();
  }

  Future<void> deleteColaborador(String id) async {
    await _remoteDataSource.deleteColaborador(id);
  }

  Stream<List<Colaborador>> watchColaboradores(String fiscalId) {
    return _remoteDataSource
        .watchColaboradores(fiscalId)
        .map((list) => list.map((m) => m.toEntity()).toList());
  }
}
