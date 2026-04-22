import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────
//  MODELO
// ─────────────────────────────────────────────

class FiscalEvent {
  final int id;
  String category;
  String description;
  String? employeeName;
  String? colaboradorId;
  double? amount;
  final String? sender;
  final String rawMessage;
  final DateTime eventDate;
  String status;
  final double confidence;
  final String? mediaType;
  bool needsReview;
  // Fase 2 — novos campos (todos nullable para compatibilidade)
  DateTime? resolvedAt;
  String? resolvedBy;
  String? notes;
  int? caixaNumero;
  String? scheduledTime; // "HH:MM"
  String? turno;         // "manha" | "tarde" | "noite"
  String source;         // "whatsapp" | "manual" | "sistema"
  String priority;       // "baixa" | "normal" | "alta" | "critica"

  FiscalEvent({
    required this.id,
    required this.category,
    required this.description,
    this.employeeName,
    this.colaboradorId,
    this.amount,
    this.sender,
    required this.rawMessage,
    required this.eventDate,
    required this.status,
    required this.confidence,
    this.mediaType,
    required this.needsReview,
    this.resolvedAt,
    this.resolvedBy,
    this.notes,
    this.caixaNumero,
    this.scheduledTime,
    this.turno,
    this.source = 'whatsapp',
    this.priority = 'normal',
  });

  factory FiscalEvent.fromMap(Map<String, dynamic> m) => FiscalEvent(
        id: m['id'] as int,
        category: m['category'] as String? ?? 'aviso_geral',
        description: m['description'] as String? ?? '',
        employeeName: m['employee_name'] as String?,
        colaboradorId: m['colaborador_id'] as String?,
        amount: m['amount'] != null ? (m['amount'] as num).toDouble() : null,
        sender: m['sender'] as String?,
        rawMessage: m['raw_message'] as String? ?? '',
        eventDate: DateTime.parse(
            (m['event_date'] ?? m['created_at']) as String),
        status: m['status'] as String? ?? 'pending',
        confidence: (m['confidence'] as num?)?.toDouble() ?? 0.5,
        mediaType: m['media_type'] as String?,
        needsReview: m['needs_review'] as bool? ?? false,
        resolvedAt: m['resolved_at'] != null
            ? DateTime.parse(m['resolved_at'] as String)
            : null,
        resolvedBy: m['resolved_by'] as String?,
        notes: m['notes'] as String?,
        caixaNumero: m['caixa_numero'] as int?,
        scheduledTime: m['scheduled_time'] as String?,
        turno: m['turno'] as String?,
        source: m['source'] as String? ?? 'whatsapp',
        priority: m['priority'] as String? ?? 'normal',
      );

  bool get isAlta => priority == 'alta' || priority == 'critica';
  bool get isCritica => priority == 'critica';
}

// ─────────────────────────────────────────────
//  PROVIDER
// ─────────────────────────────────────────────

class FiscalEventsProvider with ChangeNotifier {
  final _client = Supabase.instance.client;
  static const _table = 'fiscal_events';

  List<FiscalEvent> _events = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;

  List<FiscalEvent> get events => _events;
  bool get loading => _loading;
  String? get error => _error;

  int get totalPendentes => _events.where((e) => e.status == 'pending').length;
  int get totalMidiasPendentes =>
      _events.where((e) => e.needsReview && e.status == 'pending').length;

  /// Callback disparado quando um colaborador acumula ≥2 eventos pendentes no mesmo dia.
  void Function(String colaboradorId, int count)? onAcumuloDetectado;

  /// Callback disparado quando chega evento de caixa com valor ≥ R$ 50.
  void Function(FiscalEvent event)? onValorAltoCaixa;

  /// Callback disparado quando colaborador tem ≥3 eventos em 7 dias (reincidência).
  void Function(String colaboradorId, int count)? onReincidencia;

  // ── Filtro por colaborador ────────────────────────────────────────────────

  /// Todos os eventos vinculados a um colaborador específico.
  List<FiscalEvent> eventosDoColaborador(String colaboradorId) =>
      _events.where((e) => e.colaboradorId == colaboradorId).toList();

  // ── Estatísticas ──────────────────────────────────────────────────────────

  /// Eventos dos últimos N dias (independente do status).
  List<FiscalEvent> eventosDosUltimosDias(int dias) {
    final limite = DateTime.now().subtract(Duration(days: dias));
    return _events.where((e) => e.eventDate.isAfter(limite)).toList();
  }

  /// Contagem de pendentes por categoria.
  Map<String, int> get contagemPorCategoria {
    final m = <String, int>{};
    for (final e in _events.where((e) => e.status == 'pending')) {
      m[e.category] = (m[e.category] ?? 0) + 1;
    }
    return m;
  }

  /// Total em valores absolutos de eventos de caixa com valor definido.
  double get totalCaixaValores {
    return _events
        .where((e) => e.category == 'caixa' && e.amount != null)
        .fold(0.0, (sum, e) => sum + e.amount!.abs());
  }

  /// Eventos de caixa dos últimos 7 dias, com valor, ordenados por data.
  List<FiscalEvent> get caixaEventosRecentes => _events
      .where((e) =>
          e.category == 'caixa' &&
          e.amount != null &&
          e.eventDate.isAfter(DateTime.now().subtract(const Duration(days: 7))))
      .toList();

  // ── Busca ─────────────────────────────────────────────────────────────────

  List<FiscalEvent> buscar(String query) {
    if (query.trim().isEmpty) return _events;
    final q = query.toLowerCase().trim();
    return _events.where((e) {
      return e.description.toLowerCase().contains(q) ||
          (e.employeeName?.toLowerCase().contains(q) ?? false) ||
          (e.sender?.toLowerCase().contains(q) ?? false) ||
          e.rawMessage.toLowerCase().contains(q);
    }).toList();
  }

  // ── Carregamento ──────────────────────────────────────────────────────────

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _client
          .from(_table)
          .select()
          .order('event_date', ascending: false)
          .limit(200);

      _events = (data as List)
          .map((e) => FiscalEvent.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'Erro ao carregar eventos: $e';
      if (kDebugMode) debugPrint('[FiscalEventsProvider] $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Realtime ──────────────────────────────────────────────────────────────

  void subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = _client
        .channel('fiscal_events_rt')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: _table,
          callback: (payload) {
            final e = FiscalEvent.fromMap(payload.newRecord);
            _events.insert(0, e);
            notifyListeners();

            // Alerta: valor alto de caixa (≥ R$ 50)
            if (e.category == 'caixa' &&
                (e.amount ?? 0) >= 50 &&
                onValorAltoCaixa != null) {
              onValorAltoCaixa!(e);
            }

            // Detecta acúmulo de eventos para o mesmo colaborador no mesmo dia
            if (e.colaboradorId != null && onAcumuloDetectado != null) {
              final hoje = DateTime.now();
              final count = _events.where((ev) =>
                ev.colaboradorId == e.colaboradorId &&
                ev.status == 'pending' &&
                ev.eventDate.year == hoje.year &&
                ev.eventDate.month == hoje.month &&
                ev.eventDate.day == hoje.day,
              ).length;
              if (count >= 2) onAcumuloDetectado!(e.colaboradorId!, count);
            }

            // Detecta reincidência: ≥3 eventos do mesmo colaborador nos últimos 7 dias
            if (e.colaboradorId != null && onReincidencia != null) {
              final limite = DateTime.now().subtract(const Duration(days: 7));
              final count = _events.where((ev) =>
                ev.colaboradorId == e.colaboradorId &&
                ev.eventDate.isAfter(limite),
              ).length;
              if (count >= 3) onReincidencia!(e.colaboradorId!, count);
            }
          },
        )
        .subscribe();
  }

  void unsubscribeRealtime() {
    _channel?.unsubscribe();
    _channel = null;
  }

  // ── Ações ────────────────────────────────────────────────────────────────

  Future<void> atualizarStatus(FiscalEvent event, String novoStatus) async {
    final statusAnterior = event.status;
    event.status = novoStatus;
    notifyListeners();

    try {
      await _client
          .from(_table)
          .update({'status': novoStatus}).eq('id', event.id);
    } catch (e) {
      event.status = statusAnterior;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> recategorizar({
    required FiscalEvent event,
    required String category,
    required String description,
    String? employeeName,
    double? amount,
    String? colaboradorId,
  }) async {
    final oldCategory = event.category;
    final oldDescription = event.description;
    final oldEmployee = event.employeeName;
    final oldAmount = event.amount;
    final oldColaboradorId = event.colaboradorId;

    event.category = category;
    event.description = description;
    event.employeeName = employeeName?.isNotEmpty == true ? employeeName : null;
    event.amount = amount;
    event.colaboradorId = colaboradorId;
    notifyListeners();

    try {
      await _client.from(_table).update({
        'category': category,
        'description': description,
        'employee_name':
            employeeName?.isNotEmpty == true ? employeeName : null,
        'amount': amount,
        'colaborador_id': colaboradorId,
      }).eq('id', event.id);
    } catch (e) {
      event.category = oldCategory;
      event.description = oldDescription;
      event.employeeName = oldEmployee;
      event.amount = oldAmount;
      event.colaboradorId = oldColaboradorId;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> preencherMidia({
    required FiscalEvent event,
    required String category,
    required String description,
    String? employeeName,
    double? amount,
    String? colaboradorId,
  }) async {
    try {
      await _client.from(_table).update({
        'category': category,
        'description': description,
        'employee_name':
            employeeName?.isNotEmpty == true ? employeeName : null,
        'amount': amount,
        'colaborador_id': colaboradorId,
        'needs_review': false,
        'status': 'pending',
      }).eq('id', event.id);

      event.category = category;
      event.description = description;
      event.employeeName =
          employeeName?.isNotEmpty == true ? employeeName : null;
      event.amount = amount;
      event.colaboradorId = colaboradorId;
      event.needsReview = false;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Resolve um evento gravando resolved_at e resolved_by.
  Future<void> resolver(FiscalEvent event, {String? resolvedBy}) async {
    final now = DateTime.now();
    final anterior = event.status;
    event.status = 'resolved';
    event.resolvedAt = now;
    event.resolvedBy = resolvedBy;
    notifyListeners();
    try {
      await _client.from(_table).update({
        'status': 'resolved',
        'resolved_at': now.toIso8601String(),
        'resolved_by': resolvedBy,
      }).eq('id', event.id);
    } catch (e) {
      event.status = anterior;
      event.resolvedAt = null;
      event.resolvedBy = null;
      notifyListeners();
      rethrow;
    }
  }

  /// Adiciona ou atualiza a nota manual de um evento.
  Future<void> adicionarNota(FiscalEvent event, String nota) async {
    final anterior = event.notes;
    event.notes = nota.trim().isEmpty ? null : nota.trim();
    notifyListeners();
    try {
      await _client.from(_table).update({
        'notes': event.notes,
      }).eq('id', event.id);
    } catch (e) {
      event.notes = anterior;
      notifyListeners();
      rethrow;
    }
  }

  /// Cria um evento manualmente (sem WhatsApp).
  Future<FiscalEvent?> criarManual({
    required String category,
    required String description,
    String? employeeName,
    String? colaboradorId,
    double? amount,
    String priority = 'normal',
    String? notes,
  }) async {
    try {
      final data = await _client.from(_table).insert({
        'category': category,
        'description': description,
        'employee_name': employeeName?.isNotEmpty == true ? employeeName : null,
        'colaborador_id': colaboradorId,
        'amount': amount,
        'raw_message': description,
        'event_date': DateTime.now().toIso8601String(),
        'status': 'pending',
        'confidence': 1.0,
        'needs_review': false,
        'source': 'manual',
        'priority': priority,
        'notes': notes?.isNotEmpty == true ? notes : null,
      }).select().single();
      final evento = FiscalEvent.fromMap(data);
      _events.insert(0, evento);
      notifyListeners();
      return evento;
    } catch (e) {
      if (kDebugMode) debugPrint('[FiscalEventsProvider] criarManual: $e');
      return null;
    }
  }

  Future<void> excluir(int id) async {
    final idx = _events.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final backup = _events[idx];
    _events.removeAt(idx);
    notifyListeners();

    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      _events.insert(idx, backup);
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    unsubscribeRealtime();
    super.dispose();
  }
}
