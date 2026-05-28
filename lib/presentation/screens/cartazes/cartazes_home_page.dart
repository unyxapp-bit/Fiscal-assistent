import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../data/models/cartaz_form_data.dart';
import '../../widgets/cartazes/cartaz_template_specs.dart';
import 'cartazes_salvos_page.dart';
import 'criar_cartaz_page.dart';

class CartazesHomePage extends StatefulWidget {
  const CartazesHomePage({super.key});

  @override
  State<CartazesHomePage> createState() => _CartazesHomePageState();
}

class _CartazesHomePageState extends State<CartazesHomePage> {
  CartazTemplateTipo? _tipoSelecionado;
  CartazTamanho _tamanhoSelecionado = CartazTamanho.a6;

  void _abrirCartazesFeitos() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CartazesSalvosPage()),
    );
  }

  Future<void> _importarSvg() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['svg'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _mostrarErroImportacao('Nao foi possivel ler o arquivo SVG.');
        return;
      }

      final svg = utf8.decode(bytes, allowMalformed: true).trim();
      if (!svg.contains('<svg')) {
        _mostrarErroImportacao('Escolha um arquivo SVG valido.');
        return;
      }

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CriarCartazPage(
            tipo: CartazTemplateTipo.templateImportado,
            tamanho: _tamanhoSelecionado,
            customTemplateName: file.name.replaceAll(
              RegExp(r'\.svg$', caseSensitive: false),
              '',
            ),
            customTemplateSvg: svg,
          ),
        ),
      );
    } catch (e) {
      _mostrarErroImportacao('Erro ao importar SVG: $e');
    }
  }

  void _mostrarErroImportacao(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  void _iniciar() {
    if (_tipoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha um modelo primeiro')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CriarCartazPage(
          tipo: _tipoSelecionado!,
          tamanho: _tamanhoSelecionado,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Cartazes promocionais'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cartazes feitos',
            onPressed: _abrirCartazesFeitos,
            icon: const Icon(Icons.collections_bookmark_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('1. Escolha o modelo'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _importarSvg,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Importar template SVG'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final spec
                      in cartazTemplateSpecs.where((s) => s.showInPicker)) ...[
                    _TemplateCard(
                      spec: spec,
                      selecionado: _tipoSelecionado == spec.tipo,
                      onTap: () => setState(() => _tipoSelecionado = spec.tipo),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 18),
                  _sectionLabel('2. Escolha o tamanho'),
                  const SizedBox(height: 12),
                  _TamanhoSelector(
                    selecionado: _tamanhoSelecionado,
                    onChanged: (t) => setState(() => _tamanhoSelecionado = t),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _abrirCartazesFeitos,
                      icon: const Icon(Icons.collections_bookmark_rounded),
                      label: const Text('Ver cartazes feitos'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD6166A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFD6166A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _tipoSelecionado != null ? _iniciar : null,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text(
            'Preencher dados',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD6166A),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final CartazTemplateSpec spec;
  final bool selecionado;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.spec,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? spec.color.withAlpha(18) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: selecionado ? 0 : 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border:
                selecionado ? Border.all(color: spec.color, width: 2) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: spec.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Icon(spec.icon, color: spec.iconColor, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selecionado ? spec.color : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      spec.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  selecionado
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selecionado ? spec.color : Colors.grey.shade300,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TamanhoSelector extends StatelessWidget {
  final CartazTamanho selecionado;
  final ValueChanged<CartazTamanho> onChanged;

  const _TamanhoSelector({
    required this.selecionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final itemWidth =
            (constraints.maxWidth - (8 * (columns - 1))) / columns;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in CartazTamanho.values)
              SizedBox(
                width: itemWidth,
                child: _TamanhoTile(
                  tamanho: t,
                  selecionado: t == selecionado,
                  onTap: () => onChanged(t),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TamanhoTile extends StatelessWidget {
  final CartazTamanho tamanho;
  final bool selecionado;
  final VoidCallback onTap;

  const _TamanhoTile({
    required this.tamanho,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selecionado ? const Color(0xFFD6166A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selecionado ? const Color(0xFFD6166A) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Text(
              tamanho.label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: selecionado ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tamanho.descricao,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: selecionado ? Colors.white70 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
