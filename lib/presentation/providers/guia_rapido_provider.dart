import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
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
  final String corHex;   // ex: 'FF9800'
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
        passos: (m['passos'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        isDefault: m['is_default'] as bool? ?? false,
      );
}

// ── Defaults (situações pré-definidas) ────────────────────────────────────────

List<SituacaoGuia> _buildDefaults() {
  SituacaoGuia s(
    String titulo,
    String categoria,
    String corHex,
    String iconeKey,
    List<String> passos,
  ) =>
      SituacaoGuia(
        id: const Uuid().v5(
            '6ba7b810-9dad-11d1-80b4-00c04fd430c8', '$categoria:$titulo'),
        titulo: titulo,
        categoria: categoria,
        corHex: corHex,
        iconeKey: iconeKey,
        passos: passos,
        isDefault: true,
      );

  return [
    s('Caixa ficou sem troco', 'Caixa', 'FF9800', 'caixa', [
      'Peça ao operador para dar pausa no caixa',
      'Vá ao cofre ou caixa principal solicitar troco',
      'Assine o livro de controle de troco',
      'Retorne o troco ao operador com o comprovante',
      'Libere o caixa para voltar ao atendimento',
    ]),
    s('Divergência no fechamento de caixa', 'Caixa', 'FF9800', 'caixa', [
      'Solicite ao operador para não fechar o sistema ainda',
      'Verifique o extrato de movimentações do período',
      'Confira o valor físico em dinheiro na gaveta',
      'Verifique comprovantes de cartão e voucher',
      'Se a diferença for pequena (< R\$5), registre e assine',
      'Se a diferença for grande, chame o gerente imediatamente',
      'Registre tudo em ocorrência antes de fechar o caixa',
    ]),
    s('Operador de caixa não compareceu', 'Caixa', 'FF9800', 'caixa', [
      'Tente contato por telefone com o colaborador',
      'Verifique se há alguém na escala que pode cobrir',
      'Informe o gerente sobre a ausência imediatamente',
      'Registre a ocorrência de ausência no app',
      'Reorganize os caixas disponíveis conforme a demanda',
    ]),
    s('Cliente reclama do preço marcado', 'Clientes', '9C27B0', 'pessoa', [
      'Ouça o cliente com atenção e calma',
      'Peça para verificar o preço no setor ou sistema',
      'Se o preço estiver errado: cobre o menor preço (lei do consumidor)',
      'Corrija a etiqueta imediatamente',
      'Agradeça o cliente pela informação',
      'Registre ocorrência se necessário',
    ]),
    s('Cliente quer cancelar a compra', 'Clientes', '9C27B0', 'pessoa', [
      'Verifique se o cupom fiscal já foi emitido',
      'Se NÃO emitido: solicite ao operador para cancelar no sistema',
      'Se JÁ emitido: chame o gerente para autorizar o cancelamento',
      'Devolva o dinheiro ou cancele o cartão conforme o caso',
      'Recolha os produtos do cliente',
      'Registre o cancelamento no livro ou sistema',
    ]),
    s('Cliente quer trocar produto', 'Clientes', '9C27B0', 'pessoa', [
      'Verifique se tem cupom fiscal ou nota de compra',
      'Confira se o produto está dentro do prazo de troca',
      'Verifique se o produto está em boas condições',
      'Dirija o cliente ao setor de trocas ou SAC',
      'Se não houver setor, chame o gerente para autorização',
    ]),
    s('Fila grande no caixa', 'Clientes', '9C27B0', 'pessoa', [
      'Avalie quantos caixas estão disponíveis',
      'Abra caixas adicionais se houver operadores disponíveis',
      'Oriente clientes com poucos itens para caixas rápidos',
      'Comunique o gerente se não for possível reduzir a fila',
      'Seja cordial ao orientar os clientes',
    ]),
    s('Máquina de cartão com problema', 'Equipamentos', '2196F3', 'cartao', [
      'Oriente o operador a reiniciar a maquininha',
      'Tente com outra máquina do caixa (se houver)',
      'Acione o suporte técnico da operadora (número no verso)',
      'Enquanto aguarda: aceite apenas dinheiro neste caixa',
      'Coloque placa informando "Cartão temporariamente indisponível"',
      'Registre o problema como ocorrência',
    ]),
    s('Impressora de cupom não funciona', 'Equipamentos', '2196F3', 'impressora', [
      'Verifique se tem papel na impressora',
      'Verifique se o cabo USB/serial está conectado',
      'Reinicie a impressora (desligar e ligar)',
      'Se não resolver, transfira os clientes para outro caixa',
      'Acione o suporte de TI ou técnico',
      'Não opere sem impressora — cupom fiscal é obrigatório',
    ]),
    s('Sistema lento ou travado', 'Equipamentos', '2196F3', 'computador', [
      'Peça ao operador para aguardar antes de reiniciar',
      'Verifique se outros caixas estão com o mesmo problema',
      'Se só um caixa: reinicie o terminal (com autorização)',
      'Se todos: acione o suporte de TI imediatamente',
      'Abra caixas manuais de contingência se necessário',
      'Informe o gerente sobre a situação',
    ]),
    s('Suspeita de furto em andamento', 'Emergências', 'F44336', 'seguranca', [
      'NÃO aborde o suspeito diretamente — é perigoso',
      'Acione discretamente o segurança da loja',
      'Informe ao gerente sem alarmar os clientes',
      'Se tiver câmera, ative gravação/alert',
      'Aguarde a ação do segurança ou gerente',
      'Registre tudo em ocorrência com horário e descrição',
    ]),
    s('Briga ou conflito entre clientes', 'Emergências', 'F44336', 'alerta', [
      'Mantenha a calma e não entre no conflito fisicamente',
      'Acione o segurança da loja imediatamente',
      'Peça aos funcionários para afastar outros clientes da área',
      'Chame o gerente',
      'Se necessário, ligue para 190 (Polícia)',
      'Registre a ocorrência com detalhes',
    ]),
    s('Acidente com cliente na loja', 'Emergências', 'F44336', 'hospital', [
      'Acuda imediatamente e pergunte se está bem',
      'NÃO mova o cliente se houver suspeita de fratura',
      'Chame o gerente e acione o SAMU (192) se necessário',
      'Isole a área para evitar novos acidentes',
      'Registre o acidente com horário, local e testemunhas',
      'Guarde as câmeras para registro',
      'Preencha o Boletim de Ocorrência Interno',
    ]),
    s('Cédula suspeita de falsificação', 'Dinheiro', '4CAF50', 'dinheiro', [
      'NÃO devolva a cédula imediatamente',
      'Use o detector de notas falsas se disponível',
      'Verifique os elementos de segurança da nota',
      'Se confirmada como falsa: retenha a nota',
      'Informe o cliente com educação que a nota é suspeita',
      'Chame o gerente para seguir o procedimento legal',
      'Registre o número de série e boletim de ocorrência',
    ]),
    s('Malote ou troco errado', 'Dinheiro', '4CAF50', 'dinheiro', [
      'Confira o valor logo ao receber o malote',
      'Se estiver errado, anote a diferença antes de assinar',
      'Informe o responsável pelo envio do malote',
      'Não assine nada antes de resolver a divergência',
      'Registre a divergência no livro e como ocorrência',
    ]),
    s('Produto sem código de barras', 'Produto', '607D8B', 'produto', [
      'Oriente o operador a pausar o atendimento',
      'Acione o setor ou repositor para informar o código',
      'Se não for possível, leve o produto até o setor',
      'Nunca informe um preço "de cabeça" sem verificar',
      'Após identificar: prossiga com o atendimento',
    ]),
  ];
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

      if (rows.isEmpty) {
        await _seedDefaults();
      } else {
        _situacoes.addAll(rows.map(SituacaoGuia.fromMap));
      }
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

  Future<void> _seedDefaults() async {
    final defaults = _buildDefaults();
    try {
      await SupabaseClientManager.client
          .from(_table)
          .insert(defaults.map((d) => d.toMap(_fiscalId)).toList());
      _situacoes.addAll(defaults);
    } catch (e) {
      if (kDebugMode) debugPrint('[GuiaRapidoProvider] Erro ao seed: $e');
      rethrow;
    }
  }
}
