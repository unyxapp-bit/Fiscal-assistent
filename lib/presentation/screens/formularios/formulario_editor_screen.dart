import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/formulario.dart';
import '../../providers/formulario_provider.dart';

/// Tela de criação/edição de formulário personalizado
class FormularioEditorScreen extends StatefulWidget {
  final Formulario? formulario; // null = novo

  const FormularioEditorScreen({super.key, this.formulario});

  @override
  State<FormularioEditorScreen> createState() => _FormularioEditorScreenState();
}

class _FormularioEditorScreenState extends State<FormularioEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final List<TextEditingController> _camposControllers = [];

  bool get _isEdicao => widget.formulario != null;

  @override
  void initState() {
    super.initState();
    if (_isEdicao) {
      _tituloController.text = widget.formulario!.titulo;
      _descricaoController.text = widget.formulario!.descricao;
      for (final campo in widget.formulario!.campos) {
        _camposControllers.add(TextEditingController(text: campo));
      }
    }
    // Pelo menos 1 campo inicial
    if (_camposControllers.isEmpty) {
      _camposControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    for (final c in _camposControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _adicionarCampo() {
    setState(() {
      _camposControllers.add(TextEditingController());
    });
  }

  void _removerCampo(int index) {
    if (_camposControllers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O formulário precisa ter pelo menos 1 campo')),
      );
      return;
    }
    setState(() {
      _camposControllers[index].dispose();
      _camposControllers.removeAt(index);
    });
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final campos = _camposControllers
        .map((c) => c.text.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    if (campos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos 1 campo')),
      );
      return;
    }

    final provider = Provider.of<FormularioProvider>(context, listen: false);
    final now = DateTime.now();

    if (_isEdicao) {
      final atualizado = widget.formulario!.copyWith(
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        campos: campos,
        updatedAt: now,
      );
      provider.atualizarFormulario(atualizado);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formulário atualizado!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final novo = Formulario(
        id: const Uuid().v4(),
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        campos: campos,
        createdAt: now,
        updatedAt: now,
      );
      provider.adicionarFormulario(novo);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formulário criado!'),
          backgroundColor: AppColors.success,
        ),
      );
    }

    Navigator.of(context).pop(true);
  }

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
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título do Formulário *',
                  hintText: 'Ex: Checklist de Abertura',
                  prefixIcon: Icon(Icons.title),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Título obrigatório' : null,
              ),

              const SizedBox(height: Dimensions.spacingMD),

              // Descrição
              TextFormField(
                controller: _descricaoController,
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

              // Campos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Campos (${_camposControllers.length})',
                    style: AppTextStyles.h4,
                  ),
                  TextButton.icon(
                    onPressed: _adicionarCampo,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.spacingSM),

              // Lista de campos
              ...List.generate(_camposControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.spacingSM),
                  child: Row(
                    children: [
                      // Número do campo
                      Container(
                        width: 32,
                        height: 32,
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
                          ),
                        ),
                      ),
                      const SizedBox(width: Dimensions.spacingSM),

                      // Campo de texto
                      Expanded(
                        child: TextFormField(
                          controller: _camposControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Nome do campo ${index + 1}',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),

                      // Remover
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: AppColors.danger,
                          size: 20,
                        ),
                        onPressed: () => _removerCampo(index),
                        tooltip: 'Remover campo',
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: Dimensions.spacingMD),

              // Dica
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSM),
                decoration: BoxDecoration(
                  color: AppColors.alertInfo,
                  borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cada campo será um item a ser preenchido quando o formulário for usado',
                        style: AppTextStyles.caption.copyWith(color: AppColors.info),
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
                        minimumSize: const Size.fromHeight(Dimensions.buttonHeight),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _salvar,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(Dimensions.buttonHeight),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isEdicao ? 'Salvar' : 'Criar'),
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
