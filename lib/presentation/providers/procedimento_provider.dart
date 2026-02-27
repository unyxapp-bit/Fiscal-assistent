import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/remote/supabase_client.dart';

/// Model para Procedimento
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

/// Provider para gerenciar procedimentos com persistência no Supabase
class ProcedimentoProvider with ChangeNotifier {
  static const _table = 'procedimentos';

  // Seed keys estáveis para os pré-carregados
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

  List<Procedimento> get procedimentos => _procedimentos;
  List<Procedimento> get favoritos =>
      _procedimentos.where((p) => p.favorito).toList();

  String get _fiscalId => SupabaseClientManager.currentUserId!;

  /// Carrega procedimentos do Supabase. Faz seed dos pré-carregados na 1ª vez.
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
      if (kDebugMode) debugPrint('[ProcedimentoProvider] Erro ao carregar: $e');
    }
  }

  /// Adiciona procedimento
  void adicionarProcedimento({
    required String titulo,
    required String descricao,
    required String categoria,
    required List<String> passos,
    int? tempoEstimado,
  }) {
    final proc = Procedimento(
      id: const Uuid().v4(),
      titulo: titulo,
      descricao: descricao,
      categoria: categoria,
      passos: passos,
      tempoEstimado: tempoEstimado,
    );
    _procedimentos.add(proc);
    notifyListeners();
    _upsert(proc, seedKey: null);
  }

  /// Toggle favorito
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
        if (kDebugMode) debugPrint('[ProcedimentoProvider] Erro ao toggle: $e');
      });
    }
  }

  /// Edita procedimento existente
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

  /// Remove procedimento
  void removerProcedimento(String id) {
    _procedimentos.removeWhere((p) => p.id == id);
    notifyListeners();
    SupabaseClientManager.client
        .from(_table)
        .delete()
        .eq('id', id)
        .then((_) {})
        .catchError((e) {
      if (kDebugMode) debugPrint('[ProcedimentoProvider] Erro ao remover: $e');
    });
  }

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
      if (kDebugMode) debugPrint('[ProcedimentoProvider] Erro ao sync: $e');
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
      if (kDebugMode) debugPrint('[ProcedimentoProvider] Erro ao seed: $e');
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
