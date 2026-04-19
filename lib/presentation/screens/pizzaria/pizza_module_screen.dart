// lib/modules/pizza/pizza_module_screen.dart
//
// Adicione esta tela no seu menu principal do Fiscal Assistant
// Exemplo de como chamar:
//   Navigator.push(context, MaterialPageRoute(builder: (_) => const PizzaModuleScreen()));

import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/theme/app_theme.dart';
import 'pedidos_list_screen.dart';
import 'pizzas_cadastro_screen.dart';

class PizzaModuleScreen extends StatefulWidget {
  const PizzaModuleScreen({super.key});

  @override
  State<PizzaModuleScreen> createState() => _PizzaModuleScreenState();
}

class _PizzaModuleScreenState extends State<PizzaModuleScreen> {
  int _tab = 0;

  final _telas = const [
    PedidosListScreen(),
    PizzasCadastroScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTheme;
    return Scaffold(
      backgroundColor: tokens.background,
      body: IndexedStack(index: _tab, children: _telas),
      bottomNavigationBar: NavigationBar(
        backgroundColor: tokens.cardBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined,
                color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_pizza_outlined,
                color: AppColors.textSecondary),
            selectedIcon:
                Icon(Icons.local_pizza, color: AppColors.primary),
            label: 'Cardápio',
          ),
        ],
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            );
          }
          return AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          );
        }),
      ),
    );
  }
}
