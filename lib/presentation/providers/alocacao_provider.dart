import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/repositories/alocacao_repository.dart';
import '../../domain/entities/alocacao.dart';
import '../../domain/entities/colaborador.dart';
import '../../domain/entities/caixa.dart';
import '../../domain/usecases/alocar_colaborador.dart';
import '../../domain/usecases/liberar_alocacao.dart';
import '../../domain/usecases/get_alocacoes_ativas.dart';
import '../../data/services/notification_service.dart';
import 'escala_provider.dart';

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
  final AlocacaoRepository repository;

  AlocacaoProvider({
    required this.alocarColaboradorUseCase,
    required this.liberarAlocacaoUseCase,
    required this.getAlocacoesAtivasUseCase,
    required this.repository,
  });

  // Estado
  List<Alocacao> _alocacoes = [];
  LoadingState _loadingState = LoadingState.idle;
  String? _error;
  bool _mostrarDialogExcecao = false;
  AlocarColaboradorResult? _resultadoExcecao;
  Colaborador? _colaboradorExcecao;
  Caixa? _caixaExcecao;

  /// IDs de colaboradores cujo intervalo foi manualmente marcado como feito.
  /// Memória de sessão — resetado ao liberar a alocação.
  final Set<String> _intervalosMarcados = {};

  /// IDs de colaboradores aguardando liberação para o intervalo.
  /// Memória de sessão — resetado ao liberar a alocação.
  final Set<String> _aguardandoIntervalo = {};

  EscalaProvider? _escalaProvider;
  Timer? _timerSaidas;
  final Set<String> _saidasProcessadas = {};
  DateTime? _diaProcessado;

  // Getters
  List<Alocacao> get alocacoes => _alocacoes;
  LoadingState get loadingState => _loadingState;
  String? get error => _error;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get mostrarDialogExcecao => _mostrarDialogExcecao;
  AlocarColaboradorResult? get resultadoExcecao => _resultadoExcecao;
  Colaborador? get colaboradorExcecao => _colaboradorExcecao;
  Caixa? get caixaExcecao => _caixaExcecao;

  bool isIntervaloMarcado(String colaboradorId) =>
      _intervalosMarcados.contains(colaboradorId);

  bool isAguardandoIntervalo(String colaboradorId) =>
      _aguardandoIntervalo.contains(colaboradorId);

  void marcarAguardandoIntervalo(String colaboradorId) {
    _aguardandoIntervalo.add(colaboradorId);
    notifyListeners();
  }

  void desmarcarAguardandoIntervalo(String colaboradorId) {
    _aguardandoIntervalo.remove(colaboradorId);
    notifyListeners();
  }

  /// Conecta o provider de escala e inicia liberação automática por saída.
  void vincularEscala(EscalaProvider escala) {
    _escalaProvider = escala;
    _iniciarTimerSaidas();
  }

  void _iniciarTimerSaidas() {
    if (_timerSaidas != null) return;
    _verificarSaidasAutomaticas();
    _timerSaidas = Timer.periodic(const Duration(minutes: 1), (_) {
      _verificarSaidasAutomaticas();
    });
  }

  void _verificarSaidasAutomaticas() {
    final escala = _escalaProvider;
    if (escala == null) return;

    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    if (_diaProcessado == null ||
        _diaProcessado!.year != hoje.year ||
        _diaProcessado!.month != hoje.month ||
        _diaProcessado!.day != hoje.day) {
      _saidasProcessadas.clear();
      _intervalosMarcados.clear();
      _aguardandoIntervalo.clear();
      _diaProcessado = hoje;
    }

    for (final turno in escala.turnosHoje) {
      if (turno.saida == null || turno.folga || turno.feriado) continue;
      if (_saidasProcessadas.contains(turno.colaboradorId)) continue;

      final partes = turno.saida!.split(':');
      final h = int.tryParse(partes[0]) ?? -1;
      final m = int.tryParse(partes.length > 1 ? partes[1] : '') ?? -1;
      if (h < 0 || m < 0) continue;

      final saidaHoje = DateTime(agora.year, agora.month, agora.day, h, m);
      if (!agora.isAfter(saidaHoje)) continue;

      final alocacaoAtiva =
          getAlocacaoColaborador(turno.colaboradorId);
      if (alocacaoAtiva == null) continue;

      _saidasProcessadas.add(turno.colaboradorId);
      liberarAlocacao(
        alocacaoAtiva.id,
        'Encerramento automático — horário de saída atingido (${turno.saida})',
      );

      final notifId = turno.colaboradorId.hashCode.abs() % 100000;
      NotificationService.instance.showImmediateAlert(
        id: notifId,
        title: 'Saída automática',
        body:
            '${turno.colaboradorNome} foi liberado(a) do caixa automaticamente.',
      );
    }
  }

  Future<void> marcarIntervaloFeito(String colaboradorId) async {
    _intervalosMarcados.add(colaboradorId);
    notifyListeners();
    // Persiste no Supabase: encontra a alocação ativa do colaborador
    final alocacao = getAlocacaoColaborador(colaboradorId);
    if (alocacao != null) {
      try {
        await repository.marcarIntervaloFeito(alocacao.id);
      } catch (_) {
        // Falha silenciosa — estado local já foi atualizado
      }
    }
  }

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
      // Restaura _intervalosMarcados a partir dos dados carregados
      _intervalosMarcados.addAll(
        _alocacoes
            .where((a) => a.intervaloMarcadoFeito && a.liberadoEm == null)
            .map((a) => a.colaboradorId),
      );
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
        if (result.alocacao != null) {
          _alocacoes.add(result.alocacao!);
        }
        _loadingState = LoadingState.success;
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
      final liberada = _alocacoes.firstWhere((a) => a.id == alocacaoId,
          orElse: () => _alocacoes.first);
      _aguardandoIntervalo.remove(liberada.colaboradorId);
      _alocacoes.removeWhere((a) => a.id == alocacaoId);
      _loadingState = LoadingState.success;
    } catch (e) {
      _error = 'Erro ao liberar: $e';
      _loadingState = LoadingState.error;
    }
    notifyListeners();
  }

  /// Retorna colaborador ao mesmo caixa após pausa de café (quando possível).
  /// Retorna null em sucesso, ou uma mensagem de erro em falha.
  Future<String?> retornarDeCafe({
    required String colaboradorId,
    required String caixaId,
    required String fiscalId,
  }) async {
    if (getAlocacaoColaborador(colaboradorId) != null) {
      return 'Colaborador já está alocado em outro caixa';
    }
    if (getAlocacaoCaixa(caixaId) != null) {
      return 'Caixa já está ocupado';
    }

    await alocarColaborador(
      colaboradorId: colaboradorId,
      caixaId: caixaId,
      fiscalId: fiscalId,
      justificativa: 'Retorno de café',
    );

    if (_loadingState == LoadingState.success) return null;
    return _error ?? 'Não foi possível retornar ao caixa';
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

  /// Retorna todas as alocações ativas de um caixa/balcão
  List<Alocacao> getAlocacoesCaixa(String caixaId) {
    return _alocacoes
        .where((a) => a.caixaId == caixaId && a.liberadoEm == null)
        .toList();
  }

  /// Busca todas as alocações ativas de um período
  List<Alocacao> getAlocacoesAtivas() {
    return _alocacoes.where((a) => a.liberadoEm == null).toList();
  }

  /// Busca todas as alocações liberadas
  List<Alocacao> getAlocacoesLiberadas() {
    return _alocacoes.where((a) => a.liberadoEm != null).toList();
  }

  @override
  void dispose() {
    _timerSaidas?.cancel();
    super.dispose();
  }
}
