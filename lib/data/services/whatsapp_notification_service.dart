import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../datasources/remote/supabase_client.dart';

/// Captura notificações do WhatsApp do grupo "Balcão Fiscal" e envia
/// ao Supabase para categorização e registro.
///
/// Texto  → Edge Function (regras + Claude Haiku categoriza)
/// Áudio  → salvo direto como midia_pendente
/// Foto   → salvo direto como midia_pendente
class WhatsAppNotificationService {
  WhatsAppNotificationService._();

  static const List<String> _whatsappPackages = [
    'com.whatsapp',
    'com.whatsapp.w4b',
  ];

  static const List<String> _fontesAceitas = [
    'balcão fiscal', // grupo principal
    'pyetro filho',  // contato de teste
  ];

  // ── Estado interno ─────────────────────────────────────────────────────────

  static StreamSubscription<ServiceNotificationEvent>? _subscription;

  /// Impede que duas chamadas simultâneas de init() criem subscriptions duplas.
  static bool _initializing = false;

  /// Cache de deduplicação: "sender|content" → último processamento.
  /// WhatsApp às vezes dispara duas notificações para a mesma mensagem
  /// (chegada + atualização de contador). Ignoramos repetições em 15s.
  static final Map<String, DateTime> _recentMessages = {};

  // ── Diagnóstico (visível mesmo em release) ─────────────────────────────────

  /// Quando true: aceita QUALQUER notificação (qualquer app) e salva no banco.
  /// Permite confirmar se o stream está funcionando independente de filtros.
  static bool debugMode = false;

  /// Total de notificações que chegaram ao handler ANTES de qualquer filtro.
  /// Se ficar em 0 após várias notificações, o stream não está funcionando.
  static int receivedTotal = 0;

  /// Última notificação recebida no formato "packageName | title".
  static String lastReceived = '';

  // ── Getters ────────────────────────────────────────────────────────────────

  static bool get isListening => _subscription != null;

  // ── Inicialização ──────────────────────────────────────────────────────────

  /// Inicializa o listener. Seguro chamar várias vezes — idempotente com
  /// proteção contra race condition via flag _initializing.
  static Future<void> init() async {
    if (_subscription != null || _initializing) return;
    _initializing = true;

    try {
      final hasPermission =
          await NotificationListenerService.isPermissionGranted();
      if (kDebugMode) debugPrint('[WhatsApp] Permissão: $hasPermission');

      if (!hasPermission) return;

      _subscription = NotificationListenerService.notificationsStream
          .listen(_handleNotification, onError: _onError);

      if (kDebugMode) debugPrint('[WhatsApp] Listener ativo.');
    } catch (e) {
      if (kDebugMode) debugPrint('[WhatsApp] Erro ao iniciar listener: $e');
    } finally {
      _initializing = false;
    }
  }

  /// Cancela o listener atual e reinicia. Use quando o app volta do background
  /// para garantir que o stream não morreu enquanto o app estava em pausa.
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
      if (kDebugMode) debugPrint('[WhatsApp] Erro ao abrir configurações: $e');
    }
  }

  // ── Handler principal ──────────────────────────────────────────────────────

  static Future<void> _handleNotification(
      ServiceNotificationEvent event) async {
    // Contadores de diagnóstico — atualizados ANTES de qualquer filtro
    receivedTotal++;
    lastReceived = '${event.packageName} | ${event.title ?? ""}';

    // ── Modo diagnóstico: salva TUDO no banco sem filtrar ──────────────────
    if (debugMode) {
      await _salvarDebug(event);
      return;
    }

    // ── Filtro 1: apenas WhatsApp ──────────────────────────────────────────
    if (!_whatsappPackages.contains(event.packageName)) return;

    // ── Filtro 2: apenas fontes aceitas (grupo/contato) ───────────────────
    final titulo = (event.title ?? '').toLowerCase();
    if (!_fontesAceitas.any((f) => titulo.contains(f))) return;

    // ── Filtro 3: conteúdo não vazio ──────────────────────────────────────
    final body = event.content ?? '';
    if (body.isEmpty) return;

    // ── Filtro 4: ignora mensagens do sistema ─────────────────────────────
    if (_isMensagemSistema(body)) return;

    // ── Extrai remetente e conteúdo ───────────────────────────────────────
    String sender = '';
    String content = body;
    if (body.contains(': ')) {
      final idx = body.indexOf(': ');
      sender = body.substring(0, idx).trim();
      content = body.substring(idx + 2).trim();
    }

    // ── Filtro 5: deduplicação (mesmo conteúdo em 15 s) ──────────────────
    if (_isDuplicate(sender, content)) return;

    final timestamp = DateTime.now().toIso8601String();
    if (kDebugMode) {
      debugPrint('[WhatsApp] Capturado — de: "$sender" | conteúdo: "$content"');
    }

    // ── Roteamento ─────────────────────────────────────────────────────────
    try {
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
    } catch (e) {
      if (kDebugMode) debugPrint('[WhatsApp] Erro ao processar: $e');
      // Falhas de rede são salvas no banco para visibilidade (não ficam silenciosas)
      await _salvarErro(
          content: content, sender: sender, error: e.toString());
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

  static bool _isMensagemSistema(String b) {
    // Padrões de sistema e notificações de resumo do WhatsApp
    const frases = [
      'Mensagem apagada', 'Mensagem editada', 'adicionou você',
      'STK-', '.webp', 'criou o grupo', 'saiu', 'Figurinha',
      '🔴', 'reagiu com',
      // Resumos de grupo: "3 novas mensagens", "1 nova mensagem",
      // "5 mensagens não lidas" — sem remetente real, sem conteúdo útil
      'nova mensagem', 'novas mensagens',
      'mensagem não lida', 'mensagens não lidas',
      'mensagem não vista', 'mensagens não vistas',
      // Ligações perdidas
      'Chamada perdida', 'Chamada de vídeo perdida',
    ];
    if (frases.any((p) => b.contains(p))) return true;
    // "N mensagens" no início (ex: "12 mensagens")
    if (RegExp(r'^\d+\s+mensagens?', caseSensitive: false).hasMatch(b)) {
      return true;
    }
    return false;
  }

  /// Retorna true se a mesma mensagem (sender+content) chegou há menos de 15 s.
  /// Evita duplicatas causadas por WhatsApp atualizar o contador do grupo.
  static bool _isDuplicate(String sender, String content) {
    final key = '${sender.toLowerCase()}|${content.toLowerCase()}';
    final now = DateTime.now();
    // Limpa entradas antigas (> 30 s) para não crescer indefinidamente
    _recentMessages.removeWhere(
        (_, v) => now.difference(v).inSeconds > 30);
    final last = _recentMessages[key];
    if (last != null && now.difference(last).inSeconds < 15) {
      if (kDebugMode) {
        debugPrint('[WhatsApp] Duplicata ignorada — "$sender": "$content"');
      }
      return true;
    }
    _recentMessages[key] = now;
    return false;
  }

  // ── Envios ─────────────────────────────────────────────────────────────────

  static Future<void> _enviarParaEdgeFunction({
    required String sender,
    required String message,
    required String timestamp,
  }) async {
    await Supabase.instance.client.functions.invoke(
      'analyze-fiscal-message',
      headers: SupabaseClientManager.edgeFunctionHeaders,
      body: {
        'sender': sender,
        'message': message,
        'timestamp': timestamp,
      },
    );
  }

  static Future<void> _salvarMidia({
    required String sender,
    required String mediaType,
    required String timestamp,
  }) async {
    final emoji = mediaType == 'audio' ? '🎤' : '📷';
    final nome = sender.isNotEmpty ? sender : 'Alguém';
    await Supabase.instance.client.from('fiscal_events').insert({
      'category': 'midia_pendente',
      'description':
          '$emoji $mediaType recebido de $nome — preencher após ouvir/ver',
      'sender': sender.isNotEmpty ? sender : null,
      'raw_message': '$emoji $mediaType',
      'event_date': timestamp,
      'status': 'pending',
      'confidence': 1.0,
      'media_type': mediaType,
      'needs_review': true,
    });
    if (kDebugMode) debugPrint('[WhatsApp] Mídia salva: $mediaType de $nome');
  }

  /// Salva QUALQUER notificação no banco. Usado no modo diagnóstico.
  static Future<void> _salvarDebug(ServiceNotificationEvent event) async {
    try {
      await Supabase.instance.client.from('fiscal_events').insert({
        'category': 'aviso_geral',
        'description': '[DIAGNÓSTICO]\n'
            'App: ${event.packageName}\n'
            'Título: ${event.title}\n'
            'Conteúdo: ${event.content}',
        'raw_message': '${event.title}: ${event.content}',
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

  /// Salva erros de processamento no banco — falhas silenciosas viram visíveis.
  static Future<void> _salvarErro({
    required String content,
    required String sender,
    required String error,
  }) async {
    try {
      await Supabase.instance.client.from('fiscal_events').insert({
        'category': 'aviso_geral',
        'description':
            '[ERRO ao processar]\nRemetente: "$sender"\nErro: $error',
        'raw_message': content,
        'sender': sender.isNotEmpty ? sender : null,
        'event_date': DateTime.now().toIso8601String(),
        'status': 'pending',
        'confidence': 0.1,
        'needs_review': true,
      });
    } catch (_) {
      // Se nem o log de erro funcionar, não há mais o que fazer aqui
    }
  }

  // ── Tratamento de erro do stream ──────────────────────────────────────────

  static void _onError(Object e) {
    if (kDebugMode) debugPrint('[WhatsApp] Erro no stream: $e');
    // Se o stream morrer, descarta a subscription e agenda reinicialização
    _subscription = null;
    _initializing = false;
    Future.delayed(const Duration(seconds: 5), init);
  }
}
