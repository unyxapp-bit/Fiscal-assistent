/// Entidade que representa um empacotador no plantão do dia
class PacotePlantao {
  final String id;
  final String fiscalId;
  final String colaboradorId;
  final DateTime data;
  final DateTime criadoEm;

  const PacotePlantao({
    required this.id,
    required this.fiscalId,
    required this.colaboradorId,
    required this.data,
    required this.criadoEm,
  });
}
