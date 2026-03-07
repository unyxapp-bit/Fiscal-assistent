/// Entity para Alocacao - Registro de colaborador em caixa
class Alocacao {
  final String id;
  final String colaboradorId;
  final String caixaId;
  final String? turnoEscalaId;
  final DateTime alocadoEm;
  final DateTime? liberadoEm;
  final String? motivoLiberacao;
  final String? alocadoPor;
  final String? observacoes;
  final DateTime createdAt;
  final bool intervaloMarcadoFeito;

  const Alocacao({
    required this.id,
    required this.colaboradorId,
    required this.caixaId,
    this.turnoEscalaId,
    required this.alocadoEm,
    this.liberadoEm,
    this.motivoLiberacao,
    this.alocadoPor,
    this.observacoes,
    DateTime? createdAt,
    this.intervaloMarcadoFeito = false,
  }) : createdAt = createdAt ?? alocadoEm;

  /// Verifica se a alocação está ativa
  bool get isAtiva => liberadoEm == null;

  /// Verifica se foi alocado hoje
  bool get isHoje {
    final hoje = DateTime.now();
    return alocadoEm.year == hoje.year &&
        alocadoEm.month == hoje.month &&
        alocadoEm.day == hoje.day;
  }

  /// Calcula duração da alocação (em minutos)
  int get duracaoMinutos {
    final fim = liberadoEm ?? DateTime.now();
    return fim.difference(alocadoEm).inMinutes;
  }

  Alocacao copyWith({
    String? id,
    String? colaboradorId,
    String? caixaId,
    String? turnoEscalaId,
    DateTime? alocadoEm,
    DateTime? liberadoEm,
    String? motivoLiberacao,
    String? alocadoPor,
    String? observacoes,
    DateTime? createdAt,
    bool? intervaloMarcadoFeito,
  }) {
    return Alocacao(
      id: id ?? this.id,
      colaboradorId: colaboradorId ?? this.colaboradorId,
      caixaId: caixaId ?? this.caixaId,
      turnoEscalaId: turnoEscalaId ?? this.turnoEscalaId,
      alocadoEm: alocadoEm ?? this.alocadoEm,
      liberadoEm: liberadoEm ?? this.liberadoEm,
      motivoLiberacao: motivoLiberacao ?? this.motivoLiberacao,
      alocadoPor: alocadoPor ?? this.alocadoPor,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      intervaloMarcadoFeito: intervaloMarcadoFeito ?? this.intervaloMarcadoFeito,
    );
  }
}
