import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../core/errors/exceptions.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider with ChangeNotifier {
  final AuthRemoteDataSource _authDataSource = AuthRemoteDataSource();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final currentUser = _authDataSource.getCurrentUser();

    if (currentUser != null) {
      _user = currentUser;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();

    _authDataSource.authStateChanges.listen(
      (AuthState state) {
        if (state.event == AuthChangeEvent.signedIn) {
          _user = state.session?.user;
          _status = AuthStatus.authenticated;
          _errorMessage = null;
        } else if (state.event == AuthChangeEvent.signedOut) {
          _user = null;
          _status = AuthStatus.unauthenticated;
          _errorMessage = null;
        }
        notifyListeners();
      },
      onError: (e) {
        // Erros de reconexão WebSocket do Supabase — não críticos
        if (kDebugMode) {
          print('[AuthProvider] WebSocket reconnect: $e');
        }
      },
    );
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _user = await _authDataSource.signInWithEmail(
        email: email.trim(),
        password: password,
      );

      if (kDebugMode) {
        print('[AuthProvider] Login realizado. userId: ${_user?.id}');
      }
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ServerException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _mensagemErro(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String nome,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _user = await _authDataSource.signUpWithEmail(
        email: email.trim(),
        password: password,
        nome: nome.trim(),
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ServerException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _mensagemErro(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      await _authDataSource.signOut();

      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erro ao fazer logout';
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _authDataSource.resetPassword(email.trim());

      _status =
          _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on ServerException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erro ao enviar email';
      notifyListeners();
      return false;
    }
  }

  String _mensagemErro(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') ||
        s.contains('Failed host lookup') ||
        s.contains('NetworkException') ||
        s.contains('Connection refused')) {
      return 'Servidor indisponível. Verifique sua conexão e tente novamente.';
    }
    return 'Erro inesperado. Tente novamente.';
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status =
          _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
