import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/relatorios_dia_table.dart';

part 'relatorio_dia_dao.g.dart';

@DriftAccessor(tables: [RelatoriosDia])
class RelatorioDiaDao extends DatabaseAccessor<AppDatabase>
    with _$RelatorioDiaDaoMixin {
  RelatorioDiaDao(super.db);

  /// Insere um relatório
  Future<void> inserir(RelatoriosDiaCompanion entry) =>
      into(relatoriosDia).insert(entry);

  /// Busca todos os relatórios de um fiscal, mais recentes primeiro
  Future<List<RelatorioDiaTable>> getRelatorios(String fiscalId) =>
      (select(relatoriosDia)
            ..where((r) => r.fiscalId.equals(fiscalId))
            ..orderBy(
                [(r) => OrderingTerm.desc(r.turnoIniciadoEm)]))
          .get();

  /// Busca os últimos N relatórios
  Future<List<RelatorioDiaTable>> getUltimos(String fiscalId,
      {int limit = 30}) =>
      (select(relatoriosDia)
            ..where((r) => r.fiscalId.equals(fiscalId))
            ..orderBy(
                [(r) => OrderingTerm.desc(r.turnoIniciadoEm)])
            ..limit(limit))
          .get();
}
