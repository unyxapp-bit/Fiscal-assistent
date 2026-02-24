import 'package:flutter/foundation.dart';
import '../../domain/entities/colaborador.dart';
import '../../domain/enums/departamento_tipo.dart';
import '../../domain/usecases/colaborador/get_colaboradores.dart';
import '../../domain/usecases/colaborador/create_colaborador.dart';
import '../../domain/usecases/colaborador/update_colaborador.dart';
import '../../data/repositories/colaborador_repository.dart';

/// Estado do Provider
enum ColaboradorStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Provider para gerenciar colaboradores
class ColaboradorProvider with ChangeNotifier {
  final GetColaboradores _getColaboradores;
  final CreateColaborador _createColaborador;
  final UpdateColaborador _updateColaborador;
  final ColaboradorRepository _repository;

  ColaboradorStatus _status = ColaboradorStatus.initial;
  List<Colaborador> _colaboradores = [];
  List<Colaborador> _filteredColaboradores = [];
  String? _errorMessage;
  DepartamentoTipo? _filtroAtual;
  String _searchQuery = '';

  // Getters
  ColaboradorStatus get status => _status;
  List<Colaborador> get colaboradores => _filteredColaboradores;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ColaboradorStatus.loading;
  DepartamentoTipo? get filtroAtual => _filtroAtual;
  String get searchQuery => _searchQuery;

  // Contadores por departamento (baseados na lista completa, não filtrada)
  int get totalCaixa =>
      _colaboradores
          .where((c) => c.departamento == DepartamentoTipo.caixa && c.ativo)
          .length;

  int get totalFiscal =>
      _colaboradores
          .where((c) => c.departamento == DepartamentoTipo.fiscal && c.ativo)
          .length;

  int get totalPacote =>
      _colaboradores
          .where((c) => c.departamento == DepartamentoTipo.pacote && c.ativo)
          .length;

  int get totalSelf =>
      _colaboradores
          .where((c) => c.departamento == DepartamentoTipo.self && c.ativo)
          .length;

  int get totalAtivos => _colaboradores.where((c) => c.ativo).length;

  ColaboradorProvider({
    required GetColaboradores getColaboradores,
    required CreateColaborador createColaborador,
    required UpdateColaborador updateColaborador,
    required ColaboradorRepository repository,
  })  : _getColaboradores = getColaboradores,
        _createColaborador = createColaborador,
        _updateColaborador = updateColaborador,
        _repository = repository;

  /// Carrega colaboradores
  Future<void> loadColaboradores(String fiscalId) async {
    try {
      if (kDebugMode) {
        print('[ColaboradorProvider] Iniciando loadColaboradores para fiscalId: $fiscalId');
      }
      _status = ColaboradorStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _colaboradores = await _getColaboradores.call(fiscalId);
      if (kDebugMode) {
        print('[ColaboradorProvider] ${_colaboradores.length} colaboradores carregados');
      }
      _applyFilters();

      _status = ColaboradorStatus.loaded;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('[ColaboradorProvider] Erro ao carregar: $e');
      }
      _status = ColaboradorStatus.error;
      _errorMessage = 'Erro ao carregar colaboradores: $e';
      notifyListeners();
    }
  }

  /// Observa mudanças em tempo real
  void watchColaboradores(String fiscalId) {
    _getColaboradores.watch(fiscalId).listen(
      (colaboradores) {
        _colaboradores = colaboradores;
        _applyFilters();
        _status = ColaboradorStatus.loaded;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _status = ColaboradorStatus.error;
        _errorMessage = 'Erro ao observar colaboradores: $error';
        notifyListeners();
      },
    );
  }

  /// Cria colaborador
  Future<bool> createColaborador({
    required String fiscalId,
    required String nome,
    required DepartamentoTipo departamento,
    String? observacoes,
    bool ativo = true,
    String? cpf,
    String? telefone,
    String? cargo,
    DateTime? dataAdmissao,
  }) async {
    try {
      _status = ColaboradorStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _createColaborador.call(
        fiscalId: fiscalId,
        nome: nome,
        departamento: departamento,
        observacoes: observacoes,
        ativo: ativo,
        cpf: cpf,
        telefone: telefone,
        cargo: cargo,
        dataAdmissao: dataAdmissao,
      );

      // Recarregar lista
      await loadColaboradores(fiscalId);

      return true;
    } catch (e) {
      _status = ColaboradorStatus.error;
      _errorMessage = 'Erro ao criar colaborador: $e';
      notifyListeners();
      return false;
    }
  }

  /// Atualiza colaborador
  Future<bool> updateColaborador(Colaborador colaborador) async {
    try {
      _status = ColaboradorStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _updateColaborador.call(colaborador);

      // Atualizar na lista local
      final index = _colaboradores.indexWhere((c) => c.id == colaborador.id);
      if (index != -1) {
        _colaboradores[index] = colaborador;
        _applyFilters();
      }

      _status = ColaboradorStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _status = ColaboradorStatus.error;
      _errorMessage = 'Erro ao atualizar colaborador: $e';
      notifyListeners();
      return false;
    }
  }

  /// Deleta colaborador
  Future<bool> deleteColaborador(String id) async {
    try {
      _status = ColaboradorStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _repository.deleteColaborador(id);

      // Remover da lista local
      _colaboradores.removeWhere((c) => c.id == id);
      _applyFilters();

      _status = ColaboradorStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _status = ColaboradorStatus.error;
      _errorMessage = 'Erro ao deletar colaborador: $e';
      notifyListeners();
      return false;
    }
  }

  /// Aplica filtro por departamento
  void setFiltro(DepartamentoTipo? departamento) {
    _filtroAtual = departamento;
    _applyFilters();
    notifyListeners();
  }

  /// Busca por nome
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Aplica filtros
  void _applyFilters() {
    var result = _colaboradores.where((c) => c.ativo).toList();

    // Filtro por departamento
    if (_filtroAtual != null) {
      result = result.where((c) => c.departamento == _filtroAtual).toList();
    }

    // Filtro por busca
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result =
          result.where((c) => c.nome.toLowerCase().contains(query)).toList();
    }

    // Ordenar por nome
    result.sort((a, b) => a.nome.compareTo(b.nome));

    _filteredColaboradores = result;
  }

  /// Limpa filtros
  void clearFilters() {
    _filtroAtual = null;
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  /// Limpa erro
  void clearError() {
    _errorMessage = null;
    if (_status == ColaboradorStatus.error) {
      _status = _colaboradores.isNotEmpty
          ? ColaboradorStatus.loaded
          : ColaboradorStatus.initial;
    }
    notifyListeners();
  }
}
