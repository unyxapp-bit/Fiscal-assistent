import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_notif.dart';
import '../../../core/utils/desconto_calculator.dart';
import '../../../data/services/desconto_historico_service.dart';

enum _DescontoModo {
  comparacao,
  percentual,
  precoFinal,
  levePague,
}

extension _DescontoModoX on _DescontoModo {
  String get storage => switch (this) {
        _DescontoModo.comparacao => 'comparacao',
        _DescontoModo.percentual => 'percentual',
        _DescontoModo.precoFinal => 'preco_final',
        _DescontoModo.levePague => 'leve_pague',
      };

  String get label => switch (this) {
        _DescontoModo.comparacao => 'Etiqueta x PDV',
        _DescontoModo.percentual => 'Percentual',
        _DescontoModo.precoFinal => 'Preco final',
        _DescontoModo.levePague => 'Leve/Pague',
      };

  IconData get icon => switch (this) {
        _DescontoModo.comparacao => Icons.compare_arrows_rounded,
        _DescontoModo.percentual => Icons.percent_rounded,
        _DescontoModo.precoFinal => Icons.price_check_rounded,
        _DescontoModo.levePague => Icons.shopping_bag_outlined,
      };
}

class DescontoCalculatorScreen extends StatefulWidget {
  const DescontoCalculatorScreen({super.key});

  @override
  State<DescontoCalculatorScreen> createState() =>
      _DescontoCalculatorScreenState();
}

class _DescontoCalculatorScreenState extends State<DescontoCalculatorScreen> {
  final _produtoCodigoCtrl = TextEditingController();
  final _produtoNomeCtrl = TextEditingController();
  final _valorPrincipalCtrl = TextEditingController();
  final _valorSecundarioCtrl = TextEditingController();
  final _percentualCtrl = TextEditingController();
  final _quantidadeCtrl = TextEditingController(text: '1');
  final _leveCtrl = TextEditingController(text: '3');
  final _pagueCtrl = TextEditingController(text: '2');

  _DescontoModo _modo = _DescontoModo.comparacao;
  List<DescontoHistoricoItem> _historico = const [];
  bool _carregandoHistorico = false;
  String? _historicoErro;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  @override
  void dispose() {
    _produtoCodigoCtrl.dispose();
    _produtoNomeCtrl.dispose();
    _valorPrincipalCtrl.dispose();
    _valorSecundarioCtrl.dispose();
    _percentualCtrl.dispose();
    _quantidadeCtrl.dispose();
    _leveCtrl.dispose();
    _pagueCtrl.dispose();
    super.dispose();
  }

  int get _quantidade =>
      DescontoCalculator.parseQuantidade(_quantidadeCtrl.text);

  double? get _percentualAtual =>
      DescontoCalculator.parsePercent(_percentualCtrl.text);

  bool get _usaValorSecundario =>
      _modo == _DescontoModo.comparacao || _modo == _DescontoModo.precoFinal;

  DescontoResultado? get _resultado {
    final principal =
        DescontoCalculator.parseMoneyToCents(_valorPrincipalCtrl.text);
    if (principal == null) return null;

    switch (_modo) {
      case _DescontoModo.comparacao:
      case _DescontoModo.precoFinal:
        final secundario =
            DescontoCalculator.parseMoneyToCents(_valorSecundarioCtrl.text);
        if (secundario == null) return null;
        return DescontoCalculator.calcular(
          etiquetaCentavos: principal,
          sistemaCentavos: secundario,
          quantidade: _quantidade,
        );
      case _DescontoModo.percentual:
        final percentual = _percentualAtual;
        if (percentual == null) return null;
        return DescontoCalculator.calcularPorPercentual(
          precoBaseCentavos: principal,
          percentual: percentual,
          quantidade: _quantidade,
        );
      case _DescontoModo.levePague:
        final leve = int.tryParse(_leveCtrl.text.trim());
        final pague = int.tryParse(_pagueCtrl.text.trim());
        if (leve == null || pague == null || leve < 1 || pague < 0) {
          return null;
        }
        if (pague > leve) return null;
        return DescontoCalculator.calcularLevePague(
          precoUnitarioCentavos: principal,
          leve: leve,
          pague: pague,
          quantidade: _quantidade,
        );
    }
  }

  Future<void> _carregarHistorico() async {
    setState(() {
      _carregandoHistorico = true;
      _historicoErro = null;
    });

    try {
      final historico = await DescontoHistoricoService.listar();
      if (!mounted) return;
      setState(() {
        _historico = historico;
        _carregandoHistorico = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _historico = const [];
        _historicoErro = 'Historico indisponivel. Execute a migration SQL.';
        _carregandoHistorico = false;
      });
    }
  }

  void _selecionarModo(_DescontoModo modo) {
    setState(() {
      _modo = modo;
      if (modo == _DescontoModo.percentual && _percentualCtrl.text.isEmpty) {
        _percentualCtrl.text = '10';
      }
      if (modo == _DescontoModo.levePague) {
        if (_leveCtrl.text.isEmpty) _leveCtrl.text = '3';
        if (_pagueCtrl.text.isEmpty) _pagueCtrl.text = '2';
      }
    });
  }

  void _preencherExemplo() {
    setState(() {
      _produtoCodigoCtrl.text = '789123';
      _produtoNomeCtrl.text = 'Produto exemplo';
      _quantidadeCtrl.text = '1';
      switch (_modo) {
        case _DescontoModo.comparacao:
          _valorPrincipalCtrl.text = 'R\$ 16,99';
          _valorSecundarioCtrl.text = 'R\$ 14,99';
          break;
        case _DescontoModo.percentual:
          _valorPrincipalCtrl.text = 'R\$ 49,90';
          _percentualCtrl.text = '15';
          break;
        case _DescontoModo.precoFinal:
          _valorPrincipalCtrl.text = 'R\$ 39,90';
          _valorSecundarioCtrl.text = 'R\$ 34,90';
          break;
        case _DescontoModo.levePague:
          _valorPrincipalCtrl.text = 'R\$ 9,99';
          _leveCtrl.text = '3';
          _pagueCtrl.text = '2';
          break;
      }
    });
  }

  void _limpar() {
    setState(() {
      _produtoCodigoCtrl.clear();
      _produtoNomeCtrl.clear();
      _valorPrincipalCtrl.clear();
      _valorSecundarioCtrl.clear();
      _percentualCtrl.clear();
      _quantidadeCtrl.text = '1';
      _leveCtrl.text = '3';
      _pagueCtrl.text = '2';
    });
  }

  void _trocarValores() {
    if (!_usaValorSecundario) return;
    setState(() {
      final atual = _valorPrincipalCtrl.text;
      _valorPrincipalCtrl.text = _valorSecundarioCtrl.text;
      _valorSecundarioCtrl.text = atual;
    });
  }

  Future<void> _copiarResultado() async {
    final resultado = _resultado;
    if (resultado == null) {
      AppNotif.show(
        context,
        titulo: 'Calculo incompleto',
        mensagem: 'Preencha os campos do modo selecionado.',
        tipo: 'alerta',
        cor: AppColors.warning,
      );
      return;
    }

    final mensagem = _mensagemResultado(resultado);
    await Clipboard.setData(ClipboardData(text: mensagem));

    var salvo = false;
    try {
      await _salvarHistorico(resultado, mensagem, mostrarNotificacao: false);
      salvo = true;
    } catch (_) {
      salvo = false;
    }

    if (!mounted) return;
    AppNotif.show(
      context,
      titulo: 'Resultado copiado',
      mensagem: salvo
          ? 'Mensagem copiada e calculo salvo no historico.'
          : 'Mensagem copiada. Historico depende da migration SQL.',
      tipo: salvo ? 'saida' : 'alerta',
      cor: salvo ? AppColors.success : AppColors.warning,
    );
  }

  Future<void> _salvarHistoricoAtual() async {
    final resultado = _resultado;
    if (resultado == null) {
      AppNotif.show(
        context,
        titulo: 'Calculo incompleto',
        mensagem: 'Preencha os campos antes de salvar.',
        tipo: 'alerta',
        cor: AppColors.warning,
      );
      return;
    }

    await _salvarHistorico(
      resultado,
      _mensagemResultado(resultado),
      mostrarNotificacao: true,
    );
  }

  Future<void> _salvarHistorico(
    DescontoResultado resultado,
    String mensagem, {
    required bool mostrarNotificacao,
  }) async {
    final input = DescontoHistoricoInput(
      modo: _modo.storage,
      produtoCodigo: _produtoCodigoCtrl.text,
      produtoNome: _produtoNomeCtrl.text,
      percentual: _modo == _DescontoModo.percentual ? _percentualAtual : null,
      leve: _modo == _DescontoModo.levePague
          ? int.tryParse(_leveCtrl.text.trim())
          : null,
      pague: _modo == _DescontoModo.levePague
          ? int.tryParse(_pagueCtrl.text.trim())
          : null,
      resultado: resultado,
      mensagemCopiada: mensagem,
    );

    await DescontoHistoricoService.salvar(input);
    await _carregarHistorico();

    if (!mounted || !mostrarNotificacao) return;
    AppNotif.show(
      context,
      titulo: 'Historico salvo',
      mensagem: 'Calculo registrado para auditoria.',
      tipo: 'saida',
      cor: AppColors.success,
    );
  }

  String _mensagemResultado(DescontoResultado resultado) {
    final linhas = <String>[];
    final codigo = _produtoCodigoCtrl.text.trim();
    final produto = _produtoNomeCtrl.text.trim();
    if (produto.isNotEmpty || codigo.isNotEmpty) {
      linhas.add(
        [
          if (codigo.isNotEmpty) 'Cod. $codigo',
          if (produto.isNotEmpty) produto,
        ].join(' - '),
      );
    }

    linhas
      ..add('Modo: ${_modo.label}')
      ..add(
          'Base: ${DescontoCalculator.formatMoney(resultado.etiquetaCentavos)}')
      ..add(
          'Final: ${DescontoCalculator.formatMoney(resultado.sistemaCentavos)}')
      ..add('Qtd: ${resultado.quantidade}')
      ..add(
        '${_diferencaLabel(resultado)} unit.: ${DescontoCalculator.formatMoney(resultado.descontoUnitarioCentavos)}',
      )
      ..add(
        '${_diferencaLabel(resultado)} total: ${DescontoCalculator.formatMoney(resultado.descontoTotalCentavos)}',
      )
      ..add(
        'Valor final total: ${DescontoCalculator.formatMoney(resultado.valorFinalTotalCentavos)}',
      );

    if (_modo == _DescontoModo.percentual && _percentualAtual != null) {
      linhas.add(
          'Percentual: ${DescontoCalculator.formatPercent(_percentualAtual!)}');
    }
    if (_modo == _DescontoModo.levePague) {
      linhas.add('Promocao: leve ${_leveCtrl.text}, pague ${_pagueCtrl.text}');
    }

    return linhas.join('\n');
  }

  Future<void> _copiarHistorico(DescontoHistoricoItem item) async {
    final texto = item.mensagemCopiada.trim().isEmpty
        ? _mensagemHistoricoBasica(item)
        : item.mensagemCopiada;
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    AppNotif.show(
      context,
      titulo: 'Historico copiado',
      mensagem: 'Mensagem copiada.',
      tipo: 'saida',
      cor: AppColors.success,
    );
  }

  String _mensagemHistoricoBasica(DescontoHistoricoItem item) {
    return [
      if (item.produtoCodigo.isNotEmpty || item.produtoNome.isNotEmpty)
        [item.produtoCodigo, item.produtoNome]
            .where((value) => value.trim().isNotEmpty)
            .join(' - '),
      'Modo: ${_modoLabelFromStorage(item.modo)}',
      'Base: ${DescontoCalculator.formatMoney(item.etiquetaCentavos)}',
      'Final: ${DescontoCalculator.formatMoney(item.sistemaCentavos)}',
      'Diferenca total: ${DescontoCalculator.formatMoney(item.descontoTotalCentavos)}',
    ].join('\n');
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
            tooltip: 'Inverter valores',
            onPressed: _usaValorSecundario ? _trocarValores : null,
            icon: const Icon(Icons.swap_vert_rounded),
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
          final wide = constraints.maxWidth >= 980;
          final horizontalPadding = _pageHorizontalPadding(
            constraints.maxWidth,
          );

          if (wide) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                Dimensions.paddingMD,
                horizontalPadding,
                Dimensions.paddingXL,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _ResultCard(resultado: resultado, modo: _modo),
                        const SizedBox(height: Dimensions.spacingMD),
                        _ResumoCard(resultado: resultado, modo: _modo),
                        const SizedBox(height: Dimensions.spacingMD),
                        _HistoricoCard(
                          historico: _historico,
                          loading: _carregandoHistorico,
                          errorText: _historicoErro,
                          onRefresh: _carregarHistorico,
                          onCopy: _copiarHistorico,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingLG),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        _InputCard(
                          modo: _modo,
                          produtoCodigoCtrl: _produtoCodigoCtrl,
                          produtoNomeCtrl: _produtoNomeCtrl,
                          valorPrincipalCtrl: _valorPrincipalCtrl,
                          valorSecundarioCtrl: _valorSecundarioCtrl,
                          percentualCtrl: _percentualCtrl,
                          quantidadeCtrl: _quantidadeCtrl,
                          leveCtrl: _leveCtrl,
                          pagueCtrl: _pagueCtrl,
                          onModeChanged: _selecionarModo,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: Dimensions.spacingMD),
                        _ActionCard(
                          resultado: resultado,
                          onCopy: _copiarResultado,
                          onSave: _salvarHistoricoAtual,
                          onSwap: _trocarValores,
                          canSwap: _usaValorSecundario,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              Dimensions.paddingMD,
              horizontalPadding,
              Dimensions.paddingXL,
            ),
            children: [
              _ResultCard(resultado: resultado, modo: _modo),
              const SizedBox(height: Dimensions.spacingMD),
              _InputCard(
                modo: _modo,
                produtoCodigoCtrl: _produtoCodigoCtrl,
                produtoNomeCtrl: _produtoNomeCtrl,
                valorPrincipalCtrl: _valorPrincipalCtrl,
                valorSecundarioCtrl: _valorSecundarioCtrl,
                percentualCtrl: _percentualCtrl,
                quantidadeCtrl: _quantidadeCtrl,
                leveCtrl: _leveCtrl,
                pagueCtrl: _pagueCtrl,
                onModeChanged: _selecionarModo,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: Dimensions.spacingMD),
              _ResumoCard(resultado: resultado, modo: _modo),
              const SizedBox(height: Dimensions.spacingMD),
              _ActionCard(
                resultado: resultado,
                onCopy: _copiarResultado,
                onSave: _salvarHistoricoAtual,
                onSwap: _trocarValores,
                canSwap: _usaValorSecundario,
              ),
              const SizedBox(height: Dimensions.spacingMD),
              _HistoricoCard(
                historico: _historico,
                loading: _carregandoHistorico,
                errorText: _historicoErro,
                onRefresh: _carregarHistorico,
                onCopy: _copiarHistorico,
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
  final _DescontoModo modo;

  const _ResultCard({required this.resultado, required this.modo});

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final color = _statusColor(resultado);
    final value = resultado == null
        ? 'R\$ 0,00'
        : DescontoCalculator.formatMoney(resultado!.descontoUnitarioCentavos);

    return Container(
      width: double.infinity,
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
                child: Icon(modo.icon, color: color),
              ),
              const SizedBox(width: Dimensions.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _unitLabel(modo),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusLabel(resultado, modo),
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
            Wrap(
              spacing: Dimensions.spacingSM,
              runSpacing: Dimensions.spacingXS,
              children: [
                _MetricPill(
                  label: 'Total',
                  value: DescontoCalculator.formatMoney(
                    resultado!.descontoTotalCentavos,
                  ),
                  color: color,
                ),
                _MetricPill(
                  label: 'Final',
                  value: DescontoCalculator.formatMoney(
                    resultado!.valorFinalTotalCentavos,
                  ),
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final _DescontoModo modo;
  final TextEditingController produtoCodigoCtrl;
  final TextEditingController produtoNomeCtrl;
  final TextEditingController valorPrincipalCtrl;
  final TextEditingController valorSecundarioCtrl;
  final TextEditingController percentualCtrl;
  final TextEditingController quantidadeCtrl;
  final TextEditingController leveCtrl;
  final TextEditingController pagueCtrl;
  final ValueChanged<_DescontoModo> onModeChanged;
  final VoidCallback onChanged;

  const _InputCard({
    required this.modo,
    required this.produtoCodigoCtrl,
    required this.produtoNomeCtrl,
    required this.valorPrincipalCtrl,
    required this.valorSecundarioCtrl,
    required this.percentualCtrl,
    required this.quantidadeCtrl,
    required this.leveCtrl,
    required this.pagueCtrl,
    required this.onModeChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      decoration: AppStyles.softCard(
        context: context,
        tint: AppColors.primary,
        radius: tokens.cardRadius,
        elevated: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<_DescontoModo>(
              segments: [
                for (final item in _DescontoModo.values)
                  ButtonSegment(
                    value: item,
                    icon: Icon(item.icon, size: 16),
                    label: Text(item.label),
                  ),
              ],
              selected: {modo},
              onSelectionChanged: (values) => onModeChanged(values.first),
            ),
          ),
          const SizedBox(height: Dimensions.spacingMD),
          LayoutBuilder(
            builder: (context, constraints) {
              final inline = constraints.maxWidth >= 520;
              final codigo = _TextFieldPadrao(
                controller: produtoCodigoCtrl,
                label: 'Codigo do produto',
                hint: '789...',
                icon: Icons.qr_code_rounded,
                onChanged: onChanged,
              );
              final nome = _TextFieldPadrao(
                controller: produtoNomeCtrl,
                label: 'Produto',
                hint: 'Nome do item',
                icon: Icons.inventory_2_outlined,
                textCapitalization: TextCapitalization.words,
                onChanged: onChanged,
              );
              if (!inline) {
                return Column(
                  children: [
                    codigo,
                    const SizedBox(height: Dimensions.spacingSM),
                    nome,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: codigo),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(child: nome),
                ],
              );
            },
          ),
          const SizedBox(height: Dimensions.spacingSM),
          _MoneyField(
            controller: valorPrincipalCtrl,
            label: _primaryMoneyLabel(modo),
            hint: 'R\$ 16,99',
            onChanged: onChanged,
          ),
          if (modo == _DescontoModo.comparacao ||
              modo == _DescontoModo.precoFinal) ...[
            const SizedBox(height: Dimensions.spacingSM),
            _MoneyField(
              controller: valorSecundarioCtrl,
              label: _secondaryMoneyLabel(modo),
              hint: 'R\$ 14,99',
              onChanged: onChanged,
            ),
          ],
          if (modo == _DescontoModo.percentual) ...[
            const SizedBox(height: Dimensions.spacingSM),
            TextField(
              controller: percentualCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              style: AppTextStyles.body,
              decoration: _inputDecoration(
                context,
                label: 'Percentual de desconto',
                hint: '10',
                icon: Icons.percent_rounded,
                suffixText: '%',
              ),
              onChanged: (_) => onChanged(),
            ),
          ],
          if (modo == _DescontoModo.levePague) ...[
            const SizedBox(height: Dimensions.spacingSM),
            Row(
              children: [
                Expanded(
                  child: _IntegerField(
                    controller: leveCtrl,
                    label: 'Leve',
                    icon: Icons.add_shopping_cart_rounded,
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(width: Dimensions.spacingSM),
                Expanded(
                  child: _IntegerField(
                    controller: pagueCtrl,
                    label: 'Pague',
                    icon: Icons.price_check_rounded,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Dimensions.spacingSM),
          _IntegerField(
            controller: quantidadeCtrl,
            label: modo == _DescontoModo.levePague
                ? 'Quantidade de combos'
                : 'Quantidade',
            icon: Icons.numbers_rounded,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final DescontoResultado? resultado;
  final VoidCallback onCopy;
  final VoidCallback onSave;
  final VoidCallback onSwap;
  final bool canSwap;

  const _ActionCard({
    required this.resultado,
    required this.onCopy,
    required this.onSave,
    required this.onSwap,
    required this.canSwap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final color = _statusColor(resultado);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      decoration: AppStyles.softCard(
        context: context,
        tint: color,
        radius: tokens.cardRadius,
        elevated: false,
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded),
              label: Text(_copyLabel(resultado)),
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
          const SizedBox(height: Dimensions.spacingSM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: const Text('Salvar'),
                ),
              ),
              const SizedBox(width: Dimensions.spacingSM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canSwap ? onSwap : null,
                  icon: const Icon(Icons.swap_vert_rounded, size: 18),
                  label: const Text('Inverter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final DescontoResultado? resultado;
  final _DescontoModo modo;

  const _ResumoCard({required this.resultado, required this.modo});

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final itemColor = _statusColor(resultado);

    return Container(
      width: double.infinity,
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
            label: _baseResumoLabel(modo),
            value: resultado == null
                ? 'R\$ 0,00'
                : DescontoCalculator.formatMoney(resultado!.etiquetaCentavos),
          ),
          const Divider(height: 20),
          _ResumoRow(
            label: _finalResumoLabel(modo),
            value: resultado == null
                ? 'R\$ 0,00'
                : DescontoCalculator.formatMoney(resultado!.sistemaCentavos),
          ),
          const Divider(height: 20),
          _ResumoRow(
            label: 'Percentual real',
            value: resultado == null
                ? '0,00%'
                : DescontoCalculator.formatPercent(
                    resultado!.percentualDesconto,
                  ),
          ),
          const Divider(height: 20),
          _ResumoRow(
            label: _diferencaTotalLabel(resultado),
            value: resultado == null
                ? 'R\$ 0,00'
                : DescontoCalculator.formatMoney(
                    resultado!.descontoTotalCentavos,
                  ),
            valueColor: itemColor,
          ),
          const Divider(height: 20),
          _ResumoRow(
            label: 'Valor final total',
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

class _HistoricoCard extends StatelessWidget {
  final List<DescontoHistoricoItem> historico;
  final bool loading;
  final String? errorText;
  final VoidCallback onRefresh;
  final ValueChanged<DescontoHistoricoItem> onCopy;

  const _HistoricoCard({
    required this.historico,
    required this.loading,
    required this.errorText,
    required this.onRefresh,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      decoration: AppStyles.softCard(
        context: context,
        tint: AppColors.info,
        radius: tokens.cardRadius,
        elevated: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: AppColors.primary),
              const SizedBox(width: Dimensions.spacingSM),
              Expanded(
                child: Text(
                  'Historico recente',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Atualizar',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Dimensions.paddingMD),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: Dimensions.spacingSM),
              child: Text(
                errorText!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (historico.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Dimensions.spacingSM),
              child: Text(
                'Nenhum calculo salvo ainda.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...historico.take(8).map(
                  (item) => _HistoricoTile(
                    item: item,
                    onCopy: () => onCopy(item),
                  ),
                ),
        ],
      ),
    );
  }
}

class _HistoricoTile extends StatelessWidget {
  final DescontoHistoricoItem item;
  final VoidCallback onCopy;

  const _HistoricoTile({required this.item, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final title = [item.produtoCodigo, item.produtoNome]
        .where((value) => value.trim().isNotEmpty)
        .join(' - ');

    return Container(
      margin: const EdgeInsets.only(top: Dimensions.spacingSM),
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSM,
        vertical: Dimensions.paddingSM,
      ),
      decoration: AppStyles.softTile(
        context: context,
        tint: AppColors.primary,
        radius: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? _modoLabelFromStorage(item.modo) : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('dd/MM HH:mm').format(item.createdAt)} | '
                  '${_modoLabelFromStorage(item.modo)} | '
                  '${DescontoCalculator.formatMoney(item.descontoTotalCentavos)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar',
            onPressed: onCopy,
            icon: Icon(Icons.copy_rounded, color: AppColors.primary, size: 18),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: AppStyles.softTile(
        context: context,
        tint: color,
        radius: 999,
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
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
      keyboardType: TextInputType.number,
      inputFormatters: [_MoneyInputFormatter()],
      style: AppTextStyles.body,
      decoration: _inputDecoration(
        context,
        label: label,
        hint: hint,
        icon: Icons.attach_money_rounded,
        errorText: isInvalid ? 'Valor invalido' : null,
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

class _IntegerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final VoidCallback onChanged;

  const _IntegerField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTextStyles.body,
      decoration: _inputDecoration(
        context,
        label: label,
        hint: '1',
        icon: icon,
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

class _TextFieldPadrao extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final VoidCallback onChanged;
  final TextCapitalization textCapitalization;

  const _TextFieldPadrao({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      style: AppTextStyles.body,
      decoration: _inputDecoration(
        context,
        label: label,
        hint: hint,
        icon: icon,
      ),
      onChanged: (_) => onChanged(),
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

class _MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final cents = int.tryParse(digits);
    if (cents == null) return oldValue;
    final text = DescontoCalculator.formatMoney(cents);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String label,
  required String hint,
  required IconData icon,
  String? errorText,
  String? suffixText,
}) {
  final tokens = context.appTheme;

  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: errorText,
    suffixText: suffixText,
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

double _pageHorizontalPadding(double width) {
  if (width < Dimensions.breakpointTablet) return Dimensions.paddingMD;
  if (width < 980) return Dimensions.paddingLG;
  const maxContentWidth = 1180.0;
  const minPadding = Dimensions.paddingXL;
  if (width > maxContentWidth + minPadding * 2) {
    return (width - maxContentWidth) / 2;
  }
  return minPadding;
}

String _primaryMoneyLabel(_DescontoModo modo) => switch (modo) {
      _DescontoModo.comparacao => 'Preco da etiqueta',
      _DescontoModo.percentual => 'Preco base',
      _DescontoModo.precoFinal => 'Preco original',
      _DescontoModo.levePague => 'Preco unitario',
    };

String _secondaryMoneyLabel(_DescontoModo modo) => switch (modo) {
      _DescontoModo.comparacao => 'Preco no sistema',
      _DescontoModo.precoFinal => 'Preco final',
      _ => 'Preco',
    };

String _unitLabel(_DescontoModo modo) => switch (modo) {
      _DescontoModo.levePague => 'Diferenca por combo',
      _ => 'Diferenca unitaria',
    };

String _baseResumoLabel(_DescontoModo modo) => switch (modo) {
      _DescontoModo.levePague => 'Valor sem promocao',
      _ => 'Valor base',
    };

String _finalResumoLabel(_DescontoModo modo) => switch (modo) {
      _DescontoModo.levePague => 'Valor promocional',
      _ => 'Valor final',
    };

String _statusLabel(DescontoResultado? resultado, _DescontoModo modo) {
  if (resultado == null) return 'Aguardando valores';
  if (resultado.valoresIguais) return 'Sem diferenca';
  if (resultado.sistemaMaior) return 'Acrecimo detectado';
  return switch (modo) {
    _DescontoModo.percentual => 'Desconto por percentual',
    _DescontoModo.levePague => 'Promocao aplicada',
    _ => 'Desconto detectado',
  };
}

String _diferencaLabel(DescontoResultado resultado) {
  if (resultado.valoresIguais) return 'Diferenca';
  return resultado.sistemaMaior ? 'Acrecimo' : 'Desconto';
}

String _diferencaTotalLabel(DescontoResultado? resultado) {
  if (resultado == null) return 'Diferenca total';
  return '${_diferencaLabel(resultado)} total';
}

String _copyLabel(DescontoResultado? resultado) {
  if (resultado == null) return 'Copiar resultado';
  if (resultado.sistemaMaior) return 'Copiar acrecimo';
  if (resultado.valoresIguais) return 'Copiar conferencia';
  return 'Copiar desconto';
}

Color _statusColor(DescontoResultado? resultado) {
  if (resultado == null || resultado.valoresIguais) {
    return AppColors.textSecondary;
  }
  if (resultado.sistemaMaior) return AppColors.warning;
  return AppColors.success;
}

String _modoLabelFromStorage(String value) {
  return switch (value) {
    'percentual' => 'Percentual',
    'preco_final' => 'Preco final',
    'leve_pague' => 'Leve/Pague',
    _ => 'Etiqueta x PDV',
  };
}
