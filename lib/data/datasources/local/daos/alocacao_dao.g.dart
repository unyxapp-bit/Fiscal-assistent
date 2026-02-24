// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alocacao_dao.dart';

// ignore_for_file: type=lint
mixin _$AlocacaoDaoMixin on DatabaseAccessor<AppDatabase> {
  $AlocacoesTable get alocacoes => attachedDatabase.alocacoes;
  $ColaboradoresTable get colaboradores => attachedDatabase.colaboradores;
  $CaixasTable get caixas => attachedDatabase.caixas;
  AlocacaoDaoManager get managers => AlocacaoDaoManager(this);
}

class AlocacaoDaoManager {
  final _$AlocacaoDaoMixin _db;
  AlocacaoDaoManager(this._db);
  $$AlocacoesTableTableManager get alocacoes =>
      $$AlocacoesTableTableManager(_db.attachedDatabase, _db.alocacoes);
  $$ColaboradoresTableTableManager get colaboradores =>
      $$ColaboradoresTableTableManager(_db.attachedDatabase, _db.colaboradores);
  $$CaixasTableTableManager get caixas =>
      $$CaixasTableTableManager(_db.attachedDatabase, _db.caixas);
}
