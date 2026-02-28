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
import '../colaboradores/colaboradores_list_screen.dart';
import '../colaboradores/colaboradores_status_screen.dart';
import '../alocacao/alocacao_screen.dart';
import '../mapa/mapa_caixas_screen.dart';
import '../notificacoes/notificacoes_screen.dart';
import '../cafe/cafe_screen.dart';
import '../timeline/timeline_screen.dart';
import '../entregas/entregas_screen.dart';
import '../procedimentos/procedimentos_screen.dart';
import '../notas/notas_screen.dart';
import '../formularios/formularios_screen.dart';
import '../folga/folga_screen.dart';
import '../escala/escala_screen.dart';
import '../relatorio/relatorio_diario_screen.dart';
import '../profile/profile_screen.dart';
import '../../../data/services/seed_data_service.dart';
import 'widgets/clock_widget.dart';
import 'widgets/quick_action_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
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
              MaterialPageRoute(builder: (_) => const CafeScreen())),
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
    ];

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                saudacao,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              Text(primeiroNome, style: AppTextStyles.h3),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authProvider.signOut(),
            ),
          ],
          bottom: TabBar(
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
              const Tab(icon: Icon(Icons.home_outlined, size: 20), text: 'Início'),
              const Tab(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.apps_outlined, size: 20),
                  ],
                ),
                text: 'Principal',
              ),
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
        body: TabBarView(
          children: [
            // ── ABA 1: INÍCIO ───────────────────────────────────────────────
            RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(Dimensions.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ClockWidget(),
                    const SizedBox(height: Dimensions.spacingXL),

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
                                  color: const Color(0xFF8D6E63),
                                ),
                                const _StatDivider(),
                                _StatItem(
                                  icon: Icons.local_shipping,
                                  label: 'Em Rota',
                                  value: emRota.toString(),
                                  color: const Color(0xFFFF9800),
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
            ),

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
                        icon: Icons.swap_horiz,
                        label: 'Alocar',
                        color: AppColors.primary,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AlocacaoScreen(
                              fiscalId: authProvider.user?.id ?? '',
                            ),
                          ),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.grid_view,
                        label: 'Mapa / Caixas',
                        color: AppColors.statusIntervalo,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const MapaCaixasScreen()),
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
                        color: const Color(0xFF0097A7),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const RelatorioDiarioScreen()),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.calendar_month,
                        label: 'Escala',
                        color: const Color(0xFFE91E63),
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
                        icon: Icons.coffee,
                        label: 'Café',
                        color: const Color(0xFF8D6E63),
                        badge: cafeProvider.totalEmAtraso > 0
                            ? cafeProvider.totalEmAtraso.toString()
                            : null,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const CafeScreen()),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.local_shipping,
                        label: 'Entregas',
                        color: const Color(0xFFFF9800),
                        badge: entregaProvider.totalEmRota > 0
                            ? entregaProvider.totalEmRota.toString()
                            : null,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const EntregasScreen()),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.info,
                        label: 'Status',
                        color: const Color(0xFF00BCD4),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ColaboradoresStatusScreen()),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.note,
                        label: 'Anotações',
                        color: const Color(0xFFFF5722),
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
                        color: const Color(0xFF3F51B5),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const FormulariosScreen()),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.menu_book,
                        label: 'Procedimentos',
                        color: const Color(0xFF673AB7),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ProcedimentosScreen()),
                        ),
                      ),
                      _BotaoAcao(
                        icon: Icons.notifications,
                        label: 'Notificações',
                        color: const Color(0xFF2196F3),
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
                    if (fiscalProvider.fiscal != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(Dimensions.paddingMD),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Informações da Loja',
                                  style: AppTextStyles.h4),
                              const SizedBox(height: Dimensions.spacingMD),
                              _buildInfoRow(
                                  'Loja',
                                  fiscalProvider.fiscal!.loja ?? 'N/A'),
                              const Divider(height: 24),
                              _buildInfoRow(
                                  'Fiscal', fiscalProvider.fiscal!.nome),
                              const Divider(height: 24),
                              _buildInfoRow(
                                  'Email', fiscalProvider.fiscal!.email),
                              const Divider(height: 24),
                              _buildInfoRow(
                                'Status',
                                fiscalProvider.fiscal!.ativo
                                    ? 'Ativo'
                                    : 'Inativo',
                                valueColor: fiscalProvider.fiscal!.ativo
                                    ? AppColors.success
                                    : AppColors.danger,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: Dimensions.spacingMD),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(Dimensions.paddingMD),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Equipe', style: AppTextStyles.h4),
                              const SizedBox(height: Dimensions.spacingMD),
                              _buildInfoRow('Total ativos',
                                  totalAtivos.toString()),
                              const Divider(height: 24),
                              _buildInfoRow(
                                  'Caixas', totalCaixas.toString()),
                              const Divider(height: 24),
                              _buildInfoRow(
                                  'Alocados agora', alocados.toString()),
                              const Divider(height: 24),
                              _buildInfoRow('Em pausa', emPausa.toString()),
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
                    const SizedBox(height: Dimensions.spacingMD),
                    _GridAcoes(
                      botoes: [
                        _BotaoAcao(
                          icon: Icons.history,
                          label: 'Timeline',
                          color: const Color(0xFF9C27B0),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const TimelineScreen()),
                          ),
                        ),
                        _BotaoAcao(
                          icon: Icons.beach_access,
                          label: 'Modo Folga',
                          color: const Color(0xFF009688),
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
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        Text(
          value,
          style:
              AppTextStyles.h4.copyWith(color: valueColor ?? AppColors.textPrimary),
        ),
      ],
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
