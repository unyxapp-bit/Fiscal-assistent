import 'package:flutter/material.dart';

import '../../domain/entities/colaborador.dart';
import '../../domain/enums/departamento_tipo.dart';

/// Bottom sheet para selecionar colaborador
class SelecaoColaboradorSheet extends StatefulWidget {
  final List<Colaborador> colaboradores;
  final Function(Colaborador) onSelected;

  const SelecaoColaboradorSheet({
    super.key,
    required this.colaboradores,
    required this.onSelected,
  });

  @override
  State<SelecaoColaboradorSheet> createState() => _SelecaoColaboradorSheetState();
}

class _SelecaoColaboradorSheetState extends State<SelecaoColaboradorSheet> {
  late List<Colaborador> _filtered;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.colaboradores;
    _searchController.addListener(_filterColaboradores);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterColaboradores() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = widget.colaboradores.where((c) {
        final departamento = c.departamento.nome.toLowerCase();
        return c.nome.toLowerCase().contains(query) || departamento.contains(query);
      }).toList();
    });
  }

  Color _getCoreColor(DepartamentoTipo departamento) {
    switch (departamento) {
      case DepartamentoTipo.caixa:
        return Colors.blue;
      case DepartamentoTipo.fiscal:
        return Colors.purple;
      case DepartamentoTipo.pacote:
        return Colors.green;
      case DepartamentoTipo.self:
        return Colors.orange;
      case DepartamentoTipo.gerencia:
        return Colors.red;
      case DepartamentoTipo.acougue:
        return Colors.brown;
      case DepartamentoTipo.padaria:
        return Colors.amber;
      case DepartamentoTipo.hortifruti:
        return Colors.greenAccent;
      case DepartamentoTipo.deposito:
        return Colors.grey;
      case DepartamentoTipo.limpeza:
        return Colors.blueGrey;
      case DepartamentoTipo.seguranca:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Selecione o Colaborador',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou departamento...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nenhum colaborador encontrado',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final colaborador = _filtered[index];
                      final coreColor = _getCoreColor(colaborador.departamento);
                      final departamento = colaborador.departamento.nome;

                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSelected(colaborador);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: coreColor,
                                radius: 20,
                                child: Text(
                                  colaborador.avatarIniciais ?? '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      colaborador.nome,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      departamento,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: coreColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  departamento,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: coreColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
