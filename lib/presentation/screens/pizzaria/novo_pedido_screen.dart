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
  final _enderecoCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
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
      _nomeCtrl.text = pedido.nomeCliente ?? '';
      _codigoCtrl.text = pedido.codigoEntrega ?? '';
      _enderecoCtrl.text = pedido.endereco ?? '';
      _bairroCtrl.text = pedido.bairro ?? '';
      _telefoneCtrl.text = pedido.telefone ?? '';
      _referenciaCtrl.text = pedido.referencia ?? '';
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
    _enderecoCtrl.dispose();
    _bairroCtrl.dispose();
    _telefoneCtrl.dispose();
    _referenciaCtrl.dispose();
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

  Future<void> _adicionarItem() async {
    final itens = await Navigator.of(context).push<List<ItemPedido>>(
      MaterialPageRoute(
        builder: (_) => _SeletorPizzaScreen(pizzas: _pizzas),
      ),
    );

    if (!mounted || itens == null || itens.isEmpty) return;
    setState(() => _itens.addAll(itens));
  }

  String? _opcional(String valor) {
    final t = valor.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adicione pelo menos uma pizza ao pedido.')),
      );
      return;
    }
    setState(() => _salvando = true);

    final pedido = PedidoPizza(
      id: _isEdicao ? widget.pedidoExistente!.id : null,
      nomeCliente: _opcional(_nomeCtrl.text),
      codigoEntrega: _opcional(_codigoCtrl.text),
      endereco: _opcional(_enderecoCtrl.text),
      bairro: _opcional(_bairroCtrl.text),
      telefone: _opcional(_telefoneCtrl.text),
      referencia: _opcional(_referenciaCtrl.text),
      dataPedido: _data,
      horarioPedido: _horario,
      observacoes: _opcional(_obsCtrl.text),
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
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        builder: (_) => CupomWidget(
          pedido: PedidoPizza(
            id: id,
            nomeCliente: pedido.nomeCliente,
            codigoEntrega: pedido.codigoEntrega,
            endereco: pedido.endereco,
            bairro: pedido.bairro,
            telefone: pedido.telefone,
            referencia: pedido.referencia,
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
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ---- Dados do cliente ----
                  const _Secao('Dados do Pedido'),
                  TextFormField(
                    controller: _nomeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nome do Cliente',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _codigoCtrl,
                    decoration: InputDecoration(
                      labelText: 'Codigo do Cliente',
                      prefixIcon: Icon(Icons.qr_code),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _enderecoCtrl,
                    decoration: InputDecoration(
                      labelText: 'Endereco',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _bairroCtrl,
                    decoration: InputDecoration(
                      labelText: 'Bairro',
                      prefixIcon: Icon(Icons.map_outlined),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _telefoneCtrl,
                    decoration: InputDecoration(
                      labelText: 'Telefone',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _referenciaCtrl,
                    decoration: InputDecoration(
                      labelText: 'Referencia',
                      prefixIcon: Icon(Icons.place_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  // Data e hora em linha
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.calendar_today),
                          label: Text(DateFormat('dd/MM/yyyy').format(_data)),
                          onPressed: _escolherData,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.access_time),
                          label: Text(_horario),
                          onPressed: _escolherHora,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _obsCtrl,
                    decoration: InputDecoration(
                      labelText: 'Observacoes',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: 24),

                  // ---- Itens ----
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _Secao('Pizzas do Pedido'),
                      TextButton.icon(
                        onPressed: _adicionarItem,
                        icon: Icon(Icons.add),
                        label: Text('Adicionar'),
                      ),
                    ],
                  ),
                  if (_itens.isEmpty)
                    Padding(
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
                        leading: Icon(Icons.local_pizza, color: Colors.orange),
                        title: Text(item.descricao),
                        subtitle: Text(
                            '${item.tamanhoLabel} - Qtd: ${item.quantidade}'),
                        trailing: IconButton(
                          icon: Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () => setState(() => _itens.removeAt(i)),
                        ),
                      ),
                    );
                  }),

                  SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _salvando ? null : _salvar,
                      icon: Icon(
                          _isEdicao ? Icons.save_outlined : Icons.receipt_long),
                      label: _salvando
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              _isEdicao ? 'Salvar Alteracoes' : 'Gerar Cupom',
                              style: TextStyle(fontSize: 16),
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
// SELETOR DE PIZZA (tela dedicada)
// ============================================================

class _SeletorPizzaScreen extends StatefulWidget {
  final List<Pizza> pizzas;

  const _SeletorPizzaScreen({required this.pizzas});

  @override
  State<_SeletorPizzaScreen> createState() => _SeletorPizzaScreenState();
}

class _SeletorPizzaScreenState extends State<_SeletorPizzaScreen> {
  bool _meioAMeio = false;
  bool _expandGrandes = true;
  bool _expandMedias = false;
  Pizza? _p1;
  Pizza? _p2;
  int _qtd = 1;
  final List<ItemPedido> _itensSelecionados = [];

  List<Pizza> get _grandes =>
      widget.pizzas.where((p) => p.tamanho == 'grande').toList();
  List<Pizza> get _medias =>
      widget.pizzas.where((p) => p.tamanho == 'media').toList();

  // Meio a meio so para grandes
  List<Pizza> get _opcoesMeio => _grandes;

  bool get _podeAdicionar {
    if (_meioAMeio) return _p1 != null && _p2 != null;
    return _p1 != null;
  }

  ItemPedido? _itemAtual() {
    if (!_podeAdicionar) return null;
    return ItemPedido(
      pizzaId: _p1!.id,
      pizzaNome: _p1!.nome,
      pizzaTamanho: _p1!.tamanho,
      pizza2Id: _meioAMeio ? _p2!.id : null,
      pizza2Nome: _meioAMeio ? _p2!.nome : null,
      quantidade: _qtd,
      ehMeioAMeio: _meioAMeio,
    );
  }

  void _limparSelecaoAtual() {
    _p1 = null;
    _p2 = null;
    _qtd = 1;
  }

  void _adicionarNaSessao() {
    final item = _itemAtual();
    if (item == null) return;
    setState(() {
      _itensSelecionados.add(item);
      _limparSelecaoAtual();
    });
  }

  void _concluirSelecao() {
    final itens = List<ItemPedido>.from(_itensSelecionados);
    final itemAtual = _itemAtual();
    if (itemAtual != null) itens.add(itemAtual);
    if (itens.isEmpty) return;
    Navigator.pop(context, itens);
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutCompacto = constraints.maxWidth < 210;

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
              padding: EdgeInsets.symmetric(
                horizontal: layoutCompacto ? 10 : 12,
                vertical: layoutCompacto ? 12 : 10,
              ),
              child: layoutCompacto
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_pizza_outlined,
                              color: isSelecionada
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.orange,
                            ),
                            const Spacer(),
                            Radio<Pizza>(
                              value: pizza,
                              groupValue: selecionada,
                              visualDensity: VisualDensity.compact,
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => onSelecionar(v));
                                }
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          pizza.nome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isSelecionada
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(
                          Icons.local_pizza_outlined,
                          color: isSelecionada
                              ? Theme.of(context).colorScheme.primary
                              : Colors.orange,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            pizza.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isSelecionada
                                  ? FontWeight.w700
                                  : FontWeight.w500,
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
      },
    );
  }

  Widget _pizzaGrid({
    required List<Pizza> pizzas,
    required Pizza? selecionada,
    required ValueChanged<Pizza> onSelecionar,
  }) {
    if (pizzas.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 8, bottom: 8),
        child: Text(
          'Nenhuma pizza nessa categoria.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;

        final int colunas;
        if (largura >= 1400) {
          colunas = 5;
        } else if (largura >= 1100) {
          colunas = 4;
        } else if (largura >= 720) {
          colunas = 3;
        } else if (largura >= 430) {
          colunas = 2;
        } else {
          colunas = 1;
        }

        final double alturaCard;
        if (colunas >= 5) {
          alturaCard = 84;
        } else if (colunas == 4) {
          alturaCard = 88;
        } else if (colunas == 3) {
          alturaCard = 96;
        } else if (colunas == 2) {
          alturaCard = largura < 520 ? 132 : 118;
        } else {
          alturaCard = 92;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pizzas.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: colunas,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: alturaCard,
          ),
          itemBuilder: (_, i) => _pizzaCard(
            pizza: pizzas[i],
            selecionada: selecionada,
            onSelecionar: onSelecionar,
          ),
        );
      },
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
                    style: TextStyle(
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
    return Scaffold(
      appBar: AppBar(title: Text('Adicionar Pizza')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meio a meio toggle (so para grandes)
            SwitchListTile(
              title: Text('Meio a Meio (apenas grande)'),
              value: _meioAMeio,
              onChanged: (v) => setState(() {
                _meioAMeio = v;
                _p1 = null;
                _p2 = null;
              }),
              contentPadding: EdgeInsets.zero,
            ),
            Divider(),

            if (!_meioAMeio) ...[
              Text('Sabor', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
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
              SizedBox(height: 8),
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
              Text('Metade 1', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              SizedBox(height: 8),
              _pizzaGrid(
                pizzas: _opcoesMeio,
                selecionada: _p1,
                onSelecionar: (v) => _p1 = v,
              ),
              Divider(),
              Text('Metade 2', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              SizedBox(height: 8),
              _pizzaGrid(
                pizzas: _opcoesMeio,
                selecionada: _p2,
                onSelecionar: (v) => _p2 = v,
              ),
            ],

            Divider(),
            // Quantidade
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Quantidade: ',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: _qtd > 1 ? () => setState(() => _qtd--) : null,
                ),
                Text('$_qtd',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _qtd++),
                ),
              ],
            ),
            SizedBox(height: 8),

            if (_itensSelecionados.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_itensSelecionados.length} item(ns) jÃƒÆ’Ã‚Â¡ adicionados nesta seleÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _podeAdicionar ? _adicionarNaSessao : null,
                icon: Icon(Icons.add),
                label: Text('Adicionar item e continuar'),
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_itensSelecionados.isNotEmpty || _podeAdicionar)
                    ? _concluirSelecao
                    : null,
                icon: Icon(Icons.check),
                label: Text(
                  _itensSelecionados.isEmpty
                      ? 'Adicionar ao Pedido'
                      : 'Concluir (${_itensSelecionados.length + (_podeAdicionar ? 1 : 0)} itens)',
                ),
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
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      );
}
