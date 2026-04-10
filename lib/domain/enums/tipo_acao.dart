/// Tipos de ação que podem ser registradas no histórico
enum TipoAcao {
  alocacaoCaixa('Alocação em Caixa', 'Colaborador alocado em caixa'),
  liberacaoIntervalo(
      'Liberação Intervalo', 'Colaborador liberado para intervalo'),
  liberacaoCafe('Liberação Café', 'Colaborador liberado para café'),
  retornoIntervalo('Retorno Intervalo', 'Colaborador retornou do intervalo'),
  retornoCafe('Retorno Café', 'Colaborador retornou do café'),
  saida('Saída', 'Colaborador finalizou expediente'),
  entrada('Entrada', 'Colaborador iniciou expediente'),
  trocaCaixa('Troca de Caixa', 'Colaborador trocou de caixa'),
  excecaoCriada('Exceção Criada', 'Exceção foi registrada'),
  outro('Outro', 'Outra ação');

  const TipoAcao(this.nome, this.descricao);

  final String nome;
  final String descricao;

  /// Converte string para enum
  static TipoAcao fromString(String value) {
    switch (value.toLowerCase()) {
      case 'alocacao_caixa':
        return TipoAcao.alocacaoCaixa;
      case 'liberacao_intervalo':
        return TipoAcao.liberacaoIntervalo;
      case 'liberacao_cafe':
        return TipoAcao.liberacaoCafe;
      case 'retorno_intervalo':
        return TipoAcao.retornoIntervalo;
      case 'retorno_cafe':
        return TipoAcao.retornoCafe;
      case 'saida':
        return TipoAcao.saida;
      case 'entrada':
        return TipoAcao.entrada;
      case 'troca_caixa':
        return TipoAcao.trocaCaixa;
      case 'excecao_criada':
        return TipoAcao.excecaoCriada;
      case 'outro':
        return TipoAcao.outro;
      default:
        throw ArgumentError('Tipo de ação inválido: $value');
    }
  }

  /// Converte enum para string para salvar no banco
  String toJson() => name;
}
