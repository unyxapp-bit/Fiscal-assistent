import '../../../domain/entities/alocacao.dart';
import '../../providers/escala_provider.dart';
import '../../providers/cafe_provider.dart';
import '../../../domain/enums/departamento_tipo.dart';

class StatusColaboradorCompleto {
  final TurnoLocal turno;
  final Alocacao? alocacao;
  final PausaCafe? pausaAtiva;

  const StatusColaboradorCompleto({
    required this.turno,
    this.alocacao,
    this.pausaAtiva,
  });
}

class SlotDisponibilidade {
  final DateTime inicio;
  final DateTime fim;
  final int quantidade;
  final int capacidadeMinima;
  final bool gargalo;
  final int drop;
  final List<String> saem;
  final List<String> entram;
  final List<String> intervalosPrevistos;

  const SlotDisponibilidade({
    required this.inicio,
    required this.fim,
    required this.quantidade,
    required this.capacidadeMinima,
    required this.gargalo,
    required this.drop,
    required this.saem,
    required this.entram,
    required this.intervalosPrevistos,
  });
}

class GargaloCalculator {
  final List<StatusColaboradorCompleto> status;
  final DateTime inicio;
  final DateTime fim;

  GargaloCalculator(
    this.status, {
    required this.inicio,
    required this.fim,
  });

  List<SlotDisponibilidade> calcularPorSetor(DepartamentoTipo setor) {
    final slots = <SlotDisponibilidade>[];
    var horario = inicio;

    while (horario.isBefore(fim)) {
      final fimSlot = horario.add(const Duration(minutes: 30));

      int presentes = 0;
      final saem = <String>[];
      final entram = <String>[];
      final intervalosPrevistos = <String>[];

      for (final s in status) {
        if (s.turno.departamento != setor) continue;
        if (!s.turno.trabalhando) continue;

        final entrada = s.alocacao?.alocadoEm ??
            _parseTurnoTime(
              s.turno.data,
              s.turno.entrada,
            );
        var saida = _parseTurnoTime(s.turno.data, s.turno.saida);
        var intervalo = _parseTurnoTime(s.turno.data, s.turno.intervalo);

        if (entrada == null || saida == null) continue;
        if (saida.isBefore(entrada)) {
          saida = saida.add(const Duration(days: 1));
        }
        if (intervalo != null && intervalo.isBefore(entrada)) {
          intervalo = intervalo.add(const Duration(days: 1));
        }

        final estaPresente =
            !horario.isBefore(entrada) && horario.isBefore(saida);

        final pausa = s.pausaAtiva;
        final fimPausa = pausa != null
            ? (pausa.finalizadoEm ??
                pausa.iniciadoEm.add(Duration(minutes: pausa.duracaoMinutos)))
            : null;
        final emPausa = pausa != null &&
            !horario.isBefore(pausa.iniciadoEm) &&
            (fimPausa == null || horario.isBefore(fimPausa));

        if (estaPresente && !emPausa) {
          presentes++;
        }

        if (!saida.isBefore(horario) && saida.isBefore(fimSlot)) {
          saem.add(s.turno.colaboradorNome.split(' ').first);
        }
        if (!entrada.isBefore(horario) && entrada.isBefore(fimSlot)) {
          entram.add(s.turno.colaboradorNome.split(' ').first);
        }
        if (intervalo != null &&
            !intervalo.isBefore(horario) &&
            intervalo.isBefore(fimSlot)) {
          intervalosPrevistos.add(s.turno.colaboradorNome.split(' ').first);
        }
      }

      final capacidadeMinima = _capacidadeMinima(setor);
      final drop = slots.isEmpty ? 0 : slots.last.quantidade - presentes;
      final gargalo = presentes < capacidadeMinima || (drop >= 2);

      slots.add(
        SlotDisponibilidade(
          inicio: horario,
          fim: fimSlot,
          quantidade: presentes,
          capacidadeMinima: capacidadeMinima,
          gargalo: gargalo,
          drop: drop,
          saem: saem,
          entram: entram,
          intervalosPrevistos: intervalosPrevistos,
        ),
      );

      horario = fimSlot;
    }

    return slots;
  }

  int _capacidadeMinima(DepartamentoTipo setor) {
    return switch (setor) {
      DepartamentoTipo.caixa => 6,
      DepartamentoTipo.fiscal => 2,
      DepartamentoTipo.pacote => 3,
      _ => 1,
    };
  }
}

DateTime? _parseTurnoTime(DateTime base, String? hhmm) {
  if (hhmm == null || hhmm.isEmpty) return null;
  final p = hhmm.split(':');
  if (p.length < 2) return null;
  final h = int.tryParse(p[0]) ?? 0;
  final m = int.tryParse(p[1]) ?? 0;
  return DateTime(base.year, base.month, base.day, h, m);
}
