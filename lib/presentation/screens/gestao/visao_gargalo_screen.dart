import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../domain/enums/departamento_tipo.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/cafe_provider.dart';
import '../../providers/escala_provider.dart';
import 'gargalo_calculator.dart';

const int _kSlotMin = 30;
const int _kSlotsJanela = 8;

DateTime _floorToSlot(DateTime dt) {
  final base = DateTime(dt.year, dt.month, dt.day);
  final totalMin = dt.hour * 60 + dt.minute;
  final slotMin = (totalMin ~/ _kSlotMin) * _kSlotMin;
  return base.add(Duration(minutes: slotMin));
}

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class _SetorData {
  final DepartamentoTipo setor;
  final List<SlotDisponibilidade> slots;
  final int peak;

  const _SetorData({
    required this.setor,
    required this.slots,
    required this.peak,
  });
}

/// Retorna o número de gargalos (queda >= 2 ou abaixo do mínimo) nas próximas 4h,
/// considerando setores separados e pausas reais.
/// Exposto publicamente para o badge no GestaoScreen.
int contarGargalosHoje({
  required EscalaProvider escala,
  required AlocacaoProvider alocacao,
  required CafeProvider cafe,
}) {
  final turnos = escala.turnosHoje;
  if (turnos.isEmpty) return 0;

  final alocacaoByColab = {
    for (final a in alocacao.getAlocacoesAtivas()) a.colaboradorId: a
  };
  final pausaByColab = {
    for (final p in cafe.pausasAtivas) p.colaboradorId: p
  };

  final status = turnos
      .map(
        (t) => StatusColaboradorCompleto(
          turno: t,
          alocacao: alocacaoByColab[t.colaboradorId],
          pausaAtiva: pausaByColab[t.colaboradorId],
        ),
      )
      .toList();

  final agora = DateTime.now();
  final inicio = _floorToSlot(agora);
  final fim =
      inicio.add(const Duration(minutes: _kSlotMin * _kSlotsJanela));
  final calculator = GargaloCalculator(status, inicio: inicio, fim: fim);

  final setores = DepartamentoTipo.values
      .where(
        (d) => status.any(
          (s) => s.turno.trabalhando && s.turno.departamento == d,
        ),
      )
      .toList();

  int count = 0;
  for (final setor in setores) {
    final slots = calculator.calcularPorSetor(setor);
    count += slots.where((s) => s.gargalo).length;
  }

  return count;
}

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
    final escala = context.watch<EscalaProvider>();
    final alocacaoProvider = context.watch<AlocacaoProvider>();
    final cafeProvider = context.watch<CafeProvider>();

    final turnos = escala.turnosHoje;
    final agora = DateTime.now();
    final inicio = _floorToSlot(agora);
    final fim =
        inicio.add(const Duration(minutes: _kSlotMin * _kSlotsJanela));

    final alocacaoByColab = {
      for (final a in alocacaoProvider.getAlocacoesAtivas())
        a.colaboradorId: a
    };
    final pausaByColab = {
      for (final p in cafeProvider.pausasAtivas) p.colaboradorId: p
    };

    final status = turnos
        .map(
          (t) => StatusColaboradorCompleto(
            turno: t,
            alocacao: alocacaoByColab[t.colaboradorId],
            pausaAtiva: pausaByColab[t.colaboradorId],
          ),
        )
        .toList();

    final calculator = GargaloCalculator(status, inicio: inicio, fim: fim);
    final setores = DepartamentoTipo.values
        .where(
          (d) => status.any(
            (s) => s.turno.trabalhando && s.turno.departamento == d,
          ),
        )
        .toList();

    final setoresData = <_SetorData>[];
    for (final setor in setores) {
      final slots = calculator.calcularPorSetor(setor);
      if (slots.isEmpty) continue;
      final peak = slots.fold(
        0,
        (a, s) => s.quantidade > a ? s.quantidade : a,
      );
      setoresData.add(_SetorData(setor: setor, slots: slots, peak: peak));
    }

    final temGargalos =
        setoresData.any((s) => s.slots.any((slot) => slot.gargalo));
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
              color: temGargalos ? AppColors.warning : AppColors.success,
            ),
          ),
        ],
      ),
      body: turnos.isEmpty || !temDados
          ? _buildEmpty()
          : _buildBody(setoresData, agora),
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

  Widget _buildBody(List<_SetorData> setoresData, DateTime agora) {
    return ListView(
      padding: const EdgeInsets.all(Dimensions.paddingMD),
      children: [
        ...setoresData.expand((s) {
          final gargalos = s.slots.where((slot) => slot.gargalo).toList();
          return [
            _SectionHeader(
              label: 'Setor: ${s.setor.nome}',
              icon: Icons.apartment_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            _CoberturaChart(
              slots: s.slots,
              peak: s.peak,
              agora: agora,
            ),
            if (gargalos.isNotEmpty) ...[
              const SizedBox(height: 20),
              const _SectionHeader(
                label: 'Alertas de Gargalo',
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
              ),
              const SizedBox(height: 10),
              ...gargalos.map(
                (slot) => _GargaloCard(
                  slot: slot,
                  drop: slot.drop,
                  baixaCobertura:
                      slot.quantidade < slot.capacidadeMinima,
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
          ];
        }),
      ],
    );
  }
}

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

class _CoberturaChart extends StatelessWidget {
  final List<SlotDisponibilidade> slots;
  final int peak;
  final DateTime agora;

  const _CoberturaChart({
    required this.slots,
    required this.peak,
    required this.agora,
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
                  final isAtual = !agora.isBefore(slot.inicio) &&
                      agora.isBefore(slot.fim);
                  final barH = peak > 0
                      ? (slot.quantidade / peak * maxH).clamp(4.0, maxH)
                      : 4.0;
                  final color = _barColor(slot.quantidade);

                  return SizedBox(
                    width: 52,
                    child: Column(
                      children: [
                        Text(
                          '${slot.quantidade}',
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
                          _formatTime(slot.inicio),
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

class _GargaloCard extends StatelessWidget {
  final SlotDisponibilidade slot;
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
      final nomes = slot.intervalosPrevistos.join(', ');
      final antes =
          _formatTime(slot.inicio.subtract(const Duration(minutes: 30)));
      return 'Há intervalos previstos para $nomes. Avalie liberar antes das $antes para diluir a queda.';
    }
    if (slot.saem.isNotEmpty) {
      return 'Prepare uma substituição antes das ${_formatTime(slot.inicio)} para cobrir as saídas.';
    }
    return 'Monitore a cobertura e redistribua colaboradores se necessário.';
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = drop >= 4 || slot.quantidade <= 1;
    final color = isCritical ? AppColors.danger : AppColors.warning;
    final bgColor =
        isCritical ? AppColors.alertCritical : AppColors.alertWarning;

    final saindoNomes = slot.saem;
    final voltandoNomes = slot.entram;

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
                    ? '${_formatTime(slot.inicio)} — cobertura baixa'
                    : '${_formatTime(slot.inicio)} — queda de $drop',
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
                  '${slot.quantidade} disponíveis',
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

enum _TipoEvento { saida, entrada }

class _Evento {
  final DateTime horario;
  final String nome;
  final _TipoEvento tipo;

  const _Evento({
    required this.horario,
    required this.nome,
    required this.tipo,
  });
}

class _ProximasMovimentacoes extends StatelessWidget {
  final List<SlotDisponibilidade> slots;

  const _ProximasMovimentacoes({required this.slots});

  @override
  Widget build(BuildContext context) {
    final eventos = <_Evento>[];

    for (final slot in slots) {
      for (final nome in slot.saem) {
        eventos.add(_Evento(
          horario: slot.inicio,
          nome: nome,
          tipo: _TipoEvento.saida,
        ));
      }
      for (final nome in slot.entram) {
        eventos.add(_Evento(
          horario: slot.inicio,
          nome: nome,
          tipo: _TipoEvento.entrada,
        ));
      }
    }

    eventos.sort((a, b) => a.horario.compareTo(b.horario));

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
              _formatTime(evento.horario),
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
