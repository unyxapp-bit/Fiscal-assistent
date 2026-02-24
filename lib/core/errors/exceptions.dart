class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Erro no servidor']);

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Erro no cache local']);

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Erro de conexão']);

  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = 'Erro de autenticação']);

  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  ValidationException([this.message = 'Erro de validação']);

  @override
  String toString() => message;
}
