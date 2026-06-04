import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../datasources/remote/supabase_client.dart';

class EntregaCupomDraft {
  final String numeroNota;
  final String clienteNome;
  final String telefone;
  final String endereco;
  final String bairro;
  final String cidade;
  final String observacoes;
  final DateTime? horarioMarcado;
  final double confidence;
  final List<String> missingFields;
  final String rawText;
  final String? fileName;

  const EntregaCupomDraft({
    this.numeroNota = '',
    this.clienteNome = '',
    this.telefone = '',
    this.endereco = '',
    this.bairro = '',
    this.cidade = '',
    this.observacoes = '',
    this.horarioMarcado,
    this.confidence = 0,
    this.missingFields = const [],
    this.rawText = '',
    this.fileName,
  });

  factory EntregaCupomDraft.fromMap(Map<String, dynamic> map) {
    final horario = _readString(map, const [
      'horario_marcado',
      'horarioMarcado',
      'scheduled_time',
    ]);

    return EntregaCupomDraft(
      numeroNota: _readString(map, const [
        'numero_nota',
        'numeroNota',
        'nota',
        'nf',
      ]),
      clienteNome: _readString(map, const [
        'cliente_nome',
        'clienteNome',
        'cliente',
        'nome_cliente',
      ]),
      telefone: _readString(map, const [
        'telefone',
        'phone',
      ]),
      endereco: _readString(map, const [
        'endereco',
        'address',
      ]),
      bairro: _readString(map, const [
        'bairro',
        'district',
      ]),
      cidade: _normalizeCidade(_readString(map, const [
        'cidade',
        'city',
      ])),
      observacoes: _readString(map, const [
        'observacoes',
        'observacao',
        'notes',
      ]),
      horarioMarcado: _parseHorario(horario),
      confidence: _readDouble(map['confidence'] ?? map['confianca']),
      missingFields: _readStringList(map['missing_fields']),
      rawText: _readString(map, const [
        'raw_text',
        'texto_lido',
        'image_text',
      ]),
      fileName: _readString(map, const ['file_name', 'fileName']),
    );
  }

  bool get canCreate =>
      numeroNota.trim().isNotEmpty &&
      clienteNome.trim().length >= 3 &&
      endereco.trim().isNotEmpty &&
      bairro.trim().isNotEmpty &&
      cidade.trim().isNotEmpty;

  List<String> get requiredMissingFields {
    final fields = <String>[];
    if (numeroNota.trim().isEmpty) fields.add('numero da nota');
    if (clienteNome.trim().length < 3) fields.add('cliente');
    if (endereco.trim().isEmpty) fields.add('endereco');
    if (bairro.trim().isEmpty) fields.add('bairro');
    if (cidade.trim().isEmpty) fields.add('cidade');
    return fields;
  }

  String get confidenceLabel => '${(confidence * 100).round()}%';

  String observacoesParaSalvar() {
    final parts = <String>[
      if (observacoes.trim().isNotEmpty) observacoes.trim(),
      'Preenchido por IA a partir do cupom de entrega'
          '${fileName?.trim().isNotEmpty == true ? ' (${fileName!.trim()})' : ''}.',
      if (confidence > 0) 'Confianca da leitura: $confidenceLabel.',
    ];
    return parts.join('\n');
  }
}

class EntregaCupomAiService {
  static const _functionName = 'extract-delivery-coupon';

  SupabaseClient get _client => SupabaseClientManager.client;

  Future<EntregaCupomDraft> extractFromImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final fiscalId = SupabaseClientManager.currentUserId;
    if (fiscalId == null || fiscalId.isEmpty) {
      throw Exception('Usuario nao autenticado.');
    }
    if (bytes.isEmpty) {
      throw Exception('Imagem vazia.');
    }

    final response = await _client.functions.invoke(
      _functionName,
      headers: SupabaseClientManager.edgeFunctionHeaders,
      body: {
        'fiscal_id': fiscalId,
        'file_name': fileName,
        'mime_type': mimeType,
        'image_base64': base64Encode(bytes),
      },
    );

    final payload = _asMap(response.data);
    if (payload['success'] == false) {
      throw Exception(
        payload['error'] ?? 'Falha ao analisar cupom de entrega.',
      );
    }

    final result = _asMap(payload['result'] ?? payload);
    return EntregaCupomDraft.fromMap({
      ...result,
      'file_name': fileName,
    });
  }

  static String mimeTypeForFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
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

String _readString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return '';
}

double _readDouble(Object? value) {
  if (value is num) return value.toDouble().clamp(0, 1).toDouble();
  if (value is String) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed != null) return parsed.clamp(0, 1).toDouble();
  }
  return 0;
}

List<String> _readStringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}

DateTime? _parseHorario(String value) {
  if (value.trim().isEmpty) return null;

  final parsedDate = DateTime.tryParse(value);
  if (parsedDate != null) return parsedDate;

  final match = RegExp(r'^(\d{1,2})[:h](\d{2})$').firstMatch(value.trim());
  if (match == null) return null;

  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null || hour > 23 || minute > 59) {
    return null;
  }

  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour, minute);
}

String _normalizeCidade(String value) {
  final normalized = _normalize(value);
  if (normalized == 'baependi') return 'Baependi';
  if (normalized == 'caxambu') return 'Caxambu';
  if (normalized == 'cruzilia') return 'Cruzilia';
  return value.trim();
}

String _normalize(String value) {
  const accents = {
    'á': 'a',
    'à': 'a',
    'ã': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'õ': 'o',
    'ô': 'o',
    'ö': 'o',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };
  final lower = value.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final codeUnit in lower.codeUnits) {
    final char = String.fromCharCode(codeUnit);
    buffer.write(accents[char] ?? char);
  }
  return buffer.toString();
}
