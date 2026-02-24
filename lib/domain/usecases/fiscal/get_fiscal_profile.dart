import '../../entities/fiscal.dart';
import '../../../data/repositories/fiscal_repository.dart';

/// Use Case: Obter perfil do fiscal
class GetFiscalProfile {
  final FiscalRepository _repository;

  GetFiscalProfile(this._repository);

  /// Executa o use case
  Future<Fiscal?> call(String userId) async {
    return await _repository.getFiscalByUserId(userId);
  }

  /// Stream do perfil
  Stream<Fiscal?> watch(String userId) {
    return _repository.watchFiscal(userId);
  }
}
