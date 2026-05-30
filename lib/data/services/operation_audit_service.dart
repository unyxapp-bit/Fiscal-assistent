import 'package:flutter/foundation.dart';

import '../datasources/remote/supabase_client.dart';

class OperationAuditService {
  static const _logsTable = 'operation_audit_logs';
  static const _queueTable = 'operation_notification_queue';

  static Future<void> log({
    required String fiscalId,
    required String area,
    required String action,
    String? entityType,
    String? entityId,
    String severity = 'info',
    String? title,
    String? description,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (fiscalId.isEmpty) return;

    try {
      await SupabaseClientManager.client.from(_logsTable).insert({
        'fiscal_id': fiscalId,
        'area': area,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'severity': severity,
        'title': title,
        'description': description,
        'metadata': metadata,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OperationAuditService] Erro ao registrar log: $e');
      }
    }
  }

  static Future<void> queueNotification({
    required String fiscalId,
    required String area,
    required String title,
    required String message,
    String? entityType,
    String? entityId,
    String priority = 'normal',
    DateTime? scheduledFor,
    Map<String, dynamic> actionPayload = const {},
  }) async {
    if (fiscalId.isEmpty) return;

    try {
      await SupabaseClientManager.client.from(_queueTable).insert({
        'fiscal_id': fiscalId,
        'area': area,
        'entity_type': entityType,
        'entity_id': entityId,
        'priority': priority,
        'title': title,
        'message': message,
        'scheduled_for': scheduledFor?.toIso8601String(),
        'action_payload': actionPayload,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[OperationAuditService] Erro ao enfileirar notificacao: $e',
        );
      }
    }
  }
}
