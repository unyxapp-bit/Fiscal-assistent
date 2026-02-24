import 'package:flutter/foundation.dart';
import '../../domain/entities/registro_ponto.dart';
import '../../domain/usecases/registro_ponto/get_registros_ponto.dart';
import '../../data/repositories/registro_ponto_repository.dart';

/// Provider para gerenciar registros de ponto de um colaborador
class RegistroPontoProvider with ChangeNotifier {
  final GetRegistrosPonto _getRegistrosPonto;
  final RegistroPontoRepository _repository;

  bool _isLoading = false;
  List<RegistroPonto> _registros = [];
  String? _currentColaboradorId;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<RegistroPonto> get registros => _registros;
  String? get errorMessage => _errorMessage;
  String? get currentColaboradorId => _currentColaboradorId;

  RegistroPontoProvider({
    required GetRegistrosPonto getRegistrosPonto,
    required RegistroPontoRepository repository,
  })  : _getRegistrosPonto = getRegistrosPonto,
        _repository = repository;

  /// Carrega todos os registros de ponto de um colaborador
  Future<void> loadRegistros(String colaboradorId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _registros = await _getRegistrosPonto.call(colaboradorId);
      _currentColaboradorId = colaboradorId;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('[RegistroPontoProvider] Erro ao carregar: $e');
      _isLoading = false;
      _errorMessage = 'Erro ao carregar registros: $e';
      notifyListeners();
    }
  }

  /// Cria novo registro de ponto
  Future<bool> createRegistroPonto({
    required String colaboradorId,
    required DateTime data,
    String? entrada,
    String? intervaloSaida,
    String? intervaloRetorno,
    String? saida,
    String? observacao,
  }) async {
    try {
      final novo = RegistroPonto(
        id: 'new', // Supabase gera o UUID real
        colaboradorId: colaboradorId,
        data: data,
        entrada: entrada,
        intervaloSaida: intervaloSaida,
        intervaloRetorno: intervaloRetorno,
        saida: saida,
        observacao: observacao,
      );
      final criado = await _repository.createRegistroPonto(novo);
      _registros.add(criado);
      _registros.sort((a, b) => b.data.compareTo(a.data));
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('[RegistroPontoProvider] Erro ao criar: $e');
      _errorMessage = 'Erro ao criar registro: $e';
      notifyListeners();
      return false;
    }
  }

  /// Atualiza registro de ponto existente
  Future<bool> updateRegistroPonto(RegistroPonto registro) async {
    try {
      final atualizado = await _repository.updateRegistroPonto(registro);
      final index = _registros.indexWhere((r) => r.id == registro.id);
      if (index != -1) {
        _registros[index] = atualizado;
        _registros.sort((a, b) => b.data.compareTo(a.data));
      }
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('[RegistroPontoProvider] Erro ao atualizar: $e');
      _errorMessage = 'Erro ao atualizar registro: $e';
      notifyListeners();
      return false;
    }
  }

  /// Deleta registro de ponto
  Future<bool> deleteRegistroPonto(String id) async {
    try {
      await _repository.deleteRegistroPonto(id);
      _registros.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('[RegistroPontoProvider] Erro ao deletar: $e');
      _errorMessage = 'Erro ao deletar registro: $e';
      notifyListeners();
      return false;
    }
  }

  /// Limpa os registros carregados
  void clear() {
    _registros = [];
    _currentColaboradorId = null;
    notifyListeners();
  }
}
