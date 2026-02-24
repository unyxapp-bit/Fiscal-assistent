import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/alocacoes_table.dart';
import '../tables/colaboradores_table.dart';
import '../tables/caixas_table.dart';

part 'alocacao_dao.g.dart';

/// DAO para operações com Alocações
@DriftAccessor(tables: [Alocacoes, Colaboradores, Caixas])
class AlocacaoDao extends DatabaseAccessor<AppDatabase> with _$AlocacaoDaoMixin {
  AlocacaoDao(super.db);

  /// Busca alocações ativas (não liberadas)
  Future<List<AlocacaoTable>> getAlocacoesAtivas(String fiscalId) {
    final query = select(alocacoes).join([
      innerJoin(colaboradores, colaboradores.id.equalsExp(alocacoes.colaboradorId)),
    ])
      ..where(
        colaboradores.fiscalId.equals(fiscalId) & alocacoes.liberadoEm.isNull(),
      )
      ..orderBy([OrderingTerm(expression: alocacoes.alocadoEm)]);

    return query.map((row) => row.readTable(alocacoes)).get();
  }

  /// Busca alocação ativa de um colaborador
  Future<AlocacaoTable?> getAlocacaoAtivaColaborador(String colaboradorId) {
    return (select(alocacoes)
          ..where((a) =>
              a.colaboradorId.equals(colaboradorId) & a.liberadoEm.isNull())
          ..orderBy([(a) => OrderingTerm(expression: a.alocadoEm, mode: OrderingMode.desc)]))
        .getSingleOrNull();
  }

  Future<AlocacaoTable?> getAlocacaoById(String id) {
    return (select(alocacoes)..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  /// Busca alocações de um colaborador em uma data específica
  Future<List<AlocacaoTable>> getAlocacoesColaboradorData(
    String colaboradorId,
    DateTime data,
  ) {
    final inicioDia = DateTime(data.year, data.month, data.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    return (select(alocacoes)
          ..where((a) =>
              a.colaboradorId.equals(colaboradorId) &
              a.alocadoEm.isBiggerOrEqualValue(inicioDia) &
              a.alocadoEm.isSmallerThanValue(fimDia))
          ..orderBy([(a) => OrderingTerm(expression: a.alocadoEm)]))
        .get();
  }

  /// Verifica se colaborador já usou um caixa hoje
  Future<bool> jaUsouCaixaHoje(String colaboradorId, String caixaId) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    final query = selectOnly(alocacoes)
      ..addColumns([alocacoes.id.count()])
      ..where(
        alocacoes.colaboradorId.equals(colaboradorId) &
            alocacoes.caixaId.equals(caixaId) &
            alocacoes.alocadoEm.isBiggerOrEqualValue(inicioDia) &
            alocacoes.alocadoEm.isSmallerThanValue(fimDia),
      );

    final result = await query.getSingle();
    final count = result.read(alocacoes.id.count()) ?? 0;
    return count > 0;
  }

  /// Busca caixas já usados por colaborador hoje
  Future<List<String>> getCaixasUsadosHoje(String colaboradorId) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    final query = selectOnly(alocacoes, distinct: true)
      ..addColumns([alocacoes.caixaId])
      ..where(
        alocacoes.colaboradorId.equals(colaboradorId) &
            alocacoes.alocadoEm.isBiggerOrEqualValue(inicioDia) &
            alocacoes.alocadoEm.isSmallerThanValue(fimDia),
      );

    final results = await query.get();
    return results.map((row) => row.read(alocacoes.caixaId)!).toList();
  }

  /// Insere nova alocação
  Future<void> insertAlocacao(AlocacaoTable alocacao) {
    return into(alocacoes).insertOnConflictUpdate(alocacao);
  }

  /// Libera alocação (marca como liberada)
  Future<int> liberarAlocacao(
    String id,
    DateTime liberadoEm,
    String motivo,
  ) {
    return (update(alocacoes)..where((a) => a.id.equals(id))).write(
      AlocacoesCompanion(
        liberadoEm: Value(liberadoEm),
        motivoLiberacao: Value(motivo),
      ),
    );
  }

  /// Stream de alocações ativas
  Stream<List<AlocacaoTable>> watchAlocacoesAtivas(String fiscalId) {
    final query = select(alocacoes).join([
      innerJoin(colaboradores, colaboradores.id.equalsExp(alocacoes.colaboradorId)),
    ])
      ..where(
        colaboradores.fiscalId.equals(fiscalId) & alocacoes.liberadoEm.isNull(),
      )
      ..orderBy([OrderingTerm(expression: alocacoes.alocadoEm)]);

    return query.map((row) => row.readTable(alocacoes)).watch();
  }

  /// Deleta alocação
  Future<int> deleteAlocacao(String id) {
    return (delete(alocacoes)..where((a) => a.id.equals(id))).go();
  }

  /// Histórico de alocações (últimas 100)
  Future<List<AlocacaoTable>> getHistoricoAlocacoes(String fiscalId) {
    final query = select(alocacoes).join([
      innerJoin(colaboradores, colaboradores.id.equalsExp(alocacoes.colaboradorId)),
    ])
      ..where(colaboradores.fiscalId.equals(fiscalId))
      ..orderBy([OrderingTerm(expression: alocacoes.alocadoEm, mode: OrderingMode.desc)])
      ..limit(100);

    return query.map((row) => row.readTable(alocacoes)).get();
  }
}
