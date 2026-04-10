// lib/modules/pizza/pedidos_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  bool _loading = true;
  String _filtro = 'todos'; // 'todos' | 'aberto' | 'pronto' | 'entregue'

  @override
  void initState() {
    super.initState();
    _carregar();
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
    if (_filtro == 'todos') return _pedidos;
    return _pedidos.where((p) => p.status == _filtro).toList();
  }

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
        title: Text('Excluir pedido?'),
        content: Text(
          'Deseja excluir o pedido de ${_textoPedido(pedido.nomeCliente, vazio: 'cliente sem nome')} '
          '(cod. cliente: ${_textoPedido(pedido.codigoEntrega)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await PizzaService.excluirPedido(pedido.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pedido excluido com sucesso.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedidos de Pizza'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _carregar),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NovoPedidoScreen()),
          );
          _carregar();
        },
        icon: Icon(Icons.add),
        label: Text('Novo Pedido'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ChipFiltro(
                    label: 'Todos',
                    valor: 'todos',
                    atual: _filtro,
                    onTap: (v) => setState(() => _filtro = v),
                  ),
                  _ChipFiltro(
                    label: 'Abertos',
                    valor: 'aberto',
                    atual: _filtro,
                    onTap: (v) => setState(() => _filtro = v),
                    cor: Colors.blue,
                  ),
                  _ChipFiltro(
                    label: 'Prontos',
                    valor: 'pronto',
                    atual: _filtro,
                    onTap: (v) => setState(() => _filtro = v),
                    cor: Colors.orange,
                  ),
                  _ChipFiltro(
                    label: 'Entregues',
                    valor: 'entregue',
                    atual: _filtro,
                    onTap: (v) => setState(() => _filtro = v),
                    cor: Colors.green,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : _pedidosFiltrados.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum pedido encontrado.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregar,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _pedidosFiltrados.length,
                          separatorBuilder: (_, __) => SizedBox(height: 2),
                          itemBuilder: (_, i) {
                            final pedido = _pedidosFiltrados[i];
                            return _CardPedido(
                              pedido: pedido,
                              onAbrirDetalhes: () => _abrirDetalhes(pedido),
                              onVerCupom: () => _verCupom(pedido),
                              onEditar: () => _editarPedido(pedido),
                              onExcluir: () => _excluirPedido(pedido),
                              onMudarStatus: (s) => _mudarStatus(pedido, s),
                            );
                          },
                        ),
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
    final corStatus = _statusColor(pedido.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: corStatus.withValues(alpha: 0.16),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Cod. cliente: ${_textoPedido(pedido.codigoEntrega)} • ${pedido.horarioPedido} • ${DateFormat('dd/MM').format(pedido.dataPedido)}',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: corStatus.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: corStatus.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _statusLabel(pedido.status),
                      style: TextStyle(
                        color: corStatus,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
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
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'detalhes',
                        child: ListTile(
                          leading: Icon(Icons.visibility_outlined),
                          title: Text('Ver pedido'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'cupom',
                        child: ListTile(
                          leading: Icon(Icons.receipt_long),
                          title: Text('Ver cupom'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'editar',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'excluir',
                        child: ListTile(
                          leading:
                              Icon(Icons.delete_outline, color: Colors.red),
                          title: Text('Excluir'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              ...pedido.itens.take(3).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_pizza,
                            size: 16,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${item.quantidade}x ${item.tamanhoLabel} - ${item.descricao}',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (pedido.itens.length > 3)
                Text(
                  '+ ${pedido.itens.length - 3} itens',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              if (pedido.observacoes != null &&
                  pedido.observacoes!.isNotEmpty) ...[
                SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pedido.observacoes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 10),
              Divider(height: 1),
              SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: Icon(Icons.visibility_outlined, size: 16),
                    label: Text('Detalhes'),
                    onPressed: onAbrirDetalhes,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: TextStyle(fontSize: 13),
                    ),
                  ),
                  SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: Icon(Icons.receipt_long, size: 16),
                    label: Text('Cupom'),
                    onPressed: onVerCupom,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: TextStyle(fontSize: 13),
                    ),
                  ),
                  const Spacer(),
                  if (_proximoStatus.isNotEmpty)
                    FilledButton(
                      onPressed: () => onMudarStatus(_proximoStatus),
                      style: FilledButton.styleFrom(
                        backgroundColor: _proximoStatus == 'pronto'
                            ? Colors.orange
                            : Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        textStyle: TextStyle(fontSize: 13),
                      ),
                      child: Text(_labelProximoStatus),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final statuses = ['aberto', 'pronto', 'entregue'];

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Pedido Completo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              Divider(),
              Text(
                _textoPedido(pedido.nomeCliente, vazio: 'Sem nome'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Codigo do Cliente: ${_textoPedido(pedido.codigoEntrega)}'),
              Text(
                  'Data: ${DateFormat('dd/MM/yyyy').format(pedido.dataPedido)}'),
              Text('Horario: ${pedido.horarioPedido}'),
              if ((pedido.endereco ?? '').trim().isNotEmpty)
                Text('Endereco: ${pedido.endereco!.trim()}'),
              if ((pedido.bairro ?? '').trim().isNotEmpty)
                Text('Bairro: ${pedido.bairro!.trim()}'),
              if ((pedido.telefone ?? '').trim().isNotEmpty)
                Text('Telefone: ${pedido.telefone!.trim()}'),
              if ((pedido.referencia ?? '').trim().isNotEmpty)
                Text('Referencia: ${pedido.referencia!.trim()}'),
              SizedBox(height: 12),
              Text(
                'Itens',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ...pedido.itens.map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: Icon(Icons.local_pizza, color: Colors.orange),
                    title: Text(
                      '${item.quantidade}x ${item.tamanhoLabel} - ${item.descricao}',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ),
              if (pedido.observacoes != null &&
                  pedido.observacoes!.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  'Observacoes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(pedido.observacoes!),
              ],
              SizedBox(height: 16),
              Text(
                'Status do pedido',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: statuses
                    .map(
                      (status) => ChoiceChip(
                        label: Text(_statusLabel(status)),
                        selected: pedido.status == status,
                        onSelected: (selected) {
                          if (selected && status != pedido.status) {
                            onSelecionarStatus(status);
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onVerCupom,
                      icon: Icon(Icons.receipt_long),
                      label: Text('Cupom'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEditar,
                      icon: Icon(Icons.edit_outlined),
                      label: Text('Editar'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onExcluir,
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  label: Text('Excluir', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String label;
  final String valor;
  final String atual;
  final void Function(String) onTap;
  final Color? cor;

  const _ChipFiltro({
    required this.label,
    required this.valor,
    required this.atual,
    required this.onTap,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final selecionado = valor == atual;
    final c = cor ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selecionado,
        selectedColor: c.withValues(alpha: 0.2),
        checkmarkColor: c,
        onSelected: (_) => onTap(valor),
      ),
    );
  }
}

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
      return Colors.orange;
    case 'entregue':
      return Colors.green;
    default:
      return Colors.blue;
  }
}
