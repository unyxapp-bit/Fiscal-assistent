import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/guia_rapido_provider.dart';
import '../../../core/utils/app_notif.dart';

class GuiaRapidoFormScreen extends StatefulWidget {
  final SituacaoGuia? situacao;

  const GuiaRapidoFormScreen({super.key, this.situacao});

  @override
  State<GuiaRapidoFormScreen> createState() => _GuiaRapidoFormScreenState();
}

class _GuiaRapidoFormScreenState extends State<GuiaRapidoFormScreen> {
  final _tituloCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();
  final List<TextEditingController> _passosCtrl = [];

  String _corHex = 'FF9800';
  String _iconeKey = 'caixa';

  bool get _editando => widget.situacao != null;

  @override
  void initState() {
    super.initState();
    if (_editando) {
      final s = widget.situacao!;
      _tituloCtrl.text = s.titulo;
      _categoriaCtrl.text = s.categoria;
      _corHex = s.corHex;
      _iconeKey = s.iconeKey;
      for (final p in s.passos) {
        _passosCtrl.add(TextEditingController(text: p));
      }
    }
    if (_passosCtrl.isEmpty) {
      _passosCtrl.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _categoriaCtrl.dispose();
    for (final c in _passosCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  void _adicionarPasso() {
    setState(() => _passosCtrl.add(TextEditingController()));
  }

  void _removerPasso(int i) {
    if (_passosCtrl.length <= 1) return;
    _passosCtrl[i].dispose();
    setState(() => _passosCtrl.removeAt(i));
  }

  void _salvar() {
    final titulo = _tituloCtrl.text.trim();
    final categoria = _categoriaCtrl.text.trim();
    if (titulo.isEmpty || categoria.isEmpty) {
      AppNotif.show(
        context,
        titulo: 'Campo Inválido',
        mensagem: 'Preencha o título e a categoria',
        tipo: 'alerta',
        cor: AppColors.danger,
      );
      return;
    }

    final passos = _passosCtrl
        .map((c) => c.text.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final provider =
        Provider.of<GuiaRapidoProvider>(context, listen: false);

    if (_editando) {
      provider.atualizar(widget.situacao!.copyWith(
        titulo: titulo,
        categoria: categoria,
        corHex: _corHex,
        iconeKey: _iconeKey,
        passos: passos,
      ));
    } else {
      provider.adicionar(SituacaoGuia(
        id: const Uuid().v4(),
        titulo: titulo,
        categoria: categoria,
        corHex: _corHex,
        iconeKey: _iconeKey,
        passos: passos,
      ));
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GuiaRapidoProvider>(context, listen: false);
    final categorias = provider.categorias;
    final corAtual = Color(int.parse('FF$_corHex', radix: 16));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_editando ? 'Editar Situação' : 'Nova Situação'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _salvar,
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Título ───────────────────────────────────────────────────
            TextField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(
                labelText: 'Título da situação *',
                hintText: 'Ex: Caixa ficou sem troco',
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: Dimensions.spacingMD),

            // ── Categoria ────────────────────────────────────────────────
            TextField(
              controller: _categoriaCtrl,
              decoration: const InputDecoration(
                labelText: 'Categoria *',
                hintText: 'Ex: Caixa, Clientes, Equipamentos...',
                prefixIcon: Icon(Icons.category),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            if (categorias.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: categorias.map((cat) => ActionChip(
                  label: Text(cat, style: const TextStyle(fontSize: 12)),
                  onPressed: () =>
                      setState(() => _categoriaCtrl.text = cat),
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.08),
                )).toList(),
              ),
            ],

            const SizedBox(height: Dimensions.spacingLG),

            // ── Cor ──────────────────────────────────────────────────────
            const Text('Cor', style: AppTextStyles.h4),
            const SizedBox(height: Dimensions.spacingSM),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kGuiaCores.map((c) {
                final hex = c.toARGB32().toRadixString(16).substring(2).toUpperCase();
                final sel = _corHex == hex;
                return GestureDetector(
                  onTap: () => setState(() => _corHex = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? Colors.black54 : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: sel
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: Dimensions.spacingLG),

            // ── Ícone ────────────────────────────────────────────────────
            const Text('Ícone', style: AppTextStyles.h4),
            const SizedBox(height: Dimensions.spacingSM),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kGuiaIcones.map((t) {
                final sel = _iconeKey == t.$1;
                return GestureDetector(
                  onTap: () => setState(() => _iconeKey = t.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: sel
                          ? corAtual.withValues(alpha: 0.15)
                          : AppColors.backgroundSection,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? corAtual : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Tooltip(
                      message: t.$3,
                      child: Icon(t.$2,
                          color:
                              sel ? corAtual : AppColors.textSecondary,
                          size: 22),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: Dimensions.spacingLG),

            // ── Passos ───────────────────────────────────────────────────
            Row(
              children: [
                const Expanded(
                    child: Text('Passos', style: AppTextStyles.h4)),
                TextButton.icon(
                  onPressed: _adicionarPasso,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.spacingSM),
            ...List.generate(_passosCtrl.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(top: 14, right: 8),
                    decoration: BoxDecoration(
                      color: corAtual.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: corAtual,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _passosCtrl[i],
                      decoration: InputDecoration(
                        hintText: 'Passo ${i + 1}...',
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppColors.danger, size: 20),
                    onPressed: _passosCtrl.length > 1
                        ? () => _removerPasso(i)
                        : null,
                  ),
                ],
              ),
            )),

            const SizedBox(height: Dimensions.spacingLG),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvar,
                icon: const Icon(Icons.save),
                label: Text(_editando ? 'Salvar alterações' : 'Criar situação'),
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(Dimensions.buttonHeight),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
