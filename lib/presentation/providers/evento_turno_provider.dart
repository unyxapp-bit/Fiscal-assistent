import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/local/daos/evento_turno_dao.dart';
import '../../data/datasources/local/daos/relatorio_dia_dao.dart';
import '../../data/datasources/local/database.dart';
import '../../domain/entities/evento_turno.dart';
import '../../domain/entities/relatorio_dia.dart';

/// Provider responsável por registrar todos os eventos do turno e
/// gerar o relatório ao encerrar.
class EventoTurnoProvider with ChangeNotifier {
  final EventoTurnoDao _eventoDao;
  final RelatorioDiaDao _relatorioDao;

  EventoTurnoProvider({
    required EventoTurnoDao eventoDao,
    required RelatorioDiaDao relatorioDao,
  })  : _eventoDao = eventoDao,
        _relatorioDao = relatorioDao;

  List<EventoTurno> _eventos = [];
  List<RelatorioDia> _relatorios = [];
  bool _turnoAtivo = false;
  DateTime? _turnoIniciadoEm;
  bool _isLoading = false;

  List<EventoTurno> get eventos => _eventos;
  List<RelatorioDia> get relatorios => _relatorios;
  bool get turnoAtivo => _turnoAtivo;
  DateTime? get turnoIniciadoEm => _turnoIniciadoEm;
  bool get isLoading => _isLoading;

  /// Carrega eventos de hoje e relatórios anteriores do banco
  Future<void> load(String fiscalId) async {
    _isLoading = true;
    notifyListeners();

    final rows = await _eventoDao.getEventosHoje(fiscalId);
    _eventos = rows.map(_fromTable).toList();

    // Verifica se há turno ativo (turno_iniciado nos eventos de hoje)
    final inicio = _eventos
        .where((e) => e.tipo == TipoEvento.turnoIniciado)
        .lastOrNull;
    if (inicio != null) {
      _turnoAtivo = true;
      _turnoIniciadoEm = inicio.timestamp;
    }

    final relRows = await _relatorioDao.getUltimos(fiscalId);
    _relatorios = relRows.map(_relFromTable).toList();

    _isLoading = false;
    notifyListeners();
  }

  /// Registra um evento e persiste no banco
  Future<void> registrar({
    required String fiscalId,
    required TipoEvento tipo,
    String? colaboradorNome,
    String? caixaNome,
    String? detalhe,
  }) async {
    final evento = EventoTurno(
      id: const Uuid().v4(),
      fiscalId: fiscalId,
      tipo: tipo,
      timestamp: DateTime.now(),
      colaboradorNome: colaboradorNome,
      caixaNome: caixaNome,
      detalhe: detalhe,
    );

    await _eventoDao.inserir(EventosTurnoCompanion.insert(
      id: evento.id,
      fiscalId: evento.fiscalId,
      tipo: evento.tipo.valor,
      timestamp: evento.timestamp,
      colaboradorNome: Value(evento.colaboradorNome),
      caixaNome: Value(evento.caixaNome),
      detalhe: Value(evento.detalhe),
    ));

    _eventos.add(evento);

    if (tipo == TipoEvento.turnoIniciado) {
      _turnoAtivo = true;
      _turnoIniciadoEm = evento.timestamp;
    }

    notifyListeners();
  }

  /// Encerra o turno e gera o relatório
  Future<RelatorioDia?> encerrarTurno(String fiscalId) async {
    if (!_turnoAtivo || _turnoIniciadoEm == null) return null;

    final agora = DateTime.now();
    final hoje = agora;

    // Conta totais
    int alocacoes = _eventos
        .where((e) => e.tipo == TipoEvento.colaboradorAlocado)
        .length;
    final Set<String> colaboradores = _eventos
        .where((e) => e.colaboradorNome != null)
        .map((e) => e.colaboradorNome!)
        .toSet();
    int cafes =
        _eventos.where((e) => e.tipo == TipoEvento.cafeIniciado).length;
    int intervalos = _eventos
        .where((e) => e.tipo == TipoEvento.intervaloIniciado)
        .length;
    int empacotadores = _eventos
        .where((e) => e.tipo == TipoEvento.empacotadorAdicionado)
        .length;

    final dataStr =
        '${hoje.year.toString().padLeft(4, '0')}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';

    final eventosJson =
        jsonEncode(_eventos.map((e) => e.toJson()).toList());

    final relatorio = RelatorioDia(
      id: const Uuid().v4(),
      fiscalId: fiscalId,
      dataStr: dataStr,
      turnoIniciadoEm: _turnoIniciadoEm!,
      turnoEncerradoEm: agora,
      totalAlocacoes: alocacoes,
      totalColaboradores: colaboradores.length,
      totalCafes: cafes,
      totalIntervalos: intervalos,
      totalEmpacotadores: empacotadores,
      eventos: List.from(_eventos),
    );

    await _relatorioDao.inserir(RelatoriosDiaCompanion.insert(
      id: relatorio.id,
      fiscalId: relatorio.fiscalId,
      dataStr: relatorio.dataStr,
      turnoIniciadoEm: relatorio.turnoIniciadoEm,
      turnoEncerradoEm: relatorio.turnoEncerradoEm,
      totalAlocacoes: Value(relatorio.totalAlocacoes),
      totalColaboradores: Value(relatorio.totalColaboradores),
      totalCafes: Value(relatorio.totalCafes),
      totalIntervalos: Value(relatorio.totalIntervalos),
      totalEmpacotadores: Value(relatorio.totalEmpacotadores),
      eventosJson: Value(eventosJson),
    ));

    _relatorios = [relatorio, ..._relatorios];
    _turnoAtivo = false;

    notifyListeners();
    return relatorio;
  }

  // ── Helpers de conversão ───────────────────────────────────────────────

  EventoTurno _fromTable(EventoTurnoTable row) => EventoTurno(
        id: row.id,
        fiscalId: row.fiscalId,
        tipo: TipoEvento.fromValor(row.tipo),
        timestamp: row.timestamp,
        colaboradorNome: row.colaboradorNome,
        caixaNome: row.caixaNome,
        detalhe: row.detalhe,
      );

  RelatorioDia _relFromTable(RelatorioDiaTable row) {
    List<EventoTurno> evs = [];
    try {
      final list = jsonDecode(row.eventosJson) as List<dynamic>;
      evs = list
          .map((j) => EventoTurno.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {}
    return RelatorioDia(
      id: row.id,
      fiscalId: row.fiscalId,
      dataStr: row.dataStr,
      turnoIniciadoEm: row.turnoIniciadoEm,
      turnoEncerradoEm: row.turnoEncerradoEm,
      totalAlocacoes: row.totalAlocacoes,
      totalColaboradores: row.totalColaboradores,
      totalCafes: row.totalCafes,
      totalIntervalos: row.totalIntervalos,
      totalEmpacotadores: row.totalEmpacotadores,
      eventos: evs,
    );
  }
}
