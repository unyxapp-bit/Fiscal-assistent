import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../datasources/remote/supabase_client.dart';

class MultimodalInboxResult {
  final bool success;
  final bool skipped;
  final String message;
  final Map<String, dynamic> payload;

  const MultimodalInboxResult({
    required this.success,
    required this.skipped,
    required this.message,
    this.payload = const {},
  });

  factory MultimodalInboxResult.fromPayload(Map<String, dynamic> payload) {
    final success = payload['success'] != false;
    final skipped = payload['skipped'] == true;
    final event = _asMap(payload['event']);
    final category = event['category']?.toString();
    final description = event['description']?.toString();

    return MultimodalInboxResult(
      success: success,
      skipped: skipped,
      message: skipped
          ? 'Conteudo sem acao fiscal.'
          : description?.isNotEmpty == true
              ? description!
              : category?.isNotEmpty == true
                  ? 'Evento $category criado.'
                  : 'Conteudo analisado pela IA.',
      payload: payload,
    );
  }

  factory MultimodalInboxResult.error(Object error) => MultimodalInboxResult(
        success: false,
        skipped: false,
        message: error.toString(),
      );
}

class SharedInboxItem {
  final String? text;
  final Uint8List? bytes;
  final String? fileName;
  final String? mimeType;
  final String? sourceApp;

  const SharedInboxItem({
    this.text,
    this.bytes,
    this.fileName,
    this.mimeType,
    this.sourceApp,
  });

  bool get hasFile => bytes != null && bytes!.isNotEmpty;
  bool get hasText => text?.trim().isNotEmpty == true;
}

class MultimodalInboxService {
  static const _bucket = 'fiscal-media';
  static const _channel =
      MethodChannel('com.app.fiscal_assistant/shared_content');

  SupabaseClient get _client => SupabaseClientManager.client;

  Future<MultimodalInboxResult?> pickAndAnalyze() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'mp3',
        'm4a',
        'wav',
        'webm',
        'ogg',
        'opus',
        'mp4',
        'pdf',
        'txt',
      ],
    );

    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      return const MultimodalInboxResult(
        success: false,
        skipped: false,
        message: 'Arquivo sem dados para enviar.',
      );
    }

    return analyzeSharedItem(
      SharedInboxItem(
        bytes: bytes,
        fileName: file.name,
        mimeType: _contentType(file.name),
        sourceApp: 'file_picker',
      ),
      source: 'manual_upload',
    );
  }

  Future<MultimodalInboxResult> analyzeText({
    required String text,
    String source = 'manual_text',
    String? sourceTitle,
    String? sender,
  }) async {
    return analyzeSharedItem(
      SharedInboxItem(text: text, sourceApp: 'text'),
      source: source,
      sourceTitle: sourceTitle,
      sender: sender,
    );
  }

  Future<List<MultimodalInboxResult>> consumeSharedContent() async {
    final raw =
        await _channel.invokeMethod<List<dynamic>>('consumeSharedContent');
    if (raw == null || raw.isEmpty) return const [];

    final results = <MultimodalInboxResult>[];
    for (final item in raw) {
      try {
        final map = _asMap(item);
        final bytesBase64 = map['bytesBase64']?.toString();
        final bytes =
            bytesBase64?.isNotEmpty == true ? base64Decode(bytesBase64!) : null;
        final sharedItem = SharedInboxItem(
          text: map['text']?.toString(),
          bytes: bytes,
          fileName: map['fileName']?.toString(),
          mimeType: map['mimeType']?.toString(),
          sourceApp: map['sourceApp']?.toString(),
        );

        if (sharedItem.hasFile || sharedItem.hasText) {
          results.add(await analyzeSharedItem(
            sharedItem,
            source: 'android_share',
            sourceTitle: 'Compartilhado com Fiscal Assistant',
          ));
        }
      } catch (e) {
        results.add(MultimodalInboxResult.error(e));
      }
    }
    return results;
  }

  Future<MultimodalInboxResult> analyzeSharedItem(
    SharedInboxItem item, {
    required String source,
    String? sourceTitle,
    String? sender,
  }) async {
    try {
      final fiscalId = SupabaseClientManager.currentUserId;
      if (fiscalId == null || fiscalId.isEmpty) {
        throw Exception('Usuario nao autenticado.');
      }

      final now = DateTime.now();
      final rawText = item.text?.trim();
      final fileName = item.fileName ?? 'conteudo.txt';
      final mimeType = item.mimeType?.isNotEmpty == true
          ? item.mimeType!
          : _contentType(fileName);
      final contentType =
          item.hasFile ? _contentKind(fileName, mimeType) : 'text';
      final mediaType = switch (contentType) {
        'audio' => 'audio',
        'image' => 'foto',
        'document' => 'document',
        'video' => 'video',
        _ => null,
      };

      String? storagePath;
      if (item.hasFile) {
        storagePath = _storagePath(
          fiscalId: fiscalId,
          fileName: fileName,
          timestamp: now,
        );
        await _client.storage.from(_bucket).uploadBinary(
              storagePath,
              item.bytes!,
              fileOptions: FileOptions(
                upsert: true,
                contentType: mimeType,
              ),
            );
      }

      final capture = await _client
          .from('ai_inbox_items')
          .insert({
            'fiscal_id': fiscalId,
            'source': source,
            'source_app': item.sourceApp,
            'source_title': sourceTitle,
            'sender': sender,
            'raw_text': rawText,
            'raw_title': sourceTitle,
            'raw_content': rawText,
            'content_type': contentType,
            'media_type': mediaType,
            'storage_bucket': _bucket,
            'storage_path': storagePath,
            'file_name': item.hasFile ? fileName : null,
            'mime_type': item.hasFile ? mimeType : null,
            'size_bytes': item.bytes?.length,
            'event_date': now.toIso8601String(),
            'analysis_status': 'pending',
          })
          .select()
          .single();

      final response = await _client.functions.invoke(
        'analyze-fiscal-message',
        headers: SupabaseClientManager.edgeFunctionHeaders,
        body: {
          'capture_id': capture['id'],
          'fiscal_id': fiscalId,
        },
      );

      final payload = _asMap(response.data);
      if (payload['success'] == false) {
        throw Exception(payload['error'] ?? 'Falha ao analisar conteudo.');
      }
      return MultimodalInboxResult.fromPayload(payload);
    } catch (e) {
      return MultimodalInboxResult.error(e);
    }
  }

  String _storagePath({
    required String fiscalId,
    required String fileName,
    required DateTime timestamp,
  }) {
    final millis = timestamp.millisecondsSinceEpoch;
    return '$fiscalId/$millis-${_sanitizeFileName(fileName)}';
  }

  String _sanitizeFileName(String fileName) {
    final noSpaces = fileName.replaceAll(RegExp(r'\s+'), '_');
    final safe = noSpaces.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');
    return safe.isEmpty ? 'arquivo' : safe;
  }

  static String _contentKind(String fileName, String mimeType) {
    final lower = '${fileName.toLowerCase()} ${mimeType.toLowerCase()}';
    if (lower.contains('image/') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp')) {
      return 'image';
    }
    if (lower.contains('audio/') ||
        lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.opus')) {
      return 'audio';
    }
    if (lower.contains('video/') || lower.endsWith('.mp4')) return 'video';
    if (lower.contains('pdf') || lower.endsWith('.pdf')) return 'document';
    return 'text';
  }

  static String _contentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.m4a')) return 'audio/m4a';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.webm')) return 'audio/webm';
    if (lower.endsWith('.ogg')) return 'audio/ogg';
    if (lower.endsWith('.opus')) return 'audio/ogg';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.txt')) return 'text/plain';
    return 'application/octet-stream';
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  if (value is String && value.trim().isNotEmpty) {
    final decoded = jsonDecode(value);
    if (decoded is Map) {
      return decoded.map((key, item) => MapEntry(key.toString(), item));
    }
  }
  return {};
}
