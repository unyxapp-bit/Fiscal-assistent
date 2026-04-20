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
  double? amount;
  final String? sender;
  final String rawMessage;
  final DateTime eventDate;
  String status;
  final double confidence;
  final String? mediaType; // 'audio' | 'foto' | null
  bool needsReview;

  FiscalEvent({
    required this.id,
    required this.category,
    required this.description,
    this.employeeName,
    this.amount,
    this.sender,
    required this.rawMessage,
    required this.eventDate,
    required this.status,
    required this.confidence,
    this.mediaType,
    required this.needsReview,
  });

  factory FiscalEvent.fromMap(Map<String, dynamic> m) => FiscalEvent(
        id: m['id'] as int,
        category: m['category'] as String? ?? 'aviso_geral',
        description: m['description'] as String? ?? '',
        employeeName: m['employee_name'] as String?,
        amount: m['amount'] != null ? (m['amount'] as num).toDouble() : null,
        sender: m['sender'] as String?,
        rawMessage: m['raw_message'] as String? ?? '',
        eventDate: DateTime.parse(
            (m['event_date'] ?? m['created_at']) as String),
        status: m['status'] as String? ?? 'pending',
        confidence: (m['confidence'] as num?)?.toDouble() ?? 0.5,
        mediaType: m['media_type'] as String?,
        needsReview: m['needs_review'] as bool? ?? false,
      );
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

  Future<void> preencherMidia({
    required FiscalEvent event,
    required String category,
    required String description,
    String? employeeName,
    double? amount,
  }) async {
    try {
      await _client.from(_table).update({
        'category': category,
        'description': description,
        'employee_name':
            employeeName?.isNotEmpty == true ? employeeName : null,
        'amount': amount,
        'needs_review': false,
        'status': 'pending',
      }).eq('id', event.id);

      event.category = category;
      event.description = description;
      event.employeeName =
          employeeName?.isNotEmpty == true ? employeeName : null;
      event.amount = amount;
      event.needsReview = false;
      notifyListeners();
    } catch (e) {
      rethrow;
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
