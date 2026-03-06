import 'package:drift/drift.dart';

/// Tabela de relatórios diários gerados ao encerrar o turno
@DataClassName('RelatorioDiaTable')
class RelatoriosDia extends Table {
  TextColumn get id => text()();
  TextColumn get fiscalId => text()();

  /// Data do turno (yyyy-MM-dd como texto para facilitar)
  TextColumn get dataStr => text()();

  DateTimeColumn get turnoIniciadoEm => dateTime()();
  DateTimeColumn get turnoEncerradoEm => dateTime()();

  // Totais calculados
  IntColumn get totalAlocacoes =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalColaboradores =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalCafes =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalIntervalos =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalEmpacotadores =>
      integer().withDefault(const Constant(0))();

  /// Eventos do turno serializados como JSON
  TextColumn get eventosJson => text().withDefault(const Constant('[]'))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
