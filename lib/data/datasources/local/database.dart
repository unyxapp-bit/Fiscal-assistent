import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Imports das tabelas
import 'tables/fiscais_table.dart';
import 'tables/colaboradores_table.dart';
import 'tables/caixas_table.dart';
import 'tables/turnos_table.dart';
import 'tables/alocacoes_table.dart';

// Imports dos DAOs
import 'daos/fiscal_dao.dart';
import 'daos/colaborador_dao.dart';
import 'daos/caixa_dao.dart';
import 'daos/alocacao_dao.dart';

// Este arquivo será gerado pelo build_runner
part 'database.g.dart';

/// Database principal do app - SQLite local usando Drift
@DriftDatabase(
  tables: [
    Fiscais,
    Colaboradores,
    Caixas,
    TurnosEscala,
    Alocacoes,
  ],
  daos: [
    FiscalDao,
    ColaboradorDao,
    CaixaDao,
    AlocacaoDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Futuras migrations vão aqui
      },
      beforeOpen: (details) async {
        // Habilitar foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

/// Abre conexão com o banco de dados SQLite
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fiscal_assistant.db'));
    return NativeDatabase(file);
  });
}
