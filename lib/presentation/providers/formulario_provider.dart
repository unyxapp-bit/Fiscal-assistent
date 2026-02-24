import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/formulario.dart';
import '../../data/datasources/remote/supabase_client.dart';

class FormularioProvider with ChangeNotifier {
  static const _tableF = 'formularios';
  static const _tableR = 'respostas_formulario';

  final List<Formulario> _formularios = [];
  final List<RespostaFormulario> _respostas = [];

  List<Formulario> get formularios => _formularios;
  List<Formulario> get templates =>
      _formularios.where((f) => f.template).toList();
  List<Formulario> get personalizados =>
      _formularios.where((f) => !f.template && f.ativo).toList();

  List<RespostaFormulario> get respostas => _respostas;

  int get totalFormularios => _formularios.length;
  int get totalRespostas => _respostas.length;

  String get _fiscalId => SupabaseClientManager.currentUserId!;

  List<RespostaFormulario> respostasPorFormulario(String formularioId) {
    return _respostas
        .where((r) => r.formularioId == formularioId)
        .toList()
      ..sort((a, b) => b.preenchidoEm.compareTo(a.preenchidoEm));
  }

  int totalRespostasPorFormulario(String formularioId) {
    return respostasPorFormulario(formularioId).length;
  }

  /// Carrega formularios e respostas do Supabase. Faz seed dos templates na 1ª vez.
  Future<void> load() async {
    try {
      final rows = await SupabaseClientManager.client
          .from(_tableF)
          .select()
          .eq('fiscal_id', _fiscalId)
          .order('created_at');

      _formularios.clear();

      if (rows.isEmpty) {
        // Primeiro acesso: seed templates
        await _seedTemplates();
      } else {
        _formularios.addAll(rows.map(_fromMapF));
      }

      // Carregar respostas
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

  // CRUD Formulários
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

  // CRUD Respostas
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
      if (kDebugMode) debugPrint('[FormularioProvider] Erro ao salvar resposta: $e');
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
      if (kDebugMode) debugPrint('[FormularioProvider] Erro ao deletar resposta: $e');
    });
  }

  void _upsertF(Formulario f) {
    SupabaseClientManager.client.from(_tableF).upsert({
      'id': f.id,
      'fiscal_id': _fiscalId,
      'titulo': f.titulo,
      'descricao': f.descricao,
      'template': f.template,
      'ativo': f.ativo,
      'campos': f.campos,
      'updated_at': DateTime.now().toIso8601String(),
    }).then((_) {}).catchError((e) {
      if (kDebugMode) debugPrint('[FormularioProvider] Erro ao sincronizar: $e');
    });
  }

  Future<void> _seedTemplates() async {
    final templates = _buildTemplates();
    try {
      final data = templates
          .map((f) => {
                'id': f.id,
                'fiscal_id': _fiscalId,
                'seed_key': f.id, // use local id as seed_key
                'titulo': f.titulo,
                'descricao': f.descricao,
                'template': true,
                'ativo': true,
                'campos': f.campos,
                'created_at': f.createdAt.toIso8601String(),
                'updated_at': f.updatedAt.toIso8601String(),
              })
          .toList();

      await SupabaseClientManager.client.from(_tableF).insert(data);
      _formularios.addAll(templates);
    } catch (e) {
      if (kDebugMode) debugPrint('[FormularioProvider] Erro ao seed: $e');
      // Fallback: use local templates only
      _formularios.addAll(templates);
    }
  }

  Formulario _fromMapF(Map<String, dynamic> m) {
    // Suporta dois formatos de campos:
    //   - Antigo: ["string", "string", ...]
    //   - Novo:   [{"id": "...", "type": "...", "label": "..."}, ...]
    final rawCampos = m['campos'] as List? ?? [];
    final campos = rawCampos.map<String>((c) {
      if (c is String) return c;
      if (c is Map) return (c['label'] ?? c['id'] ?? c.toString()).toString();
      return c.toString();
    }).toList();

    return Formulario(
      id: m['id'] as String,
      titulo: m['titulo'] as String,
      descricao: m['descricao'] as String? ?? '',
      template: m['template'] as bool? ?? false,
      ativo: m['ativo'] as bool? ?? true,
      campos: campos,
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

  /// Gera UUID v5 determinístico a partir de uma chave de template.
  /// Garante que o mesmo template sempre receba o mesmo UUID.
  static String _tmplUuid(String key) =>
      const Uuid().v5(Uuid.NAMESPACE_URL, key);

  List<Formulario> _buildTemplates() {
    final now = DateTime.now();
    return [
      Formulario(
        id: _tmplUuid('tmpl_abertura'),
        titulo: 'Checklist de Abertura',
        descricao: 'Verificações necessárias para abertura da loja',
        template: true,
        campos: [
          'Luzes ligadas', 'Sistemas operacionais', 'Caixas abertos',
          'Estoque verificado', 'Limpeza conferida', 'Colaboradores presentes',
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid('tmpl_fechamento'),
        titulo: 'Checklist de Fechamento',
        descricao: 'Procedimentos para fechamento correto da loja',
        template: true,
        campos: [
          'Caixas fechados', 'Fechamento de caixa conferido', 'Sistemas desligados',
          'Luzes apagadas', 'Alarme ativado', 'Portas trancadas',
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid('tmpl_ocorrencia'),
        titulo: 'Registro de Ocorrência',
        descricao: 'Documento para registrar incidentes e ocorrências',
        template: true,
        campos: [
          'Data e hora', 'Tipo de ocorrência', 'Descrição detalhada',
          'Pessoas envolvidas', 'Ação tomada', 'Responsável',
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid('tmpl_reclamacao'),
        titulo: 'Reclamação de Cliente',
        descricao: 'Registrar reclamações e feedback negativo de clientes',
        template: true,
        campos: [
          'Nome do cliente', 'Telefone de contato', 'Produto/Serviço',
          'Motivo da reclamação', 'Solução proposta', 'Status de resolução',
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid('tmpl_produto_falta'),
        titulo: 'Solicitação de Produto em Falta',
        descricao: 'Registrar produtos esgotados para reposição',
        template: true,
        campos: [
          'Nome do produto', 'Código/SKU', 'Seção/Departamento',
          'Quantidade estimada necessária', 'Urgência', 'Observações',
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid('tmpl_troca_devolucao'),
        titulo: 'Troca / Devolução',
        descricao: 'Controle de trocas e devoluções de produtos',
        template: true,
        campos: [
          'Nome do cliente', 'Número do cupom/NF', 'Produto devolvido',
          'Motivo da troca', 'Produto escolhido (troca)', 'Valor do estorno (devolução)',
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid('tmpl_avaliacao_fornecedor'),
        titulo: 'Avaliação de Fornecedor',
        descricao: 'Avaliar a qualidade e pontualidade de fornecedores',
        template: true,
        campos: [
          'Nome do fornecedor', 'Data da entrega', 'Produto(s) entregue(s)',
          'Qualidade (1-5)', 'Pontualidade (1-5)', 'Observações',
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid('tmpl_temperatura'),
        titulo: 'Controle de Temperatura',
        descricao: 'Registro de temperatura de equipamentos e produtos',
        template: true,
        campos: [
          'Equipamento/Local', 'Temperatura registrada (°C)', 'Horário',
          'Responsável', 'Dentro da faixa ideal?', 'Ação corretiva (se aplicável)',
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid('tmpl_vistoria_seguranca'),
        titulo: 'Vistoria de Segurança',
        descricao: 'Checklist de segurança do estabelecimento',
        template: true,
        campos: [
          'Câmeras funcionando', 'Extintores verificados', 'Saídas de emergência livres',
          'Iluminação de emergência', 'Equipamentos de segurança', 'Observações',
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Formulario(
        id: _tmplUuid('tmpl_avaliacao_colaborador'),
        titulo: 'Avaliação de Colaborador',
        descricao: 'Avaliação de desempenho de colaboradores',
        template: true,
        campos: [
          'Nome do colaborador', 'Departamento', 'Pontualidade (1-5)',
          'Produtividade (1-5)', 'Atendimento ao cliente (1-5)', 'Observações e feedbacks',
        ],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}

// Make RespostaFormulario.id generable
extension RespostaFormularioEx on RespostaFormulario {
  static RespostaFormulario create({
    required String formularioId,
    required Map<String, dynamic> valores,
  }) {
    return RespostaFormulario(
      id: const Uuid().v4(),
      formularioId: formularioId,
      valores: valores,
      preenchidoEm: DateTime.now(),
    );
  }
}
