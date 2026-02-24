import 'package:drift/drift.dart';
import 'fiscais_table.dart';

/// Tabela de Caixas (PDVs e Self Checkouts)
@DataClassName('CaixaTable')
class Caixas extends Table {
  // Primary Key
  TextColumn get id => text()();

  // Foreign Keys
  TextColumn get fiscalId => text().references(Fiscais, #id, onDelete: KeyAction.cascade)();

  // Dados do caixa
  IntColumn get numero => integer()(); // 1-8 para PDVs, 11-13 para Self
  TextColumn get tipo => text()(); // 'rapido', 'normal', 'self'
  BoolColumn get ativo => boolean().withDefault(const Constant(true))();
  BoolColumn get emManutencao => boolean().withDefault(const Constant(false))();
  TextColumn get observacoes => text().nullable()();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  // Índices para queries rápidas
  @override
  List<Set<Column>> get uniqueKeys => [
    {fiscalId, numero}, // Um fiscal não pode ter 2 caixas com mesmo número
  ];
}
