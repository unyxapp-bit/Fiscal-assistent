import 'package:flutter/material.dart';

import '../../../data/models/cartaz_form_data.dart';
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

  bool get _isAproveite => widget.tipo == CartazTemplateTipo.aproveiteAgora;
  bool get _isProximo => widget.tipo == CartazTemplateTipo.proximoVencimento;
  bool get _isOferta => widget.tipo == CartazTemplateTipo.oferta;

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
      detalhe: _detalheCtrl.text.trim(),
      preco: _precoCtrl.text.trim(),
      unidade: _unidadeCtrl.text.trim(),
      validade: _validadeCtrl.text.trim(),
    );
  }

  void _visualizar() {
    if (_linha1Ctrl.text.trim().isEmpty || _precoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o produto e o preco')),
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
        title: Text(widget.tipo.label),
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
                    hint: _isAproveite
                        ? 'Ex: LAVA ROUPAS'
                        : _isProximo
                            ? 'Ex: TERERE LEAO'
                            : 'Ex: BISCOITO RECHEADO',
                  ),
                  const SizedBox(height: 10),
                  _campo(
                    controller: _linha2Ctrl,
                    label: 'Linha 2 - complemento',
                    hint: _isAproveite
                        ? 'Ex: LIQ. CLASSE A'
                        : _isProximo
                            ? 'Ex: 500G'
                            : 'Ex: DANY SABORES',
                  ),
                  const SizedBox(height: 10),
                  _campo(
                    controller: _subtituloCtrl,
                    label: _isProximo ? 'Sabor / tipo' : 'Peso / volume',
                    hint: _isAproveite
                        ? 'Ex: REFIL 900ML'
                        : _isProximo
                            ? 'Ex: ABACAXI'
                            : 'Ex: 130G',
                  ),
                  if (_isAproveite || _isOferta) ...[
                    const SizedBox(height: 10),
                    _campo(
                      controller: _detalheCtrl,
                      label: _isAproveite
                          ? 'Fragrancia / sabor'
                          : 'Detalhe / observacao',
                      hint: _isAproveite
                          ? 'Ex: FRAGRANCIAS'
                          : 'Ex: CADA 130 GRAMAS',
                    ),
                  ],
                  const SizedBox(height: 20),
                  _sectionLabel('Preco'),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _campo(
                          controller: _precoCtrl,
                          label: 'Preco *',
                          hint: 'Ex: 9,99',
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          caps: false,
                        ),
                      ),
                      if (!_isOferta) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _campo(
                            controller: _unidadeCtrl,
                            label: 'Unidade',
                            hint: 'Ex: UNID.',
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_isOferta) ...[
                    const SizedBox(height: 10),
                    _campo(
                      controller: _validadeCtrl,
                      label: 'Validade / rodape',
                      hint: 'Ex: VALIDO ATE 26/04/2026',
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
                tipo: widget.tipo,
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
  final CartazTemplateTipo tipo;
  final List<TextEditingController> ctrls;
  final CartazFormData Function() buildData;

  const _LivePreview({
    required this.tipo,
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
          final usableWidth =
              (constraints.maxWidth - 40).clamp(1.0, double.infinity);
          final usableHeight =
              (constraints.maxHeight - 72).clamp(1.0, double.infinity);
          final scaleByWidth = usableWidth / posterSize.width;
          final scaleByHeight = usableHeight / posterSize.height;
          final scale =
              (scaleByWidth < scaleByHeight ? scaleByWidth : scaleByHeight)
                  .clamp(0.08, 0.6);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'PREVIA',
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
