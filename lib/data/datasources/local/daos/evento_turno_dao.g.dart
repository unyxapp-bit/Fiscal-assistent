// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evento_turno_dao.dart';

// ignore_for_file: type=lint
mixin _$EventoTurnoDaoMixin on DatabaseAccessor<AppDatabase> {
  $EventosTurnoTable get eventosTurno => attachedDatabase.eventosTurno;
  EventoTurnoDaoManager get managers => EventoTurnoDaoManager(this);
}

class EventoTurnoDaoManager {
  final _$EventoTurnoDaoMixin _db;
  EventoTurnoDaoManager(this._db);
  $$EventosTurnoTableTableManager get eventosTurno =>
      $$EventosTurnoTableTableManager(_db.attachedDatabase, _db.eventosTurno);
}
