import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
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

  CartazTemplateSpec? get _specSelecionada {
    final tipo = _tipoSelecionado;
    if (tipo == null) return null;
    for (final spec in cartazTemplateSpecs) {
      if (spec.tipo == tipo) return spec;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cartazes promocionais'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        toolbarHeight: 48,
        actions: [
          IconButton(
            tooltip: 'Cartazes feitos',
            onPressed: _abrirCartazesFeitos,
            icon: const Icon(Icons.collections_bookmark_rounded),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPad = Dimensions.operationalHPad(
            constraints.maxWidth,
          );

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    Dimensions.paddingMD,
                    horizontalPad,
                    96,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('1. Escolha o modelo'),
                      const SizedBox(height: Dimensions.spacingSM),
                      _buildToolbar(constraints.maxWidth),
                      const SizedBox(height: Dimensions.spacingMD),
                      _buildTemplateGrid(),
                      const SizedBox(height: Dimensions.spacingMD),
                      _sectionLabel('2. Escolha o tamanho'),
                      const SizedBox(height: Dimensions.spacingSM),
                      _TamanhoSelector(
                        selecionado: _tamanhoSelecionado,
                        onChanged: (t) =>
                            setState(() => _tamanhoSelecionado = t),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(horizontalPad),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbar(double width) {
    final wide = width >= 720;
    final importar = OutlinedButton.icon(
      onPressed: _importarSvg,
      icon: const Icon(Icons.upload_file_rounded, size: 18),
      label: const Text('Importar SVG'),
    );
    final historico = OutlinedButton.icon(
      onPressed: _abrirCartazesFeitos,
      icon: const Icon(Icons.collections_bookmark_rounded, size: 18),
      label: const Text('Feitos'),
    );

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          importar,
          const SizedBox(height: Dimensions.spacingXS),
          historico,
        ],
      );
    }

    return Row(
      children: [
        SizedBox(width: 180, child: importar),
        const SizedBox(width: Dimensions.spacingSM),
        SizedBox(width: 132, child: historico),
      ],
    );
  }

  Widget _buildTemplateGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final columns = availableWidth >= 1120
            ? 4
            : availableWidth >= 820
                ? 3
                : availableWidth >= 520
                    ? 2
                    : 1;
        const gap = Dimensions.spacingSM;
        final itemWidth = (availableWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final spec in cartazTemplateSpecs.where((s) => s.showInPicker))
              SizedBox(
                width: itemWidth,
                child: _TemplateCard(
                  spec: spec,
                  selecionado: _tipoSelecionado == spec.tipo,
                  onTap: () => setState(() => _tipoSelecionado = spec.tipo),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
        letterSpacing: 0,
      ),
    );
  }

  Widget _buildBottomBar(double horizontalPad) {
    final selected = _specSelecionada;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      padding: EdgeInsets.fromLTRB(horizontalPad, 10, horizontalPad, 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 640;
          final summary = Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: AppStyles.softTile(
                  tint: selected?.color ?? AppColors.inactive,
                  radius: Dimensions.radiusSM,
                ),
                child: Icon(
                  selected?.icon ?? Icons.touch_app_rounded,
                  color: selected?.color ?? AppColors.textSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: Dimensions.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selected?.title ?? 'Escolha um modelo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      selected == null
                          ? 'Depois preencha os dados do cartaz'
                          : '${_tamanhoSelecionado.label} - ${_tamanhoSelecionado.descricao}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final action = SizedBox(
            height: 46,
            width: wide ? 260 : double.infinity,
            child: ElevatedButton.icon(
              onPressed: _tipoSelecionado != null ? _iniciar : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Preencher dados'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD6166A),
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.inactive,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Dimensions.buttonBorderRadius,
                  ),
                ),
              ),
            ),
          );

          if (wide) {
            return Row(
              children: [
                Expanded(child: summary),
                const SizedBox(width: Dimensions.spacingMD),
                action,
              ],
            );
          }

          return Column(
            children: [
              summary,
              const SizedBox(height: Dimensions.spacingSM),
              action,
            ],
          );
        },
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
      color: selecionado
          ? spec.color.withValues(alpha: 0.08)
          : AppColors.cardBackground,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 86),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selecionado ? spec.color : AppColors.cardBorder,
              width: selecionado ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: double.infinity,
                constraints: const BoxConstraints(minHeight: 86),
                decoration: BoxDecoration(
                  color: spec.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Icon(spec.icon, color: spec.iconColor, size: 32),
              ),
              const SizedBox(width: Dimensions.spacingSM),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spec.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        spec.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: Dimensions.spacingSM),
                child: Icon(
                  selecionado
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selecionado ? spec.color : AppColors.cardBorder,
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
