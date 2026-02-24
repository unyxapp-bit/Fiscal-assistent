import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/caixas_table.dart';

part 'caixa_dao.g.dart';

/// DAO para operações com Caixas
@DriftAccessor(tables: [Caixas])
class CaixaDao extends DatabaseAccessor<AppDatabase> with _$CaixaDaoMixin {
  CaixaDao(super.db);

  /// Busca todos os caixas de um fiscal
  Future<List<CaixaTable>> getCaixas(String fiscalId) {
    return (select(caixas)
          ..where((c) => c.fiscalId.equals(fiscalId))
          ..orderBy([(c) => OrderingTerm(expression: c.numero)]))
        .get();
  }

  /// Busca caixas ativos
  Future<List<CaixaTable>> getCaixasAtivos(String fiscalId) {
    return (select(caixas)
          ..where((c) => c.fiscalId.equals(fiscalId) & c.ativo.equals(true))
          ..orderBy([(c) => OrderingTerm(expression: c.numero)]))
        .get();
  }

  /// Busca caixas por tipo
  Future<List<CaixaTable>> getCaixasByTipo(String fiscalId, String tipo) {
    return (select(caixas)
          ..where((c) =>
              c.fiscalId.equals(fiscalId) &
              c.tipo.equals(tipo) &
              c.ativo.equals(true))
          ..orderBy([(c) => OrderingTerm(expression: c.numero)]))
        .get();
  }

  /// Busca caixas rápidos (1 e 2)
  Future<List<CaixaTable>> getCaixasRapidos(String fiscalId) {
    return getCaixasByTipo(fiscalId, 'rapido');
  }

  /// Busca self checkouts
  Future<List<CaixaTable>> getSelfCheckouts(String fiscalId) {
    return getCaixasByTipo(fiscalId, 'self');
  }

  /// Busca caixa pelo ID
  Future<CaixaTable?> getCaixaById(String id) {
    return (select(caixas)..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// Busca caixa pelo número
  Future<CaixaTable?> getCaixaByNumero(String fiscalId, int numero) {
    return (select(caixas)
          ..where((c) => c.fiscalId.equals(fiscalId) & c.numero.equals(numero)))
        .getSingleOrNull();
  }

  /// Insere ou atualiza caixa
  Future<void> upsertCaixa(CaixaTable caixa) {
    return into(caixas).insertOnConflictUpdate(caixa);
  }

  /// Insere múltiplos caixas (batch)
  Future<void> upsertCaixas(List<CaixaTable> caixasList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(caixas, caixasList);
    });
  }

  /// Atualiza caixa
  Future<bool> updateCaixa(CaixaTable caixa) {
    return update(caixas).replace(caixa);
  }

  /// Atualiza status do caixa
  Future<int> updateStatus(String id, bool ativo) {
    return (update(caixas)..where((c) => c.id.equals(id)))
        .write(CaixasCompanion(ativo: Value(ativo)));
  }

  /// Atualiza manutenção
  Future<int> updateManutencao(String id, bool emManutencao) {
    return (update(caixas)..where((c) => c.id.equals(id)))
        .write(CaixasCompanion(emManutencao: Value(emManutencao)));
  }

  /// Deleta caixa
  Future<int> deleteCaixa(String id) {
    return (delete(caixas)..where((c) => c.id.equals(id))).go();
  }

  /// Stream de todos os caixas
  Stream<List<CaixaTable>> watchCaixas(String fiscalId) {
    return (select(caixas)
          ..where((c) => c.fiscalId.equals(fiscalId))
          ..orderBy([(c) => OrderingTerm(expression: c.numero)]))
        .watch();
  }

  /// Stream de caixas ativos
  Stream<List<CaixaTable>> watchCaixasAtivos(String fiscalId) {
    return (select(caixas)
          ..where((c) => c.fiscalId.equals(fiscalId) & c.ativo.equals(true))
          ..orderBy([(c) => OrderingTerm(expression: c.numero)]))
        .watch();
  }

  /// Contagem de caixas ativos
  Future<int> countCaixasAtivos(String fiscalId) async {
    final query = selectOnly(caixas)
      ..addColumns([caixas.id.count()])
      ..where(caixas.fiscalId.equals(fiscalId) & caixas.ativo.equals(true));

    final result = await query.getSingle();
    return result.read(caixas.id.count()) ?? 0;
  }
}
