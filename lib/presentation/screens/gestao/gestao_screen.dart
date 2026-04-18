import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: tokens.cardBackground,
            elevation: 4,
            shadowColor:
                tokens.shadowColor.withValues(alpha: isDark ? 0.28 : 0.08),
            surfaceTintColor: Colors.transparent,
            indicatorColor: destinos[_currentIndex]
                .color
                .withValues(alpha: isDark ? 0.22 : 0.14),
            height: 68,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return AppTextStyles.caption.copyWith(
                color: selected
                    ? destinos[_currentIndex].color
                    : AppColors.textSecondary,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: selected
                    ? destinos[_currentIndex].color
                    : AppColors.textSecondary,
                size: 22,
              );
            }),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: [
            for (int i = 0; i < destinos.length; i++)
              NavigationDestination(
                icon: destinos[i].badgeCount > 0
                    ? Badge(
                        label: Text('${destinos[i].badgeCount}'),
                        child: Icon(destinos[i].icon),
                      )
                    : Icon(destinos[i].icon),
                selectedIcon: destinos[i].badgeCount > 0
                    ? Badge(
                        label: Text('${destinos[i].badgeCount}'),
                        child: Icon(destinos[i].selectedIcon),
                      )
                    : Icon(destinos[i].selectedIcon),
                label: destinos[i].label,
              ),
          ],
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

