import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/remote/supabase_client.dart';

// ── Legacy items (fallback para execuções antigas sem snapshot) ───────────────

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

// ── Constantes de UI ──────────────────────────────────────────────────────────

const kChecklistIcones = <(String, IconData, String)>[
  ('checklist', Icons.checklist, 'Checklist'),
  ('lock_open', Icons.lock_open, 'Abertura'),
  ('lock', Icons.lock, 'Fechamento'),
  ('security', Icons.security, 'Segurança'),
  ('cleaning_services', Icons.cleaning_services, 'Limpeza'),
  ('inventory', Icons.inventory_2, 'Estoque'),
  ('payments', Icons.payments, 'Caixa'),
  ('people', Icons.people, 'Equipe'),
  ('store', Icons.store, 'Loja'),
  ('task_alt', Icons.task_alt, 'Tarefas'),
];

const kChecklistCores = <Color>[
  Color(0xFF4CAF50),
  Color(0xFFF44336),
  Color(0xFF2196F3),
  Color(0xFFFF9800),
  Color(0xFF9C27B0),
  Color(0xFF00BCD4),
  Color(0xFF607D8B),
];

IconData iconeChecklistParaKey(String key) =>
    kChecklistIcones.where((e) => e.$1 == key).firstOrNull?.$2 ??
    Icons.checklist;

// ── PeriodizacaoChecklist ──────────────────────────────────────────────────────

enum PeriodizacaoChecklist {
  qualquerHorario,
  abertura, // 06:00 – 12:00
  fechamento, // 17:00 – 23:59
  horarioEspecifico, // HH:mm ± 30 min
}

extension PeriodizacaoChecklistX on PeriodizacaoChecklist {
  String get label {
    switch (this) {
      case PeriodizacaoChecklist.qualquerHorario:
        return 'Sempre';
      case PeriodizacaoChecklist.abertura:
        return 'Abertura (06h–12h)';
      case PeriodizacaoChecklist.fechamento:
        return 'Fechamento (17h–00h)';
      case PeriodizacaoChecklist.horarioEspecifico:
        return 'Horário específico';
    }
  }

  String get toValue {
    switch (this) {
      case PeriodizacaoChecklist.qualquerHorario:
        return 'qualquer_horario';
      case PeriodizacaoChecklist.abertura:
        return 'abertura';
      case PeriodizacaoChecklist.fechamento:
        return 'fechamento';
      case PeriodizacaoChecklist.horarioEspecifico:
        return 'horario_especifico';
    }
  }

  static PeriodizacaoChecklist fromValue(String? v) {
    switch (v) {
      case 'abertura':
        return PeriodizacaoChecklist.abertura;
      case 'fechamento':
        return PeriodizacaoChecklist.fechamento;
      case 'horario_especifico':
        return PeriodizacaoChecklist.horarioEspecifico;
      default:
        return PeriodizacaoChecklist.qualquerHorario;
    }
  }
}

// ── ChecklistTemplate ─────────────────────────────────────────────────────────

class ChecklistTemplate {
  final String id;
  final String titulo;
  final String descricao;
  final String iconeKey;
  final String corHex;
  final List<String> itens;
  final bool isDefault;
  final DateTime createdAt;
  final PeriodizacaoChecklist periodizacao;

  /// Horário no formato "HH:mm" — usado apenas quando [periodizacao] ==
  /// [PeriodizacaoChecklist.horarioEspecifico].
  final String? horarioNotificacao;

  ChecklistTemplate({
    required this.id,
    required this.titulo,
    this.descricao = '',
    required this.iconeKey,
    required this.corHex,
    required this.itens,
    this.isDefault = false,
    required this.createdAt,
    this.periodizacao = PeriodizacaoChecklist.qualquerHorario,
    this.horarioNotificacao,
  });

  IconData get icone => iconeChecklistParaKey(iconeKey);
  Color get cor => Color(int.parse('FF$corHex', radix: 16));

  ChecklistTemplate copyWith({
    String? titulo,
    String? descricao,
    String? iconeKey,
    String? corHex,
    List<String>? itens,
    PeriodizacaoChecklist? periodizacao,
    String? horarioNotificacao,
    bool clearHorario = false,
  }) =>
      ChecklistTemplate(
        id: id,
        titulo: titulo ?? this.titulo,
        descricao: descricao ?? this.descricao,
        iconeKey: iconeKey ?? this.iconeKey,
        corHex: corHex ?? this.corHex,
        itens: itens ?? List<String>.from(this.itens),
        isDefault: isDefault,
        createdAt: createdAt,
        periodizacao: periodizacao ?? this.periodizacao,
        horarioNotificacao:
            clearHorario ? null : (horarioNotificacao ?? this.horarioNotificacao),
      );

  Map<String, dynamic> toMap(String fiscalId) => {
        'id': id,
        'fiscal_id': fiscalId,
        'titulo': titulo,
        'descricao': descricao,
        'icone_key': iconeKey,
        'cor_hex': corHex,
        'itens': itens,
        'is_default': isDefault,
        'created_at': createdAt.toIso8601String(),
        'periodizacao': periodizacao.toValue,
        'horario_notificacao': horarioNotificacao,
      };

  static ChecklistTemplate fromMap(Map<String, dynamic> m) =>
      ChecklistTemplate(
        id: m['id'] as String,
        titulo: m['titulo'] as String,
        descricao: m['descricao'] as String? ?? '',
        iconeKey: m['icone_key'] as String? ?? 'checklist',
        corHex: m['cor_hex'] as String? ?? '4CAF50',
        itens: List<String>.from(m['itens'] as List? ?? []),
        isDefault: m['is_default'] as bool? ?? false,
        createdAt: DateTime.parse(m['created_at'] as String),
        periodizacao:
            PeriodizacaoChecklistX.fromValue(m['periodizacao'] as String?),
        horarioNotificacao: m['horario_notificacao'] as String?,
      );
}

// ── ChecklistExecucao ─────────────────────────────────────────────────────────

class ChecklistExecucao {
  final String id;

  /// Para novas execuções: ID do template.
  /// Para execuções legadas: 'abertura' | 'fechamento'.
  final String tipo;

  /// Snapshot dos itens no momento da execução.
  /// Legadas (sem snapshot): lista vazia → fallback por `tipo`.
  final List<String> _itensSnapshot;

  final DateTime data;
  final Map<int, bool> itensMarcados;
  bool concluido;
  DateTime? concluidoEm;

  ChecklistExecucao({
    required this.id,
    required this.tipo,
    List<String>? itens,
    required this.data,
    Map<int, bool>? itensMarcados,
    this.concluido = false,
    this.concluidoEm,
  })  : _itensSnapshot = itens ?? [],
        itensMarcados = itensMarcados ?? {};

  /// Itens resolvidos: snapshot ou fallback hard-coded (legado).
  List<String> get itens => _itensSnapshot.isNotEmpty
      ? _itensSnapshot
      : tipo == 'abertura'
          ? _itensAbertura
          : tipo == 'fechamento'
              ? _itensFechamento
              : [];

  List<String> get itensSnapshot => _itensSnapshot;

  int get totalItens => itens.length;
  int get marcados => itensMarcados.values.where((v) => v).length;
  double get progresso => totalItens > 0 ? marcados / totalItens : 0.0;
}

// ── ChecklistProvider ─────────────────────────────────────────────────────────

class ChecklistProvider with ChangeNotifier {
  static const _table = 'checklist_execucoes';
  static const _tableT = 'checklist_templates';

  final List<ChecklistExecucao> _execucoes = [];
  final List<ChecklistTemplate> _templates = [];

  String get _fiscalId => SupabaseClientManager.currentUserId!;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<ChecklistExecucao> get todas => _execucoes;
  List<ChecklistTemplate> get templates => _templates;

  /// Última execução do template no dia de hoje.
  ChecklistExecucao? execucaoHoje(String templateId) {
    final hoje = DateTime.now();
    // Busca por templateId direto
    try {
      return _execucoes.lastWhere((e) =>
          e.tipo == templateId &&
          e.data.year == hoje.year &&
          e.data.month == hoje.month &&
          e.data.day == hoje.day);
    } catch (_) {}
    // Fallback legado: default templates mapeados por título
    try {
      final template = _templates.firstWhere((t) => t.id == templateId);
      final legado = template.titulo.toLowerCase().contains('abertura')
          ? 'abertura'
          : template.titulo.toLowerCase().contains('fechamento')
              ? 'fechamento'
              : null;
      if (legado != null) {
        return _execucoes.lastWhere((e) =>
            e.tipo == legado &&
            e.data.year == hoje.year &&
            e.data.month == hoje.month &&
            e.data.day == hoje.day);
      }
    } catch (_) {}
    return null;
  }

  bool foiConcluidoHoje(String templateId) =>
      execucaoHoje(templateId)?.concluido == true;

  int get totalConcluidosHoje =>
      _templates.where((t) => foiConcluidoHoje(t.id)).length;

  /// Retorna true se a janela de notificação do template está ativa agora.
  /// Independe de o checklist já ter sido concluído.
  bool estaNoJanela(String templateId) {
    final t = _templates.where((t) => t.id == templateId).firstOrNull;
    if (t == null) return true;
    final agora = DateTime.now();
    final agoraMin = agora.hour * 60 + agora.minute;
    switch (t.periodizacao) {
      case PeriodizacaoChecklist.qualquerHorario:
        return true;
      case PeriodizacaoChecklist.abertura:
        return agoraMin >= 6 * 60 && agoraMin <= 12 * 60;
      case PeriodizacaoChecklist.fechamento:
        return agoraMin >= 17 * 60 && agoraMin <= 23 * 60 + 59;
      case PeriodizacaoChecklist.horarioEspecifico:
        final h = t.horarioNotificacao;
        if (h == null) return true;
        final parts = h.split(':');
        if (parts.length < 2) return true;
        final targetMin =
            (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
        return (agoraMin - targetMin).abs() <= 30;
    }
  }

  /// Retorna true se o template deve mostrar alerta agora:
  /// não concluído hoje E dentro da janela de notificação.
  bool deveNotificarAgora(String templateId) =>
      !foiConcluidoHoje(templateId) && estaNoJanela(templateId);

  /// Templates com checklist pendente cuja janela de notificação está ativa.
  List<ChecklistTemplate> get templatesPendentesAgora =>
      _templates.where((t) => deveNotificarAgora(t.id)).toList();

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> load() async {
    await _loadTemplates();
    await _loadExecucoes();
  }

  Future<void> _loadTemplates() async {
    try {
      final rows = await SupabaseClientManager.client
          .from(_tableT)
          .select()
          .eq('fiscal_id', _fiscalId)
          .order('created_at');
      _templates.clear();
      if (rows.isEmpty) {
        await _seedTemplates();
      } else {
        _templates.addAll(rows.map(ChecklistTemplate.fromMap));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ChecklistProvider] Erro ao carregar templates: $e');
      }
      if (_templates.isEmpty) _templates.addAll(_buildDefaults());
    }
  }

  Future<void> _loadExecucoes() async {
    try {
      final rows = await SupabaseClientManager.client
          .from(_table)
          .select()
          .eq('fiscal_id', _fiscalId)
          .order('data', ascending: false)
          .limit(100);
      _execucoes.clear();
      _execucoes.addAll(rows.map(_fromMap));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ChecklistProvider] Erro ao carregar execuções: $e');
      }
    }
  }

  // ── CRUD Templates ─────────────────────────────────────────────────────────

  void adicionarTemplate(ChecklistTemplate t) {
    _templates.add(t);
    notifyListeners();
    _upsertTemplate(t);
  }

  void atualizarTemplate(ChecklistTemplate t) {
    final i = _templates.indexWhere((x) => x.id == t.id);
    if (i != -1) {
      _templates[i] = t;
      notifyListeners();
      _upsertTemplate(t);
    }
  }

  void deletarTemplate(String id) {
    _templates.removeWhere((t) => t.id == id);
    notifyListeners();
    SupabaseClientManager.client
        .from(_tableT)
        .delete()
        .eq('id', id)
        .then((_) {})
        .catchError((e) {
      if (kDebugMode) {
        debugPrint('[ChecklistProvider] Erro ao deletar template: $e');
      }
    });
  }

  void _upsertTemplate(ChecklistTemplate t) {
    SupabaseClientManager.client
        .from(_tableT)
        .upsert(t.toMap(_fiscalId))
        .then((_) {})
        .catchError((e) {
      if (kDebugMode) {
        debugPrint('[ChecklistProvider] Erro ao sync template: $e');
      }
    });
  }

  // ── Execuções ──────────────────────────────────────────────────────────────

  /// Inicia nova execução a partir de um template.
  ChecklistExecucao iniciar(String templateId) {
    ChecklistTemplate? template;
    try {
      template = _templates.firstWhere((t) => t.id == templateId);
    } catch (_) {}
    final exec = ChecklistExecucao(
      id: const Uuid().v4(),
      tipo: templateId,
      itens: template != null ? List<String>.from(template.itens) : [],
      data: DateTime.now(),
    );
    _execucoes.insert(0, exec);
    notifyListeners();
    _upsert(exec);
    return exec;
  }

  void toggleItem(String execucaoId, int index) {
    final exec = _execucoes.firstWhere((e) => e.id == execucaoId);
    final atual = exec.itensMarcados[index] ?? false;
    exec.itensMarcados[index] = !atual;
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
    final itensJson = {
      for (final e in exec.itensMarcados.entries) e.key.toString(): e.value,
    };
    SupabaseClientManager.client.from(_table).upsert({
      'id': exec.id,
      'fiscal_id': _fiscalId,
      'tipo': exec.tipo,
      'data': exec.data.toIso8601String(),
      'itens_marcados': itensJson,
      'itens_snapshot': exec.itensSnapshot,
      'concluido': exec.concluido,
      'concluido_em': exec.concluidoEm?.toIso8601String(),
    }).then((_) {}).catchError((e) {
      if (kDebugMode) debugPrint('[ChecklistProvider] Erro ao sync: $e');
    });
  }

  ChecklistExecucao _fromMap(Map<String, dynamic> m) {
    final itensRaw = (m['itens_marcados'] as Map<String, dynamic>?) ?? {};
    final itensMarcados = {
      for (final e in itensRaw.entries) int.parse(e.key): e.value as bool,
    };
    final snapshot =
        List<String>.from(m['itens_snapshot'] as List? ?? []);
    return ChecklistExecucao(
      id: m['id'] as String,
      tipo: m['tipo'] as String,
      itens: snapshot,
      data: DateTime.parse(m['data'] as String),
      itensMarcados: itensMarcados,
      concluido: m['concluido'] as bool? ?? false,
      concluidoEm: m['concluido_em'] != null
          ? DateTime.parse(m['concluido_em'] as String)
          : null,
    );
  }

  Future<void> _seedTemplates() async {
    final defaults = _buildDefaults();
    try {
      await SupabaseClientManager.client
          .from(_tableT)
          .insert(defaults.map((t) => t.toMap(_fiscalId)).toList());
      _templates.addAll(defaults);
    } catch (e) {
      if (kDebugMode) debugPrint('[ChecklistProvider] Erro ao seed: $e');
      _templates.addAll(defaults);
    }
  }

  List<ChecklistTemplate> _buildDefaults() {
    final now = DateTime.now();
    const ns = '6ba7b810-9dad-11d1-80b4-00c04fd430c8'; // UUID namespace URL
    return [
      ChecklistTemplate(
        id: const Uuid().v5(ns, 'checklist:abertura'),
        titulo: 'Abertura da Loja',
        descricao: 'Verificações necessárias para abertura',
        iconeKey: 'lock_open',
        corHex: '4CAF50',
        itens: List<String>.from(_itensAbertura),
        isDefault: true,
        createdAt: now,
        periodizacao: PeriodizacaoChecklist.abertura,
      ),
      ChecklistTemplate(
        id: const Uuid().v5(ns, 'checklist:fechamento'),
        titulo: 'Fechamento da Loja',
        descricao: 'Procedimentos para fechar corretamente',
        iconeKey: 'lock',
        corHex: 'F44336',
        itens: List<String>.from(_itensFechamento),
        isDefault: true,
        createdAt: now,
        periodizacao: PeriodizacaoChecklist.fechamento,
      ),
    ];
  }
}
