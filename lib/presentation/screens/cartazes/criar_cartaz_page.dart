import 'package:flutter/material.dart';

import '../../../data/models/cartaz_form_data.dart';
import '../../widgets/cartazes/cartaz_template_specs.dart';
import '../../widgets/cartazes/poster_canvas.dart';
import '../../widgets/cartazes/poster_factory.dart';
import 'preview_cartaz_page.dart';

class CriarCartazPage extends StatefulWidget {
  final CartazTemplateTipo tipo;
  final CartazTamanho tamanho;

  const CriarCartazPage({
    super.key,
    required this.tipo,
    required this.tamanho,
  });

  @override
  State<CriarCartazPage> createState() => _CriarCartazPageState();
}

class _CriarCartazPageState extends State<CriarCartazPage> {
  final _linha1Ctrl = TextEditingController();
  final _linha2Ctrl = TextEditingController();
  final _subtituloCtrl = TextEditingController();
  final _detalheCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  final _unidadeCtrl = TextEditingController();
  final _validadeCtrl = TextEditingController();

  CartazTemplateSpec get _spec => cartazTemplateSpec(widget.tipo);
  CartazTemplateFieldHints get _fields => _spec.fields;

  @override
  void dispose() {
    _linha1Ctrl.dispose();
    _linha2Ctrl.dispose();
    _subtituloCtrl.dispose();
    _detalheCtrl.dispose();
    _precoCtrl.dispose();
    _unidadeCtrl.dispose();
    _validadeCtrl.dispose();
    super.dispose();
  }

  CartazFormData _buildData() {
    return CartazFormData(
      tipo: widget.tipo,
      tamanho: widget.tamanho,
      tituloLinha1: _linha1Ctrl.text.trim(),
      tituloLinha2: _linha2Ctrl.text.trim(),
      subtitulo: _subtituloCtrl.text.trim(),
      detalhe: _fields.showDetalhe ? _detalheCtrl.text.trim() : '',
      preco: _normalizarPreco(_precoCtrl.text),
      unidade: _fields.showUnidade ? _unidadeCtrl.text.trim() : '',
      validade: _fields.showValidade ? _validadeCtrl.text.trim() : '',
    );
  }

  String _normalizarPreco(String raw) {
    var text = raw
        .trim()
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', ',');

    text = text.replaceAll(RegExp(r'[^0-9,]'), '');

    final firstComma = text.indexOf(',');
    if (firstComma >= 0) {
      final before = text.substring(0, firstComma + 1);
      final after = text.substring(firstComma + 1).replaceAll(',', '');
      text = '$before$after';
    }

    return text;
  }

  void _visualizar() {
    if (_linha1Ctrl.text.trim().isEmpty ||
        _normalizarPreco(_precoCtrl.text).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o produto e o preço')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PreviewCartazPage(data: _buildData())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_spec.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text(
                widget.tamanho.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              backgroundColor: Colors.grey.shade200,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Produto'),
                  _campo(
                    controller: _linha1Ctrl,
                    label: 'Linha 1 - nome / marca *',
                    hint: _fields.linha1Hint,
                  ),
                  const SizedBox(height: 10),
                  _campo(
                    controller: _linha2Ctrl,
                    label: 'Linha 2 - complemento',
                    hint: _fields.linha2Hint,
                  ),
                  const SizedBox(height: 10),
                  _campo(
                    controller: _subtituloCtrl,
                    label: _fields.subtituloLabel,
                    hint: _fields.subtituloHint,
                  ),
                  if (_fields.showDetalhe) ...[
                    const SizedBox(height: 10),
                    _campo(
                      controller: _detalheCtrl,
                      label: _fields.detalheLabel,
                      hint: _fields.detalheHint,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _sectionLabel('Preço'),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _campo(
                          controller: _precoCtrl,
                          label: 'Preço *',
                          hint: 'Ex: 9,99',
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          caps: false,
                        ),
                      ),
                      if (_fields.showUnidade) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _campo(
                            controller: _unidadeCtrl,
                            label: 'Unidade',
                            hint: _fields.unidadeHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_fields.showValidade) ...[
                    const SizedBox(height: 10),
                    _campo(
                      controller: _validadeCtrl,
                      label: 'Validade / rodapé',
                      hint: _fields.validadeHint,
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _visualizar,
                      icon: const Icon(Icons.visibility_rounded),
                      label: const Text(
                        'Visualizar cartaz',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD6166A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (MediaQuery.of(context).size.width > 700) ...[
            const VerticalDivider(width: 1),
            Expanded(
              flex: 4,
              child: _LivePreview(
                ctrls: [
                  _linha1Ctrl,
                  _linha2Ctrl,
                  _subtituloCtrl,
                  _detalheCtrl,
                  _precoCtrl,
                  _unidadeCtrl,
                  _validadeCtrl,
                ],
                buildData: _buildData,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool caps = true,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      textCapitalization:
          caps ? TextCapitalization.characters : TextCapitalization.none,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD6166A), width: 2),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }
}

class _LivePreview extends StatefulWidget {
  final List<TextEditingController> ctrls;
  final CartazFormData Function() buildData;

  const _LivePreview({
    required this.ctrls,
    required this.buildData,
  });

  @override
  State<_LivePreview> createState() => _LivePreviewState();
}

class _LivePreviewState extends State<_LivePreview> {
  @override
  void initState() {
    super.initState();
    for (final c in widget.ctrls) {
      c.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in widget.ctrls) {
      c.removeListener(_refresh);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.buildData();
    final posterSize = PosterCanvas.canvasSizeFor(data.tamanho);

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = posterPreviewScaleFor(
            posterSize: posterSize,
            constraints: constraints,
            horizontalPadding: 40,
            verticalPadding: 72,
            maxScale: 0.6,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'PRÉVIA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: posterSize.width * scale,
                  height: posterSize.height * scale,
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topLeft,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: buildPosterWidget(data),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
