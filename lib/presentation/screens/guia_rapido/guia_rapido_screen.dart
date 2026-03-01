import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';

// ── Modelo de situação ────────────────────────────────────────────────────────

class _Situacao {
  final String titulo;
  final String categoria;
  final Color cor;
  final IconData icone;
  final List<String> passos;

  const _Situacao({
    required this.titulo,
    required this.categoria,
    required this.cor,
    required this.icone,
    required this.passos,
  });
}

// ── Conteúdo do guia ──────────────────────────────────────────────────────────

const _situacoes = [
  // CAIXA / OPERACIONAL
  _Situacao(
    titulo: 'Caixa ficou sem troco',
    categoria: 'Caixa',
    cor: Color(0xFFFF9800),
    icone: Icons.point_of_sale,
    passos: [
      'Peça ao operador para dar pausa no caixa',
      'Vá ao cofre ou caixa principal solicitar troco',
      'Assine o livro de controle de troco',
      'Retorne o troco ao operador com o comprovante',
      'Libere o caixa para voltar ao atendimento',
    ],
  ),
  _Situacao(
    titulo: 'Divergência no fechamento de caixa',
    categoria: 'Caixa',
    cor: Color(0xFFFF9800),
    icone: Icons.point_of_sale,
    passos: [
      'Solicite ao operador para não fechar o sistema ainda',
      'Verifique o extrato de movimentações do período',
      'Confira o valor físico em dinheiro na gaveta',
      'Verifique comprovantes de cartão e voucher',
      'Se a diferença for pequena (< R\$5), registre e assine',
      'Se a diferença for grande, chame o gerente imediatamente',
      'Registre tudo em ocorrência antes de fechar o caixa',
    ],
  ),
  _Situacao(
    titulo: 'Operador de caixa não compareceu',
    categoria: 'Caixa',
    cor: Color(0xFFFF9800),
    icone: Icons.point_of_sale,
    passos: [
      'Tente contato por telefone com o colaborador',
      'Verifique se há alguém na escala que pode cobrir',
      'Informe o gerente sobre a ausência imediatamente',
      'Registre a ocorrência de ausência no app',
      'Reorganize os caixas disponíveis conforme a demanda',
    ],
  ),

  // CLIENTES
  _Situacao(
    titulo: 'Cliente reclama do preço marcado',
    categoria: 'Clientes',
    cor: Color(0xFF9C27B0),
    icone: Icons.person,
    passos: [
      'Ouça o cliente com atenção e calma',
      'Peça para verificar o preço no setor ou sistema',
      'Se o preço estiver errado: cobre o menor preço (lei do consumidor)',
      'Corrija a etiqueta imediatamente',
      'Agradeça o cliente pela informação',
      'Registre ocorrência se necessário',
    ],
  ),
  _Situacao(
    titulo: 'Cliente quer cancelar a compra',
    categoria: 'Clientes',
    cor: Color(0xFF9C27B0),
    icone: Icons.person,
    passos: [
      'Verifique se o cupom fiscal já foi emitido',
      'Se NÃO emitido: solicite ao operador para cancelar no sistema',
      'Se JÁ emitido: chame o gerente para autorizar o cancelamento',
      'Devolva o dinheiro ou cancele o cartão conforme o caso',
      'Recolha os produtos do cliente',
      'Registre o cancelamento no livro ou sistema',
    ],
  ),
  _Situacao(
    titulo: 'Cliente quer trocar produto',
    categoria: 'Clientes',
    cor: Color(0xFF9C27B0),
    icone: Icons.person,
    passos: [
      'Verifique se tem cupom fiscal ou nota de compra',
      'Confira se o produto está dentro do prazo de troca',
      'Verifique se o produto está em boas condições',
      'Dirija o cliente ao setor de trocas ou SAC',
      'Se não houver setor, chame o gerente para autorização',
    ],
  ),
  _Situacao(
    titulo: 'Fila grande no caixa',
    categoria: 'Clientes',
    cor: Color(0xFF9C27B0),
    icone: Icons.person,
    passos: [
      'Avalie quantos caixas estão disponíveis',
      'Abra caixas adicionais se houver operadores disponíveis',
      'Oriente clientes com poucos itens para caixas rápidos',
      'Comunique o gerente se não for possível reduzir a fila',
      'Seja cordial ao orientar os clientes',
    ],
  ),

  // EQUIPAMENTOS
  _Situacao(
    titulo: 'Máquina de cartão com problema',
    categoria: 'Equipamentos',
    cor: Color(0xFF2196F3),
    icone: Icons.credit_card,
    passos: [
      'Oriente o operador a reiniciar a maquininha',
      'Tente com outra máquina do caixa (se houver)',
      'Acione o suporte técnico da operadora (número no verso)',
      'Enquanto aguarda: aceite apenas dinheiro neste caixa',
      'Coloque placa informando "Cartão temporariamente indisponível"',
      'Registre o problema como ocorrência',
    ],
  ),
  _Situacao(
    titulo: 'Impressora de cupom não funciona',
    categoria: 'Equipamentos',
    cor: Color(0xFF2196F3),
    icone: Icons.print,
    passos: [
      'Verifique se tem papel na impressora',
      'Verifique se o cabo USB/serial está conectado',
      'Reinicie a impressora (desligar e ligar)',
      'Se não resolver, transfira os clientes para outro caixa',
      'Acione o suporte de TI ou técnico',
      'Não opere sem impressora — cupom fiscal é obrigatório',
    ],
  ),
  _Situacao(
    titulo: 'Sistema lento ou travado',
    categoria: 'Equipamentos',
    cor: Color(0xFF2196F3),
    icone: Icons.computer,
    passos: [
      'Peça ao operador para aguardar antes de reiniciar',
      'Verifique se outros caixas estão com o mesmo problema',
      'Se só um caixa: reinicie o terminal (com autorização)',
      'Se todos: acione o suporte de TI imediatamente',
      'Abra caixas manuais de contingência se necessário',
      'Informe o gerente sobre a situação',
    ],
  ),

  // EMERGÊNCIAS
  _Situacao(
    titulo: 'Suspeita de furto em andamento',
    categoria: 'Emergências',
    cor: Color(0xFFF44336),
    icone: Icons.security,
    passos: [
      'NÃO aborde o suspeito diretamente — é perigoso',
      'Acione discretamente o segurança da loja',
      'Informe ao gerente sem alarmar os clientes',
      'Se tiver câmera, ative gravação/alert',
      'Aguarde a ação do segurança ou gerente',
      'Registre tudo em ocorrência com horário e descrição',
    ],
  ),
  _Situacao(
    titulo: 'Briga ou conflito entre clientes',
    categoria: 'Emergências',
    cor: Color(0xFFF44336),
    icone: Icons.warning_amber,
    passos: [
      'Mantenha a calma e não entre no conflito fisicamente',
      'Acione o segurança da loja imediatamente',
      'Peça aos funcionários para afastar outros clientes da área',
      'Chame o gerente',
      'Se necessário, ligue para 190 (Polícia)',
      'Registre a ocorrência com detalhes',
    ],
  ),
  _Situacao(
    titulo: 'Acidente com cliente na loja',
    categoria: 'Emergências',
    cor: Color(0xFFF44336),
    icone: Icons.local_hospital,
    passos: [
      'Acuda imediatamente e pergunte se está bem',
      'NÃO mova o cliente se houver suspeita de fratura',
      'Chame o gerente e acione o SAMU (192) se necessário',
      'Isole a área para evitar novos acidentes',
      'Registre o acidente com horário, local e testemunhas',
      'Guarde as câmeras para registro',
      'Preencha o Boletim de Ocorrência Interno',
    ],
  ),

  // DINHEIRO
  _Situacao(
    titulo: 'Cédula suspeita de falsificação',
    categoria: 'Dinheiro',
    cor: Color(0xFF4CAF50),
    icone: Icons.attach_money,
    passos: [
      'NÃO devolva a cédula imediatamente',
      'Use o detector de notas falsas se disponível',
      'Verifique os elementos de segurança da nota',
      'Se confirmada como falsa: retenha a nota',
      'Informe o cliente com educação que a nota é suspeita',
      'Chame o gerente para seguir o procedimento legal',
      'Registre o número de série e boletim de ocorrência',
    ],
  ),
  _Situacao(
    titulo: 'Malote ou troco errado',
    categoria: 'Dinheiro',
    cor: Color(0xFF4CAF50),
    icone: Icons.attach_money,
    passos: [
      'Confira o valor logo ao receber o malote',
      'Se estiver errado, anote a diferença antes de assinar',
      'Informe o responsável pelo envio do malote',
      'Não assine nada antes de resolver a divergência',
      'Registre a divergência no livro e como ocorrência',
    ],
  ),

  // PRODUTO
  _Situacao(
    titulo: 'Produto sem código de barras',
    categoria: 'Produto',
    cor: Color(0xFF607D8B),
    icone: Icons.qr_code,
    passos: [
      'Oriente o operador a pausar o atendimento',
      'Acione o setor ou repositor para informar o código',
      'Se não for possível, leve o produto até o setor',
      'Nunca informe um preço "de cabeça" sem verificar',
      'Após identificar: prossiga com o atendimento',
    ],
  ),
];

// ── Tela ──────────────────────────────────────────────────────────────────────

class GuiaRapidoScreen extends StatefulWidget {
  const GuiaRapidoScreen({super.key});

  @override
  State<GuiaRapidoScreen> createState() => _GuiaRapidoScreenState();
}

class _GuiaRapidoScreenState extends State<GuiaRapidoScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _categoriaFiltro;

  static final _categorias = _situacoes.map((s) => s.categoria).toSet().toList()
    ..sort();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Situacao> get _filtradas {
    var lista = _situacoes;
    if (_categoriaFiltro != null) {
      lista = lista.where((s) => s.categoria == _categoriaFiltro).toList();
    }
    if (_query.isNotEmpty) {
      lista = lista
          .where((s) =>
              s.titulo.toLowerCase().contains(_query) ||
              s.categoria.toLowerCase().contains(_query) ||
              s.passos.any((p) => p.toLowerCase().contains(_query)))
          .toList();
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _filtradas;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Guia Rápido'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                '${filtradas.length} situações',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Busca ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingMD, 8, Dimensions.paddingMD, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'O que está acontecendo?',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusMD),
                ),
              ),
              onChanged: (v) =>
                  setState(() => _query = v.toLowerCase().trim()),
            ),
          ),

          // ── Chips de categoria ─────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingMD, vertical: 4),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Todas'),
                    selected: _categoriaFiltro == null,
                    onSelected: (_) =>
                        setState(() => _categoriaFiltro = null),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _categoriaFiltro == null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: _categoriaFiltro == null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                ..._categorias.map((cat) {
                  final isSelected = _categoriaFiltro == cat;
                  // Pega a cor da primeira situação dessa categoria
                  final cor = _situacoes
                      .firstWhere((s) => s.categoria == cat)
                      .cor;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => setState(() =>
                          _categoriaFiltro = isSelected ? null : cat),
                      selectedColor: cor.withValues(alpha: 0.15),
                      checkmarkColor: cor,
                      labelStyle: TextStyle(
                        color: isSelected ? cor : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // ── Lista ──────────────────────────────────────────────────────
          Expanded(
            child: filtradas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 64, color: AppColors.inactive),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma situação encontrada',
                          style: AppTextStyles.h4
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(Dimensions.paddingMD),
                    itemCount: filtradas.length,
                    itemBuilder: (ctx, i) {
                      final s = filtradas[i];
                      return Card(
                        margin: const EdgeInsets.only(
                            bottom: Dimensions.spacingSM),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                s.cor.withValues(alpha: 0.15),
                            child: Icon(s.icone, color: s.cor, size: 20),
                          ),
                          title: Text(s.titulo, style: AppTextStyles.h4),
                          subtitle: Text(
                            s.categoria,
                            style: TextStyle(
                              color: s.cor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                              Dimensions.paddingMD,
                              0,
                              Dimensions.paddingMD,
                              Dimensions.paddingMD),
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: Dimensions.spacingMD),
                            ...s.passos.asMap().entries.map((e) => Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: Dimensions.spacingSM),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: s.cor
                                              .withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${e.key + 1}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: s.cor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          e.value,
                                          style: AppTextStyles.body,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
