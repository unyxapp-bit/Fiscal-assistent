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
import '../../providers/caixa_provider.dart';
import '../../providers/alocacao_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import 'colaborador_form_screen.dart';
import 'colaborador_detail_screen.dart';
import 'widgets/colaborador_list_item.dart';
import '../../../core/utils/app_notif.dart';

/// Tela de colaboradores com abas Lista e Status.
class ColaboradoresListScreen extends StatefulWidget {
  const ColaboradoresListScreen({super.key});

  @override
  State<ColaboradoresListScreen> createState() =>
      _ColaboradoresListScreenState();
}

class _ColaboradoresListScreenState extends State<ColaboradoresListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;
    final userId = authProvider.user!.id;
    await Future.wait([
      Provider.of<ColaboradorProvider>(context, listen: false)
          .loadColaboradores(userId),
      Provider.of<CaixaProvider>(context, listen: false).loadCaixas(userId),
      Provider.of<AlocacaoProvider>(context, listen: false)
          .loadAlocacoes(userId),
    ]);
  }

  void _navigateToDetail(Colaborador colaborador) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ColaboradorDetailScreen(colaborador: colaborador),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colaboradorProvider = Provider.of<ColaboradorProvider>(context);
    final caixaProvider = Provider.of<CaixaProvider>(context);
    final alocacaoProvider = Provider.of<AlocacaoProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Colaboradores'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Atualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Lista', icon: Icon(Icons.people)),
            Tab(text: 'Status', icon: Icon(Icons.info_outline)),
          ],
        ),
      ),
      body: colaboradorProvider.isLoading
          ? const LoadingWidget(message: 'Carregando colaboradores...')
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildListaTab(colaboradorProvider, alocacaoProvider),
                _buildStatusTab(
                    colaboradorProvider, caixaProvider, alocacaoProvider),
              ],
            ),
      floatingActionButton: _tabCtrl.index == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ColaboradorFormScreen())),
              backgroundColor: AppColors.primary,
              child: Icon(Icons.add),
            )
          : null,
    );
  }

  // â”€â”€ Aba 1: Lista â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildListaTab(
      ColaboradorProvider provider, AlocacaoProvider alocacaoProvider) {
    return Column(
      children: [
        // Busca
        Padding(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nome...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
            ),
            onChanged: (value) {
              setState(() {});
              provider.setSearchQuery(value);
            },
          ),
        ),

        // Filtros por departamento
        _buildFilterChips(provider),

        // Grade
        Expanded(
          child: provider.colaboradores.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.people_outline,
                  title: 'Nenhum colaborador',
                  message: provider.searchQuery.isNotEmpty
                      ? 'Nenhum resultado encontrado'
                      : 'Adicione colaboradores usando o botão +',
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width < 400
                          ? 2
                          : width < 650
                              ? 3
                              : width < 900
                                  ? 4
                                  : 5;
                      final showDetails = crossAxisCount >= 4;
                      return GridView.builder(
                        padding: const EdgeInsets.all(Dimensions.paddingMD),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: showDetails ? 0.68 : 0.85,
                        ),
                        itemCount: provider.colaboradores.length,
                        itemBuilder: (context, index) {
                          final colaborador = provider.colaboradores[index];
                          return ColaboradorGridCard(
                            colaborador: colaborador,
                            onTap: () => _navigateToDetail(colaborador),
                            onDelete: () => _deleteColaborador(
                              context,
                              colaborador.id,
                              colaborador.nome,
                            ),
                            alocacaoAtual: showDetails
                                ? alocacaoProvider
                                    .getAlocacaoColaborador(colaborador.id)
                                : null,
                            showDetails: showDetails,
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // â”€â”€ Aba 2: Status â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildStatusTab(
    ColaboradorProvider colaboradorProvider,
    CaixaProvider caixaProvider,
    AlocacaoProvider alocacaoProvider,
  ) {
    final todos =
        colaboradorProvider.todosColaboradores.where((c) => c.ativo).toList();

    final disponiveis = todos
        .where((c) => alocacaoProvider.getAlocacaoColaborador(c.id) == null)
        .toList();

    final emCaixa = todos
        .where((c) => alocacaoProvider.getAlocacaoColaborador(c.id) != null)
        .toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 18),
                    SizedBox(width: 6),
                    Text('Disponíveis (${disponiveis.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.point_of_sale, size: 18),
                    SizedBox(width: 6),
                    Text('Em Caixa (${emCaixa.length})'),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Disponíveis
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: disponiveis.isEmpty
                      ? const _EmptyStatus(
                          icon: Icons.people_outline,
                          mensagem: 'Nenhum colaborador disponível',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(Dimensions.paddingMD),
                          itemCount: disponiveis.length,
                          itemBuilder: (context, index) =>
                              _CardDisponivel(colaborador: disponiveis[index]),
                        ),
                ),

                // Em Caixa
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: emCaixa.isEmpty
                      ? const _EmptyStatus(
                          icon: Icons.point_of_sale,
                          mensagem: 'Nenhum colaborador alocado',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(Dimensions.paddingMD),
                          itemCount: emCaixa.length,
                          itemBuilder: (context, index) {
                            final c = emCaixa[index];
                            final alocacao =
                                alocacaoProvider.getAlocacaoColaborador(c.id);
                            final caixa = alocacao != null
                                ? caixaProvider.caixas
                                    .where((cx) => cx.id == alocacao.caixaId)
                                    .firstOrNull
                                : null;
                            return _CardEmCaixa(
                              colaborador: c,
                              nomeCaixa: caixa?.nomeExibicao,
                              localizacao: caixa?.localizacao,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Chips de filtro â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildFilterChips(ColaboradorProvider provider) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingMD),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(
            label: 'Todos (${provider.totalAtivos})',
            isSelected: provider.filtroAtual == null,
            onTap: () => provider.setFiltro(null),
          ),
          SizedBox(width: 8),
          _chip(
            label: 'Caixa (${provider.totalCaixa})',
            isSelected: provider.filtroAtual == DepartamentoTipo.caixa,
            onTap: () => provider.setFiltro(DepartamentoTipo.caixa),
          ),
          SizedBox(width: 8),
          _chip(
            label: 'Fiscal (${provider.totalFiscal})',
            isSelected: provider.filtroAtual == DepartamentoTipo.fiscal,
            onTap: () => provider.setFiltro(DepartamentoTipo.fiscal),
          ),
          SizedBox(width: 8),
          _chip(
            label: 'Pacote (${provider.totalPacote})',
            isSelected: provider.filtroAtual == DepartamentoTipo.pacote,
            onTap: () => provider.setFiltro(DepartamentoTipo.pacote),
          ),
          SizedBox(width: 8),
          _chip(
            label: 'Self (${provider.totalSelf})',
            isSelected: provider.filtroAtual == DepartamentoTipo.self,
            onTap: () => provider.setFiltro(DepartamentoTipo.self),
          ),
        ],
      ),
    );
  }

  Widget _chip({
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
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
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

  // â”€â”€ Delete â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _deleteColaborador(
    BuildContext context,
    String id,
    String nome,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir colaborador?'),
        content: Text('Tem certeza que deseja excluir $nome?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirm == true) {
      final provider = Provider.of<ColaboradorProvider>(context, listen: false);
      final success = await provider.deleteColaborador(id);
      if (mounted) {
        AppNotif.show(
          context,
          titulo: success ? 'Removido' : 'Erro',
          mensagem: success
              ? '$nome excluído com sucesso'
              : 'Erro ao excluir colaborador',
          tipo: success ? 'saida' : 'alerta',
          cor: success ? AppColors.success : AppColors.danger,
        );
      }
    }
  }
}

// â”€â”€ Widgets da aba Status â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CardDisponivel extends StatelessWidget {
  final Colaborador colaborador;
  const _CardDisponivel({required this.colaborador});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.success.withValues(alpha: 0.15),
          child: Text(
            colaborador.iniciais,
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(colaborador.nome, style: AppTextStyles.h4),
        subtitle:
            Text(colaborador.departamento.nome, style: AppTextStyles.caption),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Disponível',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardEmCaixa extends StatelessWidget {
  final Colaborador colaborador;
  final String? nomeCaixa;
  final String? localizacao;

  const _CardEmCaixa({
    required this.colaborador,
    this.nomeCaixa,
    this.localizacao,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.statusAtivo.withValues(alpha: 0.15),
          child: Text(
            colaborador.iniciais,
            style: TextStyle(
              color: AppColors.statusAtivo,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(colaborador.nome, style: AppTextStyles.h4),
        subtitle:
            Text(colaborador.departamento.nome, style: AppTextStyles.caption),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.statusAtivo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.statusAtivo),
              ),
              child: Text(
                nomeCaixa ?? 'Caixa',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.statusAtivo,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (localizacao != null) ...[
              SizedBox(height: 3),
              Text(
                localizacao!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyStatus extends StatelessWidget {
  final IconData icon;
  final String mensagem;

  const _EmptyStatus({required this.icon, required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.inactive),
          SizedBox(height: 12),
          Text(
            mensagem,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
