import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/remote/supabase_client.dart';

// ── Itens pré-definidos por tipo ──────────────────────────────────────────────

const _itensAbertura = [
  'Conferir troco de cada caixa',
  'Verificar funcionamento das máquinas de cartão',
  'Checar impressoras de cupom fiscal',
  'Confirmar colaboradores presentes / escala do dia',
  'Verificar câmeras de segurança',
  'Ler registro de pendências do turno anterior',
  'Realizar ronda inicial pelo salão',
  'Liberar caixas para início de atendimento',
];

const _itensFechamento = [
  'Avisar colaboradores sobre encerramento próximo',
  'Fechar máquinas de cartão (fechamento de lote)',
  'Recolher troco de cada caixa',
  'Conferir valores de fechamento',
  'Imprimir relatório de caixa do dia',
  'Realizar ronda final pelo salão',
  'Verificar câmeras e segurança da loja',
  'Registrar passagem de turno / ocorrências do dia',
];

// ── Model ─────────────────────────────────────────────────────────────────────

class ChecklistExecucao {
  final String id;
  final String tipo; // 'abertura' | 'fechamento'
  final DateTime data;
  final Map<int, bool> itensMarcados; // índice → marcado
  bool concluido;
  DateTime? concluidoEm;

  ChecklistExecucao({
    required this.id,
    required this.tipo,
    required this.data,
    Map<int, bool>? itensMarcados,
    this.concluido = false,
    this.concluidoEm,
  }) : itensMarcados = itensMarcados ?? {};

  List<String> get itens =>
      tipo == 'abertura' ? _itensAbertura : _itensFechamento;

  int get totalItens => itens.length;
  int get marcados =>
      itensMarcados.values.where((v) => v).length;
  double get progresso => totalItens > 0 ? marcados / totalItens : 0.0;
}

// ── Provider ──────────────────────────────────────────────────────────────────

class ChecklistProvider with ChangeNotifier {
  static const _table = 'checklist_execucoes';

  final List<ChecklistExecucao> _execucoes = [];

  String get _fiscalId => SupabaseClientManager.currentUserId!;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<ChecklistExecucao> get todas => _execucoes;

  /// Última execução do tipo no dia de hoje
  ChecklistExecucao? execucaoHoje(String tipo) {
    final hoje = DateTime.now();
    try {
      return _execucoes.lastWhere((e) =>
          e.tipo == tipo &&
          e.data.year == hoje.year &&
          e.data.month == hoje.month &&
          e.data.day == hoje.day);
    } catch (_) {
      return null;
    }
  }

  bool foiConcluidoHoje(String tipo) =>
      execucaoHoje(tipo)?.concluido == true;

  // ── Ações ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    try {
      final rows = await SupabaseClientManager.client
          .from(_table)
          .select()
          .eq('fiscal_id', _fiscalId)
          .order('data', ascending: false)
          .limit(60); // últimas 60 execuções

      _execucoes.clear();
      _execucoes.addAll(rows.map(_fromMap));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ChecklistProvider] Erro ao carregar: $e');
      }
    }
  }

  /// Inicia nova execução do tipo (abertura ou fechamento)
  ChecklistExecucao iniciar(String tipo) {
    final exec = ChecklistExecucao(
      id: const Uuid().v4(),
      tipo: tipo,
      data: DateTime.now(),
    );
    _execucoes.insert(0, exec);
    notifyListeners();
    _upsert(exec);
    return exec;
  }

  /// Marca/desmarca um item
  void toggleItem(String execucaoId, int index) {
    final exec = _execucoes.firstWhere((e) => e.id == execucaoId);
    final atual = exec.itensMarcados[index] ?? false;
    exec.itensMarcados[index] = !atual;

    // Se todos marcados, marcar como concluído automaticamente
    if (exec.marcados == exec.totalItens && !exec.concluido) {
      exec.concluido = true;
      exec.concluidoEm = DateTime.now();
    } else if (exec.marcados < exec.totalItens && exec.concluido) {
      exec.concluido = false;
      exec.concluidoEm = null;
    }

    notifyListeners();
    _upsert(exec);
  }

  /// Marca como concluído manualmente
  void concluir(String execucaoId) {
    final exec = _execucoes.firstWhere((e) => e.id == execucaoId);
    if (!exec.concluido) {
      exec.concluido = true;
      exec.concluidoEm = DateTime.now();
      notifyListeners();
      _upsert(exec);
    }
  }

  // ── Internos ───────────────────────────────────────────────────────────────

  void _upsert(ChecklistExecucao exec) {
    // Serializar itensMarcados como Map<String, bool>
    final itensJson = {
      for (final e in exec.itensMarcados.entries)
        e.key.toString(): e.value,
    };

    SupabaseClientManager.client.from(_table).upsert({
      'id': exec.id,
      'fiscal_id': _fiscalId,
      'tipo': exec.tipo,
      'data': exec.data.toIso8601String(),
      'itens_marcados': itensJson,
      'concluido': exec.concluido,
      'concluido_em': exec.concluidoEm?.toIso8601String(),
    }).then((_) {}).catchError((e) {
      if (kDebugMode) {
        debugPrint('[ChecklistProvider] Erro ao sync: $e');
      }
    });
  }

  ChecklistExecucao _fromMap(Map<String, dynamic> m) {
    final itensRaw =
        (m['itens_marcados'] as Map<String, dynamic>?) ?? {};
    final itensMarcados = {
      for (final e in itensRaw.entries)
        int.parse(e.key): e.value as bool,
    };
    return ChecklistExecucao(
      id: m['id'] as String,
      tipo: m['tipo'] as String,
      data: DateTime.parse(m['data'] as String),
      itensMarcados: itensMarcados,
      concluido: m['concluido'] as bool? ?? false,
      concluidoEm: m['concluido_em'] != null
          ? DateTime.parse(m['concluido_em'] as String)
          : null,
    );
  }
}
