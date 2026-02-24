import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/remote/supabase_client.dart';
import '../../data/services/notification_service.dart';

/// Registro de pausa de um colaborador
class PausaCafe {
  final String id;
  final String colaboradorId;
  final String colaboradorNome;
  final DateTime iniciadoEm;
  final int duracaoMinutos; // padrão 15
  DateTime? finalizadoEm;
  bool alertaDisparado;

  PausaCafe({
    required this.id,
    required this.colaboradorId,
    required this.colaboradorNome,
    required this.iniciadoEm,
    this.duracaoMinutos = 15,
    this.finalizadoEm,
    this.alertaDisparado = false,
  });

  factory PausaCafe.fromMap(Map<String, dynamic> m) => PausaCafe(
        id: m['id'] as String,
        colaboradorId: m['colaborador_id'] as String,
        colaboradorNome: m['colaborador_nome'] as String,
        iniciadoEm: DateTime.parse(m['iniciado_em'] as String),
        duracaoMinutos: m['duracao_minutos'] as int? ?? 15,
        finalizadoEm: m['finalizado_em'] != null
            ? DateTime.parse(m['finalizado_em'] as String)
            : null,
      );

  Map<String, dynamic> toMap(String fiscalId) => {
        'id': id,
        'fiscal_id': fiscalId,
        'colaborador_id': colaboradorId,
        'colaborador_nome': colaboradorNome,
        'iniciado_em': iniciadoEm.toIso8601String(),
        'duracao_minutos': duracaoMinutos,
        'finalizado_em': finalizadoEm?.toIso8601String(),
      };

  bool get ativo => finalizadoEm == null;

  Duration get tempoDecorrido =>
      (finalizadoEm ?? DateTime.now()).difference(iniciadoEm);

  Duration get tempoRestante {
    final duracao = Duration(minutes: duracaoMinutos);
    final restante = duracao - tempoDecorrido;
    return restante.isNegative ? Duration.zero : restante;
  }

  int get minutosDecorridos => tempoDecorrido.inMinutes;
  bool get expirou => tempoDecorrido.inMinutes >= duracaoMinutos;
  bool get emAtraso => tempoDecorrido.inMinutes > duracaoMinutos;
  int get minutosExcedidos =>
      emAtraso ? tempoDecorrido.inMinutes - duracaoMinutos : 0;
}

/// Provider para gerenciar intervalos/café com persistência no Supabase
class CafeProvider with ChangeNotifier {
  static const _table = 'pausas_cafe';

  final List<PausaCafe> _pausas = [];
  Timer? _timer;

  CafeProvider() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _verificarAlertasEAtualizar();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Getters
  List<PausaCafe> get pausas => List.unmodifiable(_pausas);
  List<PausaCafe> get pausasAtivas =>
      _pausas.where((p) => p.ativo).toList();
  List<PausaCafe> get pausasFinalizadas =>
      _pausas.where((p) => !p.ativo).toList();
  List<PausaCafe> get pausasEmAtraso =>
      _pausas.where((p) => p.ativo && p.emAtraso).toList();

  int get totalAtivos => pausasAtivas.length;
  int get totalEmAtraso => pausasEmAtraso.length;
  int get totalHoje => _pausas.length;

  String get _fiscalId => SupabaseClientManager.currentUserId!;

  bool colaboradorEmPausa(String colaboradorId) =>
      _pausas.any((p) => p.colaboradorId == colaboradorId && p.ativo);

  PausaCafe? getPausaAtiva(String colaboradorId) {
    try {
      return _pausas
          .firstWhere((p) => p.colaboradorId == colaboradorId && p.ativo);
    } catch (_) {
      return null;
    }
  }

  /// Carrega pausas de hoje do Supabase (ativas + histórico do dia).
  Future<void> load() async {
    try {
      final hoje = DateTime.now();
      final inicioDia =
          DateTime(hoje.year, hoje.month, hoje.day).toIso8601String();

      final rows = await SupabaseClientManager.client
          .from(_table)
          .select()
          .eq('fiscal_id', _fiscalId)
          .gte('iniciado_em', inicioDia)
          .order('iniciado_em', ascending: false);

      _pausas
        ..clear()
        ..addAll((rows as List)
            .map((r) => PausaCafe.fromMap(r as Map<String, dynamic>)));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[CafeProvider] Erro ao carregar: $e');
    }
  }

  // Timer de atualização (1s)
  void _verificarAlertasEAtualizar() {
    bool hasChanges = false;

    for (final pausa in _pausas.where((p) => p.ativo)) {
      // Disparar notificação quando o tempo de pausa expirar (duração atingida)
      if (!pausa.alertaDisparado && pausa.expirou) {
        pausa.alertaDisparado = true;
        hasChanges = true;

        // Notificação local
        final notifId = pausa.colaboradorId.hashCode.abs() % 100000;
        NotificationService.instance.showImmediateAlert(
          id: notifId,
          title: 'Pausa encerrada ☕',
          body: '${pausa.colaboradorNome} — ${pausa.duracaoMinutos} min de intervalo concluídos.',
        );
      }
    }

    if (_pausas.any((p) => p.ativo) || hasChanges) {
      notifyListeners();
    }
  }

  /// Inicia pausa para um colaborador
  void iniciarPausa({
    required String colaboradorId,
    required String colaboradorNome,
    int duracaoMinutos = 15,
  }) {
    if (colaboradorEmPausa(colaboradorId)) return;

    final pausa = PausaCafe(
      id: const Uuid().v4(),
      colaboradorId: colaboradorId,
      colaboradorNome: colaboradorNome,
      iniciadoEm: DateTime.now(),
      duracaoMinutos: duracaoMinutos,
    );
    _pausas.add(pausa);
    notifyListeners();

    SupabaseClientManager.client
        .from(_table)
        .insert(pausa.toMap(_fiscalId))
        .then((_) {})
        .catchError((e) {
      if (kDebugMode) debugPrint('[CafeProvider] Erro ao iniciar: $e');
    });
  }

  /// Finaliza pausa
  void finalizarPausa(String colaboradorId) {
    final pausa = getPausaAtiva(colaboradorId);
    if (pausa == null) return;

    pausa.finalizadoEm = DateTime.now();
    notifyListeners();

    SupabaseClientManager.client
        .from(_table)
        .update({'finalizado_em': pausa.finalizadoEm!.toIso8601String()})
        .eq('id', pausa.id)
        .then((_) {})
        .catchError((e) {
      if (kDebugMode) debugPrint('[CafeProvider] Erro ao finalizar: $e');
    });
  }

  /// Remove entrada do histórico
  void removerRegistro(String pausaId) {
    _pausas.removeWhere((p) => p.id == pausaId);
    notifyListeners();

    SupabaseClientManager.client
        .from(_table)
        .delete()
        .eq('id', pausaId)
        .then((_) {})
        .catchError((e) {
      if (kDebugMode) debugPrint('[CafeProvider] Erro ao remover: $e');
    });
  }

  /// Limpa todo o histórico finalizado
  void limparHistorico() {
    final ids =
        _pausas.where((p) => !p.ativo).map((p) => p.id).toList();
    _pausas.removeWhere((p) => !p.ativo);
    notifyListeners();

    if (ids.isNotEmpty) {
      SupabaseClientManager.client
          .from(_table)
          .delete()
          .inFilter('id', ids)
          .then((_) {})
          .catchError((e) {
        if (kDebugMode) debugPrint('[CafeProvider] Erro ao limpar: $e');
      });
    }
  }
}
