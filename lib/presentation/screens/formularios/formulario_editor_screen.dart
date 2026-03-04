import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/formulario.dart';
import '../../providers/formulario_provider.dart';

// ── Estado interno de cada campo ──────────────────────────────────────────────

class _CampoState {
  final String id;
  final TextEditingController labelCtrl;
  TipoCampo tipo;
  bool obrigatorio;
  final List<TextEditingController> opcoesCtrl;

  _CampoState({
    required this.id,
    required this.labelCtrl,
    this.tipo = TipoCampo.texto,
    this.obrigatorio = true,
    List<TextEditingController>? opcoesCtrl,
  }) : opcoesCtrl = opcoesCtrl ?? [];

  void dispose() {
    labelCtrl.dispose();
    for (final c in opcoesCtrl) {
      c.dispose();
    }
  }

  CampoFormulario toCampo() => CampoFormulario(
        id: id,
        label: labelCtrl.text.trim(),
        tipo: tipo,
        obrigatorio: obrigatorio,
        opcoes: opcoesCtrl
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
}

// ── Editor ────────────────────────────────────────────────────────────────────

class FormularioEditorScreen extends StatefulWidget {
  final Formulario? formulario;

  const FormularioEditorScreen({super.key, this.formulario});

  @override
  State<FormularioEditorScreen> createState() => _FormularioEditorScreenState();
}

class _FormularioEditorScreenState extends State<FormularioEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final List<_CampoState> _campos = [];

  bool get _isEdicao => widget.formulario != null;

  @override
  void initState() {
    super.initState();
    if (_isEdicao) {
      _tituloCtrl.text = widget.formulario!.titulo;
      _descricaoCtrl.text = widget.formulario!.descricao;
      for (final c in widget.formulario!.campos) {
        _campos.add(_CampoState(
          id: c.id,
          labelCtrl: TextEditingController(text: c.label),
          tipo: c.tipo,
          obrigatorio: c.obrigatorio,
          opcoesCtrl: c.opcoes
              .map((o) => TextEditingController(text: o))
              .toList(),
        ));
      }
    }
    if (_campos.isEmpty) {
      _adicionarCampo();
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    for (final c in _campos) {
      c.dispose();
    }
    super.dispose();
  }

  void _adicionarCampo() {
    setState(() {
      _campos.add(_CampoState(
        id: const Uuid().v4(),
        labelCtrl: TextEditingController(),
      ));
    });
  }

  void _removerCampo(int index) {
    if (_campos.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('O formulário precisa ter pelo menos 1 campo')),
      );
      return;
    }
    setState(() {
      _campos[index].dispose();
      _campos.removeAt(index);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _campos.removeAt(oldIndex);
      _campos.insert(newIndex, item);
    });
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final campos = _campos
        .map((c) => c.toCampo())
        .where((c) => c.label.isNotEmpty)
        .toList();

    if (campos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos 1 campo')),
      );
      return;
    }

    // Valida campos de opcoes: pelo menos 2 opções
    for (final c in campos) {
      if (c.tipo == TipoCampo.opcoes && c.opcoes.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Campo "${c.label}": adicione pelo menos 2 opções')),
        );
        return;
      }
    }

    final provider = Provider.of<FormularioProvider>(context, listen: false);
    final now = DateTime.now();

    if (_isEdicao) {
      provider.atualizarFormulario(widget.formulario!.copyWith(
        titulo: _tituloCtrl.text.trim(),
        descricao: _descricaoCtrl.text.trim(),
        campos: campos,
        updatedAt: now,
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Formulário atualizado!'),
            backgroundColor: AppColors.success),
      );
    } else {
      provider.adicionarFormulario(Formulario(
        id: const Uuid().v4(),
        titulo: _tituloCtrl.text.trim(),
        descricao: _descricaoCtrl.text.trim(),
        campos: campos,
        createdAt: now,
        updatedAt: now,
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Formulário criado!'),
            backgroundColor: AppColors.success),
      );
    }

    Navigator.of(context).pop(true);
  }

  // ── Tipo seletor ────────────────────────────────────────────────────────────

  void _selecionarTipo(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Tipo do campo', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            ...TipoCampo.values.map((tipo) => ListTile(
                  leading: Icon(tipo.icone, color: AppColors.primary),
                  title: Text(tipo.nome),
                  subtitle: Text(_tipoDescricao(tipo),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                  selected: _campos[index].tipo == tipo,
                  selectedColor: AppColors.primary,
                  onTap: () {
                    setState(() {
                      _campos[index].tipo = tipo;
                      if (tipo == TipoCampo.opcoes &&
                          _campos[index].opcoesCtrl.isEmpty) {
                        _campos[index].opcoesCtrl
                            .add(TextEditingController());
                        _campos[index].opcoesCtrl
                            .add(TextEditingController());
                      }
                    });
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  String _tipoDescricao(TipoCampo tipo) {
    switch (tipo) {
      case TipoCampo.texto:
        return 'Campo de texto livre';
      case TipoCampo.simNao:
        return 'Resposta Sim ou Não';
      case TipoCampo.numero:
        return 'Valor numérico';
      case TipoCampo.opcoes:
        return 'Selecionar uma das opções';
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _isEdicao ? 'Editar Formulário' : 'Novo Formulário',
          style: AppTextStyles.h3,
        ),
        actions: [
          TextButton(
            onPressed: _salvar,
            child: const Text(
              'Salvar',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Título
                  TextFormField(
                    controller: _tituloCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título do Formulário *',
                      hintText: 'Ex: Checklist de Abertura',
                      prefixIcon: Icon(Icons.title),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Título obrigatório'
                        : null,
                  ),
                  const SizedBox(height: Dimensions.spacingMD),

                  // Descrição
                  TextFormField(
                    controller: _descricaoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Para que serve este formulário?',
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: Dimensions.spacingLG),

                  // Header campos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Campos (${_campos.length})',
                        style: AppTextStyles.h4,
                      ),
                      TextButton.icon(
                        onPressed: _adicionarCampo,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Adicionar'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spacingSM),
                ]),
              ),
            ),

            // Lista reordenável
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingMD),
              sliver: SliverReorderableList(
                itemCount: _campos.length,
                onReorder: _onReorder,
                itemBuilder: (ctx, index) =>
                    _buildCampoItem(index),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: Dimensions.spacingSM),

                  // Dica
                  Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSM),
                    decoration: BoxDecoration(
                      color: AppColors.alertInfo,
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusMD),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.info, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Arraste ≡ para reordenar campos. Campos Sim/Não e Opções facilitam checklists.',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.info),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimensions.spacingXL),

                  // Botões
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                                Dimensions.buttonHeight),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: Dimensions.spacingSM),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _salvar,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                                Dimensions.buttonHeight),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(_isEdicao ? 'Salvar' : 'Criar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spacingLG),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoItem(int index) {
    final campo = _campos[index];
    return ReorderableDelayedDragStartListener(
      key: ValueKey(campo.id),
      index: index,
      child: Card(
        margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  // Drag handle
                  const Icon(Icons.drag_handle,
                      color: AppColors.inactive, size: 20),
                  const SizedBox(width: 8),

                  // Número
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Label
                  Expanded(
                    child: TextFormField(
                      controller: campo.labelCtrl,
                      decoration: InputDecoration(
                        hintText: 'Nome do campo ${index + 1}',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Tipo
                  InkWell(
                    onTap: () => _selecionarTipo(index),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(campo.tipo.icone,
                              color: AppColors.primary, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            campo.tipo.nome,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Obrigatório toggle
                  Tooltip(
                    message: campo.obrigatorio ? 'Obrigatório' : 'Opcional',
                    child: InkWell(
                      onTap: () => setState(
                          () => campo.obrigatorio = !campo.obrigatorio),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          campo.obrigatorio
                              ? Icons.lock
                              : Icons.lock_open,
                          size: 16,
                          color: campo.obrigatorio
                              ? AppColors.danger
                              : AppColors.inactive,
                        ),
                      ),
                    ),
                  ),

                  // Remover
                  InkWell(
                    onTap: () => _removerCampo(index),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close,
                          size: 16, color: AppColors.danger),
                    ),
                  ),
                ],
              ),

              // Sub-lista de opções (apenas quando tipo == opcoes)
              if (campo.tipo == TipoCampo.opcoes) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 6),
                ...campo.opcoesCtrl.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const SizedBox(width: 36),
                          const Icon(Icons.radio_button_unchecked,
                              size: 14, color: AppColors.inactive),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: e.value,
                              decoration: InputDecoration(
                                hintText: 'Opção ${e.key + 1}',
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                              ),
                              textCapitalization:
                                  TextCapitalization.sentences,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 16, color: AppColors.danger),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: campo.opcoesCtrl.length > 2
                                ? () => setState(() {
                                      campo.opcoesCtrl[e.key]
                                          .dispose();
                                      campo.opcoesCtrl.removeAt(e.key);
                                    })
                                : null,
                          ),
                        ],
                      ),
                    )),
                TextButton.icon(
                  onPressed: () => setState(() {
                    campo.opcoesCtrl.add(TextEditingController());
                  }),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Adicionar opção',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.only(left: 36),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
