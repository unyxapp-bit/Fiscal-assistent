import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseClientManager {
  static SupabaseClient? _instance;
  static String? _anonKey;

  static Future<void> initialize() async {
    // Tenta carregar do .env, com fallback para valores hardcoded
    final url = dotenv.env['SUPABASE_URL'] ??
        'https://rpbqquxnnpsiyredhkvv.supabase.co';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwYnFxdXhubnBzaXlyZWRoa3Z2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA3MTg4MDUsImV4cCI6MjA4NjI5NDgwNX0.0Ncc96n5mHY_DmsvTrjKveHPL4DB34m1GqKTwl6-VO8';

    if (url.isEmpty) {
      throw Exception('SUPABASE_URL não configurada');
    }

    if (anonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY não configurada');
    }

    // Debug: mostra se as chaves foram carregadas (apenas primeiros/últimos caracteres)
    if (dotenv.env['ENVIRONMENT'] == 'development') {
      debugPrint('[Supabase] URL carregada: ${url.substring(0, 30)}...');
      debugPrint(
          '[Supabase] Key carregada: ${anonKey.substring(0, 20)}...${anonKey.substring(anonKey.length - 10)}');
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: dotenv.env['ENVIRONMENT'] == 'development',
    );

    _anonKey = anonKey;
    _instance = Supabase.instance.client;
    if (kDebugMode) {
      debugPrint('[Supabase] Cliente inicializado com sucesso!');
    }
  }

  static SupabaseClient get instance {
    if (_instance == null) {
      throw Exception(
        'Supabase não foi inicializado. Chame SupabaseClientManager.initialize() primeiro.',
      );
    }
    return _instance!;
  }

  static SupabaseClient get client => instance;

  static String get anonKey {
    final value = _anonKey;
    if (value == null || value.isEmpty) {
      throw Exception(
        'Anon key do Supabase n\u00e3o foi inicializada. Chame SupabaseClientManager.initialize() primeiro.',
      );
    }
    return value;
  }

  /// For\u00e7a Edge Functions a usarem o JWT anon compat\u00edvel, sem reaproveitar
  /// o token da sess\u00e3o do usu\u00e1rio quando ele estiver em um algoritmo n\u00e3o suportado.
  static Map<String, String> get edgeFunctionHeaders => {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
      };

  static bool get hasSession => instance.auth.currentSession != null;

  static User? get currentUser => instance.auth.currentUser;

  static String? get currentUserId => instance.auth.currentUser?.id;

  static Stream<AuthState> get authStateChanges =>
      instance.auth.onAuthStateChange;
}
