import 'package:flutter/foundation.dart';
import '../../domain/entities/caixa.dart';
import '../../domain/enums/tipo_caixa.dart';
import '../../domain/usecases/caixa/get_caixas.dart';
import '../../domain/usecases/caixa/toggle_caixa_status.dart';
import '../../domain/usecases/caixa/toggle_caixa_manutencao.dart';
import '../../data/repositories/caixa_repository.dart';

/// Estado do Provider
enum CaixaStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Provider para gerenciar caixas
class CaixaProvider with ChangeNotifier {
  final GetCaixas _getCaixas;
  final ToggleCaixaStatus _toggleStatus;
  final ToggleCaixaManutencao _toggleManutencao;
  final CaixaRepository _caixaRepository;

  CaixaStatus _status = CaixaStatus.initial;
  List<Caixa> _caixas = [];
  List<Caixa> _filteredCaixas = [];
  String? _errorMessage;
  bool _mostrarApenasAtivos = false;

  // Getters
  CaixaStatus get status => _status;
  List<Caixa> get caixas => _filteredCaixas;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == CaixaStatus.loading;
  bool get mostrarApenasAtivos => _mostrarApenasAtivos;

  // Contadores
  int get totalCaixas => _caixas.length;
  int get totalAtivos => _caixas.where((c) => c.ativo && !c.emManutencao).length;
  int get totalEmManutencao => _caixas.where((c) => c.emManutencao).length;
  int get totalInativos => _caixas.where((c) => !c.ativo).length;

  // Contadores por tipo
  int get totalRapidos =>
      _caixas.where((c) => c.tipo == TipoCaixa.rapido && c.ativo).length;
  int get totalNormais =>
      _caixas.where((c) => c.tipo == TipoCaixa.normal && c.ativo).length;
  int get totalSelf =>
      _caixas.where((c) => c.tipo == TipoCaixa.self && c.ativo).length;

  // Caixas agrupados por tipo
  List<Caixa> get caixasRapidos =>
      _filteredCaixas.where((c) => c.tipo == TipoCaixa.rapido).toList();
  List<Caixa> get caixasNormais =>
      _filteredCaixas.where((c) => c.tipo == TipoCaixa.normal).toList();
  List<Caixa> get selfCheckouts =>
      _filteredCaixas.where((c) => c.tipo == TipoCaixa.self).toList();

  CaixaProvider({
    required GetCaixas getCaixas,
    required ToggleCaixaStatus toggleStatus,
    required ToggleCaixaManutencao toggleManutencao,
    required CaixaRepository caixaRepository,
  })  : _getCaixas = getCaixas,
        _toggleStatus = toggleStatus,
        _toggleManutencao = toggleManutencao,
        _caixaRepository = caixaRepository;

  /// Carrega caixas
  Future<void> loadCaixas(String fiscalId) async {
    try {
      _status = CaixaStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _caixas = await _getCaixas.call(fiscalId);
      _applyFilters();

      _status = CaixaStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = CaixaStatus.error;
      _errorMessage = 'Erro ao carregar caixas: $e';
      notifyListeners();
    }
  }

  /// Observa mudanças em tempo real
  void watchCaixas(String fiscalId) {
    _getCaixas.watch(fiscalId).listen(
      (caixas) {
        _caixas = caixas;
        _applyFilters();
        _status = CaixaStatus.loaded;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _status = CaixaStatus.error;
        _errorMessage = 'Erro ao observar caixas: $error';
        notifyListeners();
      },
    );
  }

  /// Toggle status de um caixa
  Future<bool> toggleStatus(String caixaId, bool novoStatus) async {
    try {
      _status = CaixaStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final caixaAtualizado = await _toggleStatus.call(caixaId, novoStatus);

      // Atualizar na lista local
      final index = _caixas.indexWhere((c) => c.id == caixaId);
      if (index != -1) {
        _caixas[index] = caixaAtualizado;
        _applyFilters();
      }

      _status = CaixaStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _status = CaixaStatus.error;
      _errorMessage = 'Erro ao atualizar status: $e';
      notifyListeners();
      return false;
    }
  }

  /// Toggle manutenção
  Future<bool> toggleManutencao(String caixaId, bool emManutencao) async {
    try {
      _status = CaixaStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final caixaAtualizado =
          await _toggleManutencao.call(caixaId, emManutencao);

      // Atualizar na lista local
      final index = _caixas.indexWhere((c) => c.id == caixaId);
      if (index != -1) {
        _caixas[index] = caixaAtualizado;
        _applyFilters();
      }

      _status = CaixaStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _status = CaixaStatus.error;
      _errorMessage = 'Erro ao atualizar manutenção: $e';
      notifyListeners();
      return false;
    }
  }

  /// Toggle filtro de apenas ativos
  void toggleFiltroAtivos() {
    _mostrarApenasAtivos = !_mostrarApenasAtivos;
    _applyFilters();
    notifyListeners();
  }

  /// Aplica filtros
  void _applyFilters() {
    _filteredCaixas = _caixas;

    if (_mostrarApenasAtivos) {
      _filteredCaixas =
          _filteredCaixas.where((c) => c.ativo && !c.emManutencao).toList();
    }

    // Ordenar por número
    _filteredCaixas.sort((a, b) => a.numero.compareTo(b.numero));
  }

  /// Insere ou atualiza um caixa no Supabase
  Future<void> upsertCaixa(Caixa caixa) async {
    try {
      _status = CaixaStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _caixaRepository.upsertCaixa(caixa);

      // Recarregar lista
      await loadCaixas(caixa.fiscalId);
    } catch (e) {
      _status = CaixaStatus.error;
      _errorMessage = 'Erro ao salvar caixa: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Limpa erro
  void clearError() {
    _errorMessage = null;
    if (_status == CaixaStatus.error) {
      _status =
          _caixas.isNotEmpty ? CaixaStatus.loaded : CaixaStatus.initial;
    }
    notifyListeners();
  }
}
