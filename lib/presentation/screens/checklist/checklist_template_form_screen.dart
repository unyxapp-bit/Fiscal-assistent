import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/checklist_provider.dart';

class ChecklistTemplateFormScreen extends StatefulWidget {
  final ChecklistTemplate? template; // null = novo

  const ChecklistTemplateFormScreen({super.key, this.template});

  @override
  State<ChecklistTemplateFormScreen> createState() =>
      _ChecklistTemplateFormScreenState();
}

class _ChecklistTemplateFormScreenState
    extends State<ChecklistTemplateFormScreen> {
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late String _iconeKey;
  late String _corHex;
  late List<String> _itens;
  final List<TextEditingController> _itemCtrls = [];

  bool get _editando => widget.template != null;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _tituloCtrl.text = t?.titulo ?? '';
    _descCtrl.text = t?.descricao ?? '';
    _iconeKey = t?.iconeKey ?? kChecklistIcones.first.$1;
    _corHex = t?.corHex ?? '4CAF50';
    _itens = List<String>.from(t?.itens ?? ['']);
    _syncControllers();
  }

  void _syncControllers() {
    // Dispose extras
    for (final c in _itemCtrls) {
      c.dispose();
    }
    _itemCtrls.clear();
    for (final item in _itens) {
      _itemCtrls.add(TextEditingController(text: item));
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    for (final c in _itemCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _itens.add('');
      _itemCtrls.add(TextEditingController());
    });
  }

  void _removeItem(int index) {
    if (_itens.length <= 1) return;
    setState(() {
      _itemCtrls[index].dispose();
      _itens.removeAt(index);
      _itemCtrls.removeAt(index);
    });
  }

  void _salvar() {
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um título para o checklist')),
      );
      return;
    }
    final itens = _itemCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Adicione pelo menos um item ao checklist')),
      );
      return;
    }

    final provider = Provider.of<ChecklistProvider>(context, listen: false);

    if (_editando) {
      final atualizado = widget.template!.copyWith(
        titulo: titulo,
        descricao: _descCtrl.text.trim(),
        iconeKey: _iconeKey,
        corHex: _corHex,
        itens: itens,
      );
      provider.atualizarTemplate(atualizado);
    } else {
      final novo = ChecklistTemplate(
        id: const Uuid().v4(),
        titulo: titulo,
        descricao: _descCtrl.text.trim(),
        iconeKey: _iconeKey,
        corHex: _corHex,
        itens: itens,
        createdAt: DateTime.now(),
      );
      provider.adicionarTemplate(novo);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:
            Text(_editando ? 'Editar Checklist' : 'Novo Checklist'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _salvar,
            child: Text(
              'Salvar',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Título ────────────────────────────────────────────────────
            TextField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(
                labelText: 'Título *',
                hintText: 'Ex: Checklist de Limpeza',
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: Dimensions.spacingMD),

            // ── Descrição ─────────────────────────────────────────────────
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Breve descrição do checklist',
                prefixIcon: Icon(Icons.notes),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: Dimensions.spacingLG),

            // ── Cor ───────────────────────────────────────────────────────
            Text('Cor', style: AppTextStyles.h4),
            const SizedBox(height: Dimensions.spacingSM),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kChecklistCores.map((c) {
                final hex =
                    c.toARGB32().toRadixString(16).substring(2).toUpperCase();
                final sel = _corHex == hex;
                return GestureDetector(
                  onTap: () => setState(() => _corHex = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: sel
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                  color: c.withValues(alpha: 0.5),
                                  blurRadius: 8)
                            ]
                          : null,
                    ),
                    child: sel
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: Dimensions.spacingLG),

            // ── Ícone ─────────────────────────────────────────────────────
            Text('Ícone', style: AppTextStyles.h4),
            const SizedBox(height: Dimensions.spacingSM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kChecklistIcones.map((entry) {
                final sel = _iconeKey == entry.$1;
                final cor = Color(int.parse('FF$_corHex', radix: 16));
                return GestureDetector(
                  onTap: () => setState(() => _iconeKey = entry.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: sel
                          ? cor.withValues(alpha: 0.15)
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                      border: Border.all(
                        color: sel ? cor : AppColors.cardBorder,
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(entry.$2,
                            color: sel ? cor : AppColors.textSecondary,
                            size: 20),
                        const SizedBox(height: 2),
                        Text(
                          entry.$3,
                          style: TextStyle(
                            fontSize: 8,
                            color: sel ? cor : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: Dimensions.spacingLG),

            // ── Itens ─────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Itens do checklist', style: AppTextStyles.h4),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Adicionar'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.spacingSM),

            ...List.generate(_itemCtrls.length, (i) {
              return Padding(
                padding:
                    const EdgeInsets.only(bottom: Dimensions.spacingSM),
                child: Row(
                  children: [
                    // Número
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(int.parse('FF$_corHex', radix: 16))
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              Color(int.parse('FF$_corHex', radix: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Campo
                    Expanded(
                      child: TextField(
                        controller: _itemCtrls[i],
                        decoration: InputDecoration(
                          hintText: 'Item ${i + 1}',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    // Remover
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: AppColors.danger, size: 20),
                      onPressed: _itens.length > 1
                          ? () => _removeItem(i)
                          : null,
                      tooltip: 'Remover item',
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: Dimensions.spacingXL),

            // ── Botão salvar ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvar,
                icon: const Icon(Icons.save),
                label: Text(_editando ? 'Salvar alterações' : 'Criar checklist'),
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(Dimensions.buttonHeight),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: Dimensions.spacingMD),
          ],
        ),
      ),
    );
  }
}
