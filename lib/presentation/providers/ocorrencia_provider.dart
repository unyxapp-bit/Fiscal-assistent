import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/remote/supabase_client.dart';
import '../../core/constants/colors.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum TipoOcorrencia {
  briga,
  furto,
  erroCaixa,
  equipamento,
  reclamacao,
  ausencia,
  outro;

  String get nome {
    switch (this) {
      case TipoOcorrencia.briga:
        return 'Briga/Conflito';
      case TipoOcorrencia.furto:
        return 'Furto/Perda';
      case TipoOcorrencia.erroCaixa:
        return 'Erro de Caixa';
      case TipoOcorrencia.equipamento:
        return 'Equipamento';
      case TipoOcorrencia.reclamacao:
        return 'Reclamação';
      case TipoOcorrencia.ausencia:
        return 'Ausência';
      case TipoOcorrencia.outro:
        return 'Outro';
    }
  }

  String get dbKey {
    switch (this) {
      case TipoOcorrencia.briga:
        return 'briga';
      case TipoOcorrencia.furto:
        return 'furto';
      case TipoOcorrencia.erroCaixa:
        return 'erro_caixa';
      case TipoOcorrencia.equipamento:
        return 'equipamento';
      case TipoOcorrencia.reclamacao:
        return 'reclamacao';
      case TipoOcorrencia.ausencia:
        return 'ausencia';
      case TipoOcorrencia.outro:
        return 'outro';
    }
  }

  IconData get icone {
    switch (this) {
      case TipoOcorrencia.briga:
        return Icons.warning_amber;
      case TipoOcorrencia.furto:
        return Icons.security;
      case TipoOcorrencia.erroCaixa:
        return Icons.point_of_sale;
      case TipoOcorrencia.equipamento:
        return Icons.build;
      case TipoOcorrencia.reclamacao:
        return Icons.sentiment_dissatisfied;
      case TipoOcorrencia.ausencia:
        return Icons.person_off;
      case TipoOcorrencia.outro:
        return Icons.more_horiz;
    }
  }

  static TipoOcorrencia fromString(String s) => TipoOcorrencia.values
      .firstWhere((t) => t.dbKey == s, orElse: () => TipoOcorrencia.outro);
}

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
  final TipoOcorrencia tipo;
  final String? caixaId;
  final String descricao;
  final GravidadeOcorrencia gravidade;
  bool resolvida;
  final DateTime registradaEm;
  DateTime? resolvidaEm;

  Ocorrencia({
    required this.id,
    required this.tipo,
    this.caixaId,
    required this.descricao,
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
    required TipoOcorrencia tipo,
    String? caixaId,
    required String descricao,
    required GravidadeOcorrencia gravidade,
  }) {
    final oc = Ocorrencia(
      id: const Uuid().v4(),
      tipo: tipo,
      caixaId: caixaId,
      descricao: descricao,
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
    SupabaseClientManager.client.from(_table).upsert({
      'id': o.id,
      'fiscal_id': _fiscalId,
      'tipo': o.tipo.dbKey,
      'caixa_id': o.caixaId,
      'descricao': o.descricao,
      'gravidade': o.gravidade.name,
      'resolvida': o.resolvida,
      'registrada_em': o.registradaEm.toIso8601String(),
      'resolvida_em': o.resolvidaEm?.toIso8601String(),
    }).then((_) {}).catchError((e) {
      if (kDebugMode) {
        debugPrint('[OcorrenciaProvider] Erro ao sync: $e');
      }
    });
  }

  Ocorrencia _fromMap(Map<String, dynamic> m) => Ocorrencia(
        id: m['id'] as String,
        tipo: TipoOcorrencia.fromString(m['tipo'] as String? ?? 'outro'),
        caixaId: m['caixa_id'] as String?,
        descricao: m['descricao'] as String? ?? '',
        gravidade: GravidadeOcorrencia.fromString(
            m['gravidade'] as String? ?? 'media'),
        resolvida: m['resolvida'] as bool? ?? false,
        registradaEm: DateTime.parse(m['registrada_em'] as String),
        resolvidaEm: m['resolvida_em'] != null
            ? DateTime.parse(m['resolvida_em'] as String)
            : null,
      );
}
