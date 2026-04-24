import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/cartaz_form_data.dart';
import '../../widgets/cartazes/poster_canvas.dart';
import '../../widgets/cartazes/poster_factory.dart';

class PreviewCartazPage extends StatefulWidget {
  final CartazFormData data;

  const PreviewCartazPage({super.key, required this.data});

  @override
  State<PreviewCartazPage> createState() => _PreviewCartazPageState();
}

class _PreviewCartazPageState extends State<PreviewCartazPage> {
  final _screenshotController = ScreenshotController();
  bool _exporting = false;

  Size get _posterSize => PosterCanvas.canvasSizeFor(widget.data.tamanho);

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
    final prod = widget.data.tituloLinha1
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        .toLowerCase();
    return 'cartaz_${prod}_${widget.data.tamanho.label.toLowerCase()}';
  }

  double get _capturePixelRatio {
    final longestSide = _posterSize.longestSide;
    if (longestSide <= 900) return 2.0;
    if (longestSide <= 1400) return 1.6;
    return 1.0;
  }

  Widget _buildTemplate() {
    return buildPosterWidget(widget.data);
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
    setState(() => _exporting = true);
    try {
      final pngBytes = await _capturarPNG();
      await Share.shareXFiles([
        XFile.fromData(
          pngBytes,
          mimeType: 'image/png',
          name: '$_nomeArquivo.png',
        ),
      ]);
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _compartilharPDF() async {
    setState(() => _exporting = true);
    try {
      final pngBytes = await _capturarPNG();
      final pdfBytes = await _gerarPDF(pngBytes);
      await Printing.sharePdf(bytes: pdfBytes, filename: '$_nomeArquivo.pdf');
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _imprimir() async {
    setState(() => _exporting = true);
    try {
      final pngBytes = await _capturarPNG();
      final pdfBytes = await _gerarPDF(pngBytes);
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'Cartaz ${widget.data.tituloLinha1}',
      );
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _mostrarErro(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro: $e')),
    );
  }

  double _previewScale(BoxConstraints constraints) {
    final usableWidth = math.max(1, constraints.maxWidth - 24);
    final usableHeight = math.max(1, constraints.maxHeight - 48);
    final scaleByWidth = usableWidth / _posterSize.width;
    final scaleByHeight = usableHeight / _posterSize.height;
    return math.min(scaleByWidth, scaleByHeight).clamp(0.08, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text('${widget.data.tipo.label} · ${widget.data.tamanho.label}'),
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
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.topLeft,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: _buildTemplate(),
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
                child: ElevatedButton.icon(
                  onPressed: _exporting ? null : _compartilharPNG,
                  icon: const Icon(Icons.image_rounded, size: 18),
                  label: const Text('PNG'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exporting ? null : _compartilharPDF,
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCC0000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
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
                  : const Icon(Icons.print_rounded),
              label: Text(_exporting ? 'Gerando...' : 'Imprimir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD6166A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
