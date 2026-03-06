import 'package:drift/drift.dart';

/// Tabela de eventos de turno — registra tudo que acontece durante um turno
@DataClassName('EventoTurnoTable')
class EventosTurno extends Table {
  TextColumn get id => text()();
  TextColumn get fiscalId => text()();

  /// Tipo do evento: turno_iniciado, colab_alocado, colab_liberado,
  /// cafe_iniciado, cafe_encerrado, intervalo_iniciado, intervalo_encerrado,
  /// intervalo_marcado_feito, empacotador_adicionado, empacotador_removido
  TextColumn get tipo => text()();

  DateTimeColumn get timestamp => dateTime()();

  /// Nome do colaborador envolvido (snapshot histórico)
  TextColumn get colaboradorNome => text().nullable()();

  /// Nome do caixa envolvido (snapshot histórico)
  TextColumn get caixaNome => text().nullable()();

  /// Informação extra (motivo, duração, etc.)
  TextColumn get detalhe => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
