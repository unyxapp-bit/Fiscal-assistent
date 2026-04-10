import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/services/cupom_config_service.dart';

class CupomConfigScreen extends StatefulWidget {
  const CupomConfigScreen({super.key});

  @override
  State<CupomConfigScreen> createState() => _CupomConfigScreenState();
}

class _CupomConfigScreenState extends State<CupomConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _subtituloCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _end1Ctrl = TextEditingController();
  final _end2Ctrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _mensagemTopoCtrl = TextEditingController();
  final _mensagemFinalCtrl = TextEditingController();
  final _obsPadraoCtrl = TextEditingController();
  final _textoDestaqueCtrl = TextEditingController();
  final _termoDestaqueItemCtrl = TextEditingController();

  bool _exibirDataHoraEmissao = true;
  bool _centralizarCabecalho = true;
  bool _centralizarRodape = true;
  double _tamanhoFonte = 12;
  int _previewLarguraMm = 58;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _subtituloCtrl.dispose();
    _cnpjCtrl.dispose();
    _end1Ctrl.dispose();
    _end2Ctrl.dispose();
    _telefoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _instagramCtrl.dispose();
    _websiteCtrl.dispose();
    _mensagemTopoCtrl.dispose();
    _mensagemFinalCtrl.dispose();
    _obsPadraoCtrl.dispose();
    _textoDestaqueCtrl.dispose();
    _termoDestaqueItemCtrl.dispose();
    super.dispose();
  }

  List<TextEditingController> get _allControllers => [
        _tituloCtrl,
        _subtituloCtrl,
        _cnpjCtrl,
        _end1Ctrl,
        _end2Ctrl,
        _telefoneCtrl,
        _whatsappCtrl,
        _instagramCtrl,
        _websiteCtrl,
        _mensagemTopoCtrl,
        _mensagemFinalCtrl,
        _obsPadraoCtrl,
        _textoDestaqueCtrl,
        _termoDestaqueItemCtrl,
      ];

  int get _camposPreenchidos =>
      _allControllers.where((c) => c.text.trim().isNotEmpty).length;

  int get _totalCampos => _allControllers.length;

  int get _larguraPreviewChars => _previewLarguraMm == 58 ? 32 : 42;

  String get _nivelConfiguracao {
    if (_camposPreenchidos >= 11) return 'Configuracao completa';
    if (_camposPreenchidos >= 7) return 'Configuracao avancada';
    return 'Configuracao basica';
  }

  Future<void> _carregar() async {
    try {
      final config = await CupomConfigService.carregar();
      if (!mounted) return;

      setState(() {
        _aplicarConfig(config);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar configuracao: $e')),
      );
    }
  }

  void _aplicarConfig(CupomDadosConfig config) {
    _tituloCtrl.text = config.tituloCabecalho;
    _subtituloCtrl.text = config.subtituloCabecalho;
    _cnpjCtrl.text = config.cnpj;
    _end1Ctrl.text = config.enderecoLinha1;
    _end2Ctrl.text = config.enderecoLinha2;
    _telefoneCtrl.text = config.telefone;
    _whatsappCtrl.text = config.whatsapp;
    _instagramCtrl.text = config.instagram;
    _websiteCtrl.text = config.website;
    _mensagemTopoCtrl.text = config.mensagemTopo;
    _mensagemFinalCtrl.text = config.mensagemFinal;
    _obsPadraoCtrl.text = config.observacaoPadrao;
    _textoDestaqueCtrl.text = config.textoDestaque;
    _termoDestaqueItemCtrl.text = config.termoDestaqueItem;
    _exibirDataHoraEmissao = config.exibirDataHoraEmissao;
    _centralizarCabecalho = config.centralizarCabecalho;
    _centralizarRodape = config.centralizarRodape;
    _tamanhoFonte = config.tamanhoFonte;
  }

  CupomDadosConfig _fromForm() {
    return CupomDadosConfig(
      tituloCabecalho: _tituloCtrl.text,
      subtituloCabecalho: _subtituloCtrl.text,
      cnpj: _cnpjCtrl.text,
      enderecoLinha1: _end1Ctrl.text,
      enderecoLinha2: _end2Ctrl.text,
      telefone: _telefoneCtrl.text,
      whatsapp: _whatsappCtrl.text,
      instagram: _instagramCtrl.text,
      website: _websiteCtrl.text,
      mensagemTopo: _mensagemTopoCtrl.text,
      mensagemFinal: _mensagemFinalCtrl.text,
      observacaoPadrao: _obsPadraoCtrl.text,
      exibirDataHoraEmissao: _exibirDataHoraEmissao,
      tamanhoFonte: _tamanhoFonte,
      centralizarCabecalho: _centralizarCabecalho,
      centralizarRodape: _centralizarRodape,
      textoDestaque: _textoDestaqueCtrl.text,
      termoDestaqueItem: _termoDestaqueItemCtrl.text,
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await CupomConfigService.salvar(_fromForm());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuracao do cupom salva com sucesso.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _restaurarPadrao() async {
    setState(() => _saving = true);
    try {
      final padrao = await CupomConfigService.restaurarPadrao();
      if (!mounted) return;

      setState(() {
        _aplicarConfig(padrao);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Configuracao padrao restaurada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao restaurar padrao: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _duasCasas(int valor) => valor.toString().padLeft(2, '0');

  String _centralizar(String texto, int largura) {
    final t = texto.trim();
    if (t.isEmpty || t.length >= largura) return t;
    final total = largura - t.length;
    final left = total ~/ 2;
    final right = total - left;
    return '${' ' * left}$t${' ' * right}';
  }

  String _linhaRegua(String simbolo) => simbolo * _larguraPreviewChars;

  String _preview() {
    final c = _fromForm();
    final b = StringBuffer();
    final agora = DateTime.now();

    void writeCabecalho(String text) {
      final t = text.trim();
      if (t.isEmpty) return;
      b.writeln(
          c.centralizarCabecalho ? _centralizar(t, _larguraPreviewChars) : t);
    }

    b.writeln(_linhaRegua('='));
    writeCabecalho(
      c.tituloCabecalho.trim().isEmpty
          ? 'PIZZARIA CARROSSEL'
          : c.tituloCabecalho,
    );
    writeCabecalho(c.subtituloCabecalho);
    if (c.cnpj.trim().isNotEmpty) {
      writeCabecalho('CNPJ: ${c.cnpj.trim()}');
    }
    writeCabecalho(c.enderecoLinha1);
    writeCabecalho(c.enderecoLinha2);
    if (c.telefone.trim().isNotEmpty) {
      writeCabecalho('TEL: ${c.telefone.trim()}');
    }
    if (c.whatsapp.trim().isNotEmpty) {
      writeCabecalho('WHATS: ${c.whatsapp.trim()}');
    }
    if (c.instagram.trim().isNotEmpty) {
      writeCabecalho('INSTA: ${c.instagram.trim()}');
    }
    if (c.website.trim().isNotEmpty) {
      writeCabecalho('SITE: ${c.website.trim()}');
    }
    b.writeln(_linhaRegua('='));

    if (c.exibirDataHoraEmissao) {
      final data =
          '${_duasCasas(agora.day)}/${_duasCasas(agora.month)}/${agora.year} ${_duasCasas(agora.hour)}:${_duasCasas(agora.minute)}';
      b.writeln('Emissao      : $data');
    }

    b.writeln('Cod. Entrega : A123');
    b.writeln('Data         : 30/03/2026');
    b.writeln('Horario      : 20:45');
    b.writeln('Cliente      : Cliente Exemplo');
    b.writeln(_linhaRegua('-'));

    if (c.mensagemTopo.trim().isNotEmpty) {
      b.writeln('MSG: ${c.mensagemTopo.trim()}');
      b.writeln(_linhaRegua('-'));
    }

    if (c.textoDestaque.trim().isNotEmpty) {
      b.writeln('>>> ${c.textoDestaque.trim().toUpperCase()} <<<');
      b.writeln(_linhaRegua('-'));
    }

    b.writeln('ITENS:');
    b.writeln(_linhaRegua('-'));
    b.writeln('1x Pizza GRANDE');
    b.writeln('   Romana');
    b.writeln('1x Pizza MEDIA (Meio a Meio)');
    b.writeln('   1/2 Calabresa');
    b.writeln('   1/2 Frango c/ Catupiry');

    if (c.termoDestaqueItem.trim().isNotEmpty) {
      b.writeln(_linhaRegua('-'));
      b.writeln(
        'Item com "${c.termoDestaqueItem.trim()}" sera destacado automatico.',
      );
    }

    if (c.observacaoPadrao.trim().isNotEmpty) {
      b.writeln(_linhaRegua('-'));
      b.writeln('OBS: ${c.observacaoPadrao.trim()}');
    }

    b.writeln(_linhaRegua('='));
    final rodape = c.mensagemFinal.trim().isEmpty
        ? 'BOM APETITE!'
        : c.mensagemFinal.trim();
    b.writeln(c.centralizarRodape
        ? _centralizar(rodape, _larguraPreviewChars)
        : rodape);
    b.writeln(_linhaRegua('='));

    return b.toString();
  }

  Widget _secao({
    required IconData icon,
    required String titulo,
    required String descricao,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(child: Text(titulo, style: AppTextStyles.h4)),
              ],
            ),
            SizedBox(height: 4),
            Text(descricao, style: AppTextStyles.caption),
            SizedBox(height: Dimensions.spacingMD),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.spacingMD),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        onChanged: (_) => setState(() {}),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          prefixIcon: icon != null ? Icon(icon) : null,
        ),
      ),
    );
  }

  Widget _switchTile({
    required bool value,
    required String title,
    required String subtitle,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      value: value,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTextStyles.body),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      onChanged: (v) {
        setState(() => onChanged(v));
      },
    );
  }

  Widget _statusChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(Dimensions.radiusSM),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          SizedBox(width: 6),
          Text('$label: ', style: AppTextStyles.caption),
          Text(value, style: AppTextStyles.label),
        ],
      ),
    );
  }

  Widget _resumoConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSM),
                  ),
                  child: Icon(Icons.receipt_long_outlined,
                      color: AppColors.primary),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Configuracao do Cupom', style: AppTextStyles.h4),
                      Text(
                        'Campos vazios ficam ocultos automaticamente na impressao.',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: Dimensions.spacingMD),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statusChip(
                  icon: Icons.checklist_outlined,
                  label: 'Preenchimento',
                  value: '$_camposPreenchidos/$_totalCampos',
                ),
                _statusChip(
                  icon: Icons.stars_outlined,
                  label: 'Nivel',
                  value: _nivelConfiguracao,
                ),
                _statusChip(
                  icon: Icons.text_fields,
                  label: 'Fonte',
                  value: '${_tamanhoFonte.toStringAsFixed(0)} pt',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _configuracaoVisual() {
    return _secao(
      icon: Icons.tune_outlined,
      titulo: 'Visual e Impressao',
      descricao: 'Ajuste tipografia, alinhamento e simulacao de bobina.',
      children: [
        Text(
          'Tamanho da fonte: ${_tamanhoFonte.toStringAsFixed(0)}',
          style: AppTextStyles.body,
        ),
        Slider(
          min: 9,
          max: 22,
          divisions: 13,
          value: _tamanhoFonte.clamp(9, 22),
          label: _tamanhoFonte.toStringAsFixed(0),
          onChanged: (v) => setState(() => _tamanhoFonte = v),
        ),
        SizedBox(height: 4),
        Text(
          'Simulacao de largura da bobina',
          style: AppTextStyles.label,
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text('58mm (mais comum)'),
              selected: _previewLarguraMm == 58,
              onSelected: (_) => setState(() => _previewLarguraMm = 58),
            ),
            ChoiceChip(
              label: Text('80mm'),
              selected: _previewLarguraMm == 80,
              onSelected: (_) => setState(() => _previewLarguraMm = 80),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'A impressao web usa ajuste automatico para reduzir corte lateral.',
          style: AppTextStyles.caption,
        ),
        Divider(height: 24),
        _switchTile(
          value: _centralizarCabecalho,
          title: 'Centralizar cabecalho',
          subtitle: 'Centraliza titulo, subtitulo e dados de contato.',
          onChanged: (v) => _centralizarCabecalho = v,
        ),
        _switchTile(
          value: _centralizarRodape,
          title: 'Centralizar rodape',
          subtitle: 'Centraliza a mensagem final de encerramento.',
          onChanged: (v) => _centralizarRodape = v,
        ),
        _campo(
          controller: _textoDestaqueCtrl,
          label: 'Texto de destaque (opcional)',
          icon: Icons.campaign_outlined,
          hint: 'Ex: PROMOCAO DO DIA',
        ),
        _campo(
          controller: _termoDestaqueItemCtrl,
          label: 'Termo para destacar item (opcional)',
          icon: Icons.local_fire_department_outlined,
          hint: 'Ex: CALABRESA',
        ),
      ],
    );
  }

  Widget _mensagensRegras() {
    return _secao(
      icon: Icons.message_outlined,
      titulo: 'Mensagens e Regras',
      descricao: 'Defina mensagens operacionais e comportamento do cupom.',
      children: [
        _campo(
          controller: _mensagemTopoCtrl,
          label: 'Mensagem de topo (opcional)',
          icon: Icons.north_outlined,
          maxLines: 2,
        ),
        _campo(
          controller: _obsPadraoCtrl,
          label: 'Observacao padrao (opcional)',
          icon: Icons.notes_outlined,
          maxLines: 2,
        ),
        _campo(
          controller: _mensagemFinalCtrl,
          label: 'Mensagem final',
          icon: Icons.celebration_outlined,
          maxLines: 2,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Informe a mensagem final.'
              : null,
        ),
        _switchTile(
          value: _exibirDataHoraEmissao,
          title: 'Exibir data/hora de emissao',
          subtitle: 'Ajuda no controle de pedidos e conferencias.',
          onChanged: (v) => _exibirDataHoraEmissao = v,
        ),
      ],
    );
  }

  Widget _previewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                    child: Text('Preview do Cupom', style: AppTextStyles.h4)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.alertInfo,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSM),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    '$_previewLarguraMm mm',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Simulacao visual do texto final que sera usado na impressao.',
              style: AppTextStyles.caption,
            ),
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                _preview(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: _tamanhoFonte.clamp(9, 22),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _acoesRodape() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _saving ? null : _restaurarPadrao,
            icon: Icon(Icons.refresh),
            label: Text('Restaurar'),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: _saving ? null : _salvar,
            icon: _saving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.save_outlined),
            label: Text('Salvar'),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFormularioSecoes() {
    return [
      _secao(
        icon: Icons.store_outlined,
        titulo: 'Identificacao da Loja',
        descricao: 'Dados exibidos no cabecalho do cupom.',
        children: [
          _campo(
            controller: _tituloCtrl,
            label: 'Titulo do cabecalho',
            icon: Icons.storefront_outlined,
            textCapitalization: TextCapitalization.characters,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Informe o titulo da loja.'
                : null,
          ),
          _campo(
            controller: _subtituloCtrl,
            label: 'Subtitulo (opcional)',
            icon: Icons.short_text,
          ),
          _campo(
            controller: _cnpjCtrl,
            label: 'CNPJ (opcional)',
            icon: Icons.badge_outlined,
          ),
        ],
      ),
      SizedBox(height: Dimensions.spacingMD),
      _secao(
        icon: Icons.location_on_outlined,
        titulo: 'Endereco e Contato',
        descricao: 'Informacoes para cliente e canais de atendimento.',
        children: [
          _campo(
            controller: _end1Ctrl,
            label: 'Endereco linha 1 (opcional)',
            icon: Icons.home_outlined,
          ),
          _campo(
            controller: _end2Ctrl,
            label: 'Endereco linha 2 (opcional)',
            icon: Icons.pin_drop_outlined,
          ),
          _campo(
            controller: _telefoneCtrl,
            label: 'Telefone (opcional)',
            icon: Icons.call_outlined,
          ),
          _campo(
            controller: _whatsappCtrl,
            label: 'WhatsApp (opcional)',
            icon: Icons.chat_outlined,
          ),
          _campo(
            controller: _instagramCtrl,
            label: 'Instagram (opcional)',
            icon: Icons.camera_alt_outlined,
          ),
          _campo(
            controller: _websiteCtrl,
            label: 'Site (opcional)',
            icon: Icons.language_outlined,
          ),
        ],
      ),
      SizedBox(height: Dimensions.spacingMD),
      _configuracaoVisual(),
      SizedBox(height: Dimensions.spacingMD),
      _mensagensRegras(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Dados do Cupom'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPad = Dimensions.hPad(constraints.maxWidth);
                  final secoes = _buildFormularioSecoes();
                  final isWide = constraints.maxWidth >= 1080;

                  if (isWide) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        Dimensions.paddingMD,
                        horizontalPad,
                        Dimensions.paddingLG,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _resumoConfig(),
                                SizedBox(height: Dimensions.spacingMD),
                                ...secoes,
                                SizedBox(height: Dimensions.spacingMD),
                                _acoesRodape(),
                              ],
                            ),
                          ),
                          SizedBox(width: Dimensions.spacingMD),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _previewCard(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      Dimensions.paddingMD,
                      horizontalPad,
                      Dimensions.paddingLG,
                    ),
                    children: [
                      _resumoConfig(),
                      SizedBox(height: Dimensions.spacingMD),
                      ...secoes,
                      SizedBox(height: Dimensions.spacingMD),
                      _previewCard(),
                      SizedBox(height: Dimensions.spacingMD),
                      _acoesRodape(),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
