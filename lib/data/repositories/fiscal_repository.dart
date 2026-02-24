import '../datasources/remote/fiscal_remote_datasource.dart';
import '../models/fiscal_model.dart';
import '../../domain/entities/fiscal.dart';

/// Repositório de Fiscal — somente Supabase.
class FiscalRepository {
  final FiscalRemoteDataSource _remoteDataSource;

  FiscalRepository({required FiscalRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<Fiscal?> getFiscalByUserId(String userId) async {
    final remote = await _remoteDataSource.getFiscalByUserId(userId);
    return remote?.toEntity();
  }

  Future<Fiscal?> getFiscalById(String id) async {
    final remote = await _remoteDataSource.getFiscalById(id);
    return remote?.toEntity();
  }

  Future<Fiscal> createFiscal(Fiscal fiscal) async {
    final model = FiscalModel.fromEntity(fiscal);
    final remote = await _remoteDataSource.createFiscal(model);
    return remote.toEntity();
  }

  Future<Fiscal> updateFiscal(Fiscal fiscal) async {
    final model = FiscalModel.fromEntity(fiscal);
    final remote = await _remoteDataSource.updateFiscal(model);
    return remote.toEntity();
  }

  Future<void> deleteFiscal(String id) async {
    await _remoteDataSource.deleteFiscal(id);
  }

  Stream<Fiscal?> watchFiscal(String userId) {
    return _remoteDataSource
        .watchFiscal(userId)
        .map((model) => model?.toEntity());
  }
}
