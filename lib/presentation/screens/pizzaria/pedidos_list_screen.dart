// lib/modules/pizza/pedidos_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pizza_models.dart';
import 'novo_pedido_screen.dart';

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
    final lista = await PizzaService.listarPedidos();
    setState(() {
      _pedidos = lista;
      _loading = false;
    });
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
      backgroundColor: Colors.transparent,
      builder: (_) => CupomWidget(
        pedido: pedido,
        onFechar: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos de Pizza'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar),
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
        icon: const Icon(Icons.add),
        label: const Text('Novo Pedido'),
      ),
      body: Column(
        children: [
          // Filtro de status
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
                      onTap: (v) => setState(() => _filtro = v)),
                  _ChipFiltro(
                      label: 'Abertos',
                      valor: 'aberto',
                      atual: _filtro,
                      onTap: (v) => setState(() => _filtro = v),
                      cor: Colors.blue),
                  _ChipFiltro(
                      label: 'Prontos',
                      valor: 'pronto',
                      atual: _filtro,
                      onTap: (v) => setState(() => _filtro = v),
                      cor: Colors.orange),
                  _ChipFiltro(
                      label: 'Entregues',
                      valor: 'entregue',
                      atual: _filtro,
                      onTap: (v) => setState(() => _filtro = v),
                      cor: Colors.green),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _pedidosFiltrados.isEmpty
                    ? const Center(
                        child: Text('Nenhum pedido encontrado.',
                            style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: _carregar,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _pedidosFiltrados.length,
                          itemBuilder: (_, i) => _CardPedido(
                            pedido: _pedidosFiltrados[i],
                            onVerCupom: () => _verCupom(_pedidosFiltrados[i]),
                            onMudarStatus: (s) =>
                                _mudarStatus(_pedidosFiltrados[i], s),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CARD DO PEDIDO
// ============================================================

class _CardPedido extends StatelessWidget {
  final PedidoPizza pedido;
  final VoidCallback onVerCupom;
  final void Function(String) onMudarStatus;

  const _CardPedido({
    required this.pedido,
    required this.onVerCupom,
    required this.onMudarStatus,
  });

  Color get _corStatus {
    switch (pedido.status) {
      case 'pronto':
        return Colors.orange;
      case 'entregue':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String get _labelStatus {
    switch (pedido.status) {
      case 'pronto':
        return 'Pronto';
      case 'entregue':
        return 'Entregue';
      default:
        return 'Aberto';
    }
  }

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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pedido.nomeCliente,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cod: ${pedido.codigoEntrega}  •  ${pedido.horarioPedido}  •  ${DateFormat('dd/MM').format(pedido.dataPedido)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _corStatus.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: _corStatus.withValues(alpha: 0.4)),
                  ),
                  child: Text(_labelStatus,
                      style: TextStyle(
                          color: _corStatus,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Itens do pedido
            ...pedido.itens.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.local_pizza,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${item.quantidade}x ${item.tamanhoLabel} — ${item.descricao}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),

            if (pedido.observacoes != null &&
                pedido.observacoes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(pedido.observacoes!,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Ações
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: const Text('Cupom'),
                  onPressed: onVerCupom,
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13),
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
                          horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: Text(_labelProximoStatus),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CHIP DE FILTRO
// ============================================================

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
