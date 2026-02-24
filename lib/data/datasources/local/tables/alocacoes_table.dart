import 'package:drift/drift.dart';
import 'colaboradores_table.dart';
import 'caixas_table.dart';

/// Tabela de Alocações (colaborador em caixa)
@DataClassName('AlocacaoTable')
class Alocacoes extends Table {
  // Primary Key
  TextColumn get id => text()();

  // Foreign Keys
  TextColumn get colaboradorId => text().references(Colaboradores, #id, onDelete: KeyAction.cascade)();
  TextColumn get caixaId => text().references(Caixas, #id, onDelete: KeyAction.cascade)();
  TextColumn get turnoEscalaId => text().nullable()();

  // Timestamps da alocação
  DateTimeColumn get alocadoEm => dateTime()();
  DateTimeColumn get liberadoEm => dateTime().nullable()();

  // Detalhes
  TextColumn get motivoLiberacao => text().nullable()(); // 'intervalo', 'cafe', 'saida', etc
  TextColumn get alocadoPor => text().nullable()(); // ID do fiscal que fez a alocação
  TextColumn get observacoes => text().nullable()();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
