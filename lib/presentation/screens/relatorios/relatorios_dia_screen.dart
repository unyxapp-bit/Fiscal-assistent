import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../../domain/entities/relatorio_dia.dart';
import '../../providers/evento_turno_provider.dart';

class RelatoriosDiaScreen extends StatelessWidget {
  const RelatoriosDiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EventoTurnoProvider>(
      builder: (context, provider, _) {
        final relatorios = provider.relatorios;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Relatório do Dia'),
            backgroundColor: AppColors.background,
            elevation: 0,
          ),
          body: relatorios.isEmpty
              ? _buildVazio()
              : ListView.builder(
                  padding: const EdgeInsets.all(Dimensions.paddingMD),
                  itemCount: relatorios.length,
                  itemBuilder: (_, i) => _RelatorioCard(relatorio: relatorios[i]),
                ),
        );
      },
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.summarize_outlined,
              size: 64, color: AppColors.inactive),
          const SizedBox(height: 16),
          Text(
            'Nenhum relatório gerado ainda.\nEncerre o turno na Timeline para gerar um.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Card de relatório ────────────────────────────────────────────────────────

class _RelatorioCard extends StatelessWidget {
  final RelatorioDia relatorio;

  const _RelatorioCard({required this.relatorio});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm');
    final duracao = relatorio.duracaoTurno;
    final horas = duracao.inHours;
    final minutos = duracao.inMinutes.remainder(60);

    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: Dimensions.spacingMD),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        onTap: () => _verDetalhes(context),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho: data + duração
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    dateFmt.format(relatorio.turnoIniciadoEm),
                    style:
                        AppTextStyles.h4.copyWith(color: AppColors.primary),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      horas > 0 ? '${horas}h ${minutos}min' : '${minutos}min',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              Text(
                '${timeFmt.format(relatorio.turnoIniciadoEm)} → ${timeFmt.format(relatorio.turnoEncerradoEm)}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),

              const Divider(height: 16),

              // Totais em grade
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _Stat(
                      icon: Icons.swap_horiz,
                      label: 'Alocações',
                      value: relatorio.totalAlocacoes,
                      color: AppColors.primary),
                  _Stat(
                      icon: Icons.people,
                      label: 'Colaboradores',
                      value: relatorio.totalColaboradores,
                      color: AppColors.statusAtivo),
                  _Stat(
                      icon: Icons.coffee,
                      label: 'Cafés',
                      value: relatorio.totalCafes,
                      color: AppColors.statusCafe),
                  _Stat(
                      icon: Icons.restaurant,
                      label: 'Intervalos',
                      value: relatorio.totalIntervalos,
                      color: AppColors.statusAtencao),
                  _Stat(
                      icon: Icons.inventory_2,
                      label: 'Empacotadores',
                      value: relatorio.totalEmpacotadores,
                      color: const Color(0xFF795548)),
                ],
              ),

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${relatorio.eventos.length} evento(s) registrado(s)',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      size: 16, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verDetalhes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => _RelatorioDetalheScreen(relatorio: relatorio)),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: AppTextStyles.caption.copyWith(color: color),
        ),
      ],
    );
  }
}

// ─── Tela de detalhes de um relatório ─────────────────────────────────────────

class _RelatorioDetalheScreen extends StatelessWidget {
  final RelatorioDia relatorio;

  const _RelatorioDetalheScreen({required this.relatorio});

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Relatório — ${dateFmt.format(relatorio.turnoIniciadoEm)}'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        children: [
          // Resumo
          Card(
            color: AppColors.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RESUMO DO TURNO', style: AppTextStyles.label),
                  const SizedBox(height: 12),
                  _InfoLinha(
                    icon: Icons.play_circle,
                    label: 'Início',
                    value: timeFmt.format(relatorio.turnoIniciadoEm),
                    color: AppColors.statusAtivo,
                  ),
                  const SizedBox(height: 6),
                  _InfoLinha(
                    icon: Icons.flag,
                    label: 'Encerramento',
                    value: timeFmt.format(relatorio.turnoEncerradoEm),
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: 6),
                  _InfoLinha(
                    icon: Icons.timer,
                    label: 'Duração',
                    value: _fmtDuracao(relatorio.duracaoTurno),
                    color: AppColors.primary,
                  ),
                  const Divider(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _Stat(
                          icon: Icons.swap_horiz,
                          label: 'Alocações',
                          value: relatorio.totalAlocacoes,
                          color: AppColors.primary),
                      _Stat(
                          icon: Icons.people,
                          label: 'Colaboradores',
                          value: relatorio.totalColaboradores,
                          color: AppColors.statusAtivo),
                      _Stat(
                          icon: Icons.coffee,
                          label: 'Cafés',
                          value: relatorio.totalCafes,
                          color: AppColors.statusCafe),
                      _Stat(
                          icon: Icons.restaurant,
                          label: 'Intervalos',
                          value: relatorio.totalIntervalos,
                          color: AppColors.statusAtencao),
                      _Stat(
                          icon: Icons.inventory_2,
                          label: 'Empacotadores',
                          value: relatorio.totalEmpacotadores,
                          color: const Color(0xFF795548)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: Dimensions.spacingMD),

          // Lista de eventos
          if (relatorio.eventos.isNotEmpty) ...[
            const Text('EVENTOS DO TURNO', style: AppTextStyles.label),
            const SizedBox(height: 8),
            ...relatorio.eventos.map((evento) {
              final (icon, color) = _iconeCor(evento.tipo);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(icon, size: 14, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(evento.tipo.label,
                              style: AppTextStyles.caption.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w600)),
                          if (evento.colaboradorNome != null)
                            Text(
                              evento.colaboradorNome! +
                                  (evento.caixaNome != null
                                      ? ' → ${evento.caixaNome}'
                                      : '') +
                                  (evento.detalhe != null
                                      ? ' (${evento.detalhe})'
                                      : ''),
                              style: AppTextStyles.caption,
                            ),
                        ],
                      ),
                    ),
                    Text(
                      timeFmt.format(evento.timestamp),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  String _fmtDuracao(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}min';
    return '${m}min';
  }

  (IconData, Color) _iconeCor(TipoEvento tipo) {
    return switch (tipo) {
      TipoEvento.turnoIniciado => (Icons.play_circle, AppColors.statusAtivo),
      TipoEvento.colaboradorAlocado => (Icons.swap_horiz, AppColors.primary),
      TipoEvento.colaboradorLiberado =>
        (Icons.exit_to_app, AppColors.statusSaida),
      TipoEvento.cafeIniciado => (Icons.coffee, AppColors.statusCafe),
      TipoEvento.cafeEncerrado =>
        (Icons.check_circle, AppColors.statusCafe),
      TipoEvento.intervaloIniciado =>
        (Icons.restaurant, AppColors.statusAtencao),
      TipoEvento.intervaloEncerrado =>
        (Icons.check_circle, AppColors.statusAtencao),
      TipoEvento.intervaloMarcadoFeito =>
        (Icons.check_circle_outline, Colors.green),
      TipoEvento.empacotadorAdicionado =>
        (Icons.inventory_2, const Color(0xFF795548)),
      TipoEvento.empacotadorRemovido =>
        (Icons.remove_circle_outline, const Color(0xFF795548)),
    };
  }
}

class _InfoLinha extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoLinha({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text('$label: ',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        Text(value,
            style: AppTextStyles.caption
                .copyWith(fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
