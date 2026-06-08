import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../domain/entities/alocacao.dart';
import '../../../../domain/entities/caixa.dart';
import '../../../../domain/entities/colaborador.dart';
import '../../../../domain/enums/departamento_tipo.dart';
import '../../../providers/alocacao_provider.dart';
import '../../../providers/cafe_provider.dart';
import '../../../providers/caixa_provider.dart';
import '../../../providers/colaborador_provider.dart';
import '../../../providers/escala_provider.dart';
import '../../mapa/widgets/colaborador_detalhes_sheet.dart';
import '../gargalo_calculator.dart';
import '../visao_gargalo_screen.dart';

class CaixasCentralView extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenAlocacao;
  final VoidCallback onOpenMapa;
  final VoidCallback onOpenCafe;
  final VoidCallback onOpenGargalo;

  const CaixasCentralView({
    super.key,
    required this.onRefresh,
    required this.onOpenAlocacao,
    required this.onOpenMapa,
    required this.onOpenCafe,
    required this.onOpenGargalo,
  });

  @override
  Widget build(BuildContext context) {
    final colaboradores = context.watch<ColaboradorProvider>();
    final caixas = context.watch<CaixaProvider>();
    final alocacao = context.watch<AlocacaoProvider>();
    final cafe = context.watch<CafeProvider>();
    final escala = context.watch<EscalaProvider>();

    final alocacoesAtivas = alocacao.getAlocacoesAtivas();
    final alocadosIds = alocacoesAtivas.map((a) => a.colaboradorId).toSet();
    final pausaIds = cafe.pausasAtivas.map((p) => p.colaboradorId).toSet();
    final ativosBase = _colaboradoresOperacionais(colaboradores, escala);
    final disponiveis = ativosBase
        .where((c) => !alocadosIds.contains(c.id) && !pausaIds.contains(c.id))
        .toList();
    final caixasOperacionais = _caixasOperacionais(caixas);
    final caixasLivres = caixasOperacionais.where(
      (c) => alocacao.getAlocacaoCaixa(c.id) == null,
    );
    final gargalos = contarGargalosHoje(
      escala: escala,
      alocacao: alocacao,
      cafe: cafe,
    );
    final risco = cafe.totalEmAtraso + gargalos;
    final sugestaoColaborador =
        disponiveis.isNotEmpty ? disponiveis.first : null;
    final sugestaoCaixa = caixasLivres.isNotEmpty ? caixasLivres.first : null;
    final queue = _buildPauseQueue(escala, alocacao, cafe);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CaixasHeroHeader(
                  risco: risco,
                  gargalos: gargalos,
                  atrasos: cafe.totalEmAtraso,
                ),
                const SizedBox(height: 12),
                _CaixasSummaryGrid(
                  disponiveis: disponiveis.length,
                  alocados: alocacao.quantidadeAtivasAgora,
                  emPausa: cafe.totalAtivos,
                  risco: risco,
                ),
                const SizedBox(height: 14),
                Text(
                  'Ações necessárias',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 10),
                _ActionGrid(
                  actions: [
                    if (sugestaoColaborador != null && sugestaoCaixa != null)
                      _CentralAction(
                        icon: Icons.auto_awesome_rounded,
                        title:
                            '${sugestaoColaborador.nome.split(' ').first} pode cobrir ${_caixaLabel(sugestaoCaixa)}',
                        description:
                            'Sugestão rápida usando colaborador livre e caixa sem alocação.',
                        buttonText: 'Abrir alocação',
                        color: AppColors.primary,
                        onTap: onOpenAlocacao,
                      ),
                    if (cafe.totalEmAtraso > 0)
                      _CentralAction(
                        icon: Icons.timer_off_rounded,
                        title: _countText(
                          cafe.totalEmAtraso,
                          'pausa em atraso',
                          'pausas em atraso',
                        ),
                        description:
                            'Retorne ou realoque antes de abrir nova pausa.',
                        buttonText: 'Ver fila',
                        color: AppColors.danger,
                        onTap: onOpenCafe,
                      ),
                    if (queue.isNotEmpty)
                      _CentralAction(
                        icon: Icons.restaurant_rounded,
                        title: _countText(
                          queue.length,
                          'pausa na fila',
                          'pausas na fila',
                        ),
                        description: 'Organize substituições antes de liberar.',
                        buttonText: 'Acompanhar',
                        color: AppColors.statusCafe,
                        onTap: onOpenCafe,
                      ),
                    if (gargalos > 0)
                      _CentralAction(
                        icon: Icons.insights_rounded,
                        title: _countText(
                          gargalos,
                          'risco de gargalo',
                          'riscos de gargalo',
                        ),
                        description:
                            'Revise cobertura nas próximas faixas de horário.',
                        buttonText: 'Ver gargalo',
                        color: AppColors.warning,
                        onTap: onOpenGargalo,
                      ),
                    if (risco == 0)
                      _CentralAction(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Operação estável',
                        description:
                            'Sem atrasos ou gargalos previstos no momento.',
                        buttonText: 'Abrir mapa',
                        color: AppColors.success,
                        onTap: onOpenMapa,
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 920;
                    final pause = _MiniPauseQueue(queue: queue);
                    final map = _MiniCashierMap(
                      caixas: caixasOperacionais,
                      alocacoes: alocacoesAtivas,
                      colaboradores: colaboradores.todosColaboradores,
                      cafe: cafe,
                      onOpenMapa: onOpenMapa,
                    );

                    if (!wide) {
                      return Column(
                        children: [pause, const SizedBox(height: 18), map],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: pause),
                        const SizedBox(width: 18),
                        Expanded(child: map),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _MiniBottleneckPanel(
                  escala: escala,
                  alocacao: alocacao,
                  cafe: cafe,
                  onOpenGargalo: onOpenGargalo,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// TODO: mover os widgets abaixo para arquivos próprios na próxima fase.
// Mantidos juntos aqui para reduzir risco de quebrar dependências internas.
class _CaixasHeroHeader extends StatelessWidget {
  final int risco;
  final int gargalos;
  final int atrasos;

  const _CaixasHeroHeader({
    required this.risco,
    required this.gargalos,
    required this.atrasos,
  });

  @override
  Widget build(BuildContext context) {
    final color = risco > 0 ? AppColors.warning : AppColors.success;
    final title = risco > 0
        ? _countText(risco, 'ação crítica', 'ações críticas')
        : 'Tudo sob controle';
    final pausasText = atrasos > 0
        ? _countText(atrasos, 'pausa em atraso', 'pausas em atraso')
        : 'Sem pausas atrasadas';
    final gargalosText = gargalos > 0
        ? _countText(gargalos, 'gargalo', 'gargalos')
        : 'sem gargalos';
    final subtitle = risco > 0
        ? '$pausasText - $gargalosText'
        : 'Sem atrasos ou gargalos previstos.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final alert = Container(
            width: constraints.maxWidth >= 780 ? 260 : double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  risco > 0
                      ? Icons.notifications_active_rounded
                      : Icons.check_circle_outline_rounded,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          final headline = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Central Operacional',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Decida quem alocar, quem liberar e onde existe risco de cobertura.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.18,
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 780) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [headline, const SizedBox(height: 8), alert],
            );
          }

          return Row(
            children: [
              Expanded(child: headline),
              const SizedBox(width: 12),
              alert,
            ],
          );
        },
      ),
    );
  }
}

class _CaixasSummaryGrid extends StatelessWidget {
  final int disponiveis;
  final int alocados;
  final int emPausa;
  final int risco;

  const _CaixasSummaryGrid({
    required this.disponiveis,
    required this.alocados,
    required this.emPausa,
    required this.risco,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryInfo(
        icon: Icons.people_alt_rounded,
        value: disponiveis.toString(),
        title: 'Disponíveis',
        subtitle: 'Prontos para caixa',
        color: AppColors.success,
      ),
      _SummaryInfo(
        icon: Icons.point_of_sale_rounded,
        value: alocados.toString(),
        title: 'Alocados',
        subtitle: 'Em operação',
        color: AppColors.primary,
      ),
      _SummaryInfo(
        icon: Icons.restaurant_rounded,
        value: emPausa.toString(),
        title: 'Em pausa',
        subtitle: 'Fora do caixa',
        color: AppColors.statusCafe,
      ),
      _SummaryInfo(
        icon: Icons.warning_rounded,
        value: risco.toString(),
        title: 'Risco',
        subtitle: 'Precisa de ação',
        color: risco > 0 ? AppColors.danger : AppColors.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 76,
          ),
          itemBuilder: (context, index) => _SummaryCard(info: items[index]),
        );
      },
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final List<_CentralAction> actions;

  const _ActionGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 820
            ? 3
            : constraints.maxWidth >= 560
                ? 2
                : 1;

        return GridView.builder(
          itemCount: actions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 122,
          ),
          itemBuilder: (context, index) =>
              _OperationalActionCard(action: actions[index]),
        );
      },
    );
  }
}

class _MiniPauseQueue extends StatelessWidget {
  final List<_PauseQueueEntry> queue;

  const _MiniPauseQueue({required this.queue});

  @override
  Widget build(BuildContext context) {
    final visibleQueue = queue.take(4).toList();
    return _GestaoPanel(
      title: 'Próximas pausas',
      icon: Icons.restaurant_rounded,
      child: visibleQueue.isEmpty
          ? const _PanelEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'Sem pausas pendentes',
              message: 'Nenhum intervalo previsto agora.',
            )
          : Column(
              children: [
                for (int i = 0; i < visibleQueue.length; i++) ...[
                  _PauseQueueCard(item: visibleQueue[i], position: i + 1),
                  if (i < visibleQueue.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _MiniCashierMap extends StatelessWidget {
  final List<Caixa> caixas;
  final List<Alocacao> alocacoes;
  final List<Colaborador> colaboradores;
  final CafeProvider cafe;
  final VoidCallback onOpenMapa;

  const _MiniCashierMap({
    required this.caixas,
    required this.alocacoes,
    required this.colaboradores,
    required this.cafe,
    required this.onOpenMapa,
  });

  @override
  Widget build(BuildContext context) {
    final colabById = {for (final c in colaboradores) c.id: c};
    final alocByCaixa = {for (final a in alocacoes) a.caixaId: a};
    final visible = caixas.take(6).toList();

    return _GestaoPanel(
      title: 'Mapa rápido',
      icon: Icons.map_rounded,
      trailing: TextButton.icon(
        onPressed: onOpenMapa,
        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
        label: const Text('Abrir mapa'),
      ),
      child: visible.isEmpty
          ? const _PanelEmptyState(
              icon: Icons.point_of_sale_outlined,
              title: 'Nenhum caixa carregado',
              message: 'Cadastre ou carregue os caixas para visualizar.',
            )
          : Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final caixa in visible) ...[
                  Builder(
                    builder: (context) {
                      final alocacao = alocByCaixa[caixa.id];
                      final pausa = cafe.getPausaAtivaPorCaixa(caixa.id);
                      final colaborador = colabById[alocacao?.colaboradorId] ??
                          colabById[pausa?.colaboradorId];

                      return _CashierMiniCard(
                        caixa: caixa,
                        alocacao: alocacao,
                        colaborador: colaborador,
                        pausa: pausa,
                        onTap: () => _showCashierDetails(
                          context,
                          caixa,
                          alocacao,
                          colaborador,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
    );
  }

  void _showCashierDetails(
    BuildContext context,
    Caixa caixa,
    Alocacao? alocacao,
    Colaborador? colaborador,
  ) {
    final alocacaoProvider = context.read<AlocacaoProvider>();
    final escalaProvider = context.read<EscalaProvider>();
    final cafeProvider = context.read<CafeProvider>();

    TurnoLocal? turno;
    if (colaborador != null) {
      for (final item in escalaProvider.turnosHoje) {
        if (item.colaboradorId == colaborador.id) {
          turno = item;
          break;
        }
      }
    }

    final pausa = colaborador != null
        ? cafeProvider.getPausaAtiva(colaborador.id)
        : cafeProvider.getPausaAtivaPorCaixa(caixa.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

class _MiniBottleneckPanel extends StatelessWidget {
  final EscalaProvider escala;
  final AlocacaoProvider alocacao;
  final CafeProvider cafe;
  final VoidCallback onOpenGargalo;

  const _MiniBottleneckPanel({
    required this.escala,
    required this.alocacao,
    required this.cafe,
    required this.onOpenGargalo,
  });

  @override
  Widget build(BuildContext context) {
    final slots = _slotsCaixa(escala, alocacao, cafe);
    final temGargalo = slots.any((slot) => slot.gargalo);
    final peak = slots.fold<int>(
      1,
      (value, slot) => slot.quantidade > value ? slot.quantidade : value,
    );

    return _GestaoPanel(
      title: 'Visão de gargalo',
      icon: Icons.insights_rounded,
      trailing: TextButton.icon(
        onPressed: onOpenGargalo,
        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
        label: const Text('Ver detalhes'),
      ),
      child: slots.isEmpty
          ? const _PanelEmptyState(
              icon: Icons.insights_outlined,
              title: 'Sem escala para analisar',
              message: 'Importe ou gere a escala para prever cobertura.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cobertura disponível por faixa de 30 minutos.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final slot in slots)
                        Expanded(
                          child: _BottleneckBar(slot: slot, peak: peak),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (temGargalo ? AppColors.warning : AppColors.success)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          (temGargalo ? AppColors.warning : AppColors.success)
                              .withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        temGargalo
                            ? Icons.auto_awesome_rounded
                            : Icons.check_circle_outline_rounded,
                        color:
                            temGargalo ? AppColors.warning : AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          temGargalo
                              ? 'Sugestão: revise pausas e entradas nas faixas em amarelo/vermelho.'
                              : 'Cobertura projetada estável nas próximas 4h.',
                          style: AppTextStyles.label.copyWith(
                            color: temGargalo
                                ? AppColors.warning
                                : AppColors.success,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final _SummaryInfo info;

  const _SummaryCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _softCard(
        color: info.color.withValues(alpha: 0.06),
        borderColor: info.color.withValues(alpha: 0.18),
        radius: 16,
        elevated: false,
      ),
      child: Row(
        children: [
          _IconBox(icon: info.icon, color: info.color, size: 38),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  info.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: info.color,
                    letterSpacing: 0,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    fontSize: 11.5,
                  ),
                ),
                Text(
                  info.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationalActionCard extends StatelessWidget {
  final _CentralAction action;

  const _OperationalActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _softCard(
        color: action.color.withValues(alpha: 0.06),
        borderColor: action.color.withValues(alpha: 0.22),
        radius: 16,
        elevated: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(icon: action.icon, color: action.color, size: 28),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: action.color, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            action.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h4.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            action.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              height: 1.05,
            ),
          ),
          const Spacer(),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: action.color,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 26),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              textStyle: AppTextStyles.caption.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            onPressed: action.onTap,
            child: Text(
              action.buttonText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GestaoPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _GestaoPanel({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _softCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(icon: icon, color: AppColors.primary, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PauseQueueCard extends StatelessWidget {
  final _PauseQueueEntry item;
  final int position;

  const _PauseQueueCard({required this.item, required this.position});

  @override
  Widget build(BuildContext context) {
    final color = item.canGoNow ? AppColors.statusCafe : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _softCard(
        color: item.canGoNow ? const Color(0xFFFFF7ED) : Colors.white,
        borderColor: color.withValues(alpha: 0.22),
        radius: 18,
        elevated: false,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '$position',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${item.role} - ${item.scheduledTime}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  item.delay,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: item.canGoNow ? () {} : null,
            icon: const Icon(Icons.restaurant_rounded, size: 18),
            label: const Text('Pausa'),
          ),
        ],
      ),
    );
  }
}

class _CashierMiniCard extends StatelessWidget {
  final Caixa caixa;
  final Alocacao? alocacao;
  final Colaborador? colaborador;
  final PausaCafe? pausa;
  final VoidCallback onTap;

  const _CashierMiniCard({
    required this.caixa,
    required this.alocacao,
    required this.colaborador,
    required this.pausa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = _cashierStatus(caixa, alocacao, pausa);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 190,
          height: 150,
          padding: const EdgeInsets.all(16),
          decoration: _softCard(
            color: status.color.withValues(alpha: 0.06),
            borderColor: status.color.withValues(alpha: 0.25),
            radius: 18,
            elevated: false,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.point_of_sale_rounded, color: status.color),
                ],
              ),
              const Spacer(),
              Text(
                _caixaLabel(caixa),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                caixa.localizacao?.trim().isNotEmpty == true
                    ? caixa.localizacao!
                    : caixa.tipo.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                colaborador?.nome ??
                    pausa?.colaboradorNome ??
                    status.operatorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    AppTextStyles.label.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                '${status.label} - ${status.note}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottleneckBar extends StatelessWidget {
  final SlotDisponibilidade slot;
  final int peak;

  const _BottleneckBar({required this.slot, required this.peak});

  @override
  Widget build(BuildContext context) {
    final color = slot.gargalo
        ? (slot.quantidade < slot.capacidadeMinima
            ? AppColors.danger
            : AppColors.warning)
        : AppColors.success;
    final barHeight = (34 + (slot.quantidade / peak) * 74).clamp(34.0, 112.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${slot.quantidade}',
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 46,
          height: barHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatTime(slot.inicio),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PanelEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _PanelEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _IconBox(icon: icon, color: AppColors.primary, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  message,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _IconBox({required this.icon, required this.color, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size <= 30 ? 9 : 12),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

class _SummaryInfo {
  final IconData icon;
  final String value;
  final String title;
  final String subtitle;
  final Color color;

  const _SummaryInfo({
    required this.icon,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _CentralAction {
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final Color color;
  final VoidCallback onTap;

  const _CentralAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.color,
    required this.onTap,
  });
}

class _PauseQueueEntry {
  final String name;
  final String role;
  final String scheduledTime;
  final String delay;
  final bool canGoNow;

  const _PauseQueueEntry({
    required this.name,
    required this.role,
    required this.scheduledTime,
    required this.delay,
    required this.canGoNow,
  });
}

class _CashierStatusInfo {
  final String label;
  final String operatorName;
  final String note;
  final Color color;

  const _CashierStatusInfo({
    required this.label,
    required this.operatorName,
    required this.note,
    required this.color,
  });
}

BoxDecoration _softCard({
  Color? color,
  Color? borderColor,
  double radius = 24,
  bool elevated = true,
}) {
  return BoxDecoration(
    color: color ?? AppColors.cardBackground,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? AppColors.cardBorder),
    boxShadow: elevated
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ]
        : null,
  );
}

List<Colaborador> _colaboradoresOperacionais(
  ColaboradorProvider colaboradores,
  EscalaProvider escala,
) {
  final ativos =
      colaboradores.todosColaboradores.where((c) => c.ativo).toList();
  final trabalhandoIds =
      escala.trabalhandoHoje.map((t) => t.colaboradorId).toSet();
  if (trabalhandoIds.isEmpty) return ativos;
  return ativos.where((c) => trabalhandoIds.contains(c.id)).toList();
}

List<Caixa> _caixasOperacionais(CaixaProvider provider) {
  final caixas = [
    ...(provider.caixasTodos.isNotEmpty
        ? provider.caixasTodos
        : provider.caixas),
  ]..sort((a, b) => a.numero.compareTo(b.numero));
  return caixas;
}

List<_PauseQueueEntry> _buildPauseQueue(
  EscalaProvider escala,
  AlocacaoProvider alocacao,
  CafeProvider cafe,
) {
  final now = DateTime.now();
  final entries = <_PauseQueueEntry>[];

  for (final turno in escala.trabalhandoHoje) {
    if (turno.intervalo == null || turno.intervalo!.trim().isEmpty) continue;
    if (alocacao.isIntervaloMarcado(turno.colaboradorId)) continue;
    if (cafe.colaboradorJaFezIntervaloHoje(turno.colaboradorId)) continue;

    final pausaAtiva = cafe.getPausaAtiva(turno.colaboradorId);
    final scheduled = _parseTimeToday(turno.intervalo!, now);
    if (scheduled == null && pausaAtiva == null) continue;

    final diff = scheduled?.difference(now).inMinutes ?? 0;
    final delay = pausaAtiva != null
        ? 'Em pausa'
        : diff < 0
            ? '+${diff.abs()} min'
            : diff <= 15
                ? 'Agora'
                : diff <= 45
                    ? 'Próxima'
                    : 'Em ${diff ~/ 60 > 0 ? '${diff ~/ 60}h ' : ''}${diff.remainder(60)}min';

    entries.add(
      _PauseQueueEntry(
        name: turno.colaboradorNome,
        role: turno.departamento.nome,
        scheduledTime: turno.intervalo!,
        delay: delay,
        canGoNow: pausaAtiva == null && diff <= 15,
      ),
    );
  }

  entries.sort((a, b) {
    final aMin = _minutes(a.scheduledTime);
    final bMin = _minutes(b.scheduledTime);
    return aMin.compareTo(bMin);
  });
  return entries;
}

List<SlotDisponibilidade> _slotsCaixa(
  EscalaProvider escala,
  AlocacaoProvider alocacao,
  CafeProvider cafe,
) {
  final turnos = escala.turnosHoje;
  if (turnos.isEmpty) return const [];

  final alocacaoByColab = {
    for (final a in alocacao.getAlocacoesAtivas()) a.colaboradorId: a,
  };
  final pausaByColab = {for (final p in cafe.pausasAtivas) p.colaboradorId: p};
  final status = turnos
      .map(
        (t) => StatusColaboradorCompleto(
          turno: t,
          alocacao: alocacaoByColab[t.colaboradorId],
          pausaAtiva: pausaByColab[t.colaboradorId],
        ),
      )
      .toList();

  final inicio = _floorToSlot(DateTime.now());
  final fim = inicio.add(const Duration(hours: 4));
  return GargaloCalculator(
    status,
    inicio: inicio,
    fim: fim,
  ).calcularPorSetor(DepartamentoTipo.caixa);
}

_CashierStatusInfo _cashierStatus(
  Caixa caixa,
  Alocacao? alocacao,
  PausaCafe? pausa,
) {
  if (caixa.emManutencao) {
    return _CashierStatusInfo(
      label: 'Manutenção',
      operatorName: 'Indisponível',
      note: 'Aguardando ajuste',
      color: AppColors.danger,
    );
  }
  if (!caixa.ativo) {
    return _CashierStatusInfo(
      label: 'Fechado',
      operatorName: 'Inativo',
      note: 'Fora da operação',
      color: AppColors.inactive,
    );
  }
  if (pausa != null && alocacao == null) {
    return _CashierStatusInfo(
      label: 'Pausa',
      operatorName: 'Em pausa',
      note: 'Retorno pendente',
      color: AppColors.statusCafe,
    );
  }
  if (alocacao != null) {
    return _CashierStatusInfo(
      label: 'Ativo',
      operatorName: 'Operando',
      note: 'Operando normal',
      color: AppColors.success,
    );
  }
  return _CashierStatusInfo(
    label: 'Livre',
    operatorName: 'Livre',
    note: 'Pronto para cobertura',
    color: AppColors.primary,
  );
}

DateTime _floorToSlot(DateTime dt) {
  final base = DateTime(dt.year, dt.month, dt.day);
  final totalMin = dt.hour * 60 + dt.minute;
  final slotMin = (totalMin ~/ 30) * 30;
  return base.add(Duration(minutes: slotMin));
}

DateTime? _parseTimeToday(String hhmm, DateTime base) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return DateTime(base.year, base.month, base.day, h, m);
}

int _minutes(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return 0;
  return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
}

String _countText(int count, String singular, String plural) {
  return '$count ${count == 1 ? singular : plural}';
}

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _caixaLabel(Caixa caixa) {
  return 'CX${caixa.numero.toString().padLeft(2, '0')}';
}
