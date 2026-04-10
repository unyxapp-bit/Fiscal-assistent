import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/formulario.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../providers/auth_provider.dart';
import '../../providers/evento_turno_provider.dart';
import '../../providers/formulario_provider.dart';
import '../../../core/utils/app_notif.dart';

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

  /// Valores para todos os campos (simNao Ã¢â€ â€™ 'Sim'/'NÃƒÂ£o'/null, opcoes Ã¢â€ â€™ String/null).
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
        title: Text('Limpar formulÃƒÂ¡rio'),
        content: Text('Deseja apagar todos os campos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
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
            child: Text('Limpar'),
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
    final eventoProvider =
        Provider.of<EventoTurnoProvider>(context, listen: false);
    if (eventoProvider.turnoAtivo) {
      final fiscalId =
          Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
      eventoProvider.registrar(
        fiscalId: fiscalId,
        tipo: TipoEvento.formularioRespondido,
        detalhe: widget.formulario.titulo,
      );
    }
    AppNotif.show(
      context,
      titulo: 'FormulÃƒÂ¡rio Enviado',
      mensagem: 'FormulÃƒÂ¡rio enviado com sucesso!',
      tipo: 'saida',
      cor: AppColors.success,
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
            icon: Icon(Icons.clear_all),
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
            // Banner descriÃƒÂ§ÃƒÂ£o
            if (widget.formulario.descricao.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.paddingMD),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          widget.formulario.template
                              ? 'Template Oficial'
                              : 'FormulÃƒÂ¡rio Personalizado',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(widget.formulario.descricao,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              SizedBox(height: Dimensions.spacingLG),
            ],

            Text(
              '${widget.formulario.campos.length} campos Ã¢â‚¬â€ todos opcionais',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: Dimensions.spacingMD),

            // Campos
            ...widget.formulario.campos.asMap().entries.map(
                  (e) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: Dimensions.spacingMD),
                    child: _buildCampo(e.key, e.value),
                  ),
                ),

            // Carimbo de data
            SizedBox(height: Dimensions.spacingSM),
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSM),
              decoration: BoxDecoration(
                color: AppColors.backgroundSection,
                borderRadius: BorderRadius.circular(Dimensions.radiusMD),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    'Preenchido em: ${_formatDateTime(DateTime.now())}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            SizedBox(height: Dimensions.spacingXL),

            // BotÃƒÂµes
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(Dimensions.buttonHeight),
                    ),
                    child: Text('Cancelar'),
                  ),
                ),
                SizedBox(width: Dimensions.spacingSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _enviar,
                    icon: Icon(Icons.send),
                    label: Text('Enviar'),
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(Dimensions.buttonHeight),
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
    const obrigLabel = '';

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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        '${index + 1}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$label$obrigLabel',
                        style: AppTextStyles.body,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SimNaoButton(
                        label: 'Sim',
                        icon: Icons.check_circle_outline,
                        selected: valor == 'Sim',
                        color: AppColors.success,
                        onTap: () => setState(() => _valores[label] = 'Sim'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _SimNaoButton(
                        label: 'NÃƒÂ£o',
                        icon: Icons.cancel_outlined,
                        selected: valor == 'NÃƒÂ£o',
                        color: AppColors.danger,
                        onTap: () => setState(() => _valores[label] = 'NÃƒÂ£o'),
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
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        '${index + 1}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$label$obrigLabel',
                        style: AppTextStyles.body,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: valor,
                  onChanged: (v) => setState(() => _valores[label] = v),
                  child: Column(
                    children: campo.opcoes
                        .map(
                          (opcao) => RadioListTile<String>(
                            value: opcao,
                            title: Text(opcao),
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        )
                        .toList(),
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
    return '$dia/$mes/${dt.year} ÃƒÂ s $hora:$min';
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ BotÃƒÂ£o Sim/NÃƒÂ£o Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

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
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
