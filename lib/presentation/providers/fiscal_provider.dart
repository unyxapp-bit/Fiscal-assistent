import 'package:flutter/foundation.dart';
import '../../domain/entities/fiscal.dart';
import '../../domain/usecases/fiscal/get_fiscal_profile.dart';
import '../../domain/usecases/fiscal/update_fiscal_profile.dart';

/// Estado do FiscalProvider
enum FiscalStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Provider para gerenciar estado do Fiscal
class FiscalProvider with ChangeNotifier {
  final GetFiscalProfile _getFiscalProfile;
  final UpdateFiscalProfile _updateFiscalProfile;

  FiscalStatus _status = FiscalStatus.initial;
  Fiscal? _fiscal;
  String? _errorMessage;

  // Getters
  FiscalStatus get status => _status;
  Fiscal? get fiscal => _fiscal;
  String? get errorMessage => _errorMessage;
  bool get hasProfile => _fiscal != null;
  bool get isLoading => _status == FiscalStatus.loading;

  FiscalProvider({
    required GetFiscalProfile getFiscalProfile,
    required UpdateFiscalProfile updateFiscalProfile,
  })  : _getFiscalProfile = getFiscalProfile,
        _updateFiscalProfile = updateFiscalProfile;

  /// Carrega perfil do fiscal
  Future<void> loadProfile(String userId) async {
    try {
      if (kDebugMode) {
        print('[FiscalProvider] Iniciando loadProfile para userId: $userId');
      }
      _status = FiscalStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _fiscal = await _getFiscalProfile.call(userId);
      
      if (kDebugMode) {
        print('[FiscalProvider] Fiscal carregado: ${_fiscal?.id}');
      }

      _status = FiscalStatus.loaded;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('[FiscalProvider] Erro ao carregar: $e');
      }
      _status = FiscalStatus.error;
      _errorMessage = 'Erro ao carregar perfil: $e';
      notifyListeners();
    }
  }

  /// Observa mudanças no perfil em tempo real
  void watchProfile(String userId) {
    _getFiscalProfile.watch(userId).listen(
      (fiscal) {
        _fiscal = fiscal;
        _status = FiscalStatus.loaded;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _status = FiscalStatus.error;
        _errorMessage = 'Erro ao observar perfil: $error';
        notifyListeners();
      },
    );
  }

  /// Atualiza perfil do fiscal
  Future<bool> updateProfile(Fiscal fiscal) async {
    try {
      _status = FiscalStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _fiscal = await _updateFiscalProfile.call(fiscal);

      _status = FiscalStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _status = FiscalStatus.error;
      _errorMessage = 'Erro ao atualizar perfil: $e';
      notifyListeners();
      return false;
    }
  }

  /// Limpa erro
  void clearError() {
    _errorMessage = null;
    if (_status == FiscalStatus.error) {
      _status = _fiscal != null ? FiscalStatus.loaded : FiscalStatus.initial;
    }
    notifyListeners();
  }

  /// Limpa estado
  void clear() {
    _status = FiscalStatus.initial;
    _fiscal = null;
    _errorMessage = null;
    notifyListeners();
  }
}
