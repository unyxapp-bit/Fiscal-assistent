import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/formulario.dart';
import '../../data/datasources/remote/supabase_client.dart';

class FormularioProvider with ChangeNotifier {
  static const _tableF = 'formularios';
  static const _tableR = 'respostas_formulario';

  final List<Formulario> _formularios = [];
  final List<RespostaFormulario> _respostas = [];

  // ─── Getters ───────────────────────────────────────────────────────────────

  List<Formulario> get formularios => _formularios;
  List<Formulario> get templates =>
      _formularios.where((f) => f.template).toList();

  /// Todos os personalizados (ativos e inativos).
  List<Formulario> get personalizados =>
      _formularios.where((f) => !f.template).toList();

  List<RespostaFormulario> get respostas => _respostas;

  int get totalFormularios => _formularios.length;
  int get totalRespostas => _respostas.length;

  String get _fiscalId => SupabaseClientManager.currentUserId!;

  List<RespostaFormulario> respostasPorFormulario(String formularioId) =>
      _respostas
          .where((r) => r.formularioId == formularioId)
          .toList()
        ..sort((a, b) => b.preenchidoEm.compareTo(a.preenchidoEm));

  int totalRespostasPorFormulario(String formularioId) =>
      respostasPorFormulario(formularioId).length;

  /// Respostas registradas hoje para o formulário.
  int respostasHoje(String formularioId) {
    final hoje = DateTime.now();
    return _respostas.where((r) {
      return r.formularioId == formularioId &&
          r.preenchidoEm.year == hoje.year &&
          r.preenchidoEm.month == hoje.month &&
          r.preenchidoEm.day == hoje.day;
    }).length;
  }

  // ─── Load ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    try {
      final rows = await SupabaseClientManager.client
          .from(_tableF)
          .select()
          .eq('fiscal_id', _fiscalId)
          .order('created_at');

      _formularios.clear();

      if (rows.isEmpty) {
        await _seedTemplates();
      } else {
        _formularios.addAll(rows.map(_fromMapF));
      }

      final rowsR = await SupabaseClientManager.client
          .from(_tableR)
          .select()
          .eq('fiscal_id', _fiscalId)
          .order('preenchido_em', ascending: false);

      _respostas
        ..clear()
        ..addAll(rowsR.map(_fromMapR));

      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[FormularioProvider] Erro ao carregar: $e');
    }
  }

  // ─── CRUD Formulários ──────────────────────────────────────────────────────

  void adicionarFormulario(Formulario formulario) {
    _formularios.add(formulario);
    notifyListeners();
    _upsertF(formulario);
  }

  void atualizarFormulario(Formulario formulario) {
    final index = _formularios.indexWhere((f) => f.id == formulario.id);
    if (index != -1) {
      _formularios[index] = formulario;
      notifyListeners();
      _upsertF(formulario);
    }
  }

  void deletarFormulario(String id) {
    _formularios.removeWhere((f) => f.id == id);
    _respostas.removeWhere((r) => r.formularioId == id);
    notifyListeners();
    SupabaseClientManager.client
        .from(_tableF)
        .delete()
        .eq('id', id)
        .then((_) {})
        .catchError((e) {
      if (kDebugMode) debugPrint('[FormularioProvider] Erro ao deletar: $e');
    });
  }

  /// Duplica um template como formulário personalizado.
  void duplicarTemplate(Formulario template) {
    final now = DateTime.now();
    final copia = Formulario(
      id: const Uuid().v4(),
      titulo: '${template.titulo} (cópia)',
      descricao: template.descricao,
      template: false,
      ativo: true,
      campos: template.campos,
      createdAt: now,
      updatedAt: now,
    );
    adicionarFormulario(copia);
  }

  /// Ativa/desativa um formulário personalizado sem deletar.
  void toggleAtivo(String id) {
    final index = _formularios.indexWhere((f) => f.id == id);
    if (index != -1) {
      final atualizado = _formularios[index].copyWith(
        ativo: !_formularios[index].ativo,
        updatedAt: DateTime.now(),
      );
      _formularios[index] = atualizado;
      notifyListeners();
      _upsertF(atualizado);
    }
  }

  // ─── CRUD Respostas ────────────────────────────────────────────────────────

  void adicionarResposta(RespostaFormulario resposta) {
    _respostas.add(resposta);
    notifyListeners();
    SupabaseClientManager.client.from(_tableR).insert({
      'id': resposta.id,
      'fiscal_id': _fiscalId,
      'formulario_id': resposta.formularioId,
      'valores': resposta.valores,
      'preenchido_em': resposta.preenchidoEm.toIso8601String(),
    }).then((_) {}).catchError((e) {
      if (kDebugMode) {
        debugPrint('[FormularioProvider] Erro ao salvar resposta: $e');
      }
    });
  }

  void deletarResposta(String id) {
    _respostas.removeWhere((r) => r.id == id);
    notifyListeners();
    SupabaseClientManager.client
        .from(_tableR)
        .delete()
        .eq('id', id)
        .then((_) {})
        .catchError((e) {
      if (kDebugMode) {
        debugPrint('[FormularioProvider] Erro ao deletar resposta: $e');
      }
    });
  }

  // ─── Sync ─────────────────────────────────────────────────────────────────

  void _upsertF(Formulario f) {
    SupabaseClientManager.client.from(_tableF).upsert({
      'id': f.id,
      'fiscal_id': _fiscalId,
      'titulo': f.titulo,
      'descricao': f.descricao,
      'template': f.template,
      'ativo': f.ativo,
      'campos': f.campos.map((c) => c.toMap()).toList(),
      'created_at': f.createdAt.toIso8601String(),
      'updated_at': f.updatedAt.toIso8601String(),
    }).then((_) {}).catchError((e) {
      if (kDebugMode) {
        debugPrint('[FormularioProvider] Erro ao sincronizar: $e');
      }
    });
  }

  // ─── Parse ────────────────────────────────────────────────────────────────

  Formulario _fromMapF(Map<String, dynamic> m) {
    final rawCampos = m['campos'] as List? ?? [];
    return Formulario(
      id: m['id'] as String,
      titulo: m['titulo'] as String,
      descricao: m['descricao'] as String? ?? '',
      template: m['template'] as bool? ?? false,
      ativo: m['ativo'] as bool? ?? true,
      campos: rawCampos.map<CampoFormulario>(CampoFormulario.fromRaw).toList(),
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
    );
  }

  RespostaFormulario _fromMapR(Map<String, dynamic> m) => RespostaFormulario(
        id: m['id'] as String,
        formularioId: m['formulario_id'] as String,
        valores: Map<String, dynamic>.from(m['valores'] as Map? ?? {}),
        preenchidoEm: DateTime.parse(m['preenchido_em'] as String),
      );

  // ─── Templates ────────────────────────────────────────────────────────────

  static String _tmplUuid(String key) =>
      const Uuid().v5(Namespace.url.value, key);

  static CampoFormulario _c(
    String tmplKey,
    String label, {
    TipoCampo tipo = TipoCampo.texto,
    bool obrigatorio = true,
    List<String> opcoes = const [],
  }) =>
      CampoFormulario(
        id: const Uuid().v5(Namespace.url.value, '$tmplKey:$label'),
        label: label,
        tipo: tipo,
        obrigatorio: obrigatorio,
        opcoes: opcoes,
      );

  Future<void> _seedTemplates() async {
    final templates = _buildTemplates();
    try {
      final data = templates
          .map((f) => {
                'id': f.id,
                'fiscal_id': _fiscalId,
                'seed_key': f.id,
                'titulo': f.titulo,
                'descricao': f.descricao,
                'template': true,
                'ativo': true,
                'campos': f.campos.map((c) => c.toMap()).toList(),
                'created_at': f.createdAt.toIso8601String(),
                'updated_at': f.updatedAt.toIso8601String(),
              })
          .toList();
      await SupabaseClientManager.client.from(_tableF).insert(data);
      _formularios.addAll(templates);
    } catch (e) {
      if (kDebugMode) debugPrint('[FormularioProvider] Erro ao seed: $e');
      _formularios.addAll(templates);
    }
  }

  List<Formulario> _buildTemplates() {
    final now = DateTime.now();
    const ab = 'tmpl_abertura';
    const fe = 'tmpl_fechamento';
    const oc = 'tmpl_ocorrencia';
    const rc = 'tmpl_reclamacao';
    const pf = 'tmpl_produto_falta';
    const td = 'tmpl_troca_devolucao';
    const af = 'tmpl_avaliacao_fornecedor';
    const tp = 'tmpl_temperatura';
    const vs = 'tmpl_vistoria_seguranca';
    const ac = 'tmpl_avaliacao_colaborador';

    return [
      Formulario(
        id: _tmplUuid(ab),
        titulo: 'Checklist de Abertura',
        descricao: 'Verificações necessárias para abertura da loja',
        template: true,
        campos: [
          _c(ab, 'Luzes ligadas', tipo: TipoCampo.simNao),
          _c(ab, 'Sistemas operacionais', tipo: TipoCampo.simNao),
          _c(ab, 'Caixas abertos', tipo: TipoCampo.simNao),
          _c(ab, 'Estoque verificado', tipo: TipoCampo.simNao),
          _c(ab, 'Limpeza conferida', tipo: TipoCampo.simNao),
          _c(ab, 'Colaboradores presentes', tipo: TipoCampo.simNao),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid(fe),
        titulo: 'Checklist de Fechamento',
        descricao: 'Procedimentos para fechamento correto da loja',
        template: true,
        campos: [
          _c(fe, 'Caixas fechados', tipo: TipoCampo.simNao),
          _c(fe, 'Fechamento de caixa conferido', tipo: TipoCampo.simNao),
          _c(fe, 'Sistemas desligados', tipo: TipoCampo.simNao),
          _c(fe, 'Luzes apagadas', tipo: TipoCampo.simNao),
          _c(fe, 'Alarme ativado', tipo: TipoCampo.simNao),
          _c(fe, 'Portas trancadas', tipo: TipoCampo.simNao),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid(oc),
        titulo: 'Registro de Ocorrência',
        descricao: 'Documento para registrar incidentes e ocorrências',
        template: true,
        campos: [
          _c(oc, 'Data e hora'),
          _c(oc, 'Tipo de ocorrência',
              tipo: TipoCampo.opcoes,
              opcoes: [
                'Roubo/Furto',
                'Acidente',
                'Briga',
                'Problema com cliente',
                'Falha de sistema',
                'Outro'
              ]),
          _c(oc, 'Descrição detalhada'),
          _c(oc, 'Pessoas envolvidas'),
          _c(oc, 'Ação tomada'),
          _c(oc, 'Responsável'),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid(rc),
        titulo: 'Reclamação de Cliente',
        descricao: 'Registrar reclamações e feedback negativo de clientes',
        template: true,
        campos: [
          _c(rc, 'Nome do cliente'),
          _c(rc, 'Telefone de contato', obrigatorio: false),
          _c(rc, 'Produto / Serviço'),
          _c(rc, 'Motivo da reclamação'),
          _c(rc, 'Solução proposta'),
          _c(rc, 'Status de resolução',
              tipo: TipoCampo.opcoes,
              opcoes: ['Aberto', 'Em andamento', 'Resolvido', 'Escalado']),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid(pf),
        titulo: 'Solicitação de Produto em Falta',
        descricao: 'Registrar produtos esgotados para reposição',
        template: true,
        campos: [
          _c(pf, 'Nome do produto'),
          _c(pf, 'Código / SKU', obrigatorio: false),
          _c(pf, 'Seção / Departamento'),
          _c(pf, 'Quantidade estimada', tipo: TipoCampo.numero),
          _c(pf, 'Urgência',
              tipo: TipoCampo.opcoes,
              opcoes: ['Alta', 'Média', 'Baixa']),
          _c(pf, 'Observações', obrigatorio: false),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid(td),
        titulo: 'Troca / Devolução',
        descricao: 'Controle de trocas e devoluções de produtos',
        template: true,
        campos: [
          _c(td, 'Nome do cliente'),
          _c(td, 'Número do cupom / NF'),
          _c(td, 'Produto devolvido'),
          _c(td, 'Motivo da troca'),
          _c(td, 'Produto escolhido (troca)', obrigatorio: false),
          _c(td, 'Valor do estorno (devolução)', obrigatorio: false),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid(af),
        titulo: 'Avaliação de Fornecedor',
        descricao: 'Avaliar a qualidade e pontualidade de fornecedores',
        template: true,
        campos: [
          _c(af, 'Nome do fornecedor'),
          _c(af, 'Data da entrega'),
          _c(af, 'Produto(s) entregue(s)'),
          _c(af, 'Qualidade (1–5)', tipo: TipoCampo.numero),
          _c(af, 'Pontualidade (1–5)', tipo: TipoCampo.numero),
          _c(af, 'Observações', obrigatorio: false),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid(tp),
        titulo: 'Controle de Temperatura',
        descricao: 'Registro de temperatura de equipamentos e produtos',
        template: true,
        campos: [
          _c(tp, 'Equipamento / Local'),
          _c(tp, 'Temperatura (°C)', tipo: TipoCampo.numero),
          _c(tp, 'Horário'),
          _c(tp, 'Responsável'),
          _c(tp, 'Dentro da faixa ideal?', tipo: TipoCampo.simNao),
          _c(tp, 'Ação corretiva', obrigatorio: false),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid(vs),
        titulo: 'Vistoria de Segurança',
        descricao: 'Checklist de segurança do estabelecimento',
        template: true,
        campos: [
          _c(vs, 'Câmeras funcionando', tipo: TipoCampo.simNao),
          _c(vs, 'Extintores verificados', tipo: TipoCampo.simNao),
          _c(vs, 'Saídas de emergência livres', tipo: TipoCampo.simNao),
          _c(vs, 'Iluminação de emergência', tipo: TipoCampo.simNao),
          _c(vs, 'Equipamentos de segurança ok', tipo: TipoCampo.simNao),
          _c(vs, 'Observações', obrigatorio: false),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid(ac),
        titulo: 'Avaliação de Colaborador',
        descricao: 'Avaliação de desempenho de colaboradores',
        template: true,
        campos: [
          _c(ac, 'Nome do colaborador'),
          _c(ac, 'Departamento'),
          _c(ac, 'Pontualidade (1–5)', tipo: TipoCampo.numero),
          _c(ac, 'Produtividade (1–5)', tipo: TipoCampo.numero),
          _c(ac, 'Atendimento ao cliente (1–5)', tipo: TipoCampo.numero),
          _c(ac, 'Observações e feedbacks', obrigatorio: false),
        ],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}

// ── Helper de criação de resposta ─────────────────────────────────────────────
extension RespostaFormularioEx on RespostaFormulario {
  static RespostaFormulario create({
    required String formularioId,
    required Map<String, dynamic> valores,
  }) =>
      RespostaFormulario(
        id: const Uuid().v4(),
        formularioId: formularioId,
        valores: valores,
        preenchidoEm: DateTime.now(),
      );
}
