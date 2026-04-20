import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/remote/supabase_client.dart';

const _checklistModoPrefix = '[[modo_execucao:';
const _checklistModoSuffix = ']]';

class _ChecklistDescricaoMetadata {
  final String descricao;
  final ModoExecucaoChecklist modoExecucao;

  const _ChecklistDescricaoMetadata({
    required this.descricao,
    required this.modoExecucao,
  });
}

_ChecklistDescricaoMetadata _parseDescricaoChecklist(String? raw) {
  final texto = raw ?? '';
  final match = RegExp(
    r'^\[\[modo_execucao:([a-z_]+)\]\]\s*',
    dotAll: true,
  ).firstMatch(texto);

  if (match == null) {
    return const _ChecklistDescricaoMetadata(
      descricao: '',
      modoExecucao: ModoExecucaoChecklist.continuo,
    ).copyWithDescricao(texto);
  }

  return _ChecklistDescricaoMetadata(
    descricao: texto.substring(match.end).trimLeft(),
    modoExecucao: ModoExecucaoChecklistX.fromValue(match.group(1)),
  );
}

String _serializarDescricaoChecklist(
  String descricao,
  ModoExecucaoChecklist modoExecucao,
) {
  final limpa = _parseDescricaoChecklist(descricao).descricao.trim();
  final cabecalho =
      '$_checklistModoPrefix${modoExecucao.toValue}$_checklistModoSuffix';
  return limpa.isEmpty ? cabecalho : '$cabecalho\n$limpa';
}

extension on _ChecklistDescricaoMetadata {
  _ChecklistDescricaoMetadata copyWithDescricao(String value) {
    return _ChecklistDescricaoMetadata(
      descricao: value,
      modoExecucao: modoExecucao,
    );
  }
}

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

enum ModoExecucaoChecklist {
  continuo,
  usoUnico,
}

extension ModoExecucaoChecklistX on ModoExecucaoChecklist {
  String get label {
    switch (this) {
      case ModoExecucaoChecklist.continuo:
        return 'Uso contínuo';
      case ModoExecucaoChecklist.usoUnico:
        return 'Uso único';
    }
  }

  String get descricaoCurta {
    switch (this) {
      case ModoExecucaoChecklist.continuo:
        return 'Pode ser respondido novamente sempre que precisar.';
      case ModoExecucaoChecklist.usoUnico:
        return 'Depois da primeira conclusão, sai da lista de resposta.';
    }
  }

  String get toValue {
    switch (this) {
      case ModoExecucaoChecklist.continuo:
        return 'continuo';
      case ModoExecucaoChecklist.usoUnico:
        return 'uso_unico';
    }
  }

  static ModoExecucaoChecklist fromValue(String? value) {
    switch (value) {
      case 'uso_unico':
        return ModoExecucaoChecklist.usoUnico;
      default:
        return ModoExecucaoChecklist.continuo;
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
  final ModoExecucaoChecklist modoExecucao;

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
    this.modoExecucao = ModoExecucaoChecklist.continuo,
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
    ModoExecucaoChecklist? modoExecucao,
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
        modoExecucao: modoExecucao ?? this.modoExecucao,
        horarioNotificacao: clearHorario
            ? null
            : (horarioNotificacao ?? this.horarioNotificacao),
      );

  Map<String, dynamic> toMap(String fiscalId) => {
        'id': id,
        'fiscal_id': fiscalId,
        'titulo': titulo,
        'descricao': _serializarDescricaoChecklist(descricao, modoExecucao),
        'icone_key': iconeKey,
        'cor_hex': corHex,
        'itens': itens,
        'is_default': isDefault,
        'created_at': createdAt.toIso8601String(),
        'periodizacao': periodizacao.toValue,
        'horario_notificacao': horarioNotificacao,
      };

  static ChecklistTemplate fromMap(Map<String, dynamic> m) {
    final metadata = _parseDescricaoChecklist(m['descricao'] as String? ?? '');
    return ChecklistTemplate(
      id: m['id'] as String,
      titulo: m['titulo'] as String,
      descricao: metadata.descricao,
      iconeKey: m['icone_key'] as String? ?? 'checklist',
      corHex: m['cor_hex'] as String? ?? '4CAF50',
      itens: List<String>.from(m['itens'] as List? ?? []),
      isDefault: m['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(m['created_at'] as String),
      periodizacao:
          PeriodizacaoChecklistX.fromValue(m['periodizacao'] as String?),
      modoExecucao: metadata.modoExecucao,
      horarioNotificacao: m['horario_notificacao'] as String?,
    );
  }
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

  /// Cache de títulos: preserva títulos mesmo após templates deletados.
  final Map<String, String> _titulosCache = {};

  /// IDs de templates deletados localmente mas ainda não removidos do Supabase.
  final Set<String> _deletedTemplateIds = {};

  String get _fiscalId => SupabaseClientManager.currentUserId!;

  // Chaves SharedPreferences com escopo por fiscal (multi-conta seguro)
  String get _keyTemplatesCache => 'ck_templates_$_fiscalId';
  String get _keyExecucoesCache => 'ck_execucoes_$_fiscalId';
  String get _keyTitulosCache => 'ck_titulos_$_fiscalId';
  String get _keyDeletedIds => 'ck_deleted_$_fiscalId';

  // ── Getters ────────────────────────────────────────────────────────────────

  List<ChecklistExecucao> get todas => _execucoes;
  List<ChecklistTemplate> get templates => _templates;

  ChecklistTemplate? templateById(String templateId) =>
      _templates.where((t) => t.id == templateId).firstOrNull;

  /// Título de um template — busca em memória, depois no cache (cobre deletados).
  String tituloParaTemplate(String templateId) =>
      templateById(templateId)?.titulo ??
      _titulosCache[templateId] ??
      (templateId == 'abertura'
          ? 'Abertura da Loja'
          : templateId == 'fechamento'
              ? 'Fechamento da Loja'
              : 'Checklist');

  /// Última execução do template no dia de hoje.
  ChecklistExecucao? execucaoHoje(String templateId) {
    final hoje = DateTime.now();
    try {
      return _execucoes.lastWhere((e) =>
          e.tipo == templateId &&
          e.data.year == hoje.year &&
          e.data.month == hoje.month &&
          e.data.day == hoje.day);
    } catch (_) {}
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

  ChecklistExecucao? execucaoAberta(String templateId) {
    try {
      return _execucoes.firstWhere(
        (e) => e.tipo == templateId && !e.concluido,
      );
    } catch (_) {
      return null;
    }
  }

  ChecklistExecucao? ultimaExecucao(String templateId) {
    try {
      return _execucoes.firstWhere((e) => e.tipo == templateId);
    } catch (_) {
      return null;
    }
  }

  ChecklistExecucao? ultimaExecucaoConcluida(String templateId) {
    try {
      return _execucoes.firstWhere(
        (e) => e.tipo == templateId && e.concluido,
      );
    } catch (_) {
      return null;
    }
  }

  bool jaFoiConcluidoAlgumaVez(String templateId) =>
      ultimaExecucaoConcluida(templateId) != null;

  bool estaDisponivelNoTurno(String templateId) {
    final template = templateById(templateId);
    if (template == null) return true;
    if (template.modoExecucao == ModoExecucaoChecklist.continuo) return true;
    return !jaFoiConcluidoAlgumaVez(templateId) ||
        execucaoAberta(templateId) != null;
  }

  bool podeIniciarNovaExecucao(String templateId) {
    final template = templateById(templateId);
    if (template == null) return true;
    if (template.modoExecucao == ModoExecucaoChecklist.continuo) return true;
    return !jaFoiConcluidoAlgumaVez(templateId);
  }

  bool foiConcluidoHoje(String templateId) =>
      execucaoHoje(templateId)?.concluido == true;

  int get totalConcluidosHoje =>
      _templates.where((t) => foiConcluidoHoje(t.id)).length;

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

  bool deveNotificarAgora(String templateId) =>
      estaDisponivelNoTurno(templateId) &&
      !foiConcluidoHoje(templateId) &&
      estaNoJanela(templateId);

  List<ChecklistTemplate> get templatesPendentesAgora =>
      _templates.where((t) => deveNotificarAgora(t.id)).toList();

  // ── Load (cache-first) ─────────────────────────────────────────────────────

  Future<void> load() async {
    // 1. Cache local (rápido — UI responde imediatamente)
    await _loadFromLocalCache();
    notifyListeners();
    // 2. Sincroniza com Supabase (atualiza UI se houver novidade)
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

      if (rows.isNotEmpty) {
        _templates.clear();
        _templates.addAll(rows.map(ChecklistTemplate.fromMap));

        // Aplica deleções pendentes (templates excluídos offline)
        if (_deletedTemplateIds.isNotEmpty) {
          _templates.removeWhere((t) => _deletedTemplateIds.contains(t.id));
          for (final id in _deletedTemplateIds.toList()) {
            try {
              await SupabaseClientManager.client
                  .from(_tableT)
                  .delete()
                  .eq('id', id);
              _deletedTemplateIds.remove(id);
            } catch (_) {}
          }
          await _saveDeletedIds();
        }

        _refreshTitulosCache();
        await _saveTemplatesToCache();
        await _saveTitulosCache();
        notifyListeners();
      } else if (_templates.isEmpty) {
        // Nenhum dado local nem remoto → semear defaults
        await _seedTemplates();
      } else {
        // Cache local presente mas Supabase vazio → tentar re-upload
        for (final t in _templates) {
          try {
            await _upsertTemplate(t);
          } catch (_) {}
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ChecklistProvider] Erro ao carregar templates: $e');
      }
      if (_templates.isEmpty) {
        _templates.addAll(_buildDefaults());
        notifyListeners();
      }
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
      await _saveExecucoesToCache();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ChecklistProvider] Erro ao carregar execuções: $e');
      }
      // Mantém o que veio do cache local
      if (_execucoes.isEmpty) notifyListeners();
    }
  }

  // ── CRUD Templates ─────────────────────────────────────────────────────────

  Future<void> adicionarTemplate(ChecklistTemplate t) async {
    _templates.add(t);
    _titulosCache[t.id] = t.titulo;
    notifyListeners();
    // Salva localmente antes de tentar o Supabase
    await _saveTemplatesToCache();
    await _saveTitulosCache();
    try {
      await _upsertTemplate(t);
    } catch (_) {
      // Salvo localmente — não reverte. Re-lança para UI mostrar aviso.
      rethrow;
    }
  }

  Future<void> atualizarTemplate(ChecklistTemplate t) async {
    final i = _templates.indexWhere((x) => x.id == t.id);
    if (i != -1) {
      _templates[i] = t;
      _titulosCache[t.id] = t.titulo;
      notifyListeners();
      await _saveTemplatesToCache();
      await _saveTitulosCache();
      try {
        await _upsertTemplate(t);
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<void> deletarTemplate(String id) async {
    _templates.removeWhere((t) => t.id == id);
    _deletedTemplateIds.add(id);
    notifyListeners();
    await _saveTemplatesToCache();
    await _saveDeletedIds();
    try {
      await SupabaseClientManager.client.from(_tableT).delete().eq('id', id);
      _deletedTemplateIds.remove(id);
      await _saveDeletedIds();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ChecklistProvider] Erro ao deletar template no Supabase: $e');
      }
      rethrow;
    }
  }

  Future<void> _upsertTemplate(ChecklistTemplate t) async {
    try {
      await SupabaseClientManager.client
          .from(_tableT)
          .upsert(t.toMap(_fiscalId));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ChecklistProvider] Erro ao sync template: $e');
      }
      rethrow;
    }
  }

  // ── Execuções ──────────────────────────────────────────────────────────────

  Future<ChecklistExecucao> iniciar(String templateId) async {
    ChecklistTemplate? template;
    try {
      template = _templates.firstWhere((t) => t.id == templateId);
    } catch (_) {}
    final execucaoPendente = execucaoAberta(templateId);
    if (execucaoPendente != null) return execucaoPendente;
    if (template != null &&
        template.modoExecucao == ModoExecucaoChecklist.usoUnico &&
        jaFoiConcluidoAlgumaVez(templateId)) {
      throw StateError('Checklist de uso único já foi concluído.');
    }
    final exec = ChecklistExecucao(
      id: const Uuid().v4(),
      tipo: templateId,
      itens: template != null ? List<String>.from(template.itens) : [],
      data: DateTime.now(),
    );
    _execucoes.insert(0, exec);
    notifyListeners();
    await _saveExecucoesToCache();
    try {
      await _upsert(exec);
    } catch (_) {
      _execucoes.removeWhere((e) => e.id == exec.id);
      await _saveExecucoesToCache();
      notifyListeners();
      rethrow;
    }
    return exec;
  }

  Future<void> toggleItem(String execucaoId, int index) async {
    final exec = _execucoes.firstWhere((e) => e.id == execucaoId);
    final marcadoAnterior = exec.itensMarcados[index] ?? false;
    final concluidoAnterior = exec.concluido;
    final concluidoEmAnterior = exec.concluidoEm;
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
    await _saveExecucoesToCache();
    try {
      await _upsert(exec);
    } catch (_) {
      exec.itensMarcados[index] = marcadoAnterior;
      exec.concluido = concluidoAnterior;
      exec.concluidoEm = concluidoEmAnterior;
      await _saveExecucoesToCache();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> concluir(String execucaoId) async {
    final exec = _execucoes.firstWhere((e) => e.id == execucaoId);
    if (!exec.concluido) {
      final concluidoAnterior = exec.concluido;
      final concluidoEmAnterior = exec.concluidoEm;
      exec.concluido = true;
      exec.concluidoEm = DateTime.now();
      notifyListeners();
      await _saveExecucoesToCache();
      try {
        await _upsert(exec);
      } catch (_) {
        exec.concluido = concluidoAnterior;
        exec.concluidoEm = concluidoEmAnterior;
        await _saveExecucoesToCache();
        notifyListeners();
        rethrow;
      }
    }
  }

  /// Remove uma execução do histórico (local + Supabase).
  Future<void> deletarExecucao(String execucaoId) async {
    _execucoes.removeWhere((e) => e.id == execucaoId);
    notifyListeners();
    await _saveExecucoesToCache();
    try {
      await SupabaseClientManager.client
          .from(_table)
          .delete()
          .eq('id', execucaoId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ChecklistProvider] Erro ao deletar execução no Supabase: $e');
      }
      // Mantém deletado localmente mesmo se Supabase falhar
    }
  }

  // ── Internos ───────────────────────────────────────────────────────────────

  Future<void> _upsert(ChecklistExecucao exec) async {
    final itensJson = {
      for (final e in exec.itensMarcados.entries) e.key.toString(): e.value,
    };
    try {
      await SupabaseClientManager.client.from(_table).upsert({
        'id': exec.id,
        'fiscal_id': _fiscalId,
        'tipo': exec.tipo,
        'data': exec.data.toIso8601String(),
        'itens_marcados': itensJson,
        'itens_snapshot': exec.itensSnapshot,
        'concluido': exec.concluido,
        'concluido_em': exec.concluidoEm?.toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[ChecklistProvider] Erro ao sync: $e');
      rethrow;
    }
  }

  ChecklistExecucao _fromMap(Map<String, dynamic> m) {
    final itensRaw = (m['itens_marcados'] as Map<String, dynamic>?) ?? {};
    final itensMarcados = {
      for (final e in itensRaw.entries) int.parse(e.key): e.value as bool,
    };
    final snapshot = List<String>.from(m['itens_snapshot'] as List? ?? []);
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

  Map<String, dynamic> _execToMap(ChecklistExecucao exec) => {
        'id': exec.id,
        'fiscal_id': _fiscalId,
        'tipo': exec.tipo,
        'data': exec.data.toIso8601String(),
        'itens_marcados': {
          for (final e in exec.itensMarcados.entries)
            e.key.toString(): e.value,
        },
        'itens_snapshot': exec.itensSnapshot,
        'concluido': exec.concluido,
        'concluido_em': exec.concluidoEm?.toIso8601String(),
      };

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
    _refreshTitulosCache();
    await _saveTemplatesToCache();
    await _saveTitulosCache();
  }

  List<ChecklistTemplate> _buildDefaults() {
    final now = DateTime.now();
    const ns = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';
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
        modoExecucao: ModoExecucaoChecklist.continuo,
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
        modoExecucao: ModoExecucaoChecklist.continuo,
      ),
    ];
  }

  // ── Cache local (SharedPreferences) ───────────────────────────────────────

  void _refreshTitulosCache() {
    for (final t in _templates) {
      _titulosCache[t.id] = t.titulo;
    }
  }

  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // IDs deletados localmente
      final deletedJson = prefs.getString(_keyDeletedIds);
      if (deletedJson != null) {
        final list = jsonDecode(deletedJson) as List;
        _deletedTemplateIds.addAll(list.cast<String>());
      }

      // Cache de títulos
      final titulosJson = prefs.getString(_keyTitulosCache);
      if (titulosJson != null) {
        final map = jsonDecode(titulosJson) as Map<String, dynamic>;
        _titulosCache.addAll(map.cast<String, String>());
      }

      // Templates
      final templatesJson = prefs.getString(_keyTemplatesCache);
      if (templatesJson != null) {
        final list = jsonDecode(templatesJson) as List;
        final loaded = list
            .map((m) => ChecklistTemplate.fromMap(m as Map<String, dynamic>))
            .where((t) => !_deletedTemplateIds.contains(t.id))
            .toList();
        _templates.addAll(loaded);
      }

      // Execuções
      final execJson = prefs.getString(_keyExecucoesCache);
      if (execJson != null) {
        final list = jsonDecode(execJson) as List;
        _execucoes.addAll(
          list.map((m) => _fromMap(m as Map<String, dynamic>)),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ChecklistProvider] Erro ao carregar cache local: $e');
      }
    }
  }

  Future<void> _saveTemplatesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _templates.map((t) => t.toMap(_fiscalId)).toList();
      await prefs.setString(_keyTemplatesCache, jsonEncode(list));
    } catch (_) {}
  }

  Future<void> _saveExecucoesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _execucoes.take(50).map(_execToMap).toList();
      await prefs.setString(_keyExecucoesCache, jsonEncode(list));
    } catch (_) {}
  }

  Future<void> _saveTitulosCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyTitulosCache, jsonEncode(_titulosCache));
    } catch (_) {}
  }

  Future<void> _saveDeletedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _keyDeletedIds, jsonEncode(_deletedTemplateIds.toList()));
    } catch (_) {}
  }
}
