// lib/modules/pizza/novo_pedido_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'cupom_widget.dart';
import 'pizza_models.dart';

class NovoPedidoScreen extends StatefulWidget {
  final PedidoPizza? pedidoExistente;

  const NovoPedidoScreen({super.key, this.pedidoExistente});

  @override
  State<NovoPedidoScreen> createState() => _NovoPedidoScreenState();
}

class _NovoPedidoScreenState extends State<NovoPedidoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  DateTime _data = DateTime.now();
  String _horario = '';
  List<Pizza> _pizzas = [];
  final List<ItemPedido> _itens = [];
  bool _carregando = false;
  bool _salvando = false;

  bool get _isEdicao => widget.pedidoExistente != null;

  @override
  void initState() {
    super.initState();
    if (_isEdicao) {
      final pedido = widget.pedidoExistente!;
      _nomeCtrl.text = pedido.nomeCliente;
      _codigoCtrl.text = pedido.codigoEntrega;
      _obsCtrl.text = pedido.observacoes ?? '';
      _data = pedido.dataPedido;
      _horario = pedido.horarioPedido;
      _itens.addAll(
        pedido.itens.map(
          (item) => ItemPedido(
            pizzaId: item.pizzaId,
            pizzaNome: item.pizzaNome,
            pizzaTamanho: item.pizzaTamanho,
            pizza2Id: item.pizza2Id,
            pizza2Nome: item.pizza2Nome,
            quantidade: item.quantidade,
            ehMeioAMeio: item.ehMeioAMeio,
          ),
        ),
      );
    } else {
      _horario = _formatarHora(TimeOfDay.now());
    }
    _carregarPizzas();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _codigoCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  String _formatarHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _carregarPizzas() async {
    setState(() => _carregando = true);
    _pizzas = await PizzaService.listarPizzas();
    setState(() => _carregando = false);
  }

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (d != null) setState(() => _data = d);
  }

  Future<void> _escolherHora() async {
    final partes = _horario.split(':');
    final t = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1])),
    );
    if (t != null) setState(() => _horario = _formatarHora(t));
  }

  void _adicionarItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SeletorPizza(
        pizzas: _pizzas,
        onAdicionado: (item) => setState(() => _itens.add(item)),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Adicione pelo menos uma pizza ao pedido.')),
      );
      return;
    }
    setState(() => _salvando = true);

    final pedido = PedidoPizza(
      id: _isEdicao ? widget.pedidoExistente!.id : null,
      nomeCliente: _nomeCtrl.text.trim(),
      codigoEntrega: _codigoCtrl.text.trim(),
      dataPedido: _data,
      horarioPedido: _horario,
      observacoes: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      status: _isEdicao ? widget.pedidoExistente!.status : 'aberto',
      itens: _itens,
    );

    try {
      if (_isEdicao) {
        await PizzaService.atualizarPedido(pedido);
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }

      final id = await PizzaService.criarPedido(pedido);
      if (!mounted) return;
      // Mostra cupom
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        builder: (_) => CupomWidget(
          pedido: PedidoPizza(
            id: id,
            nomeCliente: pedido.nomeCliente,
            codigoEntrega: pedido.codigoEntrega,
            dataPedido: pedido.dataPedido,
            horarioPedido: pedido.horarioPedido,
            observacoes: pedido.observacoes,
            itens: pedido.itens,
          ),
          onFechar: () {
            Navigator.pop(context); // fecha cupom
            Navigator.pop(context); // volta para lista
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdicao ? 'Editar Pedido' : 'Novo Pedido')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ---- Dados do cliente ----
                  const _Secao('Dados do Pedido'),
                  TextFormField(
                    controller: _nomeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Cliente *',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _codigoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Código de Entrega *',
                      prefixIcon: Icon(Icons.qr_code),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Informe o código' : null,
                  ),
                  const SizedBox(height: 12),
                  // Data e hora em linha
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(DateFormat('dd/MM/yyyy').format(_data)),
                          onPressed: _escolherData,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: Text(_horario),
                          onPressed: _escolherHora,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _obsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // ---- Itens ----
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _Secao('Pizzas do Pedido'),
                      TextButton.icon(
                        onPressed: _adicionarItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar'),
                      ),
                    ],
                  ),
                  if (_itens.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                          child: Text('Nenhuma pizza adicionada.',
                              style: TextStyle(color: Colors.grey))),
                    ),
                  ..._itens.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading:
                            const Icon(Icons.local_pizza, color: Colors.orange),
                        title: Text(item.descricao),
                        subtitle: Text(
                            '${item.tamanhoLabel} • Qtd: ${item.quantidade}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () => setState(() => _itens.removeAt(i)),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _salvando ? null : _salvar,
                      icon: Icon(
                          _isEdicao ? Icons.save_outlined : Icons.receipt_long),
                      label: _salvando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              _isEdicao ? 'Salvar Alterações' : 'Gerar Cupom',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ============================================================
// SELETOR DE PIZZA (bottom sheet)
// ============================================================

class _SeletorPizza extends StatefulWidget {
  final List<Pizza> pizzas;
  final void Function(ItemPedido) onAdicionado;

  const _SeletorPizza({required this.pizzas, required this.onAdicionado});

  @override
  State<_SeletorPizza> createState() => _SeletorPizzaState();
}

class _SeletorPizzaState extends State<_SeletorPizza> {
  bool _meioAMeio = false;
  bool _expandGrandes = true;
  bool _expandMedias = false;
  Pizza? _p1;
  Pizza? _p2;
  int _qtd = 1;

  List<Pizza> get _grandes =>
      widget.pizzas.where((p) => p.tamanho == 'grande').toList();
  List<Pizza> get _medias =>
      widget.pizzas.where((p) => p.tamanho == 'media').toList();

  // Meio a meio só para grandes
  List<Pizza> get _opcoesMeio => _grandes;

  bool get _podeAdicionar {
    if (_meioAMeio) return _p1 != null && _p2 != null;
    return _p1 != null;
  }

  void _adicionar() {
    if (!_podeAdicionar) return;
    widget.onAdicionado(ItemPedido(
      pizzaId: _p1!.id,
      pizzaNome: _p1!.nome,
      pizzaTamanho: _p1!.tamanho,
      pizza2Id: _meioAMeio ? _p2!.id : null,
      pizza2Nome: _meioAMeio ? _p2!.nome : null,
      quantidade: _qtd,
      ehMeioAMeio: _meioAMeio,
    ));
    Navigator.pop(context);
  }

  Widget _pizzaCard({
    required Pizza pizza,
    required Pizza? selecionada,
    required ValueChanged<Pizza> onSelecionar,
  }) {
    final isSelecionada = selecionada?.id == pizza.id;
    final corBorda = isSelecionada
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.withOpacity(0.25);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: corBorda, width: isSelecionada ? 1.6 : 1),
      ),
      elevation: isSelecionada ? 1.5 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => onSelecionar(pizza)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.local_pizza_outlined,
                color: isSelecionada
                    ? Theme.of(context).colorScheme.primary
                    : Colors.orange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pizza.nome,
                  style: TextStyle(
                    fontWeight:
                        isSelecionada ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Radio<Pizza>(
                value: pizza,
                groupValue: selecionada,
                onChanged: (v) {
                  if (v != null) {
                    setState(() => onSelecionar(v));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pizzaGrid({
    required List<Pizza> pizzas,
    required Pizza? selecionada,
    required ValueChanged<Pizza> onSelecionar,
  }) {
    if (pizzas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8, bottom: 8),
        child: Text(
          'Nenhuma pizza nessa categoria.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pizzas.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.7,
      ),
      itemBuilder: (_, i) => _pizzaCard(
        pizza: pizzas[i],
        selecionada: selecionada,
        onSelecionar: onSelecionar,
      ),
    );
  }

  Widget _categoriaExpansivel({
    required String titulo,
    required bool expandida,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  expandida ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState:
              expandida ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: child,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Adicionar Pizza',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Meio a meio toggle (só para grandes)
            SwitchListTile(
              title: const Text('Meio a Meio (apenas grande)'),
              value: _meioAMeio,
              onChanged: (v) => setState(() {
                _meioAMeio = v;
                _p1 = null;
                _p2 = null;
              }),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),

            if (!_meioAMeio) ...[
              const Text('Sabor',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _categoriaExpansivel(
                titulo: 'Grandes',
                expandida: _expandGrandes,
                onTap: () => setState(() => _expandGrandes = !_expandGrandes),
                child: _pizzaGrid(
                  pizzas: _grandes,
                  selecionada: _p1,
                  onSelecionar: (v) => _p1 = v,
                ),
              ),
              const SizedBox(height: 8),
              _categoriaExpansivel(
                titulo: 'Medias',
                expandida: _expandMedias,
                onTap: () => setState(() => _expandMedias = !_expandMedias),
                child: _pizzaGrid(
                  pizzas: _medias,
                  selecionada: _p1,
                  onSelecionar: (v) => _p1 = v,
                ),
              ),
            ] else ...[
              const Text('Metade 1',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const SizedBox(height: 8),
              _pizzaGrid(
                pizzas: _opcoesMeio,
                selecionada: _p1,
                onSelecionar: (v) => _p1 = v,
              ),
              const Divider(),
              const Text('Metade 2',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const SizedBox(height: 8),
              _pizzaGrid(
                pizzas: _opcoesMeio,
                selecionada: _p2,
                onSelecionar: (v) => _p2 = v,
              ),
            ],

            const Divider(),
            // Quantidade
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Quantidade: ',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _qtd > 1 ? () => setState(() => _qtd--) : null,
                ),
                Text('$_qtd',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _qtd++),
                ),
              ],
            ),
            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _podeAdicionar ? _adicionar : null,
                child: const Text('Adicionar ao Pedido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget
class _Secao extends StatelessWidget {
  final String texto;
  const _Secao(this.texto);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(texto,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      );
}
