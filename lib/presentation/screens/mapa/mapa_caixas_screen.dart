import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/alocacao.dart';
import '../../../domain/entities/caixa.dart';
import '../../../domain/entities/colaborador.dart';
import '../../providers/auth_provider.dart';
import '../../providers/caixa_provider.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/cafe_provider.dart';
import '../../providers/escala_provider.dart';
import '../../providers/pacote_plantao_provider.dart';
import '../../providers/outro_setor_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../caixas/caixa_form_screen.dart';
import '../caixas/widgets/caixa_card.dart';
import 'widgets/caixa_list_item.dart';
import 'widgets/balcao_list_item.dart';
import 'widgets/pacote_section.dart';
import 'widgets/outro_setor_section.dart';
import '../../../core/utils/app_notif.dart';
import '../../../domain/enums/tipo_caixa.dart';

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

  Timer? _timerSaidas;
  final Set<String> _saidasProcessadas = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _tabIndex = _tabController.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
      _iniciarTimerSaidas();
    });
  }

  @override
  void dispose() {
    _timerSaidas?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _iniciarTimerSaidas() {
    _verificarSaidasAutomaticas();
    _timerSaidas = Timer.periodic(const Duration(minutes: 1), (_) {
      _verificarSaidasAutomaticas();
    });
  }

  void _verificarSaidasAutomaticas() {
    if (!mounted) return;
    final escala = Provider.of<EscalaProvider>(context, listen: false);
    final plantao = Provider.of<PacotePlantaoProvider>(context, listen: false);
    final agora = DateTime.now();

    // ── Caixas ──────────────────────────────────────────────────────────────
    /*
    for (final turno in escala.turnosHoje) {
      if (turno.saida == null || turno.folga || turno.feriado) continue;
      if (_saidasProcessadas.contains(turno.colaboradorId)) continue;

      final partes = turno.saida!.split(':');
      final h = int.tryParse(partes[0]) ?? -1;
      final m = int.tryParse(partes.length > 1 ? partes[1] : '') ?? -1;
      if (h < 0 || m < 0) continue;

      final saidaHoje = DateTime(agora.year, agora.month, agora.day, h, m);
      if (!agora.isAfter(saidaHoje)) continue;

      final alocacaoAtiva = alocacao.getAlocacaoColaborador(turno.colaboradorId);
      if (alocacaoAtiva == null) continue;

      _saidasProcessadas.add(turno.colaboradorId);
      alocacao.liberarAlocacao(
        alocacaoAtiva.id,
        'Encerramento automático — horário de saída atingido (${turno.saida})',
      );

      if (mounted) {
        AppNotif.show(
          context,
          titulo: 'Saída Automática',
          mensagem: '${turno.colaboradorNome} atingiu o horário de saída e foi liberado(a) do caixa',
          tipo: 'saida',
          cor: AppColors.success,
          duracao: const Duration(seconds: 5),
        );
      }
    }

    */
    // ── Pacotes ─────────────────────────────────────────────────────────────
    for (final p in plantao.plantao.toList()) {
      if (_saidasProcessadas.contains(p.colaboradorId)) continue;

      final turno = escala.turnosHoje
          .where((t) => t.colaboradorId == p.colaboradorId)
          .firstOrNull;
      if (turno?.saida == null ||
          (turno?.folga ?? false) ||
          (turno?.feriado ?? false)) {
        continue;
      }

      final partes = turno!.saida!.split(':');
      final h = int.tryParse(partes[0]) ?? -1;
      final m = int.tryParse(partes.length > 1 ? partes[1] : '') ?? -1;
      if (h < 0 || m < 0) continue;

      final saidaHoje = DateTime(agora.year, agora.month, agora.day, h, m);
      if (!agora.isAfter(saidaHoje)) continue;

      _saidasProcessadas.add(p.colaboradorId);
      plantao.remover(p.id);

      if (mounted) {
        AppNotif.show(
          context,
          titulo: 'Saída Automática',
          mensagem:
              '${turno.colaboradorNome} atingiu o horário de saída e foi removido(a) do plantão de pacotes',
          tipo: 'saida',
          cor: AppColors.success,
          duracao: const Duration(seconds: 5),
        );
      }
    }
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
      Provider.of<EscalaProvider>(context, listen: false).load(),
      Provider.of<OutroSetorProvider>(context, listen: false).load(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final caixaProvider = Provider.of<CaixaProvider>(context);
    final alocacaoProvider = Provider.of<AlocacaoProvider>(context);

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
            final cafeProvider = Provider.of<CafeProvider>(context);

            final caixasTodos = caixaProvider.caixasTodos;

            // Caixas com alocação ativa OU com pausa ativa (café/intervalo)
            final rapidos = caixasTodos
                .where((c) => c.tipo == TipoCaixa.rapido)
                .where((c) =>
                    alocacaoProvider.getAlocacaoCaixa(c.id) != null ||
                    cafeProvider.getPausaAtivaPorCaixa(c.id) != null)
                .toList();
            final normais = caixasTodos
                .where((c) => c.tipo == TipoCaixa.normal)
                .where((c) =>
                    alocacaoProvider.getAlocacaoCaixa(c.id) != null ||
                    cafeProvider.getPausaAtivaPorCaixa(c.id) != null)
                .toList();
            final selfs = caixasTodos
                .where((c) => c.tipo == TipoCaixa.self)
                .where((c) =>
                    alocacaoProvider.getAlocacaoCaixa(c.id) != null ||
                    cafeProvider.getPausaAtivaPorCaixa(c.id) != null)
                .toList();
            final balcoes =
                caixasTodos.where((c) => c.tipo == TipoCaixa.balcao).toList();

            return LayoutBuilder(
                builder: (context, constraints) => RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.hPad(constraints.maxWidth),
                          vertical: Dimensions.paddingMD,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Mini dashboard ──────────────────────────────────
                            _MiniDashboard(
                              alocacaoProvider: alocacaoProvider,
                              cafeProvider: cafeProvider,
                              caixaProvider: caixaProvider,
                              colaboradorProvider:
                                  Provider.of<ColaboradorProvider>(context),
                            ),

                            const SizedBox(height: Dimensions.spacingMD),

                            // Legenda
                            Container(
                              decoration: AppStyles.softCard(
                                tint: AppColors.primary,
                                radius: 16,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(Dimensions.paddingMD),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildLegendItem(
                                        'Ocupado', AppColors.statusAtivo),
                                    _buildLegendItem(
                                        'Disponível', AppColors.success),
                                    _buildLegendItem(
                                        'Inativo', AppColors.inactive),
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
                                  final alocacao = alocacaoProvider
                                      .getAlocacaoCaixa(caixa.id);
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
                                  final alocacao = alocacaoProvider
                                      .getAlocacaoCaixa(caixa.id);
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
                                  final alocacao = alocacaoProvider
                                      .getAlocacaoCaixa(caixa.id);
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
                                  final alocacoes = alocacaoProvider
                                      .getAlocacoesCaixa(balcao.id);
                                  return BalcaoListItem(
                                      balcao: balcao, alocacoes: alocacoes);
                                },
                              ),
                              const SizedBox(height: Dimensions.spacingLG),
                            ],

                            // Pacotes — lista de presença de empacotadores
                            const PacoteSection(),
                            const SizedBox(height: Dimensions.spacingMD),

                            // Outro Setor — colaboradores em outras funções
                            const OutroSetorSection(),
                            const SizedBox(height: Dimensions.spacingMD),
                          ],
                        ),
                      ),
                    ));
          }),

          // ── ABA 2: CAIXAS ────────────────────────────────────────────────
          _CaixasBody(onRefresh: _loadData),
        ],
      ),
      floatingActionButton: _tabIndex == 0
          ? null
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = MediaQuery.sizeOf(context).width;
                      final cols = w >= Dimensions.breakpointWide
                          ? 6
                          : w >= Dimensions.breakpointTablet
                              ? 4
                              : 3;
                      return GridView.builder(
                        padding: const EdgeInsets.all(Dimensions.paddingMD),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: Dimensions.spacingSM,
                          mainAxisSpacing: Dimensions.spacingSM,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: caixaProvider.caixas.length,
                        itemBuilder: (_, i) =>
                            CaixaGridCard(caixa: caixaProvider.caixas[i]),
                      );
                    },
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
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
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

// ── Mini Dashboard do turno ───────────────────────────────────────────────────

class _MiniDashboard extends StatelessWidget {
  final AlocacaoProvider alocacaoProvider;
  final CafeProvider cafeProvider;
  final CaixaProvider caixaProvider;
  final ColaboradorProvider colaboradorProvider;

  const _MiniDashboard({
    required this.alocacaoProvider,
    required this.cafeProvider,
    required this.caixaProvider,
    required this.colaboradorProvider,
  });

  @override
  Widget build(BuildContext context) {
    final caixasIds = caixaProvider.caixasTodos.map((c) => c.id).toSet();
    final totalAlocados = alocacaoProvider
        .getAlocacoesAtivas()
        .where((a) => caixasIds.contains(a.caixaId))
        .length;
    final emPausa = cafeProvider.pausasAtivas
        .where((p) => p.caixaId != null && caixasIds.contains(p.caixaId))
        .length;
    final caixasLivres = caixaProvider.caixasTodos
        .where((c) =>
            c.ativo &&
            !c.emManutencao &&
            alocacaoProvider.getAlocacaoCaixa(c.id) == null)
        .length;
    final totalTurno = alocacaoProvider.quantidadeAlocacoes;

    void abrirDetalheOcupados() {
      final caixas = caixaProvider.caixasTodos;
      final colabById = {
        for (final c in colaboradorProvider.colaboradores) c.id: c
      };
      final ocupados = caixas.where((c) {
        return alocacaoProvider.getAlocacaoCaixa(c.id) != null ||
            cafeProvider.getPausaAtivaPorCaixa(c.id) != null;
      }).toList()
        ..sort((a, b) => a.numero.compareTo(b.numero));

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(Dimensions.radiusSheet)),
        ),
        builder: (_) => _OcupadosSheet(
          caixas: ocupados,
          caixasTodos: caixas,
          alocacaoProvider: alocacaoProvider,
          cafeProvider: cafeProvider,
          colabById: colabById,
        ),
      );
    }

    return Container(
      decoration: AppStyles.softCard(
        tint: AppColors.primary,
        radius: Dimensions.radiusLG,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _DashItem(
              value: '$totalAlocados',
              label: 'Alocados',
              color: AppColors.statusAtivo,
              icon: Icons.person,
              onTap: abrirDetalheOcupados,
            ),
            _DashDivider(),
            _DashItem(
              value: '$emPausa',
              label: 'Em Pausa',
              color: Colors.orange,
              icon: Icons.coffee,
            ),
            _DashDivider(),
            _DashItem(
              value: '$caixasLivres',
              label: 'Livres',
              color: AppColors.success,
              icon: Icons.point_of_sale,
            ),
            _DashDivider(),
            _DashItem(
              value: '$totalTurno',
              label: 'No turno',
              color: AppColors.primary,
              icon: Icons.bar_chart,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _DashItem({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
              ),
              child: Icon(icon, size: 12, color: color),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );

    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: child,
      ),
    );
  }
}

class _DashDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 1,
      color: AppColors.cardBorder,
    );
  }
}

class _OcupadosSheet extends StatelessWidget {
  final List<Caixa> caixas;
  final List<Caixa> caixasTodos;
  final AlocacaoProvider alocacaoProvider;
  final CafeProvider cafeProvider;
  final Map<String, Colaborador> colabById;

  const _OcupadosSheet({
    required this.caixas,
    required this.caixasTodos,
    required this.alocacaoProvider,
    required this.cafeProvider,
    required this.colabById,
  });

  @override
  Widget build(BuildContext context) {
    final temOcupados = caixas.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Row(
            children: [
              Icon(Icons.point_of_sale, size: 18, color: AppColors.primary),
              SizedBox(width: 6),
              Text('Caixas ocupados', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Mostra quais caixas estão contando como ocupados.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (!temOcupados)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Nenhum caixa ocupado no momento.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: caixas.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 16, color: AppColors.cardBorder),
                itemBuilder: (_, i) {
                  final caixa = caixas[i];
                  final alocacao = alocacaoProvider.getAlocacaoCaixa(caixa.id);
                  final pausa = cafeProvider.getPausaAtivaPorCaixa(caixa.id);

                  final nomeAlocado = alocacao != null
                      ? (colabById[alocacao.colaboradorId]?.nome ??
                          caixa.colaboradorAlocadoNome ??
                          '—')
                      : null;
                  final nomePausa = pausa?.colaboradorNome;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _mostrarAcoes(
                      context,
                      caixa,
                      alocacao,
                      pausa,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        caixa.numero.toString(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(caixa.nomeExibicao),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (nomeAlocado != null)
                          Text(
                            'Alocado: $nomeAlocado',
                            style: AppTextStyles.caption,
                          ),
                        if (nomePausa != null)
                          Text(
                            'Em pausa: $nomePausa',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.statusCafe,
                            ),
                          ),
                        if (nomeAlocado == null && nomePausa == null)
                          const Text(
                            'Sem detalhes da ocupação',
                            style: AppTextStyles.caption,
                          ),
                      ],
                    ),
                    trailing: (alocacao != null || pausa != null)
                        ? const Icon(Icons.more_vert, size: 18)
                        : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _mostrarAcoes(
    BuildContext context,
    Caixa caixa,
    Alocacao? alocacao,
    PausaCafe? pausa,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.point_of_sale,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(caixa.nomeExibicao, style: AppTextStyles.h3),
              ],
            ),
            const SizedBox(height: 8),
            if (alocacao != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.exit_to_app, color: AppColors.danger),
                title: const Text('Liberar caixa'),
                subtitle: const Text('Remove a alocação ativa deste caixa'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarLiberar(context, caixa, alocacao);
                },
              ),
            if (pausa != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.coffee, color: AppColors.statusCafe),
                title: const Text('Finalizar pausa'),
                subtitle: const Text('Encerra a pausa ativa deste caixa'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarFinalizarPausa(context, pausa);
                },
              ),
            if (alocacao == null && pausa == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Não há alocação ou pausa ativa para este caixa.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmarLiberar(
    BuildContext context,
    Caixa caixa,
    Alocacao alocacao,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Liberar caixa'),
        content: Text('Deseja liberar ${caixa.nomeExibicao}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await alocacaoProvider.liberarAlocacao(
                alocacao.id,
                'Liberado pelo mapa (lista de ocupados)',
              );
              if (context.mounted) {
                AppNotif.show(
                  context,
                  titulo: 'Caixa liberado',
                  mensagem: '${caixa.nomeExibicao} foi liberado.',
                  tipo: 'saida',
                  cor: AppColors.success,
                );
              }
            },
            child: const Text(
              'Liberar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarFinalizarPausa(
    BuildContext context,
    PausaCafe pausa,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar pausa'),
        content: Text('Deseja finalizar a pausa de ${pausa.colaboradorNome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final fiscalId =
                  Provider.of<AuthProvider>(context, listen: false).user?.id ??
                      '';
              if (fiscalId.isEmpty) {
                if (context.mounted) {
                  AppNotif.show(
                    context,
                    titulo: 'Erro',
                    mensagem: 'Usuario nao autenticado para finalizar pausa.',
                    tipo: 'alerta',
                    cor: AppColors.danger,
                  );
                }
                return;
              }

              String? erro;
              if (pausa.isIntervalo) {
                final escolha = await _escolherRetornoIntervalo(context, pausa);
                if (escolha == null) return;
                erro = await cafeProvider.finalizarPausaComRegra(
                  pausa: pausa,
                  alocacaoProvider: alocacaoProvider,
                  fiscalId: fiscalId,
                  caixaDestinoIntervaloId: escolha.caixaDestinoId,
                  permitirMesmoCaixaNoIntervalo: escolha.permitirMesmoCaixa,
                  justificativaMesmoCaixa: escolha.justificativaMesmoCaixa,
                );
              } else {
                erro = await cafeProvider.finalizarPausaComRegra(
                  pausa: pausa,
                  alocacaoProvider: alocacaoProvider,
                  fiscalId: fiscalId,
                );
              }

              if (context.mounted) {
                if (erro == null) {
                  AppNotif.show(
                    context,
                    titulo: 'Pausa finalizada',
                    mensagem: pausa.isCafe
                        ? 'Pausa de ${pausa.colaboradorNome} finalizada com retorno ao caixa.'
                        : 'Pausa de ${pausa.colaboradorNome} finalizada com realocacao.',
                    tipo: 'saida',
                    cor: AppColors.success,
                  );
                } else {
                  AppNotif.show(
                    context,
                    titulo: 'Pausa finalizada',
                    mensagem: erro,
                    tipo: 'alerta',
                    cor: AppColors.warning,
                  );
                }
              }
            },
            child: const Text(
              'Finalizar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Future<_RetornoIntervaloEscolha?> _escolherRetornoIntervalo(
    BuildContext context,
    PausaCafe pausa,
  ) async {
    final caixasAtivos = caixasTodos
        .where((c) => c.ativo && !c.emManutencao)
        .toList()
      ..sort((a, b) => a.numero.compareTo(b.numero));
    final caixasLivres = caixasAtivos
        .where((c) => alocacaoProvider.getAlocacaoCaixa(c.id) == null)
        .toList();

    if (caixasLivres.isEmpty) {
      if (context.mounted) {
        AppNotif.show(
          context,
          titulo: 'Sem caixa disponivel',
          mensagem: 'Nao ha caixa livre para retorno do intervalo.',
          tipo: 'alerta',
          cor: AppColors.warning,
        );
      }
      return null;
    }

    String? caixaSelecionadoId = caixasLivres
        .where((c) => c.id != pausa.caixaId)
        .map((c) => c.id)
        .firstOrNull;
    caixaSelecionadoId ??= caixasLivres.first.id;
    bool permitirMesmoCaixa = false;
    final justificativaCtrl = TextEditingController();

    final escolha = await showDialog<_RetornoIntervaloEscolha>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final mesmoCaixaSelecionado = pausa.caixaId != null &&
              pausa.caixaId!.isNotEmpty &&
              caixaSelecionadoId == pausa.caixaId;
          final precisaJustificativa =
              mesmoCaixaSelecionado && permitirMesmoCaixa;
          final podeConfirmar = caixaSelecionadoId != null &&
              (!precisaJustificativa ||
                  justificativaCtrl.text.trim().isNotEmpty);

          return AlertDialog(
            title: const Text('Retorno do intervalo'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: RadioGroup<String>(
                  groupValue: caixaSelecionadoId,
                  onChanged: (v) =>
                      setStateDialog(() => caixaSelecionadoId = v),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Regra padrao: retornar em caixa diferente.'),
                      const SizedBox(height: 12),
                      ...caixasAtivos.map((caixa) {
                        final ocupado =
                            alocacaoProvider.getAlocacaoCaixa(caixa.id) != null;
                        Widget tile = RadioListTile<String>(
                          value: caixa.id,
                          title: Text(caixa.nomeExibicao),
                          subtitle:
                              Text(ocupado ? 'Ocupado agora' : 'Disponivel'),
                          dense: true,
                        );
                        if (ocupado) {
                          tile = Opacity(
                            opacity: 0.5,
                            child: IgnorePointer(child: tile),
                          );
                        }
                        return tile;
                      }),
                      if (mesmoCaixaSelecionado) ...[
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: permitirMesmoCaixa,
                          onChanged: (v) => setStateDialog(
                            () => permitirMesmoCaixa = v ?? false,
                          ),
                          title: const Text('Permitir mesmo caixa (excecao)'),
                          subtitle: const Text(
                            'Necessario justificar para auditoria.',
                          ),
                        ),
                        if (permitirMesmoCaixa) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: justificativaCtrl,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Justificativa da excecao *',
                            ),
                            onChanged: (_) => setStateDialog(() {}),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: !podeConfirmar
                    ? null
                    : () => Navigator.pop(
                          ctx,
                          _RetornoIntervaloEscolha(
                            caixaDestinoId: caixaSelecionadoId!,
                            permitirMesmoCaixa: permitirMesmoCaixa,
                            justificativaMesmoCaixa:
                                justificativaCtrl.text.trim().isEmpty
                                    ? null
                                    : justificativaCtrl.text.trim(),
                          ),
                        ),
                child: const Text('Confirmar retorno'),
              ),
            ],
          );
        },
      ),
    );

    justificativaCtrl.dispose();
    return escolha;
  }
}

class _RetornoIntervaloEscolha {
  final String caixaDestinoId;
  final bool permitirMesmoCaixa;
  final String? justificativaMesmoCaixa;

  const _RetornoIntervaloEscolha({
    required this.caixaDestinoId,
    required this.permitirMesmoCaixa,
    this.justificativaMesmoCaixa,
  });
}
