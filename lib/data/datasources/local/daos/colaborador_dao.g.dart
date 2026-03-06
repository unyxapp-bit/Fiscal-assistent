// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'colaborador_dao.dart';

// ignore_for_file: type=lint
mixin _$ColaboradorDaoMixin on DatabaseAccessor<AppDatabase> {
  $FiscaisTable get fiscais => attachedDatabase.fiscais;
  $ColaboradoresTable get colaboradores => attachedDatabase.colaboradores;
  ColaboradorDaoManager get managers => ColaboradorDaoManager(this);
}

class ColaboradorDaoManager {
  final _$ColaboradorDaoMixin _db;
  ColaboradorDaoManager(this._db);
  $$FiscaisTableTableManager get fiscais =>
      $$FiscaisTableTableManager(_db.attachedDatabase, _db.fiscais);
  $$ColaboradoresTableTableManager get colaboradores =>
      $$ColaboradoresTableTableManager(_db.attachedDatabase, _db.colaboradores);
}
