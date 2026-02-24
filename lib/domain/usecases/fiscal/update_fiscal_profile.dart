import '../../entities/fiscal.dart';
import '../../../data/repositories/fiscal_repository.dart';

/// Use Case: Atualizar perfil do fiscal
class UpdateFiscalProfile {
  final FiscalRepository _repository;

  UpdateFiscalProfile(this._repository);

  /// Executa o use case
  Future<Fiscal> call(Fiscal fiscal) async {
    // Validações
    if (fiscal.nome.trim().isEmpty) {
      throw Exception('Nome não pode ser vazio');
    }

    if (fiscal.email.trim().isEmpty) {
      throw Exception('Email não pode ser vazio');
    }

    // Atualizar
    return await _repository.updateFiscal(fiscal);
  }
}
