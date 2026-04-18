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
import '../pizzaria/pizza_module_screen.dart';
// profile_screen.dart usado via ConfiguracoesScreen
import '../configuracoes/configuracoes_screen.dart';
import '../../../data/services/seed_data_service.dart';
import '../../../core/utils/app_notif.dart';
import 'widgets/stats_card.dart';

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
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (_) => _BriefingTurnoSheet(fiscalId: fiscalId),
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
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingMD),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Escolha o alerta para abrir',
                  style: AppTextStyles.h4,
                ),
              ),
            ),
            SizedBox(height: 8),
            ...destinos.map(
              (d) => ListTile(
                leading: Icon(d.icon, color: d.color),
                title: Text(d.label),
                trailing: Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => Navigator.pop(ctx, d),
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || destinoSelecionado == null) return;
    destinoSelecionado.onTap();
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

    // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Tabs compartilhadas entre phone e tablet ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
    final tabBarView = TabBarView(
      controller: _tabController,
      children: [
        // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ ABA 1: INÃƒÂCIO ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
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
                        _InicioHeroCard(
                          saudacao: saudacao,
                          primeiroNome: primeiroNome,
                          turnoJaIniciado: turnoJaIniciado,
                          totalAtivos: totalAtivos,
                          livres: livres,
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
                        SizedBox(height: Dimensions.spacingMD),

                        // BotÃƒÂ£o ComeÃƒÂ§ar Turno Ã¢â‚¬â€ oculto apÃƒÂ³s confirmar inÃƒÂ­cio
                        _DashboardSectionHeader(
                          icon: Icons.monitor_heart_outlined,
                          title: 'Monitor operacional',
                        ),
                        SizedBox(height: Dimensions.spacingSM),
                        _MonitorTempoReal(
                          cafeProvider: cafeProvider,
                          colaboradorProvider: colaboradorProvider,
                          caixaProvider: caixaProvider,
                          escalaProvider: escalaProvider,
                        ),
                        SizedBox(height: Dimensions.spacingLG),
                        _DashboardSectionHeader(
                          icon: Icons.grid_view_rounded,
                          title: 'Rotinas principais',
                        ),
                        SizedBox(height: Dimensions.spacingSM),
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
                                  builder: (_) =>
                                      const RelatorioDiarioScreen(),
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
                          ],
                        ),
                        SizedBox(height: Dimensions.spacingLG),
                        _DashboardSectionHeader(
                          icon: Icons.space_dashboard_outlined,
                          title: 'Vis\u00e3o geral',
                        ),
                        SizedBox(height: Dimensions.spacingSM),
                        LayoutBuilder(
                          builder: (context, statsConstraints) {
                            final crossAxisCount =
                                statsConstraints.maxWidth >= 640 ? 3 : 2;
                            final childAspectRatio =
                                crossAxisCount == 3 ? 1.45 : 1.28;
                            return GridView.count(
                              crossAxisCount: crossAxisCount,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: Dimensions.spacingSM,
                              mainAxisSpacing: Dimensions.spacingSM,
                              childAspectRatio: childAspectRatio,
                              children: [
                                StatsCard(
                                  title: 'Colaboradores',
                                  value: totalAtivos.toString(),
                                  icon: Icons.people_alt_outlined,
                                  color: AppColors.primary,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ColaboradoresListScreen(),
                                    ),
                                  ),
                                ),
                                StatsCard(
                                  title: 'Caixas ativos',
                                  value: totalCaixas.toString(),
                                  icon: Icons.point_of_sale_outlined,
                                  color: AppColors.success,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const GestaoScreen(initialIndex: 1),
                                    ),
                                  ),
                                ),
                                StatsCard(
                                  title: 'Alocados agora',
                                  value: alocados.toString(),
                                  icon: Icons.swap_horiz_rounded,
                                  color: AppColors.statusAtivo,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const GestaoScreen(initialIndex: 0),
                                    ),
                                  ),
                                ),
                                StatsCard(
                                  title: 'Livres',
                                  value: livres.toString(),
                                  icon: Icons.check_circle_outline,
                                  color: AppColors.info,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const GestaoScreen(initialIndex: 1),
                                    ),
                                  ),
                                ),
                                StatsCard(
                                  title: 'Em pausa',
                                  value: emPausa.toString(),
                                  icon: Icons.coffee_outlined,
                                  color: AppColors.coffee,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const GestaoScreen(initialIndex: 2),
                                    ),
                                  ),
                                ),
                                StatsCard(
                                  title: 'Em rota',
                                  value: emRota.toString(),
                                  icon: Icons.local_shipping_outlined,
                                  color: AppColors.statusCafe,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const EntregasScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        if (alertas.isNotEmpty) ...[
                          SizedBox(height: Dimensions.spacingLG),
                          _DashboardSectionHeader(
                            icon: Icons.notification_important_outlined,
                            title: 'Alertas do turno',
                          ),
                          SizedBox(height: Dimensions.spacingSM),
                          ...alertas.map((a) => _AlertCard(item: a)),
                        ],
                        SizedBox(height: Dimensions.spacingXL),
                      ],
                    ),
                  ),
                )),


        // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ ABA 3: PIZZARIA ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
        const PizzaModuleScreen(),

        // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ ABA 4: OPERAÃƒâ€¡Ãƒâ€¢ES ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
        SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardSectionHeader(
                icon: Icons.priority_high_rounded,
                title: 'A\u00e7\u00f5es priorit\u00e1rias',
              ),
              SizedBox(height: Dimensions.spacingSM),
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
                      MaterialPageRoute(builder: (_) => const EntregasScreen()),
                    ),
                  ),
                  _BotaoAcao(
                    icon: Icons.report_problem,
                    label: 'Ocorr\u00eancias',
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
                ],
              ),
              SizedBox(height: Dimensions.spacingMD),
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: _DashboardSectionHeader(
                    icon: Icons.menu_book_rounded,
                    title: 'Apoio e consulta',
                  ),
                  children: [
                    SizedBox(height: Dimensions.spacingSM),
                    _GridAcoes(
                      botoes: [
                        _BotaoAcao(
                          icon: Icons.help_outline,
                          label: 'Guia R\u00e1pido',
                          color: AppColors.blueGrey,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const GuiaRapidoScreen()),
                          ),
                        ),
                        _BotaoAcao(
                          icon: Icons.note,
                          label: 'Anota\u00e7\u00f5es',
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
                          label: 'Formul\u00e1rios',
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
                          label: 'Notifica\u00e7\u00f5es',
                          color: AppColors.primary,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const NotificacoesScreen()),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Dimensions.spacingSM),
                  ],
                ),
              ),
              SizedBox(height: Dimensions.spacingMD),
              Row(
                children: [
                  Expanded(
                    child: _InicioMetricTile(
                      label: 'Entregas',
                      value: entregaProvider.totalSeparadas.toString(),
                      color: entregaProvider.totalSeparadas > 0
                          ? AppColors.statusCafe
                          : AppColors.success,
                    ),
                  ),
                  SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: _InicioMetricTile(
                      label: 'Ocorr\u00eancias',
                      value: ocorrenciaProvider.totalAbertas.toString(),
                      color: ocorrenciaProvider.totalAbertas > 0
                          ? AppColors.danger
                          : AppColors.success,
                    ),
                  ),
                  SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: _InicioMetricTile(
                      label: 'Checklists',
                      value: checklistProvider.templatesPendentesAgora.length
                          .toString(),
                      color:
                          checklistProvider.templatesPendentesAgora.isNotEmpty
                              ? AppColors.warning
                              : AppColors.success,
                    ),
                  ),
                  SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: _InicioMetricTile(
                      label: 'Notas',
                      value: notaProvider.totalTarefasPendentes.toString(),
                      color: notaProvider.totalTarefasPendentes > 0
                          ? AppColors.statusSaida
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ ABA 5: LOJA ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
        RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Dimensions.paddingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardSectionHeader(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Sa\u00fade do turno',
                ),
                SizedBox(height: Dimensions.spacingSM),
                _BannerSaudeTurno(
                  critico: cafeProvider.totalEmAtraso > 0 ||
                      notaProvider.totalLembretesVencidos > 0,
                  atencao: ocorrenciaProvider.totalAbertas > 0 ||
                      entregaProvider.totalSeparadas > 0 ||
                      checklistProvider.templatesPendentesAgora.isNotEmpty,
                  onTap: onTapBannerSaude,
                ),
                SizedBox(height: Dimensions.spacingMD),
                if (fiscalProvider.fiscal != null) ...[
                  _DashboardSectionHeader(
                    icon: Icons.query_stats_rounded,
                    title: 'Ocupa\u00e7\u00e3o do turno',
                  ),
                  SizedBox(height: Dimensions.spacingSM),
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
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                SizedBox(height: Dimensions.spacingLG),
                _DashboardSectionHeader(
                  icon: Icons.build_outlined,
                  title: 'Ferramentas r\u00e1pidas',
                ),
                SizedBox(height: Dimensions.spacingSM),
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
                SizedBox(height: Dimensions.spacingXL),
              ],
            ),
          ),
        ),
      ],
    );

    // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Layout adaptativo ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= Dimensions.breakpointTablet;

        // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ TABLET: NavigationRail + TabBarView ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
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
                        SizedBox(height: 8),
                        IconButton(
                          icon: Icon(Icons.settings_outlined),
                          tooltip: 'Configura\u00e7\u00f5es',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const ConfiguracoesScreen()),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.logout),
                          tooltip: 'Sair',
                          onPressed: () => authProvider.signOut(),
                        ),
                      ],
                    ),
                  ),
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      label: Text('In\u00edcio'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.local_pizza_outlined),
                      label: Text('Pizzaria'),
                    ),
                    NavigationRailDestination(
                      icon: Badge(
                        isLabelVisible: cafeProvider.totalEmAtraso > 0,
                        backgroundColor: AppColors.danger,
                        child: Icon(Icons.build_outlined),
                      ),
                      label: Text('Opera\u00e7\u00f5es'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.store_outlined),
                      label: Text('Loja'),
                    ),
                  ],
                ),
                VerticalDivider(width: 1, thickness: 1),
                Expanded(child: tabBarView),
              ],
            ),
          );
        }

        // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ PHONE: AppBar com TabBar ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
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
                icon: Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ConfiguracoesScreen()),
                ),
              ),
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () => authProvider.signOut(),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(fontSize: 11),
              tabs: [
                const Tab(
                    icon: Icon(Icons.home_outlined, size: 20),
                    text: 'In\u00edcio'),
                const Tab(
                    icon: Icon(Icons.local_pizza_outlined, size: 20),
                    text: 'Pizzaria'),
                Tab(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.build_outlined, size: 20),
                      if (cafeProvider.totalEmAtraso > 0)
                        Positioned(
                          top: -4,
                          right: -6,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  text: 'Opera\u00e7\u00f5es',
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

// ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Monitor em tempo real ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

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

  Future<void> _finalizarPausaDoMonitor(
    BuildContext context,
    PausaCafe pausa,
  ) async {
    final alocacaoProvider =
        Provider.of<AlocacaoProvider>(context, listen: false);
    final fiscalId =
        Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';

    if (fiscalId.isEmpty) {
      if (context.mounted) {
        AppNotif.show(
          context,
          titulo: 'Erro',
          mensagem: 'Usu\u00e1rio n\u00e3o autenticado para finalizar pausa.',
          tipo: 'alerta',
          cor: AppColors.danger,
        );
      }
      return;
    }

    _RetornoMonitorEscolha? escolhaIntervalo;
    String? erro;
    if (pausa.isIntervalo) {
      escolhaIntervalo = await _escolherRetornoIntervalo(
        context: context,
        pausa: pausa,
        alocacaoProvider: alocacaoProvider,
      );
      if (escolhaIntervalo == null) return;

      erro = await cafeProvider.finalizarPausaComRegra(
        pausa: pausa,
        alocacaoProvider: alocacaoProvider,
        fiscalId: fiscalId,
        caixaDestinoIntervaloId: escolhaIntervalo.caixaDestinoId,
        permitirMesmoCaixaNoIntervalo: escolhaIntervalo.permitirMesmoCaixa,
        justificativaMesmoCaixa: escolhaIntervalo.justificativaMesmoCaixa,
      );
    } else {
      erro = await cafeProvider.finalizarPausaComRegra(
        pausa: pausa,
        alocacaoProvider: alocacaoProvider,
        fiscalId: fiscalId,
      );
    }

    if (!context.mounted) return;

    if (erro != null) {
      AppNotif.show(
        context,
        titulo: 'Pausa finalizada',
        mensagem: erro,
        tipo: 'alerta',
        cor: AppColors.warning,
      );
      return;
    }

    final caixaDestino = pausa.isCafe
        ? caixaProvider.caixas
            .where((c) => c.id == pausa.caixaId)
            .firstOrNull
            ?.nomeExibicao
        : caixaProvider.caixas
            .where((c) => c.id == escolhaIntervalo?.caixaDestinoId)
            .firstOrNull
            ?.nomeExibicao;

    final usouExcecaoMesmoCaixa =
        pausa.isIntervalo && pausa.caixaId == escolhaIntervalo?.caixaDestinoId;

    AppNotif.show(
      context,
      titulo: 'Pausa finalizada',
      mensagem: pausa.isCafe
          ? '${pausa.colaboradorNome} voltou ao ${caixaDestino ?? 'caixa'}.'
          : '${pausa.colaboradorNome} realocado(a) para ${caixaDestino ?? 'caixa'}'
              '${usouExcecaoMesmoCaixa ? ' (exce\u00e7\u00e3o registrada)' : ''}.',
      tipo: 'saida',
      cor: AppColors.success,
    );
  }

  Future<_RetornoMonitorEscolha?> _escolherRetornoIntervalo({
    required BuildContext context,
    required PausaCafe pausa,
    required AlocacaoProvider alocacaoProvider,
  }) async {
    final caixasAtivos = caixaProvider.caixas
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
          titulo: 'Sem caixa dispon\u00edvel',
          mensagem: 'N\u00e3o h\u00e1 caixa livre para retorno do intervalo.',
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

    final escolha = await showDialog<_RetornoMonitorEscolha>(
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
            title: Text('Retorno do intervalo'),
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
                      Text('Regra padrao: retornar em caixa diferente.'),
                      SizedBox(height: 12),
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
                        SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: permitirMesmoCaixa,
                          onChanged: (v) => setStateDialog(
                            () => permitirMesmoCaixa = v ?? false,
                          ),
                          title:
                              Text('Permitir mesmo caixa (exce\u00e7\u00e3o)'),
                          subtitle: Text(
                            'Necess\u00e1rio justificar para auditoria.',
                          ),
                        ),
                        if (permitirMesmoCaixa) ...[
                          SizedBox(height: 8),
                          TextField(
                            controller: justificativaCtrl,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'Justificativa da exce\u00e7\u00e3o *',
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
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: !podeConfirmar
                    ? null
                    : () => Navigator.pop(
                          ctx,
                          _RetornoMonitorEscolha(
                            caixaDestinoId: caixaSelecionadoId!,
                            permitirMesmoCaixa: permitirMesmoCaixa,
                            justificativaMesmoCaixa:
                                justificativaCtrl.text.trim().isEmpty
                                    ? null
                                    : justificativaCtrl.text.trim(),
                          ),
                        ),
                child: Text('Confirmar retorno'),
              ),
            ],
          );
        },
      ),
    );

    justificativaCtrl.dispose();
    return escolha;
  }

  @override
  Widget build(BuildContext context) {
    final pausasAtivas = cafeProvider.pausasAtivas;

    // PrÃƒÂ³ximos intervalos (Ã¢â€°Â¤15 min) Ã¢â‚¬â€ apenas colaboradores ativos no turno
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
            .firstWhere((c) => c.id == turno.colaboradorId, orElse: () => null);
        if (colab != null) {
          proximos.add(_ProximoIntervalo(
            nome: colab.nome as String,
            minutosRestantes: diff,
            horario: turno.intervalo!,
          ));
        }
      }
    }

    final semAlertas = pausasAtivas.isEmpty && proximos.isEmpty;
    final tokens = context.appTheme;

    return Container(
      decoration: AppStyles.softCard(
        context: context,
        tint: AppColors.primary,
        radius: tokens.cardRadius + 2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart_outlined,
                    color: AppColors.primary, size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text('Monitor em tempo real', style: AppTextStyles.h4),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: AppStyles.softTile(
                    context: context,
                    tint: semAlertas ? AppColors.success : AppColors.warning,
                    radius: 999,
                  ),
                  child: Text(
                    semAlertas ? 'Est\u00e1vel' : 'Ao vivo',
                    style: AppTextStyles.caption.copyWith(
                      color: semAlertas ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (semAlertas)
              Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Tudo em ordem, nenhum alerta no momento',
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
                SizedBox(height: 6),
                ...pausasAtivas.map((p) {
                  final caixa = p.caixaId != null
                      ? caixaProvider.caixas.cast<dynamic>().firstWhere(
                          (c) => c.id == p.caixaId,
                          orElse: () => null)
                      : null;
                  final isCafe = p.isCafe;
                  final cor = p.emAtraso
                      ? AppColors.danger
                      : (isCafe ? AppColors.coffee : AppColors.warning);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: AppStyles.softTile(
                      context: context,
                      tint: cor,
                      radius: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCafe ? Icons.coffee : Icons.restaurant,
                          color: cor,
                          size: 16,
                        ),
                        SizedBox(width: 8),
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
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textSecondary),
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
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _finalizarPausaDoMonitor(context, p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color:
                                      AppColors.success.withValues(alpha: 0.4)),
                            ),
                            child: Text(
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

              // PrÃƒÂ³ximos intervalos
              if (proximos.isNotEmpty) ...[
                if (pausasAtivas.isNotEmpty) SizedBox(height: 10),
                Text(
                  'INTERVALO EM BREVE',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 6),
                ...proximos.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: AppStyles.softTile(
                        context: context,
                        tint: AppColors.warning,
                        radius: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: AppColors.warning,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p.nome,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                          Text(
                            '\u00e0s ${p.horario} \u00b7 em ${p.minutosRestantes} min',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.warning),
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

class _RetornoMonitorEscolha {
  final String caixaDestinoId;
  final bool permitirMesmoCaixa;
  final String? justificativaMesmoCaixa;

  const _RetornoMonitorEscolha({
    required this.caixaDestinoId,
    required this.permitirMesmoCaixa,
    this.justificativaMesmoCaixa,
  });
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

// ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Helpers de layout ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

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
            _BotaoAcaoTile(botao: botoes[i]),
            if (i < botoes.length - 1)
              Divider(height: 1, indent: 52, color: AppColors.cardBorder),
          ],
        ],
      ),
    );
  }
}

class _BotaoAcaoTile extends StatelessWidget {
  final _BotaoAcao botao;

  const _BotaoAcaoTile({required this.botao});

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: botao.onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingMD,
            vertical: 12,
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: botao.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: botao.color.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Icon(botao.icon, color: botao.color, size: 18),
                  ),
                  if (botao.badge != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: tokens.cardBackground,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          botao.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: Dimensions.spacingSM),
              Expanded(
                child: Text(
                  botao.label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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

// ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Widgets auxiliares ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

class _DashboardSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _DashboardSectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: tokens.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: tokens.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(icon, color: tokens.primary, size: 16),
        ),
        SizedBox(width: Dimensions.spacingSM),
        Expanded(
          child: Text(title, style: AppTextStyles.h4),
        ),
      ],
    );
  }
}

class _InicioHeroCard extends StatelessWidget {
  final String saudacao;
  final String primeiroNome;
  final bool turnoJaIniciado;
  final int totalAtivos;
  final int livres;
  final int alertas;
  final VoidCallback onPrimaryAction;

  const _InicioHeroCard({
    required this.saudacao,
    required this.primeiroNome,
    required this.turnoJaIniciado,
    required this.totalAtivos,
    required this.livres,
    required this.alertas,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = turnoJaIniciado ? AppColors.success : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: isDark ? 0.24 : 0.14),
            tokens.cardBackground,
            tokens.backgroundSection,
          ],
        ),
        borderRadius: BorderRadius.circular(tokens.cardRadius + 2),
        border: Border.all(
          color: statusColor.withValues(alpha: isDark ? 0.34 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.shadowColor.withValues(alpha: isDark ? 0.16 : 0.06),
            blurRadius: isDark ? 22 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InicioBadge(
                icon: Icons.dashboard_customize_outlined,
                label: 'Painel do dia',
                color: AppColors.primary,
              ),
              _InicioBadge(
                icon: turnoJaIniciado
                    ? Icons.play_circle_outline
                    : Icons.hourglass_top_rounded,
                label: turnoJaIniciado
                    ? 'Turno em andamento'
                    : 'Aguardando in\u00edcio',
                color: statusColor,
              ),
              if (alertas > 0)
                _InicioBadge(
                  icon: Icons.priority_high_rounded,
                  label: '$alertas alerta${alertas > 1 ? 's' : ''}',
                  color: AppColors.warning,
                ),
            ],
          ),
          SizedBox(height: Dimensions.spacingMD),
          Text(
            '$saudacao, $primeiroNome',
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: Dimensions.spacingXS),
          Text(
            turnoJaIniciado
                ? 'Acompanhe o ritmo da opera\u00e7\u00e3o, os alertas e as pausas com uma leitura r\u00e1pida do turno.'
                : 'Comece o turno com contexto claro da opera\u00e7\u00e3o e acesso r\u00e1pido ao briefing.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          SizedBox(height: Dimensions.spacingMD),
          Row(
            children: [
              Expanded(
                child: _InicioMetricTile(
                  label: 'Ativos hoje',
                  value: totalAtivos.toString(),
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: Dimensions.spacingSM),
              Expanded(
                child: _InicioMetricTile(
                  label: 'Livres agora',
                  value: livres.toString(),
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.spacingMD),
          Align(
            alignment: Alignment.centerLeft,
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
      ),
    );
  }
}

class _InicioBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InicioBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: AppStyles.softTile(
        context: context,
        tint: color,
        radius: 999,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InicioMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InicioMetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
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
                SizedBox(width: 10),
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

// ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Banner de saÃƒÂºde do turno ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

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
              SizedBox(width: Dimensions.spacingMD),
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
                    SizedBox(height: 2),
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
                      ? 'Crítico'
                      : atencao
                          ? 'Atenção'
                          : 'Estável',
                  style: AppTextStyles.caption.copyWith(
                    color: cor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onTap != null) ...[
                SizedBox(width: Dimensions.spacingSM),
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

// ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Barra de ocupaÃƒÂ§ÃƒÂ£o dos caixas ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

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
        SizedBox(height: Dimensions.spacingSM),
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusSM),
          child: LinearProgressIndicator(
            value: progresso,
            minHeight: 10,
            backgroundColor: AppColors.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(corBarra),
          ),
        ),
        SizedBox(height: Dimensions.spacingMD),
        Divider(height: 1, color: AppColors.cardBorder),
        SizedBox(height: Dimensions.spacingMD),
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
            SizedBox(width: Dimensions.spacingMD),
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
            SizedBox(width: 8),
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


// ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Briefing de inÃƒÂ­cio de turno ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

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
    final presentes = turnosHoje.where((t) => !t.folga && !t.feriado).toList();
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

            // TÃƒÂ­tulo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.play_arrow_rounded,
                      color: AppColors.primary, size: 22),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Briefing do Turno', style: AppTextStyles.h3),
                    Text(
                      'In\u00edcio \u00e0s $horaFormatada',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),

            Expanded(
              child: ListView(
                controller: controller,
                children: [
                  // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Colaboradores presentes ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
                  _BriefingSection(
                    icon: Icons.people,
                    iconColor: AppColors.success,
                    collapsible: true,
                    title: 'Presentes hoje (${presentes.length})',
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

                  SizedBox(height: 12),

                  // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ De folga ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
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
                                      detalhe: t.feriado ? 'Feriado' : 'Folga',
                                      cor: AppColors.textSecondary,
                                    ))
                                .toList(),
                          ),
                  ),

                  SizedBox(height: 12),

                  // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Notas importantes ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
                  _BriefingSection(
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.orange,
                    title: 'Avisos importantes (${notasImportantes.length})',
                    child: notasImportantes.isEmpty
                        ? Text('Sem anota\u00e7\u00f5es importantes no momento',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary))
                        : Column(
                            children: notasImportantes
                                .map((n) => Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.orange
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.priority_high,
                                              size: 14, color: Colors.orange),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              n.titulo,
                                              style: TextStyle(
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

                  SizedBox(height: 20),
                ],
              ),
            ),

            // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ BotÃƒÂµes de aÃƒÂ§ÃƒÂ£o ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
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
                    icon: Icon(Icons.swap_horiz, size: 18),
                    label: Text('Ir para Alocar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmarInicio(context, presentes,
                        defolga, notasImportantes, horaFormatada),
                    icon: Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text('Confirmar In\u00edcio'),
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fiscalId = authProvider.user?.id ?? '';

    final resumo =
        'In\u00edcio de turno \u00e0s $horaFormatada\nPresentes: ${presentes.length} colaborador(es)';

    final pendencias = notasImportantes.isNotEmpty
        ? notasImportantes.map((n) => '- ${n.titulo}').join('\n')
        : 'Nenhuma pend\u00eancia registrada';

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
      mensagem:
          'Turno iniciado \u00e0s $horaFormatada - registrado na timeline',
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
                  SizedBox(width: 8),
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
                SizedBox(height: 10),
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
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome,
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
