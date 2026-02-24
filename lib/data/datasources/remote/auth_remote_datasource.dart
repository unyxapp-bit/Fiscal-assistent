import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/exceptions.dart' as app_exceptions;
import 'supabase_client.dart';

class AuthRemoteDataSource {
  final SupabaseClient _client = SupabaseClientManager.client;

  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw app_exceptions.ServerException('Erro ao fazer login');
      }

      return response.user!;
    } on AuthException catch (e) {
      throw app_exceptions.ServerException(_getAuthErrorMessage(e));
    } catch (e) {
      throw app_exceptions.ServerException('Erro inesperado ao fazer login: $e');
    }
  }

  Future<User> signUpWithEmail({
    required String email,
    required String password,
    required String nome,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'nome': nome,
        },
      );

      if (response.user == null) {
        throw app_exceptions.ServerException('Erro ao criar conta');
      }

      return response.user!;
    } on AuthException catch (e) {
      throw app_exceptions.ServerException(_getAuthErrorMessage(e));
    } catch (e) {
      throw app_exceptions.ServerException('Erro inesperado ao criar conta: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw app_exceptions.ServerException(_getAuthErrorMessage(e));
    } catch (e) {
      throw app_exceptions.ServerException('Erro ao fazer logout: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw app_exceptions.ServerException(_getAuthErrorMessage(e));
    } catch (e) {
      throw app_exceptions.ServerException(
        'Erro ao enviar email de recuperacao: $e',
      );
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw app_exceptions.ServerException(_getAuthErrorMessage(e));
    } catch (e) {
      throw app_exceptions.ServerException('Erro ao atualizar senha: $e');
    }
  }

  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  Session? getCurrentSession() {
    return _client.auth.currentSession;
  }

  bool get hasSession => _client.auth.currentSession != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  String _getAuthErrorMessage(AuthException e) {
    // Debug: mostra o erro completo
    if (kDebugMode) {
      print('[AuthError] Status: ${e.statusCode}, Message: ${e.message}');
    }

    // Verifica se é erro de API key inválida
    if (e.message.toLowerCase().contains('invalid api key') ||
        e.message.toLowerCase().contains('invalid_api_key')) {
      return 'Chave de API invalida. Verifique as configuracoes do Supabase no arquivo .env';
    }

    switch (e.statusCode) {
      case '400':
        if (e.message.contains('Invalid login credentials')) {
          return 'Email ou senha incorretos';
        }
        if (e.message.contains('User already registered')) {
          return 'Este email ja esta cadastrado';
        }
        if (e.message.contains('Email not confirmed')) {
          return 'Email nao confirmado. Verifique sua caixa de entrada';
        }
        return 'Dados invalidos: ${e.message}';
      case '422':
        if (e.message.contains('Password')) {
          return 'A senha deve ter no minimo 6 caracteres';
        }
        if (e.message.contains('Email')) {
          return 'Email invalido';
        }
        return 'Dados invalidos: ${e.message}';
      case '429':
        return 'Muitas tentativas. Aguarde alguns minutos';
      case '500':
        return 'Erro no servidor. Tente novamente mais tarde';
      default:
        return e.message;
    }
  }
}
