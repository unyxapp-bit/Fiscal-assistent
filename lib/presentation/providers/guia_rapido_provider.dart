import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/datasources/remote/supabase_client.dart';

// ── Opções de ícone disponíveis ────────────────────────────────────────────────

const kGuiaIcones = <(String, IconData, String)>[
  ('caixa', Icons.point_of_sale, 'Caixa'),
  ('pessoa', Icons.person, 'Pessoa'),
  ('cartao', Icons.credit_card, 'Cartão'),
  ('impressora', Icons.print, 'Impressora'),
  ('computador', Icons.computer, 'Computador'),
  ('seguranca', Icons.security, 'Segurança'),
  ('alerta', Icons.warning_amber, 'Alerta'),
  ('hospital', Icons.local_hospital, 'Emergência'),
  ('dinheiro', Icons.attach_money, 'Dinheiro'),
  ('produto', Icons.qr_code, 'Produto'),
  ('ferramenta', Icons.build, 'Ferramenta'),
  ('info', Icons.info_outline, 'Info'),
];

// ── Opções de cor disponíveis ──────────────────────────────────────────────────

const kGuiaCores = <Color>[
  Color(0xFFFF9800), // laranja
  Color(0xFF9C27B0), // roxo
  Color(0xFF2196F3), // azul
  Color(0xFFF44336), // vermelho
  Color(0xFF4CAF50), // verde
  Color(0xFF607D8B), // cinza-azul
  Color(0xFF795548), // marrom
  Color(0xFF009688), // teal
  Color(0xFF3F51B5), // índigo
  Color(0xFFE91E63), // rosa
];

IconData iconeParaKey(String key) {
  for (final t in kGuiaIcones) {
    if (t.$1 == key) return t.$2;
  }
  return Icons.help_outline;
}

// ── Modelo ────────────────────────────────────────────────────────────────────

class SituacaoGuia {
  final String id;
  final String titulo;
  final String categoria;
  final String corHex; // ex: 'FF9800'
  final String iconeKey; // ex: 'caixa'
  final List<String> passos;
  final bool isDefault;

  const SituacaoGuia({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.corHex,
    required this.iconeKey,
    required this.passos,
    this.isDefault = false,
  });

  Color get cor => Color(int.parse('FF$corHex', radix: 16));
  IconData get icone => iconeParaKey(iconeKey);

  SituacaoGuia copyWith({
    String? titulo,
    String? categoria,
    String? corHex,
    String? iconeKey,
    List<String>? passos,
  }) =>
      SituacaoGuia(
        id: id,
        titulo: titulo ?? this.titulo,
        categoria: categoria ?? this.categoria,
        corHex: corHex ?? this.corHex,
        iconeKey: iconeKey ?? this.iconeKey,
        passos: passos ?? this.passos,
        isDefault: isDefault,
      );

  Map<String, dynamic> toMap(String fiscalId) => {
        'id': id,
        'fiscal_id': fiscalId,
        'titulo': titulo,
        'categoria': categoria,
        'cor_hex': corHex,
        'icone_key': iconeKey,
        'passos': passos,
        'is_default': isDefault,
      };

  static SituacaoGuia fromMap(Map<String, dynamic> m) => SituacaoGuia(
        id: m['id'] as String,
        titulo: m['titulo'] as String,
        categoria: m['categoria'] as String,
        corHex: m['cor_hex'] as String? ?? '607D8B',
        iconeKey: m['icone_key'] as String? ?? 'outro',
        passos: (m['passos'] as List?)?.map((e) => e.toString()).toList() ?? [],
        isDefault: m['is_default'] as bool? ?? false,
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

class GuiaRapidoProvider with ChangeNotifier {
  static const _table = 'guia_rapido';

  final List<SituacaoGuia> _situacoes = [];

  List<SituacaoGuia> get situacoes => List.unmodifiable(_situacoes);

  List<String> get categorias =>
      _situacoes.map((s) => s.categoria).toSet().toList()..sort();

  String get _fiscalId => SupabaseClientManager.currentUserId!;

  Future<void> load() async {
    try {
      final rows = await SupabaseClientManager.client
          .from(_table)
          .select()
          .eq('fiscal_id', _fiscalId)
          .order('categoria')
          .order('titulo');

      _situacoes.clear();

      _situacoes.addAll(rows.map(SituacaoGuia.fromMap));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[GuiaRapidoProvider] Erro ao carregar: $e');
      // Sem fallback local: mantém estado consistente com o Supabase.
    }
  }

  Future<void> adicionar(SituacaoGuia s) async {
    _situacoes.add(s);
    notifyListeners();
    try {
      await SupabaseClientManager.client
          .from(_table)
          .upsert(s.toMap(_fiscalId));
    } catch (e) {
      _situacoes.removeWhere((x) => x.id == s.id);
      notifyListeners();
      if (kDebugMode) debugPrint('[GuiaRapidoProvider] Erro ao salvar: $e');
      rethrow;
    }
  }

  Future<void> atualizar(SituacaoGuia s) async {
    final idx = _situacoes.indexWhere((x) => x.id == s.id);
    if (idx == -1) return;
    final anterior = _situacoes[idx];
    _situacoes[idx] = s;
    notifyListeners();
    try {
      await SupabaseClientManager.client
          .from(_table)
          .upsert(s.toMap(_fiscalId));
    } catch (e) {
      _situacoes[idx] = anterior;
      notifyListeners();
      if (kDebugMode) debugPrint('[GuiaRapidoProvider] Erro ao atualizar: $e');
      rethrow;
    }
  }

  Future<void> deletar(String id) async {
    final removido = _situacoes.where((s) => s.id == id).toList();
    _situacoes.removeWhere((s) => s.id == id);
    notifyListeners();
    try {
      await SupabaseClientManager.client.from(_table).delete().eq('id', id);
    } catch (e) {
      if (removido.isNotEmpty) {
        _situacoes.addAll(removido);
        notifyListeners();
      }
      if (kDebugMode) debugPrint('[GuiaRapidoProvider] Erro ao deletar: $e');
      rethrow;
    }
  }
}
