import 'evento_turno.dart';

/// Relatório gerado ao encerrar o turno
class RelatorioDia {
  final String id;
  final String fiscalId;
  final String dataStr;
  final DateTime turnoIniciadoEm;
  final DateTime turnoEncerradoEm;
  final int totalAlocacoes;
  final int totalColaboradores;
  final int totalCafes;
  final int totalIntervalos;
  final int totalEmpacotadores;
  final List<EventoTurno> eventos;

  const RelatorioDia({
    required this.id,
    required this.fiscalId,
    required this.dataStr,
    required this.turnoIniciadoEm,
    required this.turnoEncerradoEm,
    required this.totalAlocacoes,
    required this.totalColaboradores,
    required this.totalCafes,
    required this.totalIntervalos,
    required this.totalEmpacotadores,
    required this.eventos,
  });

  Duration get duracaoTurno => turnoEncerradoEm.difference(turnoIniciadoEm);
}
