import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/procedimento_provider.dart';

/// Tela de Formulário de Procedimento
/// Permite criar ou editar um procedimento
class ProcedimentoFormScreen extends StatefulWidget {
  final Procedimento? procedimento; // Null para novo, preenchido para edição

  const ProcedimentoFormScreen({
    super.key,
    this.procedimento,
  });

  @override
  State<ProcedimentoFormScreen> createState() => _ProcedimentoFormScreenState();
}

class _ProcedimentoFormScreenState extends State<ProcedimentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _tempoEstimadoController = TextEditingController();

  String _categoriaSelecionada = 'rotina';
  bool _favorito = false;
  final List<TextEditingController> _passosControllers = [];

  final List<Map<String, String>> _categorias = [
    {'value': 'abertura', 'label': 'Abertura'},
    {'value': 'fechamento', 'label': 'Fechamento'},
    {'value': 'emergencia', 'label': 'Emergência'},
    {'value': 'rotina', 'label': 'Rotina'},
    {'value': 'fiscal', 'label': 'Fiscal'},
    {'value': 'caixa', 'label': 'Caixa'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.procedimento != null) {
      _tituloController.text = widget.procedimento!.titulo;
      _descricaoController.text = widget.procedimento!.descricao;
      _categoriaSelecionada = widget.procedimento!.categoria;
      _favorito = widget.procedimento!.favorito;
      _tempoEstimadoController.text =
          widget.procedimento!.tempoEstimado?.toString() ?? '';

      // Carregar passos
      for (var passo in widget.procedimento!.passos) {
        final controller = TextEditingController(text: passo);
        _passosControllers.add(controller);
      }
    } else {
      // Adicionar um passo inicial vazio para novos procedimentos
      _passosControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _tempoEstimadoController.dispose();
    for (var controller in _passosControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _adicionarPasso() {
    setState(() {
      _passosControllers.add(TextEditingController());
    });
  }

  void _removerPasso(int index) {
    if (_passosControllers.length > 1) {
      setState(() {
        _passosControllers[index].dispose();
        _passosControllers.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deve haver pelo menos 1 passo'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    // Validar passos
    final passos = _passosControllers
        .map((c) => c.text.trim())
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

    final provider = Provider.of<ProcedimentoProvider>(context, listen: false);

    if (widget.procedimento == null) {
      // Criar novo procedimento
      provider.adicionarProcedimento(
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        categoria: _categoriaSelecionada,
        passos: passos,
        tempoEstimado: int.tryParse(_tempoEstimadoController.text),
      );

      // Se marcado como favorito, adicionar aos favoritos
      if (_favorito) {
        final procedimentos = provider.procedimentos;
        if (procedimentos.isNotEmpty) {
          provider.toggleFavorito(procedimentos.last.id);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Procedimento criado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      // Editar procedimento existente
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
              // Título
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  hintText: 'Ex: Emissão de Nota Fiscal',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Título é obrigatório';
                  }
                  return null;
                },
              ),

              const SizedBox(height: Dimensions.spacingLG),

              // Descrição
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

              // Categoria (Dropdown)
              DropdownButtonFormField<String>(
                initialValue: _categoriaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Categoria *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categorias.map((cat) {
                  return DropdownMenuItem(
                    value: cat['value'],
                    child: Text(cat['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _categoriaSelecionada = value);
                  }
                },
              ),

              const SizedBox(height: Dimensions.spacingLG),

              // Tempo Estimado
              TextFormField(
                controller: _tempoEstimadoController,
                decoration: const InputDecoration(
                  labelText: 'Tempo Estimado (minutos)',
                  hintText: 'Ex: 15',
                  prefixIcon: Icon(Icons.timer),
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: Dimensions.spacingLG),

              // Favorito (Checkbox)
              Card(
                child: CheckboxListTile(
                  value: _favorito,
                  onChanged: (value) => setState(() => _favorito = value ?? false),
                  title: const Text('Marcar como favorito'),
                  secondary: Icon(
                    _favorito ? Icons.star : Icons.star_outline,
                    color: _favorito ? Colors.orange : AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: Dimensions.spacingXL),

              // Passos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Passos *', style: AppTextStyles.h4),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                    onPressed: _adicionarPasso,
                    tooltip: 'Adicionar passo',
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.spacingSM),

              // Lista de passos
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _passosControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Dimensions.spacingSM),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              '${index + 1}',
                              style: AppTextStyles.label.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Dimensions.spacingSM),

                        // Campo de texto do passo
                        Expanded(
                          child: TextFormField(
                            controller: _passosControllers[index],
                            decoration: InputDecoration(
                              hintText: 'Digite o passo ${index + 1}',
                              suffixIcon: _passosControllers.length > 1
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        color: AppColors.danger,
                                      ),
                                      onPressed: () => _removerPasso(index),
                                    )
                                  : null,
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: Dimensions.spacingXL),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _salvar,
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
