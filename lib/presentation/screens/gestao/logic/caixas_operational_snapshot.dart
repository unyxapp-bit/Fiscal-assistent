class CaixasOperationalSnapshot {
  final int disponiveis;
  final int alocados;
  final int emPausa;
  final int gargalos;
  final int atrasos;
  final int risco;
  final int caixasOperacionais;
  final int caixasLivres;
  final int pausasNaFila;

  const CaixasOperationalSnapshot({
    required this.disponiveis,
    required this.alocados,
    required this.emPausa,
    required this.gargalos,
    required this.atrasos,
    required this.risco,
    required this.caixasOperacionais,
    required this.caixasLivres,
    required this.pausasNaFila,
  });

  bool get estaEstavel => risco == 0;
  bool get precisaAtencao => risco > 0;

  String get statusTitulo {
    if (estaEstavel) return 'Operação estável';
    if (risco == 1) return '1 ação precisa de atenção';
    return '$risco ações precisam de atenção';
  }

  String get statusDescricao {
    if (estaEstavel) return 'Sem atrasos ou gargalos previstos no momento.';

    final partes = <String>[];

    if (atrasos > 0) {
      partes.add(
          atrasos == 1 ? '1 pausa em atraso' : '$atrasos pausas em atraso');
    }

    if (gargalos > 0) {
      partes.add(gargalos == 1
          ? '1 gargalo previsto'
          : '$gargalos gargalos previstos');
    }

    return partes.join(' • ');
  }
}
