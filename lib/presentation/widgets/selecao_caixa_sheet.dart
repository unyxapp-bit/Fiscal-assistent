import 'package:flutter/material.dart';
import '../../core/constants/app_styles.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/dimensions.dart';
import '../../domain/entities/caixa.dart';
import '../../domain/enums/tipo_caixa.dart';

/// Bottom sheet to select a checkout.
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
        if (_filtroTipo != null && c.tipo != _filtroTipo) {
          return false;
        }
        if (_filtroStatus != null && _statusKey(c) != _filtroStatus) {
          return false;
        }
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
        return AppColors.danger;
      case TipoCaixa.normal:
        return AppColors.primary;
      case TipoCaixa.preferencial:
        return AppColors.statusAtencao;
      case TipoCaixa.self:
        return AppColors.statusSelf;
      case TipoCaixa.balcao:
        return AppColors.teal;
    }
  }

  String _getNomeTipo(TipoCaixa tipo) => tipo.nome;

  Icon _getIconStatus(Caixa caixa) {
    final status = _statusKey(caixa);
    switch (status) {
      case 'ativo':
        return const Icon(Icons.check_circle, color: AppColors.success);
      case 'inativo':
        return const Icon(Icons.cancel, color: AppColors.inactive);
      case 'manutencao':
        return const Icon(Icons.construction, color: AppColors.statusAtencao);
      default:
        return const Icon(Icons.help);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('Selecionar Caixa', style: AppTextStyles.h3),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(_getNomeTipo(tipo)),
                      onSelected: (selected) {
                        setState(() => _filtroTipo = selected ? tipo : null);
                        _atualizar();
                      },
                      selected: _filtroTipo == tipo,
                      backgroundColor:
                          _getColorTipo(tipo).withValues(alpha: 0.12),
                      selectedColor: _getColorTipo(tipo).withValues(alpha: 0.2),
                      side: BorderSide(
                          color: _getColorTipo(tipo).withValues(alpha: 0.4)),
                      labelStyle: TextStyle(
                        color: _filtroTipo == tipo
                            ? _getColorTipo(tipo)
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
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
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label:
                          Text(status == 'manutencao' ? 'Manutencao' : status),
                      onSelected: (selected) {
                        setState(
                            () => _filtroStatus = selected ? status : null);
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
                ? const _VazioCaixa()
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.95,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final caixa = _filtered[index];
                      final corTipo = _getColorTipo(caixa.tipo);
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusLG),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onSelected(caixa);
                          },
                          child: Ink(
                            decoration:
                                AppStyles.softTile(tint: corTipo, radius: 14),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Cx ${caixa.numero}',
                                  style:
                                      AppTextStyles.h3.copyWith(color: corTipo),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getNomeTipo(caixa.tipo),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _getIconStatus(caixa),
                              ],
                            ),
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

class _VazioCaixa extends StatelessWidget {
  const _VazioCaixa();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: AppStyles.softCard(tint: AppColors.inactive, radius: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox,
                size: 44, color: AppColors.inactive.withValues(alpha: 0.9)),
            const SizedBox(height: 8),
            const Text('Nenhuma caixa encontrada', style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}
