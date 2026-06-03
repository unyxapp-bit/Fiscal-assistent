import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/theme/app_theme.dart';
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
import '../pizzaria/pizza_module_screen.dart';
// profile_screen.dart usado via ConfiguracoesScreen
import '../configuracoes/configuracoes_screen.dart';
import '../balcao/fiscal_events_screen.dart';
import '../ai/fiscal_ai_screen.dart';
import '../../providers/fiscal_events_provider.dart';
import '../cartazes/cartazes_home_page.dart';
import '../descontos/desconto_calculator_screen.dart';
import '../../../data/services/seed_data_service.dart';
import '../../widgets/common/operational_widgets.dart';
import 'dashboard_v2_layout.dart';
import 'widgets/briefing_turno_sheet.dart';
import 'widgets/monitor_tempo_real.dart';

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
    _tabController = TabController(length: 8, vsync: this);
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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => BriefingTurnoSheet(fiscalId: fiscalId),
    );
  }

  Future<void> _abrirDestinoBannerSaude(
    BuildContext context,
    List<_BannerSaudeDestino> destinos,
  ) async {
    if (destinos.isEmpty) return;

    if (destinos.length == 1) {
      destinos.first.onTap();
      return;
    }

    final destinoSelecionado = await showModalBottomSheet<_BannerSaudeDestino>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: Dimensions.paddingMD),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Escolha o alerta para abrir',
                  style: AppTextStyles.h4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...destinos.map(
              (d) => ListTile(
                leading: Icon(d.icon, color: d.color),
                title: Text(d.label),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => Navigator.pop(ctx, d),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || destinoSelecionado == null) return;
    destinoSelecionado.onTap();
  }

  Future<void> _loadData({bool refreshSharedData = false}) async {
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
          .loadColaboradores(userId, forceRefresh: refreshSharedData),
      Provider.of<CaixaProvider>(context, listen: false).loadCaixas(userId),
      Provider.of<AlocacaoProvider>(context, listen: false)
          .loadAlocacoes(userId),
      Provider.of<EventoTurnoProvider>(context, listen: false).load(userId),
      if (refreshSharedData) ...[
        Provider.of<CafeProvider>(context, listen: false).load(),
        Provider.of<EntregaProvider>(context, listen: false).load(),
        Provider.of<EscalaProvider>(context, listen: false).load(),
        Provider.of<NotaProvider>(context, listen: false).load(),
        Provider.of<FormularioProvider>(context, listen: false).load(),
        Provider.of<ProcedimentoProvider>(context, listen: false).load(),
        Provider.of<OcorrenciaProvider>(context, listen: false).load(),
        Provider.of<ChecklistProvider>(context, listen: false).load(),
        Provider.of<PassagemTurnoProvider>(context, listen: false).load(),
      ],
    ]);

    if (mounted) {
      Provider.of<AlocacaoProvider>(context, listen: false)
          .watchAlocacoes(userId);
    }
  }

  Future<void> _refreshData() => _loadData(refreshSharedData: true);

  void _switchToTab(int index) {
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
  }

  Future<void> _openScreen(Widget screen) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _showMobileMoreMenu() async {
    final sections = [
      _MobileMoreSection(
        title: 'M\u00f3dulos',
        actions: [
          _MobileMoreAction(
            label: 'Loja',
            icon: Icons.store_rounded,
            color: AppColors.warning,
            onTap: () => _switchToTab(3),
          ),
          _MobileMoreAction(
            label: 'Cartaz',
            icon: Icons.local_offer_rounded,
            color: const Color(0xFFD6166A),
            onTap: () => _switchToTab(4),
          ),
          _MobileMoreAction(
            label: 'Descontos',
            icon: Icons.percent_rounded,
            color: AppColors.success,
            onTap: () => _switchToTab(5),
          ),
          _MobileMoreAction(
            label: 'Balc\u00e3o',
            icon: Icons.campaign_rounded,
            color: AppColors.info,
            onTap: () => _switchToTab(6),
          ),
          _MobileMoreAction(
            label: 'IA Fiscal',
            icon: Icons.auto_awesome_rounded,
            color: AppColors.deepPurple,
            onTap: () => _switchToTab(7),
          ),
        ],
      ),
      _MobileMoreSection(
        title: 'Opera\u00e7\u00e3o',
        actions: [
          _MobileMoreAction(
            label: 'Central',
            icon: Icons.dashboard_customize_rounded,
            color: AppColors.primary,
            onTap: () => _openScreen(
              const GestaoScreen(initialIndex: GestaoScreen.centralIndex),
            ),
          ),
          _MobileMoreAction(
            label: 'Aloca\u00e7\u00e3o',
            icon: Icons.swap_horiz_rounded,
            color: AppColors.primary,
            onTap: () => _openScreen(const GestaoScreen(initialIndex: 0)),
          ),
          _MobileMoreAction(
            label: 'Caf\u00e9',
            icon: Icons.restaurant_rounded,
            color: AppColors.statusCafe,
            onTap: () => _openScreen(const GestaoScreen(initialIndex: 2)),
          ),
          _MobileMoreAction(
            label: 'Gargalo',
            icon: Icons.insights_rounded,
            color: AppColors.statusAtencao,
            onTap: () => _openScreen(const GestaoScreen(initialIndex: 3)),
          ),
          _MobileMoreAction(
            label: 'Colaboradores',
            icon: Icons.groups_2_rounded,
            color: AppColors.success,
            onTap: () => _openScreen(const ColaboradoresListScreen()),
          ),
          _MobileMoreAction(
            label: 'Entregas',
            icon: Icons.local_shipping_rounded,
            color: AppColors.primary,
            onTap: () => _openScreen(const EntregasScreen()),
          ),
          _MobileMoreAction(
            label: 'Ocorr\u00eancias',
            icon: Icons.warning_amber_rounded,
            color: AppColors.danger,
            onTap: () => _openScreen(const OcorrenciasScreen()),
          ),
          _MobileMoreAction(
            label: 'Checklists',
            icon: Icons.fact_check_rounded,
            color: AppColors.warning,
            onTap: () => _openScreen(const ChecklistScreen()),
          ),
          _MobileMoreAction(
            label: 'Passagem',
            icon: Icons.sync_alt_rounded,
            color: AppColors.primary,
            onTap: () => _openScreen(const PassagemTurnoScreen()),
          ),
        ],
      ),
      _MobileMoreSection(
        title: 'Apoio',
        actions: [
          _MobileMoreAction(
            label: 'Guia r\u00e1pido',
            icon: Icons.help_outline_rounded,
            color: AppColors.blueGrey,
            onTap: () => _openScreen(const GuiaRapidoScreen()),
          ),
          _MobileMoreAction(
            label: 'Anota\u00e7\u00f5es',
            icon: Icons.note_alt_rounded,
            color: AppColors.statusSaida,
            onTap: () => _openScreen(const NotasScreen()),
          ),
          _MobileMoreAction(
            label: 'Formul\u00e1rios',
            icon: Icons.description_rounded,
            color: AppColors.indigo,
            onTap: () => _openScreen(const FormulariosScreen()),
          ),
          _MobileMoreAction(
            label: 'Procedimentos',
            icon: Icons.menu_book_rounded,
            color: AppColors.deepPurple,
            onTap: () => _openScreen(const ProcedimentosScreen()),
          ),
          _MobileMoreAction(
            label: 'Notifica\u00e7\u00f5es',
            icon: Icons.notifications_none_rounded,
            color: AppColors.primary,
            onTap: () => _openScreen(const NotificacoesScreen()),
          ),
          _MobileMoreAction(
            label: 'Relat\u00f3rio',
            icon: Icons.assessment_rounded,
            color: AppColors.info,
            onTap: () => _openScreen(const RelatorioDiarioScreen()),
          ),
          _MobileMoreAction(
            label: 'Escala',
            icon: Icons.calendar_month_rounded,
            color: AppColors.primary,
            onTap: () => _openScreen(const EscalaScreen()),
          ),
          _MobileMoreAction(
            label: 'Folgas',
            icon: Icons.event_busy_rounded,
            color: AppColors.warning,
            onTap: () => _openScreen(const FolgaScreen()),
          ),
          _MobileMoreAction(
            label: 'Config.',
            icon: Icons.settings_rounded,
            color: AppColors.textSecondary,
            onTap: () => _openScreen(const ConfiguracoesScreen()),
          ),
        ],
      ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        void closeAndRun(VoidCallback action) {
          Navigator.of(sheetContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) => action());
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mais atalhos', style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  Text(
                    'Acesso r\u00e1pido \u00e0s telas que n\u00e3o cabem na barra inferior.',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  for (final section in sections) ...[
                    Text(section.title, style: AppTextStyles.h4),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: section.actions.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.16,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final action = section.actions[index];
                        return _MobileMoreActionCard(
                          action: action,
                          onTap: () => closeAndRun(action.onTap),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
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
    final passagemTurnoProvider = Provider.of<PassagemTurnoProvider>(context);
    final eventoProvider = Provider.of<EventoTurnoProvider>(context);
    final turnoJaIniciado = eventoProvider.turnoIniciadoEm != null;
    final fiscalEventsProvider = Provider.of<FiscalEventsProvider>(context);
    final navItems = [
      const _DashboardNavItem(
        label: 'In\u00edcio',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
      ),
      const _DashboardNavItem(
        label: 'Pizzaria',
        icon: Icons.local_pizza_outlined,
        selectedIcon: Icons.local_pizza,
      ),
      _DashboardNavItem(
        label: 'Opera\u00e7\u00f5es',
        icon: Icons.build_outlined,
        selectedIcon: Icons.build,
        badgeCount: cafeProvider.totalEmAtraso,
      ),
      const _DashboardNavItem(
        label: 'Loja',
        icon: Icons.store_outlined,
        selectedIcon: Icons.store,
      ),
      const _DashboardNavItem(
        label: 'Cartaz',
        icon: Icons.local_offer_outlined,
        selectedIcon: Icons.local_offer_rounded,
      ),
      const _DashboardNavItem(
        label: 'Descontos',
        icon: Icons.percent_outlined,
        selectedIcon: Icons.percent_rounded,
      ),
      _DashboardNavItem(
        label: 'Balc\u00e3o',
        icon: Icons.campaign_outlined,
        selectedIcon: Icons.campaign,
        badgeCount: fiscalEventsProvider.totalPendentes,
        showBadgeCount: true,
      ),
      const _DashboardNavItem(
        label: 'IA Fiscal',
        icon: Icons.auto_awesome_outlined,
        selectedIcon: Icons.auto_awesome_rounded,
      ),
    ];

    final saudacao = _getSaudacao();
    final nome = fiscalProvider.fiscal?.nome ??
        authProvider.user?.email ??
        'Usu\u00e1rio';
    final primeiroNome = nome.split(' ').first;

    final totalAtivos = colaboradorProvider.totalAtivos;
    final totalCaixas = caixaProvider.totalAtivos;
    final alocados = alocacaoProvider.quantidadeAtivasAgora;
    final livres = (totalCaixas - alocados).clamp(0, 999);
    final emPausa = cafeProvider.totalAtivos;
    final emRota = entregaProvider.totalEmRota;
    final destinosBannerSaude = <_BannerSaudeDestino>[
      if (cafeProvider.totalEmAtraso > 0)
        _BannerSaudeDestino(
          icon: Icons.coffee,
          color: AppColors.danger,
          label: 'Pausas em atraso (${cafeProvider.totalEmAtraso})',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const GestaoScreen(initialIndex: 2),
            ),
          ),
        ),
      if (notaProvider.totalLembretesVencidos > 0)
        _BannerSaudeDestino(
          icon: Icons.alarm_off,
          color: AppColors.danger,
          label: 'Lembretes vencidos (${notaProvider.totalLembretesVencidos})',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotasScreen()),
          ),
        ),
      if (ocorrenciaProvider.totalAbertas > 0)
        _BannerSaudeDestino(
          icon: Icons.report_problem,
          color: AppColors.statusAtencao,
          label:
              'Ocorr\u00eancias abertas (${ocorrenciaProvider.totalAbertas})',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OcorrenciasScreen()),
          ),
        ),
      if (entregaProvider.totalSeparadas > 0)
        _BannerSaudeDestino(
          icon: Icons.inventory,
          color: AppColors.statusAtencao,
          label:
              'Entregas aguardando envio (${entregaProvider.totalSeparadas})',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EntregasScreen()),
          ),
        ),
      if (checklistProvider.templatesPendentesAgora.isNotEmpty)
        _BannerSaudeDestino(
          icon: Icons.checklist,
          color: AppColors.primary,
          label:
              'Checklist pendente (${checklistProvider.templatesPendentesAgora.length})',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChecklistScreen()),
          ),
        ),
    ];
    final VoidCallback? onTapBannerSaude = destinosBannerSaude.isNotEmpty
        ? () => _abrirDestinoBannerSaude(context, destinosBannerSaude)
        : null;
    final turnoCritico = cafeProvider.totalEmAtraso > 0 ||
        notaProvider.totalLembretesVencidos > 0;
    final turnoEmAtencao = ocorrenciaProvider.totalAbertas > 0 ||
        entregaProvider.totalSeparadas > 0 ||
        checklistProvider.templatesPendentesAgora.isNotEmpty;

    final alertas = <_AlertItem>[
      if (cafeProvider.totalEmAtraso > 0)
        _AlertItem(
          icon: Icons.coffee,
          label:
              '${cafeProvider.totalEmAtraso} pausa${cafeProvider.totalEmAtraso > 1 ? 's' : ''} em atraso',
          color: AppColors.danger,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const GestaoScreen(initialIndex: 2))),
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
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const NotasScreen())),
        ),
      if (ocorrenciaProvider.totalAbertas > 0)
        _AlertItem(
          icon: Icons.report_problem,
          label:
              '${ocorrenciaProvider.totalAbertas} ocorr\u00eancia${ocorrenciaProvider.totalAbertas > 1 ? 's abertas' : ' aberta'}',
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

    // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Tabs compartilhadas entre phone e tablet ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
    final operationalMetrics = <OperationalMetricData>[
      OperationalMetricData(
        label: 'Colaboradores',
        value: totalAtivos.toString(),
        helper: 'Ativos hoje',
        icon: Icons.people_alt_outlined,
        color: AppColors.primary,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ColaboradoresListScreen()),
        ),
      ),
      OperationalMetricData(
        label: 'Caixas ativos',
        value: totalCaixas.toString(),
        helper: '$livres livres',
        icon: Icons.point_of_sale_outlined,
        color: AppColors.success,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const GestaoScreen(initialIndex: 1)),
        ),
      ),
      OperationalMetricData(
        label: 'Alocados agora',
        value: alocados.toString(),
        helper: 'Em operacao',
        icon: Icons.swap_horiz_rounded,
        color: AppColors.statusAtivo,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const GestaoScreen(initialIndex: 0)),
        ),
      ),
      OperationalMetricData(
        label: 'Em pausa',
        value: emPausa.toString(),
        helper: cafeProvider.totalEmAtraso > 0
            ? '${cafeProvider.totalEmAtraso} atraso(s)'
            : 'Dentro do prazo',
        icon: Icons.coffee_outlined,
        color: cafeProvider.totalEmAtraso > 0
            ? AppColors.danger
            : AppColors.coffee,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const GestaoScreen(initialIndex: 2)),
        ),
      ),
      OperationalMetricData(
        label: 'Em rota',
        value: emRota.toString(),
        helper: '${entregaProvider.totalSeparadas} aguardando',
        icon: Icons.local_shipping_outlined,
        color: AppColors.statusCafe,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EntregasScreen()),
        ),
      ),
      OperationalMetricData(
        label: 'Alertas',
        value: alertas.length.toString(),
        helper: turnoCritico
            ? 'Criticos'
            : turnoEmAtencao
                ? 'Atencao'
                : 'Estavel',
        icon: Icons.notification_important_outlined,
        color: turnoCritico
            ? AppColors.danger
            : turnoEmAtencao
                ? AppColors.warning
                : AppColors.success,
        onTap: onTapBannerSaude,
      ),
    ];

    void abrirTurnoOuTimeline() {
      if (!turnoJaIniciado) {
        _abrirBriefingTurno(
          context,
          authProvider.user?.id ?? '',
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const TimelineScreen(),
        ),
      );
    }

    int countEventoTermo(String termo) {
      return eventoProvider.eventos.where((e) {
        final alvo =
            '${e.tipo.valor} ${e.tipo.label} ${e.detalhe ?? ''}'.toLowerCase();
        return alvo.contains(termo);
      }).length;
    }

    final caixasOperacionais = [
      ...(caixaProvider.caixasTodos.isNotEmpty
          ? caixaProvider.caixasTodos
          : caixaProvider.caixas),
    ]..sort((a, b) => a.numero.compareTo(b.numero));
    final pausasRegistradas = eventoProvider.eventos.where((e) {
      final tipo = e.tipo.valor;
      return tipo.contains('cafe') || tipo.contains('intervalo');
    }).length;
    final dashboardV2NavItems = [
      for (final item in navItems)
        DashboardV2NavItem(
          label: item.label,
          icon: item.icon,
          selectedIcon: item.selectedIcon,
          badgeCount: item.badgeCount,
          showBadgeCount: item.showBadgeCount,
        ),
    ];
    final dashboardV2QuickActions = <DashboardV2QuickAction>[
      DashboardV2QuickAction(
        icon: Icons.point_of_sale_outlined,
        title: 'Caixas',
        subtitle: 'Gerenciar caixas',
        color: AppColors.primary,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                const GestaoScreen(initialIndex: GestaoScreen.centralIndex),
          ),
        ),
      ),
      DashboardV2QuickAction(
        icon: Icons.groups_2_outlined,
        title: 'Colaboradores',
        subtitle: 'Ver equipe',
        color: AppColors.success,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ColaboradoresListScreen()),
        ),
      ),
      DashboardV2QuickAction(
        icon: Icons.emoji_events_outlined,
        title: 'Pausas e rotas',
        subtitle: 'Acompanhar',
        color: AppColors.statusCafe,
        badge: cafeProvider.totalEmAtraso > 0
            ? cafeProvider.totalEmAtraso.toString()
            : null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const GestaoScreen(initialIndex: 2)),
        ),
      ),
      DashboardV2QuickAction(
        icon: Icons.shield_outlined,
        title: 'Ocorr\u00eancias',
        subtitle: 'Registrar e acompanhar',
        color: AppColors.danger,
        badge: ocorrenciaProvider.totalAbertas > 0
            ? ocorrenciaProvider.totalAbertas.toString()
            : null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OcorrenciasScreen()),
        ),
      ),
      DashboardV2QuickAction(
        icon: Icons.local_shipping_outlined,
        title: 'Entregas',
        subtitle: 'Gerenciar entregas',
        color: AppColors.success,
        badge: entregaProvider.totalSeparadas + entregaProvider.totalEmRota > 0
            ? (entregaProvider.totalSeparadas + entregaProvider.totalEmRota)
                .toString()
            : null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EntregasScreen()),
        ),
      ),
      DashboardV2QuickAction(
        icon: Icons.check_circle_outline_rounded,
        title: 'Checklists',
        subtitle: 'Ver pend\u00eancias',
        color: AppColors.success,
        badge: checklistProvider.templatesPendentesAgora.isNotEmpty
            ? checklistProvider.templatesPendentesAgora.length.toString()
            : null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChecklistScreen()),
        ),
      ),
      DashboardV2QuickAction(
        icon: Icons.local_offer_outlined,
        title: 'Cartaz',
        subtitle: 'Criar ofertas',
        color: const Color(0xFFD6166A),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CartazesHomePage()),
        ),
      ),
      DashboardV2QuickAction(
        icon: Icons.auto_awesome_rounded,
        title: 'IA Fiscal',
        subtitle: 'Perguntar e agir',
        color: AppColors.deepPurple,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FiscalAiScreen()),
        ),
      ),
    ];
    final dashboardV2ReportItems = <DashboardV2ReportItem>[
      DashboardV2ReportItem(
        icon: Icons.swap_horiz_rounded,
        label: 'Movimenta\u00e7\u00f5es',
        value: eventoProvider.eventos.length.toString(),
      ),
      DashboardV2ReportItem(
        icon: Icons.water_drop_outlined,
        label: 'Sangrias',
        value: countEventoTermo('sangria').toString(),
      ),
      DashboardV2ReportItem(
        icon: Icons.inventory_2_outlined,
        label: 'Suprimentos',
        value: countEventoTermo('suprimento').toString(),
      ),
      DashboardV2ReportItem(
        icon: Icons.shield_outlined,
        label: 'Ocorr\u00eancias',
        value: ocorrenciaProvider.totalAbertas.toString(),
        color: ocorrenciaProvider.totalAbertas > 0
            ? AppColors.danger
            : AppColors.textPrimary,
      ),
      DashboardV2ReportItem(
        icon: Icons.emoji_events_outlined,
        label: 'Pausas',
        value: pausasRegistradas.toString(),
      ),
      DashboardV2ReportItem(
        icon: Icons.local_shipping_outlined,
        label: 'Entregas',
        value: (entregaProvider.totalSeparadas + entregaProvider.totalEmRota)
            .toString(),
      ),
    ];
    final dashboardV2Home = DashboardV2Home(
      saudacao: saudacao,
      primeiroNome: primeiroNome,
      turnoJaIniciado: turnoJaIniciado,
      turnoIniciadoEm: eventoProvider.turnoIniciadoEm,
      turnoCritico: turnoCritico,
      turnoEmAtencao: turnoEmAtencao,
      totalAtivos: totalAtivos,
      totalCaixas: totalCaixas,
      alocados: alocados,
      livres: livres,
      emPausa: emPausa,
      emRota: emRota,
      alertas: alertas.length,
      metrics: operationalMetrics,
      caixas: caixasOperacionais,
      quickActions: dashboardV2QuickActions,
      reportItems: dashboardV2ReportItems,
      onPrimaryAction: abrirTurnoOuTimeline,
      onAlertTap: onTapBannerSaude,
      onReportTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RelatorioDiarioScreen()),
      ),
      onPizzariaTap: () => _switchToTab(1),
      onOperacoesTap: () => _switchToTab(2),
      onCaixasTap: () => _openScreen(
        const GestaoScreen(initialIndex: GestaoScreen.centralIndex),
      ),
      onCartazTap: () => _switchToTab(4),
      onDescontoTap: () => _switchToTab(5),
      onBalcaoTap: () => _switchToTab(6),
      onAiTap: () => _switchToTab(7),
      onRefresh: _refreshData,
    );

    final entregasAbertas =
        entregaProvider.totalSeparadas + entregaProvider.totalEmRota;
    final checklistsPendentes =
        checklistProvider.templatesPendentesAgora.length;
    final notasPendentes = notaProvider.totalTarefasPendentes;
    final passagensHoje = passagemTurnoProvider.historicoHoje.length;
    final recentOperationsActivities =
        eventoProvider.eventos.reversed.take(3).map((evento) {
      final details = <String>[
        if ((evento.colaboradorNome ?? '').trim().isNotEmpty)
          evento.colaboradorNome!.trim(),
        if ((evento.caixaNome ?? '').trim().isNotEmpty)
          evento.caixaNome!.trim(),
        if ((evento.detalhe ?? '').trim().isNotEmpty) evento.detalhe!.trim(),
      ];

      return _OperationsRecentActivityItem(
        icon: _operationsActivityIcon(evento.tipo.valor),
        title: evento.tipo.label,
        subtitle: details.isEmpty ? 'Turno de hoje' : details.join(' - '),
        time: _formatOperationsTime(evento.timestamp),
        color: _operationsActivityColor(evento.tipo.valor),
      );
    }).toList();
    final operacoesDashboardV2 = _OperationsDashboardV2(
      saudacao: saudacao,
      primeiroNome: primeiroNome,
      alertCount: alertas.length,
      onRefresh: _refreshData,
      summaryItems: [
        _OperationsSummaryItem(
          icon: Icons.local_shipping_outlined,
          value: entregasAbertas.toString(),
          title: 'Entregas',
          subtitle: entregaProvider.totalEmRota > 0
              ? '${entregaProvider.totalEmRota} em rota'
              : 'Abertas agora',
          color: AppColors.primary,
          highlighted: entregasAbertas > 0,
        ),
        _OperationsSummaryItem(
          icon: Icons.warning_amber_rounded,
          value: ocorrenciaProvider.totalAbertas.toString(),
          title: 'Ocorr\u00eancias',
          subtitle: 'Abertas agora',
          color: AppColors.danger,
          highlighted: ocorrenciaProvider.totalAbertas > 0,
        ),
        _OperationsSummaryItem(
          icon: Icons.fact_check_outlined,
          value: checklistsPendentes.toString(),
          title: 'Checklists',
          subtitle: 'Pendentes',
          color: AppColors.warning,
          highlighted: checklistsPendentes > 0,
        ),
        _OperationsSummaryItem(
          icon: Icons.edit_note_rounded,
          value: notaProvider.totalNotas.toString(),
          title: 'Notas',
          subtitle: notasPendentes > 0
              ? _pluralize(
                  notasPendentes, 'tarefa pendente', 'tarefas pendentes')
              : 'Registradas',
          color: AppColors.indigo,
          highlighted: notasPendentes > 0,
        ),
      ],
      priorityActions: [
        _OperationsActionItem(
          icon: Icons.local_shipping_outlined,
          title: 'Entregas',
          subtitle: 'Gerencie e acompanhe entregas em aberto',
          badge: entregasAbertas > 0
              ? _pluralize(entregasAbertas, 'aberta', 'abertas')
              : 'Tudo certo',
          color: AppColors.primary,
          highlighted: entregasAbertas > 0,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EntregasScreen()),
          ),
        ),
        _OperationsActionItem(
          icon: Icons.warning_amber_rounded,
          title: 'Ocorr\u00eancias',
          subtitle: 'Registre e acompanhe ocorr\u00eancias da loja',
          badge: ocorrenciaProvider.totalAbertas > 0
              ? _pluralize(
                  ocorrenciaProvider.totalAbertas,
                  'aberta',
                  'abertas',
                )
              : 'Tudo certo',
          color: AppColors.danger,
          highlighted: ocorrenciaProvider.totalAbertas > 0,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OcorrenciasScreen()),
          ),
        ),
        _OperationsActionItem(
          icon: Icons.fact_check_outlined,
          title: 'Checklist',
          subtitle: 'Verifique e conclua pend\u00eancias do turno',
          badge: checklistsPendentes > 0
              ? _pluralize(checklistsPendentes, 'pendente', 'pendentes')
              : 'Tudo certo',
          color: AppColors.warning,
          highlighted: checklistsPendentes > 0,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChecklistScreen()),
          ),
        ),
        _OperationsActionItem(
          icon: Icons.sync_alt_rounded,
          title: 'Passagem Turno',
          subtitle: 'Registre recados, pend\u00eancias e contexto',
          badge: passagensHoje > 0
              ? _pluralize(passagensHoje, 'registro hoje', 'registros hoje')
              : 'Sem registro',
          color: AppColors.primary,
          highlighted: passagensHoje == 0,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PassagemTurnoScreen()),
          ),
        ),
      ],
      supportActions: [
        _OperationsActionItem(
          icon: Icons.percent_rounded,
          title: 'Descontos',
          subtitle: 'Calcule descontos rapidamente',
          color: AppColors.success,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DescontoCalculatorScreen(),
            ),
          ),
        ),
        _OperationsActionItem(
          icon: Icons.help_outline_rounded,
          title: 'Guia R\u00e1pido',
          subtitle: 'Consulte orienta\u00e7\u00f5es e d\u00favidas frequentes',
          color: AppColors.blueGrey,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GuiaRapidoScreen()),
          ),
        ),
        _OperationsActionItem(
          icon: Icons.note_alt_outlined,
          title: 'Anota\u00e7\u00f5es',
          subtitle: 'Crie e acompanhe notas r\u00e1pidas',
          badge: notasPendentes > 0 ? notasPendentes.toString() : null,
          color: AppColors.statusSaida,
          highlighted: notasPendentes > 0,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotasScreen()),
          ),
        ),
        _OperationsActionItem(
          icon: Icons.description_outlined,
          title: 'Formul\u00e1rios',
          subtitle: 'Acesse modelos e documentos',
          color: AppColors.indigo,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FormulariosScreen()),
          ),
        ),
        _OperationsActionItem(
          icon: Icons.menu_book_outlined,
          title: 'Procedimentos',
          subtitle: 'Consulte POPs e rotinas padr\u00e3o',
          color: AppColors.deepPurple,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProcedimentosScreen()),
          ),
        ),
        _OperationsActionItem(
          icon: Icons.notifications_none_rounded,
          title: 'Notifica\u00e7\u00f5es',
          subtitle: 'Veja comunicados e alertas',
          badge: alertas.isNotEmpty ? alertas.length.toString() : null,
          color: AppColors.primary,
          highlighted: alertas.isNotEmpty,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificacoesScreen()),
          ),
        ),
      ],
      recentActivities: recentOperationsActivities,
    );

    final tabBarView = TabBarView(
      controller: _tabController,
      children: [
        // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ABA 1: INÃƒÆ’Ã‚ÂCIO ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
        LayoutBuilder(
            builder: (context, constraints) => RefreshIndicator(
                  onRefresh: _refreshData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          _inicioHorizontalPadding(constraints.maxWidth),
                      vertical: Dimensions.paddingMD,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InicioHeroCard(
                          saudacao: saudacao,
                          primeiroNome: primeiroNome,
                          turnoJaIniciado: turnoJaIniciado,
                          totalAtivos: totalAtivos,
                          totalCaixas: totalCaixas,
                          alocados: alocados,
                          livres: livres,
                          emPausa: emPausa,
                          emRota: emRota,
                          alertas: alertas.length,
                          onPrimaryAction: () {
                            if (!turnoJaIniciado) {
                              _abrirBriefingTurno(
                                context,
                                authProvider.user?.id ?? '',
                              );
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TimelineScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: Dimensions.spacingMD),
                        _BannerSaudeTurno(
                          critico: turnoCritico,
                          atencao: turnoEmAtencao,
                          onTap: onTapBannerSaude,
                        ),
                        const SizedBox(height: Dimensions.spacingMD),
                        const OperationalSectionHeader(
                          icon: Icons.insights_rounded,
                          title: 'Indicadores do turno',
                        ),
                        const SizedBox(height: Dimensions.spacingSM),
                        OperationalMetricGrid(metrics: operationalMetrics),
                        const SizedBox(height: Dimensions.spacingMD),

                        // BotÃƒÆ’Ã‚Â£o ComeÃƒÆ’Ã‚Â§ar Turno ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â oculto apÃƒÆ’Ã‚Â³s confirmar inÃƒÆ’Ã‚Â­cio
                        const OperationalSectionHeader(
                          icon: Icons.monitor_heart_outlined,
                          title: 'Monitor operacional',
                        ),
                        const SizedBox(height: Dimensions.spacingSM),
                        MonitorTempoReal(
                          cafeProvider: cafeProvider,
                          colaboradorProvider: colaboradorProvider,
                          caixaProvider: caixaProvider,
                          escalaProvider: escalaProvider,
                        ),
                        const SizedBox(height: Dimensions.spacingMD),
                        const OperationalSectionHeader(
                          icon: Icons.grid_view_rounded,
                          title: 'Rotinas principais',
                        ),
                        const SizedBox(height: Dimensions.spacingSM),
                        _GridAcoes(
                          wideGrid: true,
                          botoes: [
                            _BotaoAcao(
                              icon: Icons.point_of_sale,
                              label: 'Caixas',
                              color: AppColors.primary,
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const GestaoScreen(
                                    initialIndex: GestaoScreen.centralIndex,
                                  ),
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
                                      const ColaboradoresListScreen(),
                                ),
                              ),
                            ),
                            _BotaoAcao(
                              icon: Icons.bar_chart,
                              label: 'Relat\u00f3rio',
                              color: AppColors.cyan,
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RelatorioDiarioScreen(),
                                ),
                              ),
                            ),
                            _BotaoAcao(
                              icon: Icons.auto_awesome_rounded,
                              label: 'IA Fiscal',
                              color: AppColors.deepPurple,
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const FiscalAiScreen(),
                                ),
                              ),
                            ),
                            _BotaoAcao(
                              icon: Icons.calendar_month,
                              label: 'Escala',
                              color: AppColors.pink,
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EscalaScreen(),
                                ),
                              ),
                            ),
                            _BotaoAcao(
                              icon: Icons.local_offer_rounded,
                              label: 'Cartazes',
                              color: const Color(0xFFD6166A),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CartazesHomePage(),
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (alertas.isNotEmpty) ...[
                          const SizedBox(height: Dimensions.spacingLG),
                          const OperationalSectionHeader(
                            icon: Icons.notification_important_outlined,
                            title: 'Alertas do turno',
                          ),
                          const SizedBox(height: Dimensions.spacingSM),
                          ...alertas.map((a) => _AlertCard(item: a)),
                        ],
                        const SizedBox(height: Dimensions.spacingXL),
                      ],
                    ),
                  ),
                )),

        // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ABA 3: PIZZARIA ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
        const PizzaModuleScreen(),

        // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ABA 4: OPERAÃƒÆ’Ã¢â‚¬Â¡ÃƒÆ’Ã¢â‚¬Â¢ES ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
        operacoesDashboardV2,

        // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ ABA 5: LOJA ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
        RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Dimensions.paddingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OperationalSectionHeader(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Sa\u00fade do turno',
                ),
                const SizedBox(height: Dimensions.spacingSM),
                _BannerSaudeTurno(
                  critico: turnoCritico,
                  atencao: turnoEmAtencao,
                  onTap: onTapBannerSaude,
                ),
                const SizedBox(height: Dimensions.spacingMD),
                if (fiscalProvider.fiscal != null) ...[
                  const OperationalSectionHeader(
                    icon: Icons.query_stats_rounded,
                    title: 'Ocupa\u00e7\u00e3o do turno',
                  ),
                  const SizedBox(height: Dimensions.spacingSM),
                  Container(
                    decoration: AppStyles.softCard(
                      context: context,
                      tint: AppColors.primary,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingMD),
                      child: _OcupacaoBar(
                        alocados: alocados,
                        totalCaixas: totalCaixas,
                        emPausa: emPausa,
                        emRota: emRota,
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
                const SizedBox(height: Dimensions.spacingLG),
                const OperationalSectionHeader(
                  icon: Icons.build_outlined,
                  title: 'Ferramentas r\u00e1pidas',
                ),
                const SizedBox(height: Dimensions.spacingSM),
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
                        MaterialPageRoute(builder: (_) => const FolgaScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.spacingXL),
              ],
            ),
          ),
        ),

        // â”€â”€ ABA 5: BALCÃƒO FISCAL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        const CartazesHomePage(),
        const DescontoCalculatorScreen(),
        const FiscalEventsScreen(),
        const FiscalAiScreen(),
      ],
    );

    //ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Layout adaptativo ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= Dimensions.breakpointTablet;
        final isWide = constraints.maxWidth >= Dimensions.breakpointWide;

        if (isTablet) {
          return DashboardV2Shell(
            navItems: dashboardV2NavItems,
            selectedIndex: _tabController.index,
            onDestinationSelected: (i) => _tabController.animateTo(i),
            userName: primeiroNome,
            userRole: 'Fiscal de Caixa',
            alertCount: alertas.length,
            onSettings: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConfiguracoesScreen()),
            ),
            onSignOut: () => authProvider.signOut(),
            child: _tabController.index == 0 ? dashboardV2Home : tabBarView,
          );
        }

        // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ TABLET: NavigationRail + TabBarView ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
        if (isTablet) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _tabController.index,
                  onDestinationSelected: (i) => _tabController.animateTo(i),
                  extended: isWide,
                  minWidth: 76,
                  minExtendedWidth: 220,
                  groupAlignment: -0.86,
                  labelType: isWide
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  backgroundColor: AppColors.cardBackground,
                  indicatorColor: AppColors.secondary,
                  selectedIconTheme: IconThemeData(color: AppColors.primary),
                  unselectedIconTheme:
                      IconThemeData(color: AppColors.textSecondary),
                  selectedLabelTextStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelTextStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 16, 10, 20),
                    child: SizedBox(
                      width: isWide ? 188 : 56,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: isWide
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: isWide ? double.infinity : 48,
                            padding: const EdgeInsets.all(10),
                            decoration: AppStyles.softTile(
                              context: context,
                              tint: AppColors.primary,
                              radius: 8,
                            ),
                            child: isWide
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        saudacao,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        primeiroNome,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.h4,
                                      ),
                                    ],
                                  )
                                : Icon(
                                    Icons.storefront_outlined,
                                    color: AppColors.primary,
                                  ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            alignment: isWide
                                ? WrapAlignment.start
                                : WrapAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.settings_outlined),
                                tooltip: 'Configura\u00e7\u00f5es',
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ConfiguracoesScreen(),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout),
                                tooltip: 'Sair',
                                onPressed: () => authProvider.signOut(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  destinations: [
                    for (final item in navItems)
                      NavigationRailDestination(
                        icon: item.iconWidget(selected: false),
                        selectedIcon: item.iconWidget(selected: true),
                        label: Text(item.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: tabBarView),
              ],
            ),
          );
        }

        // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ PHONE: AppBar com TabBar ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
        final mobileNavEntries = <_MobileDashboardNavEntry>[
          _MobileDashboardNavEntry(
            item: navItems[0],
            selected: _tabController.index == 0,
            onTap: () => _switchToTab(0),
          ),
          _MobileDashboardNavEntry(
            item: navItems[1],
            selected: _tabController.index == 1,
            onTap: () => _switchToTab(1),
          ),
          _MobileDashboardNavEntry(
            item: navItems[2],
            selected: _tabController.index == 2,
            onTap: () => _switchToTab(2),
          ),
          _MobileDashboardNavEntry(
            item: const _DashboardNavItem(
              label: 'Mais',
              icon: Icons.apps_outlined,
              selectedIcon: Icons.apps_rounded,
            ),
            selected: _tabController.index > 2,
            onTap: _showMobileMoreMenu,
          ),
        ];

        final currentTabLabel = navItems[_tabController.index].label;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _tabController.index == 0
              ? null
              : AppBar(
                  backgroundColor: AppColors.cardBackground,
                  elevation: 0,
                  shape: Border(
                    bottom: BorderSide(color: AppColors.cardBorder),
                  ),
                  title: Text(
                    currentTabLabel,
                    style: AppTextStyles.h3,
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ConfiguracoesScreen(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () => authProvider.signOut(),
                    ),
                  ],
                ),
          body: _tabController.index == 0 ? dashboardV2Home : tabBarView,
          bottomNavigationBar:
              _MobileDashboardNavBar(entries: mobileNavEntries),
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

// ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Monitor em tempo real ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬

class _MobileDashboardNavEntry {
  final _DashboardNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _MobileDashboardNavEntry({
    required this.item,
    required this.selected,
    required this.onTap,
  });
}

class _MobileDashboardNavBar extends StatelessWidget {
  final List<_MobileDashboardNavEntry> entries;

  const _MobileDashboardNavBar({required this.entries});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < entries.length; i++)
              Expanded(
                child: _MobileDashboardNavButton(
                  item: entries[i].item,
                  selected: entries[i].selected,
                  onTap: entries[i].onTap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileDashboardNavButton extends StatelessWidget {
  final _DashboardNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _MobileDashboardNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final idleColor = AppColors.textSecondary;
    final color = selected ? activeColor : idleColor;

    return Tooltip(
      message: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: 22,
                    color: color,
                  ),
                  if (item.badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.showBadgeCount ? '${item.badgeCount}' : '!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                _mobileNavLabel(item.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(top: 3),
                width: selected ? 4 : 0,
                height: 4,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _mobileNavLabel(String label) {
  if (label == 'Opera\u00e7\u00f5es') return 'Ops';
  if (label == 'IA Fiscal') return 'IA';
  return label;
}

class _DashboardNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int badgeCount;
  final bool showBadgeCount;

  const _DashboardNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badgeCount = 0,
    this.showBadgeCount = false,
  });

  Widget iconWidget({required bool selected}) {
    final child = Icon(selected ? selectedIcon : icon);
    if (badgeCount <= 0) return child;

    return Badge(
      isLabelVisible: true,
      backgroundColor: AppColors.danger,
      label: showBadgeCount
          ? Text(
              '$badgeCount',
              style: const TextStyle(fontSize: 10),
            )
          : null,
      child: child,
    );
  }

  NavigationDestination toNavigationDestination() {
    return NavigationDestination(
      icon: iconWidget(selected: false),
      selectedIcon: iconWidget(selected: true),
      label: label,
    );
  }
}

class _MobileMoreSection {
  final String title;
  final List<_MobileMoreAction> actions;

  const _MobileMoreSection({
    required this.title,
    required this.actions,
  });
}

class _MobileMoreAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MobileMoreAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _MobileMoreActionCard extends StatelessWidget {
  final _MobileMoreAction action;
  final VoidCallback onTap;

  const _MobileMoreActionCard({
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: AppStyles.softCard(
            context: context,
            tint: action.color,
            radius: 14,
            elevated: false,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(action.icon, color: action.color, size: 19),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _inicioHorizontalPadding(double screenWidth) {
  return Dimensions.operationalHPad(screenWidth);
}

class _BotaoAcao {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _BotaoAcao({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });
}

class _GridAcoes extends StatelessWidget {
  final List<_BotaoAcao> botoes;
  final bool wideGrid;

  const _GridAcoes({
    required this.botoes,
    this.wideGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!wideGrid) {
      return _buildList(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return _buildList(context);
        }

        final crossAxisCount = constraints.maxWidth >= 1040 ? 3 : 2;
        final childAspectRatio = constraints.maxWidth >= 1040 ? 4.2 : 3.8;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: botoes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: Dimensions.spacingSM,
            mainAxisSpacing: Dimensions.spacingSM,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final botao = botoes[index];
            return OperationalActionTile(
              icon: botao.icon,
              label: botao.label,
              color: botao.color,
              onTap: botao.onPressed,
            );
          },
        );
      },
    );
  }

  Widget _buildList(BuildContext context) {
    final tokens = context.appTheme;
    return Container(
      decoration: AppStyles.softCard(
        context: context,
        tint: AppColors.primary,
        radius: tokens.cardRadius,
        elevated: false,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < botoes.length; i++) ...[
            OperationalActionTile(
              icon: botoes[i].icon,
              label: botoes[i].label,
              color: botoes[i].color,
              onTap: botoes[i].onPressed,
              framed: false,
              dense: true,
            ),
            if (i < botoes.length - 1)
              Divider(height: 1, indent: 52, color: AppColors.cardBorder),
          ],
        ],
      ),
    );
  }
}

// ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Widgets auxiliares ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬

class _OperationsDashboardV2 extends StatelessWidget {
  final String saudacao;
  final String primeiroNome;
  final int alertCount;
  final Future<void> Function() onRefresh;
  final List<_OperationsSummaryItem> summaryItems;
  final List<_OperationsActionItem> priorityActions;
  final List<_OperationsActionItem> supportActions;
  final List<_OperationsRecentActivityItem> recentActivities;

  const _OperationsDashboardV2({
    required this.saudacao,
    required this.primeiroNome,
    required this.alertCount,
    required this.onRefresh,
    required this.summaryItems,
    required this.priorityActions,
    required this.supportActions,
    required this.recentActivities,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isPhone = constraints.maxWidth < 600;
          if (isPhone) {
            return _OperationsMobileDashboard(
              saudacao: saudacao,
              primeiroNome: primeiroNome,
              alertCount: alertCount,
              summaryItems: summaryItems,
              priorityActions: priorityActions,
              supportActions: supportActions,
              recentActivities: recentActivities,
            );
          }

          final sectionGap = isPhone ? 16.0 : 24.0;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.operationalHPad(constraints.maxWidth),
              vertical: isPhone ? 12 : Dimensions.paddingMD,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OperationsSummaryGrid(
                      items: summaryItems,
                      compact: isPhone,
                    ),
                    SizedBox(height: sectionGap),
                    const _OperationsSectionHeader(
                      icon: Icons.star_border_rounded,
                      title: 'A\u00e7\u00f5es priorit\u00e1rias',
                    ),
                    SizedBox(height: isPhone ? 10 : 12),
                    _OperationsActionsGrid(
                      actions: priorityActions,
                      large: true,
                      maxColumns: 4,
                      compact: isPhone,
                    ),
                    SizedBox(height: sectionGap),
                    const _OperationsSectionHeader(
                      icon: Icons.menu_book_rounded,
                      title: 'Apoio e consulta',
                    ),
                    SizedBox(height: isPhone ? 10 : 12),
                    _OperationsActionsGrid(
                      actions: supportActions,
                      maxColumns: 5,
                      compact: isPhone,
                    ),
                    SizedBox(height: isPhone ? 16 : Dimensions.spacingXL),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OperationsMobileDashboard extends StatelessWidget {
  final String saudacao;
  final String primeiroNome;
  final int alertCount;
  final List<_OperationsSummaryItem> summaryItems;
  final List<_OperationsActionItem> priorityActions;
  final List<_OperationsActionItem> supportActions;
  final List<_OperationsRecentActivityItem> recentActivities;

  const _OperationsMobileDashboard({
    required this.saudacao,
    required this.primeiroNome,
    required this.alertCount,
    required this.summaryItems,
    required this.priorityActions,
    required this.supportActions,
    required this.recentActivities,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OperationsMobileHeader(
            saudacao: saudacao,
            primeiroNome: primeiroNome,
            alertCount: alertCount,
          ),
          const SizedBox(height: 16),
          _OperationsMobileMetricGrid(items: summaryItems.take(4).toList()),
          const SizedBox(height: 20),
          const _OperationsMobileSectionTitle(title: 'Ações prioritárias'),
          const SizedBox(height: 10),
          _OperationsMobileActionGrid(actions: priorityActions),
          const SizedBox(height: 20),
          const _OperationsMobileSectionTitle(title: 'Apoio e consulta'),
          const SizedBox(height: 10),
          _OperationsMobileSupportGrid(actions: supportActions),
          const SizedBox(height: 20),
          const _OperationsMobileSectionTitle(title: 'Atividades recentes'),
          const SizedBox(height: 10),
          _OperationsMobileActivityCard(activities: recentActivities),
        ],
      ),
    );
  }
}

class _OperationsMobileHeader extends StatelessWidget {
  final String saudacao;
  final String primeiroNome;
  final int alertCount;

  const _OperationsMobileHeader({
    required this.saudacao,
    required this.primeiroNome,
    required this.alertCount,
  });

  @override
  Widget build(BuildContext context) {
    final cleanName =
        primeiroNome.trim().isEmpty ? 'Fiscal' : primeiroNome.trim();
    final initial = cleanName.substring(0, 1).toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$saudacao,',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                cleanName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 29,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                alertCount > 0
                    ? _pluralize(alertCount, 'ponto precisa de atenção',
                        'pontos precisam de atenção')
                    : 'Tudo sob controle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _OperationsMobileCircleIcon(
          icon: Icons.notifications_none_rounded,
          badge: alertCount > 0 ? alertCount.toString() : null,
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 21,
          backgroundColor: AppColors.primary,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _OperationsMobileCircleIcon extends StatelessWidget {
  final IconData icon;
  final String? badge;

  const _OperationsMobileCircleIcon({
    required this.icon,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: _operationsMobileCardDecoration(radius: 999),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        if (badge != null)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18),
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OperationsMobileMetricGrid extends StatelessWidget {
  final List<_OperationsSummaryItem> items;

  const _OperationsMobileMetricGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index += 2) ...[
          Row(
            children: [
              Expanded(child: _OperationsMobileMetricCard(item: items[index])),
              const SizedBox(width: 12),
              if (index + 1 < items.length)
                Expanded(
                  child: _OperationsMobileMetricCard(item: items[index + 1]),
                )
              else
                const Spacer(),
            ],
          ),
          if (index + 2 < items.length) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _OperationsMobileMetricCard extends StatelessWidget {
  final _OperationsSummaryItem item;

  const _OperationsMobileMetricCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(12),
      decoration: _operationsMobileCardDecoration(
        borderColor:
            item.highlighted ? item.color.withValues(alpha: 0.26) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OperationsMobileIconBox(
            icon: item.icon,
            color: item.color,
            compact: true,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              maxLines: 1,
              style: AppTextStyles.h1.copyWith(
                color: item.color,
                fontSize: 26,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationsMobileActionGrid extends StatelessWidget {
  final List<_OperationsActionItem> actions;

  const _OperationsMobileActionGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            childAspectRatio: compact ? 4.7 : 5.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) =>
              _OperationsMobileActionCard(action: actions[index]),
        );
      },
    );
  }
}

class _OperationsMobileActionCard extends StatelessWidget {
  final _OperationsActionItem action;

  const _OperationsMobileActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: action.onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: _operationsMobileCardDecoration(
            borderColor: action.highlighted
                ? action.color.withValues(alpha: 0.30)
                : null,
            color: action.highlighted
                ? action.color.withValues(alpha: 0.045)
                : AppColors.cardBackground,
          ),
          child: Row(
            children: [
              _OperationsMobileIconBox(
                icon: action.icon,
                color: action.color,
                compact: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationsMobileSupportGrid extends StatelessWidget {
  final List<_OperationsActionItem> actions;

  const _OperationsMobileSupportGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: compact ? 1.05 : 1.12,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) =>
              _OperationsMobileSupportCard(action: actions[index]),
        );
      },
    );
  }
}

class _OperationsMobileSupportCard extends StatelessWidget {
  final _OperationsActionItem action;

  const _OperationsMobileSupportCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: action.onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          decoration: _operationsMobileCardDecoration(
            borderColor: action.highlighted
                ? action.color.withValues(alpha: 0.28)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _OperationsMobileIconBox(
                icon: action.icon,
                color: action.color,
                compact: true,
              ),
              const SizedBox(height: 8),
              Text(
                action.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationsMobileActivityCard extends StatelessWidget {
  final List<_OperationsRecentActivityItem> activities;

  const _OperationsMobileActivityCard({required this.activities});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _operationsMobileCardDecoration(),
      child: activities.isEmpty
          ? _OperationsMobileActivityTile(
              item: _OperationsRecentActivityItem(
                icon: Icons.check_circle_outline_rounded,
                title: 'Sem atividades recentes',
                subtitle: 'As ações do turno aparecem aqui.',
                time: '',
                color: AppColors.success,
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < activities.length; index++) ...[
                  _OperationsMobileActivityTile(item: activities[index]),
                  if (index < activities.length - 1)
                    Divider(height: 20, color: AppColors.cardBorder),
                ],
              ],
            ),
    );
  }
}

class _OperationsMobileActivityTile extends StatelessWidget {
  final _OperationsRecentActivityItem item;

  const _OperationsMobileActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _OperationsMobileIconBox(
          icon: item.icon,
          color: item.color,
          compact: true,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (item.time.isNotEmpty) ...[
          const SizedBox(width: 10),
          Text(
            item.time,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _OperationsMobileSectionTitle extends StatelessWidget {
  final String title;

  const _OperationsMobileSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.h3.copyWith(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _OperationsMobileIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool compact;

  const _OperationsMobileIconBox({
    required this.icon,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 36 : 44,
      height: compact ? 36 : 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
      ),
      child: Icon(icon, color: color, size: compact ? 18 : 23),
    );
  }
}

class _OperationsSummaryGrid extends StatelessWidget {
  final List<_OperationsSummaryItem> items;
  final bool compact;

  const _OperationsSummaryGrid({
    required this.items,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns =
            compact ? 2 : (width >= 1080 ? 4 : (width >= 640 ? 2 : 1));
        final gap = compact ? 10.0 : 14.0;
        final itemWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                height: compact ? 88 : 112,
                child: _OperationsSummaryCard(
                  item: item,
                  compact: compact,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OperationsSummaryCard extends StatelessWidget {
  final _OperationsSummaryItem item;
  final bool compact;

  const _OperationsSummaryCard({
    required this.item,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final softColor = item.highlighted
        ? item.color.withValues(alpha: 0.10)
        : item.color.withValues(alpha: 0.08);

    return Container(
      padding: EdgeInsets.all(compact ? 11 : 16),
      decoration: _operationsCardDecoration(
        borderColor:
            item.highlighted ? item.color.withValues(alpha: 0.36) : null,
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 36 : 52,
            height: compact ? 36 : 52,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(compact ? 10 : 14),
            ),
            child: Icon(item.icon, color: item.color, size: compact ? 18 : 26),
          ),
          SizedBox(width: compact ? 9 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.color,
                    fontSize: compact ? 22 : 26,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                SizedBox(height: compact ? 2 : 3),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: compact ? 11.5 : 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!compact) const SizedBox(height: 4),
                if (!compact)
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: item.highlighted
                          ? item.color
                          : AppColors.textSecondary,
                      fontWeight:
                          item.highlighted ? FontWeight.w800 : FontWeight.w600,
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

class _OperationsSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _OperationsSectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _OperationsActionsGrid extends StatelessWidget {
  final List<_OperationsActionItem> actions;
  final bool large;
  final int maxColumns;
  final bool compact;

  const _OperationsActionsGrid({
    required this.actions,
    this.large = false,
    required this.maxColumns,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = compact ? 2 : _operationsColumns(width, maxColumns);
        final gap = compact ? 10.0 : 14.0;
        final itemWidth = (width - gap * (columns - 1)) / columns;
        final itemHeight = compact ? 68.0 : (large ? 204.0 : 156.0);

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final action in actions)
              SizedBox(
                width: itemWidth,
                height: itemHeight,
                child: _OperationsActionCard(
                  action: action,
                  large: large,
                  compact: compact,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OperationsActionCard extends StatelessWidget {
  final _OperationsActionItem action;
  final bool large;
  final bool compact;

  const _OperationsActionCard({
    required this.action,
    required this.large,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        onTap: action.onTap,
        child: Ink(
          padding: EdgeInsets.all(compact ? 10 : (large ? 16 : 14)),
          decoration: _operationsCardDecoration(
            borderColor: action.highlighted
                ? action.color.withValues(alpha: 0.34)
                : null,
            color: action.highlighted
                ? action.color.withValues(alpha: 0.045)
                : AppColors.cardBackground,
          ),
          child: compact
              ? Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: action.color.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        action.icon,
                        color: action.color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        action.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: large ? 48 : 42,
                          height: large ? 48 : 42,
                          decoration: BoxDecoration(
                            color: action.color.withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            action.icon,
                            color: action.color,
                            size: large ? 25 : 22,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: large ? 22 : 16),
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: large ? 16 : 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      action.subtitle,
                      maxLines: large ? 2 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (action.badge != null && action.badge!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: action.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          action.badge!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: action.color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _OperationsSummaryItem {
  final IconData icon;
  final String value;
  final String title;
  final String subtitle;
  final Color color;
  final bool highlighted;

  const _OperationsSummaryItem({
    required this.icon,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.color,
    this.highlighted = false,
  });
}

class _OperationsActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final Color color;
  final bool highlighted;
  final VoidCallback onTap;

  const _OperationsActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
    this.highlighted = false,
  });
}

class _OperationsRecentActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _OperationsRecentActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });
}

BoxDecoration _operationsCardDecoration({
  Color? color,
  Color? borderColor,
}) {
  return BoxDecoration(
    color: color ?? AppColors.cardBackground,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderColor ?? AppColors.cardBorder),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.035),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

BoxDecoration _operationsMobileCardDecoration({
  Color? color,
  Color? borderColor,
  double radius = 20,
}) {
  return BoxDecoration(
    color: color ?? AppColors.cardBackground,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? AppColors.cardBorder),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.035),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

int _operationsColumns(double width, int maxColumns) {
  if (width < 560) return 1;
  if (width < 900) return maxColumns >= 3 ? 2 : 1;
  if (width < 1180) return maxColumns >= 4 ? 3 : maxColumns;
  return maxColumns;
}

String _formatOperationsTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

IconData _operationsActivityIcon(String type) {
  if (type.contains('checklist')) return Icons.fact_check_outlined;
  if (type.contains('entrega')) return Icons.local_shipping_outlined;
  if (type.contains('ocorrencia')) return Icons.warning_amber_rounded;
  if (type.contains('anotacao')) return Icons.edit_note_rounded;
  if (type.contains('formulario')) return Icons.description_outlined;
  if (type.contains('cafe') || type.contains('intervalo')) {
    return Icons.coffee_outlined;
  }
  if (type.contains('liberado')) return Icons.logout_rounded;
  if (type.contains('alocado')) return Icons.person_add_alt_1_rounded;
  return Icons.check_circle_outline_rounded;
}

Color _operationsActivityColor(String type) {
  if (type.contains('ocorrencia')) return AppColors.danger;
  if (type.contains('checklist')) return AppColors.warning;
  if (type.contains('entrega')) return AppColors.primary;
  if (type.contains('anotacao')) return AppColors.statusSaida;
  if (type.contains('formulario')) return AppColors.indigo;
  if (type.contains('cafe') || type.contains('intervalo')) {
    return AppColors.coffee;
  }
  return AppColors.success;
}

String _pluralize(int value, String singular, String plural) {
  return '$value ${value == 1 ? singular : plural}';
}

class _InicioHeroCard extends StatelessWidget {
  final String saudacao;
  final String primeiroNome;
  final bool turnoJaIniciado;
  final int totalAtivos;
  final int totalCaixas;
  final int alocados;
  final int livres;
  final int emPausa;
  final int emRota;
  final int alertas;
  final VoidCallback onPrimaryAction;

  const _InicioHeroCard({
    required this.saudacao,
    required this.primeiroNome,
    required this.turnoJaIniciado,
    required this.totalAtivos,
    required this.totalCaixas,
    required this.alocados,
    required this.livres,
    required this.emPausa,
    required this.emRota,
    required this.alertas,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final statusColor = turnoJaIniciado ? AppColors.success : AppColors.primary;
    final statusLabel =
        turnoJaIniciado ? 'Turno em andamento' : 'Aguardando in\u00edcio';
    final statusIcon =
        turnoJaIniciado ? Icons.play_circle_outline : Icons.hourglass_top;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      decoration: AppStyles.softCard(
        context: context,
        tint: statusColor,
        radius: tokens.sheetRadius,
        elevated: false,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          final headline = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusPill(
                    icon: Icons.dashboard_customize_outlined,
                    label: 'Central do turno',
                    color: AppColors.primary,
                  ),
                  StatusPill(
                    icon: statusIcon,
                    label: statusLabel,
                    color: statusColor,
                  ),
                  if (alertas > 0)
                    StatusPill(
                      icon: Icons.priority_high_rounded,
                      label: '$alertas alerta${alertas > 1 ? 's' : ''}',
                      color: AppColors.warning,
                    ),
                ],
              ),
              const SizedBox(height: Dimensions.spacingSM),
              Text(
                '$saudacao, $primeiroNome',
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: Dimensions.spacingXS),
              Text(
                turnoJaIniciado
                    ? 'Acompanhe ritmo, alertas e pausas com uma leitura direta da opera\u00e7\u00e3o.'
                    : 'Abra o turno com contexto do dia e confirme as prioridades antes de assumir.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: Dimensions.spacingSM),
              SizedBox(
                width: isWide ? null : double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onPrimaryAction,
                  icon: Icon(
                    turnoJaIniciado
                        ? Icons.timeline_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    turnoJaIniciado
                        ? 'Abrir timeline do turno'
                        : 'Come\u00e7ar turno',
                  ),
                ),
              ),
            ],
          );
          final signals = Container(
            padding: const EdgeInsets.all(Dimensions.paddingSM),
            decoration: AppStyles.softTile(
              context: context,
              tint: statusColor,
              radius: tokens.cardRadius,
            ),
            child: Column(
              children: [
                _InicioSignalRow(
                  icon: Icons.people_alt_outlined,
                  label: 'Equipe ativa',
                  value: totalAtivos.toString(),
                  color: AppColors.primary,
                ),
                Divider(height: 18, color: tokens.cardBorder),
                _InicioSignalRow(
                  icon: Icons.point_of_sale_outlined,
                  label: 'Caixas ativos',
                  value: totalCaixas.toString(),
                  color: AppColors.success,
                ),
                Divider(height: 18, color: tokens.cardBorder),
                _InicioSignalRow(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Alocados / livres',
                  value: '$alocados / $livres',
                  color: AppColors.statusAtivo,
                ),
                Divider(height: 18, color: tokens.cardBorder),
                _InicioSignalRow(
                  icon: Icons.coffee_outlined,
                  label: 'Pausas / rotas',
                  value: '$emPausa / $emRota',
                  color: AppColors.coffee,
                ),
              ],
            ),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: headline),
                const SizedBox(width: Dimensions.spacingMD),
                SizedBox(width: 264, child: signals),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              headline,
              const SizedBox(height: Dimensions.spacingMD),
              signals,
            ],
          );
        },
      ),
    );
  }
}

class _InicioSignalRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InicioSignalRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: Dimensions.spacingSM),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: Dimensions.spacingSM),
        Text(
          value,
          style: AppTextStyles.h4.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

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

class _BannerSaudeDestino {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _BannerSaudeDestino({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
}

class _AlertCard extends StatelessWidget {
  final _AlertItem item;

  const _AlertCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: item.onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: AppStyles.softTile(tint: item.color, radius: 12),
            child: Row(
              children: [
                Icon(item.icon, color: item.color, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: AppTextStyles.body.copyWith(
                      color: item.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: item.color, size: 13),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Banner de saÃƒÆ’Ã‚Âºde do turno ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬

class _BannerSaudeTurno extends StatelessWidget {
  final bool critico;
  final bool atencao;
  final VoidCallback? onTap;

  const _BannerSaudeTurno({
    required this.critico,
    required this.atencao,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cor;
    final IconData icone;
    final String titulo;
    final String subtitulo;

    if (critico) {
      cor = AppColors.danger;
      icone = Icons.error_outline;
      titulo = 'Turno com alertas cr\u00edticos';
      subtitulo = 'Verifique pausas em atraso ou lembretes vencidos';
    } else if (atencao) {
      cor = AppColors.warning;
      icone = Icons.warning_amber_outlined;
      titulo = 'Turno requer aten\u00e7\u00e3o';
      subtitulo = 'H\u00e1 ocorr\u00eancias, entregas ou checklist pendentes';
    } else {
      cor = AppColors.success;
      icone = Icons.check_circle_outline;
      titulo = 'Tudo em ordem';
      subtitulo = 'Nenhum alerta ativo no momento';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingMD, vertical: Dimensions.paddingSM),
          decoration: AppStyles.softCard(
            context: context,
            tint: cor,
            radius: tokens.cardRadius,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: AppStyles.softTile(
                  context: context,
                  tint: cor,
                  radius: 16,
                ),
                child: Icon(icone, color: cor, size: 24),
              ),
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
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: AppStyles.softTile(
                  context: context,
                  tint: cor,
                  radius: 999,
                ),
                child: Text(
                  critico
                      ? 'Cr\u00edtico'
                      : atencao
                          ? 'Aten\u00e7\u00e3o'
                          : 'Est\u00e1vel',
                  style: AppTextStyles.caption.copyWith(
                    color: cor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: Dimensions.spacingSM),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: isDark ? cor : AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Barra de ocupaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o dos caixas ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬

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
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: AppStyles.softTile(
                context: context,
                tint: corBarra,
                radius: 999,
              ),
              child: Text(
                '$percentual%',
                style: AppTextStyles.caption.copyWith(
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
        Divider(height: 1, color: AppColors.cardBorder),
        const SizedBox(height: Dimensions.spacingMD),
        Row(
          children: [
            Expanded(
              child: _buildStatRow(
                context,
                Icons.coffee_outlined,
                'Em Pausa',
                emPausa.toString(),
                AppColors.coffee,
              ),
            ),
            const SizedBox(width: Dimensions.spacingMD),
            Expanded(
              child: _buildStatRow(
                context,
                Icons.local_shipping_outlined,
                'Em Rota',
                emRota.toString(),
                AppColors.statusCafe,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSM,
          vertical: Dimensions.paddingSM,
        ),
        decoration: AppStyles.softTile(
          context: context,
          tint: color,
          radius: 18,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ));
  }
}

// ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Briefing de inÃƒÆ’Ã‚Â­cio de turno ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
