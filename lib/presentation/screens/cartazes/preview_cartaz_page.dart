import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/cartaz_form_data.dart';
import '../../widgets/cartazes/cartaz_aproveite_agora_widget.dart';
import '../../widgets/cartazes/cartaz_proximo_vencimento_widget.dart';
import '../../widgets/cartazes/cartaz_oferta_widget.dart';

class PreviewCartazPage extends StatefulWidget {
  final CartazFormData data;

  const PreviewCartazPage({super.key, required this.data});

  @override
  State<PreviewCartazPage> createState() => _PreviewCartazPageState();
}

class _PreviewCartazPageState extends State<PreviewCartazPage> {
  final _screenshotController = ScreenshotController();
  bool _exporting = false;

  PdfPageFormat get _pdfFormat {
    switch (widget.data.tamanho) {
      case CartazTamanho.a6:
        return const PdfPageFormat(105 * PdfPageFormat.mm, 148 * PdfPageFormat.mm);
      case CartazTamanho.a4:
        return PdfPageFormat.a4;
      case CartazTamanho.a3:
        return PdfPageFormat.a3;
      case CartazTamanho.a2:
        return const PdfPageFormat(420 * PdfPageFormat.mm, 594 * PdfPageFormat.mm);
    }
  }

  String get _nomeArquivo {
    final prod = widget.data.tituloLinha1
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        .toLowerCase();
    return 'cartaz_${prod}_${widget.data.tamanho.label.toLowerCase()}';
  }

  Future<List<int>> _capturarPNG() async {
    final image = await _screenshotController.capture(pixelRatio: 3.0);
    return image!.toList();
  }

  Future<List<int>> _gerarPDF(List<int> pngBytes) async {
    final doc = pw.Document();
    final img = pw.MemoryImage(Uint8List.fromList(pngBytes));
    doc.addPage(
      pw.Page(
        pageFormat: _pdfFormat.copyWith(marginBottom: 0, marginLeft: 0, marginRight: 0, marginTop: 0),
        build: (pw.Context ctx) => pw.Image(img, fit: pw.BoxFit.contain),
      ),
    );
    return doc.save();
  }

  Future<void> _compartilharPNG() async {
    setState(() => _exporting = true);
    try {
      final pngBytes = await _capturarPNG();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$_nomeArquivo.png');
      await file.writeAsBytes(pngBytes);
      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')]);
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
      await Printing.sharePdf(bytes: Uint8List.fromList(pdfBytes), filename: '$_nomeArquivo.pdf');
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
        onLayout: (_) async => Uint8List.fromList(pdfBytes),
        name: 'Cartaz ${widget.data.tituloLinha1}',
      );
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _mostrarErro(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Widget _buildTemplate() {
    switch (widget.data.tipo) {
      case CartazTemplateTipo.aproveiteAgora:
        return CartazAproveiteAgoraWidget(data: widget.data);
      case CartazTemplateTipo.proximoVencimento:
        return CartazProximoVencimentoWidget(data: widget.data);
      case CartazTemplateTipo.oferta:
        return CartazOfertaWidget(data: widget.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final scale = ((screenW - 40) / CartazAproveiteAgoraWidget.baseW).clamp(0.4, 1.2);

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Screenshot(
                  controller: _screenshotController,
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topCenter,
                    child: _buildTemplate(),
                  ),
                ),
              ),
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
                  onPressed: _exporting ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.print_rounded),
              label: Text(_exporting ? 'Gerando...' : 'Imprimir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD6166A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
