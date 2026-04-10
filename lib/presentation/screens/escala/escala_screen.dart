import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/datasources/remote/supabase_client.dart';
import '../../../domain/enums/departamento_tipo.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/escala_provider.dart';
import 'escala_dia_screen.dart';
import 'importar_escala_screen.dart';
import '../../../core/utils/app_notif.dart';

// Ã¢â€â‚¬Ã¢â€â‚¬ Helpers de tempo Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

int _toMin(String? hhmm) {
  if (hhmm == null) return -1;
  final p = hhmm.split(':');
  if (p.length != 2) return -1;
  return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
}

String _minToHHmm(int min) {
  final h = (min ~/ 60) % 24;
  final m = min % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Modelo de problema de cobertura Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _ProblemaCobertura {
  final DateTime dia;
  final String nomeDia;
  final String periodo;
  final int disponiveis;
  final int emIntervaloSimultaneo;
  final int totalAtivos;
  final bool critico;

  const _ProblemaCobertura({
    required this.dia,
    required this.nomeDia,
    required this.periodo,
    required this.disponiveis,
    required this.emIntervaloSimultaneo,
    required this.totalAtivos,
    required this.critico,
  });

  String get descricao {
    if (totalAtivos == 0) return 'Nenhum colaborador escalado';
    final pct = (emIntervaloSimultaneo / totalAtivos * 100).round();
    if (disponiveis == 0) {
      return 'Sem cobertura Ã¢â‚¬â€ todos em intervalo ou jÃƒÂ¡ saÃƒÂ­ram';
    }
    return '$emIntervaloSimultaneo de $totalAtivos em intervalo simultÃƒÂ¢neo ($pct%)';
  }
}

class EscalaScreen extends StatefulWidget {
  const EscalaScreen({super.key});

  @override
  State<EscalaScreen> createState() => _EscalaScreenState();
}

class _EscalaScreenState extends State<EscalaScreen> {
  DateTime _semanaBase = DateTime.now();
  DateTime? _dataImportadaPendente;

  // Ã¢â€â‚¬Ã¢â€â‚¬ Semana Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  DateTime get _segunda {
    final d = _semanaBase;
    return DateTime(d.year, d.month, d.day - (d.weekday - 1));
  }

  List<DateTime> get _diasDaSemana =>
      List.generate(7, (i) => _segunda.add(Duration(days: i)));

  bool _ehHoje(DateTime d) {
    final h = DateTime.now();
    return d.year == h.year && d.month == h.month && d.day == h.day;
  }

  bool _mesmaData(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _dataNaSemanaAtual(DateTime data) {
    return _diasDaSemana.any((dia) => _mesmaData(dia, data));
  }

  bool get _ehSemanaAtual {
    final h = DateTime.now();
    final seg = _segunda;
    final dom = seg.add(const Duration(days: 6));
    return !h.isBefore(seg) && !h.isAfter(dom);
  }

  void _semanaAnterior() => setState(
      () => _semanaBase = _semanaBase.subtract(const Duration(days: 7)));

  void _semanaSeguinte() =>
      setState(() => _semanaBase = _semanaBase.add(const Duration(days: 7)));

  void _semanaAtual() => setState(() => _semanaBase = DateTime.now());

  // Ã¢â€â‚¬Ã¢â€â‚¬ Colaboradores: garante carregamento Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final colaboradorProvider = context.read<ColaboradorProvider>();
    final authUserId = SupabaseClientManager.currentUserId ?? '';
    if (colaboradorProvider.todosColaboradores.isEmpty &&
        authUserId.isNotEmpty) {
      colaboradorProvider.loadColaboradores(authUserId);
    }
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ ValidaÃƒÂ§ÃƒÂ£o de cobertura Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  List<_ProblemaCobertura> _validarCobertura(EscalaProvider escala) {
    final problemas = <_ProblemaCobertura>[];
    final fmt = DateFormat('EEEE', 'pt_BR');

    for (final dia in _diasDaSemana) {
      final turnos = escala.getTurnosByData(dia);
      final ativos = turnos.where((t) => t.trabalhando).toList();
      if (ativos.isEmpty) continue;

      // Determina janela de slots a verificar
      int minSlot = 23 * 60, maxSlot = 0;
      for (final t in ativos) {
        final ent = _toMin(t.entrada);
        final sai = _toMin(t.saida);
        if (ent >= 0) minSlot = min(minSlot, (ent ~/ 30) * 30);
        if (sai >= 0) maxSlot = max(maxSlot, ((sai + 29) ~/ 30) * 30);
      }
      if (minSlot >= maxSlot) continue;

      // Analisa cada slot de 30min
      int? problemStart;
      int problemEndSlot = 0;
      int worstDisp = 999, worstInt = 0;

      void flush(int endSlot) {
        if (problemStart == null) return;
        final periodo =
            '${_minToHHmm(problemStart!)}Ã¢â‚¬â€œ${_minToHHmm(endSlot)}';
        final critico =
            worstDisp == 0 || worstInt >= (ativos.length * 0.6).ceil();
        problemas.add(_ProblemaCobertura(
          dia: dia,
          nomeDia: _capitalizar(fmt.format(dia)),
          periodo: periodo,
          disponiveis: worstDisp == 999 ? 0 : worstDisp,
          emIntervaloSimultaneo: worstInt,
          totalAtivos: ativos.length,
          critico: critico,
        ));
        problemStart = null;
        worstDisp = 999;
        worstInt = 0;
      }

      for (int slotMin = minSlot; slotMin < maxSlot; slotMin += 30) {
        int disp = 0, emInt = 0, activeNow = 0;
        for (final t in ativos) {
          final ent = _toMin(t.entrada);
          final sai = _toMin(t.saida);
          final int_ = _toMin(t.intervalo);
          final ret = _toMin(t.retorno);
          if (ent < 0 || sai < 0 || slotMin < ent || slotMin >= sai) continue;
          activeNow++;
          final onBreak =
              int_ >= 0 && ret >= 0 && slotMin >= int_ && slotMin < ret;
          if (onBreak) {
            emInt++;
          } else {
            disp++;
          }
        }
        if (activeNow == 0) continue;

        final isProblem = emInt / activeNow >= 0.5; // Ã¢â€°Â¥ 50% em intervalo
        if (isProblem) {
          problemStart ??= slotMin;
          problemEndSlot = slotMin + 30;
          worstDisp = min(worstDisp, disp);
          worstInt = max(worstInt, emInt);
        } else {
          flush(problemEndSlot);
        }
      }
      flush(problemEndSlot);
    }

    return problemas;
  }

  void _mostrarRelatorioCobertura(
      BuildContext context, List<_ProblemaCobertura> problemas) {
    final criticos = problemas.where((p) => p.critico).length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scroll) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    criticos > 0
                        ? Icons.warning_rounded
                        : Icons.warning_amber_rounded,
                    color: criticos > 0 ? AppColors.danger : AppColors.warning,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alertas de Cobertura',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500)),
                        Text(
                          '${problemas.length} perÃƒÂ­odo(s) com atenÃƒÂ§ÃƒÂ£o'
                          '${criticos > 0 ? " Ã‚Â· $criticos crÃƒÂ­tico(s)" : ""}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 16),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: problemas.length,
                itemBuilder: (ctx, i) {
                  final p = problemas[i];
                  final color =
                      p.critico ? AppColors.danger : AppColors.warning;
                  final bg = p.critico
                      ? AppColors.alertCritical
                      : AppColors.alertWarning;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius:
                          BorderRadius.circular(Dimensions.borderRadius),
                      border: Border.all(color: color.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          p.critico
                              ? Icons.warning_rounded
                              : Icons.warning_amber_rounded,
                          color: color,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p.nomeDia} Ã‚Â· ${p.periodo}',
                                style: AppTextStyles.subtitle.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(p.descricao, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EscalaDiaScreen(data: p.dia),
                              ),
                            );
                          },
                          child: Text('Ver dia'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Fechar'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ GeraÃƒÂ§ÃƒÂ£o automÃƒÂ¡tica Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  Future<void> _gerarEscala(BuildContext context) async {
    final colaboradorProvider = context.read<ColaboradorProvider>();
    final escalaProvider = context.read<EscalaProvider>();
    final colaboradores = colaboradorProvider.todosColaboradores;

    if (colaboradores.isEmpty) {
      AppNotif.show(
        context,
        titulo: 'Sem Colaboradores',
        mensagem:
            'Nenhum colaborador cadastrado. Cadastre colaboradores primeiro.',
        tipo: 'alerta',
        cor: AppColors.danger,
      );
      return;
    }

    final dataAlvo = _dataImportadaPendente;
    if (dataAlvo == null) {
      AppNotif.show(
        context,
        titulo: 'Importacao Necessaria',
        mensagem:
            'Use "Importar registros" e escolha a data antes de gerar a escala automatica.',
        tipo: 'alerta',
        cor: AppColors.statusAtencao,
      );
      return;
    }

    final dataFormatada = DateFormat('dd/MM/yyyy', 'pt_BR').format(dataAlvo);
    if (!_dataNaSemanaAtual(dataAlvo)) {
      AppNotif.show(
        context,
        titulo: 'Data Fora da Semana',
        mensagem:
            'A data importada ($dataFormatada) nao pertence a semana aberta. Abra a semana correta antes de gerar.',
        tipo: 'alerta',
        cor: AppColors.statusAtencao,
      );
      return;
    }

    final temEscalaExistente =
        escalaProvider.getTurnosByData(dataAlvo).isNotEmpty;
    bool substituir = false;

    if (temEscalaExistente) {
      final resposta = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Gerar Escala Automatica'),
          content: Text(
            'A data $dataFormatada ja possui turnos cadastrados.\n'
            'Deseja substituir os existentes ou apenas preencher os faltantes desse dia?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancelar'),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'preencher'),
              child: Text('So faltantes'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'substituir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('Substituir tudo'),
            ),
          ],
        ),
      );

      if (resposta == null || resposta == 'cancelar') return;
      substituir = resposta == 'substituir';
    } else {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Gerar Escala Automatica'),
          content: Text(
            'Gerar a escala automatica apenas para $dataFormatada '
            'com base nos registros importados?\n\n'
            '${colaboradores.where((c) => c.ativo).length} colaboradores ativos serao considerados.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('Gerar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    final resultado = await escalaProvider.gerarEscalaPorDia(
      colaboradores: colaboradores,
      data: dataAlvo,
      substituirExistentes: substituir,
    );

    if (!context.mounted) return;

    setState(() => _dataImportadaPendente = null);

    final criados = resultado['criados'] ?? 0;
    final semRegistro = resultado['semRegistro'] ?? 0;

    final problemas = criados > 0
        ? _validarCobertura(escalaProvider)
            .where((p) => _mesmaData(p.dia, dataAlvo))
            .toList()
        : <_ProblemaCobertura>[];
    final criticos = problemas.where((p) => p.critico).length;

    AppNotif.show(
      context,
      titulo: criados > 0 ? 'Escala Gerada' : 'Sem Registros',
      mensagem: criados > 0
          ? '$criados turno(s) gerado(s) para $dataFormatada.'
              '${semRegistro > 0 ? " $semRegistro colaborador(es) sem registro nessa data." : ""}'
              '${problemas.isNotEmpty ? " ${problemas.length} alerta(s) de cobertura." : ""}'
          : 'Nenhum registro de ponto encontrado para $dataFormatada.',
      tipo: criados > 0 ? 'saida' : 'alerta',
      cor: criticos > 0
          ? AppColors.danger
          : problemas.isNotEmpty
              ? AppColors.statusAtencao
              : AppColors.success,
      duracao: const Duration(seconds: 5),
      acao: problemas.isNotEmpty
          ? SnackBarAction(
              label: 'Ver Alertas (${problemas.length})',
              textColor: Colors.white,
              onPressed: () => _mostrarRelatorioCobertura(context, problemas),
            )
          : null,
    );
  }

  // UI

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EscalaProvider>(context);
    final diasSemana = _diasDaSemana;
    final mesAno = DateFormat('MMMM yyyy', 'pt_BR').format(_segunda);

    // Totais da semana
    int totalSemana = 0;
    int folgasSemana = 0;
    int diasComEscala = 0;
    for (final dia in diasSemana) {
      final turnos = provider.getTurnosByData(dia);
      if (turnos.isNotEmpty) diasComEscala++;
      totalSemana += turnos.where((t) => t.trabalhando).length;
      folgasSemana += turnos.where((t) => t.folga || t.feriado).length;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Escala Semanal'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (!_ehSemanaAtual)
            TextButton(
              onPressed: _semanaAtual,
              child: Text('Hoje'),
            ),
          IconButton(
            icon: Icon(Icons.upload_file_outlined),
            tooltip: 'Importar registros por texto',
            onPressed: () async {
              final dataImportada = await Navigator.of(context).push<DateTime>(
                MaterialPageRoute(
                  builder: (_) => const ImportarEscalaScreen(),
                ),
              );
              if (!mounted || dataImportada == null) return;
              setState(() {
                _dataImportadaPendente = DateTime(
                  dataImportada.year,
                  dataImportada.month,
                  dataImportada.day,
                );
              });
            },
          ),
          IconButton(
            icon: provider.gerando
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : Icon(Icons.auto_awesome),
            tooltip: 'Gerar escala automÃƒÂ¡tica',
            onPressed: provider.gerando ? null : () => _gerarEscala(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Ã¢â€â‚¬Ã¢â€â‚¬ NavegaÃƒÂ§ÃƒÂ£o de semana Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingMD, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: _semanaAnterior,
                ),
                Column(
                  children: [
                    Text(
                      _capitalizar(mesAno),
                      style: AppTextStyles.h4,
                    ),
                    Text(
                      '${DateFormat("dd/MM", "pt_BR").format(_segunda)}'
                      ' Ã¢â‚¬â€œ '
                      '${DateFormat("dd/MM", "pt_BR").format(_segunda.add(const Duration(days: 6)))}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: _semanaSeguinte,
                ),
              ],
            ),
          ),

          // Ã¢â€â‚¬Ã¢â€â‚¬ Resumo da semana Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
          if (diasComEscala > 0)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingMD, vertical: 4),
              child: Row(
                children: [
                  _StatChip(
                    icon: Icons.people,
                    label: '$totalSemana trabalhando',
                    color: AppColors.success,
                  ),
                  SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.beach_access,
                    label: '$folgasSemana folga(s)',
                    color: AppColors.inactive,
                  ),
                  SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.calendar_month,
                    label: '$diasComEscala/7 dias',
                    color: AppColors.primary,
                  ),
                ],
              ),
            )
          else if (!provider.gerando)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingMD, vertical: 8),
              child: InkWell(
                onTap: () => _gerarEscala(context),
                borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(Dimensions.borderRadius),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome,
                          color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Toque para gerar a escala automaticamente',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Ã¢â€â‚¬Ã¢â€â‚¬ Loading overlay Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
          if (provider.gerando)
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Gerando escala...'),
                ],
              ),
            ),

          // Ã¢â€â‚¬Ã¢â€â‚¬ Lista de dias Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(Dimensions.paddingMD),
              itemCount: 7,
              separatorBuilder: (_, __) =>
                  SizedBox(height: Dimensions.spacingSM),
              itemBuilder: (context, index) {
                final dia = diasSemana[index];
                final turnos = provider.getTurnosByData(dia);
                final trabalhando = turnos.where((t) => t.trabalhando).toList();
                final folgas = turnos.where((t) => t.folga || t.feriado).length;
                final hoje = _ehHoje(dia);
                final nomeDia = DateFormat('EEEE', 'pt_BR').format(dia);

                // Breakdown por departamento
                final nCaixa = trabalhando
                    .where((t) =>
                        t.departamento == DepartamentoTipo.caixa ||
                        t.departamento == DepartamentoTipo.self)
                    .length;
                final nFiscal = trabalhando
                    .where((t) => t.departamento == DepartamentoTipo.fiscal)
                    .length;
                final nPacote = trabalhando
                    .where((t) => t.departamento == DepartamentoTipo.pacote)
                    .length;
                final nOutros = trabalhando.length - nCaixa - nFiscal - nPacote;

                return Card(
                  color:
                      hoje ? AppColors.primary.withValues(alpha: 0.07) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.borderRadius),
                    side: hoje
                        ? BorderSide(color: AppColors.primary, width: 2)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: hoje
                            ? AppColors.primary
                            : AppColors.backgroundSection,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dia.day.toString(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  hoje ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            DateFormat('MMM', 'pt_BR')
                                .format(dia)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: hoje
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    title: Text(
                      _capitalizar(nomeDia),
                      style: AppTextStyles.h4.copyWith(
                        color: hoje ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: turnos.isEmpty
                        ? Text(
                            'Sem escala cadastrada',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${trabalhando.length} trabalhando'
                                '${folgas > 0 ? " Ã¢â‚¬Â¢ $folgas folga(s)" : ""}',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                              if (trabalhando.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    if (nCaixa > 0)
                                      _DeptBadge(
                                          label: 'Caixa $nCaixa',
                                          color: AppColors.primary),
                                    if (nFiscal > 0)
                                      _DeptBadge(
                                          label: 'Fiscal $nFiscal',
                                          color: AppColors.statusAtencao),
                                    if (nPacote > 0)
                                      _DeptBadge(
                                          label: 'Pacote $nPacote',
                                          color: AppColors.success),
                                    if (nOutros > 0)
                                      _DeptBadge(
                                          label: 'Outros $nOutros',
                                          color: AppColors.inactive),
                                  ],
                                ),
                              ],
                            ],
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (turnos.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${turnos.length}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right,
                            color: AppColors.textSecondary),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EscalaDiaScreen(data: dia),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Widgets auxiliares Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeptBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _DeptBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
