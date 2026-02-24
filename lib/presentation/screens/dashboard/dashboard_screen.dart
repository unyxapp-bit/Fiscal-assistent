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
import '../../providers/snapshot_provider.dart';
import '../colaboradores/colaboradores_list_screen.dart';
import '../colaboradores/colaboradores_status_screen.dart';
import '../caixas/caixas_list_screen.dart';
import '../alocacao/alocacao_screen.dart';
import '../mapa/mapa_caixas_screen.dart';
import '../notificacoes/notificacoes_screen.dart';
import '../cafe/cafe_screen.dart';
import '../timeline/timeline_screen.dart';
import '../entregas/entregas_screen.dart';
import '../procedimentos/procedimentos_screen.dart';
import '../notas/notas_screen.dart';
import '../formularios/formularios_screen.dart';
import '../snapshot/snapshot_screen.dart';
import '../folga/folga_screen.dart';
import '../escala/escala_screen.dart';
import '../relatorio/relatorio_diario_screen.dart';
import '../profile/profile_screen.dart';
import '../../../data/services/seed_data_service.dart';
import 'widgets/clock_widget.dart';
import 'widgets/quick_action_button.dart';

/// Tela principal - Dashboard
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

    // Seed de dados iniciais (primeira vez)
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
      Provider.of<SnapshotProvider>(context, listen: false).load(),
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
    final snapshotProvider = Provider.of<SnapshotProvider>(context);

    final saudacao = _getSaudacao();
    final nome = fiscalProvider.fiscal?.nome ??
        authProvider.user?.email ??
        'Usuário';
    final primeiroNome = nome.split(' ').first;

    // ── Estatísticas ────────────────────────────────────────────────────────
    final totalAtivos = colaboradorProvider.totalAtivos;
    final totalCaixas = caixaProvider.totalAtivos;
    final alocados = alocacaoProvider.quantidadeAtivasAgora;
    final livres = (totalCaixas - alocados).clamp(0, 999);
    final emPausa = cafeProvider.totalAtivos;
    final emRota = entregaProvider.totalEmRota;

    // ── Alertas ─────────────────────────────────────────────────────────────
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
      if (snapshotProvider.snapshotAtual == null)
        _AlertItem(
          icon: Icons.how_to_reg,
          label: 'Check-in de presença não realizado hoje',
          color: AppColors.statusAtencao,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SnapshotScreen())),
        ),
      if (snapshotProvider.totalAusentes > 0)
        _AlertItem(
          icon: Icons.person_off,
          label:
              '${snapshotProvider.totalAusentes} colaborador${snapshotProvider.totalAusentes > 1 ? 'es ausentes' : ' ausente'}',
          color: AppColors.danger,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SnapshotScreen())),
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
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              saudacao,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
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
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Relógio ─────────────────────────────────────────────────
              const ClockWidget(),

              const SizedBox(height: Dimensions.spacingXL),

              // ── Card de estatísticas ─────────────────────────────────────
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

              const SizedBox(height: Dimensions.spacingMD),

              // ── Card de alertas ──────────────────────────────────────────
              if (alertas.isNotEmpty) ...[
                Column(
                  children: alertas
                      .map((a) => _AlertCard(item: a))
                      .toList(),
                ),
                const SizedBox(height: Dimensions.spacingMD),
              ],

              // ── Ações Principais ─────────────────────────────────────────
              const Text('Principais', style: AppTextStyles.h3),
              const SizedBox(height: Dimensions.spacingMD),

              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
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
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.grid_view,
                      label: 'Mapa',
                      color: AppColors.statusIntervalo,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const MapaCaixasScreen()),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.spacingSM),

              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.people,
                      label: 'Colaboradores',
                      color: AppColors.statusAtivo,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ColaboradoresListScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.point_of_sale,
                      label: 'Caixas',
                      color: AppColors.success,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const CaixasListScreen()),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.spacingMD),

              // ── Operações ────────────────────────────────────────────────
              const Text('Operações', style: AppTextStyles.h3),
              const SizedBox(height: Dimensions.spacingMD),

              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.coffee,
                      label: 'Café',
                      color: const Color(0xFF8D6E63),
                      badge: cafeProvider.totalEmAtraso > 0
                          ? cafeProvider.totalEmAtraso.toString()
                          : null,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CafeScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: QuickActionButton(
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
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.spacingSM),

              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.how_to_reg,
                      label: 'Snapshot',
                      color: const Color(0xFF4CAF50),
                      badge: snapshotProvider.totalPendentes > 0
                          ? snapshotProvider.totalPendentes.toString()
                          : null,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SnapshotScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.info,
                      label: 'Status',
                      color: const Color(0xFF00BCD4),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                const ColaboradoresStatusScreen()),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.spacingSM),

              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.note,
                      label: 'Anotações',
                      color: const Color(0xFFFF5722),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotasScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.description,
                      label: 'Formulários',
                      color: const Color(0xFF3F51B5),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const FormulariosScreen()),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.spacingSM),

              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.menu_book,
                      label: 'Procedimentos',
                      color: const Color(0xFF673AB7),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ProcedimentosScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.notifications,
                      label: 'Notificações',
                      color: const Color(0xFF2196F3),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const NotificacoesScreen()),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.spacingSM),

              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.history,
                      label: 'Timeline',
                      color: const Color(0xFF9C27B0),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const TimelineScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.calendar_month,
                      label: 'Escala',
                      color: const Color(0xFFE91E63),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const EscalaScreen()),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.spacingSM),

              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.beach_access,
                      label: 'Modo Folga',
                      color: const Color(0xFF009688),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const FolgaScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSM),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.bar_chart,
                      label: 'Relatório',
                      color: const Color(0xFF0097A7),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RelatorioDiarioScreen()),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.spacingXL),

              // ── Status da Loja ───────────────────────────────────────────
              if (fiscalProvider.fiscal != null) ...[
                const Text('Status da Loja', style: AppTextStyles.h3),
                const SizedBox(height: Dimensions.spacingMD),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingMD),
                    child: Column(
                      children: [
                        _buildInfoRow(
                            'Loja', fiscalProvider.fiscal!.loja ?? 'N/A'),
                        const Divider(height: 24),
                        _buildInfoRow('Email', fiscalProvider.fiscal!.email),
                        const Divider(height: 24),
                        _buildInfoRow(
                          'Status',
                          fiscalProvider.fiscal!.ativo ? 'Ativo' : 'Inativo',
                          valueColor: fiscalProvider.fiscal!.ativo
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
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
          style: AppTextStyles.h4.copyWith(
              color: valueColor ?? AppColors.textPrimary),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            Icon(Icons.arrow_forward_ios,
                color: item.color, size: 13),
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
