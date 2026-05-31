import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                28,
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
                        turnoIniciadoEm: turnoIniciadoEm,
                        totalAtivos: totalAtivos,
                        totalCaixas: totalCaixas,
                        alocados: alocados,
                        livres: livres,
                        emPausa: emPausa,
                        emRota: emRota,
                        alertas: alertas,
                        onPrimaryAction: onPrimaryAction,
                      ),
                      const SizedBox(height: 20),
                      _DashboardAlertBanner(
                        alertas: alertas,
                        critico: turnoCritico,
                        atencao: turnoEmAtencao,
                        onTap: onAlertTap,
                      ),
                      const SizedBox(height: 20),
                      _DashboardMetricsGrid(metrics: metrics),
                      const SizedBox(height: 20),
                      _OperationalMonitorCard(
                        caixas: caixas,
                        alertas: alertas,
                        turnoCritico: turnoCritico,
                        turnoEmAtencao: turnoEmAtencao,
                      ),
                      const SizedBox(height: 20),
                      _DashboardBottomPanels(
                        quickActions: quickActions,
                        reportItems: reportItems,
                        onReportTap: onReportTap,
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
      width: 232,
      decoration: const BoxDecoration(
        color: _v2Card,
        border: Border(right: BorderSide(color: _v2Border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
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
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(14),
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
                    radius: 24,
                    backgroundColor: Colors.white.withValues(alpha: 0.92),
                    child: const Icon(
                      Icons.person_rounded,
                      color: _v2Primary,
                      size: 28,
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
              const SizedBox(width: 12),
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
          const SizedBox(height: 12),
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
            height: 36,
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
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              const SizedBox(width: 12),
              Icon(
                selected ? item.selectedIcon : item.icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    size: 13,
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
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: _v2Background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _v2Border),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent_rounded, color: _v2Muted, size: 22),
          const SizedBox(width: 12),
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
  final DateTime? turnoIniciadoEm;
  final int totalAtivos;
  final int totalCaixas;
  final int alocados;
  final int livres;
  final int emPausa;
  final int emRota;
  final int alertas;
  final VoidCallback onPrimaryAction;

  const _HeroDashboardSection({
    required this.saudacao,
    required this.primeiroNome,
    required this.turnoJaIniciado,
    required this.turnoIniciadoEm,
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
    final statusColor = turnoJaIniciado ? _v2Success : const Color(0xFF1D4ED8);
    final statusLabel =
        turnoJaIniciado ? 'Turno em andamento' : 'Aguardando inicio';

    return _V2Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 16),
            child: _DashboardTopBar(
              statusColor: statusColor,
              statusLabel: statusLabel,
              alertas: alertas,
            ),
          ),
          const Divider(height: 1, color: _v2Border),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HeroLandscapePainter(),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Color(0xFFF8FEFC),
                            Color(0xFFE8F8F4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;
                      final headline = _HeroHeadline(
                        saudacao: saudacao,
                        primeiroNome: primeiroNome,
                        turnoJaIniciado: turnoJaIniciado,
                        turnoIniciadoEm: turnoIniciadoEm,
                        onPrimaryAction: onPrimaryAction,
                      );
                      final signals = _HeroSignalsPanel(
                        totalAtivos: totalAtivos,
                        totalCaixas: totalCaixas,
                        alocados: alocados,
                        livres: livres,
                        emPausa: emPausa,
                        emRota: emRota,
                      );

                      if (!isWide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            headline,
                            const SizedBox(height: 22),
                            signals,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: headline),
                          const SizedBox(width: 30),
                          SizedBox(width: 370, child: signals),
                        ],
                      );
                    },
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

class _DashboardTopBar extends StatelessWidget {
  final Color statusColor;
  final String statusLabel;
  final int alertas;

  const _DashboardTopBar({
    required this.statusColor,
    required this.statusLabel,
    required this.alertas,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _LiveDatePill(),
        _LiveClockPill(),
        const SizedBox(width: 8),
        const _StatusPill(
          icon: Icons.dashboard_customize_outlined,
          label: 'Central do turno',
          color: _v2Primary,
        ),
        _StatusPill(
          icon: Icons.hourglass_top_rounded,
          label: statusLabel,
          color: statusColor,
        ),
        _StatusPill(
          icon: Icons.priority_high_rounded,
          label: alertas == 1 ? '1 alerta' : '$alertas alertas',
          color: alertas > 0 ? _v2Danger : _v2Success,
        ),
      ],
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
  final DateTime? turnoIniciadoEm;
  final VoidCallback onPrimaryAction;

  const _HeroHeadline({
    required this.saudacao,
    required this.primeiroNome,
    required this.turnoJaIniciado,
    required this.turnoIniciadoEm,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final buttonLabel =
        turnoJaIniciado ? 'Abrir timeline do turno' : 'Comecar turno';
    final turnoLabel = turnoJaIniciado && turnoIniciadoEm != null
        ? 'Turno iniciado as ${DateFormat('HH:mm').format(turnoIniciadoEm!)}'
        : 'Turno da manha - 08:00 as 16:00';

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 190),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$saudacao, $primeiroNome!',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _textStyle(
                  size: 32,
                  color: _v2Text,
                  weight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.waving_hand_outlined, color: _v2Warning),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            turnoLabel,
            style:
                _textStyle(size: 16, color: _v2Muted, weight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Text(
            'Confira os indicadores e acompanhe sua operacao em tempo real.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
              size: 14,
              color: _v2Muted,
              weight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 250,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: onPrimaryAction,
              icon: Icon(
                turnoJaIniciado
                    ? Icons.timeline_rounded
                    : Icons.play_arrow_rounded,
                size: 24,
              ),
              label: Text(
                buttonLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _v2Primary,
                foregroundColor: Colors.white,
                textStyle: _textStyle(size: 17, weight: FontWeight.w800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSignalsPanel extends StatelessWidget {
  final int totalAtivos;
  final int totalCaixas;
  final int alocados;
  final int livres;
  final int emPausa;
  final int emRota;

  const _HeroSignalsPanel({
    required this.totalAtivos,
    required this.totalCaixas,
    required this.alocados,
    required this.livres,
    required this.emPausa,
    required this.emRota,
  });

  @override
  Widget build(BuildContext context) {
    return _V2Card(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      radius: 16,
      child: Column(
        children: [
          _HeroInfoRow(
            icon: Icons.groups_2_outlined,
            label: 'Equipe ativa',
            value: totalAtivos.toString(),
            color: _v2Primary,
          ),
          const _PanelDivider(),
          _HeroInfoRow(
            icon: Icons.point_of_sale_outlined,
            label: 'Caixas ativos',
            value: totalCaixas.toString(),
            color: _v2Success,
          ),
          const _PanelDivider(),
          _HeroInfoRow(
            icon: Icons.swap_horiz_rounded,
            label: 'Alocados / livres',
            value: '$alocados / $livres',
            color: _v2Success,
          ),
          const _PanelDivider(),
          _HeroInfoRow(
            icon: Icons.emoji_events_outlined,
            label: 'Pausas / rotas',
            value: '$emPausa / $emRota',
            color: const Color(0xFFC2410C),
          ),
        ],
      ),
    );
  }
}

class _HeroInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HeroInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 42),
      child: Row(
        children: [
          _IconBubble(icon: icon, color: color, size: 36, iconSize: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _textStyle(
                  size: 14, color: _v2Muted, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(size: 22, color: color, weight: FontWeight.w900),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded,
              color: _v2Muted.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}

class _DashboardAlertBanner extends StatelessWidget {
  final int alertas;
  final bool critico;
  final bool atencao;
  final VoidCallback? onTap;

  const _DashboardAlertBanner({
    required this.alertas,
    required this.critico,
    required this.atencao,
    required this.onTap,
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
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
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
                size: 48,
                iconSize: 30,
              ),
              const SizedBox(width: 16),
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
                        size: 16,
                        color: color,
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle(
                        size: 14,
                        color: _v2Muted,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              if (hasAlert)
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

  const _DashboardMetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1260
            ? 6
            : width >= 900
                ? 3
                : width >= 560
                    ? 2
                    : 1;

        return GridView.builder(
          itemCount: metrics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 138,
          ),
          itemBuilder: (context, index) {
            return _MetricV2Card(metric: metrics[index]);
          },
        );
      },
    );
  }
}

class _MetricV2Card extends StatelessWidget {
  final OperationalMetricData metric;

  const _MetricV2Card({required this.metric});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        borderColor: metric.color.withValues(alpha: 0.24),
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBubble(icon: metric.icon, color: metric.color),
              const Spacer(),
              if (metric.onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: metric.color,
                  size: 22,
                ),
            ],
          ),
          const Spacer(),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
              size: 30,
              color: metric.color,
              weight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                _textStyle(size: 13, color: _v2Text, weight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 16,
                color: metric.color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  metric.helper ?? 'Em operacao',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    size: 12,
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
        borderRadius: BorderRadius.circular(16),
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

  const _OperationalMonitorCard({
    required this.caixas,
    required this.alertas,
    required this.turnoCritico,
    required this.turnoEmAtencao,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCaixas = caixas.take(5).toList();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBubble(
                icon: Icons.monitor_heart_outlined,
                color: _v2Primary,
                size: 32,
                iconSize: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Monitor em tempo real',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    size: 18,
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
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: _v2Primary),
            ],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 860;
              final summary = _MonitorSummary(
                alertas: alertas,
                color: statusColor,
                statusLabel: statusLabel,
              );
              final caixasRow = _MonitorCaixasRow(
                caixas: visibleCaixas,
                hiddenCount: hiddenCount,
              );

              if (!isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    summary,
                    const SizedBox(height: 18),
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

  const _MonitorSummary({
    required this.alertas,
    required this.color,
    required this.statusLabel,
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
          size: 34,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    _textStyle(size: 14, color: color, weight: FontWeight.w900),
              ),
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
          ),
        ),
      ],
    );
  }
}

class _MonitorCaixasRow extends StatelessWidget {
  final List<Caixa> caixas;
  final int hiddenCount;

  const _MonitorCaixasRow({
    required this.caixas,
    required this.hiddenCount,
  });

  @override
  Widget build(BuildContext context) {
    if (caixas.isEmpty) {
      return Container(
        constraints: const BoxConstraints(minHeight: 64),
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
            _CaixaStatusTile(caixa: caixa),
            const SizedBox(width: 12),
          ],
          if (hiddenCount > 0) _MoreCaixasTile(hiddenCount: hiddenCount),
        ],
      ),
    );
  }
}

class _CaixaStatusTile extends StatelessWidget {
  final Caixa caixa;

  const _CaixaStatusTile({required this.caixa});

  @override
  Widget build(BuildContext context) {
    final status = _caixaStatus(caixa);

    return Container(
      width: 140,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatCaixaName(caixa),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    size: 13,
                    color: _v2Text,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            status.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
              size: 12,
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

  const _MoreCaixasTile({required this.hiddenCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 64,
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
            style:
                _textStyle(size: 15, color: _v2Text, weight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Caixas',
            style:
                _textStyle(size: 12, color: _v2Muted, weight: FontWeight.w700),
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

  const _DashboardBottomPanels({
    required this.quickActions,
    required this.reportItems,
    required this.onReportTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        final routines = _RoutinesPanel(quickActions: quickActions);
        final report =
            _ReportPanel(items: reportItems, onReportTap: onReportTap);

        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              routines,
              const SizedBox(height: 18),
              report,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: routines),
            const SizedBox(width: 18),
            Expanded(flex: 4, child: report),
          ],
        );
      },
    );
  }
}

class _RoutinesPanel extends StatelessWidget {
  final List<DashboardV2QuickAction> quickActions;

  const _RoutinesPanel({required this.quickActions});

  @override
  Widget build(BuildContext context) {
    return _V2Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.grid_view_rounded,
            title: 'Rotinas principais',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 720
                  ? 3
                  : width >= 460
                      ? 2
                      : 1;

              return GridView.builder(
                itemCount: quickActions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 74,
                ),
                itemBuilder: (context, index) {
                  return _QuickActionTile(action: quickActions[index]);
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

  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
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
                  _IconBubble(icon: action.icon, color: action.color),
                  if (action.badge != null)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: _MiniBadge(value: action.badge!),
                    ),
                ],
              ),
              const SizedBox(width: 12),
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
                        size: 13,
                        color: _v2Text,
                        weight: FontWeight.w900,
                      ),
                    ),
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
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: _v2Muted.withValues(alpha: 0.8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportPanel extends StatelessWidget {
  final List<DashboardV2ReportItem> items;
  final VoidCallback onReportTap;

  const _ReportPanel({required this.items, required this.onReportTap});

  @override
  Widget build(BuildContext context) {
    return _V2Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: _SectionTitle(
                  icon: Icons.bar_chart_rounded,
                  title: 'Relatorio rapido',
                ),
              ),
              _SoftPill(
                label: 'Hoje',
                icon: Icons.expand_more_rounded,
                iconColor: _v2Muted,
                trailingIcon: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final item in items) ...[
            _ReportRow(item: item),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onReportTap,
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

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBubble(icon: icon, color: _v2Primary, size: 32, iconSize: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                _textStyle(size: 16, color: _v2Text, weight: FontWeight.w900),
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

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 16, color: _v2Border);
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

class _HeroLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFFFD166).withValues(alpha: 0.55);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.36), 30, paint);

    final backPath = Path()
      ..moveTo(0, size.height * 0.78)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.72,
        size.width * 0.34,
        size.height * 0.9,
        size.width * 0.52,
        size.height * 0.68,
      )
      ..cubicTo(
        size.width * 0.7,
        size.height * 0.46,
        size.width * 0.82,
        size.height * 0.72,
        size.width,
        size.height * 0.5,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    paint.color = const Color(0xFFBFEFE5).withValues(alpha: 0.42);
    canvas.drawPath(backPath, paint);

    final frontPath = Path()
      ..moveTo(0, size.height * 0.86)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.78,
        size.width * 0.31,
        size.height * 0.98,
        size.width * 0.47,
        size.height * 0.83,
      )
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.65,
        size.width * 0.77,
        size.height * 0.88,
        size.width,
        size.height * 0.65,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    paint.color = const Color(0xFF8BDACE).withValues(alpha: 0.28);
    canvas.drawPath(frontPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

class _CaixaStatus {
  final String label;
  final Color color;

  const _CaixaStatus(this.label, this.color);
}
