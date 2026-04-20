import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Captura notificações do WhatsApp do grupo "Balcão Fiscal" e envia
/// ao Supabase para categorização e registro.
///
/// Texto  → Edge Function (regras + Claude Haiku categoriza)
/// Áudio  → salvo direto como midia_pendente
/// Foto   → salvo direto como midia_pendente
class WhatsAppNotificationService {
  WhatsAppNotificationService._();

  // Nome exato do grupo (case-sensitive) — ajuste se necessário
  static const String nomeGrupo = 'Balcão Fiscal';

  // Aceita WhatsApp e WhatsApp Business
  static const List<String> _whatsappPackages = [
    'com.whatsapp',
    'com.whatsapp.w4b',
  ];

  static bool _iniciado = false;

  /// Inicializa o listener. Chame em main() antes do runApp.
  /// Solicita permissão automaticamente se não concedida.
  static Future<void> init() async {
    if (_iniciado) return;
    _iniciado = true;

    try {
      final hasPermission =
          await NotificationListenerService.isPermissionGranted();
      if (!hasPermission) {
        await NotificationListenerService.requestPermission();
      }
      NotificationListenerService.notificationsStream
          .listen(_handleNotification, onError: _onError);

      if (kDebugMode) {
        debugPrint('[WhatsApp] Listener iniciado. Permissão: $hasPermission');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[WhatsApp] Erro ao iniciar listener: $e');
    }
  }

  /// Verifica se a permissão de leitura de notificações foi concedida.
  static Future<bool> isPermissionGranted() async {
    try {
      return await NotificationListenerService.isPermissionGranted();
    } catch (_) {
      return false;
    }
  }

  /// Abre a tela de configurações para o usuário conceder a permissão.
  static Future<void> requestPermission() async {
    await NotificationListenerService.requestPermission();
  }

  // ── Handler principal ──────────────────────────────────────────────────────

  static Future<void> _handleNotification(
      ServiceNotificationEvent event) async {
    // Filtra apenas WhatsApp e WhatsApp Business
    if (!_whatsappPackages.contains(event.packageName)) return;

    // Filtra pelo grupo
    final titulo = event.title ?? '';
    if (!titulo.contains(nomeGrupo)) return;

    final body = event.content ?? '';
    if (body.isEmpty) return;

    // Ignora mensagens do sistema
    if (_isMensagemSistema(body)) return;

    // Extrai remetente e conteúdo
    String sender = '';
    String content = body;
    if (body.contains(': ')) {
      final idx = body.indexOf(': ');
      sender = body.substring(0, idx).trim();
      content = body.substring(idx + 2).trim();
    }

    final timestamp = DateTime.now().toIso8601String();

    if (kDebugMode) {
      debugPrint('[WhatsApp] Capturado — de: "$sender" | conteúdo: "$content"');
    }

    if (_isAudio(content)) {
      await _salvarMidia(
          sender: sender, mediaType: 'audio', timestamp: timestamp);
    } else if (_isFoto(content)) {
      await _salvarMidia(
          sender: sender, mediaType: 'foto', timestamp: timestamp);
    } else {
      await _enviarParaEdgeFunction(
          sender: sender, message: content, timestamp: timestamp);
    }
  }

  // ── Detectores ────────────────────────────────────────────────────────────

  static bool _isAudio(String b) =>
      b.contains('PTT-') ||
      b.contains('AUD-') ||
      b.contains('.opus') ||
      b.contains('🎤') ||
      b.contains('Mensagem de voz') ||
      b.contains('áudio');

  static bool _isFoto(String b) =>
      b.contains('IMG-') ||
      b.contains('Mídia oculta') ||
      b.contains('.jpg') ||
      b.contains('.png') ||
      b.contains('Foto') ||
      b.contains('Imagem') ||
      b.contains('📷');

  static bool _isMensagemSistema(String b) =>
      ['Mensagem apagada', 'Mensagem editada', 'adicionou você',
       'STK-', '.webp', 'criou o grupo', 'saiu', 'Figurinha',
       '🔴', 'reagiu com'].any((p) => b.contains(p));

  // ── Envios ────────────────────────────────────────────────────────────────

  static Future<void> _enviarParaEdgeFunction({
    required String sender,
    required String message,
    required String timestamp,
  }) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'analyze-fiscal-message',
        body: {
          'sender': sender,
          'message': message,
          'timestamp': timestamp,
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[WhatsApp] Erro ao enviar texto: $e');
    }
  }

  static Future<void> _salvarMidia({
    required String sender,
    required String mediaType,
    required String timestamp,
  }) async {
    try {
      final emoji = mediaType == 'audio' ? '🎤' : '📷';
      final nome = sender.isNotEmpty ? sender : 'Alguém';
      await Supabase.instance.client.from('fiscal_events').insert({
        'category': 'midia_pendente',
        'description': '$emoji $mediaType recebido de $nome — preencher após ouvir/ver',
        'sender': sender.isNotEmpty ? sender : null,
        'raw_message': '$emoji $mediaType',
        'event_date': timestamp,
        'status': 'pending',
        'confidence': 1.0,
        'media_type': mediaType,
        'needs_review': true,
      });
      if (kDebugMode) debugPrint('[WhatsApp] Mídia salva: $mediaType de $nome');
    } catch (e) {
      if (kDebugMode) debugPrint('[WhatsApp] Erro ao salvar mídia: $e');
    }
  }

  static void _onError(Object e) {
    if (kDebugMode) debugPrint('[WhatsApp] Erro no stream: $e');
  }
}
