import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_styles.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_notif.dart';
import '../../../data/models/fiscal_ai_models.dart';
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
  bool _bootstrapped = false;
  bool _analisandoMidia = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
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

    await context.read<FiscalAiProvider>().resolve(
          fiscalId: fiscalId,
          risk: risk,
          context: _buildAiContext(context),
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

    return AppPage(
      title: 'IA Fiscal',
      subtitle: 'Leitura do Balcao, caixas e turno',
      icon: Icons.auto_awesome_rounded,
      actions: [
        IconButton(
          tooltip: 'Analisar midia',
          onPressed: aiProvider.running || _analisandoMidia
              ? null
              : _analisarMidiaComIa,
          icon: _analisandoMidia
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file_rounded),
        ),
        IconButton(
          tooltip: 'Analisar agora',
          onPressed: aiProvider.running ? null : _runAnalysis,
          icon: aiProvider.running
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _runAnalysis,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingMD,
              Dimensions.paddingMD,
              Dimensions.paddingMD,
              Dimensions.paddingLG,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MetricsPanel(contextSnapshot: _buildAiContext(context)),
                const SizedBox(height: Dimensions.spacingMD),
                _MediaUploadPanel(
                  isRunning: aiProvider.running || _analisandoMidia,
                  onUpload: _analisarMidiaComIa,
                  onAnalyze: _runAnalysis,
                ),
                const SizedBox(height: Dimensions.spacingMD),
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
                  _InsightSummary(
                    insight: insight,
                    isRunning: aiProvider.running,
                    onRunPlan: insight.actionPlan.isEmpty
                        ? null
                        : () => _executePlan(insight.actionPlan),
                  ),
                  const SizedBox(height: Dimensions.spacingMD),
                  _QuestionPanel(
                    controller: _questionController,
                    isRunning: aiProvider.running,
                    chatAnswer: insight.chatAnswer,
                    onSubmit: _sendQuestion,
                  ),
                  const SizedBox(height: Dimensions.spacingMD),
                  if (insight.actionResult.hasMessage ||
                      insight.actionResult.hasArtifact) ...[
                    _ActionResultPanel(result: insight.actionResult),
                    const SizedBox(height: Dimensions.spacingMD),
                  ],
                  if (insight.resolution.hasDraft) ...[
                    _ResolutionPanel(resolution: insight.resolution),
                    const SizedBox(height: Dimensions.spacingMD),
                  ],
                  _RisksPanel(
                    risks: insight.risks,
                    isRunning: aiProvider.running,
                    onResolveRisk: _resolveRisk,
                  ),
                  const SizedBox(height: Dimensions.spacingMD),
                  _RecommendationsPanel(
                    recommendations: insight.recommendations,
                  ),
                  const SizedBox(height: Dimensions.spacingMD),
                  _QueuedActionsPanel(
                    actions: aiProvider.actions,
                    isRunning: aiProvider.running,
                    onRun: _runQueuedAction,
                    onDismiss: _dismissQueuedAction,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _buildAiContext(BuildContext context) {
    final eventsProvider = context.read<FiscalEventsProvider>();
    final colaboradorProvider = context.read<ColaboradorProvider>();
    final caixaProvider = context.read<CaixaProvider>();
    final alocacaoProvider = context.read<AlocacaoProvider>();
    final cafeProvider = context.read<CafeProvider>();
    final entregaProvider = context.read<EntregaProvider>();
    final notaProvider = context.read<NotaProvider>();
    final ocorrenciaProvider = context.read<OcorrenciaProvider>();
    final checklistProvider = context.read<ChecklistProvider>();

    final events = eventsProvider.events.take(120).map((event) {
      return {
        'id': event.id,
        'category': event.category,
        'description': event.description,
        'employee_name': event.employeeName,
        'colaborador_id': event.colaboradorId,
        'amount': event.amount,
        'sender': event.sender,
        'raw_message': event.rawMessage,
        'event_date': event.eventDate.toIso8601String(),
        'status': event.status,
        'confidence': event.confidence,
        'media_type': event.mediaType,
        'media_transcript': event.mediaTranscript,
        'media_summary': event.mediaSummary,
        'analysis_status': event.analysisStatus,
        'analysis_error': event.analysisError,
        'ai_inbox_item_id': event.aiInboxItemId,
        'needs_review': event.needsReview,
        'caixa_numero': event.caixaNumero,
        'scheduled_time': event.scheduledTime,
        'turno': event.turno,
        'source': event.source,
        'priority': event.priority,
        'notes': event.notes,
      };
    }).toList();

    final colaboradores =
        colaboradorProvider.todosColaboradores.take(120).map((colaborador) {
      return {
        'id': colaborador.id,
        'nome': colaborador.nome,
        'departamento': colaborador.departamento.toJson(),
        'ativo': colaborador.ativo,
        'cargo': colaborador.cargo,
        'observacoes': colaborador.observacoes,
      };
    }).toList();

    final caixas = caixaProvider.caixasTodos.take(120).map((caixa) {
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
        'observacoes': caixa.observacoes,
      };
    }).toList();

    final alocacoes = alocacaoProvider.alocacoes.take(80).map((alocacao) {
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
    }).toList();

    return {
      'generated_at': DateTime.now().toIso8601String(),
      'metrics': {
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
        'checklists_pendentes':
            checklistProvider.templatesPendentesAgora.length,
        'valor_caixa_pendente': eventsProvider.totalCaixaValores,
      },
      'contagem_por_categoria': eventsProvider.contagemPorCategoria,
      'fiscal_events': events,
      'colaboradores': colaboradores,
      'caixas': caixas,
      'alocacoes': alocacoes,
    };
  }
}

class _MetricsPanel extends StatelessWidget {
  final Map<String, dynamic> contextSnapshot;

  const _MetricsPanel({required this.contextSnapshot});

  @override
  Widget build(BuildContext context) {
    final metrics =
        Map<String, dynamic>.from(contextSnapshot['metrics'] as Map? ?? {});
    final valorCaixa = (metrics['valor_caixa_pendente'] as num?) ?? 0;

    return OperationalMetricGrid(
      minTileWidth: 154,
      metrics: [
        OperationalMetricData(
          label: 'Pendencias',
          value: '${metrics['eventos_pendentes'] ?? 0}',
          color: AppColors.statusAtencao,
          icon: Icons.pending_actions_rounded,
        ),
        OperationalMetricData(
          label: 'Midias',
          value: '${metrics['midias_pendentes'] ?? 0}',
          color: AppColors.cyan,
          icon: Icons.perm_media_rounded,
        ),
        OperationalMetricData(
          label: 'Caixas ativos',
          value: '${metrics['caixas_ativos'] ?? 0}',
          color: AppColors.primary,
          icon: Icons.point_of_sale_rounded,
        ),
        OperationalMetricData(
          label: 'Manutencao',
          value: '${metrics['caixas_manutencao'] ?? 0}',
          color: AppColors.danger,
          icon: Icons.build_circle_rounded,
        ),
        OperationalMetricData(
          label: 'Alertas turno',
          value:
              '${(metrics['pausas_em_atraso'] ?? 0) + (metrics['ocorrencias_abertas'] ?? 0) + (metrics['lembretes_vencidos'] ?? 0)}',
          color: AppColors.deepPurple,
          icon: Icons.crisis_alert_rounded,
        ),
        OperationalMetricData(
          label: 'Valor caixa',
          value: 'R\$ ${valorCaixa.toStringAsFixed(2)}',
          color: AppColors.teal,
          icon: Icons.payments_rounded,
        ),
      ],
    );
  }
}

class _MediaUploadPanel extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onUpload;
  final VoidCallback onAnalyze;

  const _MediaUploadPanel({
    required this.isRunning,
    required this.onUpload,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      tint: AppColors.cyan,
      padding: const EdgeInsets.all(Dimensions.paddingSM),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actions = [
            OutlinedButton.icon(
              onPressed: isRunning ? null : onAnalyze,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Atualizar IA'),
            ),
            FilledButton.icon(
              onPressed: isRunning ? null : onUpload,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Analisar midia'),
            ),
          ];

          final icon = Container(
            width: 36,
            height: 36,
            decoration: AppStyles.softTile(
              context: context,
              tint: AppColors.cyan,
              radius: Dimensions.radiusSM,
            ),
            child: Icon(Icons.perm_media_rounded, color: AppColors.cyan),
          );

          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.centerLeft, child: icon),
                const SizedBox(height: Dimensions.spacingSM),
                ...actions.map(
                  (button) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: Dimensions.spacingXS),
                    child: button,
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              icon,
              const Spacer(),
              actions[0],
              const SizedBox(width: Dimensions.spacingSM),
              actions[1],
            ],
          );
        },
      ),
    );
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

class _InsightSummary extends StatelessWidget {
  final FiscalAiInsight insight;
  final bool isRunning;
  final VoidCallback? onRunPlan;

  const _InsightSummary({
    required this.insight,
    required this.isRunning,
    required this.onRunPlan,
  });

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(insight.overallSeverity);

    return AppSurface(
      tint: color,
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: AppStyles.softTile(
                  context: context,
                  tint: color,
                  radius: Dimensions.radiusMD,
                ),
                child: Icon(Icons.auto_awesome_rounded, color: color),
              ),
              const SizedBox(width: Dimensions.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: Dimensions.spacingXS,
                      runSpacing: Dimensions.spacingXS,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusPill(
                          icon: Icons.shield_rounded,
                          label: _severityLabel(insight.overallSeverity),
                          color: color,
                          compact: true,
                        ),
                        StatusPill(
                          icon: Icons.memory_rounded,
                          label: insight.model == null
                              ? insight.provider
                              : '${insight.provider} / ${insight.model}',
                          color: AppColors.info,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.spacingSM),
                    Text(
                      insight.summary.isEmpty
                          ? 'Sem resumo disponivel ainda.'
                          : insight.summary,
                      style: AppTextStyles.h4.copyWith(height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (insight.warning != null) ...[
            const SizedBox(height: Dimensions.spacingSM),
            Text(
              insight.warning!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: Dimensions.spacingMD),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Dimensions.paddingSM),
            decoration: AppStyles.softTile(
              context: context,
              tint: AppColors.info,
              radius: Dimensions.radiusMD,
            ),
            child: Row(
              children: [
                Icon(Icons.flag_rounded, color: AppColors.info, size: 20),
                const SizedBox(width: Dimensions.spacingSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.nextAction.title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        insight.nextAction.description,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onRunPlan != null) ...[
                  const SizedBox(width: Dimensions.spacingSM),
                  FilledButton.icon(
                    onPressed: isRunning ? null : onRunPlan,
                    icon: Icon(
                      insight.actionPlan.confirmationRequired
                          ? Icons.verified_user_rounded
                          : Icons.play_arrow_rounded,
                      size: 18,
                    ),
                    label: Text(
                      insight.actionPlan.confirmationRequired
                          ? 'Confirmar'
                          : 'Executar',
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (insight.actionPlan.argumentsSummary.isNotEmpty) ...[
            const SizedBox(height: Dimensions.spacingXS),
            Text(
              insight.actionPlan.argumentsSummary,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
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
              label: result.status,
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

  const _ResolutionPanel({required this.resolution});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(resolution.severity);
    return AppSurface(
      tint: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OperationalSectionHeader(
            icon: Icons.fact_check_rounded,
            title: 'Plano de resolucao',
            trailing: StatusPill(
              label: _severityLabel(resolution.severity),
              color: color,
              compact: true,
            ),
          ),
          const SizedBox(height: Dimensions.spacingSM),
          Text(resolution.diagnosis, style: AppTextStyles.body),
          if (resolution.immediateSteps.isNotEmpty) ...[
            const SizedBox(height: Dimensions.spacingSM),
            ...resolution.immediateSteps.map(
              (step) => _BulletLine(icon: Icons.check_rounded, text: step),
            ),
          ],
          if (resolution.recommendedMessage.isNotEmpty) ...[
            const SizedBox(height: Dimensions.spacingSM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSM),
              decoration: AppStyles.softTile(
                context: context,
                tint: AppColors.info,
                radius: Dimensions.radiusMD,
              ),
              child: Text(
                resolution.recommendedMessage,
                style: AppTextStyles.body.copyWith(height: 1.35),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RisksPanel extends StatelessWidget {
  final List<FiscalAiRisk> risks;
  final bool isRunning;
  final ValueChanged<FiscalAiRisk> onResolveRisk;

  const _RisksPanel({
    required this.risks,
    required this.isRunning,
    required this.onResolveRisk,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OperationalSectionHeader(
            icon: Icons.warning_amber_rounded,
            title: 'Riscos detectados',
          ),
          const SizedBox(height: Dimensions.spacingSM),
          if (risks.isEmpty)
            Text(
              'Nenhum risco relevante no contexto atual.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...risks.map(
              (risk) => Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.spacingSM),
                child: _RiskTile(
                  risk: risk,
                  isRunning: isRunning,
                  onResolve: () => onResolveRisk(risk),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RiskTile extends StatelessWidget {
  final FiscalAiRisk risk;
  final bool isRunning;
  final VoidCallback onResolve;

  const _RiskTile({
    required this.risk,
    required this.isRunning,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(risk.severity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSM),
      decoration: AppStyles.softTile(
        context: context,
        tint: color,
        radius: Dimensions.radiusMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  risk.title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.spacingSM),
              StatusPill(
                label: _severityLabel(risk.severity),
                color: color,
                compact: true,
              ),
            ],
          ),
          if (risk.reason.isNotEmpty) ...[
            const SizedBox(height: Dimensions.spacingXS),
            Text(
              risk.reason,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (risk.evidence.isNotEmpty) ...[
            const SizedBox(height: Dimensions.spacingXS),
            Text(
              risk.evidence,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: Dimensions.spacingSM),
          Row(
            children: [
              Expanded(
                child: _BulletLine(
                  icon: Icons.route_rounded,
                  text: risk.action.isEmpty
                      ? 'Revisar evento e registrar tratativa.'
                      : risk.action,
                ),
              ),
              const SizedBox(width: Dimensions.spacingSM),
              OutlinedButton.icon(
                onPressed: isRunning ? null : onResolve,
                icon: const Icon(Icons.fact_check_rounded, size: 18),
                label: const Text('Resolver'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendationsPanel extends StatelessWidget {
  final List<FiscalAiRecommendation> recommendations;

  const _RecommendationsPanel({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OperationalSectionHeader(
            icon: Icons.tips_and_updates_rounded,
            title: 'Recomendacoes',
          ),
          const SizedBox(height: Dimensions.spacingSM),
          if (recommendations.isEmpty)
            Text(
              'A IA ainda nao gerou recomendacoes.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...recommendations.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.spacingXS),
                child: _RecommendationTile(item: item),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  final FiscalAiRecommendation item;

  const _RecommendationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(item.priority);
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
          Icon(Icons.arrow_right_rounded, color: color),
          const SizedBox(width: Dimensions.spacingXS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: Dimensions.spacingXS,
                  runSpacing: Dimensions.spacingXS,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    StatusPill(
                      label: item.priority,
                      color: color,
                      compact: true,
                    ),
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (item.owner.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.owner,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QueuedActionsPanel extends StatelessWidget {
  final List<FiscalAiQueuedAction> actions;
  final bool isRunning;
  final ValueChanged<FiscalAiQueuedAction> onRun;
  final ValueChanged<FiscalAiQueuedAction> onDismiss;

  const _QueuedActionsPanel({
    required this.actions,
    required this.isRunning,
    required this.onRun,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OperationalSectionHeader(
            icon: Icons.playlist_add_check_circle_rounded,
            title: 'Acoes sugeridas',
          ),
          const SizedBox(height: Dimensions.spacingSM),
          if (actions.isEmpty)
            Text(
              'Nenhuma acao pendente da IA.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.spacingSM),
                child: _QueuedActionTile(
                  action: action,
                  isRunning: isRunning,
                  onRun: () => onRun(action),
                  onDismiss: () => onDismiss(action),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QueuedActionTile extends StatelessWidget {
  final FiscalAiQueuedAction action;
  final bool isRunning;
  final VoidCallback onRun;
  final VoidCallback onDismiss;

  const _QueuedActionTile({
    required this.action,
    required this.isRunning,
    required this.onRun,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        action.confirmationRequired ? AppColors.statusAtencao : AppColors.info;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSM),
      decoration: AppStyles.softTile(
        context: context,
        tint: color,
        radius: Dimensions.radiusMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  action.title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusPill(
                label: action.status,
                color: color,
                compact: true,
              ),
            ],
          ),
          if (action.description.isNotEmpty) ...[
            const SizedBox(height: Dimensions.spacingXS),
            Text(
              action.description,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (action.reason?.isNotEmpty == true) ...[
            const SizedBox(height: Dimensions.spacingXS),
            Text(
              action.reason!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: Dimensions.spacingSM),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: isRunning ? null : onDismiss,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Descartar'),
              ),
              const SizedBox(width: Dimensions.spacingXS),
              FilledButton.icon(
                onPressed: isRunning || !action.hasTool ? null : onRun,
                icon: Icon(
                  action.confirmationRequired
                      ? Icons.verified_rounded
                      : Icons.play_arrow_rounded,
                  size: 18,
                ),
                label: Text(
                  action.confirmationRequired ? 'Confirmar' : 'Executar',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BulletLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: Dimensions.spacingXS),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
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
