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
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 420;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: tokens.cardBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: compact
                        ? Column(
                            children: [
                              _PizzaTabButton(
                                label: 'Pedidos',
                                icon: Icons.receipt_long_rounded,
                                selected: _tab == 0,
                                onTap: () => setState(() => _tab = 0),
                              ),
                              const SizedBox(height: 6),
                              _PizzaTabButton(
                                label: 'Card\u00e1pio',
                                icon: Icons.local_pizza_rounded,
                                selected: _tab == 1,
                                onTap: () => setState(() => _tab = 1),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _PizzaTabButton(
                                  label: 'Pedidos',
                                  icon: Icons.receipt_long_rounded,
                                  selected: _tab == 0,
                                  onTap: () => setState(() => _tab = 0),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _PizzaTabButton(
                                  label: 'Card\u00e1pio',
                                  icon: Icons.local_pizza_rounded,
                                  selected: _tab == 1,
                                  onTap: () => setState(() => _tab = 1),
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(index: _tab, children: _telas),
          ),
        ],
      ),
    );
  }
}

class _PizzaTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PizzaTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
