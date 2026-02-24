import 'package:drift/drift.dart';

/// Tabela de Fiscais (usuários do app)
@DataClassName('FiscalTable')
class Fiscais extends Table {
  // Primary Key
  TextColumn get id => text()();

  // Foreign Key para auth.users do Supabase
  TextColumn get userId => text().unique()();

  // Dados pessoais
  TextColumn get nome => text().withLength(min: 1, max: 100)();
  TextColumn get cpf => text().withLength(min: 11, max: 11).nullable()();
  TextColumn get telefone => text().withLength(max: 15).nullable()();

  // Dados da loja
  TextColumn get lojaNome => text().withDefault(const Constant('Minha Loja'))();
  TextColumn get lojaHorarioAbertura => text().withDefault(const Constant('08:00'))();
  TextColumn get lojaHorarioFechamento => text().withDefault(const Constant('21:00'))();
  TextColumn get lojaHorarioDomingoAbertura => text().withDefault(const Constant('08:00'))();
  TextColumn get lojaHorarioDomingoFechamento => text().withDefault(const Constant('13:00'))();

  // Preferências (JSON armazenado como texto)
  TextColumn get preferencias => text().nullable()();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // Timestamp de última sincronização com Supabase
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
