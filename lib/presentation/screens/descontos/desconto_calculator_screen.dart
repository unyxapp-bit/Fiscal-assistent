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
  trocaMoedas,
}

extension _DescontoModoX on _DescontoModo {
  String get storage => switch (this) {
        _DescontoModo.comparacao => 'comparacao',
        _DescontoModo.percentual => 'percentual',
        _DescontoModo.precoFinal => 'preco_final',
        _DescontoModo.levePague => 'leve_pague',
        _DescontoModo.trocaMoedas => 'troca_moedas',
      };

  String get label => switch (this) {
        _DescontoModo.comparacao => 'Etiqueta x PDV',
        _DescontoModo.percentual => 'Percentual',
        _DescontoModo.precoFinal => 'Preco final',
        _DescontoModo.levePague => 'Leve/Pague',
        _DescontoModo.trocaMoedas => 'Moedas',
      };

  IconData get icon => switch (this) {
        _DescontoModo.comparacao => Icons.compare_arrows_rounded,
        _DescontoModo.percentual => Icons.percent_rounded,
        _DescontoModo.precoFinal => Icons.price_check_rounded,
        _DescontoModo.levePague => Icons.shopping_bag_outlined,
        _DescontoModo.trocaMoedas => Icons.payments_outlined,
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
  final _moeda005Ctrl = TextEditingController();
  final _moeda010Ctrl = TextEditingController();
  final _moeda025Ctrl = TextEditingController();
  final _moeda050Ctrl = TextEditingController();

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
    _moeda005Ctrl.dispose();
    _moeda010Ctrl.dispose();
    _moeda025Ctrl.dispose();
    _moeda050Ctrl.dispose();
    super.dispose();
  }

  int get _quantidade =>
      DescontoCalculator.parseQuantidade(_quantidadeCtrl.text);

  double? get _percentualAtual =>
      DescontoCalculator.parsePercent(_percentualCtrl.text);

  bool get _usaValorSecundario =>
      _modo == _DescontoModo.comparacao || _modo == _DescontoModo.precoFinal;

  TrocaMoedasResultado? get _trocaMoedasResultado {
    if (_modo != _DescontoModo.trocaMoedas) return null;
    final resultado = DescontoCalculator.calcularTrocaMoedas(
      valor005Centavos: _parseCoinValue(_moeda005Ctrl.text),
      valor010Centavos: _parseCoinValue(_moeda010Ctrl.text),
      valor025Centavos: _parseCoinValue(_moeda025Ctrl.text),
      valor050Centavos: _parseCoinValue(_moeda050Ctrl.text),
    );
    return resultado.vazio ? null : resultado;
  }

  DescontoResultado? get _resultado {
    if (_modo == _DescontoModo.trocaMoedas) {
      return _trocaMoedasResultado?.toDescontoResultado();
    }

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
      case _DescontoModo.trocaMoedas:
        return null;
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

  int _parseCoinValue(String value) {
    final parsed = DescontoCalculator.parseMoneyToCents(value);
    if (parsed == null || parsed < 0) return 0;
    return parsed;
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
        case _DescontoModo.trocaMoedas:
          _produtoCodigoCtrl.clear();
          _produtoNomeCtrl.text = 'Troca de moedas';
          _moeda005Ctrl.text = 'R\$ 14,05';
          _moeda010Ctrl.text = 'R\$ 0,00';
          _moeda025Ctrl.text = 'R\$ 12,50';
          _moeda050Ctrl.text = 'R\$ 0,00';
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
      _moeda005Ctrl.clear();
      _moeda010Ctrl.clear();
      _moeda025Ctrl.clear();
      _moeda050Ctrl.clear();
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
      percentual: _modo == _DescontoModo.percentual
          ? _percentualAtual
          : _modo == _DescontoModo.trocaMoedas
              ? _trocaMoedasResultado?.percentualMedio
              : null,
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
    if (_modo == _DescontoModo.trocaMoedas) {
      return _mensagemTrocaMoedas();
    }

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
        '${_diferencaLabel(resultado, _modo)} unit.: ${DescontoCalculator.formatMoney(resultado.descontoUnitarioCentavos)}',
      )
      ..add(
        '${_diferencaLabel(resultado, _modo)} total: ${DescontoCalculator.formatMoney(resultado.descontoTotalCentavos)}',
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

  String _mensagemTrocaMoedas() {
    final moedas = _trocaMoedasResultado;
    if (moedas == null) return 'Modo: ${_modo.label}';

    final linhas = <String>[
      'Modo: Troca de moedas',
      'Moedas de R\$ 0,05: ${DescontoCalculator.formatMoney(moedas.valor005Centavos)} (+10%)',
      'Moedas de R\$ 0,10: ${DescontoCalculator.formatMoney(moedas.valor010Centavos)} (+10%)',
      'Moedas de R\$ 0,25: ${DescontoCalculator.formatMoney(moedas.valor025Centavos)} (+5%)',
      'Moedas de R\$ 0,50: ${DescontoCalculator.formatMoney(moedas.valor050Centavos)} (+5%)',
      'Valor total das moedas: ${DescontoCalculator.formatMoney(moedas.valorTotalMoedasCentavos)}',
      'Total das porcentagens: ${DescontoCalculator.formatMoney(moedas.totalPorcentagensCentavos)}',
      'Total com porcentagem: ${DescontoCalculator.formatMoney(moedas.totalComPorcentagemCentavos)}',
      'Percentual medio: ${DescontoCalculator.formatPercent(moedas.percentualMedio)}',
    ];

    final produto = _produtoNomeCtrl.text.trim();
    if (produto.isNotEmpty && produto != 'Troca de moedas') {
      linhas.insert(1, produto);
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
    if (item.modo == _DescontoModo.trocaMoedas.storage) {
      return [
        'Modo: ${_modoLabelFromStorage(item.modo)}',
        'Valor total das moedas: ${DescontoCalculator.formatMoney(item.etiquetaCentavos)}',
        'Total das porcentagens: ${DescontoCalculator.formatMoney(item.descontoTotalCentavos)}',
        'Total com porcentagem: ${DescontoCalculator.formatMoney(item.sistemaCentavos)}',
      ].join('\n');
    }

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
                Dimensions.paddingSM,
                horizontalPadding,
                Dimensions.paddingXL,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
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
                          moeda005Ctrl: _moeda005Ctrl,
                          moeda010Ctrl: _moeda010Ctrl,
                          moeda025Ctrl: _moeda025Ctrl,
                          moeda050Ctrl: _moeda050Ctrl,
                          onModeChanged: _selecionarModo,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: Dimensions.spacingSM),
                        _ActionCard(
                          modo: _modo,
                          resultado: resultado,
                          onCopy: _copiarResultado,
                          onSave: _salvarHistoricoAtual,
                          onSwap: _trocarValores,
                          canSwap: _usaValorSecundario,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingLG),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _ResultCard(resultado: resultado, modo: _modo),
                        const SizedBox(height: Dimensions.spacingSM),
                        _ResumoCard(resultado: resultado, modo: _modo),
                        const SizedBox(height: Dimensions.spacingSM),
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
                ],
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              Dimensions.paddingSM,
              horizontalPadding,
              Dimensions.paddingXL,
            ),
            children: [
              _ResultCard(resultado: resultado, modo: _modo),
              const SizedBox(height: Dimensions.spacingSM),
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
                moeda005Ctrl: _moeda005Ctrl,
                moeda010Ctrl: _moeda010Ctrl,
                moeda025Ctrl: _moeda025Ctrl,
                moeda050Ctrl: _moeda050Ctrl,
                onModeChanged: _selecionarModo,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: Dimensions.spacingSM),
              _ResumoCard(resultado: resultado, modo: _modo),
              const SizedBox(height: Dimensions.spacingSM),
              _ActionCard(
                modo: _modo,
                resultado: resultado,
                onCopy: _copiarResultado,
                onSave: _salvarHistoricoAtual,
                onSwap: _trocarValores,
                canSwap: _usaValorSecundario,
              ),
              const SizedBox(height: Dimensions.spacingSM),
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
    final color = _statusColor(resultado, modo);
    final value = resultado == null
        ? 'R\$ 0,00'
        : DescontoCalculator.formatMoney(resultado!.descontoUnitarioCentavos);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSM),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(tokens.inputRadius),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Icon(modo.icon, color: color, size: 20),
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
          const SizedBox(height: Dimensions.spacingSM),
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
            const SizedBox(height: Dimensions.spacingXS),
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
  final TextEditingController moeda005Ctrl;
  final TextEditingController moeda010Ctrl;
  final TextEditingController moeda025Ctrl;
  final TextEditingController moeda050Ctrl;
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
    required this.moeda005Ctrl,
    required this.moeda010Ctrl,
    required this.moeda025Ctrl,
    required this.moeda050Ctrl,
    required this.onModeChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSM),
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
          const SizedBox(height: Dimensions.spacingSM),
          if (modo == _DescontoModo.trocaMoedas)
            _CoinExchangeFields(
              moeda005Ctrl: moeda005Ctrl,
              moeda010Ctrl: moeda010Ctrl,
              moeda025Ctrl: moeda025Ctrl,
              moeda050Ctrl: moeda050Ctrl,
              onChanged: onChanged,
            )
          else ...[
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
                      const SizedBox(height: Dimensions.spacingXS),
                      nome,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: codigo),
                    const SizedBox(width: Dimensions.spacingXS),
                    Expanded(child: nome),
                  ],
                );
              },
            ),
            const SizedBox(height: Dimensions.spacingXS),
            _MoneyField(
              controller: valorPrincipalCtrl,
              label: _primaryMoneyLabel(modo),
              hint: 'R\$ 16,99',
              onChanged: onChanged,
            ),
            if (modo == _DescontoModo.comparacao ||
                modo == _DescontoModo.precoFinal) ...[
              const SizedBox(height: Dimensions.spacingXS),
              _MoneyField(
                controller: valorSecundarioCtrl,
                label: _secondaryMoneyLabel(modo),
                hint: 'R\$ 14,99',
                onChanged: onChanged,
              ),
            ],
            if (modo == _DescontoModo.percentual) ...[
              const SizedBox(height: Dimensions.spacingXS),
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
              const SizedBox(height: Dimensions.spacingXS),
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
                  const SizedBox(width: Dimensions.spacingXS),
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
            const SizedBox(height: Dimensions.spacingXS),
            _IntegerField(
              controller: quantidadeCtrl,
              label: modo == _DescontoModo.levePague
                  ? 'Quantidade de combos'
                  : 'Quantidade',
              icon: Icons.numbers_rounded,
              onChanged: onChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _CoinExchangeFields extends StatelessWidget {
  final TextEditingController moeda005Ctrl;
  final TextEditingController moeda010Ctrl;
  final TextEditingController moeda025Ctrl;
  final TextEditingController moeda050Ctrl;
  final VoidCallback onChanged;

  const _CoinExchangeFields({
    required this.moeda005Ctrl,
    required this.moeda010Ctrl,
    required this.moeda025Ctrl,
    required this.moeda050Ctrl,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 520;
        final fields = [
          _CoinValueField(
            controller: moeda005Ctrl,
            label: 'Valor em moedas de R\$ 0,05',
            hint: '14,05',
            icon: Icons.payments_outlined,
            onChanged: onChanged,
          ),
          _CoinValueField(
            controller: moeda010Ctrl,
            label: 'Valor em moedas de R\$ 0,10',
            hint: '0,00',
            icon: Icons.payments_outlined,
            onChanged: onChanged,
          ),
          _CoinValueField(
            controller: moeda025Ctrl,
            label: 'Valor em moedas de R\$ 0,25',
            hint: '12.50',
            icon: Icons.monetization_on_outlined,
            onChanged: onChanged,
          ),
          _CoinValueField(
            controller: moeda050Ctrl,
            label: 'Valor em moedas de R\$ 0,50',
            hint: '0,00',
            icon: Icons.monetization_on_outlined,
            onChanged: onChanged,
          ),
        ];

        if (!twoColumns) {
          return Column(
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(height: Dimensions.spacingXS),
                fields[i],
              ],
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: fields[0]),
                const SizedBox(width: Dimensions.spacingXS),
                Expanded(child: fields[1]),
              ],
            ),
            const SizedBox(height: Dimensions.spacingXS),
            Row(
              children: [
                Expanded(child: fields[2]),
                const SizedBox(width: Dimensions.spacingXS),
                Expanded(child: fields[3]),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final _DescontoModo modo;
  final DescontoResultado? resultado;
  final VoidCallback onCopy;
  final VoidCallback onSave;
  final VoidCallback onSwap;
  final bool canSwap;

  const _ActionCard({
    required this.modo,
    required this.resultado,
    required this.onCopy,
    required this.onSave,
    required this.onSwap,
    required this.canSwap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final color = _statusColor(resultado, modo);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSM),
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
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded),
              label: Text(_copyLabel(resultado, modo)),
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
          const SizedBox(height: Dimensions.spacingXS),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: const Text('Salvar'),
                ),
              ),
              const SizedBox(width: Dimensions.spacingXS),
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
    final itemColor = _statusColor(resultado, modo);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSM),
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
          const Divider(height: 10),
          _ResumoRow(
            label: _finalResumoLabel(modo),
            value: resultado == null
                ? 'R\$ 0,00'
                : DescontoCalculator.formatMoney(resultado!.sistemaCentavos),
          ),
          const Divider(height: 10),
          _ResumoRow(
            label: modo == _DescontoModo.trocaMoedas
                ? 'Percentual medio'
                : 'Percentual real',
            value: resultado == null
                ? '0,00%'
                : DescontoCalculator.formatPercent(
                    modo == _DescontoModo.trocaMoedas
                        ? (resultado!.descontoTotalCentavos /
                                resultado!.etiquetaCentavos) *
                            100
                        : resultado!.percentualDesconto,
                  ),
          ),
          const Divider(height: 10),
          _ResumoRow(
            label: _diferencaTotalLabel(resultado, modo),
            value: resultado == null
                ? 'R\$ 0,00'
                : DescontoCalculator.formatMoney(
                    resultado!.descontoTotalCentavos,
                  ),
            valueColor: itemColor,
          ),
          const Divider(height: 10),
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
      padding: const EdgeInsets.all(Dimensions.paddingSM),
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
              const SizedBox(width: Dimensions.spacingXS),
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
              padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSM),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: Dimensions.spacingXS),
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
              padding: const EdgeInsets.only(top: Dimensions.spacingXS),
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
      margin: const EdgeInsets.only(top: Dimensions.spacingXS),
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSM,
        vertical: Dimensions.paddingXS,
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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

class _CoinValueField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final VoidCallback onChanged;

  const _CoinValueField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
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
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.Rr\$\s]')),
      ],
      style: AppTextStyles.body,
      decoration: _inputDecoration(
        context,
        label: label,
        hint: hint,
        icon: icon,
        errorText: isInvalid ? 'Valor invalido' : null,
      ),
      onChanged: (_) => onChanged(),
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
        const SizedBox(width: Dimensions.spacingXS),
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
    prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
    filled: true,
    fillColor: AppColors.backgroundSection,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: Dimensions.paddingSM,
      vertical: 10,
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 40),
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
  return Dimensions.operationalHPad(width);
}

String _primaryMoneyLabel(_DescontoModo modo) => switch (modo) {
      _DescontoModo.comparacao => 'Preco da etiqueta',
      _DescontoModo.percentual => 'Preco base',
      _DescontoModo.precoFinal => 'Preco original',
      _DescontoModo.levePague => 'Preco unitario',
      _DescontoModo.trocaMoedas => 'Valor das moedas',
    };

String _secondaryMoneyLabel(_DescontoModo modo) => switch (modo) {
      _DescontoModo.comparacao => 'Preco no sistema',
      _DescontoModo.precoFinal => 'Preco final',
      _ => 'Preco',
    };

String _unitLabel(_DescontoModo modo) => switch (modo) {
      _DescontoModo.levePague => 'Diferenca por combo',
      _DescontoModo.trocaMoedas => 'Bonus calculado',
      _ => 'Diferenca unitaria',
    };

String _baseResumoLabel(_DescontoModo modo) => switch (modo) {
      _DescontoModo.levePague => 'Valor sem promocao',
      _DescontoModo.trocaMoedas => 'Valor das moedas',
      _ => 'Valor base',
    };

String _finalResumoLabel(_DescontoModo modo) => switch (modo) {
      _DescontoModo.levePague => 'Valor promocional',
      _DescontoModo.trocaMoedas => 'Total com porcentagem',
      _ => 'Valor final',
    };

String _statusLabel(DescontoResultado? resultado, _DescontoModo modo) {
  if (resultado == null) return 'Aguardando valores';
  if (modo == _DescontoModo.trocaMoedas) return 'Troca calculada';
  if (resultado.valoresIguais) return 'Sem diferenca';
  if (modo == _DescontoModo.precoFinal && resultado.sistemaMaior) {
    return 'Preco final acima do original';
  }
  if (modo == _DescontoModo.comparacao && resultado.sistemaMaior) {
    return 'PDV acima da etiqueta';
  }
  return switch (modo) {
    _DescontoModo.percentual => 'Desconto por percentual',
    _DescontoModo.levePague => 'Promocao aplicada',
    _DescontoModo.trocaMoedas => 'Troca calculada',
    _ => 'Desconto detectado',
  };
}

String _diferencaLabel(DescontoResultado resultado, _DescontoModo modo) {
  if (modo == _DescontoModo.trocaMoedas) return 'Bonus';
  if (resultado.valoresIguais) return 'Diferenca';
  if (modo == _DescontoModo.precoFinal && resultado.sistemaMaior) {
    return 'Acrecimo';
  }
  return 'Desconto';
}

String _diferencaTotalLabel(DescontoResultado? resultado, _DescontoModo modo) {
  if (modo == _DescontoModo.trocaMoedas) return 'Total das porcentagens';
  if (resultado == null) return 'Diferenca total';
  return '${_diferencaLabel(resultado, modo)} total';
}

String _copyLabel(DescontoResultado? resultado, _DescontoModo modo) {
  if (modo == _DescontoModo.trocaMoedas) return 'Copiar troca';
  if (resultado == null) return 'Copiar resultado';
  if (modo == _DescontoModo.precoFinal && resultado.sistemaMaior) {
    return 'Copiar acrecimo';
  }
  if (resultado.valoresIguais) return 'Copiar conferencia';
  return 'Copiar desconto';
}

Color _statusColor(DescontoResultado? resultado, _DescontoModo modo) {
  if (resultado == null || resultado.valoresIguais) {
    return AppColors.textSecondary;
  }
  if (modo == _DescontoModo.trocaMoedas) {
    return AppColors.success;
  }
  if (modo == _DescontoModo.precoFinal && resultado.sistemaMaior) {
    return AppColors.warning;
  }
  return AppColors.success;
}

String _modoLabelFromStorage(String value) {
  return switch (value) {
    'percentual' => 'Percentual',
    'preco_final' => 'Preco final',
    'leve_pague' => 'Leve/Pague',
    'troca_moedas' => 'Moedas',
    _ => 'Etiqueta x PDV',
  };
}
