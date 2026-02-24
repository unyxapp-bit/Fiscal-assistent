class Formulario {
  final String id;
  final String titulo;
  final String descricao;
  final bool template;
  final bool ativo;
  final List<String> campos; // Nomes dos campos
  final DateTime createdAt;
  final DateTime updatedAt;

  Formulario({
    required this.id,
    required this.titulo,
    required this.descricao,
    this.template = false,
    this.ativo = true,
    required this.campos,
    required this.createdAt,
    required this.updatedAt,
  });

  Formulario copyWith({
    String? id,
    String? titulo,
    String? descricao,
    bool? template,
    bool? ativo,
    List<String>? campos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Formulario(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      template: template ?? this.template,
      ativo: ativo ?? this.ativo,
      campos: campos ?? this.campos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RespostaFormulario {
  final String id;
  final String formularioId;
  final Map<String, dynamic> valores; // Campo -> Valor
  final DateTime preenchidoEm;

  RespostaFormulario({
    required this.id,
    required this.formularioId,
    required this.valores,
    required this.preenchidoEm,
  });

  RespostaFormulario copyWith({
    String? id,
    String? formularioId,
    Map<String, dynamic>? valores,
    DateTime? preenchidoEm,
  }) {
    return RespostaFormulario(
      id: id ?? this.id,
      formularioId: formularioId ?? this.formularioId,
      valores: valores ?? this.valores,
      preenchidoEm: preenchidoEm ?? this.preenchidoEm,
    );
  }
}
