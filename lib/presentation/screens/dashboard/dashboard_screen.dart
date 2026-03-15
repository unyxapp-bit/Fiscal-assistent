import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/datasources/remote/caixa_remote_datasource.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fiscal_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/caixa_provider.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/cafe_provider.dart';
import '../../providers/entrega_provider.dart';
import '../../providers/escala_provider.dart';
import '../../providers/nota_provider.dart';
import '../../providers/formulario_provider.dart';
import '../../providers/procedimento_provider.dart';
import '../../providers/ocorrencia_provider.dart';
import '../../providers/checklist_provider.dart';
import '../../providers/passagem_turno_provider.dart';
import '../../providers/evento_turno_provider.dart';
import '../../../domain/entities/evento_turno.dart';
import '../ocorrencias/ocorrencias_screen.dart';
import '../checklist/checklist_screen.dart';
import '../passagem_turno/passagem_turno_screen.dart';
import '../guia_rapido/guia_rapido_screen.dart';
import '../colaboradores/colaboradores_list_screen.dart';
import '../gestao/gestao_screen.dart';
import '../notificacoes/notificacoes_screen.dart';
import '../timeline/timeline_screen.dart';
import '../entregas/entregas_screen.dart';
import '../procedimentos/procedimentos_screen.dart';
import '../notas/notas_screen.dart';
import '../formularios/formularios_screen.dart';
import '../folga/folga_screen.dart';
import '../escala/escala_screen.dart';
import '../relatorio/relatorio_diario_screen.dart';
// profile_screen.dart usado via ConfiguracoesScreen
import '../configuracoes/configuracoes_screen.dart';
import '../../../data/services/seed_data_service.dart';
import '../../../core/utils/app_notif.dart';
import 'widgets/clock_widget.dart';
import 'widgets/quick_action_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _abrirBriefingTurno(BuildContext context, String fiscalId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => _BriefingTurnoSheet(fiscalId: fiscalId),
    );
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    final userId = authProvider.user!.id;

    try {
      final caixaRemote =
          Provider.of<CaixaRemoteDataSource>(context, listen: false);
      final seedService = SeedDataService(caixaRemote);
      await seedService.seedCaixas(userId);
    } catch (e) {
      debugPrint('[Dashboard] Erro ao fazer seed: $e');
    }

    if (!mounted) return;

    await Future.wait([
      Provider.of<FiscalProvider>(context, listen: false).loadProfile(userId),
      Provider.of<ColaboradorProvider>(context, listen: false)
          .loadColaboradores(userId),
      Provider.of<CaixaProvider>(context, listen: false).loadCaixas(userId),
      Provider.of<AlocacaoProvider>(context, listen: false)
          .loadAlocacoes(userId),
      Provider.of<CafeProvider>(context, listen: false).load(),
      Provider.of<EntregaProvider>(context, listen: false).load(),
      Provider.of<NotaProvider>(context, listen: false).load(),
      Provider.of<FormularioProvider>(context, listen: false).load(),
      Provider.of<ProcedimentoProvider>(context, listen: false).load(),
      Provider.of<OcorrenciaProvider>(context, listen: false).load(),
      Provider.of<ChecklistProvider>(context, listen: false).load(),
      Provider.of<PassagemTurnoProvider>(context, listen: false).load(),
      Provider.of<EventoTurnoProvider>(context, listen: false).load(userId),
    ]);

    if (mounted) {
      Provider.of<AlocacaoProvider>(context, listen: false)
          .watchAlocacoes(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final fiscalProvider = Provider.of<FiscalProvider>(context);
    final colaboradorProvider = Provider.of<ColaboradorProvider>(context);
    final caixaProvider = Provider.of<CaixaProvider>(context);
    final alocacaoProvider = Provider.of<AlocacaoProvider>(context);
    final cafeProvider = Provider.of<CafeProvider>(context);
    final entregaProvider = Provider.of<EntregaProvider>(context);
    final escalaProvider = Provider.of<EscalaProvider>(context);
    final notaProvider = Provider.of<NotaProvider>(context);
    final ocorrenciaProvider = Provider.of<OcorrenciaProvider>(context);
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final eventoProvider = Provider.of<EventoTurnoProvider>(context);
    final turnoJaIniciado = eventoProvider.turnoIniciadoEm != null;

    final saudacao = _getSaudacao();
    final nome = fiscalProvider.fiscal?.nome ??
        authProvider.user?.email ??
        'Usuário';
    final primeiroNome = nome.split(' ').first;

    final totalAtivos = colaboradorProvider.totalAtivos;
    final totalCaixas = caixaProvider.totalAtivos;
    final alocados = alocacaoProvider.quantidadeAtivasAgora;
    final livres = (totalCaixas - alocados).clamp(0, 999);
    final emPausa = cafeProvider.totalAtivos;
    final emRota = entregaProvider.totalEmRota;

    final alertas = <_AlertItem>[
      if (cafeProvider.totalEmAtraso > 0)
        _AlertItem(
          icon: Icons.coffee,
          label:
              '${cafeProvider.totalEmAtraso} pausa${cafeProvider.totalEmAtraso > 1 ? 's' : ''} em atraso',
          color: AppColors.danger,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const GestaoScreen(initialIndex: 2))),
        ),
      if (entregaProvider.totalSeparadas > 0)
        _AlertItem(
          icon: Icons.inventory,
          label:
              '${entregaProvider.totalSeparadas} entrega${entregaProvider.totalSeparadas > 1 ? 's aguardando' : ' aguardando'} envio',
          color: AppColors.statusAtencao,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EntregasScreen())),
        ),
      if (notaProvider.totalLembretesVencidos > 0)
        _AlertItem(
          icon: Icons.alarm_off,
          label:
              '${notaProvider.totalLembretesVencidos} lembrete${notaProvider.totalLembretesVencidos > 1 ? 's vencidos' : ' vencido'}',
          color: AppColors.danger,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotasScreen())),
        ),
      if (ocorrenciaProvider.totalAbertas > 0)
        _AlertItem(
          icon: Icons.report_problem,
          label:
              '${ocorrenciaProvider.totalAbertas} ocorrência${ocorrenciaProvider.totalAbertas > 1 ? 's abertas' : ' aberta'}',
          color: AppColors.statusAtencao,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OcorrenciasScreen())),
        ),
      for (final t in checklistProvider.templatesPendentesAgora)
        _AlertItem(
          icon: Icons.checklist,
          label: 'Checklist pendente: ${t.titulo}',
          color: AppColors.primary,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ChecklistScreen())),
        ),
    ];

    // ── Tabs compartilhadas entre phone e tablet ────────────────────────────
    final tabBarView = TabBarView(
      controller: _tabController,
      children: [
            // ── ABA 1: INÍCIO ───────────────────────────────────────────────
            LayoutBuilder(
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
                    const ClockWidget(),
                    const SizedBox(height: Dimensions.spacingMD),

                    // Botão Começar Turno — oculto após confirmar início
                    if (!turnoJaIniciado) ...[
                      _ComecaTurnoButton(
                        onPressed: () => _abrirBriefingTurno(
                          context,
                          authProvider.user?.id ?? '',
                        ),
                      ),
                      const SizedBox(height: Dimensions.spacingXL),
                    ],

                    // Stats
                    Card(
                      color: AppColors.cardBackground,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingMD,
                          vertical: Dimensions.paddingSM,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _StatItem(
                                  icon: Icons.people,
                                  label: 'Colaboradores',
                                  value: totalAtivos.toString(),
                                  color: AppColors.primary,
                                ),
                                const _StatDivider(),
                                _StatItem(
                                  icon: Icons.point_of_sale,
                                  label: 'Caixas',
                                  value: totalCaixas.toString(),
                                  color: AppColors.success,
                                ),
                                const _StatDivider(),
                                _StatItem(
                                  icon: Icons.swap_horiz,
                                  label: 'Alocados',
                                  value: alocados.toString(),
                                  color: AppColors.statusAtivo,
                                ),
                              ],
                            ),
                            const Divider(height: 1, thickness: 1),
                            Row(
                              children: [
                                _StatItem(
                                  icon: Icons.check_circle,
                                  label: 'Livres',
                                  value: livres.toString(),
                                  color: AppColors.statusIntervalo,
                                ),
                                const _StatDivider(),
                                _StatItem(
                                  icon: Icons.coffee,
                                  label: 'Em Pausa',
                                  value: emPausa.toString(),
                                  color: AppColors.coffee,
                                ),
                                const _StatDivider(),
                                _StatItem(
                                  icon: Icons.local_shipping,
                                  label: 'Em Rota',
                                  value: emRota.toString(),
                                  color: AppColors.statusCafe,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Alertas
                    if (alertas.isNotEmpty) ...[
                      const SizedBox(height: Dimensions.spacingMD),
                      ...alertas.map((a) => _AlertCard(item: a)),
                    ],

                    // Monitor em tempo real
                    const SizedBox(height: Dimensions.spacingMD),
                    _MonitorTempoReal(
                      cafeProvider: cafeProvider,
                      colaboradorProvider: colaboradorProvider,
                      caixaProvider: caixaProvider,
                      escalaProvider: escalaProvider,
                    ),

                    const SizedBox(height: Dimensions.spacingXL),
                  ],
                ),
              ),
            )),

            // ── ABA 2: PRINCIPAL ────────────────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Dimensions.spacingSM),
                  _GridAcoes(
                    botoes: [
                      _BotaoAcao(
                        icon: Icons.point_of_sale,
                        label: 'Caixas',
                        color: AppColors.primary,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const GestaoScreen(),
                          ),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.people,
                        label: 'Colaboradores',
                        color: AppColors.statusAtivo,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ColaboradoresListScreen()),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.bar_chart,
                        label: 'Relatório',
                        color: AppColors.cyan,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const RelatorioDiarioScreen()),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.calendar_month,
                        label: 'Escala',
                        color: AppColors.pink,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const EscalaScreen()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── ABA 3: OPERAÇÕES ────────────────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Dimensions.spacingSM),
                  _GridAcoes(
                    botoes: [
                      _BotaoAcao(
                        icon: Icons.local_shipping,
                        label: 'Entregas',
                        color: AppColors.statusCafe,
                        badge: entregaProvider.totalEmRota > 0
                            ? entregaProvider.totalEmRota.toString()
                            : null,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const EntregasScreen()),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.report_problem,
                        label: 'Ocorrências',
                        color: AppColors.danger,
                        badge: ocorrenciaProvider.totalAbertas > 0
                            ? ocorrenciaProvider.totalAbertas.toString()
                            : null,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const OcorrenciasScreen()),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.checklist,
                        label: 'Checklist',
                        color: AppColors.success,
                        badge: checklistProvider.templatesPendentesAgora.isNotEmpty
                            ? '!'
                            : null,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ChecklistScreen()),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.handshake,
                        label: 'Passagem Turno',
                        color: AppColors.primary,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const PassagemTurnoScreen()),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.help_outline,
                        label: 'Guia Rápido',
                        color: AppColors.blueGrey,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const GuiaRapidoScreen()),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.note,
                        label: 'Anotações',
                        color: AppColors.statusSaida,
                        badge: notaProvider.totalTarefasPendentes > 0
                            ? notaProvider.totalTarefasPendentes.toString()
                            : null,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const NotasScreen()),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.description,
                        label: 'Formulários',
                        color: AppColors.indigo,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const FormulariosScreen()),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.menu_book,
                        label: 'Procedimentos',
                        color: AppColors.deepPurple,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ProcedimentosScreen()),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.notifications,
                        label: 'Notificações',
                        color: AppColors.primary,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const NotificacoesScreen()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── ABA 4: LOJA ─────────────────────────────────────────────────
            RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(Dimensions.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Dimensions.spacingSM),

                    // Banner de saúde do turno
                    _BannerSaudeTurno(
                      critico: cafeProvider.totalEmAtraso > 0 ||
                          notaProvider.totalLembretesVencidos > 0,
                      atencao: ocorrenciaProvider.totalAbertas > 0 ||
                          entregaProvider.totalSeparadas > 0 ||
                          checklistProvider.templatesPendentesAgora.isNotEmpty,
                    ),
                    const SizedBox(height: Dimensions.spacingMD),

                    if (fiscalProvider.fiscal != null) ...[
                      // Card Ocupação do Turno
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(Dimensions.paddingMD),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ocupação do Turno',
                                  style: AppTextStyles.h4),
                              const SizedBox(height: Dimensions.spacingMD),
                              _OcupacaoBar(
                                alocados: alocados,
                                totalCaixas: totalCaixas,
                                emPausa: emPausa,
                                emRota: emRota,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: CircularProgressIndicator(),
                        ),
                      ),

                    // Cabeçalho da seção Ferramentas
                    const SizedBox(height: Dimensions.spacingMD),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 4, bottom: Dimensions.spacingSM),
                      child: Row(
                        children: [
                          const Icon(Icons.build_outlined,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Ferramentas',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _GridAcoes(
                      botoes: [
                        _BotaoAcao(
                          icon: Icons.history,
                          label: 'Timeline',
                          color: AppColors.statusSelf,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const TimelineScreen()),
                          ),
                        ),
                        _BotaoAcao(
                          icon: Icons.beach_access,
                          label: 'Modo Folga',
                          color: AppColors.teal,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const FolgaScreen()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.spacingXL),
                  ],
                ),
              ),
            ),
      ],
    );

    // ── Layout adaptativo ───────────────────────────────────────────────────
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= Dimensions.breakpointTablet;

        // ── TABLET: NavigationRail + TabBarView ─────────────────────────────
        if (isTablet) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _tabController.index,
                  onDestinationSelected: (i) => _tabController.animateTo(i),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: AppColors.cardBackground,
                  leading: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(saudacao,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary)),
                        Text(primeiroNome, style: AppTextStyles.h4),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          tooltip: 'Configurações',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const ConfiguracoesScreen()),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          tooltip: 'Sair',
                          onPressed: () => authProvider.signOut(),
                        ),
                      ],
                    ),
                  ),
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      label: Text('Início'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.apps_outlined),
                      label: Text('Principal'),
                    ),
                    NavigationRailDestination(
                      icon: Badge(
                        isLabelVisible: cafeProvider.totalEmAtraso > 0,
                        backgroundColor: AppColors.danger,
                        child: const Icon(Icons.build_outlined),
                      ),
                      label: const Text('Operações'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.store_outlined),
                      label: Text('Loja'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: tabBarView),
              ],
            ),
          );
        }

        // ── PHONE: AppBar com TabBar ────────────────────────────────────────
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(saudacao,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
                Text(primeiroNome, style: AppTextStyles.h3),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ConfiguracoesScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => authProvider.signOut(),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              tabs: [
                const Tab(
                    icon: Icon(Icons.home_outlined, size: 20), text: 'Início'),
                const Tab(
                    icon: Icon(Icons.apps_outlined, size: 20),
                    text: 'Principal'),
                Tab(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.build_outlined, size: 20),
                      if (cafeProvider.totalEmAtraso > 0)
                        Positioned(
                          top: -4,
                          right: -6,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  text: 'Operações',
                ),
                const Tab(
                    icon: Icon(Icons.store_outlined, size: 20), text: 'Loja'),
              ],
            ),
          ),
          body: tabBarView,
        );
      },
    );
  }


  String _getSaudacao() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Bom dia';
    if (hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }
}

// ── Monitor em tempo real ─────────────────────────────────────────────────────

class _MonitorTempoReal extends StatelessWidget {
  final CafeProvider cafeProvider;
  final ColaboradorProvider colaboradorProvider;
  final CaixaProvider caixaProvider;
  final EscalaProvider escalaProvider;

  const _MonitorTempoReal({
    required this.cafeProvider,
    required this.colaboradorProvider,
    required this.caixaProvider,
    required this.escalaProvider,
  });

  @override
  Widget build(BuildContext context) {
    final pausasAtivas = cafeProvider.pausasAtivas;

    // Próximos intervalos (≤15 min) — apenas colaboradores ativos no turno
    final proximos = <_ProximoIntervalo>[];
    for (final turno in escalaProvider.turnosHoje) {
      if (turno.intervalo == null) continue;
      final parts = turno.intervalo!.split(':');
      if (parts.length < 2) continue;
      final agora = DateTime.now();
      final agoraMin = agora.hour * 60 + agora.minute;
      final intervaloMin =
          (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
      final diff = intervaloMin - agoraMin;
      if (diff >= 0 && diff <= 15) {
        final colab = colaboradorProvider.colaboradores
            .cast<dynamic>()
            .firstWhere((c) => c.id == turno.colaboradorId,
                orElse: () => null);
        if (colab != null) {
          proximos.add(_ProximoIntervalo(
            nome: colab.nome as String,
            minutosRestantes: diff,
            horario: turno.intervalo!,
          ));
        }
      }
    }

    final semAlertas =
        pausasAtivas.isEmpty && proximos.isEmpty;

    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.monitor_heart_outlined,
                    color: AppColors.primary, size: 18),
                SizedBox(width: 6),
                Text('Monitor em tempo real', style: AppTextStyles.h4),
              ],
            ),
            const SizedBox(height: 12),

            if (semAlertas)
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Tudo em ordem — nenhum alerta no momento',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.success),
                  ),
                ],
              )
            else ...[
              // Pausas ativas
              if (pausasAtivas.isNotEmpty) ...[
                Text(
                  'EM PAUSA',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                ...pausasAtivas.map((p) {
                  final caixa = p.caixaId != null
                      ? caixaProvider.caixas
                          .cast<dynamic>()
                          .firstWhere((c) => c.id == p.caixaId,
                              orElse: () => null)
                      : null;
                  final isCafe = p.duracaoMinutos <= 15;
                  final cor = p.emAtraso
                      ? AppColors.danger
                      : Colors.orange.shade700;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCafe ? Icons.coffee : Icons.restaurant,
                          color: cor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.colaboradorNome,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: cor,
                                ),
                              ),
                              Text(
                                caixa != null
                                    ? '${caixa.nomeExibicao} · ${p.minutosDecorridos}/${p.duracaoMinutos} min'
                                    : '${p.minutosDecorridos}/${p.duracaoMinutos} min',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (p.emAtraso)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+${p.minutosExcedidos}min',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              cafeProvider.finalizarPausa(p.colaboradorId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.success
                                      .withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'Retornou',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              // Próximos intervalos
              if (proximos.isNotEmpty) ...[
                if (pausasAtivas.isNotEmpty) const SizedBox(height: 10),
                Text(
                  'INTERVALO EM BREVE',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                ...proximos.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule,
                              color: Colors.orange.shade700, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p.nome,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                          Text(
                            'às ${p.horario} · em ${p.minutosRestantes} min',
                            style: AppTextStyles.caption.copyWith(
                                color: Colors.orange.shade700),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ProximoIntervalo {
  final String nome;
  final int minutosRestantes;
  final String horario;

  const _ProximoIntervalo({
    required this.nome,
    required this.minutosRestantes,
    required this.horario,
  });
}

// ── Helpers de layout ─────────────────────────────────────────────────────────

class _BotaoAcao {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback onPressed;

  const _BotaoAcao({
    required this.icon,
    required this.label,
    required this.color,
    this.badge,
    required this.onPressed,
  });
}

class _GridAcoes extends StatelessWidget {
  final List<_BotaoAcao> botoes;

  const _GridAcoes({required this.botoes});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < botoes.length; i += 2) {
      final a = botoes[i];
      final b = i + 1 < botoes.length ? botoes[i + 1] : null;
      rows.add(
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                icon: a.icon,
                label: a.label,
                color: a.color,
                badge: a.badge,
                onPressed: a.onPressed,
              ),
            ),
            const SizedBox(width: Dimensions.spacingSM),
            Expanded(
              child: b != null
                  ? QuickActionButton(
                      icon: b.icon,
                      label: b.label,
                      color: b.color,
                      badge: b.badge,
                      onPressed: b.onPressed,
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      );
      if (i + 2 < botoes.length) {
        rows.add(const SizedBox(height: Dimensions.spacingSM));
      }
    }
    return Column(children: rows);
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _AlertItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AlertItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _AlertCard extends StatelessWidget {
  final _AlertItem item;

  const _AlertCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: item.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: item.color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                    color: item.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: item.color, size: 13),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.h3.copyWith(color: color)),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.cardBorder,
    );
  }
}

// ── Banner de saúde do turno ──────────────────────────────────────────────────

class _BannerSaudeTurno extends StatelessWidget {
  final bool critico;
  final bool atencao;

  const _BannerSaudeTurno({
    required this.critico,
    required this.atencao,
  });

  @override
  Widget build(BuildContext context) {
    final Color cor;
    final IconData icone;
    final String titulo;
    final String subtitulo;

    if (critico) {
      cor = AppColors.danger;
      icone = Icons.error_outline;
      titulo = 'Turno com alertas críticos';
      subtitulo = 'Verifique pausas em atraso ou lembretes vencidos';
    } else if (atencao) {
      cor = AppColors.warning;
      icone = Icons.warning_amber_outlined;
      titulo = 'Turno requer atenção';
      subtitulo = 'Há ocorrências, entregas ou checklist pendentes';
    } else {
      cor = AppColors.success;
      icone = Icons.check_circle_outline;
      titulo = 'Tudo em ordem';
      subtitulo = 'Nenhum alerta ativo no momento';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingMD, vertical: Dimensions.paddingSM),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Dimensions.radiusMD),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor, size: 28),
          const SizedBox(width: Dimensions.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: AppTextStyles.caption
                      .copyWith(color: cor.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barra de ocupação dos caixas ─────────────────────────────────────────────

class _OcupacaoBar extends StatelessWidget {
  final int alocados;
  final int totalCaixas;
  final int emPausa;
  final int emRota;

  const _OcupacaoBar({
    required this.alocados,
    required this.totalCaixas,
    required this.emPausa,
    required this.emRota,
  });

  @override
  Widget build(BuildContext context) {
    final double progresso =
        totalCaixas > 0 ? (alocados / totalCaixas).clamp(0.0, 1.0) : 0.0;
    final int percentual = (progresso * 100).round();

    final Color corBarra = percentual >= 90
        ? AppColors.danger
        : percentual >= 60
            ? AppColors.warning
            : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$alocados de $totalCaixas caixas ocupados',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: corBarra.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: corBarra.withValues(alpha: 0.4)),
              ),
              child: Text(
                '$percentual%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: corBarra,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.spacingSM),
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusSM),
          child: LinearProgressIndicator(
            value: progresso,
            minHeight: 10,
            backgroundColor: AppColors.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(corBarra),
          ),
        ),
        const SizedBox(height: Dimensions.spacingMD),
        const Divider(height: 1),
        const SizedBox(height: Dimensions.spacingMD),
        Row(
          children: [
            Expanded(
              child: _buildStatRow(
                Icons.coffee_outlined,
                'Em Pausa',
                emPausa.toString(),
                const Color(0xFF8D6E63),
              ),
            ),
            const SizedBox(width: Dimensions.spacingMD),
            Expanded(
              child: _buildStatRow(
                Icons.local_shipping_outlined,
                'Em Rota',
                emRota.toString(),
                const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Botão Começar Turno ───────────────────────────────────────────────────────

class _ComecaTurnoButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ComecaTurnoButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.75),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(Dimensions.borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Começar Turno',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ver briefing do turno e iniciar',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Briefing de início de turno ───────────────────────────────────────────────

class _BriefingTurnoSheet extends StatelessWidget {
  final String fiscalId;

  const _BriefingTurnoSheet({required this.fiscalId});

  @override
  Widget build(BuildContext context) {
    final escalaProvider = Provider.of<EscalaProvider>(context, listen: false);
    final notaProvider = Provider.of<NotaProvider>(context, listen: false);

    final agora = DateTime.now();
    final horaFormatada =
        '${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}';

    final turnosHoje = escalaProvider.turnosHoje;
    final presentes =
        turnosHoje.where((t) => !t.folga && !t.feriado).toList();
    final defolga = turnosHoje.where((t) => t.folga || t.feriado).toList();
    final notasImportantes =
        notaProvider.notas.where((n) => n.importante && !n.concluida).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Briefing do Turno', style: AppTextStyles.h3),
                    Text(
                      'Início às $horaFormatada',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                controller: controller,
                children: [
                  // ── Colaboradores presentes ──────────────────────────────
                  _BriefingSection(
                    icon: Icons.people,
                    iconColor: AppColors.success,
                    collapsible: true,
                    title:
                        'Presentes hoje (${presentes.length})',
                    child: presentes.isEmpty
                        ? Text('Nenhum colaborador na escala de hoje',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary))
                        : Column(
                            children: presentes
                                .map((t) => _BriefingColabTile(
                                      nome: t.colaboradorNome,
                                      detalhe: t.entrada != null
                                          ? 'Entrada: ${t.entrada}'
                                          : t.departamento.toString(),
                                      cor: AppColors.success,
                                    ))
                                .toList(),
                          ),
                  ),

                  const SizedBox(height: 12),

                  // ── De folga ─────────────────────────────────────────────
                  _BriefingSection(
                    icon: Icons.beach_access,
                    iconColor: AppColors.textSecondary,
                    collapsible: true,
                    title: 'De folga / feriado (${defolga.length})',
                    child: defolga.isEmpty
                        ? Text('Nenhum colaborador de folga hoje',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary))
                        : Column(
                            children: defolga
                                .map((t) => _BriefingColabTile(
                                      nome: t.colaboradorNome,
                                      detalhe: t.feriado
                                          ? 'Feriado'
                                          : 'Folga',
                                      cor: AppColors.textSecondary,
                                    ))
                                .toList(),
                          ),
                  ),

                  const SizedBox(height: 12),

                  // ── Notas importantes ────────────────────────────────────
                  _BriefingSection(
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.orange,
                    title:
                        'Avisos importantes (${notasImportantes.length})',
                    child: notasImportantes.isEmpty
                        ? Text('Sem anotações importantes no momento',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary))
                        : Column(
                            children: notasImportantes
                                .map((n) => Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.orange
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                              Icons.priority_high,
                                              size: 14,
                                              color: Colors.orange),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              n.titulo,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ── Botões de ação ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const GestaoScreen(initialIndex: 0),
                      ));
                    },
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Ir para Alocar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _confirmarInicio(context, presentes, defolga, notasImportantes, horaFormatada),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Confirmar Início'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarInicio(
    BuildContext context,
    List<dynamic> presentes,
    List<dynamic> defolga,
    List<dynamic> notasImportantes,
    String horaFormatada,
  ) {
    final passagemProvider =
        Provider.of<PassagemTurnoProvider>(context, listen: false);
    final eventoProvider =
        Provider.of<EventoTurnoProvider>(context, listen: false);
    final authProvider =
        Provider.of<AuthProvider>(context, listen: false);
    final fiscalId = authProvider.user?.id ?? '';

    final resumo =
        'Início de turno às $horaFormatada\nPresentes: ${presentes.length} colaborador(es)';

    final pendencias = notasImportantes.isNotEmpty
        ? notasImportantes.map((n) => '• ${n.titulo}').join('\n')
        : 'Nenhuma pendência registrada';

    final recados = defolga.isNotEmpty
        ? 'De folga/feriado: ${defolga.map((t) => t.colaboradorNome).join(', ')}'
        : 'Nenhum colaborador de folga hoje';

    passagemProvider.registrar(
      resumo: resumo,
      pendencias: pendencias,
      recados: recados,
    );

    eventoProvider.registrar(
      fiscalId: fiscalId,
      tipo: TipoEvento.turnoIniciado,
      detalhe:
          '${presentes.length} presente(s). ${defolga.isNotEmpty ? recados : ''}',
    );

    Navigator.pop(context);

    AppNotif.show(
      context,
      titulo: 'Turno Iniciado',
      mensagem: 'Turno iniciado às $horaFormatada — registrado na timeline',
      tipo: 'saida',
      cor: AppColors.success,
      duracao: const Duration(seconds: 4),
      acao: SnackBarAction(
        label: 'Ver',
        textColor: Colors.white,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TimelineScreen()),
        ),
      ),
    );
  }
}

class _BriefingSection extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  final bool collapsible;

  const _BriefingSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.collapsible = false,
  });

  @override
  State<_BriefingSection> createState() => _BriefingSectionState();
}

class _BriefingSectionState extends State<_BriefingSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final showChild = !widget.collapsible || _expanded;
    return Card(
      child: InkWell(
        onTap: widget.collapsible
            ? () => setState(() => _expanded = !_expanded)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.icon, color: widget.iconColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.title,
                        style: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.bold,
                            color: widget.iconColor)),
                  ),
                  if (widget.collapsible)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: widget.iconColor,
                      size: 18,
                    ),
                ],
              ),
              if (showChild) ...[
                const SizedBox(height: 10),
                widget.child,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BriefingColabTile extends StatelessWidget {
  final String nome;
  final String detalhe;
  final Color cor;

  const _BriefingColabTile({
    required this.nome,
    required this.detalhe,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: cor.withValues(alpha: 0.12),
            child: Text(
              nome.isNotEmpty ? nome[0].toUpperCase() : '?',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: cor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(detalhe,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
