import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../../domain/entities/relatorio_dia.dart';
import '../../providers/evento_turno_provider.dart';

// Cor do departamento de açougue / empacotador (usada em eventos de empacotamento)
const _kBrown = Color(0xFF795548);

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
              : Column(
                  children: [
                    _buildHeader(relatorios),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(Dimensions.paddingMD),
                        itemCount: relatorios.length,
                        itemBuilder: (_, i) => _RelatorioCard(
                          relatorio: relatorios[i],
                          onExcluir: () => _confirmarExclusao(
                              context, provider, relatorios[i]),
                          onCompartilhar: () => _compartilhar(relatorios[i]),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ── Cabeçalho da lista ────────────────────────────────────────────────────

  Widget _buildHeader(List<RelatorioDia> relatorios) {
    final periodoMin = relatorios.last.turnoIniciadoEm;
    final periodoMax = relatorios.first.turnoEncerradoEm;
    final dateFmt = DateFormat('dd/MM/yy');
    final periodo = relatorios.length == 1
        ? dateFmt.format(periodoMin)
        : '${dateFmt.format(periodoMin)} – ${dateFmt.format(periodoMax)}';

    return Container(
      margin: const EdgeInsets.fromLTRB(
          Dimensions.paddingMD, Dimensions.paddingMD, Dimensions.paddingMD, 0),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Dimensions.radiusMD),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.summarize_outlined,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${relatorios.length} relatório${relatorios.length != 1 ? 's' : ''} · $periodo',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Estado vazio ──────────────────────────────────────────────────────────

  Widget _buildVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.summarize_outlined,
                  size: 56, color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhum relatório ainda',
              style: AppTextStyles.h3
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Encerre o turno na aba Timeline para gerar automaticamente o relatório do dia.',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Ações ─────────────────────────────────────────────────────────────────

  void _confirmarExclusao(BuildContext context, EventoTurnoProvider provider,
      RelatorioDia relatorio) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Relatório'),
        content: Text(
            'Excluir o relatório de ${dateFmt.format(relatorio.turnoIniciadoEm)}? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.removerRelatorio(relatorio.id);
            },
            child: Text('Excluir',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _compartilhar(RelatorioDia relatorio) {
    Share.share(_gerarTexto(relatorio),
        subject:
            'Relatório do turno — ${DateFormat('dd/MM/yyyy').format(relatorio.turnoIniciadoEm)}');
  }

  static String _gerarTexto(RelatorioDia r) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm');
    final dur = r.duracaoTurno;
    final durStr = dur.inHours > 0
        ? '${dur.inHours}h ${dur.inMinutes.remainder(60).toString().padLeft(2, '0')}min'
        : '${dur.inMinutes}min';

    final buf = StringBuffer();
    buf.writeln('Relatório do Turno — ${dateFmt.format(r.turnoIniciadoEm)}');
    buf.writeln(
        '⏰ ${timeFmt.format(r.turnoIniciadoEm)} → ${timeFmt.format(r.turnoEncerradoEm)} ($durStr)');
    buf.writeln();
    buf.writeln('Resumo:');
    buf.writeln('• ${r.totalAlocacoes} alocações');
    buf.writeln('• ${r.totalColaboradores} colaboradores');
    buf.writeln('• ${r.totalCafes} cafés');
    buf.writeln('• ${r.totalIntervalos} intervalos');
    if (r.totalEmpacotadores > 0) {
      buf.writeln('• ${r.totalEmpacotadores} empacotadores');
    }

    // Eventos especiais
    final ocorrencias = r.eventos
        .where((e) => e.tipo == TipoEvento.ocorrenciaRegistrada)
        .length;
    final checklists = r.eventos
        .where((e) => e.tipo == TipoEvento.checklistConcluido)
        .length;
    final formularios = r.eventos
        .where((e) => e.tipo == TipoEvento.formularioRespondido)
        .length;
    if (ocorrencias > 0) buf.writeln('• $ocorrencias ocorrência(s) registrada(s)');
    if (checklists > 0) buf.writeln('• $checklists checklist(s) concluído(s)');
    if (formularios > 0) buf.writeln('• $formularios formulário(s) respondido(s)');

    if (r.eventos.isNotEmpty) {
      buf.writeln();
      buf.writeln('Eventos:');
      for (final e in r.eventos) {
        final hora = timeFmt.format(e.timestamp);
        final partes = [
          hora,
          e.tipo.label,
          if (e.colaboradorNome != null) e.colaboradorNome!,
          if (e.caixaNome != null) '→ ${e.caixaNome}',
          if (e.detalhe != null) '(${e.detalhe})',
        ];
        buf.writeln(partes.join(' '));
      }
    }

    return buf.toString().trim();
  }
}

// ─── Card de relatório ─────────────────────────────────────────────────────

class _RelatorioCard extends StatelessWidget {
  final RelatorioDia relatorio;
  final VoidCallback onExcluir;
  final VoidCallback onCompartilhar;

  const _RelatorioCard({
    required this.relatorio,
    required this.onExcluir,
    required this.onCompartilhar,
  });

  String _dateBadge(DateTime dt) {
    final hoje = DateTime.now();
    final ontem = hoje.subtract(const Duration(days: 1));
    if (dt.year == hoje.year &&
        dt.month == hoje.month &&
        dt.day == hoje.day) return 'Hoje';
    if (dt.year == ontem.year &&
        dt.month == ontem.month &&
        dt.day == ontem.day) return 'Ontem';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm');
    final duracao = relatorio.duracaoTurno;
    final horas = duracao.inHours;
    final minutos = duracao.inMinutes.remainder(60);
    final badge = _dateBadge(relatorio.turnoIniciadoEm);

    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: Dimensions.spacingMD),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        onTap: () => _verDetalhes(context),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho: data + badge + duração + popup menu
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    dateFmt.format(relatorio.turnoIniciadoEm),
                    style:
                        AppTextStyles.h4.copyWith(color: AppColors.primary),
                  ),
                  if (badge.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      horas > 0
                          ? '${horas}h ${minutos}min'
                          : '${minutos}min',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  PopupMenuButton<_CardAction>(
                    icon: Icon(Icons.more_vert,
                        size: 20, color: AppColors.textSecondary),
                    onSelected: (action) {
                      if (action == _CardAction.compartilhar) {
                        onCompartilhar();
                      } else {
                        onExcluir();
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _CardAction.compartilhar,
                        child: Row(
                          children: [
                            Icon(Icons.share_outlined,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            const Text('Compartilhar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _CardAction.excluir,
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: AppColors.danger),
                            const SizedBox(width: 10),
                            Text('Excluir',
                                style:
                                    TextStyle(color: AppColors.danger)),
                          ],
                        ),
                      ),
                    ],
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

              // Totais em grid 3 colunas
              _buildStatsGrid(relatorio),

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${relatorio.eventos.length} evento(s) · toque para detalhes',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 16, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(RelatorioDia r) {
    final stats = [
      (Icons.swap_horiz, 'Alocações', r.totalAlocacoes, AppColors.primary),
      (Icons.people, 'Colaboradores', r.totalColaboradores,
          AppColors.statusAtivo),
      (Icons.coffee, 'Cafés', r.totalCafes, AppColors.statusCafe),
      (Icons.restaurant, 'Intervalos', r.totalIntervalos,
          AppColors.statusAtencao),
      (Icons.inventory_2, 'Empacotadores', r.totalEmpacotadores, _kBrown),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = 3;
        final itemW = (constraints.maxWidth - (cols - 1) * 8) / cols;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stats
              .where((s) => s.$3 > 0 || s.$1 == Icons.swap_horiz)
              .map((s) => SizedBox(
                    width: itemW,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: s.$4.withValues(alpha: 0.07),
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSM),
                        border: Border.all(
                            color: s.$4.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(s.$1, size: 14, color: s.$4),
                          const SizedBox(height: 4),
                          Text(
                            '${s.$3}',
                            style: AppTextStyles.h3
                                .copyWith(color: s.$4),
                          ),
                          Text(
                            s.$2,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  void _verDetalhes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => _RelatorioDetalheScreen(
                relatorio: relatorio,
                onExcluir: onExcluir,
                onCompartilhar: onCompartilhar,
              )),
    );
  }
}

enum _CardAction { compartilhar, excluir }

// ─── Tela de detalhes de um relatório ─────────────────────────────────────

class _RelatorioDetalheScreen extends StatelessWidget {
  final RelatorioDia relatorio;
  final VoidCallback onExcluir;
  final VoidCallback onCompartilhar;

  const _RelatorioDetalheScreen({
    required this.relatorio,
    required this.onExcluir,
    required this.onCompartilhar,
  });

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:
            Text('Relatório — ${dateFmt.format(relatorio.turnoIniciadoEm)}'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          PopupMenuButton<_CardAction>(
            onSelected: (action) {
              if (action == _CardAction.compartilhar) {
                onCompartilhar();
              } else {
                Navigator.pop(context);
                onExcluir();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _CardAction.compartilhar,
                child: Row(
                  children: [
                    Icon(Icons.share_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    const Text('Compartilhar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _CardAction.excluir,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: AppColors.danger),
                    const SizedBox(width: 10),
                    Text('Excluir',
                        style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        children: [
          // ── Resumo ──────────────────────────────────────────────────────
          _SectionHeader(
              icon: Icons.summarize, label: 'Resumo do Turno'),
          const SizedBox(height: 8),
          Card(
            color: AppColors.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  // Grid de totais
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
                          color: _kBrown),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: Dimensions.spacingMD),

          // ── Eventos ─────────────────────────────────────────────────────
          if (relatorio.eventos.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.timeline,
              label: 'Eventos do Turno',
              pill: '${relatorio.eventos.length}',
            ),
            const SizedBox(height: 8),
            _buildTimeline(relatorio.eventos, timeFmt),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline(List<EventoTurno> eventos, DateFormat timeFmt) {
    return Column(
      children: eventos.asMap().entries.map((entry) {
        final isLast = entry.key == eventos.length - 1;
        final evento = entry.value;
        final (icon, color) = _iconeCor(evento.tipo);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha vertical + ícone
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(icon, size: 13, color: color),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppColors.cardBorder,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Conteúdo do evento
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: isLast ? 0 : Dimensions.spacingSM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              evento.tipo.label,
                              style: AppTextStyles.caption.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            timeFmt.format(evento.timestamp),
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      if (evento.colaboradorNome != null ||
                          evento.caixaNome != null ||
                          evento.detalhe != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            [
                              if (evento.colaboradorNome != null)
                                evento.colaboradorNome!,
                              if (evento.caixaNome != null)
                                '→ ${evento.caixaNome}',
                              if (evento.detalhe != null)
                                '(${evento.detalhe})',
                            ].join(' '),
                            style: AppTextStyles.caption,
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
      TipoEvento.colaboradorLiberado => (
          Icons.exit_to_app,
          AppColors.statusSaida
        ),
      TipoEvento.cafeIniciado => (Icons.coffee, AppColors.statusCafe),
      TipoEvento.cafeEncerrado =>
        (Icons.check_circle, AppColors.statusCafe),
      TipoEvento.intervaloIniciado => (
          Icons.restaurant,
          AppColors.statusAtencao
        ),
      TipoEvento.intervaloEncerrado => (
          Icons.check_circle,
          AppColors.statusAtencao
        ),
      TipoEvento.intervaloMarcadoFeito => (
          Icons.check_circle_outline,
          AppColors.success
        ),
      TipoEvento.intervaloAguardandoLiberacao => (
          Icons.pending_actions,
          AppColors.warning
        ),
      TipoEvento.empacotadorAdicionado => (Icons.inventory_2, _kBrown),
      TipoEvento.empacotadorRemovido => (Icons.remove_circle_outline, _kBrown),
      TipoEvento.checklistConcluido =>
        (Icons.checklist, AppColors.success),
      TipoEvento.entregaCadastrada =>
        (Icons.local_shipping, AppColors.primary),
      TipoEvento.entregaStatusAlterado =>
        (Icons.swap_horiz, AppColors.primary),
      TipoEvento.ocorrenciaRegistrada => (
          Icons.warning_amber,
          AppColors.danger
        ),
      TipoEvento.ocorrenciaResolvida =>
        (Icons.check_circle, AppColors.success),
      TipoEvento.anotacaoCriada => (
          Icons.note_add,
          const Color(0xFF7B1FA2)
        ),
      TipoEvento.formularioRespondido => (
          Icons.assignment_turned_in,
          AppColors.primary
        ),
    };
  }
}

// ─── Widgets auxiliares ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? pill;

  const _SectionHeader(
      {required this.icon, required this.label, this.pill});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(label,
            style: AppTextStyles.label
                .copyWith(color: AppColors.textPrimary)),
        if (pill != null) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              pill!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
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
