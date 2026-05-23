import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_notif.dart';
import '../../../core/utils/desconto_calculator.dart';

class DescontoCalculatorScreen extends StatefulWidget {
  const DescontoCalculatorScreen({super.key});

  @override
  State<DescontoCalculatorScreen> createState() =>
      _DescontoCalculatorScreenState();
}

class _DescontoCalculatorScreenState extends State<DescontoCalculatorScreen> {
  final _etiquetaCtrl = TextEditingController();
  final _sistemaCtrl = TextEditingController();
  final _quantidadeCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _etiquetaCtrl.dispose();
    _sistemaCtrl.dispose();
    _quantidadeCtrl.dispose();
    super.dispose();
  }

  DescontoResultado? get _resultado {
    final etiqueta = DescontoCalculator.parseMoneyToCents(_etiquetaCtrl.text);
    final sistema = DescontoCalculator.parseMoneyToCents(_sistemaCtrl.text);
    if (etiqueta == null || sistema == null) return null;

    return DescontoCalculator.calcular(
      etiquetaCentavos: etiqueta,
      sistemaCentavos: sistema,
      quantidade: DescontoCalculator.parseQuantidade(_quantidadeCtrl.text),
    );
  }

  void _preencherExemplo() {
    setState(() {
      _etiquetaCtrl.text = '16,99';
      _sistemaCtrl.text = '14,99';
      _quantidadeCtrl.text = '1';
    });
  }

  void _limpar() {
    setState(() {
      _etiquetaCtrl.clear();
      _sistemaCtrl.clear();
      _quantidadeCtrl.text = '1';
    });
  }

  Future<void> _copiarDesconto() async {
    final resultado = _resultado;
    if (resultado == null || resultado.valoresIguais) {
      AppNotif.show(
        context,
        titulo: 'Sem desconto',
        mensagem: 'Preencha valores diferentes para copiar.',
        tipo: 'alerta',
        cor: AppColors.warning,
      );
      return;
    }

    final valor = resultado.quantidade > 1
        ? resultado.descontoTotalCentavos
        : resultado.descontoUnitarioCentavos;
    await Clipboard.setData(
      ClipboardData(text: DescontoCalculator.formatMoney(valor)),
    );

    if (!mounted) return;
    AppNotif.show(
      context,
      titulo: 'Desconto copiado',
      mensagem: '${DescontoCalculator.formatMoney(valor)} copiado.',
      tipo: 'saida',
      cor: AppColors.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultado = _resultado;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calculadora de desconto'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Exemplo',
            onPressed: _preencherExemplo,
            icon: const Icon(Icons.auto_fix_high_rounded),
          ),
          IconButton(
            tooltip: 'Limpar',
            onPressed: _limpar,
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.hPad(constraints.maxWidth),
              vertical: Dimensions.paddingMD,
            ),
            children: [
              _ResultCard(resultado: resultado),
              const SizedBox(height: Dimensions.spacingMD),
              _InputCard(
                etiquetaCtrl: _etiquetaCtrl,
                sistemaCtrl: _sistemaCtrl,
                quantidadeCtrl: _quantidadeCtrl,
                onChanged: () => setState(() {}),
                onExample: _preencherExemplo,
                onClear: _limpar,
              ),
              const SizedBox(height: Dimensions.spacingMD),
              _ResumoCard(resultado: resultado),
              const SizedBox(height: Dimensions.spacingMD),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _copiarDesconto,
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copiar desconto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(Dimensions.buttonBorderRadius),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final DescontoResultado? resultado;

  const _ResultCard({required this.resultado});

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final color = resultado == null || resultado!.valoresIguais
        ? AppColors.textSecondary
        : AppColors.success;
    final value = resultado == null
        ? 'R\$ 0,00'
        : DescontoCalculator.formatMoney(resultado!.descontoUnitarioCentavos);

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingLG),
      decoration: AppStyles.softCard(
        context: context,
        tint: color,
        radius: tokens.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(tokens.inputRadius),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Icon(Icons.local_offer_rounded, color: color),
              ),
              const SizedBox(width: Dimensions.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Desconto unit\u00e1rio',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusLabel(resultado),
                      style: AppTextStyles.label.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spacingLG),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.h1.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (resultado != null) ...[
            const SizedBox(height: Dimensions.spacingSM),
            Text(
              'Total: ${DescontoCalculator.formatMoney(resultado!.descontoTotalCentavos)}',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(DescontoResultado? resultado) {
    if (resultado == null) return 'Aguardando valores';
    if (resultado.valoresIguais) return 'Valores iguais';
    if (resultado.etiquetaMaior) return 'Etiqueta acima do sistema';
    return 'Sistema acima da etiqueta';
  }
}

class _InputCard extends StatelessWidget {
  final TextEditingController etiquetaCtrl;
  final TextEditingController sistemaCtrl;
  final TextEditingController quantidadeCtrl;
  final VoidCallback onChanged;
  final VoidCallback onExample;
  final VoidCallback onClear;

  const _InputCard({
    required this.etiquetaCtrl,
    required this.sistemaCtrl,
    required this.quantidadeCtrl,
    required this.onChanged,
    required this.onExample,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      decoration: AppStyles.softCard(
        context: context,
        tint: AppColors.primary,
        radius: tokens.cardRadius,
        elevated: false,
      ),
      child: Column(
        children: [
          _MoneyField(
            controller: etiquetaCtrl,
            label: 'Pre\u00e7o da etiqueta',
            hint: '16,99',
            onChanged: onChanged,
          ),
          const SizedBox(height: Dimensions.spacingSM),
          _MoneyField(
            controller: sistemaCtrl,
            label: 'Pre\u00e7o no sistema',
            hint: '14,99',
            onChanged: onChanged,
          ),
          const SizedBox(height: Dimensions.spacingSM),
          TextField(
            controller: quantidadeCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.body,
            decoration: _inputDecoration(
              context,
              label: 'Quantidade',
              hint: '1',
              icon: Icons.numbers_rounded,
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: Dimensions.spacingMD),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onExample,
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                  label: const Text('Exemplo'),
                ),
              ),
              const SizedBox(width: Dimensions.spacingSM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                  label: const Text('Limpar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final VoidCallback onChanged;

  const _MoneyField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isInvalid = controller.text.trim().isNotEmpty &&
        DescontoCalculator.parseMoneyToCents(controller.text) == null;

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
      ],
      style: AppTextStyles.body,
      decoration: _inputDecoration(
        context,
        label: label,
        hint: hint,
        icon: Icons.attach_money_rounded,
        errorText: isInvalid ? 'Valor inv\u00e1lido' : null,
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final DescontoResultado? resultado;

  const _ResumoCard({required this.resultado});

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final itemColor = resultado == null || resultado!.valoresIguais
        ? AppColors.textSecondary
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      decoration: AppStyles.softCard(
        context: context,
        tint: itemColor,
        radius: tokens.cardRadius,
        elevated: false,
      ),
      child: Column(
        children: [
          _ResumoRow(
            label: 'Etiqueta',
            value: resultado == null
                ? 'R\$ 0,00'
                : DescontoCalculator.formatMoney(resultado!.etiquetaCentavos),
          ),
          const Divider(height: 20),
          _ResumoRow(
            label: 'Sistema',
            value: resultado == null
                ? 'R\$ 0,00'
                : DescontoCalculator.formatMoney(resultado!.sistemaCentavos),
          ),
          const Divider(height: 20),
          _ResumoRow(
            label: 'Percentual',
            value: resultado == null
                ? '0,00%'
                : DescontoCalculator.formatPercent(
                    resultado!.percentualDesconto,
                  ),
          ),
          const Divider(height: 20),
          _ResumoRow(
            label: 'Desconto total',
            value: resultado == null
                ? 'R\$ 0,00'
                : DescontoCalculator.formatMoney(
                    resultado!.descontoTotalCentavos,
                  ),
            valueColor: itemColor,
          ),
          const Divider(height: 20),
          _ResumoRow(
            label: 'Valor final',
            value: resultado == null
                ? 'R\$ 0,00'
                : DescontoCalculator.formatMoney(
                    resultado!.valorFinalTotalCentavos,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResumoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ResumoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: Dimensions.spacingSM),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.body.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String label,
  required String hint,
  required IconData icon,
  String? errorText,
}) {
  final tokens = context.appTheme;

  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: errorText,
    prefixIcon: Icon(icon, color: AppColors.primary),
    filled: true,
    fillColor: AppColors.backgroundSection,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: Dimensions.paddingSM,
      vertical: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.inputRadius),
      borderSide: BorderSide(color: AppColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.inputRadius),
      borderSide: BorderSide(color: AppColors.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.inputRadius),
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.inputRadius),
      borderSide: BorderSide(color: AppColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.inputRadius),
      borderSide: BorderSide(color: AppColors.danger, width: 1.5),
    ),
  );
}
