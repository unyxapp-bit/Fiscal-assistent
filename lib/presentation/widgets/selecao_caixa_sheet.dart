import 'package:flutter/material.dart';

import '../../domain/entities/caixa.dart';
import '../../domain/enums/tipo_caixa.dart';

/// Bottom sheet para selecionar caixa
class SelecaoCaixaSheet extends StatefulWidget {
  final List<Caixa> caixas;
  final Function(Caixa) onSelected;

  const SelecaoCaixaSheet({
    super.key,
    required this.caixas,
    required this.onSelected,
  });

  @override
  State<SelecaoCaixaSheet> createState() => _SelecaoCaixaSheetState();
}

class _SelecaoCaixaSheetState extends State<SelecaoCaixaSheet> {
  late List<Caixa> _filtered;
  TipoCaixa? _filtroTipo;
  String? _filtroStatus;

  @override
  void initState() {
    super.initState();
    _filtered = widget.caixas;
  }

  void _atualizar() {
    setState(() {
      _filtered = widget.caixas.where((c) {
        if (_filtroTipo != null && c.tipo != _filtroTipo) return false;
        if (_filtroStatus != null && _statusKey(c) != _filtroStatus) return false;
        return true;
      }).toList();
    });
  }

  String _statusKey(Caixa caixa) {
    if (caixa.emManutencao) return 'manutencao';
    return caixa.ativo ? 'ativo' : 'inativo';
  }

  Color _getColorTipo(TipoCaixa tipo) {
    switch (tipo) {
      case TipoCaixa.rapido:
        return Colors.red;
      case TipoCaixa.normal:
        return Colors.blue;
      case TipoCaixa.self:
        return Colors.orange;
    }
  }

  String _getNomeTipo(TipoCaixa tipo) {
    return tipo.nome;
  }

  Icon _getIconStatus(Caixa caixa) {
    final status = _statusKey(caixa);
    switch (status) {
      case 'ativo':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'inativo':
        return const Icon(Icons.cancel, color: Colors.grey);
      case 'manutencao':
        return const Icon(Icons.construction, color: Colors.orange);
      default:
        return const Icon(Icons.help);
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
                'Selecione a Caixa',
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Tipo'),
                    onSelected: (_) {
                      setState(() => _filtroTipo = null);
                      _atualizar();
                    },
                    selected: _filtroTipo != null,
                  ),
                ),
                for (final tipo in TipoCaixa.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: FilterChip(
                      label: Text(_getNomeTipo(tipo)),
                      onSelected: (selected) {
                        setState(() => _filtroTipo = selected ? tipo : null);
                        _atualizar();
                      },
                      selected: _filtroTipo == tipo,
                      backgroundColor: _getColorTipo(tipo).withValues(alpha: 0.2),
                      selectedColor: _getColorTipo(tipo),
                      labelStyle: TextStyle(
                        color: _filtroTipo == tipo ? Colors.white : _getColorTipo(tipo),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Status'),
                    onSelected: (_) {
                      setState(() => _filtroStatus = null);
                      _atualizar();
                    },
                    selected: _filtroStatus != null,
                  ),
                ),
                for (final status in ['ativo', 'inativo', 'manutencao'])
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: FilterChip(
                      label: Text(status == 'manutencao' ? 'Manutencao' : status),
                      onSelected: (selected) {
                        setState(() => _filtroStatus = selected ? status : null);
                        _atualizar();
                      },
                      selected: _filtroStatus == status,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nenhuma caixa encontrada',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final caixa = _filtered[index];
                      final corTipo = _getColorTipo(caixa.tipo);

                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSelected(caixa);
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: corTipo.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Cx ${caixa.numero}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: corTipo,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getNomeTipo(caixa.tipo),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _getIconStatus(caixa),
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
