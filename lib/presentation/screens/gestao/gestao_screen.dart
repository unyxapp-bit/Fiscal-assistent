import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cafe_provider.dart';
import '../../providers/escala_provider.dart';
import '../alocacao/alocacao_screen.dart';
import '../cafe/cafe_screen.dart';
import '../mapa/mapa_caixas_screen.dart';
import 'visao_gargalo_screen.dart';

class GestaoScreen extends StatefulWidget {
  final int initialIndex;

  const GestaoScreen({super.key, this.initialIndex = 0});

  @override
  State<GestaoScreen> createState() => _GestaoScreenState();
}

class _GestaoScreenState extends State<GestaoScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    if (_currentIndex < 0 || _currentIndex > 3) {
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.read<AuthProvider>();
    final fiscalId = authProvider.user?.id ?? '';
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
        label: 'Aloca\u00e7\u00e3o',
        headline: 'Painel de aloca\u00e7\u00e3o',
        summary:
            'Movimente equipe, cubra caixas livres e mantenha a opera\u00e7\u00e3o fluindo.',
        icon: Icons.swap_horiz_outlined,
        selectedIcon: Icons.swap_horiz_rounded,
        color: AppColors.primary,
      ),
      _GestaoDestination(
        label: 'Mapa',
        headline: 'Mapa dos caixas',
        summary:
            'Leia ocupa\u00e7\u00e3o, pausas, gargalos e exce\u00e7\u00f5es em tempo real.',
        icon: Icons.map_outlined,
        selectedIcon: Icons.map_rounded,
        color: AppColors.cyan,
      ),
      _GestaoDestination(
        label: 'Caf\u00e9',
        headline: 'Gest\u00e3o de caf\u00e9',
        summary:
            'Acompanhe pausas, atrasos e retornos sem perder o ritmo do turno.',
        icon: Icons.coffee_outlined,
        selectedIcon: Icons.coffee_rounded,
        color: AppColors.statusCafe,
        badgeCount: atrasos,
      ),
      _GestaoDestination(
        label: 'Vis\u00e3o',
        headline: 'Leitura de gargalos',
        summary:
            'Antecipe quedas operacionais e redistribua a equipe com mais rapidez.',
        icon: Icons.show_chart_outlined,
        selectedIcon: Icons.show_chart_rounded,
        color: AppColors.statusAtencao,
        badgeCount: gargalos,
      ),
    ];

    final destinoAtual = destinos[_currentIndex];

    return Scaffold(
      extendBody: true,
      backgroundColor: tokens.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AlocacaoScreen(fiscalId: fiscalId),
          const MapaCaixasScreen(),
          const CafeScreen(),
          const VisaoGargaloScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                destinoAtual.color.withValues(alpha: isDark ? 0.18 : 0.08),
                tokens.cardBackground,
                tokens.backgroundSection,
              ],
            ),
            borderRadius: BorderRadius.circular(tokens.cardRadius + 4),
            border: Border.all(
              color: destinoAtual.color.withValues(alpha: isDark ? 0.28 : 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    tokens.shadowColor.withValues(alpha: isDark ? 0.16 : 0.05),
                blurRadius: isDark ? 22 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: AppStyles.softTile(
                        context: context,
                        tint: destinoAtual.color,
                        radius: 14,
                      ),
                      child: Icon(
                        destinoAtual.selectedIcon,
                        color: destinoAtual.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Column(
                          key: ValueKey(destinoAtual.label),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Central de gest\u00e3o',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              destinoAtual.headline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.h4.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              destinoAtual.summary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GestaoStatusChip(
                      color: atrasos > 0
                          ? AppColors.statusCafe
                          : gargalos > 0
                              ? AppColors.statusAtencao
                              : AppColors.success,
                      label: atrasos > 0
                          ? '$atrasos caf\u00e9${atrasos > 1 ? 's' : ''}'
                          : gargalos > 0
                              ? '$gargalos gargalo${gargalos > 1 ? 's' : ''}'
                              : 'Fluxo OK',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < destinos.length; i++) ...[
                      Expanded(
                        child: _GestaoNavButton(
                          item: destinos[i],
                          selected: i == _currentIndex,
                          onTap: () => setState(() => _currentIndex = i),
                        ),
                      ),
                      if (i < destinos.length - 1) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GestaoDestination {
  final String label;
  final String headline;
  final String summary;
  final IconData icon;
  final IconData selectedIcon;
  final Color color;
  final int badgeCount;

  const _GestaoDestination({
    required this.label,
    required this.headline,
    required this.summary,
    required this.icon,
    required this.selectedIcon,
    required this.color,
    this.badgeCount = 0,
  });
}

class _GestaoNavButton extends StatelessWidget {
  final _GestaoDestination item;
  final bool selected;
  final VoidCallback onTap;

  const _GestaoNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? item.color : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: selected
              ? AppStyles.softTile(
                  context: context,
                  tint: item.color,
                  radius: 18,
                )
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: AppStyles.softTile(
                        context: context,
                        tint: item.color,
                        radius: 12,
                      ),
                      child: Icon(
                        selected ? item.selectedIcon : item.icon,
                        color: item.color,
                        size: 18,
                      ),
                    ),
                    if (item.badgeCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.cardBackground),
                          ),
                          child: Text(
                            item.badgeCount > 99 ? '99+' : '${item.badgeCount}',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: foreground,
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

class _GestaoStatusChip extends StatelessWidget {
  final Color color;
  final String label;

  const _GestaoStatusChip({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: AppStyles.softTile(
        context: context,
        tint: color,
        radius: 999,
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
