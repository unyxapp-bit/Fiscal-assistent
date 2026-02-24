// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caixa_dao.dart';

// ignore_for_file: type=lint
mixin _$CaixaDaoMixin on DatabaseAccessor<AppDatabase> {
  $CaixasTable get caixas => attachedDatabase.caixas;
  CaixaDaoManager get managers => CaixaDaoManager(this);
}

class CaixaDaoManager {
  final _$CaixaDaoMixin _db;
  CaixaDaoManager(this._db);
  $$CaixasTableTableManager get caixas =>
      $$CaixasTableTableManager(_db.attachedDatabase, _db.caixas);
}
