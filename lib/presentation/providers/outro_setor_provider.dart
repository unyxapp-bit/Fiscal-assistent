import 'package:flutter/foundation.dart';
import '../../data/repositories/outro_setor_repository.dart';
import '../../domain/entities/outro_setor.dart';

/// Provider para gerenciar colaboradores em outro setor no dia
class OutroSetorProvider with ChangeNotifier {
  final OutroSetorRepository _repository;

  List<OutroSetor> _lista = [];
  bool _isLoading = false;
  String? _error;

  OutroSetorProvider({required OutroSetorRepository repository})
      : _repository = repository;

  List<OutroSetor> get lista => _lista;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get total => _lista.length;

  bool isNaLista(String colaboradorId) =>
      _lista.any((o) => o.colaboradorId == colaboradorId);

  OutroSetor? getByColaborador(String colaboradorId) {
    try {
      return _lista.firstWhere((o) => o.colaboradorId == colaboradorId);
    } catch (_) {
      return null;
    }
  }

  Future<void> load(String fiscalId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lista = await _repository.getHoje(fiscalId);
    } catch (e) {
      _error = 'Erro ao carregar outro setor: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> adicionar(
    String fiscalId,
    String colaboradorId,
    String setor,
  ) async {
    _error = null;
    try {
      final novo = await _repository.add(fiscalId, colaboradorId, setor);
      _lista.add(novo);
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao registrar: $e';
      notifyListeners();
    }
  }

  Future<void> remover(String id) async {
    _error = null;
    try {
      await _repository.remove(id);
      _lista.removeWhere((o) => o.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao remover: $e';
      notifyListeners();
    }
  }
}
