import 'package:flutter/foundation.dart';
import '../../data/repositories/pacote_plantao_repository.dart';
import '../../domain/entities/pacote_plantao.dart';

/// Provider para gerenciar o plantão de empacotadores do dia
class PacotePlantaoProvider with ChangeNotifier {
  final PacotePlantaoRepository _repository;

  List<PacotePlantao> _plantao = [];
  bool _isLoading = false;
  String? _error;

  PacotePlantaoProvider({required PacotePlantaoRepository repository})
      : _repository = repository;

  List<PacotePlantao> get plantao => _plantao;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get total => _plantao.length;

  bool isNaLista(String colaboradorId) =>
      _plantao.any((p) => p.colaboradorId == colaboradorId);

  /// Carrega o plantão de hoje
  Future<void> load(String fiscalId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _plantao = await _repository.getPlantaoHoje(fiscalId);
    } catch (e) {
      _error = 'Erro ao carregar plantão: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Adiciona empacotador ao plantão
  Future<void> adicionar(String fiscalId, String colaboradorId) async {
    try {
      final novo = await _repository.addPlantao(fiscalId, colaboradorId);
      _plantao.add(novo);
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao adicionar: $e';
      notifyListeners();
    }
  }

  /// Remove empacotador do plantão
  Future<void> remover(String plantaoId) async {
    try {
      await _repository.removePlantao(plantaoId);
      _plantao.removeWhere((p) => p.id == plantaoId);
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao remover: $e';
      notifyListeners();
    }
  }
}
