import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/formulario.dart';
import '../../providers/formulario_provider.dart';

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
  /// Controladores de texto para campos do tipo texto/numero.
  final Map<String, TextEditingController> _textCtrls = {};

  /// Valores para todos os campos (simNao → 'Sim'/'Não'/null, opcoes → String/null).
  final Map<String, dynamic> _valores = {};

  @override
  void initState() {
    super.initState();
    for (final campo in widget.formulario.campos) {
      if (campo.tipo == TipoCampo.texto || campo.tipo == TipoCampo.numero) {
        _textCtrls[campo.label] = TextEditingController();
      }
      _valores[campo.label] = null;
    }
  }

  @override
  void dispose() {
    for (final c in _textCtrls.values) {
      c.dispose();
    }
    super.dispose();
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
              setState(() {
                for (final c in _textCtrls.values) {
                  c.clear();
                }
                for (final key in _valores.keys) {
                  _valores[key] = null;
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  void _enviar() {
    // Coletar valores de texto/numero
    for (final campo in widget.formulario.campos) {
      if (campo.tipo == TipoCampo.texto || campo.tipo == TipoCampo.numero) {
        _valores[campo.label] = _textCtrls[campo.label]!.text.trim();
      }
    }

    // Salvar
    final resposta = RespostaFormulario(
      id: const Uuid().v4(),
      formularioId: widget.formulario.id,
      valores: Map<String, dynamic>.from(_valores),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner descrição
            if (widget.formulario.descricao.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.paddingMD),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusMD),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description,
                            color: AppColors.primary, size: 18),
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
                    Text(widget.formulario.descricao,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.spacingLG),
            ],

            Text(
              '${widget.formulario.campos.length} campos — todos opcionais',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: Dimensions.spacingMD),

            // Campos
            ...widget.formulario.campos.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(
                        bottom: Dimensions.spacingMD),
                    child: _buildCampo(e.key, e.value),
                  ),
                ),

            // Carimbo de data
            const SizedBox(height: Dimensions.spacingSM),
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSM),
              decoration: BoxDecoration(
                color: AppColors.backgroundSection,
                borderRadius:
                    BorderRadius.circular(Dimensions.radiusMD),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Preenchido em: ${_formatDateTime(DateTime.now())}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
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
                  child: ElevatedButton.icon(
                    onPressed: _enviar,
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                          Dimensions.buttonHeight),
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
    );
  }

  Widget _buildCampo(int index, CampoFormulario campo) {
    final label = campo.label;
    final obrigLabel = campo.obrigatorio ? ' *' : ' (opcional)';

    switch (campo.tipo) {
      case TipoCampo.texto:
        return TextFormField(
          controller: _textCtrls[label],
          decoration: InputDecoration(
            labelText: '$label$obrigLabel',
            hintText: 'Preencha "$label"',
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
        );

      case TipoCampo.numero:
        return TextFormField(
          controller: _textCtrls[label],
          decoration: InputDecoration(
            labelText: '$label$obrigLabel',
            hintText: '0',
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
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
        );

      case TipoCampo.simNao:
        final valor = _valores[label] as String?;
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        '${index + 1}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$label$obrigLabel',
                        style: AppTextStyles.body,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SimNaoButton(
                        label: 'Sim',
                        icon: Icons.check_circle_outline,
                        selected: valor == 'Sim',
                        color: AppColors.success,
                        onTap: () => setState(
                            () => _valores[label] = 'Sim'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SimNaoButton(
                        label: 'Não',
                        icon: Icons.cancel_outlined,
                        selected: valor == 'Não',
                        color: AppColors.danger,
                        onTap: () => setState(
                            () => _valores[label] = 'Não'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

      case TipoCampo.opcoes:
        final valor = _valores[label] as String?;
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        '${index + 1}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$label$obrigLabel',
                        style: AppTextStyles.body,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...campo.opcoes.map(
                  (opcao) => RadioListTile<String>(
                    value: opcao,
                    groupValue: valor,
                    title: Text(opcao),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (v) =>
                        setState(() => _valores[label] = v),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  String _formatDateTime(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${dt.year} às $hora:$min';
  }
}

// ── Botão Sim/Não ─────────────────────────────────────────────────────────────

class _SimNaoButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SimNaoButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusMD),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: selected ? color : AppColors.inactive,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(Dimensions.radiusMD),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : AppColors.inactive, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.textSecondary,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
