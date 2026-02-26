import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/caixa_provider.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../alocacao/alocacao_screen.dart';
import '../caixas/caixa_form_screen.dart';
import '../caixas/widgets/caixa_card.dart';
import 'widgets/caixa_list_item.dart';
import 'widgets/balcao_list_item.dart';
import 'widgets/pacote_section.dart';

/// Tela de mapa de caixas — abas: Mapa | Caixas
class MapaCaixasScreen extends StatefulWidget {
  const MapaCaixasScreen({super.key});

  @override
  State<MapaCaixasScreen> createState() => _MapaCaixasScreenState();
}

class _MapaCaixasScreenState extends State<MapaCaixasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _tabIndex = _tabController.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    final userId = authProvider.user!.id;

    await Future.wait([
      Provider.of<CaixaProvider>(context, listen: false).loadCaixas(userId),
      Provider.of<AlocacaoProvider>(context, listen: false)
          .loadAlocacoes(userId),
      Provider.of<ColaboradorProvider>(context, listen: false)
          .loadColaboradores(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final caixaProvider = Provider.of<CaixaProvider>(context);
    final alocacaoProvider = Provider.of<AlocacaoProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mapa de Caixas'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (_tabIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined, size: 18), text: 'Mapa'),
            Tab(
                icon: Icon(Icons.point_of_sale_outlined, size: 18),
                text: 'Caixas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── ABA 1: MAPA ──────────────────────────────────────────────────
          Builder(builder: (context) {
            // Apenas caixas com alocação ativa
            final rapidos = caixaProvider.caixasRapidos
                .where((c) => alocacaoProvider.getAlocacaoCaixa(c.id) != null)
                .toList();
            final normais = caixaProvider.caixasNormais
                .where((c) => alocacaoProvider.getAlocacaoCaixa(c.id) != null)
                .toList();
            final selfs = caixaProvider.selfCheckouts
                .where((c) => alocacaoProvider.getAlocacaoCaixa(c.id) != null)
                .toList();
            final balcoes = caixaProvider.balcoes;

            return RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(Dimensions.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Legenda
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingMD),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLegendItem('Ocupado', AppColors.statusAtivo),
                            _buildLegendItem('Disponível', AppColors.success),
                            _buildLegendItem('Inativo', AppColors.inactive),
                            _buildLegendItem(
                                'Manutenção', AppColors.statusAtencao),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: Dimensions.spacingLG),

                    // Caixas Rápidos (apenas ocupados)
                    if (rapidos.isNotEmpty) ...[
                      _SectionHeader(
                        label: 'Caixas Rápidos',
                        count: rapidos.length,
                      ),
                      const SizedBox(height: Dimensions.spacingSM),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: rapidos.length,
                        itemBuilder: (context, index) {
                          final caixa = rapidos[index];
                          final alocacao =
                              alocacaoProvider.getAlocacaoCaixa(caixa.id);
                          return CaixaListItem(
                              caixa: caixa, alocacao: alocacao);
                        },
                      ),
                      const SizedBox(height: Dimensions.spacingLG),
                    ],

                    // Caixas Normais (apenas ocupados)
                    if (normais.isNotEmpty) ...[
                      _SectionHeader(
                        label: 'Caixas Normais',
                        count: normais.length,
                      ),
                      const SizedBox(height: Dimensions.spacingSM),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: normais.length,
                        itemBuilder: (context, index) {
                          final caixa = normais[index];
                          final alocacao =
                              alocacaoProvider.getAlocacaoCaixa(caixa.id);
                          return CaixaListItem(
                              caixa: caixa, alocacao: alocacao);
                        },
                      ),
                      const SizedBox(height: Dimensions.spacingLG),
                    ],

                    // Self Checkouts (apenas ocupados)
                    if (selfs.isNotEmpty) ...[
                      _SectionHeader(
                        label: 'Self Checkouts',
                        count: selfs.length,
                      ),
                      const SizedBox(height: Dimensions.spacingSM),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: selfs.length,
                        itemBuilder: (context, index) {
                          final caixa = selfs[index];
                          final alocacao =
                              alocacaoProvider.getAlocacaoCaixa(caixa.id);
                          return CaixaListItem(
                              caixa: caixa, alocacao: alocacao);
                        },
                      ),
                      const SizedBox(height: Dimensions.spacingLG),
                    ],

                    // Balcões (todos, com slots para até 3 fiscais)
                    if (balcoes.isNotEmpty) ...[
                      _SectionHeader(
                        label: 'Balcões',
                        count: balcoes.length,
                      ),
                      const SizedBox(height: Dimensions.spacingSM),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: balcoes.length,
                        itemBuilder: (context, index) {
                          final balcao = balcoes[index];
                          final alocacoes =
                              alocacaoProvider.getAlocacoesCaixa(balcao.id);
                          return BalcaoListItem(
                              balcao: balcao, alocacoes: alocacoes);
                        },
                      ),
                      const SizedBox(height: Dimensions.spacingLG),
                    ],

                    // Pacotes — lista de presença de empacotadores
                    const PacoteSection(),
                    const SizedBox(height: Dimensions.spacingMD),
                  ],
                ),
              ),
            );
          }),

          // ── ABA 2: CAIXAS ────────────────────────────────────────────────
          _CaixasBody(onRefresh: _loadData),
        ],
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AlocacaoScreen(
                      fiscalId: authProvider.user?.id ?? '',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Alocar'),
              backgroundColor: AppColors.primary,
            )
          : FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CaixaFormScreen(),
                  ),
                );
                _loadData();
              },
              icon: const Icon(Icons.add),
              label: const Text('Novo Caixa'),
              backgroundColor: AppColors.success,
            ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

// ── Aba "Caixas" ──────────────────────────────────────────────────────────────

class _CaixasBody extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _CaixasBody({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final caixaProvider = Provider.of<CaixaProvider>(context);

    if (caixaProvider.isLoading) {
      return const LoadingWidget(message: 'Carregando caixas...');
    }

    return Column(
      children: [
        // Stats
        _StatsBar(provider: caixaProvider),

        // Filtro
        _FilterBar(provider: caixaProvider),

        // Lista
        Expanded(
          child: caixaProvider.caixas.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.point_of_sale,
                  title: 'Nenhum caixa',
                  message: 'Você não possui caixas cadastrados',
                )
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(Dimensions.paddingMD),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: Dimensions.spacingSM,
                      mainAxisSpacing: Dimensions.spacingSM,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: caixaProvider.caixas.length,
                    itemBuilder: (_, i) =>
                        CaixaGridCard(caixa: caixaProvider.caixas[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _StatsBar extends StatelessWidget {
  final CaixaProvider provider;

  const _StatsBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBackground,
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
              label: 'Ativos',
              value: provider.totalAtivos.toString(),
              color: AppColors.success),
          _StatItem(
              label: 'Manutenção',
              value: provider.totalEmManutencao.toString(),
              color: Colors.orange),
          _StatItem(
              label: 'Inativos',
              value: provider.totalInativos.toString(),
              color: AppColors.textSecondary),
          _StatItem(
              label: 'Total',
              value: provider.totalCaixas.toString(),
              color: AppColors.primary),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.h3
                .copyWith(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final CaixaProvider provider;

  const _FilterBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      child: GestureDetector(
        onTap: () => provider.toggleFiltroAtivos(),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingMD,
            vertical: Dimensions.paddingSM,
          ),
          decoration: BoxDecoration(
            color: provider.mostrarApenasAtivos
                ? AppColors.primary
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(Dimensions.borderRadius),
            border: Border.all(
              color: provider.mostrarApenasAtivos
                  ? AppColors.primary
                  : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_list,
                color: provider.mostrarApenasAtivos
                    ? Colors.white
                    : AppColors.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                provider.mostrarApenasAtivos ? 'Apenas Ativos' : 'Ver Todos',
                style: AppTextStyles.label.copyWith(
                  color: provider.mostrarApenasAtivos
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontWeight: provider.mostrarApenasAtivos
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Seção com cabeçalho e contador ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;

  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.h3),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.backgroundSection,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
