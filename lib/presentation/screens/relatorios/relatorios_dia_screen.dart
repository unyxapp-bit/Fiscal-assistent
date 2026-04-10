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
            title: Text('RelatÃƒÂ³rio do Dia'),
            backgroundColor: AppColors.background,
            elevation: 0,
          ),
          body: relatorios.isEmpty
              ? _buildVazio()
              : ListView.builder(
                  padding: const EdgeInsets.all(Dimensions.paddingMD),
                  itemCount: relatorios.length,
                  itemBuilder: (_, i) => _RelatorioCard(
                    relatorio: relatorios[i],
                    onExcluir: () =>
                        _confirmarExclusao(context, provider, relatorios[i]),
                    onCompartilhar: () => _compartilhar(relatorios[i]),
                  ),
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
          Icon(Icons.summarize_outlined, size: 64, color: AppColors.inactive),
          SizedBox(height: 16),
          Text(
            'Nenhum relatÃƒÂ³rio gerado ainda.\nEncerre o turno na Timeline para gerar um.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _confirmarExclusao(BuildContext context, EventoTurnoProvider provider,
      RelatorioDia relatorio) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir RelatÃƒÂ³rio'),
        content: Text(
            'Excluir o relatÃƒÂ³rio de ${dateFmt.format(relatorio.turnoIniciadoEm)}? Esta aÃƒÂ§ÃƒÂ£o nÃƒÂ£o pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.removerRelatorio(relatorio.id);
            },
            child: Text('Excluir', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _compartilhar(RelatorioDia relatorio) {
    Share.share(_gerarTexto(relatorio),
        subject:
            'RelatÃƒÂ³rio do turno Ã¢â‚¬â€ ${DateFormat('dd/MM/yyyy').format(relatorio.turnoIniciadoEm)}');
  }

  static String _gerarTexto(RelatorioDia r) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm');
    final dur = r.duracaoTurno;
    final durStr = dur.inHours > 0
        ? '${dur.inHours}h ${dur.inMinutes.remainder(60).toString().padLeft(2, '0')}min'
        : '${dur.inMinutes}min';

    final buf = StringBuffer();
    buf.writeln(
        'Ã°Å¸â€œÅ  RelatÃƒÂ³rio do Turno Ã¢â‚¬â€ ${dateFmt.format(r.turnoIniciadoEm)}');
    buf.writeln(
        'Ã¢ÂÂ° ${timeFmt.format(r.turnoIniciadoEm)} Ã¢â€ â€™ ${timeFmt.format(r.turnoEncerradoEm)} ($durStr)');
    buf.writeln();
    buf.writeln('Ã°Å¸â€œâ€¹ Resumo:');
    buf.writeln('Ã¢â‚¬Â¢ ${r.totalAlocacoes} alocaÃƒÂ§ÃƒÂµes');
    buf.writeln('Ã¢â‚¬Â¢ ${r.totalColaboradores} colaboradores');
    buf.writeln('Ã¢â‚¬Â¢ ${r.totalCafes} cafÃƒÂ©s');
    buf.writeln('Ã¢â‚¬Â¢ ${r.totalIntervalos} intervalos');
    if (r.totalEmpacotadores > 0) {
      buf.writeln('Ã¢â‚¬Â¢ ${r.totalEmpacotadores} empacotadores');
    }

    if (r.eventos.isNotEmpty) {
      buf.writeln();
      buf.writeln('Ã°Å¸â€œâ€¦ Eventos:');
      for (final e in r.eventos) {
        final hora = timeFmt.format(e.timestamp);
        final partes = [
          hora,
          e.tipo.label,
          if (e.colaboradorNome != null) e.colaboradorNome!,
          if (e.caixaNome != null) 'Ã¢â€ â€™ ${e.caixaNome}',
          if (e.detalhe != null) '(${e.detalhe})',
        ];
        buf.writeln(partes.join(' '));
      }
    }

    return buf.toString().trim();
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Card de relatÃƒÂ³rio Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _RelatorioCard extends StatelessWidget {
  final RelatorioDia relatorio;
  final VoidCallback onExcluir;
  final VoidCallback onCompartilhar;

  const _RelatorioCard({
    required this.relatorio,
    required this.onExcluir,
    required this.onCompartilhar,
  });

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
              // CabeÃƒÂ§alho: data + duraÃƒÂ§ÃƒÂ£o + aÃƒÂ§ÃƒÂµes
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    dateFmt.format(relatorio.turnoIniciadoEm),
                    style: AppTextStyles.h4.copyWith(color: AppColors.primary),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.share_outlined, size: 18),
                    tooltip: 'Compartilhar',
                    onPressed: onCompartilhar,
                    color: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Excluir',
                    onPressed: onExcluir,
                    color: AppColors.danger,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),

              SizedBox(height: 4),
              Text(
                '${timeFmt.format(relatorio.turnoIniciadoEm)} Ã¢â€ â€™ ${timeFmt.format(relatorio.turnoEncerradoEm)}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),

              Divider(height: 16),

              // Totais em grade
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _Stat(
                      icon: Icons.swap_horiz,
                      label: 'AlocaÃƒÂ§ÃƒÂµes',
                      value: relatorio.totalAlocacoes,
                      color: AppColors.primary),
                  _Stat(
                      icon: Icons.people,
                      label: 'Colaboradores',
                      value: relatorio.totalColaboradores,
                      color: AppColors.statusAtivo),
                  _Stat(
                      icon: Icons.coffee,
                      label: 'CafÃƒÂ©s',
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

              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${relatorio.eventos.length} evento(s) registrado(s)',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  SizedBox(width: 4),
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
        SizedBox(width: 4),
        Text(
          '$value $label',
          style: AppTextStyles.caption.copyWith(color: color),
        ),
      ],
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Tela de detalhes de um relatÃƒÂ³rio Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

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
        title: Text(
            'RelatÃƒÂ³rio Ã¢â‚¬â€ ${dateFmt.format(relatorio.turnoIniciadoEm)}'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined),
            tooltip: 'Compartilhar',
            onPressed: onCompartilhar,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline),
            tooltip: 'Excluir',
            color: AppColors.danger,
            onPressed: () {
              Navigator.pop(context);
              onExcluir();
            },
          ),
        ],
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
                  Text('RESUMO DO TURNO', style: AppTextStyles.label),
                  SizedBox(height: 12),
                  _InfoLinha(
                    icon: Icons.play_circle,
                    label: 'InÃƒÂ­cio',
                    value: timeFmt.format(relatorio.turnoIniciadoEm),
                    color: AppColors.statusAtivo,
                  ),
                  SizedBox(height: 6),
                  _InfoLinha(
                    icon: Icons.flag,
                    label: 'Encerramento',
                    value: timeFmt.format(relatorio.turnoEncerradoEm),
                    color: AppColors.danger,
                  ),
                  SizedBox(height: 6),
                  _InfoLinha(
                    icon: Icons.timer,
                    label: 'DuraÃƒÂ§ÃƒÂ£o',
                    value: _fmtDuracao(relatorio.duracaoTurno),
                    color: AppColors.primary,
                  ),
                  Divider(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _Stat(
                          icon: Icons.swap_horiz,
                          label: 'AlocaÃƒÂ§ÃƒÂµes',
                          value: relatorio.totalAlocacoes,
                          color: AppColors.primary),
                      _Stat(
                          icon: Icons.people,
                          label: 'Colaboradores',
                          value: relatorio.totalColaboradores,
                          color: AppColors.statusAtivo),
                      _Stat(
                          icon: Icons.coffee,
                          label: 'CafÃƒÂ©s',
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

          SizedBox(height: Dimensions.spacingMD),

          // Lista de eventos
          if (relatorio.eventos.isNotEmpty) ...[
            Text('EVENTOS DO TURNO', style: AppTextStyles.label),
            SizedBox(height: 8),
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
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(evento.tipo.label,
                              style: AppTextStyles.caption.copyWith(
                                  color: color, fontWeight: FontWeight.w600)),
                          if (evento.colaboradorNome != null)
                            Text(
                              evento.colaboradorNome! +
                                  (evento.caixaNome != null
                                      ? ' Ã¢â€ â€™ ${evento.caixaNome}'
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
      TipoEvento.colaboradorLiberado => (
          Icons.exit_to_app,
          AppColors.statusSaida
        ),
      TipoEvento.cafeIniciado => (Icons.coffee, AppColors.statusCafe),
      TipoEvento.cafeEncerrado => (Icons.check_circle, AppColors.statusCafe),
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
          Colors.green
        ),
      TipoEvento.intervaloAguardandoLiberacao => (
          Icons.pending_actions,
          AppColors.warning
        ),
      TipoEvento.empacotadorAdicionado => (
          Icons.inventory_2,
          const Color(0xFF795548)
        ),
      TipoEvento.empacotadorRemovido => (
          Icons.remove_circle_outline,
          const Color(0xFF795548)
        ),
      TipoEvento.checklistConcluido => (Icons.checklist, AppColors.success),
      TipoEvento.entregaCadastrada => (Icons.local_shipping, AppColors.primary),
      TipoEvento.entregaStatusAlterado => (Icons.swap_horiz, AppColors.primary),
      TipoEvento.ocorrenciaRegistrada => (
          Icons.warning_amber,
          AppColors.danger
        ),
      TipoEvento.ocorrenciaResolvida => (Icons.check_circle, AppColors.success),
      TipoEvento.anotacaoCriada => (Icons.note_add, const Color(0xFF7B1FA2)),
      TipoEvento.formularioRespondido => (
          Icons.assignment_turned_in,
          AppColors.primary
        ),
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
        SizedBox(width: 6),
        Text('$label: ',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        Text(value,
            style: AppTextStyles.caption
                .copyWith(fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
