/// Entidade que representa um colaborador em atividade fora dos caixas
class OutroSetor {
  final String id;
  final String fiscalId;
  final String colaboradorId;
  final String setor; // descrição do setor/função (ex: "Estoque", "Padaria")
  final DateTime data;
  final DateTime criadoEm;

  const OutroSetor({
    required this.id,
    required this.fiscalId,
    required this.colaboradorId,
    required this.setor,
    required this.data,
    required this.criadoEm,
  });
}
