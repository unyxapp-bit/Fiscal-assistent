import 'package:flutter/foundation.dart';

import '../../data/models/fiscal_ai_models.dart';
import '../../data/services/fiscal_ai_service.dart';

class FiscalAiProvider with ChangeNotifier {
  final FiscalAiService _service;

  FiscalAiProvider({FiscalAiService? service})
      : _service = service ?? FiscalAiService();

  FiscalAiInsight? _insight;
  FiscalAiSnapshot? _latestSnapshot;
  List<FiscalAiQueuedAction> _actions = const [];
  DateTime? _lastAnalyzedAt;
  bool _loading = false;
  bool _running = false;
  String? _error;

  FiscalAiInsight? get insight => _insight;
  FiscalAiSnapshot? get latestSnapshot => _latestSnapshot;
  List<FiscalAiQueuedAction> get actions => _actions;
  DateTime? get lastAnalyzedAt => _lastAnalyzedAt;
  bool get loading => _loading;
  bool get running => _running;
  String? get error => _error;
  bool get hasInsight =>
      _insight?.hasOperationalData == true && _insight?.isLocalSource != true;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> load(String fiscalId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _service.getLatestSnapshot(fiscalId),
        _service.listQueuedActions(fiscalId),
      ]);
      _latestSnapshot = results[0] as FiscalAiSnapshot?;
      _actions = results[1] as List<FiscalAiQueuedAction>;
      _insight = _latestSnapshot?.result ?? _insight;
      _lastAnalyzedAt = _latestSnapshot?.createdAt ?? _lastAnalyzedAt;
    } catch (e) {
      _error = 'Nao foi possivel carregar historico da IA: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> analyze({
    required String fiscalId,
    required Map<String, dynamic> context,
    String? question,
  }) async {
    await _run(
      fiscalId: fiscalId,
      intent: question?.trim().isNotEmpty == true ? 'ask' : 'analyze',
      question: question,
      context: context,
    );
  }

  Future<void> resolve({
    required String fiscalId,
    required Map<String, dynamic> context,
    required FiscalAiRisk risk,
  }) async {
    await _run(
      fiscalId: fiscalId,
      intent: 'resolve',
      target: risk.toMap(),
      context: context,
    );
  }

  Future<void> runAction({
    required String fiscalId,
    required String toolName,
    required Map<String, dynamic> context,
    Map<String, dynamic> arguments = const {},
    bool confirmed = false,
  }) async {
    await _run(
      fiscalId: fiscalId,
      intent: 'act',
      context: context,
      action: FiscalAiActionRequest(
        toolName: toolName,
        arguments: arguments,
        confirmed: confirmed,
      ),
    );
  }

  Future<void> runQueuedAction({
    required String fiscalId,
    required FiscalAiQueuedAction action,
    required Map<String, dynamic> fallbackContext,
  }) async {
    final toolName = action.toolName;
    if (toolName == null || toolName.isEmpty) return;

    final context = action.contextSnapshot.isNotEmpty
        ? action.contextSnapshot
        : fallbackContext;

    await runAction(
      fiscalId: fiscalId,
      toolName: toolName,
      context: context,
      arguments: action.arguments,
      confirmed: true,
    );
    if (_error != null) return;

    final result = _insight?.actionResult;
    final nextStatus = result?.isExecuted == true ? 'executed' : 'ready';
    try {
      await _service.updateActionStatus(
        actionId: action.id,
        fiscalId: fiscalId,
        status: nextStatus,
        result: result,
      );
      _actions = await _service.listQueuedActions(fiscalId);
    } catch (e) {
      _error = 'Acao executada, mas nao foi possivel atualizar a fila: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> dismissAction({
    required String fiscalId,
    required FiscalAiQueuedAction action,
  }) async {
    try {
      await _service.updateActionStatus(
        actionId: action.id,
        fiscalId: fiscalId,
        status: 'dismissed',
      );
      _actions = _actions.where((item) => item.id != action.id).toList();
    } catch (e) {
      _error = 'Nao foi possivel descartar a acao: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> _run({
    required String fiscalId,
    required String intent,
    required Map<String, dynamic> context,
    String? question,
    Map<String, dynamic>? target,
    FiscalAiActionRequest? action,
  }) async {
    _running = true;
    _error = null;
    notifyListeners();

    try {
      _insight = await _service.runAgent(
        fiscalId: fiscalId,
        intent: intent,
        question: question,
        target: target,
        action: action,
        context: context,
      );
      _lastAnalyzedAt = DateTime.now();
      _actions = await _service.listQueuedActions(fiscalId);
    } catch (e) {
      _error = 'Falha na IA Fiscal: $e';
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}
