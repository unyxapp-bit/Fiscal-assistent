import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/cartaz_form_data.dart';
import '../../widgets/cartazes/cartaz_text_adjustments.dart';
import '../../widgets/cartazes/poster_canvas.dart';
import '../../widgets/cartazes/poster_factory.dart';
import 'cartaz_history_store.dart';
import 'cartaz_workspace_layout.dart';

class PreviewCartazPage extends StatefulWidget {
  final CartazFormData data;
  final String? savedCartazId;
  final CartazTextAdjustments? initialTextAdjustments;

  const PreviewCartazPage({
    super.key,
    required this.data,
    this.savedCartazId,
    this.initialTextAdjustments,
  });

  @override
  State<PreviewCartazPage> createState() => _PreviewCartazPageState();
}

class _PreviewCartazPageState extends State<PreviewCartazPage> {
  final _screenshotController = ScreenshotController();
  late final String _savedCartazId;
  late final CartazTextAdjustments _textAdjustments;
  Timer? _persistDebounce;
  bool _exporting = false;
  bool _adjusting = false;
  CartazTextElement _selectedElement = CartazTextElement.tituloLinha1;

  static const _minOffset = -0.18;
  static const _maxOffset = 0.18;
  static const _minScale = 0.65;
  static const _maxScale = 1.45;
  static const _colorPalette = <int>[
    0xFF111827,
    0xFFFFFFFF,
    0xFFD6166A,
    0xFFE52420,
    0xFFF59E0B,
    0xFF16A34A,
    0xFF1565C0,
    0xFF7C3AED,
  ];
  static const _fontWeightOptions = <int>[400, 700, 900];

  @override
  void initState() {
    super.initState();
    _savedCartazId = widget.savedCartazId ?? CartazHistoryStore.newId();
    _textAdjustments = Map<CartazTextElement, CartazTextAdjustment>.from(
      widget.initialTextAdjustments ?? const {},
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _persistCartaz());
  }

  @override
  void dispose() {
    _persistDebounce?.cancel();
    super.dispose();
  }

  Size get _posterSize => PosterCanvas.canvasSizeFor(widget.data.tamanho);

  List<CartazTextElement> get _availableElements {
    final data = widget.data;
    final elements = <CartazTextElement>[];

    void addIf(bool condition, CartazTextElement element) {
      if (condition) elements.add(element);
    }

    addIf(data.tituloLinha1.trim().isNotEmpty, CartazTextElement.tituloLinha1);
    addIf(data.tituloLinha2.trim().isNotEmpty, CartazTextElement.tituloLinha2);
    addIf(data.subtitulo.trim().isNotEmpty, CartazTextElement.subtitulo);
    addIf((data.detalhe ?? '').trim().isNotEmpty, CartazTextElement.detalhe);
    addIf(data.preco.trim().isNotEmpty, CartazTextElement.preco);
    addIf(
      (data.precoAnterior ?? '').trim().isNotEmpty,
      CartazTextElement.precoAnterior,
    );
    addIf(data.unidade.trim().isNotEmpty, CartazTextElement.unidade);
    addIf(
      data.linhasInformacaoPromocional.isNotEmpty,
      CartazTextElement.promocao,
    );
    addIf((data.validade ?? '').trim().isNotEmpty, CartazTextElement.validade);
    addIf((data.mensagem ?? '').trim().isNotEmpty, CartazTextElement.mensagem);

    return elements.isEmpty ? [CartazTextElement.tituloLinha1] : elements;
  }

  CartazTextElement get _effectiveSelectedElement {
    final elements = _availableElements;
    if (elements.contains(_selectedElement)) return _selectedElement;
    return elements.first;
  }

  CartazTextAdjustment get _selectedAdjustment {
    return cartazTextAdjustmentFor(_textAdjustments, _effectiveSelectedElement);
  }

  PdfPageFormat get _pdfFormat {
    switch (widget.data.tamanho) {
      case CartazTamanho.a6:
        return const PdfPageFormat(
          105 * PdfPageFormat.mm,
          148 * PdfPageFormat.mm,
        );
      case CartazTamanho.a5:
        return const PdfPageFormat(
          148 * PdfPageFormat.mm,
          210 * PdfPageFormat.mm,
        );
      case CartazTamanho.a4:
        return PdfPageFormat.a4;
      case CartazTamanho.a3:
        return PdfPageFormat.a3;
      case CartazTamanho.a2:
        return const PdfPageFormat(
          420 * PdfPageFormat.mm,
          594 * PdfPageFormat.mm,
        );
      case CartazTamanho.a1:
        return const PdfPageFormat(
          594 * PdfPageFormat.mm,
          841 * PdfPageFormat.mm,
        );
      case CartazTamanho.feedQuadrado:
        return const PdfPageFormat(
          1080 * PdfPageFormat.point,
          1080 * PdfPageFormat.point,
        );
      case CartazTamanho.storyVertical:
        return const PdfPageFormat(
          1080 * PdfPageFormat.point,
          1920 * PdfPageFormat.point,
        );
    }
  }

  String get _nomeArquivo {
    final prod = _slug(widget.data.tituloLinha1);
    return 'cartaz_${prod}_${widget.data.tamanho.label.toLowerCase()}';
  }

  String _slug(String value) {
    var text = value.trim().toLowerCase();
    const replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    for (final entry in replacements.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    final slug = text
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return slug.isEmpty ? 'produto' : slug;
  }

  double get _capturePixelRatio {
    switch (widget.data.tamanho) {
      case CartazTamanho.a6:
        return 2.4;
      case CartazTamanho.a5:
        return 2.1;
      case CartazTamanho.a4:
        return 1.8;
      case CartazTamanho.a3:
        return 1.55;
      case CartazTamanho.a2:
        return 1.3;
      case CartazTamanho.a1:
        return 1.15;
      case CartazTamanho.feedQuadrado:
      case CartazTamanho.storyVertical:
        return 1.0;
    }
  }

  Widget _buildTemplate({bool showSelection = false}) {
    return buildPosterWidget(
      widget.data,
      textAdjustments: _textAdjustments,
      selectedElement: _effectiveSelectedElement,
      showSelection: showSelection,
    );
  }

  Widget _buildCaptureWidget() {
    return Material(
      type: MaterialType.transparency,
      child: _buildTemplate(),
    );
  }

  Future<Uint8List> _capturarPNG() async {
    return _screenshotController.captureFromWidget(
      _buildCaptureWidget(),
      context: context,
      delay: const Duration(milliseconds: 50),
      pixelRatio: _capturePixelRatio,
      targetSize: _posterSize,
    );
  }

  Future<Uint8List> _gerarPDF(Uint8List pngBytes) async {
    final doc = pw.Document();
    final img = pw.MemoryImage(pngBytes);
    doc.addPage(
      pw.Page(
        pageFormat: _pdfFormat.copyWith(
          marginBottom: 0,
          marginLeft: 0,
          marginRight: 0,
          marginTop: 0,
        ),
        build: (_) => pw.SizedBox.expand(
          child: pw.Image(img, fit: pw.BoxFit.fill),
        ),
      ),
    );
    return Uint8List.fromList(await doc.save());
  }

  Future<void> _compartilharPNG() async {
    await _runExport(() async {
      final pngBytes = await _capturarPNG();
      await Share.shareXFiles([
        XFile.fromData(
          pngBytes,
          mimeType: 'image/png',
          name: '$_nomeArquivo.png',
        ),
      ]);
    });
  }

  Future<void> _compartilharPDF() async {
    await _runExport(() async {
      final pngBytes = await _capturarPNG();
      final pdfBytes = await _gerarPDF(pngBytes);
      await Printing.sharePdf(bytes: pdfBytes, filename: '$_nomeArquivo.pdf');
    });
  }

  Future<void> _imprimir() async {
    await _runExport(() async {
      final pngBytes = await _capturarPNG();
      final pdfBytes = await _gerarPDF(pngBytes);
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'Cartaz ${widget.data.tituloLinha1}',
      );
    });
  }

  Future<void> _runExport(Future<void> Function() action) async {
    if (_exporting) return;

    setState(() => _exporting = true);
    try {
      await action();
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _mostrarErro(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao gerar cartaz: $e')),
    );
  }

  double _previewScale(BoxConstraints constraints) {
    return posterPreviewScaleFor(
      posterSize: _posterSize,
      constraints: constraints,
      horizontalPadding: _adjusting ? 12 : 24,
      verticalPadding: _adjusting ? 24 : 48,
      maxScale: _adjusting ? 1.35 : 1.15,
    );
  }

  double _clampDouble(double value, double min, double max) {
    return value.clamp(min, max).toDouble();
  }

  void _selectElement(CartazTextElement element) {
    setState(() => _selectedElement = element);
  }

  void _updateSelected({
    Offset? offset,
    double? scale,
    int? colorValue,
    bool clearColor = false,
    String? fontFamily,
    bool clearFontFamily = false,
    int? fontWeightValue,
    bool clearFontWeight = false,
    CartazTextAlignOption? textAlign,
    bool clearTextAlign = false,
  }) {
    final element = _effectiveSelectedElement;
    final current = cartazTextAdjustmentFor(_textAdjustments, element);

    setState(() {
      _textAdjustments[element] = current.copyWith(
        offset: offset,
        scale: scale,
        colorValue: colorValue,
        clearColor: clearColor,
        fontFamily: fontFamily,
        clearFontFamily: clearFontFamily,
        fontWeightValue: fontWeightValue,
        clearFontWeight: clearFontWeight,
        textAlign: textAlign,
        clearTextAlign: clearTextAlign,
      );
    });
    _schedulePersistCartaz();
  }

  void _moveSelected(Offset delta, double previewScale) {
    if (!_adjusting || previewScale <= 0) return;

    final current = _selectedAdjustment;
    final nextOffset = Offset(
      _clampDouble(
        current.offset.dx + (delta.dx / previewScale / _posterSize.width),
        _minOffset,
        _maxOffset,
      ),
      _clampDouble(
        current.offset.dy + (delta.dy / previewScale / _posterSize.height),
        _minOffset,
        _maxOffset,
      ),
    );

    _updateSelected(offset: nextOffset);
  }

  void _resetSelected() {
    setState(() => _textAdjustments.remove(_effectiveSelectedElement));
    _schedulePersistCartaz();
  }

  void _resetSelectedStyle() {
    final element = _effectiveSelectedElement;
    final current = cartazTextAdjustmentFor(_textAdjustments, element);
    setState(() {
      _textAdjustments[element] = current.copyWith(
        clearColor: true,
        clearFontFamily: true,
        clearFontWeight: true,
        clearTextAlign: true,
      );
    });
    _schedulePersistCartaz();
  }

  void _resetAllAdjustments() {
    setState(_textAdjustments.clear);
    _schedulePersistCartaz();
  }

  void _schedulePersistCartaz() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(
      const Duration(milliseconds: 250),
      _persistCartaz,
    );
  }

  Future<void> _persistCartaz() async {
    await CartazHistoryStore.upsert(
      id: _savedCartazId,
      data: widget.data,
      textAdjustments: _textAdjustments,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text(
          '${widget.data.templateLabel} - ${widget.data.tamanho.label}',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;

          return Column(
            children: [
              _buildWorkspaceBar(),
              Expanded(
                child: wide ? _buildWideEditor() : _buildMobileEditor(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWorkspaceBar() {
    return CartazWorkspaceBar(
      badge:
          'Cartaz / ${widget.data.templateLabel} / ${widget.data.tamanho.label}',
      actions: [
        CartazWorkspaceAction(
          label: 'Editar',
          icon: Icons.edit_rounded,
          onPressed: _exporting ? null : () => Navigator.of(context).pop(),
        ),
        CartazWorkspaceAction(
          label: _adjusting ? 'Concluir' : 'Ajustar',
          icon: _adjusting ? Icons.check_rounded : Icons.tune_rounded,
          selected: _adjusting,
          onPressed: _exporting
              ? null
              : () => setState(() => _adjusting = !_adjusting),
        ),
      ],
    );
  }

  Widget _buildWideEditor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final controlsWidth = constraints.maxWidth < 920 ? 320.0 : 380.0;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: CartazWorkspacePanel(
                  title: 'Cartaz',
                  subtitle: _adjusting
                      ? 'Arraste o texto selecionado no cartaz'
                      : 'Previa final para compartilhar ou imprimir',
                  icon: Icons.dashboard_customize_rounded,
                  expandChild: true,
                  childPadding: EdgeInsets.zero,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final scale = _previewScale(constraints);
                      return _buildPosterStage(
                        scale,
                        padding: const EdgeInsets.all(20),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: controlsWidth,
                child: CartazWorkspacePanel(
                  title: _adjusting ? 'Ajustes' : 'Exportacao',
                  subtitle: _adjusting
                      ? 'Escolha o texto e ajuste posicao'
                      : 'Edite, compartilhe ou imprima',
                  icon:
                      _adjusting ? Icons.tune_rounded : Icons.ios_share_rounded,
                  expandChild: true,
                  child: SingleChildScrollView(
                    child: _buildControlsContent(constrainAdjustment: false),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileEditor() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = _previewScale(constraints);
        final bottomPadding = _adjusting
            ? (constraints.maxHeight * 0.34).clamp(170.0, 260.0).toDouble()
            : 116.0;

        return Stack(
          children: [
            Positioned.fill(
              child: _buildPosterStage(
                scale,
                padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomBar(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPosterStage(
    double scale, {
    required EdgeInsets padding,
  }) {
    return SingleChildScrollView(
      padding: padding,
      child: Center(
        child: SizedBox(
          width: _posterSize.width * scale,
          height: _posterSize.height * scale,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: _adjusting
                ? (details) => _moveSelected(details.delta, scale)
                : null,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: Align(
                alignment: Alignment.topLeft,
                child: _buildTemplate(
                  showSelection: _adjusting,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: _buildControlsContent(constrainAdjustment: true),
    );
  }

  Widget _buildControlsContent({required bool constrainAdjustment}) {
    final adjustmentPanel = constrainAdjustment
        ? ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.34,
            ),
            child: SingleChildScrollView(
              child: _buildAdjustmentPanel(),
            ),
          )
        : _buildAdjustmentPanel();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _exporting ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Editar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exporting
                    ? null
                    : () => setState(() => _adjusting = !_adjusting),
                icon: Icon(
                  _adjusting ? Icons.check_rounded : Icons.tune_rounded,
                  size: 18,
                ),
                label: Text(_adjusting ? 'Concluir' : 'Ajustar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
        if (_adjusting) ...[
          const SizedBox(height: 12),
          adjustmentPanel,
        ],
        if (!_adjusting) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exporting ? null : _compartilharPNG,
                  icon: const Icon(Icons.image_rounded, size: 18),
                  label: const Text('PNG'),
                  style: _exportButtonStyle(const Color(0xFF1565C0)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exporting ? null : _compartilharPDF,
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('PDF'),
                  style: _exportButtonStyle(const Color(0xFFCC0000)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exporting ? null : _imprimir,
                  icon: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.print_rounded, size: 18),
                  label: Text(_exporting ? 'Gerando' : 'Imprimir'),
                  style: _exportButtonStyle(const Color(0xFFD6166A)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  ButtonStyle _exportButtonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildAdjustmentPanel() {
    final elements = _availableElements;
    final selected = _effectiveSelectedElement;
    final adjustment = _selectedAdjustment;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: elements.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final element = elements[index];
                  return ChoiceChip(
                    label: Text(element.label),
                    selected: element == selected,
                    onSelected: (_) => _selectElement(element),
                    selectedColor: const Color(0xFF1565C0),
                    labelStyle: TextStyle(
                      color: element == selected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            _AdjustmentSlider(
              label: 'X',
              value: adjustment.offset.dx,
              min: _minOffset,
              max: _maxOffset,
              divisions: 72,
              valueText: '${(adjustment.offset.dx * 100).round()}%',
              onChanged: (value) => _updateSelected(
                offset: Offset(value, adjustment.offset.dy),
              ),
            ),
            _AdjustmentSlider(
              label: 'Y',
              value: adjustment.offset.dy,
              min: _minOffset,
              max: _maxOffset,
              divisions: 72,
              valueText: '${(adjustment.offset.dy * 100).round()}%',
              onChanged: (value) => _updateSelected(
                offset: Offset(adjustment.offset.dx, value),
              ),
            ),
            _AdjustmentSlider(
              label: 'Tamanho',
              value: adjustment.scale,
              min: _minScale,
              max: _maxScale,
              divisions: 80,
              valueText: '${(adjustment.scale * 100).round()}%',
              onChanged: (value) => _updateSelected(scale: value),
            ),
            const SizedBox(height: 8),
            _buildStyleControls(adjustment),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetSelected,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Resetar item'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetAllAdjustments,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Resetar tudo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleControls(CartazTextAdjustment adjustment) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey(
                  'font-${_effectiveSelectedElement.name}-${adjustment.fontFamily ?? ''}',
                ),
                initialValue: adjustment.fontFamily ?? '',
                isDense: true,
                decoration: const InputDecoration(
                  labelText: 'Fonte',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                items: [
                  for (final option in cartazFontOptions)
                    DropdownMenuItem<String>(
                      value: option.family ?? '',
                      child: Text(option.label),
                    ),
                ],
                onChanged: (value) {
                  final family = (value ?? '').trim();
                  _updateSelected(
                    fontFamily: family.isEmpty ? null : family,
                    clearFontFamily: family.isEmpty,
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey(
                  'weight-${_effectiveSelectedElement.name}-${adjustment.fontWeightValue ?? 0}',
                ),
                initialValue: adjustment.fontWeightValue ?? 0,
                isDense: true,
                decoration: const InputDecoration(
                  labelText: 'Peso',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: 0,
                    child: Text('Padrao'),
                  ),
                  for (final weight in _fontWeightOptions)
                    DropdownMenuItem<int>(
                      value: weight,
                      child: Text(_fontWeightLabel(weight)),
                    ),
                ],
                onChanged: (value) {
                  final weight = value ?? 0;
                  _updateSelected(
                    fontWeightValue: weight == 0 ? null : weight,
                    clearFontWeight: weight == 0,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(
              width: 72,
              child: Text(
                'Alinhar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ToggleButtons(
              isSelected: [
                for (final option in CartazTextAlignOption.values)
                  adjustment.textAlign == option,
              ],
              onPressed: (index) {
                final option = CartazTextAlignOption.values[index];
                final selected = adjustment.textAlign == option;
                _updateSelected(
                  textAlign: selected ? null : option,
                  clearTextAlign: selected,
                );
              },
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints.tightFor(
                width: 42,
                height: 34,
              ),
              children: [
                for (final option in CartazTextAlignOption.values)
                  Icon(option.icon, size: 18),
              ],
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _resetSelectedStyle,
              icon: const Icon(Icons.format_clear_rounded, size: 18),
              label: const Text('Estilo'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildColorPalette(adjustment),
      ],
    );
  }

  Widget _buildColorPalette(CartazTextAdjustment adjustment) {
    return Row(
      children: [
        const SizedBox(
          width: 72,
          child: Text(
            'Cor',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ColorSwatchButton(
                colorValue: null,
                selected: adjustment.colorValue == null,
                tooltip: 'Cor do template',
                onTap: () => _updateSelected(clearColor: true),
              ),
              for (final colorValue in _colorPalette)
                _ColorSwatchButton(
                  colorValue: colorValue,
                  selected: adjustment.colorValue == colorValue,
                  tooltip: 'Aplicar cor',
                  onTap: () => _updateSelected(colorValue: colorValue),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _fontWeightLabel(int weight) {
    switch (weight) {
      case 400:
        return 'Normal';
      case 700:
        return 'Bold';
      case 900:
        return 'Black';
    }
    return weight.toString();
  }
}

class _ColorSwatchButton extends StatelessWidget {
  final int? colorValue;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  const _ColorSwatchButton({
    required this.colorValue,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorValue == null ? null : Color(colorValue!);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color ?? Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? const Color(0xFF1565C0) : Colors.grey.shade400,
              width: selected ? 3 : 1,
            ),
          ),
          child: color == null
              ? const Icon(Icons.format_color_reset_rounded, size: 17)
              : null,
        ),
      ),
    );
  }
}

class _AdjustmentSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueText;
  final ValueChanged<double> onChanged;

  const _AdjustmentSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: valueText,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            valueText,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
