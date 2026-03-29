// lib/modules/pizza/pizza_module_screen.dart
//
// Adicione esta tela no seu menu principal do Fiscal Assistant
// Exemplo de como chamar:
//   Navigator.push(context, MaterialPageRoute(builder: (_) => const PizzaModuleScreen()));

import 'package:flutter/material.dart';
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
    return Scaffold(
      body: IndexedStack(index: _tab, children: _telas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_pizza_outlined),
            selectedIcon: Icon(Icons.local_pizza),
            label: 'Cardápio',
          ),
        ],
      ),
    );
  }
}
