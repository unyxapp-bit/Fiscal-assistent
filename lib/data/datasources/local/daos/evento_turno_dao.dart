import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/eventos_turno_table.dart';

part 'evento_turno_dao.g.dart';

@DriftAccessor(tables: [EventosTurno])
class EventoTurnoDao extends DatabaseAccessor<AppDatabase>
    with _$EventoTurnoDaoMixin {
  EventoTurnoDao(super.db);

  /// Insere um evento
  Future<void> inserir(EventosTurnoCompanion entry) =>
      into(eventosTurno).insert(entry);

  /// Busca todos os eventos de hoje para um fiscal
  Future<List<EventoTurnoTable>> getEventosHoje(String fiscalId) {
    final hoje = DateTime.now();
    final inicioDia =
        DateTime(hoje.year, hoje.month, hoje.day, 0, 0, 0);
    final fimDia =
        DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);
    return (select(eventosTurno)
          ..where((e) =>
              e.fiscalId.equals(fiscalId) &
              e.timestamp.isBiggerOrEqualValue(inicioDia) &
              e.timestamp.isSmallerOrEqualValue(fimDia))
          ..orderBy([(e) => OrderingTerm.asc(e.timestamp)]))
        .get();
  }

  /// Apaga eventos de hoje (chamado ao iniciar novo turno)
  Future<void> limparHoje(String fiscalId) {
    final hoje = DateTime.now();
    final inicioDia =
        DateTime(hoje.year, hoje.month, hoje.day, 0, 0, 0);
    return (delete(eventosTurno)
          ..where((e) =>
              e.fiscalId.equals(fiscalId) &
              e.timestamp.isBiggerOrEqualValue(inicioDia)))
        .go();
  }
}
