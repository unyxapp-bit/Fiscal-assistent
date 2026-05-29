import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const OPENAI_MODEL = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";
const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY") ?? "";
const ANTHROPIC_MODEL =
  Deno.env.get("ANTHROPIC_MODEL") ?? "claude-3-5-haiku-20241022";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type Severity = "normal" | "medio" | "alto" | "critico";
type Priority = "baixa" | "media" | "alta";
type Intent = "analyze" | "ask" | "resolve" | "act";
type ToolName = "generate_balcao_report" | "create_followup_event";

interface FiscalAiInput {
  fiscal_id?: string | null;
  intent?: Intent | null;
  question?: string | null;
  target?: Record<string, unknown> | null;
  action?: {
    tool_name?: ToolName | null;
    arguments?: Record<string, unknown> | null;
    confirmed?: boolean | null;
  } | null;
  context?: Record<string, unknown> | null;
}

interface FiscalAiInsight {
  summary: string;
  overall_severity: Severity;
  risks: Array<Record<string, unknown>>;
  recommendations: Array<Record<string, unknown>>;
  next_action: Record<string, unknown>;
  action_plan: Record<string, unknown>;
  action_result: Record<string, unknown>;
  resolution: Record<string, unknown>;
  chat_answer: string;
  tools_used: string[];
  provider: "openai" | "anthropic" | "fallback" | "local";
  model: string | null;
  warning?: string;
}

function asRecord(value: unknown): Record<string, unknown> {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return {};
}

function asArray(value: unknown): Record<string, unknown>[] {
  if (!Array.isArray(value)) return [];
  return value.map(asRecord);
}

function text(value: unknown, fallback = "") {
  return typeof value === "string" ? value : fallback;
}

function numberValue(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", "."));
    if (Number.isFinite(parsed)) return parsed;
  }
  return null;
}

function eventDate(event: Record<string, unknown>) {
  return text(event.event_date) || text(event.eventDate) || text(event.created_at);
}

function eventStatus(event: Record<string, unknown>) {
  return text(event.status, "pending");
}

function eventPriority(event: Record<string, unknown>) {
  return text(event.priority, "normal");
}

function eventCategory(event: Record<string, unknown>) {
  return text(event.category, "aviso_geral");
}

function eventDescription(event: Record<string, unknown>) {
  return text(event.description) || text(event.raw_message) || text(event.rawMessage);
}

function eventEmployee(event: Record<string, unknown>) {
  return text(event.employee_name) || text(event.employeeName) || text(event.sender);
}

function eventAmount(event: Record<string, unknown>) {
  return numberValue(event.amount);
}

function severityRank(severity: Severity) {
  return { normal: 0, medio: 1, alto: 2, critico: 3 }[severity];
}

function maxSeverity(values: Severity[]): Severity {
  return values.reduce(
    (best, item) => (severityRank(item) > severityRank(best) ? item : best),
    "normal" as Severity,
  );
}

function severityFromEvent(event: Record<string, unknown>): Severity {
  const priority = eventPriority(event);
  const category = eventCategory(event);
  const amount = eventAmount(event) ?? 0;

  if (priority === "critica") return "critico";
  if (priority === "alta") return "alto";
  if (category === "problema_operacional") return "alto";
  if (category === "caixa" && amount >= 100) return "critico";
  if (category === "caixa" && amount >= 50) return "alto";
  if (category === "ausencia" || category === "atestado") return "medio";
  return "normal";
}

function normalizeCategory(category: string) {
  const labels: Record<string, string> = {
    caixa: "Caixa",
    troco: "Troco",
    ausencia: "Ausencia",
    atestado: "Atestado",
    horario_especial: "Horario especial",
    ferias: "Ferias",
    vale: "Vale",
    problema_operacional: "Problema operacional",
    escala: "Escala",
    cooperativa: "Cooperativa",
    aviso_geral: "Aviso geral",
    midia_pendente: "Midia pendente",
  };
  return labels[category] ?? category;
}

function buildReport(context: Record<string, unknown>, insight: FiscalAiInsight) {
  const events = asArray(context.fiscal_events);
  const pending = events.filter((event) => eventStatus(event) === "pending");
  const byCategory = new Map<string, number>();

  for (const event of pending) {
    const category = eventCategory(event);
    byCategory.set(category, (byCategory.get(category) ?? 0) + 1);
  }

  const lines = [
    "# Briefing fiscal",
    "",
    insight.summary,
    "",
    "## Pendencias por categoria",
    ...Array.from(byCategory.entries()).map(
      ([category, count]) => `- ${normalizeCategory(category)}: ${count}`,
    ),
    "",
    "## Riscos principais",
    ...(insight.risks.length
      ? insight.risks.map((risk) => `- ${text(risk.title)}: ${text(risk.action)}`)
      : ["- Nenhum risco critico destacado agora."]),
    "",
    "## Proxima acao",
    `- ${text(insight.next_action.title)}: ${text(insight.next_action.description)}`,
  ];

  return lines.join("\n");
}

function emptyActionResult() {
  return {
    status: "none",
    tool_name: null,
    title: "",
    message: "",
    artifact_markdown: null,
  };
}

function emptyResolution() {
  return {
    status: "none",
    diagnosis: "",
    severity: "normal",
    immediate_steps: [],
    recommended_message: "",
    preventive_actions: [],
    confirmation_required: false,
    apply_event: null,
  };
}

function emptyActionPlan() {
  return {
    mode: "none",
    tool_name: null,
    description: "",
    confidence: 0,
    arguments: {},
    arguments_summary: "",
    confirmation_required: false,
  };
}

function buildFallbackInsight(input: FiscalAiInput): FiscalAiInsight {
  const context = asRecord(input.context);
  const events = asArray(context.fiscal_events);
  const caixas = asArray(context.caixas);
  const colaboradores = asArray(context.colaboradores);
  const pending = events.filter((event) => eventStatus(event) === "pending");
  const recent = events.slice(0, 80);
  const critical = pending.filter((event) => severityRank(severityFromEvent(event)) >= 2);
  const cashEvents = pending.filter((event) => eventCategory(event) === "caixa");
  const operationalProblems = pending.filter(
    (event) => eventCategory(event) === "problema_operacional",
  );
  const absences = pending.filter((event) =>
    ["ausencia", "atestado"].includes(eventCategory(event))
  );

  const totalCash = cashEvents.reduce(
    (sum, event) => sum + Math.abs(eventAmount(event) ?? 0),
    0,
  );

  const recurrence = new Map<string, number>();
  for (const event of recent) {
    const name = eventEmployee(event);
    if (!name) continue;
    recurrence.set(name, (recurrence.get(name) ?? 0) + 1);
  }
  const recurring = Array.from(recurrence.entries())
    .filter(([, count]) => count >= 3)
    .sort((a, b) => b[1] - a[1])[0];

  const risks: Array<Record<string, unknown>> = [];

  if (critical.length > 0) {
    const first = critical[0];
    risks.push({
      title: `${critical.length} pendencia(s) de alta prioridade`,
      severity: maxSeverity(critical.map(severityFromEvent)),
      reason: "Ha eventos pendentes com prioridade alta, valor elevado ou problema operacional.",
      evidence: eventDescription(first),
      action: "Revisar os eventos criticos, confirmar responsavel e registrar a tratativa.",
      target: first,
    });
  }

  if (totalCash >= 50) {
    risks.push({
      title: "Diferencas de caixa acumuladas",
      severity: totalCash >= 150 ? "critico" : "alto",
      reason: `Eventos de caixa pendentes somam R$ ${totalCash.toFixed(2)}.`,
      evidence: `${cashEvents.length} evento(s) de caixa pendente(s).`,
      action: "Conferir sangria, fechamento e comprovantes antes da passagem de turno.",
      target: cashEvents[0] ?? null,
    });
  }

  if (operationalProblems.length > 0) {
    risks.push({
      title: "Falha operacional aberta",
      severity: "alto",
      reason: "Problemas de POS, TEF, sistema ou impressora podem travar atendimento.",
      evidence: eventDescription(operationalProblems[0]),
      action: "Isolar o caixa afetado, acionar suporte e orientar operadores.",
      target: operationalProblems[0],
    });
  }

  if (recurring) {
    risks.push({
      title: "Reincidencia por colaborador",
      severity: "medio",
      reason: `${recurring[0]} aparece em ${recurring[1]} evento(s) recentes.`,
      evidence: "Eventos dos ultimos registros do Balcao Fiscal.",
      action: "Conversar com o responsavel e acompanhar proximas ocorrencias.",
      target: { employee_name: recurring[0] },
    });
  }

  const recommendations = [
    {
      title: "Fechar pendencias do Balcao",
      description: pending.length > 0
        ? `Priorize ${Math.min(pending.length, 5)} evento(s) pendente(s) antes do fim do turno.`
        : "Nao ha pendencias abertas no Balcao Fiscal.",
      priority: pending.length > 0 ? "alta" : "baixa",
      owner: "Fiscal do turno",
      requires_confirmation: false,
    },
    {
      title: "Validar cobertura dos caixas",
      description: caixas.length > 0
        ? "Compare caixas ativos, manutencao e operadores antes dos horarios de pico."
        : "Cadastre ou atualize os caixas para melhorar a leitura da IA.",
      priority: "media",
      owner: "Fiscal do turno",
      requires_confirmation: false,
    },
    {
      title: "Revisar equipe disponivel",
      description: colaboradores.length > 0
        ? `${colaboradores.length} colaborador(es) no contexto enviado para a IA.`
        : "Carregue colaboradores para cruzar ausencias, escala e reincidencias.",
      priority: absences.length > 0 ? "alta" : "media",
      owner: "Fiscal do turno",
      requires_confirmation: false,
    },
  ];

  const overall = risks.length > 0
    ? maxSeverity(risks.map((risk) => text(risk.severity, "normal") as Severity))
    : pending.length > 0
    ? "medio"
    : "normal";

  const nextAction = critical.length > 0
    ? {
      title: "Tratar prioridade critica",
      description: "Transforme o principal risco em evento de acompanhamento.",
      can_execute: true,
    }
    : {
      title: pending.length > 0 ? "Gerar briefing do Balcao" : "Manter monitoramento",
      description: pending.length > 0
        ? "Consolide as pendencias em um briefing compartilhavel."
        : "Continue acompanhando notificacoes e eventos do turno.",
      can_execute: pending.length > 0,
    };

  const actionPlan = critical.length > 0
    ? {
      mode: "execute_with_confirmation",
      tool_name: "create_followup_event",
      description: "Criar um evento manual de acompanhamento para o risco principal.",
      confidence: 0.82,
      arguments: {
        title: text(critical[0].description, "Risco fiscal em aberto"),
        priority: text(critical[0].priority, "alta"),
        category: "aviso_geral",
        notes: text(critical[0].raw_message) || eventDescription(critical[0]),
      },
      arguments_summary: "Evento manual de acompanhamento no Balcao Fiscal.",
      confirmation_required: true,
    }
    : pending.length > 0
    ? {
      mode: "suggest",
      tool_name: "generate_balcao_report",
      description: "Gerar briefing do turno com pendencias, riscos e proxima acao.",
      confidence: 0.76,
      arguments: {},
      arguments_summary: "Relatorio textual do estado atual.",
      confirmation_required: false,
    }
    : emptyActionPlan();

  const chatAnswer = input.question
    ? answerQuestionLocally(text(input.question), { pending, risks, totalCash })
    : "";

  return {
    summary: pending.length > 0
      ? `${pending.length} pendencia(s) fiscal(is) abertas, ${critical.length} de alta prioridade.`
      : "Turno sem pendencias fiscais abertas no contexto enviado.",
    overall_severity: overall,
    risks,
    recommendations,
    next_action: nextAction,
    action_plan: actionPlan,
    action_result: emptyActionResult(),
    resolution: emptyResolution(),
    chat_answer: chatAnswer,
    tools_used: ["local_context"],
    provider: "fallback",
    model: null,
  };
}

function answerQuestionLocally(
  question: string,
  data: { pending: Record<string, unknown>[]; risks: Record<string, unknown>[]; totalCash: number },
) {
  const q = question.toLowerCase();
  if (q.includes("caixa") || q.includes("valor") || q.includes("dinheiro")) {
    return data.totalCash > 0
      ? `Ha R$ ${data.totalCash.toFixed(2)} em diferencas de caixa pendentes no contexto atual.`
      : "Nao encontrei diferencas de caixa pendentes no contexto atual.";
  }
  if (q.includes("critico") || q.includes("urgente") || q.includes("prioridade")) {
    return data.risks.length > 0
      ? `O foco agora e: ${text(data.risks[0].title)}. ${text(data.risks[0].action)}`
      : "Nao encontrei risco critico no contexto atual.";
  }
  return data.pending.length > 0
    ? `Encontrei ${data.pending.length} pendencia(s). Priorize as mais recentes e as de prioridade alta.`
    : "Nao encontrei pendencias abertas no contexto atual.";
}

function normalizeInsight(raw: Record<string, unknown>, fallback: FiscalAiInsight): FiscalAiInsight {
  const actionPlan = asRecord(raw.action_plan);
  const actionResult = asRecord(raw.action_result);
  const resolution = asRecord(raw.resolution);
  const nextAction = asRecord(raw.next_action);

  return {
    summary: text(raw.summary, fallback.summary),
    overall_severity: text(raw.overall_severity, fallback.overall_severity) as Severity,
    risks: asArray(raw.risks).length ? asArray(raw.risks) : fallback.risks,
    recommendations: asArray(raw.recommendations).length
      ? asArray(raw.recommendations)
      : fallback.recommendations,
    next_action: Object.keys(nextAction).length ? nextAction : fallback.next_action,
    action_plan: Object.keys(actionPlan).length ? actionPlan : fallback.action_plan,
    action_result: Object.keys(actionResult).length ? actionResult : fallback.action_result,
    resolution: Object.keys(resolution).length ? resolution : fallback.resolution,
    chat_answer: text(raw.chat_answer, fallback.chat_answer),
    tools_used: Array.isArray(raw.tools_used) ? raw.tools_used.map((x) => String(x)) : fallback.tools_used,
    provider: text(raw.provider, fallback.provider) as FiscalAiInsight["provider"],
    model: text(raw.model, fallback.model ?? "") || fallback.model,
    warning: text(raw.warning) || fallback.warning,
  };
}

function parseJsonObject(raw: string): Record<string, unknown> {
  const clean = raw.replace(/```json|```/g, "").trim();
  const first = clean.indexOf("{");
  const last = clean.lastIndexOf("}");
  if (first >= 0 && last > first) {
    return JSON.parse(clean.slice(first, last + 1));
  }
  return JSON.parse(clean);
}

const systemPrompt = `
Voce e um agente operacional para fiscais de caixa de supermercado.
Analise eventos do Balcao Fiscal, caixas, equipe e pergunta do usuario.
Responda apenas JSON valido, sem markdown.

Formato obrigatorio:
{
  "summary": "resumo curto",
  "overall_severity": "normal|medio|alto|critico",
  "risks": [
    {
      "title": "titulo",
      "severity": "normal|medio|alto|critico",
      "reason": "motivo",
      "evidence": "evidencia observavel",
      "action": "acao recomendada",
      "target": {}
    }
  ],
  "recommendations": [
    {
      "title": "titulo",
      "description": "descricao",
      "priority": "baixa|media|alta",
      "owner": "responsavel",
      "requires_confirmation": false
    }
  ],
  "next_action": {
    "title": "titulo",
    "description": "descricao",
    "can_execute": true
  },
  "action_plan": {
    "mode": "none|suggest|execute_with_confirmation",
    "tool_name": null,
    "description": "",
    "confidence": 0.0,
    "arguments": {},
    "arguments_summary": "",
    "confirmation_required": false
  },
  "action_result": {
    "status": "none",
    "tool_name": null,
    "title": "",
    "message": "",
    "artifact_markdown": null
  },
  "resolution": {
    "status": "none|drafted",
    "diagnosis": "",
    "severity": "normal|medio|alto|critico",
    "immediate_steps": [],
    "recommended_message": "",
    "preventive_actions": [],
    "confirmation_required": false,
    "apply_event": null
  },
  "chat_answer": "",
  "tools_used": ["context"]
}

Ferramentas que podem ser sugeridas:
- generate_balcao_report: gera briefing textual. Nao requer confirmacao.
- create_followup_event: cria evento manual de acompanhamento. Sempre requer confirmacao.
`;

async function callOpenAI(input: FiscalAiInput, fallback: FiscalAiInsight) {
  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      temperature: 0.2,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: JSON.stringify(input) },
      ],
    }),
  });

  if (!response.ok) throw new Error(await response.text());
  const data = await response.json();
  const raw = data.choices?.[0]?.message?.content ?? "";
  return normalizeInsight(parseJsonObject(raw), {
    ...fallback,
    provider: "openai",
    model: OPENAI_MODEL,
  });
}

async function callAnthropic(input: FiscalAiInput, fallback: FiscalAiInsight) {
  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: ANTHROPIC_MODEL,
      max_tokens: 1400,
      temperature: 0.2,
      system: systemPrompt,
      messages: [{ role: "user", content: JSON.stringify(input) }],
    }),
  });

  if (!response.ok) throw new Error(await response.text());
  const data = await response.json();
  const raw = data.content?.[0]?.text ?? "";
  return normalizeInsight(parseJsonObject(raw), {
    ...fallback,
    provider: "anthropic",
    model: ANTHROPIC_MODEL,
  });
}

async function buildAiInsight(input: FiscalAiInput) {
  const fallback = buildFallbackInsight(input);

  if (OPENAI_API_KEY) {
    try {
      return await callOpenAI(input, fallback);
    } catch (error) {
      console.warn("[fiscal-ai-agent] OpenAI fallback:", error);
    }
  }

  if (ANTHROPIC_API_KEY) {
    try {
      return await callAnthropic(input, fallback);
    } catch (error) {
      console.warn("[fiscal-ai-agent] Anthropic fallback:", error);
    }
  }

  return {
    ...fallback,
    provider: "local" as const,
    warning: OPENAI_API_KEY || ANTHROPIC_API_KEY
      ? "IA externa falhou; usando analise local."
      : "Configure OPENAI_API_KEY ou ANTHROPIC_API_KEY para respostas generativas.",
  };
}

async function executeAction(
  input: FiscalAiInput,
  insight: FiscalAiInsight,
  supabase: ReturnType<typeof createClient>,
) {
  const action = input.action;
  const toolName = action?.tool_name ?? null;
  const confirmed = action?.confirmed === true;
  const args = action?.arguments ?? asRecord(insight.action_plan.arguments);
  const context = asRecord(input.context);

  if (!toolName) return insight;

  if (toolName === "generate_balcao_report") {
    return {
      ...insight,
      action_result: {
        status: "executed",
        tool_name: toolName,
        title: "Briefing gerado",
        message: "Briefing do Balcao Fiscal pronto.",
        artifact_markdown: buildReport(context, insight),
      },
      tools_used: [...new Set([...insight.tools_used, toolName])],
    };
  }

  if (toolName === "create_followup_event") {
    if (!confirmed) {
      return {
        ...insight,
        action_result: {
          status: "pending_confirmation",
          tool_name: toolName,
          title: "Confirmacao necessaria",
          message: "Confirme para criar o evento manual de acompanhamento.",
          artifact_markdown: null,
        },
        tools_used: [...new Set([...insight.tools_used, toolName])],
      };
    }

    const title = text(args.title, "Acompanhamento fiscal gerado por IA");
    const notes = text(args.notes, text(insight.summary));
    const priority = text(args.priority, "alta");
    const category = text(args.category, "aviso_geral");

    const { error } = await supabase.from("fiscal_events").insert({
      category,
      description: title,
      employee_name: text(args.employee_name) || null,
      amount: numberValue(args.amount),
      raw_message: notes,
      event_date: new Date().toISOString(),
      status: "pending",
      confidence: 1,
      source: "sistema",
      priority: priority === "critica" ? "critica" : priority === "alta" ? "alta" : "normal",
      notes,
    });

    if (error) {
      return {
        ...insight,
        action_result: {
          status: "failed",
          tool_name: toolName,
          title: "Evento nao criado",
          message: error.message,
          artifact_markdown: null,
        },
        tools_used: [...new Set([...insight.tools_used, toolName])],
      };
    }

    return {
      ...insight,
      action_result: {
        status: "executed",
        tool_name: toolName,
        title: "Evento criado",
        message: "Evento manual de acompanhamento criado no Balcao Fiscal.",
        artifact_markdown: null,
      },
      tools_used: [...new Set([...insight.tools_used, toolName])],
    };
  }

  return {
    ...insight,
    action_result: {
      status: "blocked",
      tool_name: toolName,
      title: "Ferramenta bloqueada",
      message: "Ferramenta desconhecida ou indisponivel.",
      artifact_markdown: null,
    },
  };
}

async function persistSnapshot(
  supabase: ReturnType<typeof createClient>,
  input: FiscalAiInput,
  insight: FiscalAiInsight,
) {
  if (!input.fiscal_id) return null;

  const context = asRecord(input.context);
  const actionResult = asRecord(insight.action_result);
  const actionPlan = asRecord(insight.action_plan);

  const { data, error } = await supabase
    .from("fiscal_ai_snapshots")
    .insert({
      fiscal_id: input.fiscal_id,
      intent: input.intent ?? "analyze",
      question: input.question ?? null,
      target: input.target ?? null,
      context_snapshot: context,
      result: insight,
      provider: insight.provider,
      model: insight.model,
      action_tool: text(actionPlan.tool_name) || text(actionResult.tool_name) || null,
      action_status: text(actionResult.status) || null,
    })
    .select("id")
    .single();

  if (error) {
    console.warn("[fiscal-ai-agent] snapshot not persisted:", error.message);
    return null;
  }

  return data?.id as string | null;
}

async function persistSuggestedAction(
  supabase: ReturnType<typeof createClient>,
  input: FiscalAiInput,
  insight: FiscalAiInsight,
  snapshotId: string | null,
) {
  if (!input.fiscal_id || input.intent === "act") return;

  const plan = asRecord(insight.action_plan);
  const toolName = text(plan.tool_name);
  if (!toolName || text(plan.mode, "none") === "none") return;

  const confirmationRequired = plan.confirmation_required === true;
  const status = confirmationRequired ? "pending_approval" : "ready";
  const title = text(asRecord(insight.next_action).title, "Acao sugerida pela IA");
  const description = text(plan.description, text(asRecord(insight.next_action).description));

  const { error } = await supabase.from("fiscal_ai_actions").insert({
    fiscal_id: input.fiscal_id,
    snapshot_id: snapshotId,
    intent: input.intent ?? "analyze",
    status,
    mode: text(plan.mode, "suggest"),
    tool_name: toolName,
    title,
    description,
    reason: text(plan.arguments_summary) || null,
    confidence: numberValue(plan.confidence) ?? 0.7,
    confirmation_required: confirmationRequired,
    arguments: asRecord(plan.arguments),
    target: input.target ?? null,
    context_snapshot: asRecord(input.context),
    action_result: {},
  });

  if (error) {
    console.warn("[fiscal-ai-agent] action not persisted:", error.message);
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
      throw new Error("Supabase service credentials are not configured.");
    }

    const input = (await req.json()) as FiscalAiInput;
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const normalizedInput: FiscalAiInput = {
      ...input,
      intent: input.intent ?? "analyze",
      context: asRecord(input.context),
    };

    let insight = await buildAiInsight(normalizedInput);

    if (normalizedInput.intent === "resolve" && normalizedInput.target) {
      insight = {
        ...insight,
        resolution: {
          status: "drafted",
          diagnosis: `Risco identificado: ${text(normalizedInput.target.title, "pendencia fiscal")}.`,
          severity: text(normalizedInput.target.severity, insight.overall_severity),
          immediate_steps: [
            "Validar o evento original no Balcao Fiscal.",
            "Confirmar responsavel e caixa envolvido.",
            "Registrar a tratativa antes da passagem de turno.",
          ],
          recommended_message:
            "Pessoal, estou tratando esta pendencia agora. Confirmem caixa, operador e valor antes do fechamento.",
          preventive_actions: [
            "Conferir comprovantes",
            "Anotar responsavel",
            "Revisar reincidencia",
          ],
          confirmation_required: false,
          apply_event: {
            title: text(normalizedInput.target.title, "Acompanhamento fiscal"),
            notes: text(normalizedInput.target.evidence, insight.summary),
            priority: text(normalizedInput.target.severity) === "critico" ? "critica" : "alta",
          },
        },
      };
    }

    if (normalizedInput.intent === "act") {
      insight = await executeAction(normalizedInput, insight, supabase);
    }

    const snapshotId = await persistSnapshot(supabase, normalizedInput, insight);
    await persistSuggestedAction(supabase, normalizedInput, insight, snapshotId);

    return new Response(JSON.stringify(insight), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("[fiscal-ai-agent]", error);
    return new Response(
      JSON.stringify({ success: false, error: error instanceof Error ? error.message : String(error) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
