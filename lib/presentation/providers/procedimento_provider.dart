import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/remote/supabase_client.dart';
import '../../core/constants/colors.dart';

// ── Extension de helpers por categoria ────────────────────────────────────────

extension CategoriaExt on String {
  Color get categoriaColor {
    switch (this) {
      case 'abertura':
        return AppColors.success;
      case 'fechamento':
        return AppColors.danger;
      case 'emergencia':
        return AppColors.statusAtencao;
      case 'rotina':
        return AppColors.primary;
      case 'fiscal':
        return Colors.purple;
      case 'caixa':
        return AppColors.statusCafe;
      default:
        return AppColors.inactive;
    }
  }

  IconData get categoriaIcon {
    switch (this) {
      case 'abertura':
        return Icons.lock_open;
      case 'fechamento':
        return Icons.lock;
      case 'emergencia':
        return Icons.warning;
      case 'rotina':
        return Icons.checklist;
      case 'fiscal':
        return Icons.person;
      case 'caixa':
        return Icons.point_of_sale;
      default:
        return Icons.help;
    }
  }

  String get categoriaNome {
    switch (this) {
      case 'abertura':
        return 'Abertura';
      case 'fechamento':
        return 'Fechamento';
      case 'emergencia':
        return 'Emergência';
      case 'rotina':
        return 'Rotina';
      case 'fiscal':
        return 'Fiscal';
      case 'caixa':
        return 'Caixa';
      default:
        return this;
    }
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class Procedimento {
  final String id;
  final String titulo;
  final String descricao;
  final String categoria; // abertura, fechamento, emergencia, rotina, fiscal, caixa
  final List<String> passos;
  bool favorito;
  final int? tempoEstimado;

  Procedimento({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.categoria,
    required this.passos,
    this.favorito = false,
    this.tempoEstimado,
  });

  Procedimento copyWith({
    String? id,
    String? titulo,
    String? descricao,
    String? categoria,
    List<String>? passos,
    bool? favorito,
    int? tempoEstimado,
  }) {
    return Procedimento(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      passos: passos ?? this.passos,
      favorito: favorito ?? this.favorito,
      tempoEstimado: tempoEstimado ?? this.tempoEstimado,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

class ProcedimentoProvider with ChangeNotifier {
  static const _table = 'procedimentos';

  static const _seeds = [
    'proc_fatura_dmcard',
    'proc_emissao_nf',
    'proc_nota_devolucao',
    'proc_fechamento_maquinas',
    'proc_imprimir_vasilhames',
    'proc_consulta_cheques',
    'proc_cadastro_clientes',
    'proc_emitir_cupom',
    'proc_nota_cupom_pequeno',
  ];

  final List<Procedimento> _procedimentos = [];

  // ── Estado de busca/filtro ─────────────────────────────────────────────────
  String _searchQuery = '';
  String? _filtroCategoria;

  // ── Getters públicos ───────────────────────────────────────────────────────

  List<Procedimento> get procedimentos => _procedimentos;

  String? get filtroCategoria => _filtroCategoria;
  String get searchQuery => _searchQuery;

  List<Procedimento> get procedimentosFiltrados {
    var result = List<Procedimento>.from(_procedimentos);
    if (_filtroCategoria != null) {
      result = result.where((p) => p.categoria == _filtroCategoria).toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((p) =>
              p.titulo.toLowerCase().contains(_searchQuery) ||
              p.descricao.toLowerCase().contains(_searchQuery))
          .toList();
    }
    return result;
  }

  List<Procedimento> get favoritos =>
      _procedimentos.where((p) => p.favorito).toList();

  int countByCategoria(String cat) =>
      _procedimentos.where((p) => p.categoria == cat).length;

  String get _fiscalId => SupabaseClientManager.currentUserId!;

  // ── Busca/filtro ───────────────────────────────────────────────────────────

  void setSearchQuery(String q) {
    _searchQuery = q.toLowerCase().trim();
    notifyListeners();
  }

  void setFiltroCategoria(String? cat) {
    _filtroCategoria = cat;
    notifyListeners();
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<void> load() async {
    try {
      final rows = await SupabaseClientManager.client
          .from(_table)
          .select()
          .eq('fiscal_id', _fiscalId)
          .order('created_at');

      _procedimentos.clear();

      if (rows.isEmpty) {
        await _seedProcedimentos();
      } else {
        _procedimentos.addAll(rows.map(_fromMap));
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProcedimentoProvider] Erro ao carregar: $e');
      }
    }
  }

  /// Adiciona procedimento — favorito é passado diretamente (sem toggleFavorito posterior)
  void adicionarProcedimento({
    required String titulo,
    required String descricao,
    required String categoria,
    required List<String> passos,
    int? tempoEstimado,
    bool favorito = false,
  }) {
    final proc = Procedimento(
      id: const Uuid().v4(),
      titulo: titulo,
      descricao: descricao,
      categoria: categoria,
      passos: passos,
      favorito: favorito,
      tempoEstimado: tempoEstimado,
    );
    _procedimentos.add(proc);
    notifyListeners();
    _upsert(proc, seedKey: null);
  }

  void toggleFavorito(String id) {
    final index = _procedimentos.indexWhere((p) => p.id == id);
    if (index != -1) {
      _procedimentos[index].favorito = !_procedimentos[index].favorito;
      notifyListeners();
      SupabaseClientManager.client
          .from(_table)
          .update({'favorito': _procedimentos[index].favorito})
          .eq('id', id)
          .then((_) {})
          .catchError((e) {
        if (kDebugMode) {
          debugPrint('[ProcedimentoProvider] Erro ao toggle: $e');
        }
      });
    }
  }

  void editarProcedimento({
    required String id,
    required String titulo,
    required String descricao,
    required String categoria,
    required List<String> passos,
    int? tempoEstimado,
    bool? favorito,
  }) {
    final index = _procedimentos.indexWhere((p) => p.id == id);
    if (index != -1) {
      final updated = Procedimento(
        id: id,
        titulo: titulo,
        descricao: descricao,
        categoria: categoria,
        passos: passos,
        favorito: favorito ?? _procedimentos[index].favorito,
        tempoEstimado: tempoEstimado,
      );
      _procedimentos[index] = updated;
      notifyListeners();
      _upsert(updated, seedKey: null);
    }
  }

  void removerProcedimento(String id) {
    _procedimentos.removeWhere((p) => p.id == id);
    notifyListeners();
    SupabaseClientManager.client
        .from(_table)
        .delete()
        .eq('id', id)
        .then((_) {})
        .catchError((e) {
      if (kDebugMode) {
        debugPrint('[ProcedimentoProvider] Erro ao remover: $e');
      }
    });
  }

  // ── Internos ───────────────────────────────────────────────────────────────

  void _upsert(Procedimento p, {String? seedKey}) {
    SupabaseClientManager.client.from(_table).upsert({
      'id': p.id,
      'fiscal_id': _fiscalId,
      if (seedKey != null) 'seed_key': seedKey,
      'titulo': p.titulo,
      'descricao': p.descricao,
      'categoria': p.categoria,
      'passos': p.passos,
      'favorito': p.favorito,
      'tempo_estimado': p.tempoEstimado,
      'updated_at': DateTime.now().toIso8601String(),
    }).then((_) {}).catchError((e) {
      if (kDebugMode) {
        debugPrint('[ProcedimentoProvider] Erro ao sync: $e');
      }
    });
  }

  Future<void> _seedProcedimentos() async {
    final templates = _buildTemplates();
    try {
      final data = templates
          .asMap()
          .entries
          .map((e) => {
                'id': e.value.id,
                'fiscal_id': _fiscalId,
                'seed_key': _seeds[e.key],
                'titulo': e.value.titulo,
                'descricao': e.value.descricao,
                'categoria': e.value.categoria,
                'passos': e.value.passos,
                'favorito': false,
                'tempo_estimado': e.value.tempoEstimado,
              })
          .toList();
      await SupabaseClientManager.client.from(_table).insert(data);
      _procedimentos.addAll(templates);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProcedimentoProvider] Erro ao seed: $e');
      }
      _procedimentos.addAll(templates);
    }
  }

  Procedimento _fromMap(Map<String, dynamic> m) => Procedimento(
        id: m['id'] as String,
        titulo: m['titulo'] as String,
        descricao: m['descricao'] as String? ?? '',
        categoria: m['categoria'] as String? ?? 'rotina',
        passos: List<String>.from(m['passos'] as List? ?? []),
        favorito: m['favorito'] as bool? ?? false,
        tempoEstimado: m['tempo_estimado'] as int?,
      );

  List<Procedimento> _buildTemplates() => [
        Procedimento(
          id: const Uuid().v4(),
          titulo: 'FATURA DM CARD',
          descricao: 'Procedimento para processar e emitir fatura do cartão DM Card',
          categoria: 'caixa',
          passos: [
            'Acessar o sistema',
            'Ir em Menu > Financeiro > Fatura DM Card',
            'Selecionar o período desejado',
            'Conferir os lançamentos do cartão',
            'Gerar fatura e imprimir',
            'Arquivar cópia para controle',
          ],
          tempoEstimado: 10,
        ),
        Procedimento(
          id: const Uuid().v4(),
          titulo: 'EMISSÃO DE NOTA FISCAL',
          descricao: 'Como emitir nota fiscal completa no sistema',
          categoria: 'fiscal',
          passos: [
            'Acessar Sistema > Menu Fiscal',
            'Selecionar "Emissão de NF-e"',
            'Preencher dados do cliente (CNPJ/CPF, nome, endereço)',
            'Adicionar produtos e valores',
            'Conferir CFOP e tributação',
            'Gerar e transmitir nota fiscal',
            'Imprimir DANFE e entregar ao cliente',
          ],
          tempoEstimado: 15,
        ),
        Procedimento(
          id: const Uuid().v4(),
          titulo: 'NOTA DE DEVOLUÇÃO',
          descricao: 'Procedimento para emitir nota fiscal de devolução',
          categoria: 'fiscal',
          passos: [
            'Ter em mãos a nota fiscal original',
            'Acessar Sistema > Devolução',
            'Informar chave da NF-e original',
            'Selecionar produtos devolvidos',
            'Conferir motivo da devolução',
            'Emitir NF-e de devolução',
            'Processar estorno no sistema',
          ],
          tempoEstimado: 12,
        ),
        Procedimento(
          id: const Uuid().v4(),
          titulo: 'FECHAMENTO DAS MÁQUINAS DE CARTÃO',
          descricao: 'Como fazer o fechamento correto das máquinas de cartão',
          categoria: 'fechamento',
          passos: [
            'Aguardar fim do expediente (após último cliente)',
            'Acessar menu da máquina > Relatórios',
            'Selecionar "Fechamento" ou "Lote"',
            'Confirmar fechamento do dia',
            'Aguardar impressão do comprovante',
            'Arquivar comprovante com malote',
            'Repetir para todas as máquinas (Rede, Cielo, etc.)',
          ],
          tempoEstimado: 20,
        ),
        Procedimento(
          id: const Uuid().v4(),
          titulo: 'IMPRIMIR VASILHAMES',
          descricao: 'Procedimento para imprimir etiquetas de controle de vasilhames',
          categoria: 'rotina',
          passos: [
            'Acessar Sistema > Relatórios',
            'Selecionar "Vasilhames"',
            'Escolher tipo (cerveja, água, gás)',
            'Definir quantidade de etiquetas',
            'Configurar impressora de etiquetas',
            'Imprimir e colar nos vasilhames',
          ],
          tempoEstimado: 8,
        ),
        Procedimento(
          id: const Uuid().v4(),
          titulo: 'CONSULTA DE CHEQUES',
          descricao: 'Como consultar situação de cheques no sistema',
          categoria: 'caixa',
          passos: [
            'Receber cheque do cliente',
            'Acessar Sistema > Consulta de Cheques',
            'Digitar número do cheque e banco',
            'Verificar situação (sem fundos, sustado, etc.)',
            'Se aprovado, registrar no sistema',
            'Se reprovado, informar cliente educadamente',
          ],
          tempoEstimado: 5,
        ),
        Procedimento(
          id: const Uuid().v4(),
          titulo: 'CADASTRO DE CLIENTES',
          descricao: 'Procedimento para cadastrar novos clientes no sistema',
          categoria: 'caixa',
          passos: [
            'Acessar Sistema > Cadastros > Clientes',
            'Clicar em "Novo Cliente"',
            'Preencher dados pessoais (nome, CPF/CNPJ)',
            'Adicionar endereço completo',
            'Incluir telefones e e-mail',
            'Definir limite de crédito (se aplicável)',
            'Salvar cadastro',
          ],
          tempoEstimado: 10,
        ),
        Procedimento(
          id: const Uuid().v4(),
          titulo: 'EMITIR CUPOM FISCAL',
          descricao: 'Como emitir cupom fiscal padrão no sistema',
          categoria: 'caixa',
          passos: [
            'Registrar produtos no caixa normalmente',
            'Finalizar venda (F2 ou botão Finalizar)',
            'Selecionar forma de pagamento',
            'Confirmar emissão do cupom',
            'Aguardar impressão',
            'Entregar cupom ao cliente',
          ],
          tempoEstimado: 3,
        ),
        Procedimento(
          id: const Uuid().v4(),
          titulo: 'Emitir nota fiscal (cupom pequeno)',
          descricao: 'Emissão rápida de nota fiscal para cupom não fiscal',
          categoria: 'caixa',
          passos: [
            'Cliente solicita nota fiscal após compra',
            'Acessar Sistema > NF-e rápida',
            'Informar CPF/CNPJ do cliente',
            'Vincular ao cupom não fiscal',
            'Emitir e imprimir nota resumida',
            'Entregar ao cliente',
          ],
          tempoEstimado: 5,
        ),
      ];
}
