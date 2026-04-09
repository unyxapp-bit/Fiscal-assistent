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

    final pausaCaixa = cafeProvider.getPausaAtivaPorCaixa(caixa.id);
    final isOcupado = alocacao != null;
    final isEmPausa = pausaCaixa != null && !isOcupado;

    // Colaborador em pausa (para buscar turno mesmo sem alocação ativa)
    final colaboradorEmPausa = isEmPausa && pausaCaixa.colaboradorId.isNotEmpty
        ? colaboradorProvider.colaboradores
            .where((c) => c.id == pausaCaixa.colaboradorId)
            .firstOrNull
        : null;

    final colaboradorRef = colaborador ?? colaboradorEmPausa;

    final turno = colaboradorRef != null
        ? escalaProvider.turnosHoje
            .where((t) => t.colaboradorId == colaboradorRef.id)
            .firstOrNull
        : null;

    // Situação do intervalo agendado (apenas quando ocupado e não em pausa real)
    final bool intervaloJaFeito = colaborador != null &&
        (alocacaoProvider.isIntervaloMarcado(colaborador.id) ||
            cafeProvider.colaboradorJaFezIntervaloHoje(colaborador.id));
    final int? minIntervalo = isOcupado && !isEmPausa && !intervaloJaFeito
        ? _calcMinIntervalo(turno)
        : null;
    final bool emAtencao = minIntervalo != null && minIntervalo >= 15;

    final statusColor =
        _statusColor(isOcupado, isEmPausa, emAtencao: emAtencao);

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _showDetalhes(
          context,
          colaboradorRef,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                  size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(caixa.nomeExibicao, style: AppTextStyles.h4),
                              const SizedBox(width: 6),
                              Text(
                                '· ${caixa.tipo.nome}',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textSecondary),
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
                                    size: 11, color: AppColors.textSecondary),
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
                                      AppColors.primary.withValues(alpha: 0.10),
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
                                        style: AppTextStyles.caption.copyWith(
                                            fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        colaborador.departamento.nome,
                                        style: AppTextStyles.caption.copyWith(
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

                          // Colaborador em pausa (sem alocação ativa)
                          if (isEmPausa && colaboradorEmPausa != null) ...[
                            const SizedBox(height: 5),
                            const Divider(height: 1, thickness: 0.5),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor:
                                      Colors.orange.withValues(alpha: 0.14),
                                  child: Text(
                                    colaboradorEmPausa.iniciais.length > 1
                                        ? colaboradorEmPausa.iniciais[0]
                                        : colaboradorEmPausa.iniciais,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    colaboradorEmPausa.nome,
                                    style: AppTextStyles.caption
                                        .copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                    _buildTrailing(
                      isOcupado,
                      isEmPausa,
                      pausaCaixa,
                      turno,
                      emAtencao: emAtencao,
                      minIntervalo: minIntervalo,
                    ),
                  ],
                ),
              ),

              // ── Faixa: situação do intervalo agendado ──────────
              if (minIntervalo != null && minIntervalo > -60)
                _buildIntervaloBar(minIntervalo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailing(
    bool isOcupado,
    bool isEmPausa,
    PausaCafe? pausaCaixa,
    TurnoLocal? turno, {
    bool emAtencao = false,
    int? minIntervalo,
  }) {
    if (caixa.emManutencao) {
      return const _StatusChip(
          label: 'Manutenção',
          color: AppColors.statusAtencao,
          icon: Icons.build);
    }
    if (!caixa.ativo) {
      return const _StatusChip(
          label: 'Inativo', color: AppColors.inactive, icon: Icons.power_off);
    }
    if (isOcupado) {
      final entradaEscalaRaw = turno?.entrada;
      final entradaEscala =
          (entradaEscalaRaw != null && entradaEscalaRaw.isNotEmpty)
              ? entradaEscalaRaw
              : null;
      final h = alocacao!.alocadoEm.hour.toString().padLeft(2, '0');
      final m = alocacao!.alocadoEm.minute.toString().padLeft(2, '0');
      final horarioLabel = entradaEscala ?? '$h:$m';
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          emAtencao
              ? _StatusChip(
                  label: '${minIntervalo}min atraso',
                  color: AppColors.danger,
                  icon: Icons.warning_amber_rounded,
                )
              : const _StatusChip(
                  label: 'Ocupado',
                  color: AppColors.statusAtivo,
                  icon: Icons.person),
          const SizedBox(height: 3),
          Text(
            entradaEscala != null
                ? 'entrada $horarioLabel'
                : 'desde $horarioLabel',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      );
    }
    if (isEmPausa && pausaCaixa != null) {
      final isCafe = pausaCaixa.isCafe;
      final label = isCafe
          ? 'Café ${pausaCaixa.minutosDecorridos}min'
          : 'Intervalo ${pausaCaixa.minutosDecorridos}min';
      final cor =
          pausaCaixa.emAtraso ? AppColors.danger : Colors.orange.shade700;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _StatusChip(
            label: isCafe ? 'Em Café' : 'Em Intervalo',
            color: cor,
            icon: isCafe ? Icons.coffee : Icons.restaurant,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: cor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    return const _StatusChip(
        label: 'Disponível',
        color: AppColors.success,
        icon: Icons.check_circle_outline);
  }

  Widget _buildIntervaloBar(int min) {
    final Color cor;
    final IconData icone;
    final String texto;

    if (min < 0) {
      // Countdown: faltam minutos
      cor = Colors.orange.shade800;
      icone = Icons.schedule;
      texto = 'Intervalo em ${-min}min';
    } else if (min < 15) {
      // Atraso leve (0–14 min)
      cor = Colors.orange.shade900;
      icone = Icons.warning_amber;
      texto = '${min}min em atraso para o intervalo';
    } else {
      // Em atenção (15+ min)
      cor = AppColors.danger;
      icone = Icons.error_outline;
      texto = '${min}min sem intervalo — Em Atenção';
    }

    final bgColor = min >= 15
        ? AppColors.danger.withValues(alpha: 0.08)
        : min >= 0
            ? Colors.orange.shade100
            : Colors.orange.shade50;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: bgColor,
      child: Row(
        children: [
          Icon(icone, size: 13, color: cor),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              color: cor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Positivo = minutos ATRASADO; Negativo = minutos RESTANTES; null = sem horário
  int? _calcMinIntervalo(TurnoLocal? turno) {
    if (turno?.intervalo == null) return null;
    final parts = turno!.intervalo!.split(':');
    if (parts.length < 2) return null;
    final agora = DateTime.now();
    final agoraMin = agora.hour * 60 + agora.minute;
    final intervaloMin =
        (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    return agoraMin -
        intervaloMin; // negativo = falta tempo, positivo = atrasado
  }

  Color _statusColor(bool isOcupado, bool isEmPausa, {bool emAtencao = false}) {
    if (caixa.emManutencao) return AppColors.statusAtencao;
    if (!caixa.ativo) return AppColors.inactive;
    if (isOcupado) return emAtencao ? AppColors.danger : AppColors.statusAtivo;
    if (isEmPausa) return Colors.orange;
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

    final pausa =
        colaborador != null ? cafeProvider.getPausaAtiva(colaborador.id) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSheet)),
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
        border: Border.all(color: color.withValues(alpha: 0.28)),
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
