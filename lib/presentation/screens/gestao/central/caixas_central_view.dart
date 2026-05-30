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
import '../gargalo_calculator.dart';

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
    final caixasLivres = caixasOperacionais
        .where((c) => alocacao.getAlocacaoCaixa(c.id) == null);
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
        padding: const EdgeInsets.all(24),
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
                const SizedBox(height: 22),
                _CaixasSummaryGrid(
                  disponiveis: disponiveis.length,
                  alocados: alocacao.quantidadeAtivasAgora,
                  emPausa: cafe.totalAtivos,
                  risco: risco,
                ),
                const SizedBox(height: 24),
                Text(
                  'Ações necessárias',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
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
                        title:
                            '${cafe.totalEmAtraso} pausa${cafe.totalEmAtraso > 1 ? 's' : ''} em atraso',
                        description:
                            'Retorne ou realoque antes de abrir nova pausa.',
                        buttonText: 'Ver fila',
                        color: AppColors.danger,
                        onTap: onOpenCafe,
                      ),
                    if (queue.isNotEmpty)
                      _CentralAction(
                        icon: Icons.restaurant_rounded,
                        title:
                            '${queue.length} pausa${queue.length > 1 ? 's' : ''} na fila',
                        description: 'Organize substituições antes de liberar.',
                        buttonText: 'Acompanhar',
                        color: AppColors.statusCafe,
                        onTap: onOpenCafe,
                      ),
                    if (gargalos > 0)
                      _CentralAction(
                        icon: Icons.insights_rounded,
                        title:
                            '$gargalos risco${gargalos > 1 ? 's' : ''} de gargalo',
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
                const SizedBox(height: 24),
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
                        children: [
                          pause,
                          const SizedBox(height: 18),
                          map,
                        ],
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
