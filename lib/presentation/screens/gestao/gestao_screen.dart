import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
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
  late String _fiscalId;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    if (_currentIndex < 0 || _currentIndex > 3) {
      _currentIndex = 0;
    }
    // Lido uma vez — AuthProvider raramente muda durante sessão
    _fiscalId =
        Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
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
        label: 'Aloca\u00e7\u00e3o',
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
        label: 'Caf\u00e9',
        icon: Icons.coffee_outlined,
        selectedIcon: Icons.coffee_rounded,
        color: AppColors.statusCafe,
        badgeCount: atrasos,
      ),
      _GestaoDestination(
        label: 'Vis\u00e3o',
        icon: Icons.show_chart_outlined,
        selectedIcon: Icons.show_chart_rounded,
        color: AppColors.statusAtencao,
        badgeCount: gargalos,
      ),
    ];

    return Scaffold(
      backgroundColor: tokens.background,
      body: Column(
        children: [
          // Faixa de chips de navegação
          Container(
            color: tokens.cardBackground,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(Dimensions.paddingMD,
            Dimensions.paddingSM, Dimensions.paddingMD, Dimensions.paddingSM),
                  child: Row(
                    children: [
                      for (int i = 0; i < destinos.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        _GestaoChip(
                          item: destinos[i],
                          selected: i == _currentIndex,
                          onTap: () => setState(() => _currentIndex = i),
                        ),
                      ],
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: AppColors.divider),
              ],
            ),
          ),
          // Conteúdo da aba ativa
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                AlocacaoScreen(fiscalId: fiscalId),
                const MapaCaixasScreen(),
                const CafeScreen(),
                const VisaoGargaloScreen(),
              ],
            ),
          ),
        ],
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingMD,
            vertical: Dimensions.paddingSM),
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
                    top: -5,
                    right: -7,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 14),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.badgeCount > 99 ? '99+' : '${item.badgeCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: AppTextStyles.caption.copyWith(
                color: selected ? item.color : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

