// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/colaborador.dart';
import '../../../domain/enums/departamento_tipo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import 'colaborador_form_screen.dart';
import 'colaborador_detail_screen.dart';
import 'widgets/colaborador_list_item.dart';

/// Tela de lista de colaboradores
class ColaboradoresListScreen extends StatefulWidget {
  const ColaboradoresListScreen({super.key});

  @override
  State<ColaboradoresListScreen> createState() =>
      _ColaboradoresListScreenState();
}

class _ColaboradoresListScreenState extends State<ColaboradoresListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadColaboradores();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadColaboradores() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final colaboradorProvider =
        Provider.of<ColaboradorProvider>(context, listen: false);

    if (authProvider.user != null) {
      await colaboradorProvider.loadColaboradores(authProvider.user!.id);
    }
  }

  void _navigateToForm([String? colaboradorId]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ColaboradorFormScreen(colaboradorId: colaboradorId),
      ),
    );
  }

  void _navigateToDetail(Colaborador colaborador) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ColaboradorDetailScreen(
          colaborador: colaborador,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colaboradorProvider = Provider.of<ColaboradorProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Colaboradores'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (colaboradorProvider.colaboradores.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadColaboradores,
            ),
        ],
      ),
      body: colaboradorProvider.isLoading
          ? const LoadingWidget(message: 'Carregando colaboradores...')
          : Column(
              children: [
                // Busca
                Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingMD),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                colaboradorProvider.setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.borderRadius),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                      colaboradorProvider.setSearchQuery(value);
                    },
                  ),
                ),

                // Tabs de filtro
                _buildFilterTabs(),

                // Lista
                Expanded(
                  child: colaboradorProvider.colaboradores.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.people_outline,
                          title: 'Nenhum colaborador',
                          message: colaboradorProvider.searchQuery.isNotEmpty
                              ? 'Nenhum resultado encontrado'
                              : 'Adicione colaboradores usando o botão +',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadColaboradores,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingMD,
                            ),
                            itemCount: colaboradorProvider.colaboradores.length,
                            itemBuilder: (context, index) {
                              final colaborador =
                                  colaboradorProvider.colaboradores[index];
                              return ColaboradorListItem(
                                colaborador: colaborador,
                                onTap: () => _navigateToDetail(colaborador),
                                onDelete: () => _deleteColaborador(
                                  context,
                                  colaborador.id,
                                  colaborador.nome,
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final provider = Provider.of<ColaboradorProvider>(context);

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingMD),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            label: 'Todos (${provider.totalAtivos})',
            isSelected: provider.filtroAtual == null,
            onTap: () => provider.setFiltro(null),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Caixa (${provider.totalCaixa})',
            isSelected: provider.filtroAtual == DepartamentoTipo.caixa,
            onTap: () => provider.setFiltro(DepartamentoTipo.caixa),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Fiscal (${provider.totalFiscal})',
            isSelected: provider.filtroAtual == DepartamentoTipo.fiscal,
            onTap: () => provider.setFiltro(DepartamentoTipo.fiscal),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Pacote (${provider.totalPacote})',
            isSelected: provider.filtroAtual == DepartamentoTipo.pacote,
            onTap: () => provider.setFiltro(DepartamentoTipo.pacote),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Self (${provider.totalSelf})',
            isSelected: provider.filtroAtual == DepartamentoTipo.self,
            onTap: () => provider.setFiltro(DepartamentoTipo.self),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteColaborador(
    BuildContext context,
    String id,
    String nome,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir colaborador?'),
        content: Text('Tem certeza que deseja excluir $nome?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirm == true) {
      final provider =
          Provider.of<ColaboradorProvider>(context, listen: false);

      final success = await provider.deleteColaborador(id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? '$nome excluído com sucesso'
                : 'Erro ao excluir colaborador'),
            backgroundColor:
                success ? AppColors.success : AppColors.danger,
          ),
        );
      }
    }
  }
}
