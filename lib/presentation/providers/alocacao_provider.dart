import 'package:flutter/material.dart';
import '../../domain/entities/alocacao.dart';
import '../../domain/entities/colaborador.dart';
import '../../domain/entities/caixa.dart';
import '../../domain/usecases/alocar_colaborador.dart';
import '../../domain/usecases/liberar_alocacao.dart';
import '../../domain/usecases/get_alocacoes_ativas.dart';

/// Estado de carregamento
enum LoadingState {
  idle,
  loading,
  success,
  error,
}

/// Provider para gerenciar alocações
class AlocacaoProvider extends ChangeNotifier {
  final AlocarColaborador alocarColaboradorUseCase;
  final LiberarAlocacao liberarAlocacaoUseCase;
  final GetAlocacoesAtivas getAlocacoesAtivasUseCase;

  AlocacaoProvider({
    required this.alocarColaboradorUseCase,
    required this.liberarAlocacaoUseCase,
    required this.getAlocacoesAtivasUseCase,
  });

  // Estado
  List<Alocacao> _alocacoes = [];
  LoadingState _loadingState = LoadingState.idle;
  String? _error;
  bool _mostrarDialogExcecao = false;
  AlocarColaboradorResult? _resultadoExcecao;
  Colaborador? _colaboradorExcecao;
  Caixa? _caixaExcecao;

  // Getters
  List<Alocacao> get alocacoes => _alocacoes;
  LoadingState get loadingState => _loadingState;
  String? get error => _error;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get mostrarDialogExcecao => _mostrarDialogExcecao;
  AlocarColaboradorResult? get resultadoExcecao => _resultadoExcecao;
  Colaborador? get colaboradorExcecao => _colaboradorExcecao;
  Caixa? get caixaExcecao => _caixaExcecao;

  // Computados
  int get quantidadeAlocacoes => _alocacoes.length;
  int get quantidadeAtivasAgora =>
      _alocacoes.where((a) => a.liberadoEm == null).length;
  int get quantidadeLiberadas =>
      _alocacoes.where((a) => a.liberadoEm != null).length;
  int get totalAlocacoes => quantidadeAtivasAgora;

  /// Carrega alocações ativas
  Future<void> loadAlocacoes(String fiscalId) async {
    _loadingState = LoadingState.loading;
    _error = null;
    notifyListeners();

    try {
      _alocacoes = await getAlocacoesAtivasUseCase(fiscalId);
      _loadingState = LoadingState.success;
    } catch (e) {
      _error = 'Erro ao carregar alocações: $e';
      _loadingState = LoadingState.error;
    }
    notifyListeners();
  }

  /// Inicia stream de alocações em tempo real
  void watchAlocacoes(String fiscalId) {
    getAlocacoesAtivasUseCase.watch(fiscalId).listen((alocacoes) {
      _alocacoes = alocacoes;
      notifyListeners();
    });
  }

  /// Aloca colaborador em caixa
  Future<void> alocarColaborador({
    required String colaboradorId,
    required String caixaId,
    required String fiscalId,
    String? justificativa,
  }) async {
    _loadingState = LoadingState.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await alocarColaboradorUseCase.call(
        colaboradorId: colaboradorId,
        caixaId: caixaId,
        fiscalId: fiscalId,
        justificativa: justificativa,
      );

      if (result.isSuccess) {
        _loadingState = LoadingState.success;
        // Alocação já foi adicionada via stream
      } else if (result.isPrecisaExcecao) {
        // Mostrar dialog de exceção
        _resultadoExcecao = result;
        _colaboradorExcecao = result.colaboradorConflito;
        _caixaExcecao = result.caixaConflito;
        _mostrarDialogExcecao = true;
        _loadingState = LoadingState.idle;
      } else {
        _error = result.error ?? 'Erro ao alocar';
        _loadingState = LoadingState.error;
      }
    } catch (e) {
      _error = 'Erro ao alocar: $e';
      _loadingState = LoadingState.error;
    }
    notifyListeners();
  }

  /// Fecha dialog de exceção
  void fecharDialogExcecao() {
    _mostrarDialogExcecao = false;
    _resultadoExcecao = null;
    _colaboradorExcecao = null;
    _caixaExcecao = null;
    notifyListeners();
  }

  /// Libera alocação
  Future<void> liberarAlocacao(String alocacaoId, String motivo) async {
    _loadingState = LoadingState.loading;
    _error = null;
    notifyListeners();

    try {
      await liberarAlocacaoUseCase(
        alocacaoId: alocacaoId,
        motivo: motivo,
      );
      _loadingState = LoadingState.success;
      // Alocação será removida da lista via stream
    } catch (e) {
      _error = 'Erro ao liberar: $e';
      _loadingState = LoadingState.error;
    }
    notifyListeners();
  }

  /// Encontra alocação de um colaborador
  Alocacao? getAlocacaoColaborador(String colaboradorId) {
    try {
      return _alocacoes.firstWhere((a) =>
          a.colaboradorId == colaboradorId && a.liberadoEm == null);
    } catch (e) {
      return null;
    }
  }

  /// Encontra alocação de uma caixa
  Alocacao? getAlocacaoCaixa(String caixaId) {
    try {
      return _alocacoes.firstWhere((a) =>
          a.caixaId == caixaId && a.liberadoEm == null);
    } catch (e) {
      return null;
    }
  }

  /// Busca todas as alocações ativas de um período
  List<Alocacao> getAlocacoesAtivas() {
    return _alocacoes.where((a) => a.liberadoEm == null).toList();
  }

  /// Busca todas as alocações liberadas
  List<Alocacao> getAlocacoesLiberadas() {
    return _alocacoes.where((a) => a.liberadoEm != null).toList();
  }
}
