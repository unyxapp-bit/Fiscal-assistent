// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'colaborador_dao.dart';

// ignore_for_file: type=lint
mixin _$ColaboradorDaoMixin on DatabaseAccessor<AppDatabase> {
  $ColaboradoresTable get colaboradores => attachedDatabase.colaboradores;
  ColaboradorDaoManager get managers => ColaboradorDaoManager(this);
}

class ColaboradorDaoManager {
  final _$ColaboradorDaoMixin _db;
  ColaboradorDaoManager(this._db);
  $$ColaboradoresTableTableManager get colaboradores =>
      $$ColaboradoresTableTableManager(_db.attachedDatabase, _db.colaboradores);
}
