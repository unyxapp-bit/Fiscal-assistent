import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../datasources/remote/supabase_client.dart';

class WhatsAppNotificationService {
  WhatsAppNotificationService._();

  static const List<String> _whatsappPackages = [
    'com.whatsapp',
    'com.whatsapp.w4b',
  ];

  static const List<String> _fontesDefault = [
    'balcão fiscal',
    'balcao fiscal',
    'pyetro filho',
  ];

  static const String _prefKey = 'whatsapp_fontes_aceitas';
  static const Duration _edgeTimeout = Duration(seconds: 35);

  static List<String> _fontesAceitas = List.of(_fontesDefault);
  static StreamSubscription<ServiceNotificationEvent>? _subscription;
  static bool _initializing = false;
  static final Map<String, DateTime> _recentMessages = {};

  static bool debugMode = false;
  static int receivedTotal = 0;
  static String lastReceived = '';

  static List<String> get fontesAceitas => List.unmodifiable(_fontesAceitas);
  static bool get isListening => _subscription != null;

  static Future<void> _carregarFontes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final salvas = prefs.getStringList(_prefKey);
      if (salvas != null && salvas.isNotEmpty) {
        _fontesAceitas = salvas;
      }
    } catch (_) {}
  }

  static Future<void> salvarFontes(List<String> fontes) async {
    _fontesAceitas = fontes.map((f) => f.toLowerCase().trim()).toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, _fontesAceitas);
    } catch (_) {}
  }

  static Future<void> resetarFontes() async {
    _fontesAceitas = List.of(_fontesDefault);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } catch (_) {}
  }

  static Future<void> init() async {
    if (_subscription != null || _initializing) return;
    _initializing = true;

    try {
      await _carregarFontes();
      final hasPermission =
          await NotificationListenerService.isPermissionGranted();
      if (kDebugMode) debugPrint('[WhatsApp] Permissao: $hasPermission');
      if (!hasPermission) return;

      _subscription = NotificationListenerService.notificationsStream.listen(
        _handleNotification,
        onError: _onError,
      );
      if (kDebugMode) debugPrint('[WhatsApp] Listener ativo.');
    } catch (e) {
      if (kDebugMode) debugPrint('[WhatsApp] Erro ao iniciar listener: $e');
    } finally {
      _initializing = false;
    }
  }

  static Future<void> reset() async {
    await _subscription?.cancel();
    _subscription = null;
    _initializing = false;
    await init();
  }

  static Future<bool> isPermissionGranted() async {
    try {
      return await NotificationListenerService.isPermissionGranted();
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await NotificationListenerService.requestPermission();
    } catch (e) {
      if (kDebugMode) debugPrint('[WhatsApp] Erro ao abrir configuracoes: $e');
    }
  }

  static Future<void> _handleNotification(
    ServiceNotificationEvent event,
  ) async {
    receivedTotal++;
    lastReceived = '${event.packageName} | ${event.title ?? ""}';

    if (debugMode) {
      await _salvarDebug(event);
      return;
    }

    if (!_whatsappPackages.contains(event.packageName)) return;

    final sourceTitle = event.title ?? '';
    final titulo = sourceTitle.toLowerCase();
    if (!_fontesAceitas.any((f) => titulo.contains(f))) return;

    final body = event.content ?? '';
    if (body.isEmpty || _isMensagemSistema(body)) return;

    String sender = '';
    String content = body;
    if (body.contains(': ')) {
      final idx = body.indexOf(': ');
      sender = body.substring(0, idx).trim();
      content = body.substring(idx + 2).trim();
    }

    if (_isDuplicate(sender, content)) return;

    final timestamp = DateTime.now().toIso8601String();
    if (kDebugMode) {
      debugPrint('[WhatsApp] Capturado - de: "$sender" | conteudo: "$content"');
    }

    try {
      if (_isAudio(content)) {
        await _salvarMidia(
          sender: sender,
          mediaType: 'audio',
          timestamp: timestamp,
          sourceTitle: sourceTitle,
          rawContent: body,
        );
      } else if (_isFoto(content)) {
        await _salvarMidia(
          sender: sender,
          mediaType: 'foto',
          timestamp: timestamp,
          sourceTitle: sourceTitle,
          rawContent: body,
        );
      } else {
        await _enviarParaEdgeFunction(
          sender: sender,
          message: content,
          timestamp: timestamp,
          sourceTitle: sourceTitle,
          rawContent: body,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[WhatsApp] Erro ao processar: $e');
      await _salvarErro(content: content, sender: sender, error: e.toString());
    }
  }

  static bool _isAudio(String body) {
    final lower = body.toLowerCase();
    return lower.contains('ptt-') ||
        lower.contains('aud-') ||
        lower.contains('.opus') ||
        lower.contains('mensagem de voz') ||
        lower.contains('audio') ||
        lower.contains('áudio') ||
        body.contains('🎤');
  }

  static bool _isFoto(String body) {
    final lower = body.toLowerCase();
    return lower.contains('img-') ||
        lower.contains('mídia oculta') ||
        lower.contains('midia oculta') ||
        lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp') ||
        lower.contains('foto') ||
        lower.contains('imagem') ||
        body.contains('📷');
  }

  static bool _isMensagemSistema(String body) {
    const frases = [
      'Mensagem apagada',
      'Mensagem editada',
      'adicionou você',
      'adicionou voce',
      'STK-',
      '.webp',
      'criou o grupo',
      'saiu',
      'Figurinha',
      'reagiu com',
      'nova mensagem',
      'novas mensagens',
      'mensagem não lida',
      'mensagem nao lida',
      'mensagens não lidas',
      'mensagens nao lidas',
      'mensagem não vista',
      'mensagem nao vista',
      'mensagens não vistas',
      'mensagens nao vistas',
      'Chamada perdida',
      'Chamada de vídeo perdida',
      'Chamada de video perdida',
    ];
    if (frases.any((p) => body.contains(p))) return true;
    return RegExp(r'^\d+\s+mensagens?', caseSensitive: false).hasMatch(body);
  }

  static bool _isDuplicate(String sender, String content) {
    final key = '${sender.toLowerCase()}|${content.toLowerCase()}';
    final now = DateTime.now();
    _recentMessages.removeWhere(
      (_, value) => now.difference(value).inSeconds > 30,
    );
    final last = _recentMessages[key];
    if (last != null && now.difference(last).inSeconds < 15) {
      if (kDebugMode) debugPrint('[WhatsApp] Duplicata ignorada: $key');
      return true;
    }
    _recentMessages[key] = now;
    return false;
  }

  static Future<void> _enviarParaEdgeFunction({
    required String sender,
    required String message,
    required String timestamp,
    required String sourceTitle,
    required String rawContent,
  }) async {
    await Supabase.instance.client.functions.invoke(
      'analyze-fiscal-message',
      headers: SupabaseClientManager.edgeFunctionHeaders,
      body: {
        'fiscal_id': SupabaseClientManager.currentUserId,
        'source': 'whatsapp_notification',
        'source_app': 'whatsapp',
        'source_title': sourceTitle,
        'raw_title': sourceTitle,
        'raw_content': rawContent,
        'sender': sender,
        'message': message,
        'timestamp': timestamp,
      },
    ).timeout(_edgeTimeout);
  }

  static Future<void> _salvarMidia({
    required String sender,
    required String mediaType,
    required String timestamp,
    required String sourceTitle,
    required String rawContent,
  }) async {
    final emoji = mediaType == 'audio' ? '🎤' : '📷';
    final nome = sender.isNotEmpty ? sender : 'Alguem';
    try {
      await Supabase.instance.client.functions.invoke(
        'analyze-fiscal-message',
        headers: SupabaseClientManager.edgeFunctionHeaders,
        body: {
          'fiscal_id': SupabaseClientManager.currentUserId,
          'source': 'whatsapp_notification',
          'source_app': 'whatsapp',
          'source_title': sourceTitle,
          'raw_title': sourceTitle,
          'raw_content': rawContent,
          'sender': sender,
          'message': '$emoji $mediaType recebido de $nome',
          'timestamp': timestamp,
          'media_type': mediaType,
        },
      ).timeout(_edgeTimeout);
      if (kDebugMode) debugPrint('[WhatsApp] Midia enviada: $mediaType');
      return;
    } catch (e) {
      if (kDebugMode) debugPrint('[WhatsApp] Edge falhou para midia: $e');
    }

    await Supabase.instance.client.from('fiscal_events').insert({
      'fiscal_id': SupabaseClientManager.currentUserId,
      'category': 'midia_pendente',
      'description': '$emoji $mediaType recebido de $nome - anexar arquivo',
      'source_title': sourceTitle,
      'raw_title': sourceTitle,
      'raw_content': rawContent,
      'sender': sender.isNotEmpty ? sender : null,
      'raw_message': '$emoji $mediaType',
      'event_date': timestamp,
      'status': 'pending',
      'confidence': 1.0,
      'media_type': mediaType,
      'needs_review': true,
      'analysis_status': 'needs_file',
    });
  }

  static Future<void> _salvarDebug(ServiceNotificationEvent event) async {
    try {
      await Supabase.instance.client.from('fiscal_events').insert({
        'fiscal_id': SupabaseClientManager.currentUserId,
        'category': 'aviso_geral',
        'description': '[DIAGNOSTICO]\n'
            'App: ${event.packageName}\n'
            'Titulo: ${event.title}\n'
            'Conteudo: ${event.content}',
        'raw_message': '${event.title}: ${event.content}',
        'raw_title': event.title,
        'raw_content': event.content,
        'sender': event.packageName,
        'event_date': DateTime.now().toIso8601String(),
        'status': 'pending',
        'confidence': 0.1,
        'needs_review': true,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[WhatsApp] Erro ao salvar debug: $e');
    }
  }

  static Future<void> _salvarErro({
    required String content,
    required String sender,
    required String error,
  }) async {
    try {
      await Supabase.instance.client.from('fiscal_events').insert({
        'fiscal_id': SupabaseClientManager.currentUserId,
        'category': 'aviso_geral',
        'description':
            '[ERRO ao processar]\nRemetente: "$sender"\nErro: $error',
        'raw_message': content,
        'raw_content': content,
        'sender': sender.isNotEmpty ? sender : null,
        'event_date': DateTime.now().toIso8601String(),
        'status': 'pending',
        'confidence': 0.1,
        'needs_review': true,
      });
    } catch (_) {}
  }

  static void _onError(Object error) {
    if (kDebugMode) debugPrint('[WhatsApp] Erro no stream: $error');
    _subscription = null;
    _initializing = false;
    Future.delayed(const Duration(seconds: 5), init);
  }
}
