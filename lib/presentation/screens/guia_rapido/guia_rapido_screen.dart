import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/app_notif.dart';
import '../../providers/guia_rapido_provider.dart';
import 'guia_rapido_form_screen.dart';

class GuiaRapidoScreen extends StatefulWidget {
  const GuiaRapidoScreen({super.key});

  @override
  State<GuiaRapidoScreen> createState() => _GuiaRapidoScreenState();
}

class _GuiaRapidoScreenState extends State<GuiaRapidoScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _categoriaFiltro;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SituacaoGuia> _filtrar(List<SituacaoGuia> todas) {
    var lista = todas;
    if (_categoriaFiltro != null) {
      lista = lista.where((s) => s.categoria == _categoriaFiltro).toList();
    }
    if (_query.isNotEmpty) {
      lista = lista
          .where((s) =>
              s.titulo.toLowerCase().contains(_query) ||
              s.categoria.toLowerCase().contains(_query) ||
              s.passos.any((p) => p.toLowerCase().contains(_query)))
          .toList();
    }
    return lista;
  }

  void _confirmarDelete(
    BuildContext context,
    SituacaoGuia s,
    GuiaRapidoProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir situação'),
        content: Text('Excluir "${s.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await provider.deletar(s.id);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              } catch (_) {
                if (!ctx.mounted) return;
                AppNotif.show(
                  ctx,
                  titulo: 'Erro ao excluir',
                  mensagem: 'Nao foi possivel salvar no Supabase.',
                  tipo: 'erro',
                  cor: AppColors.danger,
                );
              }
            },
            child: const Text('Excluir',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GuiaRapidoProvider>(context);
    final categorias = provider.categorias;
    final todas = provider.situacoes.toList();
    final filtradas = _filtrar(todas);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Guia Rápido'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                '${filtradas.length} situações',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Busca ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingMD, 8, Dimensions.paddingMD, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'O que está acontecendo?',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusMD),
                ),
              ),
              onChanged: (v) =>
                  setState(() => _query = v.toLowerCase().trim()),
            ),
          ),

          // ── Chips de categoria ─────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingMD, vertical: 4),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Todas'),
                    selected: _categoriaFiltro == null,
                    onSelected: (_) =>
                        setState(() => _categoriaFiltro = null),
                    selectedColor:
                        AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _categoriaFiltro == null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: _categoriaFiltro == null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                ...categorias.map((cat) {
                  final isSelected = _categoriaFiltro == cat;
                  final cor = todas
                      .firstWhere((s) => s.categoria == cat,
                          orElse: () => todas.first)
                      .cor;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => setState(() =>
                          _categoriaFiltro = isSelected ? null : cat),
                      selectedColor: cor.withValues(alpha: 0.15),
                      checkmarkColor: cor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? cor
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // ── Lista ──────────────────────────────────────────────────
          Expanded(
            child: filtradas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 64, color: AppColors.inactive),
                        const SizedBox(height: 16),
                        Text(
                          todas.isEmpty
                              ? 'Carregando guia...'
                              : 'Nenhuma situação encontrada',
                          style: AppTextStyles.h4
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(Dimensions.paddingMD),
                    itemCount: filtradas.length,
                    itemBuilder: (ctx, i) {
                      final s = filtradas[i];
                      return Card(
                        margin: const EdgeInsets.only(
                            bottom: Dimensions.spacingSM),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                s.cor.withValues(alpha: 0.15),
                            child:
                                Icon(s.icone, color: s.cor, size: 20),
                          ),
                          title:
                              Text(s.titulo, style: AppTextStyles.h4),
                          subtitle: Text(
                            s.categoria,
                            style: TextStyle(
                              color: s.cor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    size: 18,
                                    color: AppColors.textSecondary),
                                tooltip: 'Editar',
                                onPressed: () =>
                                    Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        GuiaRapidoFormScreen(
                                            situacao: s),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: AppColors.danger),
                                tooltip: 'Excluir',
                                onPressed: () => _confirmarDelete(
                                    ctx, s, provider),
                              ),
                            ],
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                              Dimensions.paddingMD,
                              0,
                              Dimensions.paddingMD,
                              Dimensions.paddingMD),
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: Dimensions.spacingMD),
                            ...s.passos.asMap().entries.map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: Dimensions.spacingSM),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: s.cor
                                                .withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${e.key + 1}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: s.cor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            e.value,
                                            style: AppTextStyles.body,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const GuiaRapidoFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nova Situação'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
