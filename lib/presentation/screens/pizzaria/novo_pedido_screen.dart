// lib/modules/pizza/novo_pedido_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'pizza_models.dart';

class NovoPedidoScreen extends StatefulWidget {
  const NovoPedidoScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _horario = _formatarHora(TimeOfDay.now());
    _carregarPizzas();
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
      nomeCliente: _nomeCtrl.text.trim(),
      codigoEntrega: _codigoCtrl.text.trim(),
      dataPedido: _data,
      horarioPedido: _horario,
      observacoes: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      itens: _itens,
    );

    try {
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
      appBar: AppBar(title: const Text('Novo Pedido')),
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
                      icon: const Icon(Icons.receipt_long),
                      label: _salvando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Gerar Cupom',
                              style: TextStyle(fontSize: 16)),
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
              const Text('— Grandes —',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              ..._grandes.map((p) => RadioListTile<Pizza>(
                    title: Text(p.nome),
                    value: p,
                    groupValue: _p1,
                    onChanged: (v) => setState(() => _p1 = v),
                    dense: true,
                  )),
              const Text('— Médias —',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              ..._medias.map((p) => RadioListTile<Pizza>(
                    title: Text(p.nome),
                    value: p,
                    groupValue: _p1,
                    onChanged: (v) => setState(() => _p1 = v),
                    dense: true,
                  )),
            ] else ...[
              const Text('Metade 1',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ..._opcoesMeio.map((p) => RadioListTile<Pizza>(
                    title: Text(p.nome),
                    value: p,
                    groupValue: _p1,
                    onChanged: (v) => setState(() => _p1 = v),
                    dense: true,
                  )),
              const Divider(),
              const Text('Metade 2',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ..._opcoesMeio.map((p) => RadioListTile<Pizza>(
                    title: Text(p.nome),
                    value: p,
                    groupValue: _p2,
                    onChanged: (v) => setState(() => _p2 = v),
                    dense: true,
                  )),
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

// ============================================================
// WIDGET CUPOM
// ============================================================

class CupomWidget extends StatelessWidget {
  final PedidoPizza pedido;
  final VoidCallback onFechar;

  const CupomWidget({super.key, required this.pedido, required this.onFechar});

  String _gerarTexto() {
    const linha = '================================';
    const linhaf = '--------------------------------';
    final buf = StringBuffer();

    buf.writeln(linha);
    buf.writeln('      PIZZARIA CARROSSEL');
    buf.writeln(linha);
    buf.writeln('Cod. Entrega : ${pedido.codigoEntrega}');
    buf.writeln(
        'Data         : ${DateFormat('dd/MM/yyyy').format(pedido.dataPedido)}');
    buf.writeln('Horário      : ${pedido.horarioPedido}');
    buf.writeln('Cliente      : ${pedido.nomeCliente}');
    buf.writeln(linhaf);
    buf.writeln('ITENS:');
    buf.writeln(linhaf);

    for (final item in pedido.itens) {
      final tamanho = item.tamanhoLabel.toUpperCase();
      if (item.ehMeioAMeio) {
        buf.writeln('${item.quantidade}x Pizza $tamanho (Meio a Meio)');
        buf.writeln('   ½ ${item.pizzaNome}');
        buf.writeln('   ½ ${item.pizza2Nome}');
      } else {
        buf.writeln('${item.quantidade}x Pizza $tamanho');
        buf.writeln('   ${item.pizzaNome}');
      }
    }

    buf.writeln(linhaf);
    if (pedido.observacoes != null && pedido.observacoes!.isNotEmpty) {
      buf.writeln('OBS: ${pedido.observacoes}');
      buf.writeln(linhaf);
    }
    buf.writeln(linha);
    buf.writeln('       BOM APETITE! 🍕');
    buf.writeln(linha);

    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final texto = _gerarTexto();

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Cupom do Pedido',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: onFechar),
            ],
          ),
          const Divider(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              texto,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: texto));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Cupom copiado! Cole no WhatsApp.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Concluir'),
                  onPressed: onFechar,
                ),
              ),
            ],
          ),
        ],
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
