import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const OPENAI_MODEL =
  Deno.env.get("OPENAI_AGENT_MODEL") ?? Deno.env.get("OPENAI_MODEL") ?? "gpt-5-mini";
const OPENAI_MINI_MODEL =
  Deno.env.get("OPENAI_MINI_MODEL") ?? "gpt-5-nano";
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.0-flash";
const GEMINI_LITE_MODEL =
  Deno.env.get("GEMINI_LITE_MODEL") ?? "gemini-2.0-flash-lite";
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
type ToolName =
  | "generate_balcao_report"
  | "generate_shift_handoff_report"
  | "create_followup_event"
  | "register_timeline_event"
  | "create_allocation"
  | "release_allocation"
  | "start_cafe_pause"
  | "finish_cafe_pause";
type ContextLevel = "full" | "reduced" | "minimal";

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
  provider: "openai" | "anthropic" | "gemini" | "fallback" | "local";
  source: string;
  fonte: string;
  model: string | null;
  warning?: string;
}

interface TableContextConfig {
  key: string;
  table: string;
  fiscalColumn?: string;
  select?: string;
  order?: string;
  ascending?: boolean;
  limit?: number;
  dateColumn?: string;
  dateKind?: "timestamp" | "date";
  daysBack?: number;
  daysForward?: number;
  filters?: Array<{ column: string; op: "eq" | "neq"; value: unknown }>;
}

const DEFAULT_TIME_ZONE = "America/Sao_Paulo";

const tableContextConfigs: TableContextConfig[] = [
  {
    key: "fiscal_profile",
    table: "fiscais",
    fiscalColumn: "id",
    limit: 1,
  },
  {
    key: "colaboradores",
    table: "colaboradores",
    order: "nome",
    ascending: true,
    limit: 180,
  },
  {
    key: "turnos_escala",
    table: "turnos_escala",
    order: "data",
    ascending: true,
    dateColumn: "data",
    dateKind: "date",
    daysBack: 1,
    daysForward: 7,
    limit: 260,
  },
  {
    key: "caixas",
    table: "caixas",
    order: "numero",
    ascending: true,
    limit: 120,
  },
  {
    key: "alocacoes",
    table: "alocacoes",
    order: "horario_inicio",
    ascending: false,
    dateColumn: "horario_inicio",
    dateKind: "timestamp",
    daysBack: 1,
    daysForward: 1,
    limit: 180,
  },
  {
    key: "pacote_plantao",
    table: "pacote_plantao",
    order: "data",
    ascending: false,
    dateColumn: "data",
    dateKind: "date",
    daysBack: 7,
    daysForward: 7,
    limit: 120,
  },
  {
    key: "outro_setor",
    table: "outro_setor",
    order: "data",
    ascending: false,
    dateColumn: "data",
    dateKind: "date",
    daysBack: 7,
    daysForward: 7,
    limit: 120,
  },
  {
    key: "pausas_cafe",
    table: "pausas_cafe",
    order: "iniciado_em",
    ascending: false,
    dateColumn: "iniciado_em",
    dateKind: "timestamp",
    daysBack: 1,
    daysForward: 1,
    limit: 140,
  },
  {
    key: "entregas",
    table: "entregas",
    order: "created_at",
    ascending: false,
    dateColumn: "created_at",
    dateKind: "timestamp",
    daysBack: 2,
    daysForward: 1,
    limit: 180,
  },
  {
    key: "notas",
    table: "notas",
    order: "updated_at",
    ascending: false,
    limit: 120,
  },
  {
    key: "ocorrencias",
    table: "ocorrencias",
    order: "registrada_em",
    ascending: false,
    limit: 120,
  },
  {
    key: "checklist_execucoes",
    table: "checklist_execucoes",
    order: "data",
    ascending: false,
    dateColumn: "data",
    dateKind: "date",
    daysBack: 3,
    daysForward: 1,
    limit: 120,
  },
  {
    key: "checklist_templates",
    table: "checklist_templates",
    order: "created_at",
    ascending: false,
    limit: 120,
  },
  {
    key: "fiscal_events",
    table: "fiscal_events",
    order: "event_date",
    ascending: false,
    dateColumn: "event_date",
    dateKind: "timestamp",
    daysBack: 7,
    daysForward: 1,
    limit: 220,
  },
  {
    key: "passagens_turno",
    table: "passagens_turno",
    order: "registrada_em",
    ascending: false,
    limit: 40,
  },
  {
    key: "eventos_turno",
    table: "eventos_turno",
    order: "timestamp",
    ascending: false,
    dateColumn: "timestamp",
    dateKind: "timestamp",
    daysBack: 2,
    daysForward: 1,
    limit: 220,
  },
  {
    key: "relatorios_dia",
    table: "relatorios_dia",
    order: "turno_iniciado_em",
    ascending: false,
    limit: 40,
  },
  {
    key: "operation_audit_logs",
    table: "operation_audit_logs",
    order: "created_at",
    ascending: false,
    dateColumn: "created_at",
    dateKind: "timestamp",
    daysBack: 3,
    daysForward: 1,
    limit: 220,
  },
  {
    key: "operation_attachments",
    table: "operation_attachments",
    order: "created_at",
    ascending: false,
    limit: 80,
  },
  {
    key: "operation_notification_queue",
    table: "operation_notification_queue",
    order: "created_at",
    ascending: false,
    limit: 120,
  },
  {
    key: "operation_sla_rules",
    table: "operation_sla_rules",
    order: "updated_at",
    ascending: false,
    limit: 80,
  },
  {
    key: "dashboard_quick_notes",
    table: "dashboard_quick_notes",
    order: "created_at",
    ascending: false,
    limit: 80,
  },
  {
    key: "dashboard_layouts",
    table: "dashboard_layouts",
    order: "updated_at",
    ascending: false,
    limit: 20,
  },
  {
    key: "ai_inbox_items",
    table: "ai_inbox_items",
    order: "created_at",
    ascending: false,
    limit: 80,
  },
  {
    key: "operation_media_insights",
    table: "operation_media_insights",
    order: "created_at",
    ascending: false,
    limit: 80,
  },
  {
    key: "formularios",
    table: "formularios",
    order: "updated_at",
    ascending: false,
    limit: 80,
  },
  {
    key: "respostas_formulario",
    table: "respostas_formulario",
    order: "preenchido_em",
    ascending: false,
    dateColumn: "preenchido_em",
    dateKind: "timestamp",
    daysBack: 7,
    daysForward: 1,
    limit: 120,
  },
  {
    key: "procedimentos",
    table: "procedimentos",
    order: "updated_at",
    ascending: false,
    limit: 120,
  },
  {
    key: "guia_rapido",
    table: "guia_rapido",
    order: "updated_at",
    ascending: false,
    limit: 120,
  },
  {
    key: "desconto_calculos",
    table: "desconto_calculos",
    order: "created_at",
    ascending: false,
    dateColumn: "created_at",
    dateKind: "timestamp",
    daysBack: 30,
    daysForward: 1,
    limit: 80,
  },
  {
    key: "cupom_configuracoes",
    table: "cupom_configuracoes",
    order: "updated_at",
    ascending: false,
    limit: 1,
  },
];

const operationalKnowledgeMap = {
  identidade_fiscal: {
    use_when: ["quem sou eu", "loja", "perfil do fiscal", "dados do fiscal"],
    primary_tables: ["fiscais"],
    key_columns: ["fiscais.id", "fiscais.nome", "fiscais.email", "fiscais.loja"],
  },
  equipe_colaboradores: {
    use_when: ["colaboradores", "equipe", "quem esta ativo", "cargo", "departamento"],
    primary_tables: ["colaboradores"],
    key_columns: [
      "colaboradores.id",
      "colaboradores.nome",
      "colaboradores.departamento",
      "colaboradores.cargo",
      "colaboradores.ativo",
    ],
  },
  escala_folgas_horarios: {
    use_when: ["quem esta de folga", "escala", "horario", "entrada", "saida", "intervalo"],
    primary_tables: ["turnos_escala"],
    secondary_tables: ["registros_ponto", "pacote_plantao", "outro_setor"],
    key_columns: [
      "turnos_escala.colaborador_id",
      "turnos_escala.colaborador_nome",
      "turnos_escala.data",
      "turnos_escala.entrada",
      "turnos_escala.intervalo",
      "turnos_escala.retorno",
      "turnos_escala.saida",
      "turnos_escala.folga",
      "turnos_escala.feriado",
      "registros_ponto.data",
      "registros_ponto.entrada",
      "registros_ponto.intervalo_saida",
      "registros_ponto.intervalo_retorno",
      "registros_ponto.saida",
    ],
    relationships: [
      "turnos_escala.colaborador_id -> colaboradores.id",
      "registros_ponto.colaborador_id -> colaboradores.id",
    ],
  },
  frente_de_caixa_alocacoes: {
    use_when: ["alocacao", "quem esta no caixa", "liberar caixa", "trocar caixa", "pdv"],
    primary_tables: ["alocacoes", "caixas"],
    secondary_tables: ["colaboradores", "turnos_escala"],
    key_columns: [
      "alocacoes.id",
      "alocacoes.colaborador_id",
      "alocacoes.caixa_id",
      "alocacoes.status",
      "alocacoes.horario_inicio",
      "alocacoes.liberado_em",
      "alocacoes.motivo_liberacao",
      "caixas.id",
      "caixas.numero",
      "caixas.status",
      "caixas.em_manutencao",
    ],
    relationships: [
      "alocacoes.colaborador_id -> colaboradores.id",
      "alocacoes.caixa_id -> caixas.id",
      "alocacoes.turno_escala_id -> turnos_escala.id",
    ],
  },
  cafes_intervalos: {
    use_when: ["cafe", "café", "intervalo", "pausa", "quem saiu", "quem voltou"],
    primary_tables: ["pausas_cafe"],
    secondary_tables: ["alocacoes", "turnos_escala", "operation_sla_rules"],
    key_columns: [
      "pausas_cafe.id",
      "pausas_cafe.colaborador_id",
      "pausas_cafe.colaborador_nome",
      "pausas_cafe.caixa_id",
      "pausas_cafe.iniciado_em",
      "pausas_cafe.duracao_minutos",
      "pausas_cafe.finalizado_em",
    ],
    relationships: [
      "pausas_cafe.colaborador_id -> colaboradores.id",
      "pausas_cafe.caixa_id -> caixas.id",
    ],
  },
  entregas: {
    use_when: ["entregas", "quantas entregas", "entrega hoje", "nota", "cliente", "bairro"],
    primary_tables: ["entregas"],
    key_columns: [
      "entregas.id",
      "entregas.numero_nota",
      "entregas.cliente_nome",
      "entregas.bairro",
      "entregas.cidade",
      "entregas.status",
      "entregas.separado_em",
      "entregas.horario_marcado",
      "entregas.saiu_para_entrega_em",
      "entregas.entregue_em",
    ],
  },
  balcao_fiscal_midias_whatsapp: {
    use_when: ["balcao fiscal", "whatsapp", "midia pendente", "foto", "audio", "evento fiscal"],
    primary_tables: ["fiscal_events", "ai_inbox_items", "operation_media_insights"],
    key_columns: [
      "fiscal_events.id",
      "fiscal_events.category",
      "fiscal_events.description",
      "fiscal_events.status",
      "fiscal_events.priority",
      "fiscal_events.event_date",
      "fiscal_events.colaborador_id",
      "ai_inbox_items.analysis_status",
      "ai_inbox_items.summary",
    ],
    relationships: [
      "fiscal_events.colaborador_id -> colaboradores.id",
      "fiscal_events.ai_inbox_item_id -> ai_inbox_items.id",
    ],
  },
  pendencias_rotina: {
    use_when: ["pendencias", "sem resolver", "ocorrencias", "notas", "checklists"],
    primary_tables: ["ocorrencias", "notas", "checklist_execucoes"],
    secondary_tables: ["operation_notification_queue"],
    key_columns: [
      "ocorrencias.resolvida",
      "notas.concluida",
      "checklist_execucoes.concluido",
      "operation_notification_queue.status",
    ],
  },
  passagem_turno_linha_tempo: {
    use_when: ["passagem de turno", "linha do tempo", "relatorio do dia", "o que aconteceu hoje"],
    primary_tables: ["operation_audit_logs", "passagens_turno", "eventos_turno", "relatorios_dia"],
    secondary_tables: ["fiscal_ai_snapshots", "fiscal_ai_actions"],
    key_columns: [
      "operation_audit_logs.created_at",
      "operation_audit_logs.area",
      "operation_audit_logs.action",
      "operation_audit_logs.title",
      "operation_audit_logs.description",
      "passagens_turno.resumo",
      "passagens_turno.pendencias",
      "passagens_turno.recados",
    ],
  },
  apoio_operacional: {
    use_when: ["procedimento", "guia rapido", "formulario", "anexo", "cupom", "desconto"],
    primary_tables: [
      "procedimentos",
      "guia_rapido",
      "formularios",
      "respostas_formulario",
      "operation_attachments",
      "cupom_configuracoes",
      "desconto_calculos",
    ],
  },
  arquitetura_organizacional_futura: {
    use_when: ["organizacao", "filial", "setor", "postos operacionais", "comunicados", "treinamento"],
    primary_tables: [
      "organizations",
      "branches",
      "sectors",
      "user_profiles",
      "employees",
      "schedules",
      "attendance_events",
      "operational_status",
      "post_allocations",
      "cash_movements",
    ],
    note:
      "Essas tabelas usam organization_id/branch_id. So devem ser consultadas quando o fiscal_id estiver vinculado a user_profiles/auth_user_id.",
  },
};

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

function boolValue(value: unknown, fallback = false) {
  if (typeof value === "boolean") return value;
  if (typeof value === "string") {
    const normalized = value.toLowerCase().trim();
    if (normalized === "true" || normalized === "1" || normalized === "sim") {
      return true;
    }
    if (normalized === "false" || normalized === "0" || normalized === "nao") {
      return false;
    }
  }
  return fallback;
}

function intValue(value: unknown, fallback = 0) {
  const parsed = numberValue(value);
  return parsed == null ? fallback : Math.trunc(parsed);
}

function normalizedStatus(value: unknown, fallback = "") {
  return text(value, fallback).trim().toLowerCase();
}

function isClosedStatus(status: unknown) {
  return [
    "concluida",
    "concluido",
    "resolvida",
    "resolvido",
    "entregue",
    "cancelada",
    "cancelado",
    "finalizado",
    "finalizada",
    "dismissed",
    "executed",
  ].includes(normalizedStatus(status));
}

function isOpenDelivery(row: Record<string, unknown>) {
  return !isClosedStatus(row.status);
}

function addDays(date: Date, days: number) {
  const next = new Date(date);
  next.setUTCDate(next.getUTCDate() + days);
  return next;
}

function isoDate(date: Date) {
  return date.toISOString().slice(0, 10);
}

function localDateParts(date = new Date(), timeZone = DEFAULT_TIME_ZONE) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date);

  const get = (type: string) =>
    Number(parts.find((part) => part.type === type)?.value ?? "0");

  return {
    year: get("year"),
    month: get("month"),
    day: get("day"),
  };
}

function saoPauloDayStartUtc(date = new Date()) {
  const parts = localDateParts(date);
  return new Date(Date.UTC(parts.year, parts.month - 1, parts.day, 3, 0, 0));
}

function buildDateWindow(config: TableContextConfig) {
  const startOfToday = saoPauloDayStartUtc();
  const start = addDays(startOfToday, -(config.daysBack ?? 0));
  const end = addDays(startOfToday, (config.daysForward ?? 0) + 1);
  return {
    startIso: start.toISOString(),
    endIso: end.toISOString(),
    startDate: isoDate(start),
    endDate: isoDate(end),
    todayDate: isoDate(startOfToday),
  };
}

function truncateText(value: string, maxLength: number) {
  const normalized = value.replace(/\s+/g, " ").trim();
  if (normalized.length <= maxLength) return normalized;
  return `${normalized.slice(0, maxLength).trim()}...`;
}

function compactRecord(record: Record<string, unknown>, maxChars: number): Record<string, unknown> {
  const output: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(record)) {
    if (typeof value === "string") {
      output[key] = truncateText(value, maxChars);
    } else if (Array.isArray(value)) {
      output[key] = value.slice(0, 12).map((item) =>
        typeof item === "string"
          ? truncateText(item, maxChars)
          : asRecord(item)
      );
    } else if (value && typeof value === "object") {
      output[key] = asRecord(value);
    } else {
      output[key] = value;
    }
  }
  return output;
}

function eventRelevanceScore(event: Record<string, unknown>) {
  let score = 0;
  if (eventStatus(event) === "pending") score += 80;
  if (eventPriority(event) === "critica") score += 70;
  if (eventPriority(event) === "alta") score += 50;
  if (eventCategory(event) === "caixa") score += 35;
  if (eventCategory(event) === "problema_operacional") score += 35;
  if (event.needs_review === true || event.analysis_status === "needs_review") score += 30;
  if (event.analysis_status === "needs_file") score += 25;
  return score;
}

function compactList(value: unknown, limit: number, maxChars: number) {
  if (limit <= 0) return [];
  return asArray(value)
    .slice(0, limit)
    .map((item) => compactRecord(item, maxChars));
}

function compactEvents(value: unknown, limit: number, maxChars: number) {
  return [...asArray(value)]
    .sort((a, b) => eventRelevanceScore(b) - eventRelevanceScore(a))
    .slice(0, limit)
    .map((event) => compactRecord(event, maxChars));
}

function compactContext(context: Record<string, unknown>, level: ContextLevel) {
  const limits = {
    full: { default: 45, events: 70, colaboradores: 120, escala: 160, chars: 260 },
    reduced: { default: 24, events: 35, colaboradores: 60, escala: 90, chars: 170 },
    minimal: { default: 10, events: 14, colaboradores: 20, escala: 25, chars: 100 },
  }[level];

  const listLimits: Record<string, number> = {
    fiscal_profile: 1,
    colaboradores: limits.colaboradores,
    turnos_escala: limits.escala,
    registros_ponto: limits.default,
    caixas: limits.default,
    alocacoes: limits.default,
    pacote_plantao: limits.default,
    outro_setor: limits.default,
    pausas_cafe: limits.default,
    entregas: limits.default,
    notas: limits.default,
    ocorrencias: limits.default,
    checklist_execucoes: limits.default,
    checklist_templates: limits.default,
    fiscal_events: limits.events,
    passagens_turno: limits.default,
    eventos_turno: limits.default,
    relatorios_dia: Math.min(limits.default, 12),
    operation_audit_logs: limits.default,
    operation_attachments: Math.min(limits.default, 20),
    operation_notification_queue: limits.default,
    operation_sla_rules: Math.min(limits.default, 20),
    dashboard_quick_notes: limits.default,
    dashboard_layouts: Math.min(limits.default, 6),
    ai_inbox_items: limits.default,
    operation_media_insights: limits.default,
    formularios: Math.min(limits.default, 20),
    respostas_formulario: limits.default,
    procedimentos: Math.min(limits.default, 24),
    guia_rapido: Math.min(limits.default, 24),
    desconto_calculos: Math.min(limits.default, 20),
    cupom_configuracoes: 1,
  };

  const output: Record<string, unknown> = {
    ...context,
    context_policy: {
      ...asRecord(context.context_policy),
      edge_context_level: level,
      edge_limits: limits,
    },
  };

  for (const [key, limit] of Object.entries(listLimits)) {
    output[key] = key === "fiscal_events"
      ? compactEvents(context[key], limit, limits.chars)
      : compactList(context[key], limit, limits.chars);
  }

  return output;
}

function compactInput(input: FiscalAiInput, level: ContextLevel): FiscalAiInput {
  return {
    ...input,
    context: compactContext(asRecord(input.context), level),
  };
}

async function fetchTableContext(
  supabase: ReturnType<typeof createClient>,
  config: TableContextConfig,
  fiscalId: string,
) {
  try {
    const select = config.select ?? "*";
    const fiscalColumn = config.fiscalColumn ?? "fiscal_id";
    let query = supabase
      .from(config.table)
      .select(select)
      .eq(fiscalColumn, fiscalId);

    if (config.dateColumn) {
      const window = buildDateWindow(config);
      if (config.dateKind === "date") {
        query = query.gte(config.dateColumn, window.startDate).lt(
          config.dateColumn,
          window.endDate,
        );
      } else {
        query = query.gte(config.dateColumn, window.startIso).lt(
          config.dateColumn,
          window.endIso,
        );
      }
    }

    for (const filter of config.filters ?? []) {
      if (filter.op === "eq") query = query.eq(filter.column, filter.value);
      if (filter.op === "neq") query = query.neq(filter.column, filter.value);
    }

    if (config.order) {
      query = query.order(config.order, { ascending: config.ascending ?? false });
    }

    query = query.limit(config.limit ?? 100);
    const { data, error } = await query;
    if (error) throw error;
    return {
      key: config.key,
      rows: Array.isArray(data) ? data.map(asRecord) : data ? [asRecord(data)] : [],
      error: null as string | null,
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.warn(`[fiscal-ai-agent] table context ${config.table}:`, message);
    return {
      key: config.key,
      rows: [] as Record<string, unknown>[],
      error: message,
    };
  }
}

function statusCount(rows: Record<string, unknown>[], status: string) {
  return rows.filter((row) => normalizedStatus(row.status) === status).length;
}

function openCount(rows: Record<string, unknown>[]) {
  return rows.filter((row) => !isClosedStatus(row.status)).length;
}

function buildOperationalMetrics(context: Record<string, unknown>) {
  const colaboradores = asArray(context.colaboradores);
  const escala = asArray(context.turnos_escala);
  const entregas = asArray(context.entregas);
  const pausas = asArray(context.pausas_cafe);
  const alocacoes = asArray(context.alocacoes);
  const notas = asArray(context.notas);
  const ocorrencias = asArray(context.ocorrencias);
  const fiscalEvents = asArray(context.fiscal_events);
  const checklists = asArray(context.checklist_execucoes);

  const folgasHoje = escala.filter((turno) => boolValue(turno.folga));
  const pausasAtivas = pausas.filter((pausa) => !text(pausa.finalizado_em));
  const alocacoesAtivas = alocacoes.filter((alocacao) => {
    const status = normalizedStatus(alocacao.status, "ativo");
    return status === "ativo" && !text(alocacao.liberado_em);
  });

  return {
    colaboradores_ativos: colaboradores.filter((row) => boolValue(row.ativo, true)).length,
    colaboradores_inativos: colaboradores.filter((row) => !boolValue(row.ativo, true)).length,
    folgas_hoje: folgasHoje.length,
    escala_hoje: escala.length,
    entregas_total_contexto: entregas.length,
    entregas_pendentes: openCount(entregas),
    entregas_separadas: statusCount(entregas, "separada"),
    entregas_em_rota: statusCount(entregas, "saiu_para_entrega"),
    pausas_ativas: pausasAtivas.length,
    cafes_ou_intervalos_hoje: pausas.length,
    alocacoes_ativas: alocacoesAtivas.length,
    alocacoes_contexto: alocacoes.length,
    notas_abertas: notas.filter((nota) => !boolValue(nota.concluida)).length,
    ocorrencias_abertas: ocorrencias.filter((ocorrencia) => !boolValue(ocorrencia.resolvida)).length,
    eventos_fiscais_pendentes: fiscalEvents.filter((event) => eventStatus(event) === "pending").length,
    checklists_pendentes: checklists.filter((checklist) => !boolValue(checklist.concluido)).length,
  };
}

async function fetchOperationalContext(
  supabase: ReturnType<typeof createClient>,
  fiscalId?: string | null,
) {
  if (!fiscalId) return {};

  const entries = await Promise.all(
    tableContextConfigs.map((config) => fetchTableContext(supabase, config, fiscalId)),
  );
  const context: Record<string, unknown> = {};
  const tableErrors: Record<string, string> = {};

  for (const entry of entries) {
    context[entry.key] = entry.rows;
    if (entry.error) tableErrors[entry.key] = entry.error;
  }

  try {
    const collaboratorIds = asArray(context.colaboradores)
      .map((row) => text(row.id))
      .filter((id) => id.length > 0)
      .slice(0, 180);
    if (collaboratorIds.length > 0) {
      const pointWindow = buildDateWindow({
        key: "registros_ponto",
        table: "registros_ponto",
        daysBack: 1,
        daysForward: 1,
      });
      const { data, error } = await supabase
        .from("registros_ponto")
        .select("*")
        .in("colaborador_id", collaboratorIds)
        .gte("data", pointWindow.startDate)
        .lt("data", pointWindow.endDate)
        .order("data", { ascending: false })
        .limit(160);
      if (error) throw error;
      context.registros_ponto = Array.isArray(data) ? data.map(asRecord) : [];
    } else {
      context.registros_ponto = [];
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    tableErrors.registros_ponto = message;
    context.registros_ponto = [];
  }

  const window = buildDateWindow({ key: "meta", table: "meta" });
  context.operational_metrics = buildOperationalMetrics(context);
  context.knowledge_map = operationalKnowledgeMap;
  context.table_catalog = [
    ...tableContextConfigs.map((config) => ({
      key: config.key,
      table: config.table,
      rows_loaded: asArray(context[config.key]).length,
      fiscal_column: config.fiscalColumn ?? "fiscal_id",
      date_column: config.dateColumn ?? null,
    })),
    {
      key: "registros_ponto",
      table: "registros_ponto",
      rows_loaded: asArray(context.registros_ponto).length,
      fiscal_column: "via colaboradores.id",
      date_column: "data",
    },
  ];
  context.context_policy = {
    source: "supabase_service_role",
    fiscal_scope: fiscalId,
    time_zone: DEFAULT_TIME_ZONE,
    today: window.todayDate,
    generated_at: new Date().toISOString(),
    table_errors: tableErrors,
    write_policy: "mutating tools require explicit confirmation and are logged",
  };

  return context;
}

async function fetchWithTimeout(url: string, init: RequestInit, timeoutMs = 25000) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...init, signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
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
  const metrics = asRecord(context.operational_metrics);
  const entregas = asArray(context.entregas);
  const ocorrencias = asArray(context.ocorrencias);
  const notas = asArray(context.notas);
  const checklists = asArray(context.checklist_execucoes);
  const alocacoes = asArray(context.alocacoes);
  const pausas = asArray(context.pausas_cafe);
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
    "## Numeros do contexto",
    `- Escala carregada: ${intValue(metrics.escala_hoje)} registro(s)`,
    `- Folgas hoje: ${intValue(metrics.folgas_hoje)}`,
    `- Entregas abertas: ${intValue(metrics.entregas_pendentes)}`,
    `- Pausas ativas: ${intValue(metrics.pausas_ativas)}`,
    `- Alocacoes ativas: ${intValue(metrics.alocacoes_ativas)}`,
    "",
    "## Pendencias por categoria",
    ...Array.from(byCategory.entries()).map(
      ([category, count]) => `- ${normalizeCategory(category)}: ${count}`,
    ),
    ...(entregas.length
      ? ["", "## Entregas recentes", ...entregas.slice(0, 10).map((entrega) =>
        `- ${text(entrega.numero_nota) || text(entrega.id)}: ${text(entrega.status, "sem status")} ${text(entrega.cliente_nome)}`.trim()
      )]
      : []),
    ...(ocorrencias.length || notas.length || checklists.length
      ? [
        "",
        "## Pendencias de rotina",
        ...ocorrencias
          .filter((item) => !boolValue(item.resolvida))
          .slice(0, 8)
          .map((item) => `- Ocorrencia: ${text(item.titulo) || text(item.descricao) || text(item.id)}`),
        ...notas
          .filter((item) => !boolValue(item.concluida))
          .slice(0, 8)
          .map((item) => `- Nota: ${text(item.titulo) || text(item.conteudo) || text(item.id)}`),
        ...checklists
          .filter((item) => !boolValue(item.concluido))
          .slice(0, 8)
          .map((item) => `- Checklist: ${text(item.tipo) || text(item.id)}`),
      ]
      : []),
    ...(alocacoes.length || pausas.length
      ? [
        "",
        "## Operacao de frente de caixa",
        ...alocacoes
          .filter((item) => normalizedStatus(item.status, "ativo") === "ativo" && !text(item.liberado_em))
          .slice(0, 12)
          .map((item) =>
            `- Alocado: ${text(item.colaborador_nome) || text(item.colaborador_id)} no caixa ${text(item.caixa_nome) || text(item.caixa_id)}`
          ),
        ...pausas
          .filter((item) => !text(item.finalizado_em))
          .slice(0, 12)
          .map((item) =>
            `- Pausa ativa: ${text(item.colaborador_nome) || text(item.colaborador_id)} (${intValue(item.duracao_minutos, 0)} min)`
          ),
      ]
      : []),
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

function buildShiftHandoffReport(context: Record<string, unknown>, insight: FiscalAiInsight) {
  const base = buildReport(context, insight);
  const logs = asArray(context.operation_audit_logs);
  const passagens = asArray(context.passagens_turno);
  const recados = [
    ...logs.slice(0, 12).map((log) =>
      `${text(log.title) || text(log.action)}${text(log.description) ? `: ${text(log.description)}` : ""}`
    ),
    ...passagens.slice(0, 3).map((passagem) =>
      `Passagem anterior: ${text(passagem.resumo)} ${text(passagem.pendencias)}`
    ),
  ].filter((line) => line.trim().length > 0);

  return [
    "# Passagem de turno sugerida pela IA",
    "",
    "## Resumo para o proximo fiscal",
    insight.summary,
    "",
    base.replace("# Briefing fiscal\n\n", ""),
    "",
    "## Recados / linha do tempo",
    ...(recados.length ? recados.map((line) => `- ${line}`) : ["- Sem recados recentes registrados."]),
  ].join("\n");
}

function splitHandoffArtifact(artifact: string) {
  const pendingMatch = artifact.match(/## Pendencias[\s\S]*?(?=\n## |$)/i);
  const notesMatch = artifact.match(/## Recados[\s\S]*?(?=\n## |$)/i);
  return {
    resumo: artifact.split("\n").slice(0, 12).join("\n").trim(),
    pendencias: pendingMatch?.[0]?.replace(/## Pendencias[^\n]*\n?/i, "").trim() ?? "",
    recados: notesMatch?.[0]?.replace(/## Recados[^\n]*\n?/i, "").trim() ?? "",
  };
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
  const metrics = asRecord(context.operational_metrics);
  const events = asArray(context.fiscal_events);
  const caixas = asArray(context.caixas);
  const colaboradores = asArray(context.colaboradores);
  const escala = asArray(context.turnos_escala);
  const entregas = asArray(context.entregas);
  const pausas = asArray(context.pausas_cafe);
  const alocacoes = asArray(context.alocacoes);
  const checklists = asArray(context.checklist_execucoes);
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

  const entregasPendentes = intValue(metrics.entregas_pendentes);
  if (entregasPendentes > 0) {
    risks.push({
      title: "Entregas abertas",
      severity: entregasPendentes >= 6 ? "alto" : "medio",
      reason: `${entregasPendentes} entrega(s) ainda exigem acompanhamento.`,
      evidence: entregas
        .slice(0, 3)
        .map((entrega) =>
          `${text(entrega.numero_nota) || text(entrega.id)} - ${text(entrega.status, "sem status")}`
        )
        .join("; "),
      action: "Conferir entregas separadas, em rota e atrasadas antes de fechar o turno.",
      target: { table: "entregas" },
    });
  }

  const checklistsPendentes = intValue(metrics.checklists_pendentes);
  if (checklistsPendentes > 0) {
    risks.push({
      title: "Checklist em aberto",
      severity: "medio",
      reason: `${checklistsPendentes} checklist(s) ainda nao foram concluidos.`,
      evidence: checklists
        .filter((checklist) => !boolValue(checklist.concluido))
        .slice(0, 3)
        .map((checklist) => text(checklist.tipo) || text(checklist.id))
        .join("; "),
      action: "Concluir ou justificar checklists pendentes antes da passagem de turno.",
      target: { table: "checklist_execucoes" },
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
        ? `${colaboradores.length} colaborador(es), ${escala.length} turno(s) de escala e ${intValue(metrics.folgas_hoje)} folga(s) no contexto.`
        : "Carregue colaboradores para cruzar ausencias, escala e reincidencias.",
      priority: absences.length > 0 ? "alta" : "media",
      owner: "Fiscal do turno",
      requires_confirmation: false,
    },
    {
      title: "Conferir cafes e intervalos",
      description: `${intValue(metrics.pausas_ativas)} pausa(s) ativa(s), ${pausas.length} registro(s) recente(s) e ${alocacoes.length} alocacao(oes) no contexto.`,
      priority: intValue(metrics.pausas_ativas) > 0 ? "media" : "baixa",
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
    ? answerQuestionLocally(text(input.question), { context, pending, risks, totalCash })
    : "";

  return {
    summary: pending.length > 0
      ? `${pending.length} pendencia(s) fiscal(is) abertas, ${critical.length} de alta prioridade. Contexto inclui escala, entregas, cafe, alocacoes e linha do tempo.`
      : `Contexto operacional carregado: ${intValue(metrics.escala_hoje)} escala(s), ${intValue(metrics.entregas_pendentes)} entrega(s) aberta(s), ${intValue(metrics.pausas_ativas)} pausa(s) ativa(s).`,
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
    source: "local_edge",
    fonte: "local_edge",
    model: null,
  };
}

function answerQuestionLocally(
  question: string,
  data: {
    context: Record<string, unknown>;
    pending: Record<string, unknown>[];
    risks: Record<string, unknown>[];
    totalCash: number;
  },
) {
  const q = question.toLowerCase();
  const context = data.context;
  const escala = asArray(context.turnos_escala);
  const entregas = asArray(context.entregas);
  const pausas = asArray(context.pausas_cafe);
  const alocacoes = asArray(context.alocacoes);
  const colaboradores = asArray(context.colaboradores);
  const ocorrencias = asArray(context.ocorrencias);
  const notas = asArray(context.notas);
  const checklists = asArray(context.checklist_execucoes);

  const nameOf = (row: Record<string, unknown>) =>
    text(row.nome) ||
    text(row.colaborador_nome) ||
    text(row.employee_name) ||
    text(row.cliente_nome) ||
    text(row.titulo) ||
    text(row.description) ||
    text(row.id);

  const shortList = (items: string[], empty: string) =>
    items.length ? items.slice(0, 12).join(", ") : empty;

  if (q.includes("folga") || q.includes("folgando")) {
    const folgas = escala.filter((turno) => boolValue(turno.folga));
    return folgas.length > 0
      ? `Hoje estao de folga: ${shortList(folgas.map(nameOf), "nenhum nome identificado")}.`
      : "Nao encontrei colaboradores marcados como folga na escala carregada.";
  }

  if (q.includes("entrega")) {
    const abertas = entregas.filter(isOpenDelivery);
    const porStatus = new Map<string, number>();
    for (const entrega of entregas) {
      const status = normalizedStatus(entrega.status, "sem_status");
      porStatus.set(status, (porStatus.get(status) ?? 0) + 1);
    }
    const resumoStatus = Array.from(porStatus.entries())
      .map(([status, count]) => `${status}: ${count}`)
      .join("; ");
    return `Encontrei ${entregas.length} entrega(s) no contexto recente, ${abertas.length} aberta(s). ${resumoStatus || "Sem status detalhado."}`;
  }

  if (q.includes("escala") || q.includes("horario") || q.includes("horário")) {
    const linhas = escala.slice(0, 18).map((turno) => {
      const nome = nameOf(turno);
      if (boolValue(turno.folga)) return `${nome}: folga`;
      const entrada = text(turno.entrada, "--");
      const intervalo = text(turno.intervalo);
      const retorno = text(turno.retorno);
      const saida = text(turno.saida, "--");
      const meio = intervalo || retorno ? `, intervalo ${intervalo || "?"}/${retorno || "?"}` : "";
      return `${nome}: ${entrada} ate ${saida}${meio}`;
    });
    return linhas.length
      ? `Escala carregada: ${linhas.join("; ")}.`
      : "Nao encontrei escala carregada no contexto atual.";
  }

  if (q.includes("cafe") || q.includes("café") || q.includes("intervalo")) {
    const ativas = pausas.filter((pausa) => !text(pausa.finalizado_em));
    return ativas.length
      ? `Pausas ativas: ${shortList(ativas.map(nameOf), "sem nomes identificados")}. Total no contexto: ${pausas.length}.`
      : `Nao encontrei cafe/intervalo ativo agora. Total no contexto recente: ${pausas.length}.`;
  }

  if (q.includes("aloca") || q.includes("caixa") || q.includes("pdv")) {
    const ativas = alocacoes.filter((alocacao) =>
      normalizedStatus(alocacao.status, "ativo") === "ativo" && !text(alocacao.liberado_em)
    );
    if (q.includes("caixa") || q.includes("pdv")) {
      const linhas = ativas.slice(0, 18).map((alocacao) =>
        `${text(alocacao.colaborador_nome) || text(alocacao.colaborador_id)} no caixa ${text(alocacao.caixa_nome) || text(alocacao.caixa_id)}`
      );
      return linhas.length
        ? `Alocacoes ativas: ${linhas.join("; ")}.`
        : "Nao encontrei alocacoes ativas no contexto atual.";
    }
  }

  if (
    q.includes("passagem") ||
    q.includes("passar o turno") ||
    q.includes("pendente") ||
    q.includes("sem resolver")
  ) {
    const abertas = [
      ...data.pending.map((item) => `Balcao: ${eventDescription(item)}`),
      ...ocorrencias
        .filter((item) => !boolValue(item.resolvida))
        .map((item) => `Ocorrencia: ${text(item.titulo) || text(item.descricao)}`),
      ...notas
        .filter((item) => !boolValue(item.concluida))
        .map((item) => `Nota: ${text(item.titulo) || text(item.conteudo)}`),
      ...checklists
        .filter((item) => !boolValue(item.concluido))
        .map((item) => `Checklist: ${text(item.tipo) || text(item.id)}`),
    ].filter((item) => item.trim().length > 0);

    return abertas.length
      ? `Para passagem de turno, encontrei ${abertas.length} item(ns) aberto(s): ${abertas.slice(0, 10).join("; ")}.`
      : "Nao encontrei pendencias abertas para passagem de turno no contexto atual.";
  }

  if (q.includes("colaborador") || q.includes("equipe")) {
    const ativos = colaboradores.filter((row) => boolValue(row.ativo, true));
    return `Encontrei ${ativos.length} colaborador(es) ativo(s) no cadastro e ${escala.length} registro(s) de escala no periodo carregado.`;
  }

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
    source: text(raw.source) || text(raw.fonte) || fallback.source,
    fonte: text(raw.fonte) || text(raw.source) || fallback.fonte,
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

function safeErrorMessage(error: unknown) {
  const raw = error instanceof Error ? error.message : String(error);
  return truncateText(
    raw
      .replace(/sk-[A-Za-z0-9_-]+/g, "sk-***")
      .replace(/AIza[A-Za-z0-9_-]+/g, "AIza***")
      .replace(/Bearer\s+[A-Za-z0-9._-]+/gi, "Bearer ***"),
    220,
  );
}

function providerFromFailure(failure: string) {
  const lower = failure.toLowerCase();
  if (lower.startsWith("openai")) return "OpenAI";
  if (lower.startsWith("gemini")) return "Gemini";
  if (lower.startsWith("anthropic")) return "Anthropic";
  return "IA externa";
}

function classifyFailure(failure: string) {
  const lower = failure.toLowerCase();
  if (
    lower.includes("quota") ||
    lower.includes("credit balance") ||
    lower.includes("billing") ||
    lower.includes("rate-limits") ||
    lower.includes("429")
  ) {
    return "sem cota/credito";
  }
  if (
    lower.includes("api_key") ||
    lower.includes("api key") ||
    lower.includes("nao configurada") ||
    lower.includes("unauthorized") ||
    lower.includes("401")
  ) {
    return "sem chave valida";
  }
  if (
    lower.includes("model") ||
    lower.includes("not found") ||
    lower.includes("unsupported")
  ) {
    return "com modelo indisponivel";
  }
  return "falhou";
}

function summarizeAiFailures(failures: string[]) {
  const byReason = new Map<string, Set<string>>();

  for (const failure of failures) {
    const reason = classifyFailure(failure);
    const provider = providerFromFailure(failure);
    const providers = byReason.get(reason) ?? new Set<string>();
    providers.add(provider);
    byReason.set(reason, providers);
  }

  if (byReason.size === 0) {
    return "IA externa falhou; usando analise local.";
  }

  const priority = [
    "sem cota/credito",
    "sem chave valida",
    "com modelo indisponivel",
    "falhou",
  ];
  const details = priority
    .filter((reason) => byReason.has(reason))
    .map((reason) => `${Array.from(byReason.get(reason)!).join("/")} ${reason}`)
    .join("; ");

  return `IA externa indisponivel (${details}); usando analise local.`;
}

const systemPrompt = `
Voce e um agente operacional para fiscais de caixa de supermercado.
Analise todo o contexto operacional do app: escala, colaboradores, caixas, alocacoes,
cafe/intervalos, entregas, notas, ocorrencias, checklists, Balcao Fiscal,
linha do tempo, passagens de turno, relatorios e anexos.
O contexto vem de tabelas Supabase escopadas por fiscal_id. Use ids/tabelas reais
quando sugerir uma acao. Se a pergunta for objetiva, responda em chat_answer com
o dado encontrado e cite de onde veio de forma simples.
Use context.knowledge_map como mapa de localizacao: ele indica em qual tabela e
coluna procurar cada tipo de informacao e quais relacoes ligam os registros.

Voce deve funcionar como auxiliar do fiscal:
- responder quem esta de folga, horarios, escala e disponibilidade;
- contar entregas, pendencias, ocorrencias, notas e checklists;
- organizar o que ficou sem resolver para passagem de turno;
- sugerir alocacoes, liberacoes, cafe/intervalos e registros de timeline;
- gerar relatorios operacionais claros.

Nunca finja ter executado uma acao. Para qualquer escrita ou mudanca de estado,
preencha action_plan com ferramenta e confirmation_required=true.
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
- generate_shift_handoff_report: gera e, se confirmado, registra passagem de turno organizada.
- create_followup_event: cria evento manual de acompanhamento.
- register_timeline_event: registra acontecimento na linha do tempo operation_audit_logs.
- create_allocation: aloca colaborador em caixa.
- release_allocation: libera alocacao ativa.
- start_cafe_pause: inicia cafe ou intervalo de colaborador.
- finish_cafe_pause: finaliza cafe ou intervalo ativo.
Ferramentas que alteram dados sempre requerem confirmacao.
`;

function openAiResponseText(data: Record<string, unknown>) {
  const directText = text(data.output_text);
  if (directText) return directText;

  const output = Array.isArray(data.output) ? data.output : [];
  const chunks: string[] = [];
  for (const item of output) {
    const itemRecord = asRecord(item);
    const content = Array.isArray(itemRecord.content)
      ? itemRecord.content as unknown[]
      : [];
    for (const part of content) {
      const record = asRecord(part);
      const value = text(record.text);
      if (value) chunks.push(value);
    }
  }
  return chunks.join("");
}

async function callOpenAI(
  input: FiscalAiInput,
  fallback: FiscalAiInsight,
  model: string,
  source: string,
  warning?: string,
) {
  const response = await fetchWithTimeout("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model,
      max_output_tokens: 1600,
      truncation: "auto",
      input: [
        { role: "system", content: systemPrompt },
        { role: "user", content: JSON.stringify(input) },
      ],
      text: {
        format: { type: "json_object" },
      },
    }),
  });

  if (!response.ok) throw new Error(await response.text());
  const data = await response.json();
  const raw = openAiResponseText(asRecord(data));
  if (!raw) throw new Error("OpenAI returned an empty response.");
  return normalizeInsight(parseJsonObject(raw), {
    ...fallback,
    provider: "openai",
    source,
    fonte: source,
    model,
    warning,
  });
}

const fiscalAiGeminiSchema = {
  type: "OBJECT",
  properties: {
    summary: { type: "STRING" },
    overall_severity: { type: "STRING" },
    risks: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          title: { type: "STRING" },
          severity: { type: "STRING" },
          reason: { type: "STRING" },
          evidence: { type: "STRING" },
          action: { type: "STRING" },
          target: { type: "OBJECT" },
        },
      },
    },
    recommendations: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          title: { type: "STRING" },
          description: { type: "STRING" },
          priority: { type: "STRING" },
          owner: { type: "STRING" },
          requires_confirmation: { type: "BOOLEAN" },
        },
      },
    },
    next_action: {
      type: "OBJECT",
      properties: {
        title: { type: "STRING" },
        description: { type: "STRING" },
        can_execute: { type: "BOOLEAN" },
      },
    },
    action_plan: {
      type: "OBJECT",
      properties: {
        mode: { type: "STRING" },
        tool_name: { type: "STRING" },
        description: { type: "STRING" },
        confidence: { type: "NUMBER" },
        arguments: { type: "OBJECT" },
        arguments_summary: { type: "STRING" },
        confirmation_required: { type: "BOOLEAN" },
      },
    },
    action_result: { type: "OBJECT" },
    resolution: { type: "OBJECT" },
    chat_answer: { type: "STRING" },
    tools_used: { type: "ARRAY", items: { type: "STRING" } },
  },
  required: [
    "summary",
    "overall_severity",
    "risks",
    "recommendations",
    "next_action",
    "action_plan",
    "action_result",
    "resolution",
    "chat_answer",
    "tools_used",
  ],
};

function geminiResponseText(data: Record<string, unknown>) {
  const candidates = Array.isArray(data.candidates) ? data.candidates : [];
  const chunks: string[] = [];

  for (const candidate of candidates) {
    const content = asRecord(asRecord(candidate).content);
    const parts = Array.isArray(content.parts) ? content.parts : [];
    for (const part of parts) {
      const value = text(asRecord(part).text);
      if (value) chunks.push(value);
    }
  }

  return chunks.join("");
}

async function callGemini(
  input: FiscalAiInput,
  fallback: FiscalAiInsight,
  model: string,
  source: string,
  warning: string,
) {
  const endpoint =
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(GEMINI_API_KEY)}`;
  const response = await fetchWithTimeout(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [
        {
          role: "user",
          parts: [
            {
              text: `${systemPrompt}\n\nEntrada JSON:\n${JSON.stringify(input)}`,
            },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.2,
        maxOutputTokens: 1400,
        responseMimeType: "application/json",
        responseSchema: fiscalAiGeminiSchema,
      },
    }),
  });

  if (!response.ok) throw new Error(await response.text());
  const data = await response.json();
  const raw = geminiResponseText(asRecord(data));
  if (!raw) throw new Error("Gemini returned an empty response.");
  return normalizeInsight(parseJsonObject(raw), {
    ...fallback,
    provider: "gemini",
    source,
    fonte: source,
    model,
    warning,
  });
}

async function callAnthropic(input: FiscalAiInput, fallback: FiscalAiInsight) {
  const response = await fetchWithTimeout("https://api.anthropic.com/v1/messages", {
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
    source: "ia_anthropic",
    fonte: "ia_anthropic",
    model: ANTHROPIC_MODEL,
    warning: "OpenAI/Gemini indisponiveis; usando Anthropic.",
  });
}

async function buildAiInsight(input: FiscalAiInput) {
  const fallback = buildFallbackInsight(input);
  const failures: string[] = [];

  if (OPENAI_API_KEY) {
    try {
      return await callOpenAI(compactInput(input, "full"), fallback, OPENAI_MODEL, "ia_completa");
    } catch (error) {
      failures.push(`OpenAI ${OPENAI_MODEL}: ${safeErrorMessage(error)}`);
      console.warn("[fiscal-ai-agent] OpenAI primary fallback:", error);
    }

    try {
      return await callOpenAI(
        compactInput(input, "reduced"),
        fallback,
        OPENAI_MINI_MODEL,
        "ia_mini",
        "IA completa indisponivel; usando analise resumida.",
      );
    } catch (error) {
      failures.push(`OpenAI ${OPENAI_MINI_MODEL}: ${safeErrorMessage(error)}`);
      console.warn("[fiscal-ai-agent] OpenAI mini fallback:", error);
    }
  } else {
    failures.push("OpenAI: OPENAI_API_KEY nao configurada.");
  }

  if (GEMINI_API_KEY) {
    try {
      return await callGemini(
        compactInput(input, "reduced"),
        fallback,
        GEMINI_MODEL,
        "ia_gemini",
        "OpenAI indisponivel; usando Gemini.",
      );
    } catch (error) {
      failures.push(`Gemini ${GEMINI_MODEL}: ${safeErrorMessage(error)}`);
      console.warn("[fiscal-ai-agent] Gemini fallback:", error);
    }

    try {
      return await callGemini(
        compactInput(input, "minimal"),
        fallback,
        GEMINI_LITE_MODEL,
        "ia_gemini_lite",
        "IA principal indisponivel; usando Gemini Lite com contexto minimo.",
      );
    } catch (error) {
      failures.push(`Gemini ${GEMINI_LITE_MODEL}: ${safeErrorMessage(error)}`);
      console.warn("[fiscal-ai-agent] Gemini Lite fallback:", error);
    }
  } else {
    failures.push("Gemini: GEMINI_API_KEY nao configurada.");
  }

  if (ANTHROPIC_API_KEY) {
    try {
      return await callAnthropic(compactInput(input, "minimal"), fallback);
    } catch (error) {
      failures.push(`Anthropic ${ANTHROPIC_MODEL}: ${safeErrorMessage(error)}`);
      console.warn("[fiscal-ai-agent] Anthropic fallback:", error);
    }
  } else {
    failures.push("Anthropic: ANTHROPIC_API_KEY nao configurada.");
  }

  return {
    ...fallback,
    provider: "local" as const,
    source: "local_offline",
    fonte: "local_offline",
    warning: OPENAI_API_KEY || GEMINI_API_KEY || ANTHROPIC_API_KEY
      ? summarizeAiFailures(failures)
      : "Configure OPENAI_API_KEY ou GEMINI_API_KEY para respostas generativas.",
  };
}

function actionResult(
  status: string,
  toolName: string,
  title: string,
  message: string,
  artifactMarkdown: string | null = null,
) {
  return {
    status,
    tool_name: toolName,
    title,
    message,
    artifact_markdown: artifactMarkdown,
  };
}

function requireConfirmation(insight: FiscalAiInsight, toolName: string, message: string) {
  return {
    ...insight,
    action_result: actionResult(
      "pending_confirmation",
      toolName,
      "Confirmacao necessaria",
      message,
    ),
    tools_used: [...new Set([...insight.tools_used, toolName])],
  };
}

function actionFailed(insight: FiscalAiInsight, toolName: string, message: string) {
  return {
    ...insight,
    action_result: actionResult("failed", toolName, "Acao nao executada", message),
    tools_used: [...new Set([...insight.tools_used, toolName])],
  };
}

function auditSeverity(value: unknown): "info" | "success" | "warning" | "critical" {
  const severity = text(value, "info").toLowerCase();
  if (severity === "success") return "success";
  if (severity === "warning" || severity === "alto" || severity === "medio") {
    return "warning";
  }
  if (severity === "critical" || severity === "critico" || severity === "critica") {
    return "critical";
  }
  return "info";
}

async function writeAuditLog(
  supabase: ReturnType<typeof createClient>,
  fiscalId: string | null | undefined,
  payload: {
    area: string;
    action: string;
    entity_type?: string | null;
    entity_id?: string | null;
    severity?: "info" | "success" | "warning" | "critical";
    title?: string | null;
    description?: string | null;
    metadata?: Record<string, unknown>;
  },
) {
  if (!fiscalId) return;
  const { error } = await supabase.from("operation_audit_logs").insert({
    fiscal_id: fiscalId,
    area: payload.area,
    action: payload.action,
    entity_type: payload.entity_type ?? null,
    entity_id: payload.entity_id ?? null,
    severity: payload.severity ?? "info",
    title: payload.title ?? null,
    description: payload.description ?? null,
    metadata: payload.metadata ?? {},
  });
  if (error) console.warn("[fiscal-ai-agent] audit log failed:", error.message);
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
      action_result: actionResult(
        "executed",
        toolName,
        "Briefing gerado",
        "Briefing operacional pronto.",
        buildReport(context, insight),
      ),
      tools_used: [...new Set([...insight.tools_used, toolName])],
    };
  }

  if (toolName === "generate_shift_handoff_report") {
    const artifact = buildShiftHandoffReport(context, insight);
    if (!confirmed) {
      return {
        ...insight,
        action_result: actionResult(
          "pending_confirmation",
          toolName,
          "Passagem pronta para revisar",
          "Confirme para salvar esta passagem de turno no historico.",
          artifact,
        ),
        tools_used: [...new Set([...insight.tools_used, toolName])],
      };
    }

    const sections = splitHandoffArtifact(artifact);
    const { error } = await supabase.from("passagens_turno").insert({
      fiscal_id: input.fiscal_id ?? null,
      resumo: sections.resumo,
      pendencias: sections.pendencias,
      recados: sections.recados,
      registrada_em: new Date().toISOString(),
    });

    if (error) return actionFailed(insight, toolName, error.message);

    await writeAuditLog(supabase, input.fiscal_id, {
      area: "passagem_turno",
      action: "ai_created",
      entity_type: "passagem_turno",
      severity: "success",
      title: "Passagem de turno gerada pela IA",
      description: sections.resumo,
      metadata: { tool: toolName },
    });

    return {
      ...insight,
      action_result: actionResult(
        "executed",
        toolName,
        "Passagem salva",
        "Passagem de turno registrada no historico.",
        artifact,
      ),
      tools_used: [...new Set([...insight.tools_used, toolName])],
    };
  }

  if (toolName === "create_followup_event") {
    if (!confirmed) {
      return requireConfirmation(
        insight,
        toolName,
        "Confirme para criar o evento manual de acompanhamento.",
      );
    }

    const title = text(args.title) ||
      text(args.description) ||
      "Acompanhamento fiscal gerado por IA";
    const notes = text(args.notes) ||
      text(args.reason) ||
      text(insight.summary);
    const priority = text(args.priority, "alta");
    const category = text(args.category, "aviso_geral");

    const { error } = await supabase.from("fiscal_events").insert({
      fiscal_id: input.fiscal_id ?? null,
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
        action_result: actionResult("failed", toolName, "Evento nao criado", error.message),
        tools_used: [...new Set([...insight.tools_used, toolName])],
      };
    }

    await writeAuditLog(supabase, input.fiscal_id, {
      area: "balcao_fiscal",
      action: "ai_followup_created",
      entity_type: "fiscal_event",
      severity: priority === "critica" ? "critical" : "warning",
      title,
      description: notes,
      metadata: { category, priority, tool: toolName },
    });

    return {
      ...insight,
      action_result: actionResult(
        "executed",
        toolName,
        "Evento criado",
        "Evento manual de acompanhamento criado no Balcao Fiscal.",
      ),
      tools_used: [...new Set([...insight.tools_used, toolName])],
    };
  }

  if (toolName === "register_timeline_event") {
    if (!confirmed) {
      return requireConfirmation(
        insight,
        toolName,
        "Confirme para registrar esta informacao na linha do tempo.",
      );
    }

    const title = text(args.title) || text(args.titulo) || "Registro da IA";
    const description = text(args.description) || text(args.descricao) || text(args.notes);
    await writeAuditLog(supabase, input.fiscal_id, {
      area: text(args.area, "ia_fiscal"),
      action: text(args.action, "ai_note"),
      entity_type: text(args.entity_type) || null,
      entity_id: text(args.entity_id) || null,
      severity: auditSeverity(args.severity),
      title,
      description,
      metadata: { ...asRecord(args.metadata), tool: toolName },
    });

    return {
      ...insight,
      action_result: actionResult(
        "executed",
        toolName,
        "Linha do tempo atualizada",
        "Registro salvo na linha do tempo operacional.",
      ),
      tools_used: [...new Set([...insight.tools_used, toolName])],
    };
  }

  if (toolName === "create_allocation") {
    if (!confirmed) {
      return requireConfirmation(insight, toolName, "Confirme para alocar o colaborador.");
    }

    const colaboradorId = text(args.colaborador_id);
    const caixaId = text(args.caixa_id);
    if (!colaboradorId || !caixaId) {
      return actionFailed(insight, toolName, "Informe colaborador_id e caixa_id.");
    }

    const now = new Date();
    const { error } = await supabase.from("alocacoes").insert({
      fiscal_id: input.fiscal_id ?? null,
      colaborador_id: colaboradorId,
      caixa_id: caixaId,
      turno_escala_id: text(args.turno_escala_id) || null,
      alocado_em: now.toISOString(),
      horario_inicio: now.toISOString(),
      data_alocacao: isoDate(saoPauloDayStartUtc()),
      status: "ativo",
      alocado_por: "ia_fiscal",
      observacoes: text(args.observacoes) || text(args.notes) || "Alocacao sugerida pela IA.",
    });

    if (error) return actionFailed(insight, toolName, error.message);

    await writeAuditLog(supabase, input.fiscal_id, {
      area: "alocacao",
      action: "ai_created",
      entity_type: "alocacao",
      severity: "success",
      title: "Alocacao criada pela IA",
      description: `Colaborador ${colaboradorId} alocado no caixa ${caixaId}.`,
      metadata: { colaborador_id: colaboradorId, caixa_id: caixaId, tool: toolName },
    });

    return {
      ...insight,
      action_result: actionResult("executed", toolName, "Alocacao criada", "Colaborador alocado no caixa."),
      tools_used: [...new Set([...insight.tools_used, toolName])],
    };
  }

  if (toolName === "release_allocation") {
    if (!confirmed) {
      return requireConfirmation(insight, toolName, "Confirme para liberar esta alocacao.");
    }

    let allocationId = text(args.allocation_id) || text(args.alocacao_id);
    const colaboradorId = text(args.colaborador_id);
    if (!allocationId && colaboradorId && input.fiscal_id) {
      const { data } = await supabase
        .from("alocacoes")
        .select("id")
        .eq("fiscal_id", input.fiscal_id)
        .eq("colaborador_id", colaboradorId)
        .eq("status", "ativo")
        .order("horario_inicio", { ascending: false })
        .limit(1)
        .maybeSingle();
      allocationId = text(asRecord(data).id);
    }
    if (!allocationId) {
      return actionFailed(insight, toolName, "Informe allocation_id/alocacao_id ou colaborador_id ativo.");
    }

    const releasedAt = new Date().toISOString();
    const motivo = text(args.motivo, "liberacao_ia");
    const { error } = await supabase
      .from("alocacoes")
      .update({
        liberado_em: releasedAt,
        horario_fim: releasedAt,
        status: "finalizado",
        motivo_liberacao: motivo,
      })
      .eq("id", allocationId)
      .eq("fiscal_id", input.fiscal_id ?? "");

    if (error) return actionFailed(insight, toolName, error.message);

    await writeAuditLog(supabase, input.fiscal_id, {
      area: "alocacao",
      action: "ai_released",
      entity_type: "alocacao",
      entity_id: allocationId,
      severity: "success",
      title: "Alocacao liberada pela IA",
      description: `Motivo: ${motivo}.`,
      metadata: { allocation_id: allocationId, colaborador_id: colaboradorId, tool: toolName },
    });

    return {
      ...insight,
      action_result: actionResult("executed", toolName, "Alocacao liberada", "Alocacao finalizada."),
      tools_used: [...new Set([...insight.tools_used, toolName])],
    };
  }

  if (toolName === "start_cafe_pause") {
    if (!confirmed) {
      return requireConfirmation(insight, toolName, "Confirme para iniciar cafe/intervalo.");
    }

    const colaboradorId = text(args.colaborador_id);
    if (!colaboradorId) return actionFailed(insight, toolName, "Informe colaborador_id.");

    let colaboradorNome = text(args.colaborador_nome);
    if (!colaboradorNome && input.fiscal_id) {
      const { data } = await supabase
        .from("colaboradores")
        .select("nome")
        .eq("fiscal_id", input.fiscal_id)
        .eq("id", colaboradorId)
        .maybeSingle();
      colaboradorNome = text(asRecord(data).nome);
    }

    const duration = intValue(args.duracao_minutos, intValue(args.duration_minutes, 10));
    const { error } = await supabase.from("pausas_cafe").insert({
      fiscal_id: input.fiscal_id ?? null,
      colaborador_id: colaboradorId,
      colaborador_nome: colaboradorNome || colaboradorId,
      caixa_id: text(args.caixa_id) || null,
      iniciado_em: new Date().toISOString(),
      duracao_minutos: duration,
    });

    if (error) return actionFailed(insight, toolName, error.message);

    await writeAuditLog(supabase, input.fiscal_id, {
      area: "cafe_intervalo",
      action: "ai_started",
      entity_type: "pausas_cafe",
      severity: "success",
      title: "Cafe/intervalo iniciado pela IA",
      description: `${colaboradorNome || colaboradorId} por ${duration} minuto(s).`,
      metadata: { colaborador_id: colaboradorId, duration, tool: toolName },
    });

    return {
      ...insight,
      action_result: actionResult("executed", toolName, "Pausa iniciada", "Cafe/intervalo registrado."),
      tools_used: [...new Set([...insight.tools_used, toolName])],
    };
  }

  if (toolName === "finish_cafe_pause") {
    if (!confirmed) {
      return requireConfirmation(insight, toolName, "Confirme para finalizar cafe/intervalo.");
    }

    let pausaId = text(args.pausa_id);
    const colaboradorId = text(args.colaborador_id);
    if (!pausaId && colaboradorId && input.fiscal_id) {
      const { data } = await supabase
        .from("pausas_cafe")
        .select("id")
        .eq("fiscal_id", input.fiscal_id)
        .eq("colaborador_id", colaboradorId)
        .is("finalizado_em", null)
        .order("iniciado_em", { ascending: false })
        .limit(1)
        .maybeSingle();
      pausaId = text(asRecord(data).id);
    }
    if (!pausaId) return actionFailed(insight, toolName, "Informe pausa_id ou colaborador_id com pausa ativa.");

    const { error } = await supabase
      .from("pausas_cafe")
      .update({ finalizado_em: new Date().toISOString() })
      .eq("id", pausaId)
      .eq("fiscal_id", input.fiscal_id ?? "");

    if (error) return actionFailed(insight, toolName, error.message);

    await writeAuditLog(supabase, input.fiscal_id, {
      area: "cafe_intervalo",
      action: "ai_finished",
      entity_type: "pausas_cafe",
      entity_id: pausaId,
      severity: "success",
      title: "Cafe/intervalo finalizado pela IA",
      description: colaboradorId ? `Colaborador ${colaboradorId}.` : null,
      metadata: { pausa_id: pausaId, colaborador_id: colaboradorId, tool: toolName },
    });

    return {
      ...insight,
      action_result: actionResult("executed", toolName, "Pausa finalizada", "Cafe/intervalo finalizado."),
      tools_used: [...new Set([...insight.tools_used, toolName])],
    };
  }

  return {
    ...insight,
    action_result: actionResult(
      "blocked",
      toolName,
      "Ferramenta bloqueada",
      "Ferramenta desconhecida ou indisponivel.",
    ),
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
  const openStatuses = ["suggested", "ready", "pending_approval"];
  const payload = {
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
    updated_at: new Date().toISOString(),
  };

  const { data: existing, error: existingError } = await supabase
    .from("fiscal_ai_actions")
    .select("id")
    .eq("fiscal_id", input.fiscal_id)
    .eq("tool_name", toolName)
    .eq("title", title)
    .eq("description", description)
    .in("status", openStatuses)
    .limit(1)
    .maybeSingle();

  if (existingError) {
    console.warn("[fiscal-ai-agent] action dedupe check failed:", existingError.message);
  }

  if (existing?.id) {
    const { error } = await supabase
      .from("fiscal_ai_actions")
      .update(payload)
      .eq("id", existing.id)
      .eq("fiscal_id", input.fiscal_id);

    if (error) {
      console.warn("[fiscal-ai-agent] action not updated:", error.message);
    }
    return;
  }

  const { error } = await supabase.from("fiscal_ai_actions").insert(payload);

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
    const clientContext = asRecord(input.context);
    const isRuntimeTest = clientContext.runtime_test === true;
    const backendContext = isRuntimeTest
      ? {}
      : await fetchOperationalContext(supabase, input.fiscal_id);
    const normalizedInput: FiscalAiInput = {
      ...input,
      intent: input.intent ?? "analyze",
      context: {
        ...clientContext,
        ...backendContext,
        client_context: clientContext,
      },
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

    if (!isRuntimeTest) {
      const snapshotId = await persistSnapshot(supabase, normalizedInput, insight);
      await persistSuggestedAction(supabase, normalizedInput, insight, snapshotId);
    }

    return new Response(JSON.stringify(insight), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("[fiscal-ai-agent]", error);
    const fallback = buildFallbackInsight({ intent: "analyze", context: {} });
    return new Response(
      JSON.stringify({
        ...fallback,
        provider: "local",
        source: "local_offline",
        fonte: "local_offline",
        warning: "A IA encontrou uma falha interna e usou analise local.",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
