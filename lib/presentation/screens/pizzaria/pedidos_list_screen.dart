// lib/modules/pizza/pedidos_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/theme/app_theme.dart';
import 'cupom_widget.dart';
import 'novo_pedido_screen.dart';
import 'pizza_models.dart';

class PedidosListScreen extends StatefulWidget {
  const PedidosListScreen({super.key});

  @override
  State<PedidosListScreen> createState() => _PedidosListScreenState();
}

class _PedidosListScreenState extends State<PedidosListScreen> {
  List<PedidoPizza> _pedidos = [];
  final _buscaCtrl = TextEditingController();
  bool _loading = true;
  String _filtro = 'todos'; // 'todos' | 'aberto' | 'pronto' | 'entregue'
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final lista = await PizzaService.listarPedidos();
      if (!mounted) return;
      setState(() {
        _pedidos = lista;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar pedidos: $e')),
      );
    }
  }

  List<PedidoPizza> get _pedidosFiltrados {
    final porStatus = _filtro == 'todos'
        ? _pedidos
        : _pedidos.where((p) => p.status == _filtro).toList();
    final termo = _busca.trim().toLowerCase();
    if (termo.isEmpty) return porStatus;

    return porStatus.where((pedido) {
      final campos = <String>[
        pedido.nomeCliente ?? '',
        pedido.codigoEntrega ?? '',
        pedido.endereco ?? '',
        pedido.bairro ?? '',
        pedido.telefone ?? '',
        pedido.referencia ?? '',
        pedido.observacoes ?? '',
        ...pedido.itens.expand(
          (item) => [
            item.descricao,
            item.pizzaNome,
            item.pizza2Nome ?? '',
            item.tamanhoLabel,
          ],
        ),
      ];
      return campos.any((campo) => campo.toLowerCase().contains(termo));
    }).toList();
  }

  int _contarStatus(String status) =>
      _pedidos.where((p) => p.status == status).length;

  Future<void> _mudarStatus(PedidoPizza pedido, String novoStatus) async {
    await PizzaService.atualizarStatus(pedido.id!, novoStatus);
    _carregar();
  }

  void _verCupom(PedidoPizza pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CupomWidget(
        pedido: pedido,
        onFechar: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _editarPedido(PedidoPizza pedido) async {
    final atualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NovoPedidoScreen(pedidoExistente: pedido),
      ),
    );
    if (atualizado == true) {
      _carregar();
    }
  }

  Future<void> _excluirPedido(PedidoPizza pedido) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir pedido?'),
        content: Text(
          'Deseja excluir o pedido de ${_textoPedido(pedido.nomeCliente, vazio: 'cliente sem nome')} '
          '(cod. cliente: ${_textoPedido(pedido.codigoEntrega)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Excluir', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await PizzaService.excluirPedido(pedido.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pedido excluido com sucesso.')),
    );
    _carregar();
  }

  void _abrirDetalhes(PedidoPizza pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _DetalhesPedidoSheet(
        pedido: pedido,
        onVerCupom: () {
          Navigator.pop(sheetContext);
          _verCupom(pedido);
        },
        onEditar: () {
          Navigator.pop(sheetContext);
          _editarPedido(pedido);
        },
        onExcluir: () {
          Navigator.pop(sheetContext);
          _excluirPedido(pedido);
        },
        onSelecionarStatus: (novoStatus) async {
          Navigator.pop(sheetContext);
          await _mudarStatus(pedido, novoStatus);
        },
      ),
    );
  }

  Future<void> _abrirNovoPedido() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NovoPedidoScreen()),
    );
    if (!mounted) return;
    _carregar();
  }

  Widget _buildListaPedidos(List<PedidoPizza> pedidos) {
    if (pedidos.isEmpty) {
      return Center(
        child: Text(
          _busca.trim().isEmpty
              ? 'Nenhum pedido encontrado.'
              : 'Nenhum pedido combina com a busca.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _carregar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: pedidos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 2),
        itemBuilder: (_, i) => _buildCardPedido(pedidos[i]),
      ),
    );
  }

  Widget _buildCardPedido(PedidoPizza pedido) {
    return _CardPedido(
      pedido: pedido,
      onAbrirDetalhes: () => _abrirDetalhes(pedido),
      onVerCupom: () => _verCupom(pedido),
      onEditar: () => _editarPedido(pedido),
      onExcluir: () => _excluirPedido(pedido),
      onMudarStatus: (s) => _mudarStatus(pedido, s),
    );
  }

  Widget _buildCorpoPedidos() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final pedidos = _pedidosFiltrados;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return _buildListaPedidos(pedidos);
        }

        return _PedidosBoard(
          pedidos: pedidos,
          filtro: _filtro,
          buscaAtiva: _busca.trim().isNotEmpty,
          buildCard: _buildCardPedido,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final abertos = _contarStatus('aberto');
    final prontos = _contarStatus('pronto');
    final entregues = _contarStatus('entregue');

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        backgroundColor: tokens.cardBackground,
        title: Text('Pedidos de Pizza',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _carregar,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNovoPedido,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnColor,
        icon: const Icon(Icons.add),
        label: const Text('Novo Pedido'),
      ),
      body: Column(
        children: [
          Container(
            color: tokens.cardBackground,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      label: 'Abertos',
                      count: abertos,
                      color: AppColors.info,
                    ),
                    _StatusChip(
                      label: 'Prontos',
                      count: prontos,
                      color: AppColors.warning,
                    ),
                    _StatusChip(
                      label: 'Entregues',
                      count: entregues,
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _buscaCtrl,
                  decoration: InputDecoration(
                    hintText:
                        'Buscar por cliente, c\u00f3digo, telefone ou sabor',
                    prefixIcon:
                        Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: _busca.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(Icons.close,
                                color: AppColors.textSecondary),
                            onPressed: () {
                              _buscaCtrl.clear();
                              setState(() => _busca = '');
                            },
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _busca = value),
                ),
              ],
            ),
          ),
          // Chips de filtro com contagem
          Container(
            color: tokens.cardBackground,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final filtros = [
                      _ChipFiltro(
                        label: 'Todos',
                        count: _pedidos.length,
                        valor: 'todos',
                        atual: _filtro,
                        onTap: (v) => setState(() => _filtro = v),
                      ),
                      _ChipFiltro(
                        label: 'Abertos',
                        count: abertos,
                        valor: 'aberto',
                        atual: _filtro,
                        onTap: (v) => setState(() => _filtro = v),
                        cor: AppColors.info,
                      ),
                      _ChipFiltro(
                        label: 'Prontos',
                        count: prontos,
                        valor: 'pronto',
                        atual: _filtro,
                        onTap: (v) => setState(() => _filtro = v),
                        cor: AppColors.warning,
                      ),
                      _ChipFiltro(
                        label: 'Entregues',
                        count: entregues,
                        valor: 'entregue',
                        atual: _filtro,
                        onTap: (v) => setState(() => _filtro = v),
                        cor: AppColors.success,
                      ),
                    ];

                    if (constraints.maxWidth < 430) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                        child: Wrap(
                          spacing: 0,
                          runSpacing: 0,
                          children: filtros,
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Row(children: filtros),
                    );
                  },
                ),
                Divider(height: 1, thickness: 1, color: AppColors.divider),
              ],
            ),
          ),
          Expanded(
            child: _buildCorpoPedidos(),
          ),
        ],
      ),
    );
  }
}

// ── Chip de resumo de status ──────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card de pedido ────────────────────────────────────────────

class _PedidosBoard extends StatelessWidget {
  final List<PedidoPizza> pedidos;
  final String filtro;
  final bool buscaAtiva;
  final Widget Function(PedidoPizza pedido) buildCard;

  const _PedidosBoard({
    required this.pedidos,
    required this.filtro,
    required this.buscaAtiva,
    required this.buildCard,
  });

  @override
  Widget build(BuildContext context) {
    final statuses =
        filtro == 'todos' ? ['aberto', 'pronto', 'entregue'] : [filtro];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < statuses.length; i++) ...[
            Expanded(
              child: _PedidosStatusColumn(
                status: statuses[i],
                pedidos: pedidos.where((p) => p.status == statuses[i]).toList(),
                buscaAtiva: buscaAtiva,
                buildCard: buildCard,
              ),
            ),
            if (i < statuses.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _PedidosStatusColumn extends StatelessWidget {
  final String status;
  final List<PedidoPizza> pedidos;
  final bool buscaAtiva;
  final Widget Function(PedidoPizza pedido) buildCard;

  const _PedidosStatusColumn({
    required this.status,
    required this.pedidos,
    required this.buscaAtiva,
    required this.buildCard,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final color = _statusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(color: color.withValues(alpha: 0.18)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusLabel(status),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${pedidos.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: pedidos.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        buscaAtiva
                            ? 'Nada encontrado aqui.'
                            : 'Nenhum pedido ${_statusLabel(status).toLowerCase()}.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: pedidos.length,
                    itemBuilder: (context, index) => buildCard(pedidos[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CardPedido extends StatelessWidget {
  final PedidoPizza pedido;
  final VoidCallback onAbrirDetalhes;
  final VoidCallback onVerCupom;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final void Function(String) onMudarStatus;

  const _CardPedido({
    required this.pedido,
    required this.onAbrirDetalhes,
    required this.onVerCupom,
    required this.onEditar,
    required this.onExcluir,
    required this.onMudarStatus,
  });

  String get _proximoStatus {
    switch (pedido.status) {
      case 'aberto':
        return 'pronto';
      case 'pronto':
        return 'entregue';
      default:
        return '';
    }
  }

  String get _labelProximoStatus {
    switch (pedido.status) {
      case 'aberto':
        return 'Marcar Pronto';
      case 'pronto':
        return 'Marcar Entregue';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final corStatus = _statusColor(pedido.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: tokens.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: corStatus.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAbrirDetalhes,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _textoPedido(pedido.nomeCliente, vazio: 'Sem nome'),
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cod. cliente: ${_textoPedido(pedido.codigoEntrega)} • ${pedido.horarioPedido} • ${DateFormat('dd/MM').format(pedido.dataPedido)}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: corStatus.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: corStatus.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      _statusLabel(pedido.status),
                      style: AppTextStyles.caption.copyWith(
                        color: corStatus,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'detalhes':
                          onAbrirDetalhes();
                          break;
                        case 'cupom':
                          onVerCupom();
                          break;
                        case 'editar':
                          onEditar();
                          break;
                        case 'excluir':
                          onExcluir();
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'detalhes',
                        child: ListTile(
                          leading: Icon(Icons.visibility_outlined),
                          title: Text('Ver pedido'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'cupom',
                        child: ListTile(
                          leading: Icon(Icons.receipt_long),
                          title: Text('Ver cupom'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'editar',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'excluir',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline,
                              color: AppColors.danger),
                          title: Text('Excluir',
                              style: TextStyle(color: AppColors.danger)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...pedido.itens.take(3).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.local_pizza,
                              size: 15, color: AppColors.warning),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${item.quantidade}x ${item.tamanhoLabel} - ${item.descricao}',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (pedido.itens.length > 3)
                Text(
                  '+ ${pedido.itens.length - 3} itens',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              if (pedido.observacoes != null &&
                  pedido.observacoes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pedido.observacoes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
              // Botão de avanço de status (único CTA direto no card)
              if (_proximoStatus.isNotEmpty) ...[
                const SizedBox(height: 10),
                Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => onMudarStatus(_proximoStatus),
                    style: FilledButton.styleFrom(
                      backgroundColor: _proximoStatus == 'pronto'
                          ? AppColors.warning
                          : AppColors.success,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      textStyle: AppTextStyles.caption
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    child: Text(_labelProximoStatus),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sheet de detalhes ─────────────────────────────────────────

class _DetalhesPedidoSheet extends StatelessWidget {
  final PedidoPizza pedido;
  final VoidCallback onVerCupom;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final void Function(String) onSelecionarStatus;

  const _DetalhesPedidoSheet({
    required this.pedido,
    required this.onVerCupom,
    required this.onEditar,
    required this.onExcluir,
    required this.onSelecionarStatus,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final statuses = ['aberto', 'pronto', 'entregue'];

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    'Pedido Completo',
                    style:
                        AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Divider(color: AppColors.divider),
              Text(
                _textoPedido(pedido.nomeCliente, vazio: 'Sem nome'),
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              _InfoRow(
                  label: 'Codigo do Cliente',
                  value: _textoPedido(pedido.codigoEntrega)),
              _InfoRow(
                  label: 'Data',
                  value: DateFormat('dd/MM/yyyy').format(pedido.dataPedido)),
              _InfoRow(label: 'Horario', value: pedido.horarioPedido),
              if ((pedido.endereco ?? '').trim().isNotEmpty)
                _InfoRow(label: 'Endereco', value: pedido.endereco!.trim()),
              if ((pedido.bairro ?? '').trim().isNotEmpty)
                _InfoRow(label: 'Bairro', value: pedido.bairro!.trim()),
              if ((pedido.telefone ?? '').trim().isNotEmpty)
                _InfoRow(label: 'Telefone', value: pedido.telefone!.trim()),
              if ((pedido.referencia ?? '').trim().isNotEmpty)
                _InfoRow(label: 'Referencia', value: pedido.referencia!.trim()),
              const SizedBox(height: 12),
              Text(
                'Itens',
                style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              ...pedido.itens.map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_pizza,
                          color: AppColors.warning, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.quantidade}x ${item.tamanhoLabel} - ${item.descricao}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (pedido.observacoes != null &&
                  pedido.observacoes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Observacoes',
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  pedido.observacoes!,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Status do pedido',
                style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: statuses
                    .map(
                      (status) => ChoiceChip(
                        label: Text(_statusLabel(status)),
                        selected: pedido.status == status,
                        selectedColor:
                            _statusColor(status).withValues(alpha: 0.18),
                        checkmarkColor: _statusColor(status),
                        onSelected: (selected) {
                          if (selected && status != pedido.status) {
                            onSelecionarStatus(status);
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onVerCupom,
                      icon: Icon(Icons.receipt_long,
                          color: AppColors.textSecondary),
                      label: Text('Cupom',
                          style: TextStyle(color: AppColors.textPrimary)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEditar,
                      icon: Icon(Icons.edit_outlined,
                          color: AppColors.textSecondary),
                      label: Text('Editar',
                          style: TextStyle(color: AppColors.textPrimary)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onExcluir,
                  icon: Icon(Icons.delete_outline, color: AppColors.danger),
                  label: Text('Excluir',
                      style: TextStyle(color: AppColors.danger)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.4)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip de filtro com contagem ───────────────────────────────

class _ChipFiltro extends StatelessWidget {
  final String label;
  final int count;
  final String valor;
  final String atual;
  final void Function(String) onTap;
  final Color? cor;

  const _ChipFiltro({
    required this.label,
    required this.count,
    required this.valor,
    required this.atual,
    required this.onTap,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final selecionado = valor == atual;
    final c = cor ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: selecionado,
        selectedColor: c.withValues(alpha: 0.18),
        checkmarkColor: c,
        labelStyle: AppTextStyles.caption.copyWith(
          color: selecionado ? c : AppColors.textSecondary,
          fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
        ),
        onSelected: (_) => onTap(valor),
      ),
    );
  }
}

// ── Funções utilitárias ───────────────────────────────────────

String _textoPedido(String? valor, {String vazio = '-'}) {
  final t = valor?.trim() ?? '';
  return t.isEmpty ? vazio : t;
}

String _statusLabel(String status) {
  switch (status) {
    case 'pronto':
      return 'Pronto';
    case 'entregue':
      return 'Entregue';
    default:
      return 'Aberto';
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'pronto':
      return AppColors.warning;
    case 'entregue':
      return AppColors.success;
    default:
      return AppColors.info;
  }
}
