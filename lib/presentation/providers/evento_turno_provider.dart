import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/remote/supabase_client.dart';
import '../../domain/entities/evento_turno.dart';
import '../../domain/entities/relatorio_dia.dart';

/// Provider responsável por registrar todos os eventos do turno e
/// gerar o relatório ao encerrar.
/// 
/// ✅ Migrado para usar **apenas Supabase** (removido SQLite/Drift)
class EventoTurnoProvider with ChangeNotifier {
  EventoTurnoProvider();

  SupabaseClient get _supabase => SupabaseClientManager.client;

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

  /// Carrega eventos de hoje e relatórios anteriores apenas do Supabase
  /// ✅ Versão simplificada (removido SQLite)
  Future<void> load(String fiscalId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Carrega eventos de hoje do Supabase
      final hoje = DateTime.now();
      final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
      final supaRows = await _supabase
          .from('eventos_turno')
          .select()
          .eq('fiscal_id', fiscalId)
          .gte('timestamp', inicioDia.toIso8601String())
          .order('timestamp', ascending: true);
      _eventos = (supaRows as List).map(_eventoFromSupabase).toList();

      // Verifica se há turno ativo (turno_iniciado nos eventos de hoje)
      final inicio = _eventos
          .where((e) => e.tipo == TipoEvento.turnoIniciado)
          .lastOrNull;
      if (inicio != null) {
        _turnoAtivo = true;
        _turnoIniciadoEm = inicio.timestamp;
      }

      // Carrega relatórios anteriores do Supabase
      final supaRels = await _supabase
          .from('relatorios_dia')
          .select()
          .eq('fiscal_id', fiscalId)
          .order('turno_iniciado_em', ascending: false)
          .limit(30);
      _relatorios =
          (supaRels as List).map(_relatorioFromSupabase).toList();
    } catch (e) {
      debugPrint('[EventoTurnoProvider] Erro ao carregar: $e');
      _eventos = [];
      _relatorios = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Registra um evento apenas no Supabase
  /// ✅ Versão simplificada (removido SQLite)
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

    // Insere direto no Supabase
    try {
      await _supabase.from('eventos_turno').insert({
        'id': evento.id,
        'fiscal_id': evento.fiscalId,
        'tipo': evento.tipo.valor,
        'timestamp': evento.timestamp.toIso8601String(),
        'colaborador_nome': evento.colaboradorNome,
        'caixa_nome': evento.caixaNome,
        'detalhe': evento.detalhe,
      });
    } catch (e) {
      debugPrint('[EventoTurnoProvider] Erro ao registrar evento: $e');
      rethrow;
    }

    _eventos.add(evento);

    if (tipo == TipoEvento.turnoIniciado) {
      _turnoAtivo = true;
      _turnoIniciadoEm = evento.timestamp;
    }

    notifyListeners();
  }

  /// Encerra o turno e gera o relatório
  /// ✅ Versão simplificada (removido SQLite)
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

    // Insere direto no Supabase
    try {
      await _supabase.from('relatorios_dia').insert({
        'id': relatorio.id,
        'fiscal_id': relatorio.fiscalId,
        'data_str': relatorio.dataStr,
        'turno_iniciado_em': relatorio.turnoIniciadoEm.toIso8601String(),
        'turno_encerrado_em': relatorio.turnoEncerradoEm.toIso8601String(),
        'total_alocacoes': relatorio.totalAlocacoes,
        'total_colaboradores': relatorio.totalColaboradores,
        'total_cafes': relatorio.totalCafes,
        'total_intervalos': relatorio.totalIntervalos,
        'total_empacotadores': relatorio.totalEmpacotadores,
        'eventos_json': eventosJson,
      });
    } catch (e) {
      debugPrint('[EventoTurnoProvider] Erro ao encerrar turno: $e');
      rethrow;
    }

    _relatorios = [relatorio, ..._relatorios];
    _turnoAtivo = false;

    notifyListeners();
    return relatorio;
  }

  // ── Helpers de conversão ───────────────────────────────────────────────

  EventoTurno _eventoFromSupabase(dynamic json) => EventoTurno(
        id: json['id'] as String,
        fiscalId: json['fiscal_id'] as String,
        tipo: TipoEvento.fromValor(json['tipo'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
        colaboradorNome: json['colaborador_nome'] as String?,
        caixaNome: json['caixa_nome'] as String?,
        detalhe: json['detalhe'] as String?,
      );

  RelatorioDia _relatorioFromSupabase(dynamic json) {
    List<EventoTurno> evs = [];
    try {
      final raw = json['eventos_json'];
      if (raw != null) {
        final list = jsonDecode(raw as String) as List<dynamic>;
        evs = list
            .map((j) => EventoTurno.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return RelatorioDia(
      id: json['id'] as String,
      fiscalId: json['fiscal_id'] as String,
      dataStr: json['data_str'] as String,
      turnoIniciadoEm: DateTime.parse(json['turno_iniciado_em'] as String),
      turnoEncerradoEm: DateTime.parse(json['turno_encerrado_em'] as String),
      totalAlocacoes: (json['total_alocacoes'] as num?)?.toInt() ?? 0,
      totalColaboradores: (json['total_colaboradores'] as num?)?.toInt() ?? 0,
      totalCafes: (json['total_cafes'] as num?)?.toInt() ?? 0,
      totalIntervalos: (json['total_intervalos'] as num?)?.toInt() ?? 0,
      totalEmpacotadores: (json['total_empacotadores'] as num?)?.toInt() ?? 0,
      eventos: evs,
    );
  }
}
