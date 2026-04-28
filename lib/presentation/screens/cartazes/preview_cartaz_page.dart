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
    addIf(data.unidade.trim().isNotEmpty, CartazTextElement.unidade);
    addIf((data.validade ?? '').trim().isNotEmpty, CartazTextElement.validade);

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
      case CartazTamanho.a4:
        return PdfPageFormat.a4;
      case CartazTamanho.a3:
        return PdfPageFormat.a3;
      case CartazTamanho.a2:
        return const PdfPageFormat(
          420 * PdfPageFormat.mm,
          594 * PdfPageFormat.mm,
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
    final longestSide = _posterSize.longestSide;
    if (longestSide <= 900) return 2.0;
    if (longestSide <= 1400) return 1.6;
    return 1.0;
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
          child: pw.Image(img, fit: pw.BoxFit.contain),
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
      horizontalPadding: 24,
      verticalPadding: 48,
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
  }) {
    final element = _effectiveSelectedElement;
    final current = cartazTextAdjustmentFor(_textAdjustments, element);

    setState(() {
      _textAdjustments[element] = current.copyWith(
        offset: offset,
        scale: scale,
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
        title: Text('${widget.data.tipo.label} - ${widget.data.tamanho.label}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = _previewScale(constraints);
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
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
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
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
            _buildAdjustmentPanel(),
          ],
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
      ),
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
