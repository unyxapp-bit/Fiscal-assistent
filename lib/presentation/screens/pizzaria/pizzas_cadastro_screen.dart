// lib/modules/pizza/pizzas_cadastro_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/theme/app_theme.dart';
import 'pizza_models.dart';

final _currencyFmt =
    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);

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
        title: const Text('Excluir pizza?'),
        content:
            Text('Deseja excluir "${pizza.nome} (${pizza.tamanhoLabel})"?'),
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
    if (ok == true) {
      await PizzaService.deletarPizza(pizza.id);
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final grandes = _pizzas.where((p) => p.tamanho == 'grande').toList();
    final medias = _pizzas.where((p) => p.tamanho == 'media').toList();

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        backgroundColor: tokens.cardBackground,
        title: Text('Cardápio de Pizzas',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _carregar,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnColor,
        icon: const Icon(Icons.add),
        label: const Text('Nova Pizza'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                _secao(context, Icons.circle, 'Pizzas Grandes', grandes),
                _secao(context, Icons.circle_outlined, 'Pizzas Médias', medias),
              ],
            ),
    );
  }

  Widget _secao(
      BuildContext context, IconData icon, String titulo, List<Pizza> lista) {
    final tokens = context.appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho de seção estilizado
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.warning),
              ),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${lista.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (lista.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Nenhuma pizza cadastrada.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ...lista.map(
          (p) => Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            decoration: BoxDecoration(
              color: tokens.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: p.ativa
                    ? AppColors.cardBorder
                    : AppColors.cardBorder.withValues(alpha: 0.4),
              ),
            ),
            child: ListTile(
              onTap: () => _abrirFormulario(p),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: p.ativa
                    ? AppColors.warning.withValues(alpha: 0.15)
                    : AppColors.textSecondary.withValues(alpha: 0.1),
                child: Icon(
                  Icons.local_pizza,
                  color: p.ativa ? AppColors.warning : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              title: Text(
                p.nome,
                style: AppTextStyles.body.copyWith(
                  color: p.ativa
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _subtituloPizza(p),
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: p.ativa,
                    activeColor: AppColors.success,
                    onChanged: (v) async {
                      await PizzaService.toggleAtivaPizza(p.id, v);
                      _carregar();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        color: AppColors.textSecondary, size: 20),
                    onPressed: () => _abrirFormulario(p),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: AppColors.danger, size: 20),
                    onPressed: () => _confirmarDelete(p),
                    tooltip: 'Excluir',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _subtituloPizza(Pizza p) {
    final partes = <String>[p.tamanhoLabel];
    if (p.ingredientes?.trim().isNotEmpty == true) {
      partes.add(p.ingredientes!.trim());
    }
    if (p.preco != null) {
      partes.add(_currencyFmt.format(p.preco));
    }
    return partes.join(' • ');
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
  final _precoCtrl = TextEditingController();
  String _tamanho = 'grande';
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    if (widget.pizza != null) {
      _nomeCtrl.text = widget.pizza!.nome;
      _ingredientesCtrl.text = widget.pizza!.ingredientes ?? '';
      _tamanho = widget.pizza!.tamanho;
      if (widget.pizza!.preco != null) {
        _precoCtrl.text =
            widget.pizza!.preco!.toStringAsFixed(2).replaceAll('.', ',');
      }
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _ingredientesCtrl.dispose();
    _precoCtrl.dispose();
    super.dispose();
  }

  double? _parsePreco() {
    final texto = _precoCtrl.text.trim().replaceAll(',', '.');
    if (texto.isEmpty) return null;
    return double.tryParse(texto);
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
      preco: _parsePreco(),
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
    final tokens = context.appTheme;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.pizza == null ? 'Nova Pizza' : 'Editar Pizza',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nomeCtrl,
            decoration: InputDecoration(
              labelText: 'Nome do sabor',
              border: const OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_pizza, color: AppColors.warning),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ingredientesCtrl,
            decoration: InputDecoration(
              labelText: 'Ingredientes',
              border: const OutlineInputBorder(),
              prefixIcon:
                  Icon(Icons.list_alt, color: AppColors.textSecondary),
              hintText: 'Ex: queijo, molho de tomate, orégano',
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _precoCtrl,
            decoration: InputDecoration(
              labelText: 'Preço (opcional)',
              border: const OutlineInputBorder(),
              prefixIcon:
                  Icon(Icons.attach_money, color: AppColors.textSecondary),
              hintText: 'Ex: 45,00',
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          Text('Tamanho',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'grande',
                label: Text('Grande'),
                icon: Icon(Icons.circle),
              ),
              ButtonSegment(
                value: 'media',
                label: Text('Média'),
                icon: Icon(Icons.circle_outlined),
              ),
            ],
            selected: {_tamanho},
            onSelectionChanged: (s) => setState(() => _tamanho = s.first),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _salvando ? null : _salvar,
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: _salvando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
  }
}
