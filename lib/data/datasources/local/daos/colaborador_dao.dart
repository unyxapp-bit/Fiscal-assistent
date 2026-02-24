import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/colaboradores_table.dart';

part 'colaborador_dao.g.dart';

/// DAO para operações com Colaboradores
@DriftAccessor(tables: [Colaboradores])
class ColaboradorDao extends DatabaseAccessor<AppDatabase> with _$ColaboradorDaoMixin {
  ColaboradorDao(super.db);

  /// Busca todos os colaboradores de um fiscal
  Future<List<ColaboradorTable>> getColaboradores(String fiscalId) {
    return (select(colaboradores)
          ..where((c) => c.fiscalId.equals(fiscalId))
          ..orderBy([(c) => OrderingTerm(expression: c.nome)]))
        .get();
  }

  /// Busca colaboradores ativos
  Future<List<ColaboradorTable>> getColaboradoresAtivos(String fiscalId) {
    return (select(colaboradores)
          ..where((c) => c.fiscalId.equals(fiscalId) & c.ativo.equals(true))
          ..orderBy([(c) => OrderingTerm(expression: c.nome)]))
        .get();
  }

  /// Busca colaboradores por departamento
  Future<List<ColaboradorTable>> getColaboradoresByDepartamento(
    String fiscalId,
    String departamento,
  ) {
    return (select(colaboradores)
          ..where((c) =>
              c.fiscalId.equals(fiscalId) &
              c.departamento.equals(departamento) &
              c.ativo.equals(true))
          ..orderBy([(c) => OrderingTerm(expression: c.nome)]))
        .get();
  }

  /// Busca colaborador pelo ID
  Future<ColaboradorTable?> getColaboradorById(String id) {
    return (select(colaboradores)..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// Insere ou atualiza colaborador
  Future<void> upsertColaborador(ColaboradorTable colaborador) {
    return into(colaboradores).insertOnConflictUpdate(colaborador);
  }

  /// Insere múltiplos colaboradores (batch)
  Future<void> upsertColaboradores(List<ColaboradorTable> colaboradoresList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(colaboradores, colaboradoresList);
    });
  }

  /// Atualiza colaborador
  Future<bool> updateColaborador(ColaboradorTable colaborador) {
    return update(colaboradores).replace(colaborador);
  }

  /// Deleta colaborador
  Future<int> deleteColaborador(String id) {
    return (delete(colaboradores)..where((c) => c.id.equals(id))).go();
  }

  /// Stream de todos os colaboradores
  Stream<List<ColaboradorTable>> watchColaboradores(String fiscalId) {
    return (select(colaboradores)
          ..where((c) => c.fiscalId.equals(fiscalId))
          ..orderBy([(c) => OrderingTerm(expression: c.nome)]))
        .watch();
  }

  /// Stream de colaboradores ativos
  Stream<List<ColaboradorTable>> watchColaboradoresAtivos(String fiscalId) {
    return (select(colaboradores)
          ..where((c) => c.fiscalId.equals(fiscalId) & c.ativo.equals(true))
          ..orderBy([(c) => OrderingTerm(expression: c.nome)]))
        .watch();
  }

  /// Contagem de colaboradores por departamento
  Future<int> countByDepartamento(String fiscalId, String departamento) async {
    final query = selectOnly(colaboradores)
      ..addColumns([colaboradores.id.count()])
      ..where(
        colaboradores.fiscalId.equals(fiscalId) &
            colaboradores.departamento.equals(departamento) &
            colaboradores.ativo.equals(true),
      );

    final result = await query.getSingle();
    return result.read(colaboradores.id.count()) ?? 0;
  }
}
