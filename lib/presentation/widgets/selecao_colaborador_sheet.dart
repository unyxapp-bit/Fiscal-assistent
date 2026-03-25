import 'package:flutter/material.dart';
import '../../core/constants/app_styles.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/dimensions.dart';
import '../../domain/entities/colaborador.dart';
import '../../domain/enums/departamento_tipo.dart';

/// Bottom sheet to select a collaborator.
class SelecaoColaboradorSheet extends StatefulWidget {
  final List<Colaborador> colaboradores;
  final Function(Colaborador) onSelected;

  const SelecaoColaboradorSheet({
    super.key,
    required this.colaboradores,
    required this.onSelected,
  });

  @override
  State<SelecaoColaboradorSheet> createState() =>
      _SelecaoColaboradorSheetState();
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
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filtered = widget.colaboradores.where((c) {
        final departamento = c.departamento.nome.toLowerCase();
        return c.nome.toLowerCase().contains(query) ||
            departamento.contains(query);
      }).toList();
    });
  }

  Color _getCoreColor(DepartamentoTipo departamento) {
    switch (departamento) {
      case DepartamentoTipo.caixa:
        return AppColors.primary;
      case DepartamentoTipo.fiscal:
        return AppColors.indigo;
      case DepartamentoTipo.pacote:
        return AppColors.success;
      case DepartamentoTipo.self:
        return AppColors.statusSelf;
      case DepartamentoTipo.gerencia:
        return AppColors.danger;
      case DepartamentoTipo.acougue:
        return AppColors.coffee;
      case DepartamentoTipo.padaria:
        return AppColors.statusAtencao;
      case DepartamentoTipo.hortifruti:
        return AppColors.teal;
      case DepartamentoTipo.deposito:
        return AppColors.blueGrey;
      case DepartamentoTipo.limpeza:
        return AppColors.cyan;
      case DepartamentoTipo.seguranca:
        return AppColors.deepPurple;
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
              const Text('Selecionar Colaborador', style: AppTextStyles.h3),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Buscar por nome ou departamento',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filtered.isEmpty
                ? const _VazioColaborador()
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final colaborador = _filtered[index];
                      final coreColor = _getCoreColor(colaborador.departamento);
                      final departamento = colaborador.departamento.nome;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusLG),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onSelected(colaborador);
                          },
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration:
                                AppStyles.softTile(tint: coreColor, radius: 14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: coreColor,
                                  radius: 21,
                                  child: Text(
                                    colaborador.avatarIniciais ?? '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        colaborador.nome,
                                        style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        departamento,
                                        style: AppTextStyles.caption,
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
                                    color: coreColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: coreColor.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Text(
                                    departamento,
                                    style: AppTextStyles.caption.copyWith(
                                      color: coreColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
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

class _VazioColaborador extends StatelessWidget {
  const _VazioColaborador();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: AppStyles.softCard(tint: AppColors.inactive, radius: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off,
                size: 44, color: AppColors.inactive.withValues(alpha: 0.9)),
            const SizedBox(height: 8),
            const Text('Nenhum colaborador encontrado',
                style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}
