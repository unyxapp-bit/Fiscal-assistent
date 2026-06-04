import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../datasources/remote/supabase_client.dart';
import '../models/fiscal_ai_models.dart';

class FiscalAiService {
  static const _functionName = 'fiscal-ai-agent';
  static const _snapshotsTable = 'fiscal_ai_snapshots';
  static const _actionsTable = 'fiscal_ai_actions';
  static const _agentTimeout = Duration(seconds: 35);

  SupabaseClient get _client => Supabase.instance.client;

  Future<FiscalAiInsight> runAgent({
    required String fiscalId,
    String intent = 'analyze',
    String? question,
    Map<String, dynamic>? target,
    FiscalAiActionRequest? action,
    Map<String, dynamic>? context,
  }) async {
    final body = <String, dynamic>{
      'fiscal_id': fiscalId,
      'intent': intent,
      'context': context ?? const {},
    };

    if (question?.trim().isNotEmpty == true) {
      body['question'] = question!.trim();
    }
    if (target != null && target.isNotEmpty) {
      body['target'] = target;
    }
    if (action != null) {
      body['action'] = action.toMap();
    }

    try {
      final response = await _client.functions
          .invoke(
            _functionName,
            headers: SupabaseClientManager.edgeFunctionHeaders,
            body: body,
          )
          .timeout(_agentTimeout);

      final payload = _responseDataAsMap(response.data);
      if (payload['success'] == false) {
        return _buildLocalInsight(
          context: context,
          question: question,
          action: action,
          source: 'erro_edge',
          warning: 'A IA externa respondeu com erro; usando leitura local.',
        );
      }

      final result = payload['result'];
      if (result is Map || result is String) {
        return FiscalAiInsight.fromMap(_responseDataAsMap(result));
      }
      if (payload.isNotEmpty) return FiscalAiInsight.fromMap(payload);

      return _buildLocalInsight(
        context: context,
        question: question,
        action: action,
        source: 'resposta_vazia',
        warning: 'A IA nao retornou dados; usando leitura local.',
      );
    } on TimeoutException {
      return _buildLocalInsight(
        context: context,
        question: question,
        action: action,
        source: 'timeout_edge',
        warning: 'A IA demorou para responder; usando leitura local.',
      );
    } catch (_) {
      return _buildLocalInsight(
        context: context,
        question: question,
        action: action,
        source: 'erro_edge',
        warning: 'Nao foi possivel falar com a IA; usando leitura local.',
      );
    }
  }

  Future<FiscalAiSnapshot?> getLatestSnapshot(String fiscalId) async {
    try {
      final data = await _client
          .from(_snapshotsTable)
          .select()
          .eq('fiscal_id', fiscalId)
          .order('created_at', ascending: false)
          .limit(1);

      if (data.isEmpty) return null;
      return FiscalAiSnapshot.fromMap(
        Map<String, dynamic>.from(data.first as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<FiscalAiQueuedAction>> listQueuedActions(
    String fiscalId, {
    bool openOnly = true,
    int limit = 30,
  }) async {
    try {
      final data = await _client
          .from(_actionsTable)
          .select()
          .eq('fiscal_id', fiscalId)
          .order('created_at', ascending: false)
          .limit(limit);

      final actions = data
          .map((item) => FiscalAiQueuedAction.fromMap(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();

      if (!openOnly) return actions;
      return actions.where((action) => !action.isTerminal).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> updateActionStatus({
    required String actionId,
    required String fiscalId,
    required String status,
    FiscalAiActionResult? result,
  }) async {
    final payload = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (status == 'executed' || status == 'dismissed') {
      payload['resolved_at'] = DateTime.now().toIso8601String();
      payload['resolved_by'] = fiscalId;
    }
    if (status == 'approved') {
      payload['approved_at'] = DateTime.now().toIso8601String();
      payload['approved_by'] = fiscalId;
    }
    if (result != null) {
      payload['action_result'] = result.toMap();
    }

    await _client
        .from(_actionsTable)
        .update(payload)
        .eq('id', actionId)
        .eq('fiscal_id', fiscalId);
  }

  Map<String, dynamic> _responseDataAsMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    if (data is String && data.trim().isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    return {};
  }

  FiscalAiInsight _buildLocalInsight({
    required Map<String, dynamic>? context,
    required String? question,
    required FiscalAiActionRequest? action,
    required String source,
    required String warning,
  }) {
    final safeContext = _asLocalMap(context);
    final metrics = _asLocalMap(safeContext['metrics']);
    final events = _asLocalMapList(safeContext['fiscal_events']);
    final pending = events
        .where((event) => _localText(event['status'], 'pending') == 'pending')
        .toList();
    final critical = pending
        .where((event) => _localSeverityRank(_localSeverity(event)) >= 2)
        .toList();
    final totalPending =
        _localInt(metrics['eventos_pendentes'], pending.length);
    final totalCash = _localDouble(metrics['valor_caixa_pendente']);
    final sourceLabel = _sourceLabel(source);

    final risks = critical.take(3).map((event) {
      final evidence = _localText(
        event['raw_message'],
        _localText(event['media_summary'], 'Sem evidencia textual.'),
      );
      return FiscalAiRisk(
        title: _localText(event['description'], 'Pendencia fiscal aberta'),
        severity: _localSeverity(event),
        reason: 'Evento pendente identificado no contexto local.',
        evidence: evidence,
        action: 'Validar o evento no Balcao Fiscal e registrar a tratativa.',
        target: event,
      );
    }).toList();

    final summary = totalPending > 0
        ? '$totalPending pendencia(s) aberta(s). ${critical.length} exigem prioridade. Fonte: $sourceLabel.'
        : 'Sem pendencias abertas no contexto local. Fonte: $sourceLabel.';

    return FiscalAiInsight(
      summary: summary,
      overallSeverity: critical.isNotEmpty
          ? _maxLocalSeverity(critical.map(_localSeverity))
          : totalPending > 0
              ? 'medio'
              : 'normal',
      risks: risks,
      recommendations: [
        FiscalAiRecommendation(
          title: 'Revisar Balcao Fiscal',
          description: totalPending > 0
              ? 'Confira as pendencias abertas antes da passagem de turno.'
              : 'Mantenha o monitoramento do turno.',
          priority: totalPending > 0 ? 'alta' : 'baixa',
          owner: 'Fiscal do turno',
          requiresConfirmation: false,
        ),
        if (totalCash > 0)
          FiscalAiRecommendation(
            title: 'Conferir valores de caixa',
            description:
                'Ha R\$ ${totalCash.toStringAsFixed(2)} em eventos de caixa no contexto.',
            priority: totalCash >= 100 ? 'alta' : 'media',
            owner: 'Fiscal do turno',
            requiresConfirmation: false,
          ),
      ],
      nextAction: FiscalAiNextAction(
        title:
            totalPending > 0 ? 'Tratar pendencias abertas' : 'Monitorar turno',
        description: totalPending > 0
            ? 'Comece pelos eventos marcados como alta prioridade.'
            : 'Atualize a IA novamente quando houver novos eventos.',
        canExecute: false,
      ),
      actionPlan: FiscalAiActionPlan.empty(),
      actionResult: action == null
          ? FiscalAiActionResult.empty()
          : FiscalAiActionResult(
              status: 'failed',
              toolName: action.toolName,
              title: 'Acao nao executada',
              message:
                  'Nao foi possivel executar a acao externa agora. Tente novamente com conexao.',
              artifactMarkdown: null,
            ),
      resolution: FiscalAiResolution.empty(),
      chatAnswer: question == null || question.trim().isEmpty
          ? ''
          : _localAnswer(question, pending, totalCash),
      toolsUsed: const ['flutter_local_context'],
      provider: 'local',
      source: source,
      model: null,
      warning: warning,
    );
  }

  String _localAnswer(
    String question,
    List<Map<String, dynamic>> pending,
    double totalCash,
  ) {
    final normalized = question.toLowerCase();
    if (normalized.contains('caixa') ||
        normalized.contains('valor') ||
        normalized.contains('dinheiro')) {
      return totalCash > 0
          ? 'No contexto local ha R\$ ${totalCash.toStringAsFixed(2)} em eventos de caixa.'
          : 'No contexto local nao encontrei valor de caixa pendente.';
    }
    if (pending.isEmpty) {
      return 'No contexto local nao encontrei pendencias abertas.';
    }
    return 'No contexto local encontrei ${pending.length} pendencia(s). Priorize as mais recentes e as de alta prioridade.';
  }

  String _localSeverity(Map<String, dynamic> event) {
    final priority = _localText(event['priority']).toLowerCase();
    final category = _localText(event['category']).toLowerCase();
    final amount = _localDouble(event['amount']);

    if (priority == 'critica') return 'critico';
    if (priority == 'alta') return 'alto';
    if (category == 'problema_operacional') return 'alto';
    if (category == 'caixa' && amount >= 100) return 'critico';
    if (category == 'caixa' && amount >= 50) return 'alto';
    if (category == 'ausencia' || category == 'atestado') return 'medio';
    return 'normal';
  }

  int _localSeverityRank(String severity) {
    switch (severity) {
      case 'critico':
        return 3;
      case 'alto':
        return 2;
      case 'medio':
        return 1;
      default:
        return 0;
    }
  }

  String _maxLocalSeverity(Iterable<String> severities) {
    var best = 'normal';
    for (final severity in severities) {
      if (_localSeverityRank(severity) > _localSeverityRank(best)) {
        best = severity;
      }
    }
    return best;
  }

  Map<String, dynamic> _asLocalMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return {};
  }

  List<Map<String, dynamic>> _asLocalMapList(Object? value) {
    if (value is! List) return const [];
    return value.map(_asLocalMap).where((item) => item.isNotEmpty).toList();
  }

  String _localText(Object? value, [String fallback = '']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  int _localInt(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  double _localDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'timeout_edge':
        return 'timeout';
      case 'erro_edge':
        return 'modo local';
      case 'resposta_vazia':
        return 'resposta local';
      default:
        return source;
    }
  }
}
