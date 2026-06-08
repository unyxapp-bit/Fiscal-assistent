import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_notif.dart';
import '../../../data/models/fiscal_ai_models.dart';
import '../../../data/services/fiscal_ai_service.dart';
import '../../../data/services/multimodal_inbox_service.dart';
import '../../providers/alocacao_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cafe_provider.dart';
import '../../providers/caixa_provider.dart';
import '../../providers/checklist_provider.dart';
import '../../providers/colaborador_provider.dart';
import '../../providers/entrega_provider.dart';
import '../../providers/fiscal_ai_provider.dart';
import '../../providers/fiscal_events_provider.dart';
import '../../providers/nota_provider.dart';
import '../../providers/ocorrencia_provider.dart';
import '../../widgets/common/operational_widgets.dart';

class FiscalAiScreen extends StatefulWidget {
  const FiscalAiScreen({super.key});

  @override
  State<FiscalAiScreen> createState() => _FiscalAiScreenState();
}

class _FiscalAiScreenState extends State<FiscalAiScreen> {
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();
  final _resolutionSectionKey = GlobalKey();
  final _actionResultSectionKey = GlobalKey();
  final _questionSectionKey = GlobalKey();
  bool _bootstrapped = false;
  bool _analisandoMidia = false;
  bool _testingExternalAi = false;
  FiscalAiInsight? _lastApiTestInsight;
  DateTime? _lastApiTestAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped || !mounted) return;
    _bootstrapped = true;

    final fiscalId = context.read<AuthProvider>().user?.id;
    if (fiscalId == null || fiscalId.isEmpty) return;

    final futures = <Future<void>>[];
    final eventsProvider = context.read<FiscalEventsProvider>();
    final colaboradorProvider = context.read<ColaboradorProvider>();
    final caixaProvider = context.read<CaixaProvider>();

    if (eventsProvider.events.isEmpty && !eventsProvider.loading) {
      futures.add(eventsProvider.load());
    }
    if (colaboradorProvider.todosColaboradores.isEmpty) {
      futures.add(colaboradorProvider.loadColaboradores(fiscalId));
    }
    if (caixaProvider.caixasTodos.isEmpty) {
      futures.add(caixaProvider.loadCaixas(fiscalId));
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
    if (!mounted) return;

    final aiProvider = context.read<FiscalAiProvider>();
    await aiProvider.load(fiscalId);
    if (!mounted || aiProvider.hasInsight) return;

    await aiProvider.analyze(
      fiscalId: fiscalId,
      context: _buildAiContext(context),
    );
  }

  Future<void> _runAnalysis() async {
    final fiscalId = context.read<AuthProvider>().user?.id;
    if (fiscalId == null || fiscalId.isEmpty) return;

    await context.read<FiscalAiProvider>().analyze(
      fiscalId: fiscalId,
      context: _buildAiContext(context),
    );
  }

  Future<void> _testExternalAi() async {
    if (_testingExternalAi) return;

    final fiscalId = context.read<AuthProvider>().user?.id;
    if (fiscalId == null || fiscalId.isEmpty) {
      AppNotif.show(
        context,
        titulo: 'Teste da IA',
        mensagem: 'Entre com um usuario fiscal para testar a IA.',
        tipo: 'alerta',
        cor: AppColors.statusAtencao,
      );
      return;
    }

    setState(() => _testingExternalAi = true);

    try {
      final insight = await FiscalAiService().runAgent(
        fiscalId: fiscalId,
        intent: 'ask',
        question:
            'Teste rapido de conectividade. Responda apenas confirmando se a IA externa esta ativa.',
        context: {
          'runtime_test': true,
          'generated_at': DateTime.now().toIso8601String(),
          'context_policy': {'mode': 'runtime_test'},
          'metrics': _buildAiMetrics(context),
        },
      );
      if (!mounted) return;

      final ok = _isExternalAiResult(insight);
      setState(() {
        _lastApiTestInsight = insight;
        _lastApiTestAt = DateTime.now();
      });

      AppNotif.show(
        context,
        titulo: ok ? 'IA externa ativa' : 'IA ainda em fallback',
        mensagem: ok
            ? 'Teste OK via ${_providerLabel(insight.provider, insight.model)}.'
            : (insight.warning?.trim().isNotEmpty == true
                  ? insight.warning!
                  : 'A chamada respondeu usando fallback local.'),
        tipo: ok ? 'saida' : 'alerta',
        cor: ok ? AppColors.success : AppColors.statusAtencao,
        duracao: const Duration(seconds: 4),
      );
    } catch (e) {
      if (!mounted) return;
      AppNotif.show(
        context,
        titulo: 'Teste da IA falhou',
        mensagem: 'Nao foi possivel testar agora: $e',
        tipo: 'alerta',
        cor: AppColors.danger,
        duracao: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) setState(() => _testingExternalAi = false);
    }
  }

  Future<void> _analisarMidiaComIa() async {
    if (_analisandoMidia) return;
    setState(() => _analisandoMidia = true);

    try {
      final result = await MultimodalInboxService().pickAndAnalyze();
      if (!mounted || result == null) return;

      await context.read<FiscalEventsProvider>().load();
      if (!mounted) return;

      final fiscalId = context.read<AuthProvider>().user?.id;
      if (fiscalId != null && fiscalId.isNotEmpty && result.success) {
        await context.read<FiscalAiProvider>().analyze(
          fiscalId: fiscalId,
          context: _buildAiContext(context),
        );
      }
      if (!mounted) return;

      AppNotif.show(
        context,
        titulo: result.success ? 'Midia analisada' : 'Falha na analise',
        mensagem: result.message,
        tipo: result.success ? 'saida' : 'alerta',
        cor: result.success ? AppColors.success : AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => _analisandoMidia = false);
    }
  }

  Future<void> _sendQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    final fiscalId = context.read<AuthProvider>().user?.id;
    if (fiscalId == null || fiscalId.isEmpty) return;

    _questionController.clear();
    await context.read<FiscalAiProvider>().analyze(
      fiscalId: fiscalId,
      question: question,
      context: _buildAiContext(context),
    );
  }

  Future<void> _executePlan(FiscalAiActionPlan plan) async {
    final fiscalId = context.read<AuthProvider>().user?.id;
    final toolName = plan.toolName;
    if (fiscalId == null || fiscalId.isEmpty || toolName == null) return;

    await context.read<FiscalAiProvider>().runAction(
      fiscalId: fiscalId,
      toolName: toolName,
      context: _buildAiContext(context),
      arguments: plan.arguments,
      confirmed: plan.confirmationRequired,
    );
  }

  Future<void> _resolveRisk(FiscalAiRisk risk) async {
    final fiscalId = context.read<AuthProvider>().user?.id;
    if (fiscalId == null || fiscalId.isEmpty) return;

    final aiProvider = context.read<FiscalAiProvider>();
    await aiProvider.resolve(
      fiscalId: fiscalId,
      risk: risk,
      context: _buildAiContext(context),
    );

    if (!mounted) return;
    if (aiProvider.insight?.resolution.hasDraft == true) {
      AppNotif.show(
        context,
        titulo: 'Diagnostico gerado',
        mensagem: 'A IA preparou uma tratativa para esse alerta.',
        tipo: 'saida',
        cor: AppColors.success,
      );
      await _scrollToSection(_resolutionSectionKey);
    } else if (aiProvider.error == null) {
      AppNotif.show(
        context,
        titulo: 'Resolver',
        mensagem: 'Nao foi possivel gerar uma tratativa agora.',
        tipo: 'alerta',
        cor: AppColors.statusAtencao,
      );
    }
  }

  Future<void> _registerResolutionTimeline(
    FiscalAiResolution resolution,
  ) async {
    final fiscalId = context.read<AuthProvider>().user?.id;
    if (fiscalId == null || fiscalId.isEmpty) return;

    final aiProvider = context.read<FiscalAiProvider>();
    await aiProvider.runAction(
      fiscalId: fiscalId,
      toolName: 'register_timeline_event',
      context: _buildAiContext(context),
      confirmed: true,
      arguments: {
        'title': resolution.diagnosis.isNotEmpty
            ? resolution.diagnosis
            : 'Diagnostico da IA',
        'description': [
          if (resolution.recommendedMessage.isNotEmpty)
            resolution.recommendedMessage,
          if (resolution.immediateSteps.isNotEmpty)
            'Passos: ${resolution.immediateSteps.join(' | ')}',
        ].join('\n'),
        'area': 'ia_fiscal',
        'action': 'diagnostico_registrado',
        'severity': resolution.severity,
        'entity_type': 'fiscal_diagnostic',
        'metadata': {
          'immediate_steps': resolution.immediateSteps,
          'preventive_actions': resolution.preventiveActions,
        },
      },
    );

    if (!mounted) return;
    final result = aiProvider.insight?.actionResult;
    if (result?.isExecuted == true) {
      AppNotif.show(
        context,
        titulo: 'Linha do tempo atualizada',
        mensagem: 'O diagnostico da IA foi salvo no historico operacional.',
        tipo: 'saida',
        cor: AppColors.success,
      );
      await _scrollToSection(_actionResultSectionKey);
    }
  }

  Future<void> _askAboutRecommendation(FiscalAiRecommendation item) async {
    final question = _questionFromRecommendation(item);
    _questionController.text = question;
    _questionController.selection = TextSelection.collapsed(
      offset: _questionController.text.length,
    );
    await _sendQuestion();

    if (!mounted) return;
    await _scrollToSection(_questionSectionKey);
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    if (!mounted) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final refreshedContext = key.currentContext;
    if (refreshedContext == null) return;
    if (!refreshedContext.mounted) return;

    await Scrollable.ensureVisible(
      refreshedContext,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  Future<void> _runQueuedAction(FiscalAiQueuedAction action) async {
    final fiscalId = context.read<AuthProvider>().user?.id;
    if (fiscalId == null || fiscalId.isEmpty) return;

    await context.read<FiscalAiProvider>().runQueuedAction(
      fiscalId: fiscalId,
      action: action,
      fallbackContext: _buildAiContext(context),
    );
  }

  Future<void> _dismissQueuedAction(FiscalAiQueuedAction action) async {
    final fiscalId = context.read<AuthProvider>().user?.id;
    if (fiscalId == null || fiscalId.isEmpty) return;

    await context.read<FiscalAiProvider>().dismissAction(
      fiscalId: fiscalId,
      action: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<FiscalAiProvider>();
    final insight = aiProvider.insight;
    final metrics = _buildAiMetrics(context);
    final displayName = _displayName(context.watch<AuthProvider>().user);
    final isBusy = aiProvider.running || _analisandoMidia;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _runAnalysis,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingMD,
              Dimensions.paddingMD,
              Dimensions.paddingMD,
              Dimensions.paddingLG,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AiDashboardHeader(
                      displayName: displayName,
                      isBusy: isBusy,
                      isTestingExternalAi: _testingExternalAi,
                      onAnalyzeMedia: _analisarMidiaComIa,
                      onTestExternalAi: _testExternalAi,
                      onRefresh: _runAnalysis,
                    ),
                    const SizedBox(height: Dimensions.spacingMD),
                    if (_lastApiTestInsight != null) ...[
                      _AiRuntimeTestNotice(
                        insight: _lastApiTestInsight!,
                        testedAt: _lastApiTestAt,
                        isTesting: _testingExternalAi,
                        onRetest: _testExternalAi,
                      ),
                      const SizedBox(height: Dimensions.spacingMD),
                    ],
                    _OperationStatusCard(
                      metrics: metrics,
                      insight: insight,
                      provider: insight?.provider,
                      source: insight?.source,
                      model: insight?.model,
                      warning: insight?.warning,
                      lastAnalyzedAt: aiProvider.lastAnalyzedAt,
                      actionsCount: aiProvider.actions.length,
                      running: isBusy,
                    ),
                    const SizedBox(height: Dimensions.spacingMD),
                    if (insight?.isLocalSource == true) ...[
                      _AiRuntimeNotice(insight: insight!),
                      const SizedBox(height: Dimensions.spacingMD),
                    ],
                    if (aiProvider.error != null) ...[
                      _InlineError(message: aiProvider.error!),
                      const SizedBox(height: Dimensions.spacingMD),
                    ],
                    if ((aiProvider.loading || aiProvider.running) &&
                        insight == null) ...[
                      const SizedBox(height: 180),
                      const OperationalLoadingState(
                        message: 'Lendo eventos fiscais e contexto do turno...',
                      ),
                      const SizedBox(height: 180),
                    ] else if (insight == null) ...[
                      OperationalEmptyState(
                        icon: Icons.auto_awesome_rounded,
                        title: 'IA Fiscal pronta',
                        message:
                            'Analise o Balcao Fiscal junto com caixas, equipe e alertas do turno.',
                        actionLabel: 'Analisar agora',
                        onAction: _runAnalysis,
                      ),
                    ] else ...[
                      _DashboardTwoColumn(
                        left: _PriorityActionsCard(
                          insight: insight,
                          actions: aiProvider.actions,
                          isRunning: aiProvider.running,
                          onRunPlan: insight.actionPlan.isEmpty
                              ? null
                              : () => _executePlan(insight.actionPlan),
                          onRunQueuedAction: _runQueuedAction,
                          onDismissQueuedAction: _dismissQueuedAction,
                        ),
                        right: _ActiveAlertsCard(
                          risks: insight.risks,
                          isRunning: aiProvider.running,
                          onResolveRisk: _resolveRisk,
                        ),
                      ),
                      const SizedBox(height: Dimensions.spacingMD),
                      if (insight.actionResult.hasMessage ||
                          insight.actionResult.hasArtifact) ...[
                        KeyedSubtree(
                          key: _actionResultSectionKey,
                          child: _ActionResultPanel(
                            result: insight.actionResult,
                          ),
                        ),
                        const SizedBox(height: Dimensions.spacingMD),
                      ],
                      if (insight.resolution.hasDraft) ...[
                        KeyedSubtree(
                          key: _resolutionSectionKey,
                          child: _ResolutionPanel(
                            resolution: insight.resolution,
                            isRunning: aiProvider.running,
                            onRegisterTimeline: () =>
                                _registerResolutionTimeline(insight.resolution),
                          ),
                        ),
                        const SizedBox(height: Dimensions.spacingMD),
                      ],
                      if (insight.recommendations.isNotEmpty) ...[
                        _RecommendationsPanel(
                          recommendations: insight.recommendations,
                          isRunning: aiProvider.running,
                          onAskAboutRecommendation: _askAboutRecommendation,
                        ),
                        const SizedBox(height: Dimensions.spacingMD),
                      ],
                      KeyedSubtree(
                        key: _questionSectionKey,
                        child: _QuestionPanel(
                          controller: _questionController,
                          isRunning: aiProvider.running,
                          chatAnswer: insight.chatAnswer,
                          onSubmit: _sendQuestion,
                        ),
                      ),
                      const SizedBox(height: Dimensions.spacingSM),
                      Center(
                        child: Text(
                          'IA Fiscal pode cometer erros. Valide informacoes criticas.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _buildAiMetrics(BuildContext context) {
    final eventsProvider = context.read<FiscalEventsProvider>();
    final colaboradorProvider = context.read<ColaboradorProvider>();
    final caixaProvider = context.read<CaixaProvider>();
    final alocacaoProvider = context.read<AlocacaoProvider>();
    final cafeProvider = context.read<CafeProvider>();
    final entregaProvider = context.read<EntregaProvider>();
    final notaProvider = context.read<NotaProvider>();
    final ocorrenciaProvider = context.read<OcorrenciaProvider>();
    final checklistProvider = context.read<ChecklistProvider>();

    return {
      'eventos_pendentes': eventsProvider.totalPendentes,
      'midias_pendentes': eventsProvider.totalMidiasPendentes,
      'colaboradores_ativos': colaboradorProvider.totalAtivos,
      'caixas_ativos': caixaProvider.totalAtivos,
      'caixas_manutencao': caixaProvider.totalEmManutencao,
      'alocacoes_ativas': alocacaoProvider.quantidadeAtivasAgora,
      'pausas_em_atraso': cafeProvider.totalEmAtraso,
      'entregas_aguardando': entregaProvider.totalSeparadas,
      'lembretes_vencidos': notaProvider.totalLembretesVencidos,
      'ocorrencias_abertas': ocorrenciaProvider.totalAbertas,
      'checklists_pendentes': checklistProvider.templatesPendentesAgora.length,
      'valor_caixa_pendente': eventsProvider.totalCaixaValores,
    };
  }

  Map<String, dynamic> _buildAiContext(BuildContext context) {
    final eventsProvider = context.read<FiscalEventsProvider>();
    final colaboradorProvider = context.read<ColaboradorProvider>();
    final caixaProvider = context.read<CaixaProvider>();
    final alocacaoProvider = context.read<AlocacaoProvider>();
    final metrics = _buildAiMetrics(context);
    final selectedEvents = _selectRelevantEvents(eventsProvider.events);

    final events = selectedEvents.map((event) {
      return {
        'id': event.id,
        'category': event.category,
        'description': _compactText(event.description, 220),
        'employee_name': event.employeeName,
        'colaborador_id': event.colaboradorId,
        'amount': event.amount,
        'raw_message': _compactText(event.rawMessage, 220),
        'event_date': event.eventDate.toIso8601String(),
        'status': event.status,
        'confidence': event.confidence,
        'media_type': event.mediaType,
        'media_transcript': _compactText(event.mediaTranscript, 280),
        'media_summary': _compactText(event.mediaSummary, 180),
        'analysis_status': event.analysisStatus,
        'analysis_error': event.analysisError,
        'needs_review': event.needsReview,
        'caixa_numero': event.caixaNumero,
        'scheduled_time': event.scheduledTime,
        'turno': event.turno,
        'source': event.source,
        'priority': event.priority,
        'notes': _compactText(event.notes, 180),
      };
    }).toList();

    final colaboradores = colaboradorProvider.todosColaboradores.take(80).map((
      colaborador,
    ) {
      return {
        'id': colaborador.id,
        'nome': colaborador.nome,
        'departamento': colaborador.departamento.toJson(),
        'ativo': colaborador.ativo,
        'cargo': colaborador.cargo,
        'observacoes': _compactText(colaborador.observacoes, 120),
      };
    }).toList();

    final caixas = caixaProvider.caixasTodos.take(80).map((caixa) {
      return {
        'id': caixa.id,
        'numero': caixa.numero,
        'nome': caixa.nomeExibicao,
        'tipo': caixa.tipo.toJson(),
        'loja': caixa.loja,
        'localizacao': caixa.localizacao,
        'ativo': caixa.ativo,
        'em_manutencao': caixa.emManutencao,
        'colaborador_alocado_id': caixa.colaboradorAlocadoId,
        'colaborador_alocado_nome': caixa.colaboradorAlocadoNome,
        'observacoes': _compactText(caixa.observacoes, 120),
      };
    }).toList();

    final alocacoes = alocacaoProvider.alocacoes
        .where((alocacao) => alocacao.isAtiva)
        .take(60)
        .map((alocacao) {
          return {
            'id': alocacao.id,
            'colaborador_id': alocacao.colaboradorId,
            'caixa_id': alocacao.caixaId,
            'alocado_em': alocacao.alocadoEm.toIso8601String(),
            'liberado_em': alocacao.liberadoEm?.toIso8601String(),
            'is_ativa': alocacao.isAtiva,
            'duracao_minutos': alocacao.duracaoMinutos,
            'intervalo_marcado_feito': alocacao.intervaloMarcadoFeito,
          };
        })
        .toList();

    return {
      'generated_at': DateTime.now().toIso8601String(),
      'context_policy': {
        'mode': 'compact',
        'fiscal_events_total': eventsProvider.events.length,
        'fiscal_events_included': events.length,
        'event_limit': 45,
        'text_fields_truncated': true,
      },
      'metrics': metrics,
      'contagem_por_categoria': eventsProvider.contagemPorCategoria,
      'fiscal_events': events,
      'colaboradores': colaboradores,
      'caixas': caixas,
      'alocacoes': alocacoes,
    };
  }

  List<dynamic> _selectRelevantEvents(List<dynamic> events) {
    final selected = <dynamic>[];
    final selectedIds = <int>{};

    void add(dynamic event) {
      if (selected.length >= 45) return;
      final id = event.id as int;
      if (selectedIds.add(id)) selected.add(event);
    }

    for (final event in events.where(_isPriorityEvent)) {
      add(event);
    }
    for (final event in events.where((event) => event.status == 'pending')) {
      add(event);
    }
    for (final event in events) {
      add(event);
    }

    return selected;
  }

  bool _isPriorityEvent(dynamic event) {
    return event.status == 'pending' ||
        event.priority == 'alta' ||
        event.priority == 'critica' ||
        event.needsReview == true ||
        event.analysisStatus == 'needs_review' ||
        event.analysisStatus == 'needs_file' ||
        event.category == 'caixa' ||
        event.category == 'problema_operacional';
  }

  String? _compactText(String? value, int maxLength) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= maxLength) return normalized;
    return '${normalized.substring(0, maxLength).trim()}...';
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      tint: AppColors.danger,
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: Dimensions.spacingSM),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiDashboardHeader extends StatelessWidget {
  final String displayName;
  final bool isBusy;
  final bool isTestingExternalAi;
  final VoidCallback onAnalyzeMedia;
  final VoidCallback onTestExternalAi;
  final VoidCallback onRefresh;

  const _AiDashboardHeader({
    required this.displayName,
    required this.isBusy,
    required this.isTestingExternalAi,
    required this.onAnalyzeMedia,
    required this.onTestExternalAi,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final titleBlock = Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(Dimensions.radiusLG),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: Dimensions.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ola, $displayName!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h2.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatHeaderDate(DateTime.now()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final actions = Wrap(
          spacing: Dimensions.spacingSM,
          runSpacing: Dimensions.spacingXS,
          alignment: compact ? WrapAlignment.start : WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: isBusy ? null : onAnalyzeMedia,
              icon: isBusy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Analisar midia'),
            ),
            OutlinedButton.icon(
              onPressed: isBusy || isTestingExternalAi
                  ? null
                  : onTestExternalAi,
              icon: isTestingExternalAi
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.network_check_rounded, size: 18),
              label: const Text('Testar IA'),
            ),
            FilledButton.icon(
              onPressed: isBusy ? null : onRefresh,
              icon: isBusy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Atualizar'),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock,
              const SizedBox(height: Dimensions.spacingMD),
              actions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: Dimensions.spacingMD),
            actions,
          ],
        );
      },
    );
  }
}

class _OperationStatusCard extends StatelessWidget {
  final Map<String, dynamic> metrics;
  final FiscalAiInsight? insight;
  final String? provider;
  final String? source;
  final String? model;
  final String? warning;
  final DateTime? lastAnalyzedAt;
  final int actionsCount;
  final bool running;

  const _OperationStatusCard({
    required this.metrics,
    required this.insight,
    required this.provider,
    required this.source,
    required this.model,
    required this.warning,
    required this.lastAnalyzedAt,
    required this.actionsCount,
    required this.running,
  });

  @override
  Widget build(BuildContext context) {
    final severity = insight?.overallSeverity ?? _severityFromMetrics(metrics);
    final isLocalAi = _isLocalAi(insight, provider, source);
    final color = running
        ? AppColors.info
        : isLocalAi
        ? AppColors.statusAtencao
        : _severityColor(severity);
    final confidence = _analysisConfidence(insight);
    final sources = _sourceChecks(metrics, insight: insight);

    return AppSurface(
      elevated: true,
      padding: const EdgeInsets.all(Dimensions.paddingLG),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 780;
          final status = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  running
                      ? Icons.sync_rounded
                      : isLocalAi
                      ? Icons.cloud_off_rounded
                      : severity == 'normal'
                      ? Icons.check_rounded
                      : Icons.priority_high_rounded,
                  color: color,
                  size: 44,
                ),
              ),
              const SizedBox(width: Dimensions.spacingLG),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      running
                          ? 'Analisando operacao'
                          : isLocalAi
                          ? 'IA externa indisponivel'
                          : _operationTitle(severity, metrics),
                      style: AppTextStyles.h2.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _operationDescription(metrics, insight),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: Dimensions.spacingSM),
                    Wrap(
                      spacing: Dimensions.spacingXS,
                      runSpacing: Dimensions.spacingXS,
                      children: [
                        StatusPill(
                          icon: _sourceIcon(source),
                          label: _sourceLabel(source),
                          color: _sourceColor(source),
                          compact: true,
                        ),
                        StatusPill(
                          icon: Icons.memory_rounded,
                          label: _providerLabel(provider, model),
                          color: AppColors.info,
                          compact: true,
                        ),
                        StatusPill(
                          icon: Icons.schedule_rounded,
                          label: _formatAiTimestamp(lastAnalyzedAt),
                          color: AppColors.blueGrey,
                          compact: true,
                        ),
                        if (actionsCount > 0)
                          StatusPill(
                            icon: Icons.playlist_add_check_circle_rounded,
                            label:
                                '$actionsCount acao${actionsCount == 1 ? '' : 'es'}',
                            color: AppColors.statusAtencao,
                            compact: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLocalAi
                    ? 'Estado do agente'
                    : confidence == null
                    ? 'Confianca indisponivel'
                    : 'Confianca da acao',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Dimensions.spacingXS),
              Text(
                isLocalAi
                    ? 'Fallback'
                    : confidence == null
                    ? '--'
                    : '${(confidence * 100).round()}%',
                style: AppTextStyles.h2.copyWith(
                  color: isLocalAi
                      ? AppColors.statusAtencao
                      : confidence == null
                      ? AppColors.textSecondary
                      : color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: Dimensions.spacingXS),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: isLocalAi ? 1 : confidence ?? 0,
                  backgroundColor: AppColors.divider,
                  color: isLocalAi
                      ? AppColors.statusAtencao
                      : confidence == null
                      ? AppColors.blueGrey
                      : color,
                ),
              ),
              const SizedBox(height: Dimensions.spacingMD),
              Text(
                'Fontes analisadas',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Dimensions.spacingXS),
              ...sources.map(
                (source) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        source.enabled
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: source.enabled
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          source.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: source.enabled
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (warning?.trim().isNotEmpty == true) ...[
                const SizedBox(height: Dimensions.spacingXS),
                Text(
                  warning!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                status,
                const SizedBox(height: Dimensions.spacingLG),
                details,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 5, child: status),
              Container(width: 1, height: 120, color: AppColors.divider),
              const SizedBox(width: Dimensions.spacingLG),
              Expanded(flex: 2, child: details),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _DashboardTwoColumn({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(
            children: [
              left,
              const SizedBox(height: Dimensions.spacingMD),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: Dimensions.spacingMD),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _AiRuntimeNotice extends StatelessWidget {
  final FiscalAiInsight insight;

  const _AiRuntimeNotice({required this.insight});

  @override
  Widget build(BuildContext context) {
    final warning = insight.warning?.trim();
    final message = warning == null || warning.isEmpty
        ? 'A resposta veio da leitura local do app.'
        : warning;

    return AppSurface(
      tint: AppColors.statusAtencao,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OperationalSectionHeader(
            icon: Icons.cloud_off_rounded,
            title: 'IA generativa fora do ar',
          ),
          const SizedBox(height: Dimensions.spacingSM),
          Text(
            'O app carregou o contexto operacional do Supabase, mas a resposta nao veio das APIs externas. Neste momento a tela esta usando fallback local para resumir dados e manter a operacao visivel.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: Dimensions.spacingSM),
          _RuntimeStatusLine(
            icon: Icons.storage_rounded,
            label: 'Dados do app',
            value: 'Carregados',
            color: AppColors.success,
          ),
          _RuntimeStatusLine(
            icon: Icons.auto_awesome_rounded,
            label: 'OpenAI / Gemini / Anthropic',
            value: 'Indisponivel',
            color: AppColors.statusAtencao,
          ),
          _RuntimeStatusLine(
            icon: Icons.info_outline_rounded,
            label: 'Motivo',
            value: message,
            color: AppColors.statusAtencao,
          ),
        ],
      ),
    );
  }
}

class _AiRuntimeTestNotice extends StatelessWidget {
  final FiscalAiInsight insight;
  final DateTime? testedAt;
  final bool isTesting;
  final VoidCallback onRetest;

  const _AiRuntimeTestNotice({
    required this.insight,
    required this.testedAt,
    required this.isTesting,
    required this.onRetest,
  });

  @override
  Widget build(BuildContext context) {
    final ok = _isExternalAiResult(insight);
    final color = ok ? AppColors.success : AppColors.statusAtencao;
    final warning = insight.warning?.trim();

    return AppSurface(
      tint: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Dimensions.radiusMD),
            ),
            child: Icon(
              ok ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: Dimensions.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok ? 'Teste da IA: ativa' : 'Teste da IA: fallback',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ok
                      ? 'Resposta recebida por ${_providerLabel(insight.provider, insight.model)} em ${_formatAiTimestamp(testedAt)}.'
                      : (warning == null || warning.isEmpty
                            ? 'A chamada de teste ainda voltou pela leitura local.'
                            : warning),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: Dimensions.spacingXS),
                Wrap(
                  spacing: Dimensions.spacingXS,
                  runSpacing: Dimensions.spacingXS,
                  children: [
                    StatusPill(
                      icon: _sourceIcon(insight.source),
                      label: _sourceLabel(insight.source),
                      color: _sourceColor(insight.source),
                      compact: true,
                    ),
                    StatusPill(
                      icon: Icons.schedule_rounded,
                      label: _formatAiTimestamp(testedAt),
                      color: AppColors.blueGrey,
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Dimensions.spacingSM),
          IconButton(
            tooltip: 'Testar novamente',
            onPressed: isTesting ? null : onRetest,
            icon: isTesting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _RuntimeStatusLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _RuntimeStatusLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.spacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: Dimensions.spacingSM),
          SizedBox(
            width: 126,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityActionsCard extends StatelessWidget {
  final FiscalAiInsight insight;
  final List<FiscalAiQueuedAction> actions;
  final bool isRunning;
  final VoidCallback? onRunPlan;
  final Future<void> Function(FiscalAiQueuedAction action) onRunQueuedAction;
  final Future<void> Function(FiscalAiQueuedAction action)
  onDismissQueuedAction;

  const _PriorityActionsCard({
    required this.insight,
    required this.actions,
    required this.isRunning,
    required this.onRunPlan,
    required this.onRunQueuedAction,
    required this.onDismissQueuedAction,
  });

  @override
  Widget build(BuildContext context) {
    final items = actions.take(3).toList();
    final total = actions.length + (insight.actionPlan.isEmpty ? 0 : 1);

    return AppSurface(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OperationalSectionHeader(
            icon: Icons.track_changes_rounded,
            title: 'Acoes prioritarias',
            trailing: StatusPill(
              label: '$total pendencia${total == 1 ? '' : 's'}',
              color: AppColors.success,
              compact: true,
            ),
          ),
          const SizedBox(height: Dimensions.spacingSM),
          if (!insight.actionPlan.isEmpty)
            _PriorityPlanTile(
              number: 1,
              insight: insight,
              isRunning: isRunning,
              onRunPlan: onRunPlan,
            ),
          ...items.asMap().entries.map(
            (entry) => _PriorityQueuedTile(
              number: entry.key + (insight.actionPlan.isEmpty ? 1 : 2),
              action: entry.value,
              isRunning: isRunning,
              onRun: () => onRunQueuedAction(entry.value),
              onDismiss: () => onDismissQueuedAction(entry.value),
            ),
          ),
          if (insight.actionPlan.isEmpty && items.isEmpty)
            _EmptyDashboardLine(
              icon: Icons.check_circle_outline_rounded,
              title: insight.nextAction.title,
              message: insight.nextAction.description,
              color: AppColors.success,
            ),
        ],
      ),
    );
  }
}

class _PriorityPlanTile extends StatelessWidget {
  final int number;
  final FiscalAiInsight insight;
  final bool isRunning;
  final VoidCallback? onRunPlan;

  const _PriorityPlanTile({
    required this.number,
    required this.insight,
    required this.isRunning,
    required this.onRunPlan,
  });

  @override
  Widget build(BuildContext context) {
    final confidence = insight.actionPlan.confidence;
    return _DashboardListTile(
      leading: _NumberBadge(number: number, color: AppColors.success),
      title: insight.nextAction.title,
      subtitle: insight.nextAction.description,
      trailing: Wrap(
        spacing: Dimensions.spacingXS,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (confidence > 0)
            StatusPill(
              label: '${(confidence * 100).round()}%',
              color: AppColors.info,
              compact: true,
            ),
          if (onRunPlan != null)
            FilledButton(
              onPressed: isRunning ? null : onRunPlan,
              child: Text(
                insight.actionPlan.confirmationRequired
                    ? 'Confirmar'
                    : 'Executar',
              ),
            ),
        ],
      ),
    );
  }
}

class _PriorityQueuedTile extends StatelessWidget {
  final int number;
  final FiscalAiQueuedAction action;
  final bool isRunning;
  final VoidCallback onRun;
  final VoidCallback onDismiss;

  const _PriorityQueuedTile({
    required this.number,
    required this.action,
    required this.isRunning,
    required this.onRun,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = action.confirmationRequired
        ? AppColors.statusAtencao
        : AppColors.info;
    return _DashboardListTile(
      leading: _NumberBadge(number: number, color: color),
      title: action.title,
      subtitle: action.description,
      trailing: Wrap(
        spacing: Dimensions.spacingXS,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StatusPill(
            label: _actionStatusLabel(action.status),
            color: color,
            compact: true,
          ),
          IconButton(
            tooltip: 'Executar',
            onPressed: isRunning ? null : onRun,
            icon: const Icon(Icons.play_arrow_rounded),
          ),
          IconButton(
            tooltip: 'Descartar',
            onPressed: isRunning ? null : onDismiss,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _ActiveAlertsCard extends StatelessWidget {
  final List<FiscalAiRisk> risks;
  final bool isRunning;
  final Future<void> Function(FiscalAiRisk risk) onResolveRisk;

  const _ActiveAlertsCard({
    required this.risks,
    required this.isRunning,
    required this.onResolveRisk,
  });

  @override
  Widget build(BuildContext context) {
    final critical = risks
        .where((risk) => risk.severity == 'critico' || risk.severity == 'alto')
        .length;

    return AppSurface(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OperationalSectionHeader(
            icon: Icons.alarm_rounded,
            title: 'Alertas ativos',
            trailing: StatusPill(
              label: critical > 0
                  ? '$critical critico${critical == 1 ? '' : 's'}'
                  : '${risks.length} alerta${risks.length == 1 ? '' : 's'}',
              color: critical > 0 ? AppColors.danger : AppColors.info,
              compact: true,
            ),
          ),
          const SizedBox(height: Dimensions.spacingSM),
          if (risks.isEmpty)
            const _EmptyDashboardLine(
              icon: Icons.check_circle_outline_rounded,
              title: 'Sem alertas ativos',
              message: 'A IA nao destacou riscos no contexto atual.',
              color: Color(0xFF0F766E),
            )
          else
            ...risks
                .take(4)
                .map(
                  (risk) => _AlertRiskTile(
                    risk: risk,
                    isRunning: isRunning,
                    onResolve: () => onResolveRisk(risk),
                  ),
                ),
        ],
      ),
    );
  }
}

class _AlertRiskTile extends StatelessWidget {
  final FiscalAiRisk risk;
  final bool isRunning;
  final VoidCallback onResolve;

  const _AlertRiskTile({
    required this.risk,
    required this.isRunning,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(risk.severity);
    return _DashboardListTile(
      tint: color,
      leading: Icon(Icons.warning_amber_rounded, color: color),
      title: _riskTitle(risk),
      subtitle: _riskSubtitle(risk),
      trailing: Wrap(
        spacing: Dimensions.spacingXS,
        runSpacing: Dimensions.spacingXS,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StatusPill(
            label: _severityLabel(risk.severity),
            color: color,
            compact: true,
          ),
          OutlinedButton.icon(
            onPressed: isRunning ? null : onResolve,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.task_alt_rounded, size: 16),
            label: const Text('Resolver'),
          ),
        ],
      ),
    );
  }
}

class _DashboardListTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? tint;

  const _DashboardListTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSM),
      padding: const EdgeInsets.all(Dimensions.paddingSM),
      decoration: AppStyles.softTile(
        context: context,
        tint: tint ?? AppColors.blueGrey,
        radius: Dimensions.radiusMD,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: Dimensions.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'Acao da IA' : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          if (trailing == null) return content;
          final trailingMaxWidth = compact
              ? constraints.maxWidth
              : constraints.maxWidth * 0.42;
          final trailingBox = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: trailingMaxWidth),
            child: trailing!,
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                content,
                const SizedBox(height: Dimensions.spacingSM),
                Align(alignment: Alignment.centerRight, child: trailingBox),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: content),
              const SizedBox(width: Dimensions.spacingSM),
              trailingBox,
            ],
          );
        },
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final int number;
  final Color color;

  const _NumberBadge({required this.number, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        '$number',
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyDashboardLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _EmptyDashboardLine({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardListTile(
      leading: Icon(icon, color: color),
      title: title,
      subtitle: message,
      tint: color,
    );
  }
}

class _SourceCheck {
  final String label;
  final bool enabled;

  const _SourceCheck(this.label, this.enabled);
}

class _QuestionPanel extends StatelessWidget {
  final TextEditingController controller;
  final bool isRunning;
  final String chatAnswer;
  final VoidCallback onSubmit;

  const _QuestionPanel({
    required this.controller,
    required this.isRunning,
    required this.chatAnswer,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OperationalSectionHeader(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Perguntar para a IA',
          ),
          const SizedBox(height: Dimensions.spacingSM),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!isRunning) onSubmit();
                  },
                  decoration: const InputDecoration(
                    hintText: 'Ex: o que precisa ser resolvido antes do turno?',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.spacingSM),
              IconButton.filled(
                tooltip: 'Enviar pergunta',
                onPressed: isRunning ? null : onSubmit,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spacingSM),
          Wrap(
            spacing: Dimensions.spacingXS,
            runSpacing: Dimensions.spacingXS,
            children: [
              _QuickQuestionChip(
                label: 'Caixas sem operador',
                question: 'Quais caixas estao sem operador agora?',
                controller: controller,
                isRunning: isRunning,
                onSubmit: onSubmit,
              ),
              _QuickQuestionChip(
                label: 'Pendencias criticas',
                question:
                    'Quais pendencias criticas preciso resolver primeiro?',
                controller: controller,
                isRunning: isRunning,
                onSubmit: onSubmit,
              ),
              _QuickQuestionChip(
                label: 'Diferencas de valor',
                question: 'Existe alguma diferenca de valor pendente?',
                controller: controller,
                isRunning: isRunning,
                onSubmit: onSubmit,
              ),
              _QuickQuestionChip(
                label: 'Resumo do dia',
                question: 'Faca um resumo operacional do dia.',
                controller: controller,
                isRunning: isRunning,
                onSubmit: onSubmit,
              ),
            ],
          ),
          if (chatAnswer.trim().isNotEmpty) ...[
            const SizedBox(height: Dimensions.spacingSM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSM),
              decoration: AppStyles.softTile(
                context: context,
                tint: AppColors.primary,
                radius: Dimensions.radiusMD,
              ),
              child: Text(
                chatAnswer,
                style: AppTextStyles.body.copyWith(height: 1.35),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickQuestionChip extends StatelessWidget {
  final String label;
  final String question;
  final TextEditingController controller;
  final bool isRunning;
  final VoidCallback onSubmit;

  const _QuickQuestionChip({
    required this.label,
    required this.question,
    required this.controller,
    required this.isRunning,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isRunning
          ? null
          : () {
              controller.text = question;
              controller.selection = TextSelection.collapsed(
                offset: controller.text.length,
              );
              onSubmit();
            },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: Text(label),
    );
  }
}

class _ActionResultPanel extends StatelessWidget {
  final FiscalAiActionResult result;

  const _ActionResultPanel({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.isExecuted ? AppColors.success : AppColors.info;

    return AppSurface(
      tint: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OperationalSectionHeader(
            icon: result.isExecuted
                ? Icons.task_alt_rounded
                : Icons.pending_actions_rounded,
            title: result.title.isEmpty ? 'Resultado da acao' : result.title,
            trailing: StatusPill(
              label: _actionStatusLabel(result.status),
              color: color,
              compact: true,
            ),
          ),
          if (result.message.isNotEmpty) ...[
            const SizedBox(height: Dimensions.spacingSM),
            Text(result.message, style: AppTextStyles.body),
          ],
          if (result.hasArtifact) ...[
            const SizedBox(height: Dimensions.spacingSM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSM),
              decoration: AppStyles.softTile(
                context: context,
                tint: AppColors.blueGrey,
                radius: Dimensions.radiusMD,
              ),
              child: SelectableText(
                result.artifactMarkdown!,
                style: AppTextStyles.caption.copyWith(
                  fontFamily: 'monospace',
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResolutionPanel extends StatelessWidget {
  final FiscalAiResolution resolution;
  final bool isRunning;
  final VoidCallback? onRegisterTimeline;

  const _ResolutionPanel({
    required this.resolution,
    required this.isRunning,
    required this.onRegisterTimeline,
  });

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(resolution.severity);
    return AppSurface(
      tint: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OperationalSectionHeader(
            icon: Icons.psychology_alt_rounded,
            title: 'Diagnostico da IA',
            trailing: StatusPill(
              label: _severityLabel(resolution.severity),
              color: color,
              compact: true,
            ),
          ),
          const SizedBox(height: Dimensions.spacingSM),
          if (resolution.diagnosis.trim().isNotEmpty)
            _InsightTextBlock(
              icon: Icons.manage_search_rounded,
              label: 'Leitura',
              text: resolution.diagnosis,
              color: color,
            ),
          if (resolution.immediateSteps.isNotEmpty) ...[
            const SizedBox(height: Dimensions.spacingSM),
            Text(
              'Fazer agora',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: Dimensions.spacingXS),
            ...resolution.immediateSteps.asMap().entries.map(
              (entry) => _NumberedStepLine(
                number: entry.key + 1,
                text: entry.value,
                color: color,
              ),
            ),
          ],
          if (resolution.recommendedMessage.isNotEmpty) ...[
            const SizedBox(height: Dimensions.spacingSM),
            _InsightTextBlock(
              icon: Icons.edit_note_rounded,
              label: 'Tratativa sugerida',
              text: resolution.recommendedMessage,
              color: AppColors.info,
            ),
          ],
          const SizedBox(height: Dimensions.spacingSM),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: isRunning ? null : onRegisterTimeline,
              icon: const Icon(Icons.timeline_rounded, size: 16),
              label: const Text('Registrar na linha do tempo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationsPanel extends StatelessWidget {
  final List<FiscalAiRecommendation> recommendations;
  final bool isRunning;
  final Future<void> Function(FiscalAiRecommendation item)
  onAskAboutRecommendation;

  const _RecommendationsPanel({
    required this.recommendations,
    required this.isRunning,
    required this.onAskAboutRecommendation,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OperationalSectionHeader(
            icon: Icons.playlist_add_check_rounded,
            title: 'Sugestoes extras',
          ),
          const SizedBox(height: Dimensions.spacingSM),
          if (recommendations.isEmpty)
            Text(
              'Sem sugestoes extras nesta analise.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...recommendations.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.spacingXS),
                child: _RecommendationTile(
                  item: item,
                  isRunning: isRunning,
                  onTap: () => onAskAboutRecommendation(item),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  final FiscalAiRecommendation item;
  final bool isRunning;
  final VoidCallback onTap;

  const _RecommendationTile({
    required this.item,
    required this.isRunning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(item.priority);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isRunning ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: AppStyles.softTile(
                context: context,
                tint: color,
                radius: Dimensions.radiusSM,
              ),
              child: Icon(Icons.arrow_forward_rounded, color: color, size: 16),
            ),
            const SizedBox(width: Dimensions.spacingSM),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.spacingSM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: Dimensions.spacingXS,
                        runSpacing: Dimensions.spacingXS,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            item.title.isEmpty ? 'Acao sugerida' : item.title,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          StatusPill(
                            label: 'prioridade ${item.priority}',
                            color: color,
                            compact: true,
                          ),
                        ],
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.description,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (item.owner.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Responsavel: ${item.owner}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: isRunning ? null : onTap,
                          icon: const Icon(
                            Icons.question_answer_rounded,
                            size: 16,
                          ),
                          label: const Text('Perguntar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightTextBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  final Color color;

  const _InsightTextBlock({
    required this.icon,
    required this.label,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSM),
      decoration: AppStyles.softTile(
        context: context,
        tint: color,
        radius: Dimensions.radiusMD,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: Dimensions.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberedStepLine extends StatelessWidget {
  final int number;
  final String text;
  final Color color;

  const _NumberedStepLine({
    required this.number,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.spacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(Dimensions.radiusSM),
            ),
            child: Text(
              '$number',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: Dimensions.spacingSM),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _displayName(dynamic user) {
  try {
    final metadata = user?.userMetadata;
    if (metadata is Map) {
      for (final key in const ['nome', 'name', 'full_name']) {
        final value = metadata[key]?.toString().trim();
        if (value != null && value.isNotEmpty) {
          return value.split(RegExp(r'\s+')).first;
        }
      }
    }

    final email = user?.email?.toString().trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
  } catch (_) {
    return 'Fiscal';
  }
  return 'Fiscal';
}

String _formatHeaderDate(DateTime value) {
  final local = value.toLocal();
  const weekdays = [
    'segunda-feira',
    'terca-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sabado',
    'domingo',
  ];
  const months = [
    'janeiro',
    'fevereiro',
    'marco',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${weekdays[local.weekday - 1]}, $day de ${months[local.month - 1]} de ${local.year} - $hour:$minute';
}

int _metricInt(Map<String, dynamic> metrics, String key) {
  final value = metrics[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.replaceAll(',', '.')) ?? 0;
  return 0;
}

double _metricDouble(Map<String, dynamic> metrics, String key) {
  final value = metrics[key];
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  return 0;
}

String _severityFromMetrics(Map<String, dynamic> metrics) {
  if (_metricInt(metrics, 'ocorrencias_abertas') > 0 ||
      _metricDouble(metrics, 'valor_caixa_pendente') >= 100) {
    return 'alto';
  }

  final attention =
      _metricInt(metrics, 'eventos_pendentes') +
      _metricInt(metrics, 'midias_pendentes') +
      _metricInt(metrics, 'caixas_manutencao') +
      _metricInt(metrics, 'pausas_em_atraso') +
      _metricInt(metrics, 'lembretes_vencidos') +
      _metricInt(metrics, 'checklists_pendentes');
  return attention > 0 ? 'medio' : 'normal';
}

double? _analysisConfidence(FiscalAiInsight? insight) {
  if (insight == null || insight.actionPlan.confidence <= 0) return null;
  final confidence = insight.actionPlan.confidence;
  if (confidence > 1) return 1;
  return confidence;
}

List<_SourceCheck> _sourceChecks(
  Map<String, dynamic> metrics, {
  FiscalAiInsight? insight,
}) {
  final summary = insight?.summary.toLowerCase() ?? '';
  final hasScaleContext =
      summary.contains('escala') ||
      summary.contains('colaborador') ||
      summary.contains('equipe') ||
      _metricInt(metrics, 'colaboradores_ativos') > 0;
  final hasCashContext =
      summary.contains('caixa') ||
      summary.contains('aloc') ||
      _metricInt(metrics, 'caixas_ativos') > 0 ||
      _metricInt(metrics, 'caixas_manutencao') > 0 ||
      _metricInt(metrics, 'alocacoes_ativas') > 0;
  final hasDeliveryPauseContext =
      summary.contains('entrega') ||
      summary.contains('pausa') ||
      summary.contains('cafe') ||
      summary.contains('intervalo') ||
      _metricInt(metrics, 'entregas_aguardando') > 0 ||
      _metricInt(metrics, 'pausas_em_atraso') > 0;
  final hasTimelineContext =
      summary.contains('balcao') ||
      summary.contains('timeline') ||
      summary.contains('pendencia') ||
      _metricInt(metrics, 'eventos_pendentes') > 0 ||
      _metricInt(metrics, 'midias_pendentes') > 0 ||
      _metricDouble(metrics, 'valor_caixa_pendente') > 0;

  return [
    _SourceCheck('Escala / equipe', hasScaleContext),
    _SourceCheck('Caixas / alocacoes', hasCashContext),
    _SourceCheck('Entregas / pausas', hasDeliveryPauseContext),
    _SourceCheck('Balcao / timeline', hasTimelineContext),
  ];
}

String _operationTitle(String severity, Map<String, dynamic> metrics) {
  switch (severity) {
    case 'critico':
      return 'Acao imediata';
    case 'alto':
      return 'Atencao necessaria';
    case 'medio':
      return 'Pontos em acompanhamento';
    default:
      final caixas = _metricInt(metrics, 'caixas_ativos');
      return caixas > 0 ? 'Operacao monitorada' : 'Aguardando contexto';
  }
}

String _operationDescription(
  Map<String, dynamic> metrics,
  FiscalAiInsight? insight,
) {
  final summary = insight?.summary.trim();
  if (insight?.isLocalSource == true) {
    final warning = insight?.warning?.trim();
    final reason = warning == null || warning.isEmpty
        ? 'A IA externa nao respondeu.'
        : warning;
    if (summary != null && summary.isNotEmpty) {
      return '$reason Leitura local: $summary';
    }
    return '$reason Mostrando apenas leitura local do contexto carregado.';
  }

  if (summary != null && summary.isNotEmpty) return summary;

  final pending =
      _metricInt(metrics, 'eventos_pendentes') +
      _metricInt(metrics, 'midias_pendentes') +
      _metricInt(metrics, 'ocorrencias_abertas') +
      _metricInt(metrics, 'checklists_pendentes');
  if (pending > 0) {
    return '$pending pendencia${pending == 1 ? '' : 's'} no contexto atual. Priorize o que exige intervencao do fiscal.';
  }

  final caixas = _metricInt(metrics, 'caixas_ativos');
  final colaboradores = _metricInt(metrics, 'colaboradores_ativos');
  if (caixas > 0 || colaboradores > 0) {
    return 'Dados reais carregados de caixas, equipe e movimentos recentes para apoiar a fiscalizacao.';
  }

  return 'Execute uma analise para carregar o panorama fiscal do turno.';
}

String _formatAiTimestamp(DateTime? value) {
  if (value == null) return 'Sem analise';
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}

String _providerLabel(String? provider, String? model) {
  final providerText = switch (provider) {
    'openai' => 'OpenAI',
    'anthropic' => 'Anthropic',
    'gemini' => 'Gemini',
    'fallback' => 'Fallback local',
    'local' => 'Fallback local',
    null || '' => 'Aguardando IA',
    _ => provider,
  };
  if (model == null || model.trim().isEmpty) return providerText;
  return '$providerText / ${model.trim()}';
}

bool _isLocalAi(FiscalAiInsight? insight, String? provider, String? source) {
  if (insight?.isLocalSource == true) return true;
  if (provider == 'local' || provider == 'fallback') return true;
  return switch (source) {
    'local_edge' ||
    'local_offline' ||
    'sem_conexao' ||
    'timeout_edge' ||
    'erro_edge' ||
    'resposta_vazia' => true,
    _ => false,
  };
}

bool _isExternalAiResult(FiscalAiInsight insight) {
  final provider = insight.provider.toLowerCase();
  final source = insight.source.toLowerCase();
  return provider == 'openai' ||
      provider == 'gemini' ||
      provider == 'anthropic' ||
      source == 'ia_completa' ||
      source == 'ia_mini' ||
      source == 'ia_gemini' ||
      source == 'ia_gemini_lite' ||
      source == 'ia_anthropic';
}

String _sourceLabel(String? source) {
  return switch (source) {
    'ia_completa' => 'IA completa',
    'ia_mini' => 'IA resumida',
    'ia_gemini' => 'Gemini',
    'ia_gemini_lite' => 'Gemini Lite',
    'ia_anthropic' => 'Anthropic',
    'local_edge' => 'Fallback local',
    'local_offline' => 'Fallback local',
    'sem_conexao' => 'Sem conexao',
    'timeout_edge' => 'Fallback local',
    'erro_edge' => 'Fallback local',
    'resposta_vazia' => 'Fallback local',
    null || '' => 'Fonte pendente',
    _ => source,
  };
}

Color _sourceColor(String? source) {
  return switch (source) {
    'ia_completa' => AppColors.success,
    'ia_mini' => AppColors.info,
    'ia_gemini' || 'ia_gemini_lite' => AppColors.teal,
    'ia_anthropic' => AppColors.deepPurple,
    'local_edge' ||
    'local_offline' ||
    'sem_conexao' ||
    'timeout_edge' ||
    'erro_edge' ||
    'resposta_vazia' => AppColors.statusAtencao,
    _ => AppColors.blueGrey,
  };
}

IconData _sourceIcon(String? source) {
  return switch (source) {
    'ia_completa' => Icons.check_circle_rounded,
    'ia_mini' => Icons.compress_rounded,
    'ia_gemini' || 'ia_gemini_lite' => Icons.auto_awesome_rounded,
    'ia_anthropic' => Icons.psychology_alt_rounded,
    'local_edge' || 'local_offline' => Icons.cloud_off_rounded,
    'sem_conexao' => Icons.wifi_off_rounded,
    'timeout_edge' => Icons.timer_off_rounded,
    'erro_edge' || 'resposta_vazia' => Icons.info_outline_rounded,
    _ => Icons.route_rounded,
  };
}

String _actionStatusLabel(String status) {
  switch (status) {
    case 'pending_approval':
      return 'Aguardando aprovacao';
    case 'pending_confirmation':
      return 'Confirmacao';
    case 'ready':
      return 'Pronta';
    case 'executed':
      return 'Executada';
    case 'dismissed':
      return 'Descartada';
    case 'failed':
      return 'Falhou';
    case 'blocked':
      return 'Bloqueada';
    case 'suggested':
      return 'Sugerida';
    case 'none':
      return 'Sem acao';
    default:
      return status;
  }
}

Color _severityColor(String severity) {
  switch (severity) {
    case 'critico':
      return AppColors.danger;
    case 'alto':
      return AppColors.statusAtencao;
    case 'medio':
      return AppColors.info;
    default:
      return AppColors.success;
  }
}

String _severityLabel(String severity) {
  switch (severity) {
    case 'critico':
      return 'Critico';
    case 'alto':
      return 'Alto';
    case 'medio':
      return 'Medio';
    default:
      return 'Normal';
  }
}

String _questionFromRecommendation(FiscalAiRecommendation item) {
  final title = item.title.trim().isEmpty ? 'esta sugestao' : item.title.trim();
  final description = item.description.trim();
  final owner = item.owner.trim();
  final buffer = StringBuffer()
    ..write('Explique como executar a sugestao "$title" no contexto atual');

  if (description.isNotEmpty) {
    buffer.write('. Detalhe da sugestao: $description');
  }
  if (owner.isNotEmpty) {
    buffer.write('. Responsavel sugerido: $owner');
  }

  buffer.write(
    '. Diga quais dados do app voce usou, o que precisa ser feito agora e se existe alguma acao que voce pode preparar.',
  );
  return buffer.toString();
}

String _riskTitle(FiscalAiRisk risk) {
  final title = risk.title.trim();
  if (title.isNotEmpty) return title;

  final description = _targetText(risk.target, 'description');
  if (description.isNotEmpty) return description;

  return 'Alerta fiscal em acompanhamento';
}

String _riskSubtitle(FiscalAiRisk risk) {
  final options = [
    risk.reason,
    risk.action,
    risk.evidence,
    _targetText(risk.target, 'raw_message'),
    _targetText(risk.target, 'media_summary'),
  ];

  for (final option in options) {
    final text = option.trim();
    if (text.isNotEmpty) return text;
  }

  return 'Toque em Resolver para gerar uma tratativa sugerida pela IA.';
}

String _targetText(Map<String, dynamic> target, String key) {
  final value = target[key];
  if (value == null) return '';
  return value.toString().trim();
}

Color _priorityColor(String priority) {
  switch (priority) {
    case 'alta':
      return AppColors.statusAtencao;
    case 'baixa':
      return AppColors.success;
    default:
      return AppColors.info;
  }
}
