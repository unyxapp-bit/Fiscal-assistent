/// Tipos de notificação do sistema
enum TipoNotificacao {
  entradaProxima('Entrada Próxima', 'Colaborador está chegando'),
  intervaloProximo('Intervalo Próximo', 'Hora do intervalo'),
  retornoProximo('Retorno Próximo', 'Retorno do intervalo em breve'),
  cafeDisponivel('Café Disponível', 'Vaga disponível para café'),
  saidaProxima('Saída Próxima', 'Fim do expediente próximo'),
  atrasado('Atrasado', 'Colaborador está atrasado'),
  selfSemOperador('Self Sem Operador', 'Self checkout precisa de operador'),
  coberturaBaixa('Cobertura Baixa', 'Poucos caixas ativos'),
  fechamentoLoja('Fechamento Loja', 'Loja vai fechar em breve'),
  outro('Outro', 'Outra notificação');

  const TipoNotificacao(this.nome, this.descricao);

  final String nome;
  final String descricao;

  /// Converte string para enum
  static TipoNotificacao fromString(String value) {
    switch (value.toLowerCase()) {
      case 'entrada_proxima':
        return TipoNotificacao.entradaProxima;
      case 'intervalo_proximo':
        return TipoNotificacao.intervaloProximo;
      case 'retorno_proximo':
        return TipoNotificacao.retornoProximo;
      case 'cafe_disponivel':
        return TipoNotificacao.cafeDisponivel;
      case 'saida_proxima':
        return TipoNotificacao.saidaProxima;
      case 'atrasado':
        return TipoNotificacao.atrasado;
      case 'self_sem_operador':
        return TipoNotificacao.selfSemOperador;
      case 'cobertura_baixa':
        return TipoNotificacao.coberturaBaixa;
      case 'fechamento_loja':
        return TipoNotificacao.fechamentoLoja;
      case 'outro':
        return TipoNotificacao.outro;
      default:
        throw ArgumentError('Tipo de notificação inválido: $value');
    }
  }

  /// Converte enum para string para salvar no banco
  String toJson() => name;
}
