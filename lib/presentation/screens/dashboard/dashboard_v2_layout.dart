import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/dashboard_quick_note_service.dart';
import '../../../domain/entities/caixa.dart';
import '../../widgets/common/operational_widgets.dart';

const _v2Primary = Color(0xFF0F766E);
const _v2Secondary = Color(0xFF14B8A6);
const _v2Success = Color(0xFF16A34A);
const _v2Warning = Color(0xFFF59E0B);
const _v2Danger = Color(0xFFDC2626);
const _v2Background = Color(0xFFF8FAFC);
const _v2Card = Color(0xFFFFFFFF);
const _v2Border = Color(0xFFE2E8F0);
const _v2Text = Color(0xFF0F172A);
const _v2Muted = Color(0xFF475569);
const _v2Subtle = Color(0xFF64748B);
const _quickNoteStorageKey = 'dashboard_quick_note_v1';

class DashboardV2NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int badgeCount;
  final bool showBadgeCount;

  const DashboardV2NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badgeCount = 0,
    this.showBadgeCount = false,
  });
}

class DashboardV2QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const DashboardV2QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });
}

class DashboardV2ReportItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const DashboardV2ReportItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color = _v2Text,
  });
}

class DashboardV2Shell extends StatelessWidget {
  final List<DashboardV2NavItem> navItems;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String userName;
  final String userRole;
  final int alertCount;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;
  final Widget child;

  const DashboardV2Shell({
    super.key,
    required this.navItems,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.userName,
    required this.userRole,
    required this.alertCount,
    required this.onSettings,
    required this.onSignOut,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _v2Background,
      body: Row(
        children: [
          _DashboardV2Sidebar(
            navItems: navItems,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            userName: userName,
            userRole: userRole,
            alertCount: alertCount,
            onSettings: onSettings,
            onSignOut: onSignOut,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class DashboardV2Home extends StatelessWidget {
  final String saudacao;
  final String primeiroNome;
  final bool turnoJaIniciado;
  final DateTime? turnoIniciadoEm;
  final bool turnoCritico;
  final bool turnoEmAtencao;
  final int totalAtivos;
  final int totalCaixas;
  final int alocados;
  final int livres;
  final int emPausa;
  final int emRota;
  final int alertas;
  final List<OperationalMetricData> metrics;
  final List<Caixa> caixas;
  final List<DashboardV2QuickAction> quickActions;
  final List<DashboardV2ReportItem> reportItems;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onAlertTap;
  final VoidCallback onReportTap;
  final VoidCallback onPizzariaTap;
  final VoidCallback onOperacoesTap;
  final VoidCallback onCaixasTap;
  final VoidCallback onCartazTap;
  final VoidCallback onDescontoTap;
  final VoidCallback onBalcaoTap;
  final VoidCallback onAiTap;
  final Future<void> Function() onRefresh;

  const DashboardV2Home({
    super.key,
    required this.saudacao,
    required this.primeiroNome,
    required this.turnoJaIniciado,
    required this.turnoIniciadoEm,
    required this.turnoCritico,
    required this.turnoEmAtencao,
    required this.totalAtivos,
    required this.totalCaixas,
    required this.alocados,
    required this.livres,
    required this.emPausa,
    required this.emRota,
    required this.alertas,
    required this.metrics,
    required this.caixas,
    required this.quickActions,
    required this.reportItems,
    required this.onPrimaryAction,
    required this.onAlertTap,
    required this.onReportTap,
    required this.onPizzariaTap,
    required this.onOperacoesTap,
    required this.onCaixasTap,
    required this.onCartazTap,
    required this.onDescontoTap,
    required this.onBalcaoTap,
    required this.onAiTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _v2Background,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: _v2Primary,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 900 ? 28.0 : 16.0;
            final isPhone = constraints.maxWidth < 600;
            final sectionGap = isPhone ? 12.0 : 20.0;

            if (isPhone) {
              return _MobileDashboardHome(
                saudacao: saudacao,
                primeiroNome: primeiroNome,
                turnoJaIniciado: turnoJaIniciado,
                turnoIniciadoEm: turnoIniciadoEm,
                turnoCritico: turnoCritico,
                turnoEmAtencao: turnoEmAtencao,
                totalAtivos: totalAtivos,
                totalCaixas: totalCaixas,
                alocados: alocados,
                livres: livres,
                alertas: alertas,
                onPrimaryAction: onPrimaryAction,
                onPizzariaTap: onPizzariaTap,
                onOperacoesTap: onOperacoesTap,
                onCaixasTap: onCaixasTap,
                onCartazTap: onCartazTap,
                onDescontoTap: onDescontoTap,
                onBalcaoTap: onBalcaoTap,
                onAiTap: onAiTap,
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isPhone ? 12 : 16,
                horizontalPadding,
                isPhone ? 18 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroDashboardSection(
                        saudacao: saudacao,
                        primeiroNome: primeiroNome,
                        turnoJaIniciado: turnoJaIniciado,
                        onPrimaryAction: onPrimaryAction,
                      ),
                      if (!isPhone ||
                          alertas > 0 ||
                          turnoCritico ||
                          turnoEmAtencao) ...[
                        SizedBox(height: sectionGap),
                        _DashboardAlertBanner(
                          alertas: alertas,
                          critico: turnoCritico,
                          atencao: turnoEmAtencao,
                          onTap: onAlertTap,
                          compact: isPhone,
                        ),
                      ],
                      SizedBox(height: sectionGap),
                      const _QuickNotePanel(),
                      SizedBox(height: sectionGap),
                      _OperationalMonitorCard(
                        caixas: caixas,
                        alertas: alertas,
                        turnoCritico: turnoCritico,
                        turnoEmAtencao: turnoEmAtencao,
                        compact: isPhone,
                      ),
                      SizedBox(height: sectionGap),
                      _DashboardMetricsGrid(
                        metrics: metrics,
                        compact: isPhone,
                      ),
                      SizedBox(height: sectionGap),
                      _DashboardBottomPanels(
                        quickActions: quickActions,
                        reportItems: reportItems,
                        onReportTap: onReportTap,
                        compact: isPhone,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MobileDashboardHome extends StatelessWidget {
  final String saudacao;
  final String primeiroNome;
  final bool turnoJaIniciado;
  final DateTime? turnoIniciadoEm;
  final bool turnoCritico;
  final bool turnoEmAtencao;
  final int totalAtivos;
  final int totalCaixas;
  final int alocados;
  final int livres;
  final int alertas;
  final VoidCallback onPrimaryAction;
  final VoidCallback onPizzariaTap;
  final VoidCallback onOperacoesTap;
  final VoidCallback onCaixasTap;
  final VoidCallback onCartazTap;
  final VoidCallback onDescontoTap;
  final VoidCallback onBalcaoTap;
  final VoidCallback onAiTap;

  const _MobileDashboardHome({
    required this.saudacao,
    required this.primeiroNome,
    required this.turnoJaIniciado,
    required this.turnoIniciadoEm,
    required this.turnoCritico,
    required this.turnoEmAtencao,
    required this.totalAtivos,
    required this.totalCaixas,
    required this.alocados,
    required this.livres,
    required this.alertas,
    required this.onPrimaryAction,
    required this.onPizzariaTap,
    required this.onOperacoesTap,
    required this.onCaixasTap,
    required this.onCartazTap,
    required this.onDescontoTap,
    required this.onBalcaoTap,
    required this.onAiTap,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _MobileStatItem(
        label: 'Equipe',
        value: totalAtivos.toString(),
        trend: '$alocados alocados',
        positive: true,
      ),
      _MobileStatItem(
        label: 'Caixas',
        value: totalCaixas.toString(),
        trend: '$livres livres',
        positive: livres > 0,
      ),
      _MobileStatItem(
        label: 'Alertas',
        value: alertas.toString(),
        trend: turnoCritico
            ? 'cr\u00edtico'
            : turnoEmAtencao
                ? 'aten\u00e7\u00e3o'
                : 'ok',
        positive: alertas == 0 && !turnoCritico,
      ),
    ];

    final modules = [
      _MobileModuleItem(
        title: 'IA Fiscal',
        subtitle: 'Assistente operacional',
        icon: Icons.smart_toy_rounded,
        color: const Color(0xFF7C3AED),
        background: const Color(0xFFEDE9FE),
        onTap: onAiTap,
        wide: true,
        badge: 'Online',
        badgeColor: const Color(0xFF10B981),
      ),
      _MobileModuleItem(
        title: 'Pizzaria',
        subtitle: 'Pedidos e card\u00e1pio',
        icon: Icons.local_pizza_rounded,
        color: const Color(0xFFD97706),
        background: const Color(0xFFFEF3C7),
        onTap: onPizzariaTap,
      ),
      _MobileModuleItem(
        title: 'Opera\u00e7\u00f5es',
        subtitle: 'Vis\u00e3o geral',
        icon: Icons.dashboard_customize_rounded,
        color: const Color(0xFF2563EB),
        background: const Color(0xFFDBEAFE),
        onTap: onOperacoesTap,
        badge: alertas > 0 ? '$alertas' : null,
        badgeColor: alertas > 0 ? _v2Danger : null,
      ),
      _MobileModuleItem(
        title: 'Caixas',
        subtitle: 'Central operacional',
        icon: Icons.point_of_sale_rounded,
        color: _v2Primary,
        background: const Color(0xFFDDF7F3),
        onTap: onCaixasTap,
      ),
      _MobileModuleItem(
        title: 'Cartaz',
        subtitle: 'Ofertas e campanhas',
        icon: Icons.local_offer_rounded,
        color: const Color(0xFFD6166A),
        background: const Color(0xFFFFE4EE),
        onTap: onCartazTap,
      ),
      _MobileModuleItem(
        title: 'Descontos',
        subtitle: 'Calculadora r\u00e1pida',
        icon: Icons.loyalty_rounded,
        color: const Color(0xFF059669),
        background: const Color(0xFFD1FAE5),
        onTap: onDescontoTap,
      ),
      _MobileModuleItem(
        title: 'Balc\u00e3o',
        subtitle: 'Atendimento fiscal',
        icon: Icons.point_of_sale_rounded,
        color: const Color(0xFF0284C7),
        background: const Color(0xFFE0F2FE),
        onTap: onBalcaoTap,
      ),
    ];

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MobileHomeHeader(
              saudacao: saudacao,
              primeiroNome: primeiroNome,
            ),
            const SizedBox(height: 16),
            _MobileTurnoCard(
              turnoJaIniciado: turnoJaIniciado,
              turnoIniciadoEm: turnoIniciadoEm,
              onTap: onPrimaryAction,
            ),
            const SizedBox(height: 14),
            const _QuickNotePanel(compact: true),
            const SizedBox(height: 16),
            _MobileStatsRow(stats: stats),
            const SizedBox(height: 18),
            _MobileBentoGrid(modules: modules),
          ],
        ),
      ),
    );
  }
}

class _MobileStatItem {
  final String label;
  final String value;
  final String trend;
  final bool positive;

  const _MobileStatItem({
    required this.label,
    required this.value,
    required this.trend,
    required this.positive,
  });
}

class _MobileModuleItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;
  final bool wide;
  final String? badge;
  final Color? badgeColor;

  const _MobileModuleItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
    this.wide = false,
    this.badge,
    this.badgeColor,
  });
}

class _MobileHomeHeader extends StatelessWidget {
  final String saudacao;
  final String primeiroNome;

  const _MobileHomeHeader({
    required this.saudacao,
    required this.primeiroNome,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child:
              const Icon(Icons.person_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$saudacao, $primeiroNome',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _textStyle(
                  size: 18,
                  color: const Color(0xFF1E293B),
                  weight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fiscal de Caixa',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _textStyle(
                  size: 13,
                  color: const Color(0xFF64748B),
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const _MobileDateTimePill(),
      ],
    );
  }
}

class _MobileDateTimePill extends StatefulWidget {
  const _MobileDateTimePill();

  @override
  State<_MobileDateTimePill> createState() => _MobileDateTimePillState();
}

class _MobileDateTimePillState extends State<_MobileDateTimePill> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _softShadow(Colors.black, opacity: 0.045, blur: 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('HH:mm').format(_now),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
              size: 18,
              color: const Color(0xFF1E293B),
              weight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _formatShortDate(_now),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
              size: 11,
              color: const Color(0xFF94A3B8),
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileTurnoCard extends StatelessWidget {
  final bool turnoJaIniciado;
  final DateTime? turnoIniciadoEm;
  final VoidCallback onTap;

  const _MobileTurnoCard({
    required this.turnoJaIniciado,
    required this.turnoIniciadoEm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = turnoJaIniciado ? _v2Success : _v2Primary;
    final title = turnoJaIniciado ? 'Turno em andamento' : 'Comecar turno';
    final subtitle = turnoJaIniciado && turnoIniciadoEm != null
        ? 'Iniciado as ${DateFormat('HH:mm').format(turnoIniciadoEm!)}'
        : 'Acompanhe a operacao de hoje';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.14)),
            boxShadow: _softShadow(Colors.black, opacity: 0.035, blur: 12),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  turnoJaIniciado
                      ? Icons.timeline_rounded
                      : Icons.play_arrow_rounded,
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle(
                        size: 14,
                        color: const Color(0xFF1E293B),
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle(
                        size: 12,
                        color: const Color(0xFF64748B),
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileStatsRow extends StatelessWidget {
  final List<_MobileStatItem> stats;

  const _MobileStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          Expanded(child: _MobileStatCard(stat: stats[i])),
          if (i < stats.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _MobileStatCard extends StatelessWidget {
  final _MobileStatItem stat;

  const _MobileStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final trendColor =
        stat.positive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _softShadow(Colors.black, opacity: 0.035, blur: 10),
      ),
      child: Column(
        children: [
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
              size: 18,
              color: const Color(0xFF1E293B),
              weight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
              size: 10,
              color: const Color(0xFF94A3B8),
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.trend,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
                size: 11, color: trendColor, weight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MobileBentoGrid extends StatelessWidget {
  final List<_MobileModuleItem> modules;

  const _MobileBentoGrid({required this.modules});

  @override
  Widget build(BuildContext context) {
    final wide = modules.where((module) => module.wide).toList();
    final grid = modules.where((module) => !module.wide).toList();

    return Column(
      children: [
        for (final module in wide)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MobileBentoCard(module: module, wide: true),
          ),
        for (var i = 0; i < grid.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(child: _MobileBentoCard(module: grid[i])),
                const SizedBox(width: 12),
                if (i + 1 < grid.length)
                  Expanded(child: _MobileBentoCard(module: grid[i + 1]))
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
      ],
    );
  }
}

class _MobileBentoCard extends StatelessWidget {
  final _MobileModuleItem module;
  final bool wide;

  const _MobileBentoCard({
    required this.module,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: module.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(wide ? 22 : 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            boxShadow: _softShadow(Colors.black, opacity: 0.03, blur: 15),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: module.background,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          module.icon,
                          color: module.color,
                          size: wide ? 28 : 22,
                        ),
                      ),
                      if (module.badge != null && module.badgeColor != null)
                        _MobileBadge(
                          label: module.badge!,
                          color: module.badgeColor!,
                        ),
                    ],
                  ),
                  SizedBox(height: wide ? 18 : 14),
                  Text(
                    module.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle(
                      size: wide ? 20 : 16,
                      color: const Color(0xFF1E293B),
                      weight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle(
                      size: 12,
                      color: const Color(0xFF94A3B8),
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MobileBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(size: 11, color: color, weight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DashboardV2Sidebar extends StatelessWidget {
  final List<DashboardV2NavItem> navItems;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String userName;
  final String userRole;
  final int alertCount;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;

  const _DashboardV2Sidebar({
    required this.navItems,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.userName,
    required this.userRole,
    required this.alertCount,
    required this.onSettings,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 204,
      decoration: const BoxDecoration(
        color: _v2Card,
        border: Border(right: BorderSide(color: _v2Border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _UserCard(
                userName: userName,
                userRole: userRole,
                onSettings: onSettings,
                onSignOut: onSignOut,
              ),
              const SizedBox(height: 22),
              Expanded(
                child: ListView.separated(
                  itemCount: navItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = navItems[index];
                    return _SidebarNavTile(
                      item: item,
                      selected: index == selectedIndex,
                      onTap: () => onDestinationSelected(index),
                    );
                  },
                ),
              ),
              _SupportTile(alertCount: alertCount),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Versao 2.0.0',
                    style: _textStyle(
                      size: 12,
                      color: _v2Subtle,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String userName;
  final String userRole;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;

  const _UserCard({
    required this.userName,
    required this.userRole,
    required this.onSettings,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 124),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_v2Primary, Color(0xFF0B8278), _v2Secondary],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _softShadow(_v2Primary, opacity: 0.18, blur: 22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withValues(alpha: 0.92),
                    child: const Icon(
                      Icons.person_rounded,
                      color: _v2Primary,
                      size: 26,
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle(
                        size: 15,
                        color: Colors.white,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userRole,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle(
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.82),
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFFBBF7D0),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Online',
                          style: _textStyle(
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.9),
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ProfileActionButton(
                  icon: Icons.settings_outlined,
                  label: 'Config.',
                  tooltip: 'Configuracoes',
                  onTap: onSettings,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProfileActionButton(
                  icon: Icons.logout_rounded,
                  label: 'Sair',
                  tooltip: 'Sair',
                  onTap: onSignOut,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;

  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle(
                      size: 11,
                      color: Colors.white,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  final DashboardV2NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? _v2Primary : const Color(0xFF334155);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE6F7F5) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 4,
                height: 26,
                decoration: BoxDecoration(
                  color: selected ? _v2Primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected ? item.selectedIcon : item.icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    size: 12.5,
                    color: color,
                    weight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (item.badgeCount > 0) ...[
                const SizedBox(width: 8),
                _MiniBadge(
                  value: item.showBadgeCount ? item.badgeCount.toString() : '',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final int alertCount;

  const _SupportTile({required this.alertCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: _v2Background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _v2Border),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent_rounded, color: _v2Muted, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ajuda e suporte',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _textStyle(
                size: 13,
                color: _v2Muted,
                weight: FontWeight.w700,
              ),
            ),
          ),
          if (alertCount > 0) _MiniBadge(value: alertCount.toString()),
        ],
      ),
    );
  }
}

class _HeroDashboardSection extends StatelessWidget {
  final String saudacao;
  final String primeiroNome;
  final bool turnoJaIniciado;
  final VoidCallback onPrimaryAction;

  const _HeroDashboardSection({
    required this.saudacao,
    required this.primeiroNome,
    required this.turnoJaIniciado,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: _HeroHeadline(
        saudacao: saudacao,
        primeiroNome: primeiroNome,
        turnoJaIniciado: turnoJaIniciado,
        onPrimaryAction: onPrimaryAction,
      ),
    );
  }
}

class _LiveDatePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return _SoftPill(
      icon: Icons.wb_sunny_outlined,
      iconColor: _v2Warning,
      label: _capitalize(_formatDate(now)),
    );
  }
}

class _LiveClockPill extends StatefulWidget {
  @override
  State<_LiveClockPill> createState() => _LiveClockPillState();
}

class _LiveClockPillState extends State<_LiveClockPill> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SoftPill(
      icon: Icons.schedule_rounded,
      iconColor: const Color(0xFF1E3A8A),
      label: DateFormat('HH:mm').format(_now),
    );
  }
}

class _HeroHeadline extends StatelessWidget {
  final String saudacao;
  final String primeiroNome;
  final bool turnoJaIniciado;
  final VoidCallback onPrimaryAction;

  const _HeroHeadline({
    required this.saudacao,
    required this.primeiroNome,
    required this.turnoJaIniciado,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final buttonLabel = turnoJaIniciado ? 'Abrir timeline' : 'Comecar turno';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final title = Text(
          '$saudacao, $primeiroNome!',
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: _textStyle(
            size: compact ? 28 : 34,
            color: _v2Text,
            weight: FontWeight.w900,
            height: 1.08,
          ),
        );
        final meta = Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _LiveDatePill(),
            _LiveClockPill(),
          ],
        );
        final action = SizedBox(
          width: compact ? double.infinity : 220,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: onPrimaryAction,
            icon: Icon(
              turnoJaIniciado
                  ? Icons.timeline_rounded
                  : Icons.play_arrow_rounded,
              size: 22,
            ),
            label: Text(
              buttonLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _v2Primary,
              foregroundColor: Colors.white,
              textStyle: _textStyle(size: 16, weight: FontWeight.w900),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 14),
              meta,
              const SizedBox(height: 16),
              action,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 14),
                  meta,
                ],
              ),
            ),
            const SizedBox(width: 24),
            action,
          ],
        );
      },
    );
  }
}

class _DashboardAlertBanner extends StatelessWidget {
  final int alertas;
  final bool critico;
  final bool atencao;
  final VoidCallback? onTap;
  final bool compact;

  const _DashboardAlertBanner({
    required this.alertas,
    required this.critico,
    required this.atencao,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasAlert = alertas > 0;
    final color = critico
        ? _v2Danger
        : hasAlert || atencao
            ? const Color(0xFFC2410C)
            : _v2Success;
    final background =
        hasAlert || atencao ? const Color(0xFFFFFBF5) : const Color(0xFFF0FDF4);
    final border =
        hasAlert || atencao ? const Color(0xFFFED7AA) : const Color(0xFFBBF7D0);
    final title = hasAlert
        ? '$alertas alerta${alertas > 1 ? 's' : ''} precisa${alertas > 1 ? 'm' : ''} de atencao'
        : 'Operacao estavel';
    final message = hasAlert
        ? 'Ha ocorrencias, entregas ou checklist pendentes.'
        : 'Nenhuma acao urgente no momento.';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasAlert ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 64 : 88),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 22,
            vertical: compact ? 12 : 18,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              _IconBubble(
                icon: hasAlert
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_rounded,
                color: color,
                size: compact ? 36 : 48,
                iconSize: compact ? 22 : 30,
              ),
              SizedBox(width: compact ? 10 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle(
                        size: compact ? 13 : 16,
                        color: color,
                        weight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: compact ? 2 : 4),
                    Text(
                      message,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle(
                        size: compact ? 12 : 14,
                        color: _v2Muted,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 8 : 14),
              if (hasAlert && compact)
                Icon(Icons.chevron_right_rounded, color: color)
              else if (hasAlert)
                OutlinedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Ver detalhes'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withValues(alpha: 0.28)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    minimumSize: const Size(140, 48),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardMetricsGrid extends StatelessWidget {
  final List<OperationalMetricData> metrics;
  final bool compact;

  const _DashboardMetricsGrid({
    required this.metrics,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = compact
            ? 2
            : width >= 1200
                ? 6
                : width >= 920
                    ? 5
                    : width >= 720
                        ? 4
                        : width >= 520
                            ? 3
                            : 2;

        return GridView.builder(
          itemCount: metrics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: compact ? 10 : 12,
            mainAxisSpacing: compact ? 10 : 12,
            mainAxisExtent: compact ? 96 : 112,
          ),
          itemBuilder: (context, index) {
            return _MetricV2Card(
              metric: metrics[index],
              compact: compact,
            );
          },
        );
      },
    );
  }
}

class _MetricV2Card extends StatelessWidget {
  final OperationalMetricData metric;
  final bool compact;

  const _MetricV2Card({
    required this.metric,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 10 : 11,
      ),
      decoration: _cardDecoration(
        borderColor: metric.color.withValues(alpha: 0.24),
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              _IconBubble(
                icon: metric.icon,
                color: metric.color,
                size: compact ? 30 : 34,
                iconSize: compact ? 16 : 18,
              ),
              const Spacer(),
              if (metric.onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: metric.color,
                  size: compact ? 18 : 20,
                ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
              size: compact ? 22 : 25,
              color: metric.color,
              weight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
              size: compact ? 11 : 12.5,
              color: _v2Text,
              weight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: compact ? 12 : 14,
                color: metric.color,
              ),
              SizedBox(width: compact ? 4 : 6),
              Expanded(
                child: Text(
                  metric.helper ?? 'Em operacao',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    size: compact ? 10 : 11.5,
                    color: _v2Subtle,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (metric.onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: metric.onTap,
        borderRadius: BorderRadius.circular(14),
        child: content,
      ),
    );
  }
}

class _OperationalMonitorCard extends StatelessWidget {
  final List<Caixa> caixas;
  final int alertas;
  final bool turnoCritico;
  final bool turnoEmAtencao;
  final bool compact;

  const _OperationalMonitorCard({
    required this.caixas,
    required this.alertas,
    required this.turnoCritico,
    required this.turnoEmAtencao,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCaixas = caixas.take(compact ? 3 : 5).toList();
    final hiddenCount = caixas.length - visibleCaixas.length;
    final statusColor = turnoCritico
        ? _v2Danger
        : turnoEmAtencao
            ? _v2Warning
            : _v2Success;
    final statusLabel = turnoCritico
        ? 'Critico'
        : turnoEmAtencao
            ? 'Atencao'
            : 'Estavel';

    return _V2Card(
      padding: EdgeInsets.all(compact ? 14 : 20),
      radius: compact ? 16 : 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBubble(
                icon: Icons.monitor_heart_outlined,
                color: _v2Primary,
                size: compact ? 28 : 32,
                iconSize: compact ? 16 : 18,
              ),
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Text(
                  'Monitor em tempo real',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    size: compact ? 15 : 18,
                    color: _v2Text,
                    weight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(
                icon: Icons.circle,
                label: statusLabel,
                color: statusColor,
                compact: true,
              ),
              SizedBox(width: compact ? 4 : 8),
              Icon(
                Icons.chevron_right_rounded,
                color: _v2Primary,
                size: compact ? 20 : 24,
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 860;
              final summary = _MonitorSummary(
                alertas: alertas,
                color: statusColor,
                statusLabel: statusLabel,
                compact: compact,
              );
              final caixasRow = _MonitorCaixasRow(
                caixas: visibleCaixas,
                hiddenCount: hiddenCount,
                compact: compact,
              );

              if (!isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    summary,
                    SizedBox(height: compact ? 12 : 18),
                    caixasRow,
                  ],
                );
              }

              return Row(
                children: [
                  SizedBox(width: 420, child: summary),
                  Container(width: 1, height: 70, color: _v2Border),
                  const SizedBox(width: 20),
                  Expanded(child: caixasRow),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MonitorSummary extends StatelessWidget {
  final int alertas;
  final Color color;
  final String statusLabel;
  final bool compact;

  const _MonitorSummary({
    required this.alertas,
    required this.color,
    required this.statusLabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = alertas > 0
        ? '$alertas ponto${alertas > 1 ? 's' : ''} exige${alertas > 1 ? 'm' : ''} atencao'
        : 'Tudo em ordem, nenhum alerta no momento';
    final subtitle = alertas > 0
        ? 'Priorize as rotinas pendentes da operacao.'
        : 'Sua operacao esta fluindo bem.';

    return Row(
      children: [
        Icon(
          alertas > 0 ? Icons.priority_high_rounded : Icons.check_circle,
          color: color,
          size: compact ? 26 : 34,
        ),
        SizedBox(width: compact ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: _textStyle(
                  size: compact ? 12 : 14,
                  color: color,
                  weight: FontWeight.w900,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    size: 13,
                    color: _v2Muted,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MonitorCaixasRow extends StatelessWidget {
  final List<Caixa> caixas;
  final int hiddenCount;
  final bool compact;

  const _MonitorCaixasRow({
    required this.caixas,
    required this.hiddenCount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (caixas.isEmpty) {
      return Container(
        constraints: BoxConstraints(minHeight: compact ? 52 : 64),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _v2Background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _v2Border),
        ),
        child: Text(
          'Nenhum caixa carregado',
          style:
              _textStyle(size: 13, color: _v2Subtle, weight: FontWeight.w700),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final caixa in caixas) ...[
            _CaixaStatusTile(caixa: caixa, compact: compact),
            SizedBox(width: compact ? 8 : 12),
          ],
          if (hiddenCount > 0)
            _MoreCaixasTile(hiddenCount: hiddenCount, compact: compact),
        ],
      ),
    );
  }
}

class _CaixaStatusTile extends StatelessWidget {
  final Caixa caixa;
  final bool compact;

  const _CaixaStatusTile({
    required this.caixa,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = _caixaStatus(caixa);

    return Container(
      width: compact ? 112 : 140,
      height: compact ? 54 : 64,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: Text(
                  _formatCaixaName(caixa),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    size: compact ? 11.5 : 13,
                    color: _v2Text,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 4 : 7),
          Text(
            status.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
              size: compact ? 10.5 : 12,
              color: status.color,
              weight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreCaixasTile extends StatelessWidget {
  final int hiddenCount;
  final bool compact;

  const _MoreCaixasTile({
    required this.hiddenCount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 64 : 86,
      height: compact ? 54 : 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _v2Border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '+$hiddenCount',
            style: _textStyle(
              size: compact ? 13 : 15,
              color: _v2Text,
              weight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            'Caixas',
            style: _textStyle(
              size: compact ? 10.5 : 12,
              color: _v2Muted,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBottomPanels extends StatelessWidget {
  final List<DashboardV2QuickAction> quickActions;
  final List<DashboardV2ReportItem> reportItems;
  final VoidCallback onReportTap;
  final bool compact;

  const _DashboardBottomPanels({
    required this.quickActions,
    required this.reportItems,
    required this.onReportTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return _RoutinesPanel(
      quickActions: compact ? quickActions.take(4).toList() : quickActions,
      compact: compact,
      trailing: _QuickReportButton(
        items: reportItems,
        onReportTap: onReportTap,
        compact: compact,
      ),
    );
  }
}

class _QuickNotePanel extends StatefulWidget {
  final bool compact;

  const _QuickNotePanel({this.compact = false});

  @override
  State<_QuickNotePanel> createState() => _QuickNotePanelState();
}

class _QuickNotePanelState extends State<_QuickNotePanel> {
  final _controller = TextEditingController();
  List<DashboardQuickNote> _notes = const [];
  bool _loaded = false;
  bool _saving = false;
  String? _syncError;

  @override
  void initState() {
    super.initState();
    unawaited(_loadNotes());
  }

  Future<void> _loadNotes() async {
    try {
      await _migrateLocalNotesIfNeeded();
      final notes = await DashboardQuickNoteService.listar();

      if (!mounted) return;
      setState(() {
        _notes = notes;
        _loaded = true;
        _syncError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loaded = true;
        _syncError = 'Nao foi possivel sincronizar as notas.';
      });
    }
  }

  Future<void> _migrateLocalNotesIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    const migratedKey = '${_quickNoteStorageKey}_supabase_migrated';
    if (prefs.getBool(migratedKey) == true) return;

    final legacyNotes =
        _decodeLegacyNotes(prefs.getString(_quickNoteStorageKey));
    if (legacyNotes.isNotEmpty) {
      for (final note in legacyNotes.reversed) {
        await DashboardQuickNoteService.salvar(note);
      }
    }

    await prefs.remove(_quickNoteStorageKey);
    await prefs.setBool(migratedKey, true);
  }

  List<String> _decodeLegacyNotes(String? rawValue) {
    final trimmed = rawValue?.trim();
    if (trimmed == null || trimmed.isEmpty) return const [];

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        return decoded
            .map((item) => item is Map ? item['text'] : item)
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // The previous version saved one plain text note in this same key.
    }

    return [trimmed];
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _createNote() async {
    if (_saving) return;
    final note = _controller.text.trim();
    if (note.isEmpty) {
      _showMessage('Escreva uma nota antes.');
      return;
    }

    setState(() => _saving = true);
    try {
      final saved = await DashboardQuickNoteService.salvar(note);
      if (!mounted) return;
      setState(() {
        _notes = [saved, ..._notes];
        _controller.clear();
        _syncError = null;
      });
      _showMessage('Nota salva no Supabase.');
    } catch (e) {
      _showMessage('Nao foi possivel salvar a nota.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copyNote(DashboardQuickNote note) async {
    await Clipboard.setData(ClipboardData(text: note.text));
    _showMessage('Nota copiada.');
  }

  Future<void> _shareNote(DashboardQuickNote note) async {
    await Share.share(note.text, subject: 'Nota rapida');
  }

  Future<void> _deleteNote(DashboardQuickNote note) async {
    final previousNotes = _notes;
    final nextNotes = _notes.where((item) => item.id != note.id).toList();
    setState(() => _notes = nextNotes);
    try {
      await DashboardQuickNoteService.excluir(note.id);
      _showMessage('Nota removida.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _notes = previousNotes);
      _showMessage('Nao foi possivel remover a nota.');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;

    return _V2Card(
      padding: EdgeInsets.all(compact ? 14 : 18),
      radius: compact ? 16 : 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionTitle(
                  icon: Icons.sticky_note_2_outlined,
                  title: 'Nota rapida',
                  compact: compact,
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              _SoftPill(
                icon: Icons.note_alt_outlined,
                iconColor: _v2Primary,
                label: _loaded ? '${_notes.length}' : '...',
              ),
            ],
          ),
          if (_syncError != null) ...[
            SizedBox(height: compact ? 8 : 10),
            _QuickNoteSyncError(
              message: _syncError!,
              compact: compact,
              onRetry: _loadNotes,
            ),
          ],
          SizedBox(height: compact ? 10 : 12),
          TextField(
            controller: _controller,
            minLines: compact ? 2 : 2,
            maxLines: compact ? 3 : 4,
            maxLength: 360,
            textInputAction: TextInputAction.newline,
            style: _textStyle(
              size: compact ? 13 : 14,
              color: _v2Text,
              weight: FontWeight.w700,
              height: 1.3,
            ),
            decoration: InputDecoration(
              hintText: 'Escreva um lembrete rapido...',
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 14,
                vertical: compact ? 11 : 13,
              ),
              hintStyle: _textStyle(
                size: compact ? 13 : 14,
                color: _v2Subtle,
                weight: FontWeight.w600,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _v2Border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _v2Border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _v2Primary, width: 1.4),
              ),
            ),
          ),
          SizedBox(height: compact ? 10 : 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: compact ? 42 : 46,
                  child: FilledButton.icon(
                    onPressed: _loaded && !_saving ? _createNote : null,
                    icon: Icon(
                      _saving ? Icons.sync_rounded : Icons.add_rounded,
                      size: 18,
                    ),
                    label: Text(_saving ? 'Salvando...' : 'Salvar nota'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _v2Primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: _textStyle(
                        size: compact ? 12 : 13,
                        weight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              _QuickNoteIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Limpar texto',
                compact: compact,
                onPressed: () {
                  if (_controller.text.isEmpty) return;
                  _controller.clear();
                  setState(() {});
                },
              ),
            ],
          ),
          if (_notes.isNotEmpty) ...[
            SizedBox(height: compact ? 12 : 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = compact
                    ? 1
                    : width >= 1000
                        ? 3
                        : width >= 640
                            ? 2
                            : 1;

                return GridView.builder(
                  itemCount: _notes.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: compact ? 10 : 12,
                    mainAxisSpacing: compact ? 10 : 12,
                    mainAxisExtent: compact ? 128 : 136,
                  ),
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return _QuickNoteCard(
                      note: note,
                      compact: compact,
                      onCopy: () => _copyNote(note),
                      onShare: () => _shareNote(note),
                      onDelete: () => _deleteNote(note),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickNoteCard extends StatelessWidget {
  final DashboardQuickNote note;
  final bool compact;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _QuickNoteCard({
    required this.note,
    required this.onCopy,
    required this.onShare,
    required this.onDelete,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM HH:mm').format(note.createdAt);

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _v2Border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    size: compact ? 11 : 12,
                    color: _v2Subtle,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              _QuickNoteIconButton(
                icon: Icons.content_copy_rounded,
                tooltip: 'Copiar nota',
                compact: true,
                onPressed: onCopy,
              ),
              const SizedBox(width: 6),
              _QuickNoteIconButton(
                icon: Icons.ios_share_rounded,
                tooltip: 'Compartilhar nota',
                compact: true,
                onPressed: onShare,
              ),
              const SizedBox(width: 6),
              _QuickNoteIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Excluir nota',
                compact: true,
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              note.text,
              maxLines: compact ? 3 : 4,
              overflow: TextOverflow.ellipsis,
              style: _textStyle(
                size: compact ? 12.5 : 13.5,
                color: _v2Text,
                weight: FontWeight.w700,
                height: 1.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickNoteSyncError extends StatelessWidget {
  final String message;
  final bool compact;
  final VoidCallback onRetry;

  const _QuickNoteSyncError({
    required this.message,
    required this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: _v2Warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _v2Warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: _v2Warning,
            size: compact ? 16 : 18,
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _textStyle(
                size: compact ? 12 : 13,
                color: _v2Text,
                weight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _QuickNoteIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Tentar sincronizar',
            compact: true,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _QuickNoteIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool compact;
  final VoidCallback onPressed;

  const _QuickNoteIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 38.0;

    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: size,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: compact ? 17 : 18),
          color: _v2Primary,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFEFFDF9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
              side: const BorderSide(color: Color(0xFFD0F2EA)),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutinesPanel extends StatelessWidget {
  final List<DashboardV2QuickAction> quickActions;
  final bool compact;
  final Widget? trailing;

  const _RoutinesPanel({
    required this.quickActions,
    this.compact = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return _V2Card(
      padding: EdgeInsets.all(compact ? 14 : 20),
      radius: compact ? 16 : 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionTitle(
                  icon: Icons.grid_view_rounded,
                  title: compact ? 'Atalhos' : 'Rotinas principais',
                  compact: compact,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
          SizedBox(height: compact ? 12 : 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = compact
                  ? 2
                  : width >= 1180
                      ? 5
                      : width >= 900
                          ? 4
                          : width >= 620
                              ? 3
                              : width >= 420
                                  ? 2
                                  : 1;

              return GridView.builder(
                itemCount: quickActions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: compact ? 10 : 12,
                  mainAxisSpacing: compact ? 10 : 12,
                  mainAxisExtent: compact ? 62 : 68,
                ),
                itemBuilder: (context, index) {
                  return _QuickActionTile(
                    action: quickActions[index],
                    compact: compact,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final DashboardV2QuickAction action;
  final bool compact;

  const _QuickActionTile({
    required this.action,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 9 : 10,
          ),
          decoration: BoxDecoration(
            color: _v2Card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _v2Border),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _IconBubble(
                    icon: action.icon,
                    color: action.color,
                    size: compact ? 34 : 38,
                    iconSize: compact ? 17 : 19,
                  ),
                  if (action.badge != null)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: _MiniBadge(value: action.badge!),
                    ),
                ],
              ),
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle(
                        size: compact ? 11.5 : 12.5,
                        color: _v2Text,
                        weight: FontWeight.w900,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 3),
                      Text(
                        action.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _textStyle(
                          size: 12,
                          color: _v2Subtle,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: compact ? 4 : 8),
              Icon(
                Icons.chevron_right_rounded,
                color: _v2Muted.withValues(alpha: 0.8),
                size: compact ? 18 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickReportButton extends StatelessWidget {
  final List<DashboardV2ReportItem> items;
  final VoidCallback onReportTap;
  final bool compact;

  const _QuickReportButton({
    required this.items,
    required this.onReportTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 38 : 42,
      child: OutlinedButton.icon(
        onPressed: () => _showQuickReport(context),
        icon: const Icon(Icons.bar_chart_rounded, size: 18),
        label: Text(compact ? 'Relatorio' : 'Relatorio rapido'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _v2Primary,
          side: const BorderSide(color: _v2Border),
          backgroundColor: const Color(0xFFF6FEFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
          textStyle:
              _textStyle(size: compact ? 12 : 13, weight: FontWeight.w900),
        ),
      ),
    );
  }

  void _showQuickReport(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _QuickReportDialog(
          items: items,
          onOpenFullReport: () {
            Navigator.of(dialogContext).pop();
            onReportTap();
          },
        );
      },
    );
  }
}

class _QuickReportDialog extends StatelessWidget {
  final List<DashboardV2ReportItem> items;
  final VoidCallback onOpenFullReport;

  const _QuickReportDialog({
    required this.items,
    required this.onOpenFullReport,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 460, maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: _SectionTitle(
                        icon: Icons.bar_chart_rounded,
                        title: 'Relatorio rapido',
                      ),
                    ),
                    const _SoftPill(
                      label: 'Hoje',
                      icon: Icons.today_outlined,
                      iconColor: _v2Muted,
                      trailingIcon: false,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  Container(
                    constraints: const BoxConstraints(minHeight: 92),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _v2Background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _v2Border),
                    ),
                    child: Text(
                      'Nenhuma informacao carregada para hoje.',
                      textAlign: TextAlign.center,
                      style: _textStyle(
                        size: 13,
                        color: _v2Muted,
                        weight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  for (final item in items) ...[
                    _ReportRow(item: item),
                    const SizedBox(height: 8),
                  ],
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onOpenFullReport,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Ver relatorio completo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _v2Primary,
                      side: const BorderSide(color: _v2Border),
                      backgroundColor: const Color(0xFFF6FEFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: _textStyle(size: 13, weight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final DashboardV2ReportItem item;

  const _ReportRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 16, color: item.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  _textStyle(size: 13, color: _v2Text, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
                size: 13, color: item.color, weight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool compact;

  const _SectionTitle({
    required this.icon,
    required this.title,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBubble(
          icon: icon,
          color: _v2Primary,
          size: compact ? 28 : 32,
          iconSize: compact ? 16 : 18,
        ),
        SizedBox(width: compact ? 9 : 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
              size: compact ? 14 : 16,
              color: _v2Text,
              weight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool compact;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: compact ? 12 : 18),
          const SizedBox(width: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
              size: compact ? 12 : 13,
              color: color,
              weight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool trailingIcon;

  const _SoftPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.trailingIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _v2Border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingIcon) ...[
            Icon(icon, size: 17, color: iconColor),
            const SizedBox(width: 9),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                _textStyle(size: 13, color: _v2Muted, weight: FontWeight.w700),
          ),
          if (!trailingIcon) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 17, color: iconColor),
          ],
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const _IconBubble({
    required this.icon,
    required this.color,
    this.size = 42,
    this.iconSize = 21,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String value;

  const _MiniBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: const BoxDecoration(
        color: _v2Danger,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      alignment: Alignment.center,
      child: Text(
        value.isEmpty ? '!' : value,
        style:
            _textStyle(size: 10, color: Colors.white, weight: FontWeight.w900),
      ),
    );
  }
}

class _V2Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const _V2Card({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: _cardDecoration(radius: radius),
      child: child,
    );
  }
}

BoxDecoration _cardDecoration({
  Color borderColor = _v2Border,
  double radius = 20,
}) {
  return BoxDecoration(
    color: _v2Card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor),
    boxShadow: _softShadow(Colors.black, opacity: 0.055, blur: 20),
  );
}

List<BoxShadow> _softShadow(
  Color color, {
  required double opacity,
  required double blur,
}) {
  return [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: blur,
      offset: const Offset(0, 4),
    ),
  ];
}

TextStyle _textStyle({
  double size = 14,
  Color color = _v2Text,
  FontWeight weight = FontWeight.w600,
  double? height,
}) {
  return TextStyle(
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
    letterSpacing: 0,
  );
}

_CaixaStatus _caixaStatus(Caixa caixa) {
  if (caixa.emManutencao) {
    return const _CaixaStatus('Manutencao', _v2Danger);
  }
  if (!caixa.ativo) {
    return const _CaixaStatus('Inativo', Color(0xFF64748B));
  }
  if (caixa.colaboradorAlocadoId != null) {
    return const _CaixaStatus('Alocado', _v2Success);
  }
  return const _CaixaStatus('Ativo', _v2Success);
}

String _formatCaixaName(Caixa caixa) {
  return 'Caixa ${caixa.numero.toString().padLeft(2, '0')}';
}

String _formatDate(DateTime date) {
  try {
    return DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(date);
  } catch (_) {
    return DateFormat("EEEE, d 'de' MMMM").format(date);
  }
}

String _formatShortDate(DateTime date) {
  const weekdays = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sab'];
  const months = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  return '${weekdays[date.weekday % 7]}, ${date.day} ${months[date.month - 1]}';
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

class _CaixaStatus {
  final String label;
  final Color color;

  const _CaixaStatus(this.label, this.color);
}
