// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fiscal_dao.dart';

// ignore_for_file: type=lint
mixin _$FiscalDaoMixin on DatabaseAccessor<AppDatabase> {
  $FiscaisTable get fiscais => attachedDatabase.fiscais;
  FiscalDaoManager get managers => FiscalDaoManager(this);
}

class FiscalDaoManager {
  final _$FiscalDaoMixin _db;
  FiscalDaoManager(this._db);
  $$FiscaisTableTableManager get fiscais =>
      $$FiscaisTableTableManager(_db.attachedDatabase, _db.fiscais);
}
