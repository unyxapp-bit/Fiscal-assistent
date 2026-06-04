import 'package:fiscal_assistant/data/models/fiscal_ai_models.dart';
import 'package:fiscal_assistant/data/services/fiscal_ai_service.dart';
import 'package:fiscal_assistant/presentation/providers/fiscal_ai_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FiscalAiProvider', () {
    test('load restaura snapshot, fila e horario da ultima analise', () async {
      final createdAt = DateTime(2026, 6, 4, 9, 30);
      final service = _FakeFiscalAiService(
        snapshot: FiscalAiSnapshot(
          id: 'snapshot-1',
          fiscalId: 'fiscal-1',
          intent: 'analyze',
          question: null,
          result: _insight(summary: 'Turno com alerta'),
          createdAt: createdAt,
        ),
        queuedActions: [_queuedAction()],
      );
      final provider = FiscalAiProvider(service: service);

      await provider.load('fiscal-1');

      expect(provider.error, isNull);
      expect(provider.insight?.summary, 'Turno com alerta');
      expect(provider.actions, hasLength(1));
      expect(provider.lastAnalyzedAt, createdAt);
    });

    test('analyze atualiza insight, fila e horario local', () async {
      final service = _FakeFiscalAiService(
        runResult: _insight(summary: 'Analise atualizada'),
        queuedActions: [_queuedAction()],
      );
      final provider = FiscalAiProvider(service: service);

      await provider.analyze(
        fiscalId: 'fiscal-1',
        context: {
          'metrics': {'eventos_pendentes': 1},
        },
      );

      expect(provider.error, isNull);
      expect(provider.running, isFalse);
      expect(provider.insight?.summary, 'Analise atualizada');
      expect(provider.actions, hasLength(1));
      expect(provider.lastAnalyzedAt, isNotNull);
      expect(service.lastContext?['metrics'], {'eventos_pendentes': 1});
    });
  });
}

class _FakeFiscalAiService extends FiscalAiService {
  final FiscalAiSnapshot? snapshot;
  final FiscalAiInsight runResult;
  final List<FiscalAiQueuedAction> queuedActions;
  Map<String, dynamic>? lastContext;

  _FakeFiscalAiService({
    this.snapshot,
    FiscalAiInsight? runResult,
    this.queuedActions = const [],
  }) : runResult = runResult ?? _insight();

  @override
  Future<FiscalAiSnapshot?> getLatestSnapshot(String fiscalId) async {
    return snapshot;
  }

  @override
  Future<List<FiscalAiQueuedAction>> listQueuedActions(
    String fiscalId, {
    bool openOnly = true,
    int limit = 30,
  }) async {
    return queuedActions;
  }

  @override
  Future<FiscalAiInsight> runAgent({
    required String fiscalId,
    String intent = 'analyze',
    String? question,
    Map<String, dynamic>? target,
    FiscalAiActionRequest? action,
    Map<String, dynamic>? context,
  }) async {
    lastContext = context;
    return runResult;
  }
}

FiscalAiInsight _insight({String summary = 'Resumo'}) {
  return FiscalAiInsight(
    summary: summary,
    overallSeverity: 'normal',
    risks: const [],
    recommendations: const [],
    nextAction: FiscalAiNextAction.empty(),
    actionPlan: FiscalAiActionPlan.empty(),
    actionResult: FiscalAiActionResult.empty(),
    resolution: FiscalAiResolution.empty(),
    chatAnswer: '',
    toolsUsed: const [],
    provider: 'local',
    source: 'local_offline',
    model: null,
    warning: null,
  );
}

FiscalAiQueuedAction _queuedAction() {
  return FiscalAiQueuedAction(
    id: 'action-1',
    fiscalId: 'fiscal-1',
    snapshotId: null,
    status: 'ready',
    mode: 'suggest',
    toolName: 'generate_balcao_report',
    title: 'Gerar briefing',
    description: 'Gerar resumo do turno',
    reason: null,
    confidence: 0.8,
    confirmationRequired: false,
    arguments: const {},
    target: const {},
    contextSnapshot: const {},
    actionResult: FiscalAiActionResult.empty(),
    createdAt: null,
    updatedAt: null,
  );
}
