import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// ── Tipos de evento detectados ────────────────────────────────────────────────

enum TipoEventoImportado {
  discrepanciaValor, // falta/sobra no caixa
  atestado,          // atestado médico
  ausencia,          // falta ao trabalho
  tarefa,            // tarefa a fazer
  entrega,           // entrega recebida
  reclamacao,        // reclamação/problema
  outro,
}

extension TipoEventoImportadoExt on TipoEventoImportado {
  String get label {
    switch (this) {
      case TipoEventoImportado.discrepanciaValor:
        return 'Discrepância de Caixa';
      case TipoEventoImportado.atestado:
        return 'Atestado Médico';
      case TipoEventoImportado.ausencia:
        return 'Falta';
      case TipoEventoImportado.tarefa:
        return 'Tarefa';
      case TipoEventoImportado.entrega:
        return 'Entrega';
      case TipoEventoImportado.reclamacao:
        return 'Reclamação';
      case TipoEventoImportado.outro:
        return 'Outro';
    }
  }

  bool get vaiParaOcorrencia =>
      this == TipoEventoImportado.discrepanciaValor ||
      this == TipoEventoImportado.atestado ||
      this == TipoEventoImportado.ausencia ||
      this == TipoEventoImportado.reclamacao;
}

// ── Model ─────────────────────────────────────────────────────────────────────

class EventoImportado {
  final TipoEventoImportado tipo;
  final String descricao;
  final String? nomeColaborador;
  final double? valor;
  final DateTime? dataEvento;
  final double confianca;

  const EventoImportado({
    required this.tipo,
    required this.descricao,
    this.nomeColaborador,
    this.valor,
    this.dataEvento,
    this.confianca = 1.0,
  });
}

// ── Serviço ───────────────────────────────────────────────────────────────────

class ClaudeParserService {
  static const _url = 'https://api.anthropic.com/v1/messages';

  // Usa haiku — mais rápido e barato para tarefas de extração simples
  static const _model = 'claude-haiku-4-5-20251001';

  String get _apiKey => dotenv.env['CLAUDE_API_KEY'] ?? '';

  bool get configurado => _apiKey.isNotEmpty;

  Future<List<EventoImportado>> analisar(String conversa) async {
    if (!configurado) {
      throw Exception(
          'API key não configurada. Adicione CLAUDE_API_KEY no arquivo .env');
    }

    const systemPrompt = '''
Você analisa conversas de WhatsApp de supervisores de supermercado e extrai eventos relevantes.

TIPOS DE EVENTO:
- cashDiscrepancy: falta ou sobra em caixa. Ex: "caixa faltou 9,90", "sobrou 5 reais"
- medicalLeave: atestado médico. Ex: "atestado da Talita", "Ingrid apresentou atestado"
- absence: falta ao trabalho. Ex: "Ingrid não veio", "Talita faltou"
- task: tarefa a fazer. Ex: "lavar os carrinhos", "fazer cartazes", "ligar para fornecedor"
- delivery: entrega recebida. Ex: "pedidos chegaram", "mercadoria chegou"
- complaint: reclamação ou problema. Ex: "cliente reclamou", "problema no caixa 3"
- other: outro evento relevante para o supervisor

Responda APENAS com JSON válido, sem texto extra e sem markdown:
{"events":[{"type":"cashDiscrepancy","description":"Descrição clara em pt-BR","employee_name":"Nome ou null","amount":9.90,"event_date":"2026-01-28","confidence":0.95}]}

REGRAS:
1. Ignore cumprimentos, "ok", "sim", "obrigada" e mensagens sem informação operacional
2. description sempre em português, clara e concisa
3. confidence: 0.9-1.0 muito certo, 0.7-0.9 certo — omita eventos abaixo de 0.7
4. Para datas, use a data da mensagem no formato YYYY-MM-DD
5. employee_name: nome do colaborador envolvido, ou null se não identificado
6. amount: valor numérico sem R\$ apenas para cashDiscrepancy, null para outros tipos
''';

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'system': systemPrompt,
          'messages': [
            {
              'role': 'user',
              'content': 'Analise esta conversa do WhatsApp:\n\n$conversa',
            }
          ],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Erro ${response.statusCode}: verifique sua CLAUDE_API_KEY');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text =
          ((data['content'] as List).first as Map)['text'] as String;

      // Remove possível markdown envolvendo o JSON
      final cleaned = text
          .trim()
          .replaceAll(RegExp(r'^```json\s*'), '')
          .replaceAll(RegExp(r'\s*```$'), '');

      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      final events = (parsed['events'] as List?) ?? [];

      return events
          .map((e) => EventoImportado(
                tipo: _parseTipo(e['type'] as String? ?? ''),
                descricao: e['description'] as String? ?? '',
                nomeColaborador: e['employee_name'] as String?,
                valor: (e['amount'] as num?)?.toDouble(),
                dataEvento: e['event_date'] != null
                    ? DateTime.tryParse(e['event_date'] as String)
                    : null,
                confianca:
                    (e['confidence'] as num?)?.toDouble() ?? 1.0,
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[ClaudeParserService] $e');
      rethrow;
    }
  }

  TipoEventoImportado _parseTipo(String type) {
    switch (type.toLowerCase()) {
      case 'cashdiscrepancy':
        return TipoEventoImportado.discrepanciaValor;
      case 'medicalleave':
        return TipoEventoImportado.atestado;
      case 'absence':
        return TipoEventoImportado.ausencia;
      case 'task':
        return TipoEventoImportado.tarefa;
      case 'delivery':
        return TipoEventoImportado.entrega;
      case 'complaint':
        return TipoEventoImportado.reclamacao;
      default:
        return TipoEventoImportado.outro;
    }
  }
}
