import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/cafe_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/escala_provider.dart';
import '../alocacao/alocacao_screen.dart';
import '../mapa/mapa_caixas_screen.dart';
import '../cafe/cafe_screen.dart';
import 'visao_gargalo_screen.dart';

/// Hub unificado: Alocar · Mapa · Café · Visão
/// Usa IndexedStack para manter os timers e estado vivos ao trocar de aba.
class GestaoScreen extends StatefulWidget {
  /// Índice inicial (0 = Alocar, 1 = Mapa, 2 = Café, 3 = Visão)
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
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fiscalId = authProvider.user?.id ?? '';

    // Badge de atraso no café
    final cafeProvider = Provider.of<CafeProvider>(context);
    final atrasos = cafeProvider.totalEmAtraso;

    // Badge de gargalo na visão
    final escalaProvider = Provider.of<EscalaProvider>(context);
    final alocacaoProvider = Provider.of<AlocacaoProvider>(context);
    final colaboradorProvider = Provider.of<ColaboradorProvider>(context);
    final gargalos = contarGargalosHoje(
      escala: escalaProvider,
      alocacao: alocacaoProvider,
      cafe: cafeProvider,
      colaborador: colaboradorProvider,
    );

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AlocacaoScreen(fiscalId: fiscalId),
          const MapaCaixasScreen(),
          const CafeScreen(),
          const VisaoGargaloScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Alocar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: atrasos > 0,
              label: Text('$atrasos'),
              child: const Icon(Icons.coffee_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: atrasos > 0,
              label: Text('$atrasos'),
              child: const Icon(Icons.coffee),
            ),
            label: 'Café',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: gargalos > 0,
              label: Text('$gargalos'),
              child: const Icon(Icons.show_chart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: gargalos > 0,
              label: Text('$gargalos'),
              child: const Icon(Icons.show_chart),
            ),
            label: 'Visão',
          ),
        ],
      ),
    );
  }
}
