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

  bool _exibirDataHoraEmissao = true;
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
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final config = await CupomConfigService.carregar();
      if (!mounted) return;
      setState(() {
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
        _exibirDataHoraEmissao = config.exibirDataHoraEmissao;
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
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await CupomConfigService.salvar(_fromForm());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Configuracao do cupom salva com sucesso.')),
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
        _tituloCtrl.text = padrao.tituloCabecalho;
        _subtituloCtrl.text = padrao.subtituloCabecalho;
        _cnpjCtrl.text = padrao.cnpj;
        _end1Ctrl.text = padrao.enderecoLinha1;
        _end2Ctrl.text = padrao.enderecoLinha2;
        _telefoneCtrl.text = padrao.telefone;
        _whatsappCtrl.text = padrao.whatsapp;
        _instagramCtrl.text = padrao.instagram;
        _websiteCtrl.text = padrao.website;
        _mensagemTopoCtrl.text = padrao.mensagemTopo;
        _mensagemFinalCtrl.text = padrao.mensagemFinal;
        _obsPadraoCtrl.text = padrao.observacaoPadrao;
        _exibirDataHoraEmissao = padrao.exibirDataHoraEmissao;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuracao padrao restaurada.')),
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

  String _preview() {
    const linha = '================================';
    final c = _fromForm();
    final b = StringBuffer();

    b.writeln(linha);
    b.writeln(
        '      ${c.tituloCabecalho.trim().isEmpty ? 'PIZZARIA CARROSSEL' : c.tituloCabecalho.trim()}');
    if (c.subtituloCabecalho.trim().isNotEmpty) {
      b.writeln('      ${c.subtituloCabecalho.trim()}');
    }
    if (c.cnpj.trim().isNotEmpty) {
      b.writeln('      CNPJ: ${c.cnpj.trim()}');
    }
    if (c.enderecoLinha1.trim().isNotEmpty) {
      b.writeln('      ${c.enderecoLinha1.trim()}');
    }
    if (c.enderecoLinha2.trim().isNotEmpty) {
      b.writeln('      ${c.enderecoLinha2.trim()}');
    }
    b.writeln(linha);
    if (c.exibirDataHoraEmissao) {
      b.writeln('Emissao      : 29/03/2026 18:30');
    }
    b.writeln('Cod. Entrega : A123');
    b.writeln('Cliente      : Cliente Exemplo');
    if (c.mensagemTopo.trim().isNotEmpty) {
      b.writeln('MSG: ${c.mensagemTopo.trim()}');
    }
    b.writeln('...');
    if (c.observacaoPadrao.trim().isNotEmpty) {
      b.writeln('OBS: ${c.observacaoPadrao.trim()}');
    }
    b.writeln(linha);
    b.writeln(
        '       ${c.mensagemFinal.trim().isEmpty ? 'BOM APETITE!' : c.mensagemFinal.trim()}');
    b.writeln(linha);
    if (c.telefone.trim().isNotEmpty) {
      b.writeln('Tel: ${c.telefone.trim()}');
    }
    if (c.whatsapp.trim().isNotEmpty) {
      b.writeln('WhatsApp: ${c.whatsapp.trim()}');
    }
    if (c.instagram.trim().isNotEmpty) {
      b.writeln('Instagram: ${c.instagram.trim()}');
    }
    if (c.website.trim().isNotEmpty) {
      b.writeln('Site: ${c.website.trim()}');
    }

    return b.toString();
  }

  Widget _secao({
    required IconData icon,
    required String titulo,
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
                const SizedBox(width: 8),
                Text(titulo, style: AppTextStyles.h4),
              ],
            ),
            const SizedBox(height: Dimensions.spacingMD),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dados do Cupom'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(Dimensions.paddingMD),
                children: [
                  const Text(
                    'Edite os dados de identificacao e comunicacao do cupom da pizzaria. '
                    'As alteracoes sao salvas no Supabase e valem para seu usuario.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: Dimensions.spacingMD),
                  _secao(
                    icon: Icons.store_outlined,
                    titulo: 'Identificacao',
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
                        hint: 'Ex: Unidade Centro',
                      ),
                      _campo(
                        controller: _cnpjCtrl,
                        label: 'CNPJ (opcional)',
                        icon: Icons.badge_outlined,
                        hint: '00.000.000/0001-00',
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spacingMD),
                  _secao(
                    icon: Icons.location_on_outlined,
                    titulo: 'Endereco e Contato',
                    children: [
                      _campo(
                        controller: _end1Ctrl,
                        label: 'Endereco linha 1 (opcional)',
                        icon: Icons.home_outlined,
                        hint: 'Rua, numero e bairro',
                      ),
                      _campo(
                        controller: _end2Ctrl,
                        label: 'Endereco linha 2 (opcional)',
                        icon: Icons.pin_drop_outlined,
                        hint: 'Cidade - UF',
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
                        hint: '@sualoja',
                      ),
                      _campo(
                        controller: _websiteCtrl,
                        label: 'Site (opcional)',
                        icon: Icons.language_outlined,
                        hint: 'www.seusite.com.br',
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spacingMD),
                  _secao(
                    icon: Icons.message_outlined,
                    titulo: 'Mensagens e Regras',
                    children: [
                      _campo(
                        controller: _mensagemTopoCtrl,
                        label: 'Mensagem de topo (opcional)',
                        icon: Icons.north_outlined,
                        hint: 'Ex: Pedido sujeito a disponibilidade',
                        maxLines: 2,
                      ),
                      _campo(
                        controller: _obsPadraoCtrl,
                        label: 'Observacao padrao (opcional)',
                        icon: Icons.notes_outlined,
                        hint: 'Ex: Confira o pedido ao receber',
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
                      SwitchListTile(
                        value: _exibirDataHoraEmissao,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Exibir data/hora de emissao'),
                        subtitle: const Text(
                          'Inclui no cupom o momento em que ele foi gerado.',
                          style: AppTextStyles.caption,
                        ),
                        onChanged: (v) => setState(() {
                          _exibirDataHoraEmissao = v;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spacingMD),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Preview', style: AppTextStyles.h4),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _preview(),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.spacingMD),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _restaurarPadrao,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Restaurar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _salvar,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: const Text('Salvar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
