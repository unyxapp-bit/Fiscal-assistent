import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/formulario.dart';
import '../../providers/formulario_provider.dart';

/// Tela para preencher um formulário
class FormularioPreenchimentoScreen extends StatefulWidget {
  final Formulario formulario;

  const FormularioPreenchimentoScreen({
    super.key,
    required this.formulario,
  });

  @override
  State<FormularioPreenchimentoScreen> createState() =>
      _FormularioPreenchimentoScreenState();
}

class _FormularioPreenchimentoScreenState
    extends State<FormularioPreenchimentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final campo in widget.formulario.campos) {
      _controllers[campo] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _enviar() {
    if (!_formKey.currentState!.validate()) return;

    final valores = <String, dynamic>{};
    for (final entry in _controllers.entries) {
      valores[entry.key] = entry.value.text.trim();
    }

    final resposta = RespostaFormulario(
      id: const Uuid().v4(),
      formularioId: widget.formulario.id,
      valores: valores,
      preenchidoEm: DateTime.now(),
    );

    Provider.of<FormularioProvider>(context, listen: false)
        .adicionarResposta(resposta);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Formulário enviado com sucesso!'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.of(context).pop(true);
  }

  void _limpar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar formulário'),
        content: const Text('Deseja apagar todos os campos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              for (final c in _controllers.values) {
                c.clear();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(widget.formulario.titulo, style: AppTextStyles.h3),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _limpar,
            tooltip: 'Limpar',
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
              // Descrição do formulário
              if (widget.formulario.descricao.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Dimensions.paddingMD),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.description,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.formulario.template
                                ? 'Template Oficial'
                                : 'Formulário Personalizado',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.formulario.descricao,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.spacingLG),
              ],

              // Campos do formulário
              Text(
                '${widget.formulario.campos.length} campos para preencher',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: Dimensions.spacingMD),

              ...widget.formulario.campos.asMap().entries.map((entry) {
                final index = entry.key;
                final campo = entry.value;
                final controller = _controllers[campo]!;

                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: Dimensions.spacingMD),
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: campo,
                      hintText: 'Preencha "$campo"',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            '${index + 1}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Preencha "$campo"';
                      }
                      return null;
                    },
                  ),
                );
              }),

              const SizedBox(height: Dimensions.spacingLG),

              // Data/hora atual
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSM),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSection,
                  borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Preenchido em: ${_formatDateTime(DateTime.now())}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
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
                    child: ElevatedButton.icon(
                      onPressed: _enviar,
                      icon: const Icon(Icons.send),
                      label: const Text('Enviar'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(Dimensions.buttonHeight),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
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

  String _formatDateTime(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${dt.year} às $hora:$min';
  }
}
