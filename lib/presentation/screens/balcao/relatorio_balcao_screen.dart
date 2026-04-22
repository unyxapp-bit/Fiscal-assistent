import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/fiscal_events_provider.dart';

class RelatorioBalcaoScreen extends StatefulWidget {
  const RelatorioBalcaoScreen({super.key});

  @override
  State<RelatorioBalcaoScreen> createState() => _RelatorioBalcaoScreenState();
}

class _RelatorioBalcaoScreenState extends State<RelatorioBalcaoScreen> {
  // 'hoje' | 'semana' | 'mes'
  String _periodo = 'hoje';

  static const _periodoOpcoes = [
    ('hoje', 'Hoje'),
    ('semana', '7 dias'),
    ('mes', '30 dias'),
  ];

  List<FiscalEvent> _eventosFiltrados(List<FiscalEvent> todos) {
    final agora = DateTime.now();
    final inicio = switch (_periodo) {
      'semana' => agora.subtract(const Duration(days: 7)),
      'mes' => agora.subtract(const Duration(days: 30)),
      _ => DateTime(agora.year, agora.month, agora.day),
    };
    return todos.where((e) => e.eventDate.isAfter(inicio)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FiscalEventsProvider>();
    final colaboradorProvider = context.watch<ColaboradorProvider>();
    final eventos = _eventosFiltrados(provider.events);

    final total = eventos.length;
    final pendentes = eventos.where((e) => e.status == 'pending').length;
    final resolvidos = eventos.where((e) => e.status == 'resolved').length;
    final ignorados = eventos.where((e) => e.status == 'ignored').length;

    // Contagem por categoria
    final porCategoria = <String, int>{};
    for (final e in eventos) {
      porCategoria[e.category] = (porCategoria[e.category] ?? 0) + 1;
    }
    final categoriasOrdenadas = porCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top colaboradores
    final porColab = <String, int>{};
    for (final e in eventos) {
      if (e.colaboradorId != null) {
        porColab[e.colaboradorId!] =
            (porColab[e.colaboradorId!] ?? 0) + 1;
      }
    }
    final topColab = porColab.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Eventos de alta prioridade
    final altaPrioridade =
        eventos.where((e) => e.isAlta && e.status == 'pending').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Relatório do Balcão', style: AppTextStyles.h3),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingMD, 0, Dimensions.paddingMD, 24),
        children: [
          // Filtro de período
          _PeriodoSelector(
            selected: _periodo,
            opcoes: _periodoOpcoes,
            onChanged: (v) => setState(() => _periodo = v),
          ),

          const SizedBox(height: 16),

          // Cards de resumo
          Row(children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.campaign_rounded,
                label: 'Total',
                value: '$total',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                icon: Icons.pending_outlined,
                label: 'Pendentes',
                value: '$pendentes',
                color: AppColors.warning,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.check_circle_outline_rounded,
                label: 'Resolvidos',
                value: '$resolvidos',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                icon: Icons.do_not_disturb_on_outlined,
                label: 'Ignorados',
                value: '$ignorados',
                color: AppColors.textSecondary,
              ),
            ),
          ]),

          // Alertas de alta prioridade
          if (altaPrioridade.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(
              icon: Icons.priority_high_rounded,
              label: 'Alta prioridade — pendentes',
              color: AppColors.danger,
            ),
            const SizedBox(height: 10),
            ...altaPrioridade.take(5).map((e) => _EventoResumoTile(
                  event: e,
                  colaboradorNome: e.colaboradorId != null
                      ? colaboradorProvider.todosColaboradores
                          .where((c) => c.id == e.colaboradorId)
                          .firstOrNull
                          ?.nome
                      : null,
                )),
          ],

          // Distribuição por categoria
          if (categoriasOrdenadas.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(
              icon: Icons.bar_chart_rounded,
              label: 'Por categoria',
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: categoriasOrdenadas.map((entry) {
                  final frac = total > 0 ? entry.value / total : 0.0;
                  return _CategoriaBar(
                    categoria: entry.key,
                    count: entry.value,
                    frac: frac,
                  );
                }).toList(),
              ),
            ),
          ],

          // Top colaboradores
          if (topColab.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(
              icon: Icons.people_outline_rounded,
              label: 'Colaboradores com mais eventos',
              color: AppColors.teal,
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(Dimensions.radiusMD),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < topColab.take(5).length; i++) ...[
                    if (i > 0)
                      Divider(
                          height: 1, color: AppColors.divider, indent: 16),
                    _ColabTile(
                      rank: i + 1,
                      colaboradorId: topColab[i].key,
                      count: topColab[i].value,
                      nome: colaboradorProvider.todosColaboradores
                          .where((c) => c.id == topColab[i].key)
                          .firstOrNull
                          ?.nome,
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Eventos recentes (últimos 10)
          if (eventos.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(
              icon: Icons.access_time_rounded,
              label: 'Eventos recentes',
              color: AppColors.blueGrey,
            ),
            const SizedBox(height: 10),
            ...eventos.take(10).map((e) => _EventoResumoTile(
                  event: e,
                  colaboradorNome: e.colaboradorId != null
                      ? colaboradorProvider.todosColaboradores
                          .where((c) => c.id == e.colaboradorId)
                          .firstOrNull
                          ?.nome
                      : null,
                )),
          ],

          if (eventos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text('Sem eventos no período',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  WIDGETS INTERNOS
// ─────────────────────────────────────────────

class _PeriodoSelector extends StatelessWidget {
  final String selected;
  final List<(String, String)> opcoes;
  final ValueChanged<String> onChanged;

  const _PeriodoSelector({
    required this.selected,
    required this.opcoes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: opcoes.map((o) {
          final sel = selected == o.$1;
          return GestureDetector(
            onTap: () => onChanged(o.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.cardBorder,
                  width: 1.5,
                ),
              ),
              child: Text(
                o.$2,
                style: AppTextStyles.caption.copyWith(
                  color: sel ? AppColors.primary : AppColors.textSecondary,
                  fontWeight:
                      sel ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 6),
      Text(label,
          style: AppTextStyles.caption.copyWith(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    ]);
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(Dimensions.radiusMD),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: AppTextStyles.h3.copyWith(color: color)),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ]),
    );
  }
}

class _CategoriaBar extends StatelessWidget {
  final String categoria;
  final int count;
  final double frac;

  const _CategoriaBar(
      {required this.categoria, required this.count, required this.frac});

  static const _labels = <String, String>{
    'caixa': 'Caixa',
    'ausencia': 'Ausência',
    'atestado': 'Atestado',
    'horario_especial': 'Horário Especial',
    'ferias': 'Férias',
    'vale': 'Vale',
    'problema_operacional': 'Problema',
    'aviso_geral': 'Aviso Geral',
    'midia_pendente': 'Mídia',
    'troco': 'Troco',
    'escala': 'Escala',
    'cooperativa': 'Cooperativa',
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[categoria] ?? categoria;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textPrimary)),
            ),
            Text('$count',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 5,
              backgroundColor: AppColors.backgroundSection,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColabTile extends StatelessWidget {
  final int rank;
  final String colaboradorId;
  final int count;
  final String? nome;

  const _ColabTile({
    required this.rank,
    required this.colaboradorId,
    required this.count,
    this.nome,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingMD, vertical: 10),
      child: Row(children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: rank == 1
                ? AppColors.warning.withValues(alpha: 0.15)
                : AppColors.backgroundSection,
            shape: BoxShape.circle,
          ),
          child: Text('$rank',
              style: AppTextStyles.caption.copyWith(
                  color: rank == 1
                      ? AppColors.warning
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(nome ?? colaboradorId,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textPrimary)),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$count evento${count != 1 ? 's' : ''}',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.teal, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _EventoResumoTile extends StatelessWidget {
  final FiscalEvent event;
  final String? colaboradorNome;

  const _EventoResumoTile({required this.event, this.colaboradorNome});

  @override
  Widget build(BuildContext context) {
    final isPending = event.status == 'pending';
    final isResolved = event.status == 'resolved';
    final statusColor = isPending
        ? AppColors.warning
        : isResolved
            ? AppColors.success
            : AppColors.textSecondary;
    final statusLabel =
        isPending ? 'pendente' : isResolved ? 'resolvido' : 'ignorado';

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(Dimensions.radiusMD),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Status dot
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: statusColor),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.description,
                  style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                if (colaboradorNome != null) ...[
                  Icon(Icons.person_rounded,
                      size: 11, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Text(colaboradorNome!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                ],
                Text(
                  DateFormat('dd/MM HH:mm').format(event.eventDate),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(statusLabel,
                      style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}
