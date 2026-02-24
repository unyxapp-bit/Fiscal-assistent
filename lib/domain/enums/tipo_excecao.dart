/// Tipos de exceção que podem ser registradas
enum TipoExcecao {
  caixaRepetido('Caixa Repetido', 'Colaborador usou mesmo caixa 2x no dia'),
  intervaloAtrasado('Intervalo Atrasado', 'Intervalo não concedido no prazo'),
  coberturaMinima('Cobertura Mínima', 'Menos caixas ativos que o mínimo'),
  selfSemOperador('Self Sem Operador', 'Self checkout ficou sem supervisão'),
  outro('Outro', 'Outra exceção');

  const TipoExcecao(this.nome, this.descricao);

  final String nome;
  final String descricao;

  /// Converte string para enum
  static TipoExcecao fromString(String value) {
    switch (value.toLowerCase()) {
      case 'caixa_repetido':
        return TipoExcecao.caixaRepetido;
      case 'intervalo_atrasado':
        return TipoExcecao.intervaloAtrasado;
      case 'cobertura_minima':
        return TipoExcecao.coberturaMinima;
      case 'self_sem_operador':
        return TipoExcecao.selfSemOperador;
      case 'outro':
        return TipoExcecao.outro;
      default:
        throw ArgumentError('Tipo de exceção inválido: $value');
    }
  }

  /// Converte enum para string para salvar no banco
  String toJson() => name;
}
