import '../enums/status_presenca.dart';

class Snapshot {
  final String id;
  final String fiscalId;
  final DateTime dataHora;
  final bool finalizado;
  final List<PresencaSnapshot> presencas;

  Snapshot({
    required this.id,
    required this.fiscalId,
    required this.dataHora,
    required this.finalizado,
    required this.presencas,
  });

  int get totalConfirmados =>
      presencas.where((p) => p.status == StatusPresenca.confirmado).length;

  int get totalPendentes =>
      presencas.where((p) => p.status == StatusPresenca.pendente).length;

  int get totalAusentes =>
      presencas.where((p) => p.status == StatusPresenca.ausente).length;

  int get totalComFolga =>
      presencas.where((p) => p.status == StatusPresenca.folga).length;

  int get totalAtivos =>
      presencas.length - totalComFolga;

  double get percentualPresenca {
    if (totalAtivos == 0) return 0;
    return (totalConfirmados / totalAtivos) * 100;
  }

  Snapshot copyWith({
    String? id,
    String? fiscalId,
    DateTime? dataHora,
    bool? finalizado,
    List<PresencaSnapshot>? presencas,
  }) {
    return Snapshot(
      id: id ?? this.id,
      fiscalId: fiscalId ?? this.fiscalId,
      dataHora: dataHora ?? this.dataHora,
      finalizado: finalizado ?? this.finalizado,
      presencas: presencas ?? this.presencas,
    );
  }
}

class PresencaSnapshot {
  final String id;
  final String colaboradorId;
  final StatusPresenca status;
  final DateTime horarioEsperado;
  final DateTime? confirmadoEm;
  final int? minutosAtraso;
  final String? observacao;
  final String? substituidoPor;

  PresencaSnapshot({
    required this.id,
    required this.colaboradorId,
    required this.status,
    required this.horarioEsperado,
    this.confirmadoEm,
    this.minutosAtraso,
    this.observacao,
    this.substituidoPor,
  });

  bool get temAtraso => minutosAtraso != null && minutosAtraso! > 0;
  bool get foiSubstituido => substituidoPor != null;

  PresencaSnapshot copyWith({
    String? id,
    String? colaboradorId,
    StatusPresenca? status,
    DateTime? horarioEsperado,
    DateTime? confirmadoEm,
    int? minutosAtraso,
    String? observacao,
    String? substituidoPor,
  }) {
    return PresencaSnapshot(
      id: id ?? this.id,
      colaboradorId: colaboradorId ?? this.colaboradorId,
      status: status ?? this.status,
      horarioEsperado: horarioEsperado ?? this.horarioEsperado,
      confirmadoEm: confirmadoEm ?? this.confirmadoEm,
      minutosAtraso: minutosAtraso ?? this.minutosAtraso,
      observacao: observacao ?? this.observacao,
      substituidoPor: substituidoPor ?? this.substituidoPor,
    );
  }
}

class Sugestao {
  final String colaboradorId;
  final String nomeColaborador;
  final int prioridade;
  final String motivo;

  Sugestao({
    required this.colaboradorId,
    required this.nomeColaborador,
    required this.prioridade,
    required this.motivo,
  });
}
