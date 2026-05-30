import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/alocacao.dart';
import '../../../domain/entities/caixa.dart';
import '../../../domain/entities/colaborador.dart';
import '../../../domain/enums/departamento_tipo.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cafe_provider.dart';
import '../../providers/caixa_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/escala_provider.dart';
import '../alocacao/alocacao_screen.dart';
import '../cafe/cafe_screen.dart';
import '../mapa/mapa_caixas_screen.dart';
import 'gargalo_calculator.dart';
import 'visao_gargalo_screen.dart';

class GestaoScreen extends StatefulWidget {
  static const int centralIndex = -1;

  final int initialIndex;

  const GestaoScreen({super.key, this.initialIndex = 0});

  @override
  State<GestaoScreen> createState() => _GestaoScreenState();
}

class _GestaoScreenState extends State<GestaoScreen> {
  late int _currentIndex;
  late String _fiscalId;

  @override
  void initState() {
    super.initState();
    _currentIndex = _initialToTabIndex(widget.initialIndex);
    _fiscalId =
        Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  int _initialToTabIndex(int initialIndex) {
    if (initialIndex == GestaoScreen.centralIndex) return 0;
    return (initialIndex + 1).clamp(1, 4);
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id ?? _fiscalId;
    if (userId.isEmpty) return;

    await Future.wait([
      Provider.of<ColaboradorProvider>(context, listen: false)
          .loadColaboradores(userId),
      Provider.of<CaixaProvider>(context, listen: false).loadCaixas(userId),
      Provider.of<AlocacaoProvider>(context, listen: false)
          .loadAlocacoes(userId),
      Provider.of<CafeProvider>(context, listen: false).load(),
      Provider.of<EscalaProvider>(context, listen: false).load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final fiscalId = _fiscalId;
    final cafeProvider = context.watch<CafeProvider>();
    final escalaProvider = context.watch<EscalaProvider>();
    final alocacaoProvider = context.watch<AlocacaoProvider>();

    final atrasos = cafeProvider.totalEmAtraso;
    final gargalos = contarGargalosHoje(
      escala: escalaProvider,
      alocacao: alocacaoProvider,
      cafe: cafeProvider,
    );

    final destinos = <_GestaoDestination>[
      _GestaoDestination(
        label: 'Central',
        icon: Icons.dashboard_customize_outlined,
        selectedIcon: Icons.dashboard_customize_rounded,
        color: AppColors.primary,
      ),
      _GestaoDestination(
        label: 'Alocacao',
        icon: Icons.swap_horiz_outlined,
        selectedIcon: Icons.swap_horiz_rounded,
        color: AppColors.primary,
      ),
      _GestaoDestination(
        label: 'Mapa',
        icon: Icons.map_outlined,
        selectedIcon: Icons.map_rounded,
        color: AppColors.cyan,
      ),
      _GestaoDestination(
        label: 'Cafe',
        icon: Icons.restaurant_outlined,
        selectedIcon: Icons.restaurant_rounded,
        color: AppColors.statusCafe,
        badgeCount: atrasos,
      ),
      _GestaoDestination(
        label: 'Gargalo',
        icon: Icons.insights_outlined,
        selectedIcon: Icons.insights_rounded,
        color: AppColors.statusAtencao,
        badgeCount: gargalos,
      ),
    ];

    final pages = [
      _CaixasCentralView(
        onRefresh: _loadData,
        onOpenAlocacao: () => setState(() => _currentIndex = 1),
        onOpenMapa: () => setState(() => _currentIndex = 2),
        onOpenCafe: () => setState(() => _currentIndex = 3),
        onOpenGargalo: () => setState(() => _currentIndex = 4),
      ),
      AlocacaoScreen(fiscalId: fiscalId),
      const MapaCaixasScreen(),
      const CafeScreen(),
      const VisaoGargaloScreen(),
    ];

    return Scaffold(
      backgroundColor: tokens.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;

          if (!isWide) {
            return Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: _GestaoTopNavigation(
                    destinos: destinos,
                    selectedIndex: _currentIndex,
                    compact: true,
                    onRefresh: _loadData,
                    onSelected: (i) => setState(() => _currentIndex = i),
                  ),
                ),
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: pages),
                ),
              ],
            );
          }

          return Row(
            children: [
              _CaixasSidebarV3(
                destinos: destinos,
                selectedIndex: _currentIndex,
                onSelected: (i) => setState(() => _currentIndex = i),
              ),
              Expanded(
                child: Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: _GestaoTopNavigation(
                        destinos: destinos,
                        selectedIndex: _currentIndex,
                        onRefresh: _loadData,
                        onSelected: (i) => setState(() => _currentIndex = i),
                      ),
                    ),
                    Expanded(
                      child:
                          IndexedStack(index: _currentIndex, children: pages),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CaixasCentralView extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenAlocacao;
  final VoidCallback onOpenMapa;
  final VoidCallback onOpenCafe;
  final VoidCallback onOpenGargalo;

  const _CaixasCentralView({
    required this.onRefresh,
    required this.onOpenAlocacao,
    required this.onOpenMapa,
    required this.onOpenCafe,
    required this.onOpenGargalo,
  });

  @override
  Widget build(BuildContext context) {
    final colaboradores = context.watch<ColaboradorProvider>();
    final caixas = context.watch<CaixaProvider>();
    final alocacao = context.watch<AlocacaoProvider>();
    final cafe = context.watch<CafeProvider>();
    final escala = context.watch<EscalaProvider>();

    final alocacoesAtivas = alocacao.getAlocacoesAtivas();
    final alocadosIds = alocacoesAtivas.map((a) => a.colaboradorId).toSet();
    final pausaIds = cafe.pausasAtivas.map((p) => p.colaboradorId).toSet();
    final ativosBase = _colaboradoresOperacionais(colaboradores, escala);
    final disponiveis = ativosBase
        .where((c) => !alocadosIds.contains(c.id) && !pausaIds.contains(c.id))
        .toList();
    final caixasOperacionais = _caixasOperacionais(caixas);
    final caixasLivres = caixasOperacionais
        .where((c) => alocacao.getAlocacaoCaixa(c.id) == null);
    final gargalos = contarGargalosHoje(
      escala: escala,
      alocacao: alocacao,
      cafe: cafe,
    );
    final risco = cafe.totalEmAtraso + gargalos;
    final sugestaoColaborador =
        disponiveis.isNotEmpty ? disponiveis.first : null;
    final sugestaoCaixa = caixasLivres.isNotEmpty ? caixasLivres.first : null;
    final queue = _buildPauseQueue(escala, alocacao, cafe);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CaixasHeroHeader(
                  risco: risco,
                  gargalos: gargalos,
                  atrasos: cafe.totalEmAtraso,
                ),
                const SizedBox(height: 22),
                _CaixasSummaryGrid(
                  disponiveis: disponiveis.length,
                  alocados: alocacao.quantidadeAtivasAgora,
                  emPausa: cafe.totalAtivos,
                  risco: risco,
                ),
                const SizedBox(height: 24),
                Text(
                  'Acoes necessarias',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                _ActionGrid(
                  actions: [
                    if (sugestaoColaborador != null && sugestaoCaixa != null)
                      _CentralAction(
                        icon: Icons.auto_awesome_rounded,
                        title:
                            '${sugestaoColaborador.nome.split(' ').first} pode cobrir ${_caixaLabel(sugestaoCaixa)}',
                        description:
                            'Sugestao rapida usando colaborador livre e caixa sem alocacao.',
                        buttonText: 'Abrir alocacao',
                        color: AppColors.primary,
                        onTap: onOpenAlocacao,
                      ),
                    if (cafe.totalEmAtraso > 0)
                      _CentralAction(
                        icon: Icons.timer_off_rounded,
                        title:
                            '${cafe.totalEmAtraso} pausa${cafe.totalEmAtraso > 1 ? 's' : ''} em atraso',
                        description:
                            'Retorne ou realoque antes de abrir nova pausa.',
                        buttonText: 'Ver fila',
                        color: AppColors.danger,
                        onTap: onOpenCafe,
                      ),
                    if (queue.isNotEmpty)
                      _CentralAction(
                        icon: Icons.restaurant_rounded,
                        title:
                            '${queue.length} pausa${queue.length > 1 ? 's' : ''} na fila',
                        description: 'Organize substituicoes antes de liberar.',
                        buttonText: 'Acompanhar',
                        color: AppColors.statusCafe,
                        onTap: onOpenCafe,
                      ),
                    if (gargalos > 0)
                      _CentralAction(
                        icon: Icons.insights_rounded,
                        title:
                            '$gargalos risco${gargalos > 1 ? 's' : ''} de gargalo',
                        description:
                            'Revise cobertura nas proximas faixas de horario.',
                        buttonText: 'Ver gargalo',
                        color: AppColors.warning,
                        onTap: onOpenGargalo,
                      ),
                    if (risco == 0)
                      _CentralAction(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Operacao estavel',
                        description:
                            'Sem atrasos ou gargalos previstos no momento.',
                        buttonText: 'Abrir mapa',
                        color: AppColors.success,
                        onTap: onOpenMapa,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 920;
                    final pause = _MiniPauseQueue(queue: queue);
                    final map = _MiniCashierMap(
                      caixas: caixasOperacionais,
                      alocacoes: alocacoesAtivas,
                      colaboradores: colaboradores.todosColaboradores,
                      cafe: cafe,
                      onOpenMapa: onOpenMapa,
                    );

                    if (!wide) {
                      return Column(
                        children: [
                          pause,
                          const SizedBox(height: 18),
                          map,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: pause),
                        const SizedBox(width: 18),
                        Expanded(child: map),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _MiniBottleneckPanel(
                  escala: escala,
                  alocacao: alocacao,
                  cafe: cafe,
                  onOpenGargalo: onOpenGargalo,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaixasHeroHeader extends StatelessWidget {
  final int risco;
  final int gargalos;
  final int atrasos;

  const _CaixasHeroHeader({
    required this.risco,
    required this.gargalos,
    required this.atrasos,
  });

  @override
  Widget build(BuildContext context) {
    final color = risco > 0 ? AppColors.warning : AppColors.success;
    final title = risco > 0 ? '$risco acao critica' : 'Tudo sob controle';
    final subtitle = risco > 0
        ? '${atrasos > 0 ? '$atrasos pausa(s) em atraso' : 'Sem pausa atrasada'} - ${gargalos > 0 ? '$gargalos gargalo(s)' : 'sem gargalo'}'
        : 'Sem atrasos ou gargalos previstos.';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final alert = Container(
            width: constraints.maxWidth >= 780 ? 330 : double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Icon(
                  risco > 0
                      ? Icons.notifications_active_rounded
                      : Icons.check_circle_outline_rounded,
                  color: color,
                  size: 30,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          final headline = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Central Operacional',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Decida quem alocar, quem liberar e onde existe risco de cobertura.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 780) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                headline,
                const SizedBox(height: 18),
                alert,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: headline),
              const SizedBox(width: 24),
              alert,
            ],
          );
        },
      ),
    );
  }
}

class _CaixasSummaryGrid extends StatelessWidget {
  final int disponiveis;
  final int alocados;
  final int emPausa;
  final int risco;

  const _CaixasSummaryGrid({
    required this.disponiveis,
    required this.alocados,
    required this.emPausa,
    required this.risco,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryInfo(
        icon: Icons.people_alt_rounded,
        value: disponiveis.toString(),
        title: 'Disponiveis',
        subtitle: 'Prontos para caixa',
        color: AppColors.success,
      ),
      _SummaryInfo(
        icon: Icons.point_of_sale_rounded,
        value: alocados.toString(),
        title: 'Alocados',
        subtitle: 'Em operacao',
        color: AppColors.primary,
      ),
      _SummaryInfo(
        icon: Icons.restaurant_rounded,
        value: emPausa.toString(),
        title: 'Em pausa',
        subtitle: 'Fora do caixa',
        color: AppColors.statusCafe,
      ),
      _SummaryInfo(
        icon: Icons.warning_rounded,
        value: risco.toString(),
        title: 'Risco',
        subtitle: 'Precisa acao',
        color: risco > 0 ? AppColors.danger : AppColors.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 112,
          ),
          itemBuilder: (context, index) => _SummaryCard(info: items[index]),
        );
      },
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final List<_CentralAction> actions;

  const _ActionGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1080
            ? 3
            : constraints.maxWidth >= 700
                ? 2
                : 1;

        return GridView.builder(
          itemCount: actions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 220,
          ),
          itemBuilder: (context, index) => _OperationalActionCard(
            action: actions[index],
          ),
        );
      },
    );
  }
}

class _MiniPauseQueue extends StatelessWidget {
  final List<_PauseQueueEntry> queue;

  const _MiniPauseQueue({required this.queue});

  @override
  Widget build(BuildContext context) {
    return _GestaoPanel(
      title: 'Proximas pausas',
      icon: Icons.restaurant_rounded,
      child: queue.isEmpty
          ? const _PanelEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'Sem pausas pendentes',
              message: 'Nenhum intervalo previsto agora.',
            )
          : Column(
              children: [
                for (int i = 0; i < queue.take(4).length; i++) ...[
                  _PauseQueueCard(item: queue[i], position: i + 1),
                  if (i < queue.take(4).length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _MiniCashierMap extends StatelessWidget {
  final List<Caixa> caixas;
  final List<Alocacao> alocacoes;
  final List<Colaborador> colaboradores;
  final CafeProvider cafe;
  final VoidCallback onOpenMapa;

  const _MiniCashierMap({
    required this.caixas,
    required this.alocacoes,
    required this.colaboradores,
    required this.cafe,
    required this.onOpenMapa,
  });

  @override
  Widget build(BuildContext context) {
    final colabById = {for (final c in colaboradores) c.id: c};
    final alocByCaixa = {for (final a in alocacoes) a.caixaId: a};
    final visible = caixas.take(6).toList();

    return _GestaoPanel(
      title: 'Mapa rapido',
      icon: Icons.map_rounded,
      trailing: TextButton.icon(
        onPressed: onOpenMapa,
        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
        label: const Text('Abrir mapa'),
      ),
      child: visible.isEmpty
          ? const _PanelEmptyState(
              icon: Icons.point_of_sale_outlined,
              title: 'Nenhum caixa carregado',
              message: 'Cadastre ou carregue os caixas para visualizar.',
            )
          : Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final caixa in visible)
                  _CashierMiniCard(
                    caixa: caixa,
                    alocacao: alocByCaixa[caixa.id],
                    colaborador:
                        colabById[alocByCaixa[caixa.id]?.colaboradorId],
                    pausa: cafe.getPausaAtivaPorCaixa(caixa.id),
                  ),
              ],
            ),
    );
  }
}

class _MiniBottleneckPanel extends StatelessWidget {
  final EscalaProvider escala;
  final AlocacaoProvider alocacao;
  final CafeProvider cafe;
  final VoidCallback onOpenGargalo;

  const _MiniBottleneckPanel({
    required this.escala,
    required this.alocacao,
    required this.cafe,
    required this.onOpenGargalo,
  });

  @override
  Widget build(BuildContext context) {
    final slots = _slotsCaixa(escala, alocacao, cafe);
    final temGargalo = slots.any((slot) => slot.gargalo);
    final peak = slots.fold<int>(
      1,
      (value, slot) => slot.quantidade > value ? slot.quantidade : value,
    );

    return _GestaoPanel(
      title: 'Visao de gargalo',
      icon: Icons.insights_rounded,
      trailing: TextButton.icon(
        onPressed: onOpenGargalo,
        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
        label: const Text('Ver detalhes'),
      ),
      child: slots.isEmpty
          ? const _PanelEmptyState(
              icon: Icons.insights_outlined,
              title: 'Sem escala para analisar',
              message: 'Importe ou gere a escala para prever cobertura.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cobertura disponivel por faixa de 30 minutos.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final slot in slots)
                        Expanded(
                          child: _BottleneckBar(
                            slot: slot,
                            peak: peak,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (temGargalo ? AppColors.warning : AppColors.success)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          (temGargalo ? AppColors.warning : AppColors.success)
                              .withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        temGargalo
                            ? Icons.auto_awesome_rounded
                            : Icons.check_circle_outline_rounded,
                        color:
                            temGargalo ? AppColors.warning : AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          temGargalo
                              ? 'Sugestao: revise pausas e entradas nas faixas em amarelo/vermelho.'
                              : 'Cobertura projetada estavel nas proximas 4h.',
                          style: AppTextStyles.label.copyWith(
                            color: temGargalo
                                ? AppColors.warning
                                : AppColors.success,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _CaixasSidebarV3 extends StatelessWidget {
  final List<_GestaoDestination> destinos;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _CaixasSidebarV3({
    required this.destinos,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(right: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Color(0xFF0F766E)),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Marcos',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          'Fiscal de Caixa',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Online',
                          style: TextStyle(
                            color: Color(0xFFA7F3D0),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            for (int i = 0; i < destinos.length; i++) ...[
              _SidebarTile(
                item: destinos[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
              const SizedBox(height: 10),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _softCard(color: AppColors.background),
              child: const Row(
                children: [
                  Icon(Icons.headset_mic_rounded, color: Color(0xFF64748B)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ajuda e suporte',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GestaoTopNavigation extends StatelessWidget {
  final List<_GestaoDestination> destinos;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onRefresh;
  final bool compact;

  const _GestaoTopNavigation({
    required this.destinos,
    required this.selectedIndex,
    required this.onSelected,
    required this.onRefresh,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 72 : 76),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 24,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Voltar',
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            Text(
              'Centro de Controle dos Caixas',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
          const Spacer(),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: [
                  for (int i = 0; i < destinos.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _GestaoChip(
                      item: destinos[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelected(i),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _GestaoDestination item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    color: selected ? item.color : AppColors.textSecondary,
                  ),
                  if (item.badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: _Badge(value: item.badgeCount),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w800,
                    color: selected ? item.color : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GestaoDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Color color;
  final int badgeCount;

  const _GestaoDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.color,
    this.badgeCount = 0,
  });
}

class _GestaoChip extends StatelessWidget {
  final _GestaoDestination item;
  final bool selected;
  final VoidCallback onTap;

  const _GestaoChip({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingMD,
            vertical: Dimensions.paddingSM,
          ),
          decoration: BoxDecoration(
            color: selected
                ? item.color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? item.color.withValues(alpha: 0.28)
                  : AppColors.cardBorder.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: 16,
                    color: selected ? item.color : AppColors.textSecondary,
                  ),
                  if (item.badgeCount > 0)
                    Positioned(
                      top: -7,
                      right: -9,
                      child: _Badge(value: item.badgeCount),
                    ),
                ],
              ),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? item.color : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final _SummaryInfo info;

  const _SummaryCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _softCard(
        color: info.color.withValues(alpha: 0.06),
        borderColor: info.color.withValues(alpha: 0.18),
      ),
      child: Row(
        children: [
          _IconBox(icon: info.icon, color: info.color, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  info.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: info.color,
                    letterSpacing: 0,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  info.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  info.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationalActionCard extends StatelessWidget {
  final _CentralAction action;

  const _OperationalActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _softCard(
        color: action.color.withValues(alpha: 0.06),
        borderColor: action.color.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(icon: action.icon, color: action.color, size: 44),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: action.color),
            ],
          ),
          const Spacer(),
          Text(
            action.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            action.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: action.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: action.onTap,
            child: Text(action.buttonText),
          ),
        ],
      ),
    );
  }
}

class _GestaoPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _GestaoPanel({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _softCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(icon: icon, color: AppColors.primary, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PauseQueueCard extends StatelessWidget {
  final _PauseQueueEntry item;
  final int position;

  const _PauseQueueCard({required this.item, required this.position});

  @override
  Widget build(BuildContext context) {
    final color = item.canGoNow ? AppColors.statusCafe : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _softCard(
        color: item.canGoNow ? const Color(0xFFFFF7ED) : Colors.white,
        borderColor: color.withValues(alpha: 0.22),
        radius: 18,
        elevated: false,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '$position',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${item.role} - ${item.scheduledTime}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  item.delay,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: item.canGoNow ? () {} : null,
            icon: const Icon(Icons.restaurant_rounded, size: 18),
            label: const Text('Pausa'),
          ),
        ],
      ),
    );
  }
}

class _CashierMiniCard extends StatelessWidget {
  final Caixa caixa;
  final Alocacao? alocacao;
  final Colaborador? colaborador;
  final PausaCafe? pausa;

  const _CashierMiniCard({
    required this.caixa,
    required this.alocacao,
    required this.colaborador,
    required this.pausa,
  });

  @override
  Widget build(BuildContext context) {
    final status = _cashierStatus(caixa, alocacao, pausa);
    return Container(
      width: 190,
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: _softCard(
        color: status.color.withValues(alpha: 0.06),
        borderColor: status.color.withValues(alpha: 0.25),
        radius: 18,
        elevated: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const Spacer(),
              Icon(Icons.point_of_sale_rounded, color: status.color),
            ],
          ),
          const Spacer(),
          Text(
            _caixaLabel(caixa),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            caixa.localizacao?.trim().isNotEmpty == true
                ? caixa.localizacao!
                : caixa.tipo.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            colaborador?.nome ?? pausa?.colaboradorNome ?? status.operatorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            '${status.label} - ${status.note}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: status.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottleneckBar extends StatelessWidget {
  final SlotDisponibilidade slot;
  final int peak;

  const _BottleneckBar({required this.slot, required this.peak});

  @override
  Widget build(BuildContext context) {
    final color = slot.gargalo
        ? (slot.quantidade < slot.capacidadeMinima
            ? AppColors.danger
            : AppColors.warning)
        : AppColors.success;
    final barHeight = (34 + (slot.quantidade / peak) * 74).clamp(34.0, 112.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${slot.quantidade}',
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 46,
          height: barHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatTime(slot.inicio),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PanelEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _PanelEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _IconBox(icon: icon, color: AppColors.primary, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  message,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _IconBox({
    required this.icon,
    required this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

class _Badge extends StatelessWidget {
  final int value;

  const _Badge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        value > 99 ? '99+' : '$value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SummaryInfo {
  final IconData icon;
  final String value;
  final String title;
  final String subtitle;
  final Color color;

  const _SummaryInfo({
    required this.icon,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _CentralAction {
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final Color color;
  final VoidCallback onTap;

  const _CentralAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.color,
    required this.onTap,
  });
}

class _PauseQueueEntry {
  final String name;
  final String role;
  final String scheduledTime;
  final String delay;
  final bool canGoNow;

  const _PauseQueueEntry({
    required this.name,
    required this.role,
    required this.scheduledTime,
    required this.delay,
    required this.canGoNow,
  });
}

class _CashierStatusInfo {
  final String label;
  final String operatorName;
  final String note;
  final Color color;

  const _CashierStatusInfo({
    required this.label,
    required this.operatorName,
    required this.note,
    required this.color,
  });
}

BoxDecoration _softCard({
  Color? color,
  Color? borderColor,
  double radius = 24,
  bool elevated = true,
}) {
  return BoxDecoration(
    color: color ?? AppColors.cardBackground,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? AppColors.cardBorder),
    boxShadow: elevated
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ]
        : null,
  );
}

List<Colaborador> _colaboradoresOperacionais(
  ColaboradorProvider colaboradores,
  EscalaProvider escala,
) {
  final ativos =
      colaboradores.todosColaboradores.where((c) => c.ativo).toList();
  final trabalhandoIds =
      escala.trabalhandoHoje.map((t) => t.colaboradorId).toSet();
  if (trabalhandoIds.isEmpty) return ativos;
  return ativos.where((c) => trabalhandoIds.contains(c.id)).toList();
}

List<Caixa> _caixasOperacionais(CaixaProvider provider) {
  final caixas = [
    ...(provider.caixasTodos.isNotEmpty
        ? provider.caixasTodos
        : provider.caixas)
  ]..sort((a, b) => a.numero.compareTo(b.numero));
  return caixas;
}

List<_PauseQueueEntry> _buildPauseQueue(
  EscalaProvider escala,
  AlocacaoProvider alocacao,
  CafeProvider cafe,
) {
  final now = DateTime.now();
  final entries = <_PauseQueueEntry>[];

  for (final turno in escala.trabalhandoHoje) {
    if (turno.intervalo == null || turno.intervalo!.trim().isEmpty) continue;
    if (alocacao.isIntervaloMarcado(turno.colaboradorId)) continue;
    if (cafe.colaboradorJaFezIntervaloHoje(turno.colaboradorId)) continue;

    final pausaAtiva = cafe.getPausaAtiva(turno.colaboradorId);
    final scheduled = _parseTimeToday(turno.intervalo!, now);
    if (scheduled == null && pausaAtiva == null) continue;

    final diff = scheduled?.difference(now).inMinutes ?? 0;
    final delay = pausaAtiva != null
        ? 'Em pausa'
        : diff < 0
            ? '+${diff.abs()} min'
            : diff <= 15
                ? 'Agora'
                : diff <= 45
                    ? 'Proxima'
                    : 'Em ${diff ~/ 60 > 0 ? '${diff ~/ 60}h ' : ''}${diff.remainder(60)}min';

    entries.add(
      _PauseQueueEntry(
        name: turno.colaboradorNome,
        role: turno.departamento.nome,
        scheduledTime: turno.intervalo!,
        delay: delay,
        canGoNow: pausaAtiva == null && diff <= 15,
      ),
    );
  }

  entries.sort((a, b) {
    final aMin = _minutes(a.scheduledTime);
    final bMin = _minutes(b.scheduledTime);
    return aMin.compareTo(bMin);
  });
  return entries;
}

List<SlotDisponibilidade> _slotsCaixa(
  EscalaProvider escala,
  AlocacaoProvider alocacao,
  CafeProvider cafe,
) {
  final turnos = escala.turnosHoje;
  if (turnos.isEmpty) return const [];

  final alocacaoByColab = {
    for (final a in alocacao.getAlocacoesAtivas()) a.colaboradorId: a
  };
  final pausaByColab = {for (final p in cafe.pausasAtivas) p.colaboradorId: p};
  final status = turnos
      .map(
        (t) => StatusColaboradorCompleto(
          turno: t,
          alocacao: alocacaoByColab[t.colaboradorId],
          pausaAtiva: pausaByColab[t.colaboradorId],
        ),
      )
      .toList();

  final inicio = _floorToSlot(DateTime.now());
  final fim = inicio.add(const Duration(hours: 4));
  return GargaloCalculator(status, inicio: inicio, fim: fim)
      .calcularPorSetor(DepartamentoTipo.caixa);
}

_CashierStatusInfo _cashierStatus(
  Caixa caixa,
  Alocacao? alocacao,
  PausaCafe? pausa,
) {
  if (caixa.emManutencao) {
    return _CashierStatusInfo(
      label: 'Manutencao',
      operatorName: 'Indisponivel',
      note: 'Aguardando ajuste',
      color: AppColors.danger,
    );
  }
  if (!caixa.ativo) {
    return _CashierStatusInfo(
      label: 'Fechado',
      operatorName: 'Inativo',
      note: 'Fora da operacao',
      color: AppColors.inactive,
    );
  }
  if (pausa != null && alocacao == null) {
    return _CashierStatusInfo(
      label: 'Pausa',
      operatorName: 'Em pausa',
      note: 'Retorno pendente',
      color: AppColors.statusCafe,
    );
  }
  if (alocacao != null) {
    return _CashierStatusInfo(
      label: 'Ativo',
      operatorName: 'Operando',
      note: 'Operando normal',
      color: AppColors.success,
    );
  }
  return _CashierStatusInfo(
    label: 'Livre',
    operatorName: 'Livre',
    note: 'Pronto para cobertura',
    color: AppColors.primary,
  );
}

DateTime _floorToSlot(DateTime dt) {
  final base = DateTime(dt.year, dt.month, dt.day);
  final totalMin = dt.hour * 60 + dt.minute;
  final slotMin = (totalMin ~/ 30) * 30;
  return base.add(Duration(minutes: slotMin));
}

DateTime? _parseTimeToday(String hhmm, DateTime base) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return DateTime(base.year, base.month, base.day, h, m);
}

int _minutes(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return 0;
  return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
}

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _caixaLabel(Caixa caixa) {
  return 'CX${caixa.numero.toString().padLeft(2, '0')}';
}
