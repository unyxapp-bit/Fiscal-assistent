import 'package:drift/drift.dart';
import 'colaboradores_table.dart';

/// Tabela de Turnos da Escala
@DataClassName('TurnoTable')
class TurnosEscala extends Table {
  // Primary Key
  TextColumn get id => text()();

  // Foreign Keys
  TextColumn get escalaId => text()(); // Vamos criar tabela escalas depois
  TextColumn get colaboradorId => text().references(Colaboradores, #id, onDelete: KeyAction.cascade)();

  // Data do turno
  DateTimeColumn get data => dateTime()();

  // Horários previstos (formato HH:mm armazenado como texto)
  TextColumn get entradaPrevista => text().nullable()();
  TextColumn get intervaloPrevisto => text().nullable()();
  TextColumn get retornoPrevisto => text().nullable()();
  TextColumn get saidaPrevista => text().nullable()();

  // Status
  BoolColumn get ehFolga => boolean().withDefault(const Constant(false))();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  // Índices
  @override
  List<Set<Column>> get uniqueKeys => [
    {colaboradorId, data}, // Um colaborador só tem 1 turno por dia
  ];
}
