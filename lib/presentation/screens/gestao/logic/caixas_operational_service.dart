import '../../../../domain/entities/alocacao.dart';
import '../../../../domain/entities/caixa.dart';
import '../../../../domain/entities/colaborador.dart';
import '../../../providers/alocacao_provider.dart';
import '../../../providers/cafe_provider.dart';
import '../../../providers/caixa_provider.dart';
import '../../../providers/colaborador_provider.dart';
import '../../../providers/escala_provider.dart';
import '../visao_gargalo_screen.dart';
import 'caixas_operational_snapshot.dart';

class CaixasOperationalService {
  const CaixasOperationalService._();

  static CaixasOperationalSnapshot buildSnapshot({
    required ColaboradorProvider colaboradores,
    required CaixaProvider caixas,
    required AlocacaoProvider alocacao,
    required CafeProvider cafe,
    required EscalaProvider escala,
  }) {
    final alocacoesAtivas = alocacao.getAlocacoesAtivas();
    final alocadosIds = alocacoesAtivas.map((a) => a.colaboradorId).toSet();
    final pausaIds = cafe.pausasAtivas.map((p) => p.colaboradorId).toSet();
    final ativosBase = colaboradoresOperacionais(colaboradores, escala);
    final disponiveis = ativosBase
        .where((c) => !alocadosIds.contains(c.id) && !pausaIds.contains(c.id))
        .toList();
    final caixasOperacionaisList = caixasOperacionais(caixas);
    final caixasLivres = caixasOperacionaisList
        .where((c) => alocacao.getAlocacaoCaixa(c.id) == null)
        .toList();
    final gargalos = contarGargalosHoje(
      escala: escala,
      alocacao: alocacao,
      cafe: cafe,
    );
    final atrasos = cafe.totalEmAtraso;
    final risco = (atrasos + gargalos).toInt();
    final pausasNaFila = buildPauseQueue(escala, alocacao, cafe).length;

    return CaixasOperationalSnapshot(
      disponiveis: disponiveis.length,
      alocados: alocacao.quantidadeAtivasAgora,
      emPausa: cafe.totalAtivos,
      gargalos: gargalos,
      atrasos: atrasos,
      risco: risco,
      caixasOperacionais: caixasOperacionaisList.length,
      caixasLivres: caixasLivres.length,
      pausasNaFila: pausasNaFila,
    );
  }

  static List<Colaborador> colaboradoresDisponiveis({
    required ColaboradorProvider colaboradores,
    required AlocacaoProvider alocacao,
    required CafeProvider cafe,
    required EscalaProvider escala,
  }) {
    final alocacoesAtivas = alocacao.getAlocacoesAtivas();
    final alocadosIds = alocacoesAtivas.map((a) => a.colaboradorId).toSet();
    final pausaIds = cafe.pausasAtivas.map((p) => p.colaboradorId).toSet();

    return colaboradoresOperacionais(colaboradores, escala)
        .where((c) => !alocadosIds.contains(c.id) && !pausaIds.contains(c.id))
        .toList();
  }

  static List<Caixa> caixasLivres({
    required CaixaProvider caixas,
    required AlocacaoProvider alocacao,
  }) {
    return caixasOperacionais(caixas)
        .where((c) => alocacao.getAlocacaoCaixa(c.id) == null)
        .toList();
  }

  static List<Caixa> caixasOperacionais(CaixaProvider caixas) {
    final todos =
        caixas.caixasTodos.isNotEmpty ? caixas.caixasTodos : caixas.caixas;
    return todos.where((caixa) => caixa.ativo).toList()
      ..sort((a, b) => a.numero.compareTo(b.numero));
  }

  static List<Colaborador> colaboradoresOperacionais(
    ColaboradorProvider colaboradores,
    EscalaProvider escala,
  ) {
    final idsEscalados =
        escala.trabalhandoHoje.map((e) => e.colaboradorId).toSet();

    if (idsEscalados.isEmpty) {
      return colaboradores.todosColaboradores.where((c) => c.ativo).toList();
    }

    return colaboradores.todosColaboradores
        .where((c) => c.ativo && idsEscalados.contains(c.id))
        .toList();
  }

  static List<Alocacao> alocacoesAtivas(AlocacaoProvider alocacao) {
    return alocacao.getAlocacoesAtivas();
  }

  static List<dynamic> buildPauseQueue(
    EscalaProvider escala,
    AlocacaoProvider alocacao,
    CafeProvider cafe,
  ) {
    // Mantém o retorno flexível nesta primeira fase para evitar acoplamento
    // com o modelo interno da fila de pausa existente em gestao_screen.dart.
    // Na próxima fase, este método deve retornar uma entidade tipada.
    return const <dynamic>[];
  }
}
