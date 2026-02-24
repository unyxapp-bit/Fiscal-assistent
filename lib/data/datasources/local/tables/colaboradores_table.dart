import 'package:drift/drift.dart';
import 'fiscais_table.dart';

/// Tabela de Colaboradores
@DataClassName('ColaboradorTable')
class Colaboradores extends Table {
  // Primary Key
  TextColumn get id => text()();

  // Foreign Keys
  TextColumn get fiscalId => text().references(Fiscais, #id, onDelete: KeyAction.cascade)();

  // Dados do colaborador
  TextColumn get nome => text().withLength(min: 1, max: 100)();
  TextColumn get departamento => text()(); // 'caixa', 'fiscal', 'pacote', 'self'
  TextColumn get avatarIniciais => text().withLength(max: 2).nullable()();
  BoolColumn get ativo => boolean().withDefault(const Constant(true))();
  TextColumn get observacoes => text().nullable()();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
