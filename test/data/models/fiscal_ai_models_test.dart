import 'dart:convert';

import 'package:fiscal_assistant/data/models/fiscal_ai_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FiscalAi models', () {
    test('normaliza insight com JSON aninhado e defaults seguros', () {
      final insight = FiscalAiInsight.fromMap({
        'summary': '2 pendencias abertas',
        'overall_severity': 'alto',
        'risks': [
          {
            'title': 'Diferenca de caixa',
            'severity': 'critico',
            'reason': 'Valor alto',
            'target': {'event_id': 10},
          }
        ],
        'recommendations': [
          {'title': 'Conferir comprovantes', 'priority': 'alta'}
        ],
        'next_action': {
          'title': 'Criar acompanhamento',
          'can_execute': true,
        },
        'action_plan': jsonEncode({
          'mode': 'execute_with_confirmation',
          'tool_name': 'create_followup_event',
          'arguments': {'description': 'Conferir caixa 7'},
          'confirmation_required': true,
        }),
        'provider': 'openai',
        'fonte': 'ia_completa',
        'model': 'gpt-5.4-mini',
      });

      expect(insight.hasOperationalData, isTrue);
      expect(insight.risks.single.title, 'Diferenca de caixa');
      expect(insight.recommendations.single.owner, 'Fiscal do turno');
      expect(insight.actionPlan.toolName, 'create_followup_event');
      expect(insight.actionPlan.confirmationRequired, isTrue);
      expect(insight.provider, 'openai');
      expect(insight.source, 'ia_completa');
      expect(insight.model, 'gpt-5.4-mini');
    });

    test('normaliza action da fila com status aberto', () {
      final action = FiscalAiQueuedAction.fromMap({
        'id': 'action-1',
        'fiscal_id': 'fiscal-1',
        'status': 'pending_approval',
        'tool_name': 'create_followup_event',
        'title': 'Acao critica',
        'description': 'Criar acompanhamento',
        'confirmation_required': true,
        'arguments': {'description': 'Evento importante'},
        'context_snapshot': {'metrics': {}},
      });

      expect(action.hasTool, isTrue);
      expect(action.isTerminal, isFalse);
      expect(action.confirmationRequired, isTrue);
      expect(action.arguments['description'], 'Evento importante');
    });
  });
}
