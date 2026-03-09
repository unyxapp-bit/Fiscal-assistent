import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../domain/entities/evento_turno.dart';
import '../../providers/auth_provider.dart';
import '../../providers/evento_turno_provider.dart';
import '../relatorios/relatorios_dia_screen.dart';
import '../../../core/utils/app_notif.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EventoTurnoProvider>(
      builder: (context, eventoProvider, _) {
        final authProvider =
            Provider.of<AuthProvider>(context, listen: false);
        final fiscalId = authProvider.user?.id ?? '';
        final eventos = eventoProvider.eventos;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Timeline de Hoje'),
            backgroundColor: AppColors.background,
            elevation: 0,
            actions: [
              if (eventoProvider.relatorios.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'Relatórios do Dia',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RelatoriosDiaScreen()),
                  ),
                ),
              if (eventos.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Exportar Timeline',
                  onPressed: () => _exportarTimeline(context, eventos),
                ),
            ],
          ),
          body: eventos.isEmpty
              ? _buildVazia(eventoProvider.turnoAtivo)
              : _buildLista(eventos),
          floatingActionButton: eventoProvider.turnoAtivo
              ? FloatingActionButton.extended(
                  onPressed: () =>
                      _confirmarFinalTurno(context, eventoProvider, fiscalId),
                  icon: const Icon(Icons.flag),
                  label: const Text('Final de Turno'),
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                )
              : null,
        );
      },
    );
  }

  Widget _buildVazia(bool turnoAtivo) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            turnoAtivo ? Icons.timeline : Icons.play_circle_outline,
            size: 64,
            color: AppColors.inactive,
          ),
          const SizedBox(height: 16),
          Text(
            turnoAtivo
                ? 'Nenhum evento registrado ainda'
                : 'Inicie o turno no Briefing para registrar eventos',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLista(List<EventoTurno> eventos) {
    final fmt = DateFormat('HH:mm');
    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      itemCount: eventos.length,
      itemBuilder: (context, index) {
        // Invertemos a lista para mostrar os mais recentes no topo
        final evento = eventos[eventos.length - 1 - index];
        return _EventoCard(evento: evento, fmt: fmt);
      },
    );
  }

  Future<void> _confirmarFinalTurno(
    BuildContext context,
    EventoTurnoProvider eventoProvider,
    String fiscalId,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Encerrar Turno'),
        content: const Text(
            'Deseja encerrar o turno agora?\nUm relatório será gerado e salvo automaticamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    final relatorio = await eventoProvider.encerrarTurno(fiscalId);

    if (!context.mounted) return;

    if (relatorio != null) {
      AppNotif.show(
        context,
        titulo: 'Turno Encerrado',
        mensagem: 'Turno encerrado! Relatório salvo.',
        tipo: 'saida',
        cor: AppColors.success,
        acao: SnackBarAction(
          label: 'Ver Relatório',
          textColor: Colors.white,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RelatoriosDiaScreen()),
          ),
        ),
      );
    }
  }

  void _exportarTimeline(BuildContext context, List<EventoTurno> eventos) {
    final fmt = DateFormat('HH:mm');
    final dateFmt = DateFormat('dd/MM/yyyy');
    final hoje = dateFmt.format(DateTime.now());

    final buffer = StringBuffer();
    buffer.writeln('TIMELINE DE HOJE — $hoje');
    buffer.writeln('=' * 40);
    buffer.writeln('Total de eventos: ${eventos.length}');
    buffer.writeln();

    for (final e in eventos) {
      final hora = fmt.format(e.timestamp);
      final partes = [hora, e.tipo.label];
      if (e.colaboradorNome != null) partes.add(e.colaboradorNome!);
      if (e.caixaNome != null) partes.add(e.caixaNome!);
      if (e.detalhe != null) partes.add('(${e.detalhe})');
      buffer.writeln(partes.join(' | '));
    }

    final texto = buffer.toString();
    Clipboard.setData(ClipboardData(text: texto));

    AppNotif.show(
      context,
      titulo: 'Copiado',
      mensagem: 'Timeline copiada para a área de transferência!',
      tipo: 'saida',
      cor: AppColors.success,
      acao: SnackBarAction(
        label: 'Ver',
        textColor: Colors.white,
        onPressed: () => showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Timeline Exportada'),
            content: SingleChildScrollView(
              child: Text(texto,
                  style:
                      const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fechar')),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Card de evento na timeline ─────────────────────────────────────────────

class _EventoCard extends StatelessWidget {
  final EventoTurno evento;
  final DateFormat fmt;

  const _EventoCard({required this.evento, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconeCor(evento.tipo);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicador de linha
        Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, size: 16, color: color),
            ),
            Container(
              width: 2,
              height: 40,
              color: AppColors.cardBorder,
            ),
          ],
        ),
        const SizedBox(width: 12),

        // Conteúdo
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(evento.tipo.label,
                          style: AppTextStyles.subtitle.copyWith(color: color)),
                    ),
                    Text(
                      fmt.format(evento.timestamp),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (evento.colaboradorNome != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          evento.colaboradorNome! +
                              (evento.caixaNome != null
                                  ? ' → ${evento.caixaNome}'
                                  : ''),
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ],
                if (evento.detalhe != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    evento.detalhe!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  (IconData, Color) _iconeCor(TipoEvento tipo) {
    return switch (tipo) {
      TipoEvento.turnoIniciado => (Icons.play_circle, AppColors.statusAtivo),
      TipoEvento.colaboradorAlocado =>
        (Icons.swap_horiz, AppColors.primary),
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
      TipoEvento.checklistConcluido =>
        (Icons.checklist, AppColors.success),
      TipoEvento.entregaCadastrada =>
        (Icons.local_shipping, AppColors.primary),
      TipoEvento.entregaStatusAlterado =>
        (Icons.swap_horiz, AppColors.primary),
      TipoEvento.ocorrenciaRegistrada =>
        (Icons.warning_amber, AppColors.danger),
      TipoEvento.ocorrenciaResolvida =>
        (Icons.check_circle, AppColors.success),
      TipoEvento.anotacaoCriada =>
        (Icons.note_add, const Color(0xFF7B1FA2)),
      TipoEvento.formularioRespondido =>
        (Icons.assignment_turned_in, AppColors.primary),
    };
  }
}
