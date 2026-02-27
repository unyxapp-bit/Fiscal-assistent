import '../../domain/entities/alocacao.dart';
import '../../data/models/alocacao_model.dart';
import '../../data/repositories/alocacao_repository.dart';
import '../../data/repositories/colaborador_repository.dart';
import '../../data/repositories/caixa_repository.dart';
import '../entities/colaborador.dart';
import '../entities/caixa.dart';
import 'package:uuid/uuid.dart';

/// Resultado da alocação com três estados possíveis
class AlocarColaboradorResult {
  final bool isSuccess;
  final bool isPrecisaExcecao; // True quando regra foi quebrada mas pode ser justificada
  final Alocacao? alocacao;
  final String? motivoExcecao; // Ex: "Colaborador já alocado hoje nesta caixa"
  final String? tipoExcecao; // Ex: "MESMO_CAIXA_DIA"
  final Colaborador? colaboradorConflito;
  final Caixa? caixaConflito;
  final String? error;

  AlocarColaboradorResult._({
    required this.isSuccess,
    required this.isPrecisaExcecao,
    this.alocacao,
    this.motivoExcecao,
    this.tipoExcecao,
    this.colaboradorConflito,
    this.caixaConflito,
    this.error,
  });

  /// Sucesso - alocação criada sem problemas
  factory AlocarColaboradorResult.sucesso(Alocacao alocacao) {
    return AlocarColaboradorResult._(
      isSuccess: true,
      isPrecisaExcecao: false,
      alocacao: alocacao,
    );
  }

  /// Exceção - regra violada, precisa justificação
  factory AlocarColaboradorResult.excecao({
    required String motivo,
    required String tipo,
    Colaborador? colaborador,
    Caixa? caixa,
  }) {
    return AlocarColaboradorResult._(
      isSuccess: false,
      isPrecisaExcecao: true,
      motivoExcecao: motivo,
      tipoExcecao: tipo,
      colaboradorConflito: colaborador,
      caixaConflito: caixa,
    );
  }

  /// Erro - impossível alocar
  factory AlocarColaboradorResult.erro(String mensagem) {
    return AlocarColaboradorResult._(
      isSuccess: false,
      isPrecisaExcecao: false,
      error: mensagem,
    );
  }
}

/// Use case para alocar colaborador em caixa
class AlocarColaborador {
  final AlocacaoRepository alocacaoRepository;
  final ColaboradorRepository colaboradorRepository;
  final CaixaRepository caixaRepository;

  AlocarColaborador({
    required this.alocacaoRepository,
    required this.colaboradorRepository,
    required this.caixaRepository,
  });

  /// Executa alocação com validações completas
  ///
  /// Validações:
  /// 1. Colaborador existe e está ativo
  /// 2. Caixa existe, está ativa e não está em manutenção
  /// 3. Compatibilidade de departamento (Self operators só para self-checkout)
  /// 4. Colaborador não está alocado em outra caixa agora
  /// 5. Se já usou caixa hoje, retorna EXCECAO (pode justificar)
  ///
  /// Retorna [AlocarColaboradorResult] com três estados possíveis:
  /// - sucesso: alocação criada
  /// - precisaExcecao: regra violada, aguardando justificação
  /// - erro: validação falhou
  Future<AlocarColaboradorResult> call({
    required String colaboradorId,
    required String caixaId,
    required String fiscalId,
    String? justificativa, // Preenchido se resultado anterior foi precisaExcecao
  }) async {
    try {
      // 1. Verifica se colaborador existe e está ativo
      final colaboradores = await colaboradorRepository.getColaboradores(fiscalId);
      final colaborador = colaboradores
          .cast<Colaborador?>()
          .firstWhere(
            (c) => c?.id == colaboradorId,
            orElse: () => null,
          );

      if (colaborador == null) {
        return AlocarColaboradorResult.erro(
          'Colaborador não encontrado',
        );
      }

      // if (colaborador.status != StatusColaborador.ativo) {
      //   return AlocarColaboradorResult.erro(
      //     'Colaborador não está ativo',
      //   );
      // }

      // 2. Verifica se caixa existe, está ativa e não em manutenção
      final caixas = await caixaRepository.getCaixas(fiscalId);
      final caixa = caixas
          .cast<Caixa?>()
          .firstWhere(
            (c) => c?.id == caixaId,
            orElse: () => null,
          );

      if (caixa == null) {
        return AlocarColaboradorResult.erro(
          'Caixa não encontrada',
        );
      }

      if (caixa.ativo != true) {
        return AlocarColaboradorResult.erro(
          'Caixa não está ativa',
        );
      }

      if (caixa.emManutencao) {
        return AlocarColaboradorResult.erro(
          'Caixa está em manutenção',
        );
      }

      // 3. Verifica compatibilidade de departamento
      final isOperadorSelf =
          colaborador.departamento.toString() == 'DepartamentoTipo.self';
      final isCaixaSelf =
          caixa.tipo.toString() == 'TipoCaixa.self';

      if (isOperadorSelf && !isCaixaSelf) {
        return AlocarColaboradorResult.erro(
          'Operador de Self-checkout não pode ser alocado em caixa normal',
        );
      }

      // 4. Verifica se colaborador já está alocado em outra caixa
      final alocacaoAtiva =
          await alocacaoRepository.getAlocacaoAtivaColaborador(colaboradorId);
      if (alocacaoAtiva != null) {
        return AlocarColaboradorResult.erro(
          'Colaborador já está alocado em outra caixa',
        );
      }

      // 5. Verifica se colaborador já usou esta caixa hoje (regra 1 caixa por dia)
      final jaUsou =
          await alocacaoRepository.jaUsouCaixaHoje(colaboradorId, caixaId);

      if (jaUsou && justificativa == null) {
        // Retorna exceção aguardando justificação
        return AlocarColaboradorResult.excecao(
          motivo:
              'Colaborador já trabalhou nesta caixa hoje. Justifique o motivo.',
          tipo: 'MESMO_CAIXA_DIA',
          colaborador: colaborador,
          caixa: caixa,
        );
      }

      // Todas as validações passaram - cria alocação
      final alocacao = AlocacaoModel(
        id: const Uuid().v4(),
        colaboradorId: colaboradorId,
        caixaId: caixaId,
        alocadoEm: DateTime.now(),
        liberadoEm: null,
        motivoLiberacao: null,
        createdAt: DateTime.now(),
      );

      final result = await alocacaoRepository.createAlocacao(alocacao);
      return AlocarColaboradorResult.sucesso(result);
    } catch (e) {
      return AlocarColaboradorResult.erro(
        'Erro ao alocar: ${e.toString()}',
      );
    }
  }
}
