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
  final _linhaAdicionalCtrl = TextEditingController();
  final _mensagemFinalCtrl = TextEditingController();

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
    _linhaAdicionalCtrl.dispose();
    _mensagemFinalCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final config = await CupomConfigService.carregar();
    if (!mounted) return;
    setState(() {
      _tituloCtrl.text = config.tituloCabecalho;
      _linhaAdicionalCtrl.text = config.linhaAdicional;
      _mensagemFinalCtrl.text = config.mensagemFinal;
      _loading = false;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    await CupomConfigService.salvar(
      CupomDadosConfig(
        tituloCabecalho: _tituloCtrl.text,
        linhaAdicional: _linhaAdicionalCtrl.text,
        mensagemFinal: _mensagemFinalCtrl.text,
      ),
    );

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados do cupom salvos com sucesso.')),
    );
  }

  Future<void> _restaurarPadrao() async {
    setState(() => _saving = true);
    final padrao = await CupomConfigService.restaurarPadrao();

    if (!mounted) return;
    setState(() {
      _tituloCtrl.text = padrao.tituloCabecalho;
      _linhaAdicionalCtrl.text = padrao.linhaAdicional;
      _mensagemFinalCtrl.text = padrao.mensagemFinal;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuracao padrao restaurada.')),
    );
  }

  String _preview() {
    const linha = '================================';
    final titulo = _tituloCtrl.text.trim().isEmpty
        ? 'PIZZARIA CARROSSEL'
        : _tituloCtrl.text.trim();
    final linhaAdicional = _linhaAdicionalCtrl.text.trim();
    final mensagemFinal = _mensagemFinalCtrl.text.trim().isEmpty
        ? 'BOM APETITE!'
        : _mensagemFinalCtrl.text.trim();

    final b = StringBuffer()
      ..writeln(linha)
      ..writeln('      $titulo');
    if (linhaAdicional.isNotEmpty) {
      b.writeln('      $linhaAdicional');
    }
    b
      ..writeln(linha)
      ..writeln('...')
      ..writeln('       $mensagemFinal')
      ..writeln(linha);
    return b.toString();
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
                    'Edite os dados exibidos no cabecalho e no rodape do cupom da pizzaria.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: Dimensions.spacingMD),
                  TextFormField(
                    controller: _tituloCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Titulo do cabecalho',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o titulo.'
                        : null,
                  ),
                  const SizedBox(height: Dimensions.spacingMD),
                  TextFormField(
                    controller: _linhaAdicionalCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Linha adicional (opcional)',
                      hintText: 'Ex: Delivery (11) 99999-9999',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: Dimensions.spacingMD),
                  TextFormField(
                    controller: _mensagemFinalCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mensagem final do cupom',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.celebration_outlined),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe a mensagem final.'
                        : null,
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
                          label: const Text('Restaurar Padrao'),
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
