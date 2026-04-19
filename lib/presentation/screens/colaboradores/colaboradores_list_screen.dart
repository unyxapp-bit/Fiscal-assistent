// ignore_for_file: use_build_context_synchronously
import 'dart:async';
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
  Timer? _debounce;

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
    _debounce?.cancel();
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
        title: const Text('Colaboradores'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
                _StatusTab(
                  colaboradorProvider: colaboradorProvider,
                  caixaProvider: caixaProvider,
                  alocacaoProvider: alocacaoProvider,
                  onRefresh: _loadData,
                  onNavigateToDetail: _navigateToDetail,
                ),
              ],
            ),
      floatingActionButton: _tabCtrl.index == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ColaboradorFormScreen())),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // ── Aba 1: Lista ─────────────────────────────────────────────────────────

  Widget _buildListaTab(
      ColaboradorProvider provider, AlocacaoProvider alocacaoProvider) {
    return Column(
      children: [
        // Busca com debounce
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
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                provider.setSearchQuery(value);
              });
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
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
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

  // ── Chips de filtro ───────────────────────────────────────────────────────

  Widget _buildFilterChips(ColaboradorProvider provider) {
    return Container(
      height: 48,
      margin:
          const EdgeInsets.symmetric(horizontal: Dimensions.paddingMD),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(
            label: 'Todos (${provider.totalAtivos})',
            isSelected: provider.filtroAtual == null,
            onTap: () => provider.setFiltro(null),
          ),
          const SizedBox(width: 8),
          _chip(
            label: 'Caixa (${provider.totalCaixa})',
            isSelected: provider.filtroAtual == DepartamentoTipo.caixa,
            onTap: () => provider.setFiltro(DepartamentoTipo.caixa),
            icon: DepartamentoTipo.caixa.icone,
            iconColor: DepartamentoTipo.caixa.cor,
          ),
          const SizedBox(width: 8),
          _chip(
            label: 'Fiscal (${provider.totalFiscal})',
            isSelected: provider.filtroAtual == DepartamentoTipo.fiscal,
            onTap: () => provider.setFiltro(DepartamentoTipo.fiscal),
            icon: DepartamentoTipo.fiscal.icone,
            iconColor: DepartamentoTipo.fiscal.cor,
          ),
          const SizedBox(width: 8),
          _chip(
            label: 'Pacote (${provider.totalPacote})',
            isSelected: provider.filtroAtual == DepartamentoTipo.pacote,
            onTap: () => provider.setFiltro(DepartamentoTipo.pacote),
            icon: DepartamentoTipo.pacote.icone,
            iconColor: DepartamentoTipo.pacote.cor,
          ),
          const SizedBox(width: 8),
          _chip(
            label: 'Self (${provider.totalSelf})',
            isSelected: provider.filtroAtual == DepartamentoTipo.self,
            onTap: () => provider.setFiltro(DepartamentoTipo.self),
            icon: DepartamentoTipo.self.icone,
            iconColor: DepartamentoTipo.self.cor,
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : (iconColor ?? AppColors.textSecondary),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────

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
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
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

// ── StatusTab — extraído para evitar o bug de reconstrução do DefaultTabController ──

class _StatusTab extends StatefulWidget {
  final ColaboradorProvider colaboradorProvider;
  final CaixaProvider caixaProvider;
  final AlocacaoProvider alocacaoProvider;
  final Future<void> Function() onRefresh;
  final void Function(Colaborador) onNavigateToDetail;

  const _StatusTab({
    required this.colaboradorProvider,
    required this.caixaProvider,
    required this.alocacaoProvider,
    required this.onRefresh,
    required this.onNavigateToDetail,
  });

  @override
  State<_StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<_StatusTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todos = widget.colaboradorProvider.todosColaboradores
        .where((c) => c.ativo)
        .toList();
    final disponiveis = todos
        .where((c) =>
            widget.alocacaoProvider.getAlocacaoColaborador(c.id) == null)
        .toList();
    final emCaixa = todos
        .where((c) =>
            widget.alocacaoProvider.getAlocacaoColaborador(c.id) != null)
        .toList();

    return Column(
      children: [
        TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 18),
                  const SizedBox(width: 6),
                  Text('Disponíveis (${disponiveis.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.point_of_sale, size: 18),
                  const SizedBox(width: 6),
                  Text('Em Caixa (${emCaixa.length})'),
                ],
              ),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              // Disponíveis
              RefreshIndicator(
                onRefresh: widget.onRefresh,
                child: disponiveis.isEmpty
                    ? const _EmptyStatus(
                        icon: Icons.people_outline,
                        mensagem: 'Nenhum colaborador disponível',
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(Dimensions.paddingMD),
                        itemCount: disponiveis.length,
                        itemBuilder: (context, index) => _CardDisponivel(
                          colaborador: disponiveis[index],
                          onTap: () => widget
                              .onNavigateToDetail(disponiveis[index]),
                        ),
                      ),
              ),

              // Em Caixa
              RefreshIndicator(
                onRefresh: widget.onRefresh,
                child: emCaixa.isEmpty
                    ? const _EmptyStatus(
                        icon: Icons.point_of_sale,
                        mensagem: 'Nenhum colaborador alocado',
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(Dimensions.paddingMD),
                        itemCount: emCaixa.length,
                        itemBuilder: (context, index) {
                          final c = emCaixa[index];
                          final alocacao = widget.alocacaoProvider
                              .getAlocacaoColaborador(c.id);
                          final caixa = alocacao != null
                              ? widget.caixaProvider.caixas
                                  .where(
                                      (cx) => cx.id == alocacao.caixaId)
                                  .firstOrNull
                              : null;
                          return _CardEmCaixa(
                            colaborador: c,
                            nomeCaixa: caixa?.nomeExibicao,
                            localizacao: caixa?.localizacao,
                            onTap: () => widget.onNavigateToDetail(c),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Widgets da aba Status ─────────────────────────────────────────────────

class _CardDisponivel extends StatelessWidget {
  final Colaborador colaborador;
  final VoidCallback? onTap;

  const _CardDisponivel({required this.colaborador, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor:
              colaborador.departamento.cor.withValues(alpha: 0.15),
          child: Icon(
            colaborador.departamento.icone,
            color: colaborador.departamento.cor,
            size: 18,
          ),
        ),
        title: Text(colaborador.nome, style: AppTextStyles.h4),
        subtitle: Text(colaborador.departamento.nome,
            style: AppTextStyles.caption),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
  final VoidCallback? onTap;

  const _CardEmCaixa({
    required this.colaborador,
    this.nomeCaixa,
    this.localizacao,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor:
              colaborador.departamento.cor.withValues(alpha: 0.15),
          child: Icon(
            colaborador.departamento.icone,
            color: colaborador.departamento.cor,
            size: 18,
          ),
        ),
        title: Text(colaborador.nome, style: AppTextStyles.h4),
        subtitle: Text(colaborador.departamento.nome,
            style: AppTextStyles.caption),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              const SizedBox(height: 3),
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
          const SizedBox(height: 12),
          Text(
            mensagem,
            style:
                AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
