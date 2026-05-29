import 'dart:convert';

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return _asMap(decoded);
    } catch (_) {
      return {};
    }
  }
  return {};
}

List<Map<String, dynamic>> _asMapList(Object? value) {
  if (value is! List) return const [];
  return value.map(_asMap).where((item) => item.isNotEmpty).toList();
}

List<String> _asStringList(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList();
}

String _asString(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

double _asDouble(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? fallback;
  }
  return fallback;
}

bool _asBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.toLowerCase().trim();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return fallback;
}

DateTime? _asDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class FiscalAiRisk {
  final String title;
  final String severity;
  final String reason;
  final String evidence;
  final String action;
  final Map<String, dynamic> target;

  const FiscalAiRisk({
    required this.title,
    required this.severity,
    required this.reason,
    required this.evidence,
    required this.action,
    required this.target,
  });

  factory FiscalAiRisk.fromMap(Map<String, dynamic> map) => FiscalAiRisk(
        title: _asString(map['title'], 'Risco fiscal'),
        severity: _asString(map['severity'], 'normal'),
        reason: _asString(map['reason']),
        evidence: _asString(map['evidence']),
        action: _asString(map['action']),
        target: _asMap(map['target']),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'severity': severity,
        'reason': reason,
        'evidence': evidence,
        'action': action,
        'target': target,
      };
}

class FiscalAiRecommendation {
  final String title;
  final String description;
  final String priority;
  final String owner;
  final bool requiresConfirmation;

  const FiscalAiRecommendation({
    required this.title,
    required this.description,
    required this.priority,
    required this.owner,
    required this.requiresConfirmation,
  });

  factory FiscalAiRecommendation.fromMap(Map<String, dynamic> map) =>
      FiscalAiRecommendation(
        title: _asString(map['title'], 'Recomendacao'),
        description: _asString(map['description']),
        priority: _asString(map['priority'], 'media'),
        owner: _asString(map['owner'], 'Fiscal do turno'),
        requiresConfirmation: _asBool(map['requires_confirmation']),
      );
}

class FiscalAiNextAction {
  final String title;
  final String description;
  final bool canExecute;

  const FiscalAiNextAction({
    required this.title,
    required this.description,
    required this.canExecute,
  });

  factory FiscalAiNextAction.fromMap(Map<String, dynamic> map) =>
      FiscalAiNextAction(
        title: _asString(map['title'], 'Proxima acao'),
        description: _asString(map['description']),
        canExecute: _asBool(map['can_execute']),
      );

  factory FiscalAiNextAction.empty() => const FiscalAiNextAction(
        title: 'Aguardando analise',
        description: 'Execute uma analise para receber a proxima acao.',
        canExecute: false,
      );
}

class FiscalAiActionPlan {
  final String mode;
  final String? toolName;
  final String description;
  final double confidence;
  final Map<String, dynamic> arguments;
  final String argumentsSummary;
  final bool confirmationRequired;

  const FiscalAiActionPlan({
    required this.mode,
    required this.toolName,
    required this.description,
    required this.confidence,
    required this.arguments,
    required this.argumentsSummary,
    required this.confirmationRequired,
  });

  bool get hasTool => toolName != null && toolName!.trim().isNotEmpty;
  bool get isEmpty => !hasTool || mode == 'none';

  factory FiscalAiActionPlan.fromMap(Map<String, dynamic> map) {
    final tool = _asString(map['tool_name']);
    return FiscalAiActionPlan(
      mode: _asString(map['mode'], 'none'),
      toolName: tool.isEmpty ? null : tool,
      description: _asString(map['description']),
      confidence: _asDouble(map['confidence']),
      arguments: _asMap(map['arguments']),
      argumentsSummary: _asString(map['arguments_summary']),
      confirmationRequired: _asBool(map['confirmation_required']),
    );
  }

  factory FiscalAiActionPlan.empty() => const FiscalAiActionPlan(
        mode: 'none',
        toolName: null,
        description: '',
        confidence: 0,
        arguments: {},
        argumentsSummary: '',
        confirmationRequired: false,
      );
}

class FiscalAiActionResult {
  final String status;
  final String? toolName;
  final String title;
  final String message;
  final String? artifactMarkdown;

  const FiscalAiActionResult({
    required this.status,
    required this.toolName,
    required this.title,
    required this.message,
    required this.artifactMarkdown,
  });

  bool get isExecuted => status == 'executed';
  bool get needsConfirmation => status == 'pending_confirmation';
  bool get hasArtifact => artifactMarkdown?.trim().isNotEmpty == true;
  bool get hasMessage => title.isNotEmpty || message.isNotEmpty;

  factory FiscalAiActionResult.fromMap(Map<String, dynamic> map) {
    final tool = _asString(map['tool_name']);
    final artifact = _asString(map['artifact_markdown']);
    return FiscalAiActionResult(
      status: _asString(map['status'], 'none'),
      toolName: tool.isEmpty ? null : tool,
      title: _asString(map['title']),
      message: _asString(map['message']),
      artifactMarkdown: artifact.isEmpty ? null : artifact,
    );
  }

  factory FiscalAiActionResult.empty() => const FiscalAiActionResult(
        status: 'none',
        toolName: null,
        title: '',
        message: '',
        artifactMarkdown: null,
      );

  Map<String, dynamic> toMap() => {
        'status': status,
        'tool_name': toolName,
        'title': title,
        'message': message,
        'artifact_markdown': artifactMarkdown,
      };
}

class FiscalAiResolution {
  final String status;
  final String diagnosis;
  final String severity;
  final List<String> immediateSteps;
  final String recommendedMessage;
  final List<String> preventiveActions;
  final bool confirmationRequired;
  final Map<String, dynamic> applyEvent;

  const FiscalAiResolution({
    required this.status,
    required this.diagnosis,
    required this.severity,
    required this.immediateSteps,
    required this.recommendedMessage,
    required this.preventiveActions,
    required this.confirmationRequired,
    required this.applyEvent,
  });

  bool get hasDraft => status == 'drafted' || diagnosis.isNotEmpty;

  factory FiscalAiResolution.fromMap(Map<String, dynamic> map) =>
      FiscalAiResolution(
        status: _asString(map['status'], 'none'),
        diagnosis: _asString(map['diagnosis']),
        severity: _asString(map['severity'], 'normal'),
        immediateSteps: _asStringList(map['immediate_steps']),
        recommendedMessage: _asString(map['recommended_message']),
        preventiveActions: _asStringList(map['preventive_actions']),
        confirmationRequired: _asBool(map['confirmation_required']),
        applyEvent: _asMap(map['apply_event']),
      );

  factory FiscalAiResolution.empty() => const FiscalAiResolution(
        status: 'none',
        diagnosis: '',
        severity: 'normal',
        immediateSteps: [],
        recommendedMessage: '',
        preventiveActions: [],
        confirmationRequired: false,
        applyEvent: {},
      );
}

class FiscalAiInsight {
  final String summary;
  final String overallSeverity;
  final List<FiscalAiRisk> risks;
  final List<FiscalAiRecommendation> recommendations;
  final FiscalAiNextAction nextAction;
  final FiscalAiActionPlan actionPlan;
  final FiscalAiActionResult actionResult;
  final FiscalAiResolution resolution;
  final String chatAnswer;
  final List<String> toolsUsed;
  final String provider;
  final String? model;
  final String? warning;

  const FiscalAiInsight({
    required this.summary,
    required this.overallSeverity,
    required this.risks,
    required this.recommendations,
    required this.nextAction,
    required this.actionPlan,
    required this.actionResult,
    required this.resolution,
    required this.chatAnswer,
    required this.toolsUsed,
    required this.provider,
    required this.model,
    required this.warning,
  });

  bool get hasOperationalData =>
      summary.isNotEmpty || risks.isNotEmpty || recommendations.isNotEmpty;

  factory FiscalAiInsight.fromMap(Map<String, dynamic> map) => FiscalAiInsight(
        summary: _asString(map['summary']),
        overallSeverity: _asString(map['overall_severity'], 'normal'),
        risks: _asMapList(map['risks']).map(FiscalAiRisk.fromMap).toList(),
        recommendations: _asMapList(map['recommendations'])
            .map(FiscalAiRecommendation.fromMap)
            .toList(),
        nextAction: FiscalAiNextAction.fromMap(_asMap(map['next_action'])),
        actionPlan: FiscalAiActionPlan.fromMap(_asMap(map['action_plan'])),
        actionResult:
            FiscalAiActionResult.fromMap(_asMap(map['action_result'])),
        resolution: FiscalAiResolution.fromMap(_asMap(map['resolution'])),
        chatAnswer: _asString(map['chat_answer']),
        toolsUsed: _asStringList(map['tools_used']),
        provider: _asString(map['provider'], 'local'),
        model: _asString(map['model']).isEmpty ? null : _asString(map['model']),
        warning: _asString(map['warning']).isEmpty
            ? null
            : _asString(map['warning']),
      );

  factory FiscalAiInsight.empty() => FiscalAiInsight(
        summary: '',
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
        model: null,
        warning: null,
      );
}

class FiscalAiSnapshot {
  final String id;
  final String fiscalId;
  final String intent;
  final String? question;
  final FiscalAiInsight result;
  final DateTime? createdAt;

  const FiscalAiSnapshot({
    required this.id,
    required this.fiscalId,
    required this.intent,
    required this.question,
    required this.result,
    required this.createdAt,
  });

  factory FiscalAiSnapshot.fromMap(Map<String, dynamic> map) =>
      FiscalAiSnapshot(
        id: _asString(map['id']),
        fiscalId: _asString(map['fiscal_id']),
        intent: _asString(map['intent'], 'analyze'),
        question: _asString(map['question']).isEmpty
            ? null
            : _asString(map['question']),
        result: FiscalAiInsight.fromMap(_asMap(map['result'])),
        createdAt: _asDate(map['created_at']),
      );
}

class FiscalAiActionRequest {
  final String toolName;
  final Map<String, dynamic> arguments;
  final bool confirmed;

  const FiscalAiActionRequest({
    required this.toolName,
    this.arguments = const {},
    this.confirmed = false,
  });

  Map<String, dynamic> toMap() => {
        'tool_name': toolName,
        'arguments': arguments,
        'confirmed': confirmed,
      };
}

class FiscalAiQueuedAction {
  final String id;
  final String fiscalId;
  final String? snapshotId;
  final String status;
  final String mode;
  final String? toolName;
  final String title;
  final String description;
  final String? reason;
  final double confidence;
  final bool confirmationRequired;
  final Map<String, dynamic> arguments;
  final Map<String, dynamic> target;
  final Map<String, dynamic> contextSnapshot;
  final FiscalAiActionResult actionResult;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FiscalAiQueuedAction({
    required this.id,
    required this.fiscalId,
    required this.snapshotId,
    required this.status,
    required this.mode,
    required this.toolName,
    required this.title,
    required this.description,
    required this.reason,
    required this.confidence,
    required this.confirmationRequired,
    required this.arguments,
    required this.target,
    required this.contextSnapshot,
    required this.actionResult,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasTool => toolName != null && toolName!.trim().isNotEmpty;
  bool get isTerminal => status == 'executed' || status == 'dismissed';

  factory FiscalAiQueuedAction.fromMap(Map<String, dynamic> map) {
    final tool = _asString(map['tool_name']);
    final reason = _asString(map['reason']);
    return FiscalAiQueuedAction(
      id: _asString(map['id']),
      fiscalId: _asString(map['fiscal_id']),
      snapshotId: _asString(map['snapshot_id']).isEmpty
          ? null
          : _asString(map['snapshot_id']),
      status: _asString(map['status'], 'suggested'),
      mode: _asString(map['mode'], 'suggest'),
      toolName: tool.isEmpty ? null : tool,
      title: _asString(map['title'], 'Acao sugerida'),
      description: _asString(map['description']),
      reason: reason.isEmpty ? null : reason,
      confidence: _asDouble(map['confidence'], 0.7),
      confirmationRequired: _asBool(map['confirmation_required']),
      arguments: _asMap(map['arguments']),
      target: _asMap(map['target']),
      contextSnapshot: _asMap(map['context_snapshot']),
      actionResult: FiscalAiActionResult.fromMap(_asMap(map['action_result'])),
      createdAt: _asDate(map['created_at']),
      updatedAt: _asDate(map['updated_at']),
    );
  }
}
