import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/cafe_provider.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/entrega_provider.dart';
import '../../providers/colaborador_provider.dart';

class RelatorioDiarioScreen extends StatelessWidget {
  const RelatorioDiarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cafe = context.watch<CafeProvider>();
    final alocacao = context.watch<AlocacaoProvider>();
    final entrega = context.watch<EntregaProvider>();
    final colaborador = context.watch<ColaboradorProvider>();

    final hoje = DateTime.now();
    final dataFormatada =
        DateFormat("EEEE, d 'de' MMMM 'de' y", 'pt_BR').format(hoje);
    final horaFormatada = DateFormat('HH:mm').format(hoje);

    // ── Métricas de pausas ─────────────────────────────────────────────────
    final totalPausasHoje = cafe.totalHoje;
    final pausasEmAtraso = cafe.totalEmAtraso;
    final pausasAtivas = cafe.totalAtivos;
    final mediaDuracaoPausas = _calcularMediaDuracao(cafe.pausas);

    // ── Métricas de alocações ──────────────────────────────────────────────
    final alocacoesAtivas = alocacao.quantidadeAtivasAgora;
    final alocacoesLiberadas = alocacao.quantidadeLiberadas;

    // ── Métricas de entregas ───────────────────────────────────────────────
    final entregasSep = entrega.totalSeparadas;
    final entregasRota = entrega.totalEmRota;
    final entregasConc = entrega.totalEntregues;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Relatório do Dia'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabeçalho ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bar_chart, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Resumo do Turno',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dataFormatada,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    'Gerado às $horaFormatada',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Seção: Pausas / Café ─────────────────────────────────────
            const _SectionTitle(
              icon: Icons.coffee,
              label: 'Pausas / Café',
              color: Color(0xFF8D6E63),
            ),
            const SizedBox(height: 10),

            _MetricGrid(metrics: [
              _MetricItem(
                label: 'Total Hoje',
                value: '$totalPausasHoje',
                icon: Icons.coffee,
                color: const Color(0xFF8D6E63),
              ),
              _MetricItem(
                label: 'Em Pausa',
                value: '$pausasAtivas',
                icon: Icons.pause_circle,
                color: AppColors.statusAtencao,
              ),
              _MetricItem(
                label: 'Em Atraso',
                value: '$pausasEmAtraso',
                icon: Icons.warning_rounded,
                color: AppColors.danger,
              ),
              _MetricItem(
                label: 'Média',
                value: mediaDuracaoPausas,
                icon: Icons.timer,
                color: AppColors.primary,
              ),
            ]),

            const SizedBox(height: 20),

            // ── Seção: Alocações ─────────────────────────────────────────
            const _SectionTitle(
              icon: Icons.point_of_sale,
              label: 'Alocações no Caixa',
              color: AppColors.statusAtivo,
            ),
            const SizedBox(height: 10),

            _MetricGrid(metrics: [
              _MetricItem(
                label: 'Ativas Agora',
                value: '$alocacoesAtivas',
                icon: Icons.swap_horiz,
                color: AppColors.statusAtivo,
              ),
              _MetricItem(
                label: 'Finalizadas',
                value: '$alocacoesLiberadas',
                icon: Icons.check_circle_outline,
                color: AppColors.success,
              ),
              _MetricItem(
                label: 'Total Hoje',
                value: '${alocacoesAtivas + alocacoesLiberadas}',
                icon: Icons.history,
                color: AppColors.primary,
              ),
            ]),

            const SizedBox(height: 20),

            // ── Seção: Entregas ──────────────────────────────────────────
            const _SectionTitle(
              icon: Icons.local_shipping,
              label: 'Entregas',
              color: Color(0xFFFF9800),
            ),
            const SizedBox(height: 10),

            _MetricGrid(metrics: [
              _MetricItem(
                label: 'Separadas',
                value: '$entregasSep',
                icon: Icons.inventory,
                color: const Color(0xFFFF9800),
              ),
              _MetricItem(
                label: 'Em Rota',
                value: '$entregasRota',
                icon: Icons.local_shipping,
                color: AppColors.primary,
              ),
              _MetricItem(
                label: 'Concluídas',
                value: '$entregasConc',
                icon: Icons.done_all,
                color: AppColors.success,
              ),
            ]),

            const SizedBox(height: 20),

            // ── Seção: Equipe ─────────────────────────────────────────────
            const _SectionTitle(
              icon: Icons.groups,
              label: 'Equipe',
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),

            _MetricGrid(metrics: [
              _MetricItem(
                label: 'Total Ativos',
                value: '${colaborador.totalAtivos}',
                icon: Icons.people,
                color: AppColors.primary,
              ),
              _MetricItem(
                label: 'Caixa',
                value: '${colaborador.totalCaixa}',
                icon: Icons.point_of_sale,
                color: AppColors.statusAtivo,
              ),
              _MetricItem(
                label: 'Self',
                value: '${colaborador.totalSelf}',
                icon: Icons.store,
                color: const Color(0xFF9C27B0),
              ),
              _MetricItem(
                label: 'Pacote',
                value: '${colaborador.totalPacote}',
                icon: Icons.inventory_2,
                color: const Color(0xFFFF9800),
              ),
            ]),

            const SizedBox(height: 20),

            // ── Rodapé ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inactive.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Fiscal Assistant • $dataFormatada às $horaFormatada',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _calcularMediaDuracao(List<PausaCafe> pausas) {
    final finalizadas = pausas.where((p) => !p.ativo).toList();
    if (finalizadas.isEmpty) return '—';
    final totalMin =
        finalizadas.fold<int>(0, (sum, p) => sum + p.minutosDecorridos);
    final media = totalMin ~/ finalizadas.length;
    return '${media}min';
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.h4
              .copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: color.withValues(alpha: 0.3))),
      ],
    );
  }
}

class _MetricItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricItem> metrics;

  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.1,
      children: metrics
          .map(
            (m) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: m.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: m.color.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(m.icon, color: m.color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    m.value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: m.color,
                    ),
                  ),
                  Text(
                    m.label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
