import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../domain/entities/caixa.dart';
import '../../../../domain/entities/alocacao.dart';
import '../../../../domain/entities/colaborador.dart';
import '../../../providers/colaborador_provider.dart';
import '../../../providers/alocacao_provider.dart';
import '../../../providers/escala_provider.dart';
import '../../../providers/cafe_provider.dart';
import 'colaborador_detalhes_sheet.dart';

/// Item de lista para o mapa de caixas
class CaixaListItem extends StatelessWidget {
  final Caixa caixa;
  final Alocacao? alocacao;

  const CaixaListItem({
    super.key,
    required this.caixa,
    this.alocacao,
  });

  @override
  Widget build(BuildContext context) {
    final colaboradorProvider = Provider.of<ColaboradorProvider>(context);
    final alocacaoProvider = Provider.of<AlocacaoProvider>(context);
    final escalaProvider = Provider.of<EscalaProvider>(context);
    final cafeProvider = Provider.of<CafeProvider>(context);

    final colaborador = alocacao != null
        ? colaboradorProvider.colaboradores
            .where((c) => c.id == alocacao!.colaboradorId)
            .firstOrNull
        : null;

    final isOcupado = alocacao != null;
    final statusColor = _statusColor(isOcupado);

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _showDetalhes(
          context,
          colaborador,
          alocacaoProvider,
          escalaProvider,
          cafeProvider,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: statusColor, width: 5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                    // Avatar com número do caixa
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${caixa.numero}',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ── Informações centrais ─────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Nome + tipo
                          Row(
                            children: [
                              Icon(caixa.tipo.icone,
                                  size: 14,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(caixa.nomeExibicao,
                                  style: AppTextStyles.h4),
                              const SizedBox(width: 6),
                              Text(
                                '· ${caixa.tipo.nome}',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),

                          // Localização + loja
                          if (caixa.localizacao != null ||
                              caixa.loja != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 11,
                                    color: AppColors.textSecondary),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                  [caixa.loja, caixa.localizacao]
                                      .whereType<String>()
                                      .join(' · '),
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                                ),
                              ],
                            ),
                          ],

                          // Colaborador alocado
                          if (colaborador != null) ...[
                            const SizedBox(height: 5),
                            const Divider(height: 1, thickness: 0.5),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.15),
                                  child: Text(
                                    colaborador.iniciais.length > 1
                                        ? colaborador.iniciais[0]
                                        : colaborador.iniciais,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        colaborador.nome,
                                        style: AppTextStyles.caption
                                            .copyWith(
                                                fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        colaborador.departamento.nome,
                                        style: AppTextStyles.caption
                                            .copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

              // ── Trailing: badge de status ──────────────
              _buildTrailing(isOcupado),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailing(bool isOcupado) {
    if (caixa.emManutencao) {
      return _StatusChip(
          label: 'Manutenção',
          color: AppColors.statusAtencao,
          icon: Icons.build);
    }
    if (!caixa.ativo) {
      return _StatusChip(
          label: 'Inativo',
          color: AppColors.inactive,
          icon: Icons.power_off);
    }
    if (isOcupado) {
      final h = alocacao!.alocadoEm.hour.toString().padLeft(2, '0');
      final m = alocacao!.alocadoEm.minute.toString().padLeft(2, '0');
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _StatusChip(
              label: 'Ocupado',
              color: AppColors.statusAtivo,
              icon: Icons.person),
          const SizedBox(height: 3),
          Text(
            'desde $h:$m',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      );
    }
    return _StatusChip(
        label: 'Disponível',
        color: AppColors.success,
        icon: Icons.check_circle_outline);
  }

  Color _statusColor(bool isOcupado) {
    if (caixa.emManutencao) return AppColors.statusAtencao;
    if (!caixa.ativo) return AppColors.inactive;
    if (isOcupado) return AppColors.statusAtivo;
    return AppColors.success;
  }

  void _showDetalhes(
    BuildContext context,
    Colaborador? colaborador,
    AlocacaoProvider alocacaoProvider,
    EscalaProvider escalaProvider,
    CafeProvider cafeProvider,
  ) {
    final turno = colaborador != null
        ? escalaProvider.turnosHoje
            .where((t) => t.colaboradorId == colaborador.id)
            .firstOrNull
        : null;

    final pausa = colaborador != null
        ? cafeProvider.getPausaAtiva(colaborador.id)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ColaboradorDetalhesSheet(
        caixa: caixa,
        colaborador: colaborador,
        alocacao: alocacao,
        turno: turno,
        pausa: pausa,
        alocacaoProvider: alocacaoProvider,
        providerContext: context,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Badge de status inline
// ─────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusChip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
