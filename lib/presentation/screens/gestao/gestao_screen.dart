import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cafe_provider.dart';
import '../../providers/caixa_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/escala_provider.dart';
import '../alocacao/alocacao_screen.dart';
import '../cafe/cafe_screen.dart';
import '../mapa/mapa_caixas_screen.dart';
import 'central/caixas_central_view.dart';
import 'visao_gargalo_screen.dart';
import 'widgets/gestao_navigation.dart';

class GestaoScreen extends StatefulWidget {
  static const int centralIndex = -1;

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
    _currentIndex = _initialToTabIndex(widget.initialIndex);
    _fiscalId =
        Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  int _initialToTabIndex(int initialIndex) {
    if (initialIndex == GestaoScreen.centralIndex) return 0;
    return (initialIndex + 1).clamp(1, 4);
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id ?? _fiscalId;
    if (userId.isEmpty) return;

    await Future.wait([
      Provider.of<ColaboradorProvider>(context, listen: false)
          .loadColaboradores(userId),
      Provider.of<CaixaProvider>(context, listen: false).loadCaixas(userId),
      Provider.of<AlocacaoProvider>(context, listen: false)
          .loadAlocacoes(userId),
      Provider.of<CafeProvider>(context, listen: false).load(),
      Provider.of<EscalaProvider>(context, listen: false).load(),
    ]);
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

    final destinos = <GestaoDestination>[
      GestaoDestination(
        label: 'Central',
        icon: Icons.dashboard_customize_outlined,
        selectedIcon: Icons.dashboard_customize_rounded,
        color: AppColors.primary,
      ),
      GestaoDestination(
        label: 'Alocação',
        icon: Icons.swap_horiz_outlined,
        selectedIcon: Icons.swap_horiz_rounded,
        color: AppColors.primary,
      ),
      GestaoDestination(
        label: 'Mapa',
        icon: Icons.map_outlined,
        selectedIcon: Icons.map_rounded,
        color: AppColors.cyan,
      ),
      GestaoDestination(
        label: 'Café',
        icon: Icons.restaurant_outlined,
        selectedIcon: Icons.restaurant_rounded,
        color: AppColors.statusCafe,
        badgeCount: atrasos,
      ),
      GestaoDestination(
        label: 'Gargalo',
        icon: Icons.insights_outlined,
        selectedIcon: Icons.insights_rounded,
        color: AppColors.statusAtencao,
        badgeCount: gargalos,
      ),
    ];

    final pages = [
      CaixasCentralView(
        onRefresh: _loadData,
        onOpenAlocacao: () => setState(() => _currentIndex = 1),
        onOpenMapa: () => setState(() => _currentIndex = 2),
        onOpenCafe: () => setState(() => _currentIndex = 3),
        onOpenGargalo: () => setState(() => _currentIndex = 4),
      ),
      AlocacaoScreen(fiscalId: fiscalId),
      const MapaCaixasScreen(),
      const CafeScreen(),
      const VisaoGargaloScreen(),
    ];

    return Scaffold(
      backgroundColor: tokens.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;

          if (!isWide) {
            return Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: GestaoTopNavigation(
                    destinos: destinos,
                    selectedIndex: _currentIndex,
                    compact: true,
                    onRefresh: _loadData,
                    onSelected: (i) => setState(() => _currentIndex = i),
                  ),
                ),
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: pages),
                ),
              ],
            );
          }

          return Row(
            children: [
              CaixasSidebarV3(
                destinos: destinos,
                selectedIndex: _currentIndex,
                onSelected: (i) => setState(() => _currentIndex = i),
              ),
              Expanded(
                child: Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: GestaoTopNavigation(
                        destinos: destinos,
                        selectedIndex: _currentIndex,
                        onRefresh: _loadData,
                        onSelected: (i) => setState(() => _currentIndex = i),
                      ),
                    ),
                    Expanded(
                      child:
                          IndexedStack(index: _currentIndex, children: pages),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
