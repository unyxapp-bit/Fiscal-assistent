// lib/modules/pizza/pizzas_cadastro_screen.dart

import 'package:flutter/material.dart';
import 'pizza_models.dart';

class PizzasCadastroScreen extends StatefulWidget {
  const PizzasCadastroScreen({super.key});

  @override
  State<PizzasCadastroScreen> createState() => _PizzasCadastroScreenState();
}

class _PizzasCadastroScreenState extends State<PizzasCadastroScreen> {
  List<Pizza> _pizzas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final lista = await PizzaService.listarPizzas(somenteAtivas: false);
    setState(() {
      _pizzas = lista;
      _loading = false;
    });
  }

  void _abrirFormulario([Pizza? pizza]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormPizza(
        pizza: pizza,
        onSalvo: _carregar,
      ),
    );
  }

  Future<void> _confirmarDelete(Pizza pizza) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Excluir pizza?'),
        content:
            Text('Deseja excluir "${pizza.nome} (${pizza.tamanhoLabel})"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await PizzaService.deletarPizza(pizza.id);
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final grandes = _pizzas.where((p) => p.tamanho == 'grande').toList();
    final medias = _pizzas.where((p) => p.tamanho == 'media').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Cardápio de Pizzas'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _carregar),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: Icon(Icons.add),
        label: Text('Nova Pizza'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                _secao('🍕 Pizzas Grandes', grandes),
                _secao('🍕 Pizzas Médias', medias),
              ],
            ),
    );
  }

  Widget _secao(String titulo, List<Pizza> lista) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(titulo,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        if (lista.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Nenhuma pizza cadastrada.',
                style: TextStyle(color: Colors.grey)),
          ),
        ...lista.map(
          (p) => Card(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: ListTile(
              onTap: () => _abrirFormulario(p),
              leading: CircleAvatar(
                backgroundColor: p.ativa ? Colors.orange : Colors.grey[300],
                child: Icon(
                  Icons.local_pizza,
                  color: p.ativa ? Colors.white : Colors.grey,
                ),
              ),
              title: Text(
                p.nome,
                style: TextStyle(color: p.ativa ? null : Colors.grey),
              ),
              subtitle: Text(
                p.ingredientes?.trim().isNotEmpty == true
                    ? '${p.tamanhoLabel} - ${p.ingredientes}'
                    : p.tamanhoLabel,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: p.ativa,
                    onChanged: (v) async {
                      await PizzaService.toggleAtivaPizza(p.id, v);
                      _carregar();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined),
                    onPressed: () => _abrirFormulario(p),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmarDelete(p),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// BOTTOM SHEET — Formulário de pizza
// ============================================================

class _FormPizza extends StatefulWidget {
  final Pizza? pizza;
  final VoidCallback onSalvo;

  const _FormPizza({this.pizza, required this.onSalvo});

  @override
  State<_FormPizza> createState() => _FormPizzaState();
}

class _FormPizzaState extends State<_FormPizza> {
  final _nomeCtrl = TextEditingController();
  final _ingredientesCtrl = TextEditingController();
  String _tamanho = 'grande';
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    if (widget.pizza != null) {
      _nomeCtrl.text = widget.pizza!.nome;
      _ingredientesCtrl.text = widget.pizza!.ingredientes ?? '';
      _tamanho = widget.pizza!.tamanho;
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _ingredientesCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty) return;
    setState(() => _salvando = true);

    final nova = Pizza(
      id: widget.pizza?.id ?? '',
      nome: _nomeCtrl.text.trim(),
      tamanho: _tamanho,
      ingredientes: _ingredientesCtrl.text.trim().isEmpty
          ? null
          : _ingredientesCtrl.text.trim(),
    );

    if (widget.pizza == null) {
      await PizzaService.salvarPizza(nova);
    } else {
      await PizzaService.atualizarPizza(widget.pizza!.id, nova);
    }

    if (mounted) {
      Navigator.pop(context);
      widget.onSalvo();
    }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.pizza == null ? 'Nova Pizza' : 'Editar Pizza',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _nomeCtrl,
            decoration: InputDecoration(
              labelText: 'Nome do sabor',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_pizza),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: 16),
          TextField(
            controller: _ingredientesCtrl,
            decoration: InputDecoration(
              labelText: 'Ingredientes',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.list_alt),
              hintText: 'Ex: queijo, molho de tomate, oregano',
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
          ),
          SizedBox(height: 16),
          Text('Tamanho'),
          SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'grande',
                  label: Text('Grande'),
                  icon: Icon(Icons.circle)),
              ButtonSegment(
                  value: 'media',
                  label: Text('Média'),
                  icon: Icon(Icons.circle_outlined)),
            ],
            selected: {_tamanho},
            onSelectionChanged: (s) => setState(() => _tamanho = s.first),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: _salvando
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Salvar'),
            ),
          ),
        ],
      ),
    );
  }
}
