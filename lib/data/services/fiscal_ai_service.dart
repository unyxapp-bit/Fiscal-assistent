import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../datasources/remote/supabase_client.dart';
import '../models/fiscal_ai_models.dart';

class FiscalAiService {
  static const _functionName = 'fiscal-ai-agent';
  static const _snapshotsTable = 'fiscal_ai_snapshots';
  static const _actionsTable = 'fiscal_ai_actions';

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

    final response = await _client.functions.invoke(
      _functionName,
      headers: SupabaseClientManager.edgeFunctionHeaders,
      body: body,
    );

    final payload = _responseDataAsMap(response.data);
    if (payload['success'] == false) {
      throw Exception(payload['error'] ?? 'Falha ao executar agente fiscal.');
    }

    final result = payload['result'];
    if (result is Map || result is String) {
      return FiscalAiInsight.fromMap(_responseDataAsMap(result));
    }
    return FiscalAiInsight.fromMap(payload);
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
}
