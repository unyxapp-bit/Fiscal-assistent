import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseClientManager {
  static SupabaseClient? _instance;

  static Future<void> initialize() async {
    // Tenta carregar do .env, com fallback para valores hardcoded
    final url = dotenv.env['SUPABASE_URL'] ?? 'https://rpbqquxnnpsiyredhkvv.supabase.co';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'sb_publishable_ysgHVMVFL_9LA1kEGa1FGQ_HlHIn3dV';

    if (url.isEmpty) {
      throw Exception('SUPABASE_URL não configurada');
    }

    if (anonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY não configurada');
    }

    // Debug: mostra se as chaves foram carregadas (apenas primeiros/últimos caracteres)
    if (dotenv.env['ENVIRONMENT'] == 'development') {
      debugPrint('[Supabase] URL carregada: ${url.substring(0, 30)}...');
      debugPrint('[Supabase] Key carregada: ${anonKey.substring(0, 20)}...${anonKey.substring(anonKey.length - 10)}');
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: dotenv.env['ENVIRONMENT'] == 'development',
    );

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

  static bool get hasSession => instance.auth.currentSession != null;

  static User? get currentUser => instance.auth.currentUser;

  static String? get currentUserId => instance.auth.currentUser?.id;

  static Stream<AuthState> get authStateChanges =>
      instance.auth.onAuthStateChange;
}
