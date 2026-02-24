import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/enums/status_presenca.dart';
import '../../providers/snapshot_provider.dart';
import '../../providers/cafe_provider.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/entrega_provider.dart';
import '../../providers/colaborador_provider.dart';

class RelatorioDiarioScreen extends StatelessWidget {
  const RelatorioDiarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final snapshotProv = context.watch<SnapshotProvider>();
    final cafe = context.watch<CafeProvider>();
    final alocacao = context.watch<AlocacaoProvider>();
    final entrega = context.watch<EntregaProvider>();
    final colaborador = context.watch<ColaboradorProvider>();

    final hoje = DateTime.now();
    final dataFormatada =
        DateFormat("EEEE, d 'de' MMMM 'de' y", 'pt_BR').format(hoje);
    final horaFormatada = DateFormat('HH:mm').format(hoje);

    final snap = snapshotProv.snapshotAtual;

    // ── Métricas de presença ────────────────────────────────────────────────
    final totalEscala = snap?.totalAtivos ?? 0;
    final confirmados = snap?.totalConfirmados ?? 0;
    final atrasados = snap?.presencas
            .where((p) => p.status == StatusPresenca.atrasado)
            .length ??
        0;
    final ausentes = snap?.totalAusentes ?? 0;
    final pendentes = snap?.totalPendentes ?? 0;
    final folgas = snap?.totalComFolga ?? 0;
    final substituicoes =
        snap?.presencas.where((p) => p.foiSubstituido).length ?? 0;
    final percentual = snap?.percentualPresenca ?? 0.0;

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

    // ── Colaboradores por departamento ─────────────────────────────────────
    final colabs = colaborador.colaboradores;

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
                  Row(
                    children: [
                      const Icon(Icons.bar_chart, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      const Text(
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

            // ── Seção: Presença ──────────────────────────────────────────
            _SectionTitle(
              icon: Icons.people,
              label: 'Presença',
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),

            if (snap != null) ...[
              // Barra de presença
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percentual / 100,
                      backgroundColor:
                          AppColors.inactive.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(
                          _presencaColor(percentual)),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${percentual.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _presencaColor(percentual),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inactive.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Nenhum snapshot criado hoje. Acesse a tela de Check-in para registrar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              const SizedBox(height: 10),
            ],

            _MetricGrid(metrics: [
              _MetricItem(
                label: 'Escala Hoje',
                value: '$totalEscala',
                icon: Icons.calendar_today,
                color: AppColors.primary,
              ),
              _MetricItem(
                label: 'Confirmados',
                value: '$confirmados',
                icon: Icons.check_circle,
                color: AppColors.success,
              ),
              _MetricItem(
                label: 'Atrasados',
                value: '$atrasados',
                icon: Icons.schedule,
                color: AppColors.statusAtencao,
              ),
              _MetricItem(
                label: 'Ausências',
                value: '$ausentes',
                icon: Icons.cancel,
                color: AppColors.danger,
              ),
              _MetricItem(
                label: 'Pendentes',
                value: '$pendentes',
                icon: Icons.pending,
                color: StatusPresenca.pendente.cor,
              ),
              _MetricItem(
                label: 'Folgas',
                value: '$folgas',
                icon: Icons.beach_access,
                color: AppColors.inactive,
              ),
            ]),

            if (substituicoes > 0) ...[
              const SizedBox(height: 8),
              _InfoChip(
                icon: Icons.swap_horiz,
                label: '$substituicoes substituição${substituicoes > 1 ? 'ões' : ''} registrada${substituicoes > 1 ? 's' : ''}',
                color: const Color(0xFF9C27B0),
              ),
            ],

            const SizedBox(height: 20),

            // ── Seção: Pausas / Café ─────────────────────────────────────
            _SectionTitle(
              icon: Icons.coffee,
              label: 'Pausas / Café',
              color: const Color(0xFF8D6E63),
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
            _SectionTitle(
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
            _SectionTitle(
              icon: Icons.local_shipping,
              label: 'Entregas',
              color: const Color(0xFFFF9800),
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
            _SectionTitle(
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

            // ── Ausências Registradas ────────────────────────────────────
            if (snap != null && ausentes > 0) ...[
              _SectionTitle(
                icon: Icons.person_off,
                label: 'Ausências Registradas',
                color: AppColors.danger,
              ),
              const SizedBox(height: 8),
              ...snap.presencas
                  .where((p) => p.status == StatusPresenca.ausente)
                  .map((p) {
                final nome = _nomeFromColabs(colabs, p.colaboradorId);
                final nomeSubstituto = p.substituidoPor != null
                    ? _nomeFromColabs(colabs, p.substituidoPor!)
                    : null;
                return _AbsenceRow(
                  nome: nome,
                  motivo: p.observacao,
                  nomeSubstituto: nomeSubstituto,
                );
              }),
              const SizedBox(height: 12),
            ],

            // ── Rodapé ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inactive.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'CISS Fiscal Assistant • $dataFormatada às $horaFormatada',
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

  String _nomeFromColabs(List<dynamic> colabs, String id) {
    try {
      return (colabs.firstWhere((c) => c.id == id)).nome as String;
    } catch (_) {
      return id.length > 6 ? id.substring(0, 6).toUpperCase() : id;
    }
  }

  Color _presencaColor(double pct) {
    if (pct >= 90) return AppColors.success;
    if (pct >= 70) return AppColors.statusAtencao;
    return AppColors.danger;
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
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

class _AbsenceRow extends StatelessWidget {
  final String nome;
  final String? motivo;
  final String? nomeSubstituto;

  const _AbsenceRow({
    required this.nome,
    this.motivo,
    this.nomeSubstituto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_off, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (motivo != null)
                  Text(
                    motivo!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                if (nomeSubstituto != null)
                  Text(
                    'Substituído por $nomeSubstituto',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.success),
                  ),
              ],
            ),
          ),
          if (nomeSubstituto != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Coberto',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
