import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/caixa_provider.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  String? _filtroColaboradorId;
  String _filtroTipo = 'todos'; // todos | alocado | liberado

  static const _tipoOptions = [
    ('todos', 'Todos'),
    ('alocado', 'Alocações'),
    ('liberado', 'Liberações'),
  ];

  @override
  Widget build(BuildContext context) {
    final alocacaoProvider = Provider.of<AlocacaoProvider>(context);
    final colaboradorProvider = Provider.of<ColaboradorProvider>(context);
    final caixaProvider = Provider.of<CaixaProvider>(context);

    final todasAlocacoes = alocacaoProvider.alocacoes;

    // Filtrar por colaborador
    var eventosFiltrados = _filtroColaboradorId == null
        ? todasAlocacoes
        : todasAlocacoes
            .where((a) => a.colaboradorId == _filtroColaboradorId)
            .toList();

    // Filtrar por tipo
    if (_filtroTipo == 'alocado') {
      eventosFiltrados =
          eventosFiltrados.where((a) => a.liberadoEm == null).toList();
    } else if (_filtroTipo == 'liberado') {
      eventosFiltrados =
          eventosFiltrados.where((a) => a.liberadoEm != null).toList();
    }

    // Colaboradores que aparecem na timeline (para filtro)
    final colaboradoresNaTimeline = colaboradorProvider.colaboradores
        .where(
          (c) => todasAlocacoes.any((a) => a.colaboradorId == c.id),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Timeline de Hoje'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (todasAlocacoes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Exportar Timeline',
              onPressed: () => _exportarTimeline(
                context,
                todasAlocacoes,
                colaboradorProvider,
                caixaProvider,
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Filtros ----
          if (todasAlocacoes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Dimensions.paddingMD, Dimensions.paddingMD, Dimensions.paddingMD, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtro por tipo
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _tipoOptions.map((opt) {
                        final sel = _filtroTipo == opt.$1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(opt.$2),
                            selected: sel,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: sel ? Colors.white : AppColors.textPrimary,
                              fontWeight:
                                  sel ? FontWeight.bold : FontWeight.normal,
                            ),
                            checkmarkColor: Colors.white,
                            onSelected: (_) =>
                                setState(() => _filtroTipo = opt.$1),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Filtro por colaborador
                  if (colaboradoresNaTimeline.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: const Text('Todos'),
                              selected: _filtroColaboradorId == null,
                              selectedColor: AppColors.statusIntervalo,
                              labelStyle: TextStyle(
                                color: _filtroColaboradorId == null
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: _filtroColaboradorId == null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              checkmarkColor: Colors.white,
                              onSelected: (_) =>
                                  setState(() => _filtroColaboradorId = null),
                            ),
                          ),
                          ...colaboradoresNaTimeline.map((c) {
                            final sel = _filtroColaboradorId == c.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(c.nome.split(' ').first),
                                selected: sel,
                                selectedColor: AppColors.statusIntervalo,
                                labelStyle: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: sel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                checkmarkColor: Colors.white,
                                onSelected: (_) =>
                                    setState(() => _filtroColaboradorId = c.id),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: Dimensions.spacingSM),
                  Text(
                    '${eventosFiltrados.length} evento(s)',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

          // ---- Lista de eventos ----
          Expanded(
            child: eventosFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.timeline,
                          size: 64,
                          color: AppColors.inactive,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          todasAlocacoes.isEmpty
                              ? 'Nenhum evento hoje'
                              : 'Nenhum evento com os filtros selecionados',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(Dimensions.paddingMD),
                    itemCount: eventosFiltrados.length,
                    itemBuilder: (context, index) {
                      final alocacao = eventosFiltrados[index];
                      final colaborador = colaboradorProvider.colaboradores
                          .where((c) => c.id == alocacao.colaboradorId)
                          .firstOrNull;
                      final caixa = caixaProvider.caixas
                          .where((c) => c.id == alocacao.caixaId)
                          .firstOrNull;

                      final timeFormat = DateFormat('HH:mm');
                      final liberado = alocacao.liberadoEm != null;

                      return Card(
                        margin: const EdgeInsets.only(
                            bottom: Dimensions.spacingSM),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: liberado
                                ? AppColors.inactive
                                : AppColors.statusAtivo,
                            child: Icon(
                              liberado ? Icons.logout : Icons.swap_horiz,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            '${colaborador?.nome ?? "Colaborador"} → ${caixa?.nomeExibicao ?? "Caixa"}',
                            style: AppTextStyles.h4,
                          ),
                          subtitle: Text(
                            liberado
                                ? 'Alocado: ${timeFormat.format(alocacao.alocadoEm)} • Liberado: ${timeFormat.format(alocacao.liberadoEm!)}'
                                : 'Alocado às ${timeFormat.format(alocacao.alocadoEm)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (liberado
                                      ? AppColors.inactive
                                      : AppColors.success)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              liberado ? 'Liberado' : 'Alocado',
                              style: AppTextStyles.caption.copyWith(
                                color: liberado
                                    ? AppColors.inactive
                                    : AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _exportarTimeline(
    BuildContext context,
    List alocacoes,
    ColaboradorProvider colaboradorProvider,
    CaixaProvider caixaProvider,
  ) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final hoje = dateFormat.format(DateTime.now());

    final buffer = StringBuffer();
    buffer.writeln('TIMELINE DE HOJE - $hoje');
    buffer.writeln('=' * 40);
    buffer.writeln('Total de eventos: ${alocacoes.length}');
    buffer.writeln();

    for (final alocacao in alocacoes) {
      final colaborador = colaboradorProvider.colaboradores
          .where((c) => c.id == alocacao.colaboradorId)
          .firstOrNull;
      final caixa = caixaProvider.caixas
          .where((c) => c.id == alocacao.caixaId)
          .firstOrNull;

      final nomeColaborador = colaborador?.nome ?? 'Colaborador';
      final nomeCaixa = caixa?.nomeExibicao ?? 'Caixa';
      final horario = timeFormat.format(alocacao.alocadoEm);
      final status = alocacao.liberadoEm != null
          ? '[Liberado ${timeFormat.format(alocacao.liberadoEm!)}]'
          : '[Ativo]';

      buffer.writeln('$horario | $nomeColaborador → $nomeCaixa $status');
    }

    final texto = buffer.toString();

    // Copia para clipboard
    Clipboard.setData(ClipboardData(text: texto));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Timeline copiada para a área de transferência!'),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () => _mostrarDialogoExport(context, texto),
        ),
      ),
    );
  }

  void _mostrarDialogoExport(BuildContext context, String texto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Timeline Exportada'),
        content: SingleChildScrollView(
          child: Text(
            texto,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
