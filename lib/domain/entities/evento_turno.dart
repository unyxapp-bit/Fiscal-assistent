/// Tipos de evento que podem ocorrer durante um turno
enum TipoEvento {
  turnoIniciado('turno_iniciado', 'Turno iniciado'),
  colaboradorAlocado('colab_alocado', 'Colaborador alocado'),
  colaboradorLiberado('colab_liberado', 'Colaborador liberado'),
  cafeIniciado('cafe_iniciado', 'Café iniciado'),
  cafeEncerrado('cafe_encerrado', 'Café encerrado'),
  intervaloIniciado('intervalo_iniciado', 'Intervalo iniciado'),
  intervaloEncerrado('intervalo_encerrado', 'Intervalo encerrado'),
  intervaloMarcadoFeito('intervalo_marcado_feito', 'Intervalo marcado como feito'),
  intervaloAguardandoLiberacao('intervalo_aguardando_liberacao', 'Aguardando liberação para intervalo'),
  empacotadorAdicionado('empacotador_adicionado', 'Empacotador adicionado'),
  empacotadorRemovido('empacotador_removido', 'Empacotador removido'),
  checklistConcluido('checklist_concluido', 'Checklist concluído'),
  entregaCadastrada('entrega_cadastrada', 'Entrega cadastrada'),
  entregaStatusAlterado('entrega_status', 'Status de entrega atualizado'),
  ocorrenciaRegistrada('ocorrencia_registrada', 'Ocorrência registrada'),
  ocorrenciaResolvida('ocorrencia_resolvida', 'Ocorrência resolvida'),
  anotacaoCriada('anotacao_criada', 'Anotação criada'),
  formularioRespondido('formulario_respondido', 'Formulário respondido');

  final String valor;
  final String label;
  const TipoEvento(this.valor, this.label);

  static TipoEvento fromValor(String v) =>
      TipoEvento.values.firstWhere((e) => e.valor == v,
          orElse: () => TipoEvento.colaboradorAlocado);
}

/// Evento registrado durante um turno
class EventoTurno {
  final String id;
  final String fiscalId;
  final TipoEvento tipo;
  final DateTime timestamp;
  final String? colaboradorNome;
  final String? caixaNome;
  final String? detalhe;

  const EventoTurno({
    required this.id,
    required this.fiscalId,
    required this.tipo,
    required this.timestamp,
    this.colaboradorNome,
    this.caixaNome,
    this.detalhe,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fiscalId': fiscalId,
        'tipo': tipo.valor,
        'timestamp': timestamp.toIso8601String(),
        'colaboradorNome': colaboradorNome,
        'caixaNome': caixaNome,
        'detalhe': detalhe,
      };

  factory EventoTurno.fromJson(Map<String, dynamic> j) => EventoTurno(
        id: j['id'] as String,
        fiscalId: j['fiscalId'] as String,
        tipo: TipoEvento.fromValor(j['tipo'] as String),
        timestamp: DateTime.parse(j['timestamp'] as String),
        colaboradorNome: j['colaboradorNome'] as String?,
        caixaNome: j['caixaNome'] as String?,
        detalhe: j['detalhe'] as String?,
      );
}
