import 'dart:async';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../domain/enums/departamento_tipo.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/cafe_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/escala_provider.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

const int _kSlotMin = 30;
const int _kSlotsJanela = 8;
const int _kMinCobertura = 2;

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

// ── Slot model ───────────────────────────────────────────────────────────────

class _Slot {
  final int minuto;
  final int disponiveis;
  final List<TurnoLocal> saidas;
  final List<TurnoLocal> entradas;
  final List<TurnoLocal> intervalosPrevistos;

  const _Slot({
    required this.minuto,
    required this.disponiveis,
    required this.saidas,
    required this.entradas,
    required this.intervalosPrevistos,
  });

  String get horaStr => _minToHHmm(minuto);
  int get saiQtd => saidas.length;
  int get voltaQtd => entradas.length;

  factory _Slot.build(
    List<TurnoLocal> turnos,
    int slotMin, {
    required DateTime slotTime,
    Map<String, PausaCafe>? pausasAtivas,
    Set<String>? alocadosAtivos,
    bool ajustarComRealTime = false,
  }) {
    int disponiveis = 0;
    final counted = <String>{};
    final saidas = <TurnoLocal>[];
    final entradas = <TurnoLocal>[];
    final intervalosPrevistos = <TurnoLocal>[];

    bool emPausa(String colaboradorId) {
      final pausa = pausasAtivas?[colaboradorId];
      if (pausa == null) return false;
      final fim =
          pausa.iniciadoEm.add(Duration(minutes: pausa.duracaoMinutos));
      return !slotTime.isBefore(pausa.iniciadoEm) && slotTime.isBefore(fim);
    }

    for (final t in turnos) {
      if (!t.trabalhando) continue;
      int entMin = _toMin(t.entrada);
      int saiMin = _toMin(t.saida);
      int intMin = _toMin(t.intervalo);
      int retMin = _toMin(t.retorno);
      if (entMin < 0 || saiMin < 0) continue;

      int slotMinAdj = slotMin;
      if (saiMin <= entMin) {
        // Virada de dia: saída no dia seguinte
        saiMin += 1440;
        if (intMin >= 0 && intMin < entMin) intMin += 1440;
        if (retMin >= 0) {
          if (intMin >= 0 && retMin < intMin) retMin += 1440;
          if (intMin < 0 && retMin < entMin) retMin += 1440;
        }
        if (slotMinAdj < entMin) slotMinAdj += 1440;
      }

      // Disponível no início do slot?
      if (slotMinAdj >= entMin && slotMinAdj < saiMin) {
        // Horário de intervalo é referência. Só consideramos pausa real.
        if (!emPausa(t.colaboradorId)) {
          disponiveis++;
          counted.add(t.colaboradorId);
        }
      }

      // Eventos dentro do slot [slotMin, slotMin+30)
      if (saiMin >= slotMinAdj && saiMin < slotMinAdj + _kSlotMin) {
        saidas.add(t);
      }
      if (intMin >= 0 &&
          intMin >= slotMinAdj &&
          intMin < slotMinAdj + _kSlotMin) {
        intervalosPrevistos.add(t);
      }
      if (entMin >= slotMinAdj &&
          entMin < slotMinAdj + _kSlotMin) {
        entradas.add(t);
      }
    }

    if (ajustarComRealTime &&
        alocadosAtivos != null &&
        alocadosAtivos.isNotEmpty) {
      for (final id in alocadosAtivos) {
        if (counted.contains(id)) continue;
        if (emPausa(id)) continue;
        disponiveis++;
      }
    }

    return _Slot(
      minuto: slotMin,
      disponiveis: disponiveis,
      saidas: saidas,
      entradas: entradas,
      intervalosPrevistos: intervalosPrevistos,
    );
  }
}

class _SetorData {
  final DepartamentoTipo setor;
  final List<_Slot> slots;
  final List<({int idx, int drop, bool low})> gargalos;
  final int peak;
  final int slotAtual;

  const _SetorData({
    required this.setor,
    required this.slots,
    required this.gargalos,
    required this.peak,
    required this.slotAtual,
  });
}

List<_SetorData> _buildSetoresData({
  required List<TurnoLocal> turnos,
  required DateTime agora,
  required Map<String, DepartamentoTipo> deptByColab,
  required Set<String> alocadosAtivos,
  required Map<String, PausaCafe> pausasAtivas,
}) {
  final base = DateTime(agora.year, agora.month, agora.day);
  final slotAtual =
      ((agora.hour * 60 + agora.minute) ~/ _kSlotMin) * _kSlotMin;
  final turnosTrabalhando = turnos.where((t) => t.trabalhando).toList();
  final setores = DepartamentoTipo.values
      .where((d) => turnosTrabalhando.any((t) => t.departamento == d))
      .toList();

  final setoresData = <_SetorData>[];
  for (final setor in setores) {
    final turnosSetor =
        turnosTrabalhando.where((t) => t.departamento == setor).toList();

    final alocadosAtivosSetor = alocadosAtivos
        .where((id) => deptByColab[id] == setor)
        .toSet();
    final pausasAtivasSetor = {
      for (final entry in pausasAtivas.entries)
        if (deptByColab[entry.key] == setor) entry.key: entry.value
    };

    final slots = List.generate(
      _kSlotsJanela,
      (i) {
        final slotMin = slotAtual + i * _kSlotMin;
        final slotTime = base.add(Duration(minutes: slotMin));
        return _Slot.build(
          turnosSetor,
          slotMin,
          slotTime: slotTime,
          pausasAtivas: pausasAtivasSetor,
          alocadosAtivos: alocadosAtivosSetor,
          ajustarComRealTime: slotMin == slotAtual,
        );
      },
    );
    final peak =
        slots.fold(0, (a, s) => s.disponiveis > a ? s.disponiveis : a);

    final gargalosMap = <int, ({int idx, int drop, bool low})>{};
    for (int i = 1; i < slots.length; i++) {
      final drop = slots[i - 1].disponiveis - slots[i].disponiveis;
      if (drop >= 2) {
        gargalosMap[i] = (idx: i, drop: drop, low: false);
      }
      if (slots[i].disponiveis <= _kMinCobertura) {
        final atual = gargalosMap[i];
        if (atual != null) {
          gargalosMap[i] = (
            idx: i,
            drop: atual.drop,
            low: true,
          );
        } else {
          gargalosMap[i] = (idx: i, drop: 0, low: true);
        }
      }
    }
    final gargalos = gargalosMap.values.toList();
    setoresData.add(_SetorData(
      setor: setor,
      slots: slots,
      gargalos: gargalos,
      peak: peak,
      slotAtual: slotAtual,
    ));
  }

  return setoresData;
}

/// Retorna o número de gargalos (quedas ≥ 2 ou cobertura baixa) nas próximas 4h,
/// considerando setores separados e pausas reais.
/// Exposto publicamente para o badge no GestaoScreen.
int contarGargalosHoje({
  required EscalaProvider escala,
  required AlocacaoProvider alocacao,
  required CafeProvider cafe,
  required ColaboradorProvider colaborador,
}) {
  final turnos = escala.turnosHoje;
  final agora = DateTime.now();
  final deptByColab = {
    for (final c in colaborador.colaboradores) c.id: c.departamento
  };
  final alocadosAtivos =
      alocacao.getAlocacoesAtivas().map((a) => a.colaboradorId).toSet();
  final pausasAtivas = {
    for (final p in cafe.pausasAtivas) p.colaboradorId: p
  };

  final setoresData = _buildSetoresData(
    turnos: turnos,
    agora: agora,
    deptByColab: deptByColab,
    alocadosAtivos: alocadosAtivos,
    pausasAtivas: pausasAtivas,
  );

  int count = 0;
  for (final s in setoresData) {
    count += s.gargalos.length;
  }
  return count;
}

// ── Screen ───────────────────────────────────────────────────────────────────

class VisaoGargaloScreen extends StatefulWidget {
  const VisaoGargaloScreen({super.key});

  @override
  State<VisaoGargaloScreen> createState() => _VisaoGargaloScreenState();
}

class _VisaoGargaloScreenState extends State<VisaoGargaloScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EscalaProvider>(
      builder: (context, escala, _) {
        final alocacaoProvider =
            Provider.of<AlocacaoProvider>(context, listen: false);
        final cafeProvider =
            Provider.of<CafeProvider>(context, listen: false);
        final colaboradorProvider =
            Provider.of<ColaboradorProvider>(context, listen: false);
        final turnos = escala.turnosHoje;
        final agora = DateTime.now();
        final base = DateTime(agora.year, agora.month, agora.day);
        final deptByColab = {
          for (final c in colaboradorProvider.colaboradores)
            c.id: c.departamento
        };
        final alocadosAtivos = alocacaoProvider
            .getAlocacoesAtivas()
            .map((a) => a.colaboradorId)
            .toSet();
        final pausasAtivas = {
          for (final p in cafeProvider.pausasAtivas) p.colaboradorId: p
        };

        final setoresData = _buildSetoresData(
          turnos: turnos,
          agora: agora,
          deptByColab: deptByColab,
          alocadosAtivos: alocadosAtivos,
          pausasAtivas: pausasAtivas,
        );
        final temGargalos =
            setoresData.any((s) => s.gargalos.isNotEmpty);

        final temDados = setoresData.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Visão de Gargalo'),
            backgroundColor: AppColors.background,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  temGargalos
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: temGargalos
                      ? AppColors.warning
                      : AppColors.success,
                ),
              ),
            ],
          ),
          body: turnos.isEmpty || !temDados
              ? _buildEmpty()
              : _buildBody(setoresData),
        );
      },
    );
  }

  Widget _buildEmpty() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: AppColors.inactive),
            SizedBox(height: 16),
            Text(
              'Nenhuma escala cadastrada para hoje.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildBody(List<_SetorData> setoresData) {
    return ListView(
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      children: [
        ...setoresData.expand((s) => [
              _SectionHeader(
                label: 'Setor: ${s.setor.nome}',
                icon: Icons.apartment_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              _CoberturaChart(
                slots: s.slots,
                peak: s.peak,
                slotAtual: s.slotAtual,
              ),
              if (s.gargalos.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _SectionHeader(
                  label: 'Alertas de Gargalo',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 10),
                ...s.gargalos.map(
                  (g) => _GargaloCard(
                    slot: s.slots[g.idx],
                    drop: g.drop,
                    baixaCobertura: g.low,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const _SectionHeader(
                label: 'Próximas Movimentações',
                icon: Icons.schedule,
                color: AppColors.primary,
              ),
              const SizedBox(height: 10),
              _ProximasMovimentacoes(slots: s.slots),
              const SizedBox(height: 32),
            ]),
      ],
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.subtitle.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── Cobertura Chart ──────────────────────────────────────────────────────────

class _CoberturaChart extends StatelessWidget {
  final List<_Slot> slots;
  final int peak;
  final int slotAtual;

  const _CoberturaChart({
    required this.slots,
    required this.peak,
    required this.slotAtual,
  });

  Color _barColor(int disp) {
    if (peak == 0) return AppColors.inactive;
    final r = disp / peak;
    if (r >= 0.75) return AppColors.success;
    if (r >= 0.50) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    const maxH = 80.0;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Cobertura nas próximas 4h',
                  style: AppTextStyles.subtitle
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Colaboradores disponíveis por slot de 30min',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: slots.map((slot) {
                  final isAtual = slot.minuto == slotAtual;
                  final barH = peak > 0
                      ? (slot.disponiveis / peak * maxH).clamp(4.0, maxH)
                      : 4.0;
                  final color = _barColor(slot.disponiveis);

                  return SizedBox(
                    width: 52,
                    child: Column(
                      children: [
                        Text(
                          '${slot.disponiveis}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              width: 40,
                              height: maxH,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundSection,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                              width: 40,
                              height: barH,
                              decoration: BoxDecoration(
                                color: color.withValues(
                                    alpha: isAtual ? 1.0 : 0.75),
                                borderRadius: BorderRadius.circular(6),
                                border: isAtual
                                    ? Border.all(
                                        color: AppColors.primary, width: 2)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          slot.horaStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: isAtual
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isAtual
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (isAtual)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 7),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                _Legend(color: AppColors.success, label: 'Normal'),
                SizedBox(width: 16),
                _Legend(color: AppColors.warning, label: 'Atenção'),
                SizedBox(width: 16),
                _Legend(color: AppColors.danger, label: 'Crítico'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

// ── Gargalo Card ─────────────────────────────────────────────────────────────

class _GargaloCard extends StatelessWidget {
  final _Slot slot;
  final int drop;
  final bool baixaCobertura;

  const _GargaloCard({
    required this.slot,
    required this.drop,
    required this.baixaCobertura,
  });

  String _sugestao() {
    if (baixaCobertura) {
      return 'Cobertura muito baixa. Planeje reforço ou redistribua a equipe.';
    }
    if (slot.intervalosPrevistos.isNotEmpty) {
      final nomes = slot.intervalosPrevistos
          .map((t) => t.colaboradorNome.split(' ').first)
          .join(', ');
      final antes = _minToHHmm(slot.minuto - 30);
      return 'Há intervalos previstos para $nomes. Avalie liberar antes das $antes para diluir a queda.';
    }
    if (slot.saidas.isNotEmpty) {
      return 'Prepare uma substituição antes das ${slot.horaStr} para cobrir as saídas.';
    }
    return 'Monitore a cobertura e redistribua colaboradores se necessário.';
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = drop >= 4 || slot.disponiveis <= 1;
    final color = isCritical ? AppColors.danger : AppColors.warning;
    final bgColor =
        isCritical ? AppColors.alertCritical : AppColors.alertWarning;

    final saindoNomes =
        slot.saidas.map((t) => t.colaboradorNome.split(' ').first).toList();
    final voltandoNomes =
        slot.entradas.map((t) => t.colaboradorNome.split(' ').first).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCritical
                    ? Icons.warning_rounded
                    : Icons.warning_amber_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                baixaCobertura
                    ? '${slot.horaStr} — cobertura baixa'
                    : '${slot.horaStr} — queda de $drop',
                style: AppTextStyles.subtitle.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${slot.disponiveis} disponíveis',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (saindoNomes.isNotEmpty)
            _EventRow(
              icon: Icons.arrow_circle_up,
              color: AppColors.danger,
              label: 'Saem',
              nomes: saindoNomes,
            ),
          if (voltandoNomes.isNotEmpty) ...[
            const SizedBox(height: 4),
            _EventRow(
              icon: Icons.arrow_circle_down,
              color: AppColors.success,
              label: 'Chegam',
              nomes: voltandoNomes,
            ),
          ],
          const Divider(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _sugestao(),
                  style: AppTextStyles.caption
                      .copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final List<String> nomes;

  const _EventRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.nomes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(nomes.join(', '), style: AppTextStyles.caption),
        ),
      ],
    );
  }
}

// ── Próximas Movimentações ───────────────────────────────────────────────────

enum _TipoEvento { saida, entrada }

class _Evento {
  final int horaMin;
  final String nome;
  final _TipoEvento tipo;

  const _Evento(
      {required this.horaMin, required this.nome, required this.tipo});
}

class _ProximasMovimentacoes extends StatelessWidget {
  final List<_Slot> slots;

  const _ProximasMovimentacoes({required this.slots});

  @override
  Widget build(BuildContext context) {
    final eventos = <_Evento>[];

    for (final slot in slots) {
      for (final t in slot.saidas) {
        final m = _toMin(t.saida);
        if (m >= 0) {
          eventos.add(_Evento(
              horaMin: m,
              nome: t.colaboradorNome.split(' ').first,
              tipo: _TipoEvento.saida));
        }
      }
      for (final t in slot.entradas) {
        final m = _toMin(t.entrada);
        if (m >= 0) {
          eventos.add(_Evento(
              horaMin: m,
              nome: t.colaboradorNome.split(' ').first,
              tipo: _TipoEvento.entrada));
        }
      }
    }

    eventos.sort((a, b) => a.horaMin.compareTo(b.horaMin));

    if (eventos.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.borderRadius),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        child: const Padding(
          padding: EdgeInsets.all(Dimensions.paddingMD),
          child: Text(
            'Nenhuma movimentação prevista nas próximas 4h.',
            style: AppTextStyles.caption,
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: eventos.map((e) => _EventoItem(evento: e)).toList(),
        ),
      ),
    );
  }
}

class _EventoItem extends StatelessWidget {
  final _Evento evento;

  const _EventoItem({required this.evento});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (evento.tipo) {
      _TipoEvento.saida => (Icons.exit_to_app, AppColors.danger, 'Saída'),
      _TipoEvento.entrada => (Icons.login, AppColors.primary, 'Entrada'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              _minToHHmm(evento.horaMin),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            width: 1.5,
            height: 24,
            color: AppColors.cardBorder,
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${evento.nome} · $label',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}
