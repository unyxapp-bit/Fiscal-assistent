import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/fiscais_table.dart';

part 'fiscal_dao.g.dart';

/// DAO para operações com Fiscais
@DriftAccessor(tables: [Fiscais])
class FiscalDao extends DatabaseAccessor<AppDatabase> with _$FiscalDaoMixin {
  FiscalDao(super.db);

  /// Busca fiscal pelo userId (auth)
  Future<FiscalTable?> getFiscalByUserId(String userId) {
    return (select(fiscais)..where((f) => f.userId.equals(userId))).getSingleOrNull();
  }

  /// Busca fiscal pelo ID
  Future<FiscalTable?> getFiscalById(String id) {
    return (select(fiscais)..where((f) => f.id.equals(id))).getSingleOrNull();
  }

  /// Insere ou atualiza fiscal
  Future<void> upsertFiscal(FiscalTable fiscal) {
    return into(fiscais).insertOnConflictUpdate(fiscal);
  }

  /// Atualiza fiscal
  Future<bool> updateFiscal(FiscalTable fiscal) {
    return update(fiscais).replace(fiscal);
  }

  /// Deleta fiscal
  Future<int> deleteFiscal(String id) {
    return (delete(fiscais)..where((f) => f.id.equals(id))).go();
  }

  /// Atualiza última sincronização
  Future<void> updateLastSync(String id) {
    return (update(fiscais)..where((f) => f.id.equals(id)))
        .write(FiscaisCompanion(lastSyncAt: Value(DateTime.now())));
  }

  /// Stream do fiscal atual
  Stream<FiscalTable?> watchFiscalByUserId(String userId) {
    return (select(fiscais)..where((f) => f.userId.equals(userId))).watchSingleOrNull();
  }
}
