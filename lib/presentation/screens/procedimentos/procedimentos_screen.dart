import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/procedimento_provider.dart';
import 'procedimento_form_screen.dart';
import 'procedimento_detail_screen.dart';
import '../../../core/utils/app_notif.dart';

class ProcedimentosScreen extends StatefulWidget {
  const ProcedimentosScreen({super.key});

  @override
  State<ProcedimentosScreen> createState() => _ProcedimentosScreenState();
}

class _ProcedimentosScreenState extends State<ProcedimentosScreen> {
  final _searchController = TextEditingController();

  static const _categorias = [
    'abertura',
    'fechamento',
    'emergencia',
    'rotina',
    'fiscal',
    'caixa',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmarDelete(
    BuildContext context,
    Procedimento proc,
    ProcedimentoProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir procedimento'),
        content: Text('Excluir "${proc.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              provider.removerProcedimento(proc.id);
              Navigator.pop(ctx);
            },
            child: const Text('Excluir',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _onMenuSelected(
    String value,
    Procedimento proc,
    ProcedimentoProvider provider,
    BuildContext context,
  ) {
    switch (value) {
      case 'favorito':
        provider.toggleFavorito(proc.id);
      case 'editar':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ProcedimentoFormScreen(procedimento: proc),
        ));
      case 'copiar':
        _copiarProcedimento(context, proc);
      case 'deletar':
        _confirmarDelete(context, proc, provider);
    }
  }

  void _copiarProcedimento(BuildContext context, Procedimento proc) {
    final buf = StringBuffer();
    buf.writeln(proc.titulo);
    if (proc.descricao.isNotEmpty) {
      buf.writeln();
      buf.writeln(proc.descricao);
    }
    buf.writeln();
    for (var i = 0; i < proc.passos.length; i++) {
      buf.writeln('${i + 1}. ${proc.passos[i]}');
    }
    Clipboard.setData(ClipboardData(text: buf.toString().trim()));
    AppNotif.show(
      context,
      titulo: 'Copiado',
      mensagem: 'Copiado para área de transferência',
      tipo: 'intervalo',
    );
  }

  Widget _buildCard(
    BuildContext context,
    Procedimento proc,
    ProcedimentoProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ProcedimentoDetailScreen(procedimento: proc),
        )),
        onLongPress: () => _copiarProcedimento(context, proc),
        borderRadius: BorderRadius.circular(Dimensions.radiusMD),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: proc.categoria.categoriaColor,
            child: Icon(proc.categoria.categoriaIcon, color: Colors.white),
          ),
          title: Text(proc.titulo, style: AppTextStyles.h4),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                proc.categoria.categoriaNome,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              if (proc.tempoEstimado != null)
                Row(
                  children: [
                    const Icon(Icons.timer,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text(
                      '${proc.tempoEstimado} min',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (v) =>
                _onMenuSelected(v, proc, provider, context),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'favorito',
                child: Row(children: [
                  Icon(
                    proc.favorito
                        ? Icons.star
                        : Icons.star_outline,
                    size: 18,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(proc.favorito
                      ? 'Remover favorito'
                      : 'Adicionar favorito'),
                ]),
              ),
              const PopupMenuItem(
                value: 'editar',
                child: Row(children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Editar'),
                ]),
              ),
              const PopupMenuItem(
                value: 'copiar',
                child: Row(children: [
                  Icon(Icons.copy, size: 18),
                  SizedBox(width: 8),
                  Text('Copiar'),
                ]),
              ),
              const PopupMenuItem(
                value: 'deletar',
                child: Row(children: [
                  Icon(Icons.delete, size: 18, color: AppColors.danger),
                  SizedBox(width: 8),
                  Text('Deletar',
                      style: TextStyle(color: AppColors.danger)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProcedimentoProvider>(context);
    final filtrados = provider.procedimentosFiltrados;
    final isFiltering = _searchController.text.isNotEmpty ||
        provider.filtroCategoria != null;
    final favoritosFiltrados =
        filtrados.where((p) => p.favorito).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Procedimentos'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ProcedimentoFormScreen(),
            )),
            tooltip: 'Novo procedimento',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Busca ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingMD, 8, Dimensions.paddingMD, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar procedimento...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusMD),
                ),
              ),
              onChanged: provider.setSearchQuery,
            ),
          ),

          // ── Chips de categoria ────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingMD, vertical: 4),
            child: Row(
              children: [
                // "Todos"
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                        'Todos (${provider.procedimentos.length})'),
                    selected: provider.filtroCategoria == null,
                    onSelected: (_) =>
                        provider.setFiltroCategoria(null),
                    selectedColor:
                        AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: provider.filtroCategoria == null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: provider.filtroCategoria == null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                // Por categoria
                ..._categorias.map((cat) {
                  final count = provider.countByCategoria(cat);
                  if (count == 0) return const SizedBox.shrink();
                  final isSelected = provider.filtroCategoria == cat;
                  final cor = cat.categoriaColor;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label:
                          Text('${cat.categoriaNome} ($count)'),
                      selected: isSelected,
                      onSelected: (_) => provider.setFiltroCategoria(
                          isSelected ? null : cat),
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

          // ── Lista ─────────────────────────────────────────────────────────
          Expanded(
            child: filtrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.menu_book,
                            size: 64, color: AppColors.inactive),
                        const SizedBox(height: 16),
                        Text(
                          isFiltering
                              ? 'Nenhum resultado encontrado'
                              : 'Nenhum procedimento',
                          style: AppTextStyles.h4
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding:
                        const EdgeInsets.all(Dimensions.paddingMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Seção Favoritos (só quando não está filtrando)
                        if (!isFiltering &&
                            favoritosFiltrados.isNotEmpty) ...[
                          const Text('Favoritos',
                              style: AppTextStyles.h3),
                          const SizedBox(height: Dimensions.spacingSM),
                          ...favoritosFiltrados.map((proc) =>
                              _buildCard(context, proc, provider)),
                          const SizedBox(height: Dimensions.spacingLG),
                        ],

                        // Seção Todos
                        Text(
                          isFiltering
                              ? 'Resultados (${filtrados.length})'
                              : 'Todos os Procedimentos',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: Dimensions.spacingSM),
                        ...filtrados.map((proc) =>
                            _buildCard(context, proc, provider)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
