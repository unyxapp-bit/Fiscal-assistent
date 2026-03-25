import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/remote/supabase_client.dart';
import '../../data/services/notification_service.dart';
import 'alocacao_provider.dart';

enum TipoPausa {
  cafe,
  intervalo;

  bool get isCafe => this == TipoPausa.cafe;
  bool get isIntervalo => this == TipoPausa.intervalo;
}

/// Registro de pausa de um colaborador
class PausaCafe {
  final String id;
  final String colaboradorId;
  final String colaboradorNome;
  final String? caixaId; // caixa de onde saiu para a pausa
  final DateTime iniciadoEm;
  final int duracaoMinutos; // padrão 15
  DateTime? finalizadoEm;
  bool alertaDisparado;

  PausaCafe({
    required this.id,
    required this.colaboradorId,
    required this.colaboradorNome,
    this.caixaId,
    required this.iniciadoEm,
    this.duracaoMinutos = 15,
    this.finalizadoEm,
    this.alertaDisparado = false,
  });

  factory PausaCafe.fromMap(Map<String, dynamic> m) => PausaCafe(
        id: m['id'] as String,
        colaboradorId: m['colaborador_id'] as String,
        colaboradorNome: m['colaborador_nome'] as String,
        caixaId: m['caixa_id'] as String?,
        // .toLocal() — Supabase retorna timestamptz com +00:00 (UTC);
        // convertemos para hora local antes de usar em cálculos e exibição.
        iniciadoEm: DateTime.parse(m['iniciado_em'] as String).toLocal(),
        duracaoMinutos: m['duracao_minutos'] as int? ?? 15,
        finalizadoEm: m['finalizado_em'] != null
            ? DateTime.parse(m['finalizado_em'] as String).toLocal()
            : null,
      );

  Map<String, dynamic> toMap(String fiscalId) => {
        'id': id,
        'fiscal_id': fiscalId,
        'colaborador_id': colaboradorId,
        'colaborador_nome': colaboradorNome,
        'caixa_id': caixaId,
        // .toUtc() — garante que o Supabase armazene o instante correto em UTC
        // em vez de interpretar a hora local como UTC.
        'iniciado_em': iniciadoEm.toUtc().toIso8601String(),
        'duracao_minutos': duracaoMinutos,
        'finalizado_em': finalizadoEm?.toUtc().toIso8601String(),
      };

  bool get ativo => finalizadoEm == null;
  bool get isCafe => duracaoMinutos <= 15;
  bool get isIntervalo => !isCafe;

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
  List<PausaCafe> get pausasAtivas => _pausas.where((p) => p.ativo).toList();
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

  /// Retorna true quando o colaborador já realizou intervalo (>15 min) hoje.
  /// Considera pausas ativas e finalizadas.
  bool colaboradorJaFezIntervaloHoje(String colaboradorId) =>
      _pausas.any((p) => p.colaboradorId == colaboradorId && p.isIntervalo);

  /// Retorna a pausa ativa associada a um caixa específico
  PausaCafe? getPausaAtivaPorCaixa(String caixaId) {
    try {
      return _pausas.firstWhere((p) => p.ativo && p.caixaId == caixaId);
    } catch (_) {
      return null;
    }
  }

  /// Carrega pausas de hoje do Supabase (ativas + histórico do dia).
  Future<void> load() async {
    try {
      final hoje = DateTime.now();
      // .toUtc() — converte meia-noite local para UTC, garantindo que o filtro
      // do Supabase (timestamptz) compare na mesma base temporal.
      final inicioDia =
          DateTime(hoje.year, hoje.month, hoje.day).toUtc().toIso8601String();

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

      // Bug 2: evitar re-disparar alerta para pausas que já expiraram
      // enquanto o app estava fechado
      for (final pausa in _pausas.where((p) => p.ativo && p.expirou)) {
        pausa.alertaDisparado = true;
      }

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
          body:
              '${pausa.colaboradorNome} — ${pausa.duracaoMinutos} min de intervalo concluídos.',
        );
      }
    }

    if (_pausas.any((p) => p.ativo) || hasChanges) {
      notifyListeners();
    }
  }

  /// Inicia pausa para um colaborador.
  /// [iniciadoEm] permite informar hora de saída retroativa (ponto já passado).
  void iniciarPausa({
    required String colaboradorId,
    required String colaboradorNome,
    int duracaoMinutos = 10,
    String? caixaId,
    DateTime? iniciadoEm,
  }) {
    if (colaboradorEmPausa(colaboradorId)) return;

    final pausa = PausaCafe(
      id: const Uuid().v4(),
      colaboradorId: colaboradorId,
      colaboradorNome: colaboradorNome,
      caixaId: caixaId,
      iniciadoEm: iniciadoEm ?? DateTime.now(),
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
        .update(
            {'finalizado_em': pausa.finalizadoEm!.toUtc().toIso8601String()})
        .eq('id', pausa.id)
        .then((_) {})
        .catchError((e) {
          if (kDebugMode) debugPrint('[CafeProvider] Erro ao finalizar: $e');
        });
  }

  /// Finaliza a pausa e aplica regra unificada de retorno:
  /// - Café (10 min): retorna para o mesmo caixa de origem, quando disponível.
  /// - Intervalo (60/120): retorna para novo caixa (padrão), com exceção
  ///   opcional para mesmo caixa mediante justificativa.
  Future<String?> finalizarPausaComRegra({
    required PausaCafe pausa,
    required AlocacaoProvider alocacaoProvider,
    required String fiscalId,
    String? caixaDestinoIntervaloId,
    bool permitirMesmoCaixaNoIntervalo = false,
    String? justificativaMesmoCaixa,
  }) async {
    finalizarPausa(pausa.colaboradorId);

    if (pausa.isCafe) {
      if (pausa.caixaId == null || pausa.caixaId!.isEmpty) return null;
      if (fiscalId.isEmpty) return 'Usuário não autenticado para realocação.';
      return alocacaoProvider.retornarDeCafe(
        colaboradorId: pausa.colaboradorId,
        caixaId: pausa.caixaId!,
        fiscalId: fiscalId,
      );
    }

    alocacaoProvider.marcarAguardandoRealocacaoPosIntervalo(
      pausa.colaboradorId,
    );

    if (caixaDestinoIntervaloId == null || caixaDestinoIntervaloId.isEmpty) {
      return null;
    }

    if (fiscalId.isEmpty) return 'Usuário não autenticado para realocação.';
    return alocacaoProvider.realocarPosIntervalo(
      colaboradorId: pausa.colaboradorId,
      caixaDestinoId: caixaDestinoIntervaloId,
      fiscalId: fiscalId,
      caixaOrigemId: pausa.caixaId,
      permitirMesmoCaixa: permitirMesmoCaixaNoIntervalo,
      justificativaMesmoCaixa: justificativaMesmoCaixa,
    );
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
    final ids = _pausas.where((p) => !p.ativo).map((p) => p.id).toList();
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
