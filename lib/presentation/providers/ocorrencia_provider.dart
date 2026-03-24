import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/remote/supabase_client.dart';
import '../../core/constants/colors.dart';

// ── Sugestões de tipo (apenas para quick-select na tela de registro) ───────────

const kTiposSugestao = [
  'Briga/Conflito',
  'Furto/Perda',
  'Erro de Caixa',
  'Equipamento',
  'Reclamação',
  'Ausência',
  'Acidente',
  'Fraude',
  'Outro',
];

// ── Helper de ícone por tipo (keyword matching) ────────────────────────────────

IconData iconForTipo(String tipo) {
  final t = tipo.toLowerCase();
  if (t.contains('briga') || t.contains('conflito') || t.contains('briga')) {
    return Icons.warning_amber;
  }
  if (t.contains('furto') ||
      t.contains('perda') ||
      t.contains('roubo') ||
      t.contains('fraude')) {
    return Icons.security;
  }
  if (t.contains('caixa')) return Icons.point_of_sale;
  if (t.contains('equipamento') ||
      t.contains('tecnico') ||
      t.contains('maquina')) {
    return Icons.build;
  }
  if (t.contains('reclama')) return Icons.sentiment_dissatisfied;
  if (t.contains('aus') || t.contains('falta') || t.contains('person')) {
    return Icons.person_off;
  }
  if (t.contains('acid') || t.contains('lesao') || t.contains('queda')) {
    return Icons.local_hospital;
  }
  return Icons.more_horiz;
}

// ── Gravidade (mantida como enum, só para UX) ─────────────────────────────────

enum GravidadeOcorrencia {
  baixa,
  media,
  alta;

  String get nome {
    switch (this) {
      case GravidadeOcorrencia.baixa:
        return 'Baixa';
      case GravidadeOcorrencia.media:
        return 'Média';
      case GravidadeOcorrencia.alta:
        return 'Alta';
    }
  }

  Color get cor {
    switch (this) {
      case GravidadeOcorrencia.baixa:
        return AppColors.success;
      case GravidadeOcorrencia.media:
        return AppColors.statusAtencao;
      case GravidadeOcorrencia.alta:
        return AppColors.danger;
    }
  }

  static GravidadeOcorrencia fromString(String s) =>
      GravidadeOcorrencia.values.firstWhere(
        (g) => g.name == s,
        orElse: () => GravidadeOcorrencia.media,
      );
}

// ── Model ─────────────────────────────────────────────────────────────────────

class Ocorrencia {
  final String id;
  final String tipo; // texto livre
  final String? caixaId;
  final String? caixaNome;
  final String? colaboradorId;
  final String? colaboradorNome;
  final String descricao;
  final String? fotoUrl;
  final String? fotoNome;
  final String? arquivoUrl;
  final String? arquivoNome;
  final GravidadeOcorrencia gravidade;
  bool resolvida;
  final DateTime registradaEm;
  DateTime? resolvidaEm;

  Ocorrencia({
    required this.id,
    required this.tipo,
    this.caixaId,
    this.caixaNome,
    this.colaboradorId,
    this.colaboradorNome,
    required this.descricao,
    this.fotoUrl,
    this.fotoNome,
    this.arquivoUrl,
    this.arquivoNome,
    required this.gravidade,
    this.resolvida = false,
    required this.registradaEm,
    this.resolvidaEm,
  });
}

// ── Provider ──────────────────────────────────────────────────────────────────

class OcorrenciaProvider with ChangeNotifier {
  static const _table = 'ocorrencias';

  final List<Ocorrencia> _ocorrencias = [];

  List<Ocorrencia> get todas => _ocorrencias;
  List<Ocorrencia> get abertas =>
      _ocorrencias.where((o) => !o.resolvida).toList();
  List<Ocorrencia> get resolvidas =>
      _ocorrencias.where((o) => o.resolvida).toList();
  int get totalAbertas => abertas.length;

  List<Ocorrencia> get hoje {
    final agora = DateTime.now();
    return _ocorrencias.where((o) {
      return o.registradaEm.year == agora.year &&
          o.registradaEm.month == agora.month &&
          o.registradaEm.day == agora.day;
    }).toList();
  }

  String get _fiscalId => SupabaseClientManager.currentUserId!;

  Future<void> load() async {
    try {
      final rows = await SupabaseClientManager.client
          .from(_table)
          .select()
          .eq('fiscal_id', _fiscalId)
          .order('registrada_em', ascending: false);

      _ocorrencias.clear();
      _ocorrencias.addAll(rows.map(_fromMap));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OcorrenciaProvider] Erro ao carregar: $e');
      }
    }
  }

  void registrar({
    required String tipo,
    String? caixaId,
    String? caixaNome,
    String? colaboradorId,
    String? colaboradorNome,
    required String descricao,
    required GravidadeOcorrencia gravidade,
    String? fotoUrl,
    String? fotoNome,
    String? arquivoUrl,
    String? arquivoNome,
  }) {
    final oc = Ocorrencia(
      id: const Uuid().v4(),
      tipo: tipo.trim().isEmpty ? 'Outro' : tipo.trim(),
      caixaId: caixaId,
      caixaNome: caixaNome,
      colaboradorId: colaboradorId,
      colaboradorNome: colaboradorNome,
      descricao: descricao,
      fotoUrl: fotoUrl,
      fotoNome: fotoNome,
      arquivoUrl: arquivoUrl,
      arquivoNome: arquivoNome,
      gravidade: gravidade,
      registradaEm: DateTime.now(),
    );
    _ocorrencias.insert(0, oc);
    notifyListeners();
    _upsert(oc);
  }

  void resolver(String id) {
    final index = _ocorrencias.indexWhere((o) => o.id == id);
    if (index == -1) return;
    final agora = DateTime.now();
    _ocorrencias[index].resolvida = true;
    _ocorrencias[index].resolvidaEm = agora;
    notifyListeners();
    SupabaseClientManager.client
        .from(_table)
        .update({
          'resolvida': true,
          'resolvida_em': agora.toIso8601String(),
        })
        .eq('id', id)
        .then((_) {})
        .catchError((e) {
          if (kDebugMode) {
            debugPrint('[OcorrenciaProvider] Erro ao resolver: $e');
          }
        });
  }

  void deletar(String id) {
    _ocorrencias.removeWhere((o) => o.id == id);
    notifyListeners();
    SupabaseClientManager.client
        .from(_table)
        .delete()
        .eq('id', id)
        .then((_) {})
        .catchError((e) {
      if (kDebugMode) {
        debugPrint('[OcorrenciaProvider] Erro ao deletar: $e');
      }
    });
  }

  void _upsert(Ocorrencia o) {
    SupabaseClientManager.client
        .from(_table)
        .upsert({
          'id': o.id,
          'fiscal_id': _fiscalId,
          'tipo': o.tipo, // agora salva o texto livre diretamente
          'caixa_id': o.caixaId,
          'caixa_nome': o.caixaNome,
          'colaborador_id': o.colaboradorId,
          'colaborador_nome': o.colaboradorNome,
          'descricao': o.descricao,
          'foto_url': o.fotoUrl,
          'foto_nome': o.fotoNome,
          'arquivo_url': o.arquivoUrl,
          'arquivo_nome': o.arquivoNome,
          'gravidade': o.gravidade.name,
          'resolvida': o.resolvida,
          'registrada_em': o.registradaEm.toIso8601String(),
          'resolvida_em': o.resolvidaEm?.toIso8601String(),
        })
        .then((_) {})
        .catchError((e) {
          if (kDebugMode) {
            debugPrint('[OcorrenciaProvider] Erro ao sync: $e');
          }
        });
  }

  Ocorrencia _fromMap(Map<String, dynamic> m) => Ocorrencia(
        id: m['id'] as String,
        tipo: m['tipo'] as String? ?? 'Outro',
        caixaId: m['caixa_id'] as String?,
        caixaNome: m['caixa_nome'] as String?,
        colaboradorId: m['colaborador_id'] as String?,
        colaboradorNome: m['colaborador_nome'] as String?,
        descricao: m['descricao'] as String? ?? '',
        fotoUrl: m['foto_url'] as String?,
        fotoNome: m['foto_nome'] as String?,
        arquivoUrl: m['arquivo_url'] as String?,
        arquivoNome: m['arquivo_nome'] as String?,
        gravidade: GravidadeOcorrencia.fromString(
            m['gravidade'] as String? ?? 'media'),
        resolvida: m['resolvida'] as bool? ?? false,
        registradaEm: DateTime.parse(m['registrada_em'] as String),
        resolvidaEm: m['resolvida_em'] != null
            ? DateTime.parse(m['resolvida_em'] as String)
            : null,
      );
}
