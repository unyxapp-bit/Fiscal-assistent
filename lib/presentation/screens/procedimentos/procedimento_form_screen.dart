import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/procedimento_provider.dart';

// Entrada interna para cada passo (chave única + controller)
class _PassoEntry {
  final Key key = UniqueKey();
  final TextEditingController controller;

  _PassoEntry(String text) : controller = TextEditingController(text: text);
  _PassoEntry.empty() : controller = TextEditingController();

  void dispose() => controller.dispose();
}

class ProcedimentoFormScreen extends StatefulWidget {
  final Procedimento? procedimento;

  const ProcedimentoFormScreen({
    super.key,
    this.procedimento,
  });

  @override
  State<ProcedimentoFormScreen> createState() =>
      _ProcedimentoFormScreenState();
}

class _ProcedimentoFormScreenState extends State<ProcedimentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _tempoEstimadoController = TextEditingController();

  String _categoriaSelecionada = 'rotina';
  bool _favorito = false;
  final List<_PassoEntry> _passos = [];

  static const _categorias = [
    ('abertura', 'Abertura'),
    ('fechamento', 'Fechamento'),
    ('emergencia', 'Emergência'),
    ('rotina', 'Rotina'),
    ('fiscal', 'Fiscal'),
    ('caixa', 'Caixa'),
  ];

  @override
  void initState() {
    super.initState();
    final proc = widget.procedimento;
    if (proc != null) {
      _tituloController.text = proc.titulo;
      _descricaoController.text = proc.descricao;
      _categoriaSelecionada = proc.categoria;
      _favorito = proc.favorito;
      _tempoEstimadoController.text =
          proc.tempoEstimado?.toString() ?? '';
      for (final passo in proc.passos) {
        _passos.add(_PassoEntry(passo));
      }
    } else {
      _passos.add(_PassoEntry.empty());
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _tempoEstimadoController.dispose();
    for (final entry in _passos) {
      entry.dispose();
    }
    super.dispose();
  }

  void _adicionarPasso() {
    setState(() => _passos.add(_PassoEntry.empty()));
  }

  void _removerPasso(int index) {
    if (_passos.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deve haver pelo menos 1 passo'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() {
      _passos[index].dispose();
      _passos.removeAt(index);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final entry = _passos.removeAt(oldIndex);
      _passos.insert(newIndex, entry);
    });
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final passos = _passos
        .map((e) => e.controller.text.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (passos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos 1 passo'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final provider =
        Provider.of<ProcedimentoProvider>(context, listen: false);

    if (widget.procedimento == null) {
      // Favorito passado diretamente na criação (sem toggleFavorito)
      provider.adicionarProcedimento(
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        categoria: _categoriaSelecionada,
        passos: passos,
        tempoEstimado: int.tryParse(_tempoEstimadoController.text),
        favorito: _favorito,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Procedimento criado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      provider.editarProcedimento(
        id: widget.procedimento!.id,
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        categoria: _categoriaSelecionada,
        passos: passos,
        tempoEstimado: int.tryParse(_tempoEstimadoController.text),
        favorito: _favorito,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Procedimento atualizado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNovo = widget.procedimento == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          isNovo ? 'Novo Procedimento' : 'Editar Procedimento',
          style: AppTextStyles.h3,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Título ─────────────────────────────────────────────────
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  hintText: 'Ex: Emissão de Nota Fiscal',
                  prefixIcon: Icon(Icons.title),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Título é obrigatório';
                  }
                  return null;
                },
              ),

              const SizedBox(height: Dimensions.spacingLG),

              // ── Descrição ───────────────────────────────────────────────
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Breve descrição do procedimento',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),

              const SizedBox(height: Dimensions.spacingLG),

              // ── Categoria ───────────────────────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: _categoriaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Categoria *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categorias.map((cat) {
                  return DropdownMenuItem(
                    value: cat.$1,
                    child: Row(
                      children: [
                        Icon(cat.$1.categoriaIcon,
                            size: 16,
                            color: cat.$1.categoriaColor),
                        const SizedBox(width: 8),
                        Text(cat.$2),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _categoriaSelecionada = value);
                  }
                },
              ),

              const SizedBox(height: Dimensions.spacingLG),

              // ── Tempo estimado ──────────────────────────────────────────
              TextFormField(
                controller: _tempoEstimadoController,
                decoration: const InputDecoration(
                  labelText: 'Tempo estimado (minutos)',
                  hintText: 'Ex: 15',
                  prefixIcon: Icon(Icons.timer),
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: Dimensions.spacingLG),

              // ── Favorito ───────────────────────────────────────────────
              Card(
                child: CheckboxListTile(
                  value: _favorito,
                  onChanged: (v) =>
                      setState(() => _favorito = v ?? false),
                  title: const Text('Marcar como favorito'),
                  secondary: Icon(
                    _favorito ? Icons.star : Icons.star_outline,
                    color: _favorito
                        ? Colors.orange
                        : AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: Dimensions.spacingXL),

              // ── Passos (reordenáveis) ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Passos *', style: AppTextStyles.h4),
                  IconButton(
                    icon: const Icon(Icons.add_circle,
                        color: AppColors.primary),
                    onPressed: _adicionarPasso,
                    tooltip: 'Adicionar passo',
                  ),
                ],
              ),
              Text(
                'Segure e arraste ≡ para reordenar',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: Dimensions.spacingSM),

              // ReorderableListView com shrinkWrap dentro do scroll pai
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: _onReorder,
                children: [
                  for (int i = 0; i < _passos.length; i++)
                    Padding(
                      key: _passos[i].key,
                      padding: const EdgeInsets.only(
                          bottom: Dimensions.spacingSM),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle de arraste
                          ReorderableDragStartListener(
                            index: i,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 16, right: 4),
                              child: Icon(Icons.drag_handle,
                                  color: AppColors.inactive),
                            ),
                          ),

                          // Número do passo
                          Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(top: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: AppTextStyles.label.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: Dimensions.spacingSM),

                          // Campo de texto
                          Expanded(
                            child: TextFormField(
                              controller: _passos[i].controller,
                              decoration: InputDecoration(
                                hintText: 'Digite o passo ${i + 1}',
                                suffixIcon: _passos.length > 1
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: AppColors.danger,
                                        ),
                                        onPressed: () => _removerPasso(i),
                                      )
                                    : null,
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: Dimensions.spacingXL),

              // ── Botões ─────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(Dimensions.buttonHeight),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _salvar,
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(Dimensions.buttonHeight),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isNovo ? 'Criar' : 'Salvar'),
                    ),
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
