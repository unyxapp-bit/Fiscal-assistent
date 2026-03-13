import '../datasources/remote/outro_setor_remote_datasource.dart';
import '../../domain/entities/outro_setor.dart';

/// Repositório para colaboradores em Outro Setor
class OutroSetorRepository {
  final OutroSetorRemoteDataSource remoteDataSource;

  OutroSetorRepository({required this.remoteDataSource});

  Future<List<OutroSetor>> getHoje(String fiscalId) async {
    final data = await remoteDataSource.getOutroSetorHoje(fiscalId);
    return data.map(_fromMap).toList();
  }

  Future<OutroSetor> add(
    String fiscalId,
    String colaboradorId,
    String setor,
  ) async {
    final data =
        await remoteDataSource.addOutroSetor(fiscalId, colaboradorId, setor);
    return _fromMap(data);
  }

  Future<void> remove(String id) async {
    await remoteDataSource.removeOutroSetor(id);
  }

  OutroSetor _fromMap(Map<String, dynamic> map) {
    return OutroSetor(
      id: map['id'] as String,
      fiscalId: map['fiscal_id'] as String,
      colaboradorId: map['colaborador_id'] as String,
      setor: map['setor'] as String,
      data: DateTime.parse(map['data'] as String),
      criadoEm: DateTime.parse(map['criado_em'] as String),
    );
  }
}
