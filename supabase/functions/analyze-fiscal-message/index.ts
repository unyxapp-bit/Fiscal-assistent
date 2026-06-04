import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const OPENAI_MODEL =
  Deno.env.get("OPENAI_ANALYSIS_MODEL") ?? Deno.env.get("OPENAI_MODEL") ?? "gpt-5.4-mini";
const OPENAI_TRANSCRIBE_MODEL =
  Deno.env.get("OPENAI_TRANSCRIBE_MODEL") ?? "gpt-4o-transcribe";
const MEDIA_BUCKET = "fiscal-media";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const categories = new Set([
  "caixa",
  "troco",
  "ausencia",
  "atestado",
  "horario_especial",
  "ferias",
  "vale",
  "problema_operacional",
  "escala",
  "cooperativa",
  "aviso_geral",
  "midia_pendente",
  "nao_relevante",
]);

const socialExact = new Set([
  "ok",
  "blz",
  "beleza",
  "obrigada",
  "obrigado",
  "obg",
  "de nada",
  "sim",
  "nao",
  "não",
  "tmj",
  "vlw",
  "valeu",
  "combinado",
  "entendido",
  "perfeito",
  "certo",
  "ta joia",
  "tá joia",
  "tá bom",
  "ta bom",
  "já veio",
  "ja veio",
  "deu certo",
  "deu certinho",
  "ja deu certo",
  "já deu certo",
  "ainda não",
  "ainda nao",
  "não me lembro",
  "nao me lembro",
  "não lembro",
  "nao lembro",
  "bom dia",
  "boa tarde",
  "boa noite",
  "bom dia pessoal",
  "boa tarde pessoal",
  "boa noite pessoal",
]);

interface AnalyzeRequest {
  capture_id?: string | null;
  target_event_id?: number | string | null;
  fiscal_id?: string | null;
  sender?: string | null;
  message?: string | null;
  timestamp?: string | null;
  source?: string | null;
  source_app?: string | null;
  source_title?: string | null;
  raw_title?: string | null;
  raw_content?: string | null;
  media_type?: string | null;
  media_storage_bucket?: string | null;
  media_storage_path?: string | null;
  media_file_name?: string | null;
  media_content_type?: string | null;
}

interface RuleResult {
  category: string;
  description: string;
  employee_name: string | null;
  amount: number | null;
  confidence: number;
  caixa_numero?: number | null;
  scheduled_time?: string | null;
  turno?: string | null;
  priority?: string | null;
  media_summary?: string | null;
  image_text?: string | null;
  needs_review?: boolean | null;
  missing_fields?: string[];
}

interface ColaboradorRow {
  id: string;
  nome: string;
}

function asRecord(value: unknown): Record<string, unknown> {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return {};
}

function text(value: unknown, fallback = "") {
  return typeof value === "string" ? value : fallback;
}

function nullableText(value: unknown): string | null {
  const result = text(value).trim();
  return result.length === 0 ? null : result;
}

function numberValue(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", "."));
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function clampConfidence(value: unknown, fallback = 0.6) {
  const n = numberValue(value);
  if (n === null) return fallback;
  return Math.max(0, Math.min(1, n));
}

function normalizeLower(value: string) {
  return value
    .toLowerCase()
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .trim();
}

function isNaoRelevante(message: string): boolean {
  const t = message.trim();
  if (t.length <= 3) return true;

  const lower = t.toLowerCase();
  const normalized = normalizeLower(t);
  if (socialExact.has(lower) || socialExact.has(normalized)) return true;

  if (t.length <= 30) {
    const hasFiscal =
      /falt|sobr|atestado|ausente|caixa|vale|desconto|pos\b|tef\b|ferias|f[eé]rias|afastamento|atraso|entrar|horario|horário|impressora|cooper/i
        .test(t);
    if (!hasFiscal) {
      if (/^(?:bom\s+dia|boa\s+(?:tarde|noite))\s*[!.,]?\s*(?:pessoal|gente|todos?)?\s*[!.]?\s*$/i.test(lower)) {
        return true;
      }
      if (/^n[aã]o\s+(?:me\s+)?(?:lembro|sei|acho)\s*(?:n[aã]o)?\s*[!.,]?\s*$/i.test(lower)) {
        return true;
      }
      if (/^j[aá]\s+(?:veio|deu\s+certo|entrei|avisei|foi|vou)\s*[!.,]?\s*$/i.test(lower)) {
        return true;
      }
    }
  }

  return false;
}

function extrairCaixaNumero(msg: string): number | null {
  const m = msg.match(/\b(?:caixa|cx)\s*(\d{1,3})\b/i);
  if (!m) return null;
  const n = parseInt(m[1], 10);
  return Number.isFinite(n) ? n : null;
}

function extrairHorario(msg: string): string | null {
  const m = msg.match(/\b(\d{1,2})[h:](\d{2})\b/) ??
    msg.match(/\b(\d{1,2})h\b/i);
  if (!m) return null;
  const h = m[1].padStart(2, "0");
  const min = (m[2] ?? "00").padStart(2, "0");
  if (parseInt(h) > 23 || parseInt(min) > 59) return null;
  return `${h}:${min}`;
}

function inferirTurno(timestamp: string): string {
  const hour = new Date(timestamp).getHours();
  if (hour < 12) return "manha";
  if (hour < 18) return "tarde";
  return "noite";
}

function inferirPrioridade(category: string, amount: number | null): string {
  if (category === "caixa" && amount !== null && Math.abs(amount) >= 100) {
    return "critica";
  }
  if (category === "caixa" && amount !== null && Math.abs(amount) >= 50) {
    return "alta";
  }
  if (category === "problema_operacional") return "alta";
  return "normal";
}

function extrairValor(msg: string): number | null {
  const match = msg.match(/R\$\s*([\d.,]+)/i) ??
    msg.match(/([\d]+[.,][\d]{2})\s*(?:reais?|centavos?)?/i) ??
    msg.match(/(\d+)\s*(?:real|reais)/i);
  if (!match) return null;
  const raw = match[1].replace(".", "").replace(",", ".");
  const val = parseFloat(raw);
  return Number.isFinite(val) ? val : null;
}

function extrairNome(msg: string, sender: string): string | null {
  const name =
    msg.match(/(?:de|da|do)\s+([A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+(?:\s+[A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+)?)/)?.[1] ??
    msg.match(/^([A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+)\s+(?:faltou|n[aã]o\s+veio|ausente|atestado|f[eé]rias|saiu|chegou|vai\s+entrar|vai\s+sair)/)?.[1] ??
    msg.match(/funcion[aá]rio[:\s]+([A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+)/i)?.[1] ??
    msg.match(/op(?:erador)?\s+([A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+)/i)?.[1] ??
    msg.match(/caixa\s+(?:da?o?\s+)?([A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+)/i)?.[1];
  if (name) return name;
  if (sender && !/^\d/.test(sender) && sender.length > 3) return sender;
  return null;
}

function categorizarPorRegra(
  msg: string,
  sender: string,
  timestamp: string,
): RuleResult | null {
  const turno = inferirTurno(timestamp);

  if (
    /falt(?:ou|a|ando)\s*r\$|sobr(?:ou|a)\s*r\$|diferen.a\s*(?:no\s*)?caixa|falta\s*(?:de\s*)?dinheiro/i
      .test(msg) ||
    /(?:caixa|cx)\b.{0,60}\b(?:falt|sobr)/i.test(msg) ||
    /(?:falt|sobr)(?:ou|a)\b.{0,60}\b(?:caixa|cx)\b/i.test(msg) ||
    /(?:falt|sobr)(?:ou|a|ando)\s+\d+[.,]\d{2}/i.test(msg) ||
    /(?:falt|sobr)(?:ou|a|ando)\s+\d+\s*(?:real|reais)/i.test(msg)
  ) {
    const amount = extrairValor(msg);
    return {
      category: "caixa",
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount,
      caixa_numero: extrairCaixaNumero(msg),
      turno,
      priority: inferirPrioridade("caixa", amount),
      confidence: 0.92,
    };
  }

  if (/sem\s+troco|falt[ao]?\s+troco|troco\s+(?:insuficiente|acabou|esgotado)|n[aã]o\s+tem\s+troco|precisa\s+de\s+troco/i.test(msg)) {
    return {
      category: "troco",
      description: msg.trim(),
      employee_name: null,
      amount: null,
      caixa_numero: extrairCaixaNumero(msg),
      turno,
      priority: "alta",
      confidence: 0.9,
    };
  }

  if (/atestado|afastamento|afastad[oa]|licen.a\s*m.dica|postinho|conjuntivite|m[eé]dico\s+receitou/i.test(msg)) {
    return {
      category: "atestado",
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount: null,
      confidence: 0.93,
    };
  }

  if (/\bn[aã]o\s+veio\b|ausente|n[aã]o\s+apareceu|faltando\s+hoje|\bfaltou\b(?!.{0,30}r\$)(?!.{0,30}\d+[,.])/i.test(msg)) {
    return {
      category: "ausencia",
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount: null,
      confidence: 0.88,
    };
  }

  if (/f[eé]rias|inicio\s*de\s*f[eé]rias|volta\s*de\s*f[eé]rias|entrou\s*de\s*f[eé]rias|saiu\s*de\s*f[eé]rias|sobre\s+as\s+f[eé]rias/i.test(msg)) {
    return {
      category: "ferias",
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount: null,
      confidence: 0.92,
    };
  }

  if (/vale\s*troca|vale\s*desconto|desconto\s*para\s*cliente|cupom\s*de\s*desconto/i.test(msg)) {
    return {
      category: "vale",
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount: extrairValor(msg),
      confidence: 0.9,
    };
  }

  if (/vai\s*(?:chegar|entrar|sair)|vou\s*(?:entrar|sair|chegar)|chegando\s*(?:mais\s*)?tarde|vai\s*sair\s*(?:mais\s*)?cedo|saindo\s*antes|atraso(?:ada)?|atrasar|hora\s*extra|\d{1,2}[h:]\d{2}\s*(?:segunda|ter.a|quarta|quinta|sexta|s.bado|domingo|amanh.|hoje)/i.test(msg)) {
    return {
      category: "horario_especial",
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount: null,
      scheduled_time: extrairHorario(msg),
      turno,
      priority: "normal",
      confidence: 0.85,
    };
  }

  if (/pos\s*duplicad|c[oó]digo\s+n[aã]o\s*encontrad|sistema\s*(?:fora|caiu|erro)|erro\s*no\s*(?:sistema|terminal|pos|caixa)|n[aã]o\s*est[aá]\s*funcionando|terminal\s*travad|impressora.*problem|problem.*impressora|tef.*cart[aã]o|cart[aã]o.*tef|pos\s*errado|fechando.*pos.*errado/i.test(msg)) {
    return {
      category: "problema_operacional",
      description: msg.trim(),
      employee_name: null,
      amount: null,
      caixa_numero: extrairCaixaNumero(msg),
      turno,
      priority: "alta",
      confidence: 0.87,
    };
  }

  if (/trocar?\s+(?:turno|dia|folga|s.bado|domingo|plant.o)|preciso\s+(?:de\s+)?folga|posso\s+(?:trocar|mudar)|muda[rn]\s+(?:meu\s+)?(?:dia|turno|escala)|algu[eé][mn]\s+(?:pode|quer)\s+trocar/i.test(msg)) {
    return {
      category: "escala",
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount: null,
      turno,
      priority: "normal",
      confidence: 0.85,
    };
  }

  if (/cooper(?:ativa)?|desconto\s+coop|coop\s+desconto/i.test(msg)) {
    return {
      category: "cooperativa",
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount: extrairValor(msg),
      turno,
      priority: "normal",
      confidence: 0.88,
    };
  }

  return null;
}

function openAiResponseText(data: Record<string, unknown>) {
  const directText = text(data.output_text);
  if (directText) return directText;

  const output = Array.isArray(data.output) ? data.output : [];
  const chunks: string[] = [];
  for (const item of output) {
    const content = asRecord(item).content;
    if (!Array.isArray(content)) continue;
    for (const part of content) {
      const partRecord = asRecord(part);
      const value = text(partRecord.text);
      if (value) chunks.push(value);
    }
  }
  return chunks.join("");
}

function parseJsonObject(raw: string): Record<string, unknown> {
  try {
    return asRecord(JSON.parse(raw.replace(/```json|```/g, "").trim()));
  } catch {
    return {};
  }
}

const analysisPrompt = `Voce analisa conteudo do grupo "Balcao Fiscal" de um supermercado.

Entrada possivel: texto, transcricao de audio ou foto/documento do WhatsApp.
Extraia somente informacoes operacionais/fiscais relevantes. Mensagens sociais devem virar nao_relevante.

Categorias permitidas:
- caixa: falta/sobra/diferenca de dinheiro no caixa
- troco: falta de troco
- ausencia: colaborador nao veio sem atestado
- atestado: afastamento medico/atestado
- horario_especial: entrada, saida, atraso ou hora extra
- ferias: ferias ou retorno de ferias
- vale: vale troca/desconto/cupom para cliente
- problema_operacional: POS, TEF, impressora, sistema, terminal, codigo ou processo com erro
- escala: troca de turno, folga, plantao ou escala
- cooperativa: desconto/cooperativa
- aviso_geral: informacao operacional relevante
- nao_relevante: social, figurinha, confirmacao simples, agradecimento, conversa sem acao

Retorne apenas JSON valido:
{
  "category": "uma categoria permitida",
  "description": "resumo curto em portugues",
  "employee_name": "nome do colaborador ou null",
  "amount": numero ou null,
  "caixa_numero": numero ou null,
  "scheduled_time": "HH:MM ou null",
  "turno": "manha|tarde|noite|null",
  "priority": "baixa|normal|alta|critica",
  "confidence": numero entre 0 e 1,
  "media_summary": "o que a foto/audio mostra, ou null",
  "image_text": "texto lido na imagem, ou null",
  "needs_review": boolean,
  "missing_fields": []
}`;

async function categorizarComOpenAI(params: {
  message: string;
  sender: string;
  timestamp: string;
  contentType: string;
  transcript?: string | null;
  imageDataUrl?: string | null;
}) {
  if (!OPENAI_API_KEY) {
    return {
      category: "aviso_geral",
      description: params.message,
      employee_name: extrairNome(params.message, params.sender),
      amount: extrairValor(params.message),
      confidence: 0.45,
      priority: "normal",
      needs_review: true,
      missing_fields: ["openai_api_key"],
    } as RuleResult;
  }

  const inputText = [
    `Remetente: ${params.sender || "desconhecido"}`,
    `Horario: ${params.timestamp}`,
    `Tipo: ${params.contentType}`,
    params.transcript ? `Transcricao: ${params.transcript}` : null,
    params.message ? `Texto/contexto: ${params.message}` : null,
    "Classifique e extraia os campos fiscais.",
  ].filter(Boolean).join("\n");

  const content: Record<string, unknown>[] = [
    { type: "input_text", text: inputText },
  ];
  if (params.imageDataUrl) {
    content.push({ type: "input_image", image_url: params.imageDataUrl });
  }

  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      max_output_tokens: 900,
      truncation: "auto",
      reasoning: { effort: "low" },
      input: [
        { role: "system", content: analysisPrompt },
        { role: "user", content },
      ],
      text: {
        verbosity: "low",
        format: { type: "json_object" },
      },
    }),
  });

  if (!response.ok) throw new Error(await response.text());
  const data = await response.json();
  const raw = openAiResponseText(asRecord(data));
  const parsed = parseJsonObject(raw);

  return normalizeRuleResult(parsed, params.message, params.sender);
}

function normalizeRuleResult(
  input: Record<string, unknown>,
  fallbackText: string,
  sender: string,
): RuleResult {
  let category = text(input.category, "aviso_geral");
  if (!categories.has(category)) category = "aviso_geral";

  const amount = numberValue(input.amount);
  const priority = text(input.priority) ||
    inferirPrioridade(category, amount);
  const description = text(input.description).trim() ||
    text(input.media_summary).trim() ||
    fallbackText.trim() ||
    "Conteudo recebido para analise fiscal";

  return {
    category,
    description,
    employee_name: nullableText(input.employee_name) ??
      extrairNome(fallbackText, sender),
    amount,
    caixa_numero: numberValue(input.caixa_numero),
    scheduled_time: nullableText(input.scheduled_time),
    turno: nullableText(input.turno),
    priority,
    confidence: clampConfidence(input.confidence, 0.6),
    media_summary: nullableText(input.media_summary),
    image_text: nullableText(input.image_text),
    needs_review: typeof input.needs_review === "boolean"
      ? input.needs_review
      : undefined,
    missing_fields: Array.isArray(input.missing_fields)
      ? input.missing_fields.map((item) => String(item))
      : [],
  };
}

function matchColaborador(
  employeeName: string,
  colaboradores: ColaboradorRow[],
): string | null {
  const target = normalizeLower(employeeName);
  if (target.length < 2) return null;

  for (const c of colaboradores) {
    const nome = normalizeLower(c.nome);
    const firstName = nome.split(/\s+/)[0] ?? "";
    if (nome === target) return c.id;
    if (firstName.startsWith(target) && target.length >= 3) return c.id;
    if (target.startsWith(firstName) && firstName.length >= 3) return c.id;
    if (nome.includes(target) && target.length >= 4) return c.id;
  }

  return null;
}

function safeFileName(fileName: string, contentType: string) {
  const clean = fileName.replace(/[^\w.\-]+/g, "_");
  if (clean.toLowerCase().endsWith(".opus")) {
    return clean.replace(/\.opus$/i, ".ogg");
  }
  if (clean.includes(".")) return clean;
  if (contentType.includes("jpeg")) return `${clean}.jpg`;
  if (contentType.includes("png")) return `${clean}.png`;
  if (contentType.includes("webp")) return `${clean}.webp`;
  if (contentType.includes("ogg") || contentType.includes("opus")) {
    return `${clean}.ogg`;
  }
  if (contentType.includes("wav")) return `${clean}.wav`;
  if (contentType.includes("mp4")) return `${clean}.mp4`;
  if (contentType.includes("mpeg") || contentType.includes("mp3")) {
    return `${clean}.mp3`;
  }
  return clean || "arquivo";
}

function normalizeAudioMime(mimeType: string, fileName: string) {
  const lower = `${mimeType} ${fileName}`.toLowerCase();
  if (lower.includes("opus") || lower.endsWith(".opus")) return "audio/ogg";
  if (lower.includes("ogg")) return "audio/ogg";
  if (lower.includes("webm")) return "audio/webm";
  if (lower.includes("wav")) return "audio/wav";
  if (lower.includes("m4a")) return "audio/m4a";
  if (lower.includes("mp4")) return "audio/mp4";
  return mimeType || "audio/mpeg";
}

async function transcribeAudio(bytes: Uint8Array, fileName: string, mimeType: string) {
  if (!OPENAI_API_KEY) throw new Error("OPENAI_API_KEY nao configurada");

  const type = normalizeAudioMime(mimeType, fileName);
  const form = new FormData();
  const blob = new Blob([bytes], { type });
  const file = new File([blob], safeFileName(fileName || "audio", type), {
    type,
  });
  form.append("file", file);
  form.append("model", OPENAI_TRANSCRIBE_MODEL);
  form.append("response_format", "json");

  const response = await fetch("https://api.openai.com/v1/audio/transcriptions", {
    method: "POST",
    headers: { Authorization: `Bearer ${OPENAI_API_KEY}` },
    body: form,
  });

  if (!response.ok) throw new Error(await response.text());
  const data = await response.json();
  return text(asRecord(data).text).trim();
}

function bytesToBase64(bytes: Uint8Array) {
  let binary = "";
  const chunkSize = 0x8000;
  for (let i = 0; i < bytes.length; i += chunkSize) {
    const chunk = bytes.subarray(i, i + chunkSize);
    binary += String.fromCharCode(...chunk);
  }
  return btoa(binary);
}

async function sha256(value: string) {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function minuteBucket(timestamp: string) {
  const date = new Date(timestamp);
  if (Number.isNaN(date.getTime())) return new Date().toISOString().slice(0, 16);
  date.setSeconds(0, 0);
  return date.toISOString();
}

function inferContentType(req: AnalyzeRequest, capture: Record<string, unknown>) {
  const explicit = text(req.media_type) ||
    text(capture.media_type) ||
    text(capture.content_type);
  const mime = `${text(req.media_content_type)} ${text(capture.mime_type)}`;
  const path = `${text(req.media_storage_path)} ${text(capture.storage_path)}`.toLowerCase();
  const probe = `${explicit} ${mime} ${path}`.toLowerCase();

  if (/audio|opus|ptt-|aud-|\.(mp3|m4a|wav|webm|ogg|opus)\b/.test(probe)) {
    return "audio";
  }
  if (/foto|image|imagem|\.(jpg|jpeg|png|webp)\b/.test(probe)) {
    return "image";
  }
  if (/pdf|document|application\/pdf/.test(probe)) return "document";
  return "text";
}

async function downloadStorageFile(
  supabase: ReturnType<typeof createClient>,
  bucket: string,
  path: string,
) {
  const { data, error } = await supabase.storage.from(bucket).download(path);
  if (error || !data) throw new Error(error?.message ?? "Arquivo nao encontrado");
  return new Uint8Array(await data.arrayBuffer());
}

async function loadOrCreateCapture(
  supabase: ReturnType<typeof createClient>,
  req: AnalyzeRequest,
) {
  if (req.capture_id) {
    const { data, error } = await supabase
      .from("ai_inbox_items")
      .select("*")
      .eq("id", req.capture_id)
      .single();
    if (error || !data) throw new Error(error?.message ?? "Captura nao encontrada");
    await supabase
      .from("ai_inbox_items")
      .update({ analysis_status: "processing", error_message: null })
      .eq("id", req.capture_id);
    return asRecord(data);
  }

  const ts = req.timestamp ?? new Date().toISOString();
  const hash = await sha256([
    req.fiscal_id ?? "anon",
    req.source ?? "whatsapp_notification",
    req.source_title ?? req.raw_title ?? "",
    req.sender ?? "",
    req.message ?? req.raw_content ?? "",
    req.media_type ?? "text",
    req.media_storage_path ?? "",
    minuteBucket(ts),
  ].join("|"));

  const source = req.source ?? "whatsapp_notification";
  const contentType = inferContentType(req, {});
  const insertPayload = {
    fiscal_id: req.fiscal_id ?? null,
    source,
    source_app: req.source_app ?? "whatsapp",
    source_title: req.source_title ?? req.raw_title ?? null,
    sender: req.sender ?? null,
    raw_text: req.message ?? null,
    raw_title: req.raw_title ?? req.source_title ?? null,
    raw_content: req.raw_content ?? req.message ?? null,
    content_type: contentType,
    media_type: contentType === "image" ? "foto" : contentType,
    storage_bucket: req.media_storage_bucket ?? MEDIA_BUCKET,
    storage_path: req.media_storage_path ?? null,
    file_name: req.media_file_name ?? null,
    mime_type: req.media_content_type ?? null,
    content_hash: hash,
    event_date: ts,
    analysis_status: "processing",
  };

  const { data, error } = await supabase
    .from("ai_inbox_items")
    .insert(insertPayload)
    .select()
    .single();

  if (!error && data) return asRecord(data);
  if (error?.code !== "23505") throw error;

  const { data: existing } = await supabase
    .from("ai_inbox_items")
    .select("*")
    .eq("fiscal_id", req.fiscal_id)
    .eq("content_hash", hash)
    .limit(1)
    .maybeSingle();

  if (existing) return asRecord(existing);
  throw error;
}

async function updateCapture(
  supabase: ReturnType<typeof createClient>,
  captureId: string,
  payload: Record<string, unknown>,
) {
  await supabase.from("ai_inbox_items").update(payload).eq("id", captureId);
}

function dbSource(source: string) {
  return source.includes("whatsapp") ? "whatsapp" : "manual";
}

async function findColaboradorId(
  supabase: ReturnType<typeof createClient>,
  employeeName: string | null,
) {
  if (!employeeName) return null;
  const { data: colaboradores } = await supabase
    .from("colaboradores")
    .select("id, nome")
    .eq("ativo", true);

  if (!Array.isArray(colaboradores) || colaboradores.length === 0) return null;
  return matchColaborador(employeeName, colaboradores as ColaboradorRow[]);
}

interface FiscalEventPersistParams {
  fiscalId: string | null;
  capture: Record<string, unknown>;
  source: string;
  sender: string;
  rawMessage: string;
  timestamp: string;
  contentType: string;
  storageBucket: string | null;
  storagePath: string | null;
  fileName: string | null;
  mimeType: string | null;
  transcript: string | null;
  imageText: string | null;
  mediaSummary: string | null;
  contentHash: string | null;
  analysisStatus: string;
  analysisError?: string | null;
}

async function buildFiscalEventPayload(
  supabase: ReturnType<typeof createClient>,
  parsed: RuleResult,
  params: FiscalEventPersistParams,
) {
  const colaboradorId = await findColaboradorId(supabase, parsed.employee_name);
  const confidence = clampConfidence(parsed.confidence);
  const inferredNeedsReview =
    confidence < 0.65 ||
    params.analysisStatus !== "analyzed" ||
    (params.contentType !== "text" && (parsed.missing_fields?.length ?? 0) > 0);
  const needsReview = parsed.needs_review ?? inferredNeedsReview;

  return {
    fiscal_id: params.fiscalId,
    ai_inbox_item_id: text(params.capture.id) || null,
    content_hash: params.contentHash,
    category: parsed.category,
    description: parsed.description,
    employee_name: parsed.employee_name,
    colaborador_id: colaboradorId,
    amount: parsed.amount ?? null,
    caixa_numero: parsed.caixa_numero ?? null,
    scheduled_time: parsed.scheduled_time ?? null,
    turno: parsed.turno ?? inferirTurno(params.timestamp),
    priority: parsed.priority ?? inferirPrioridade(parsed.category, parsed.amount),
    source: dbSource(params.source),
    source_title: text(params.capture.source_title) || null,
    sender: params.sender || null,
    raw_message: params.rawMessage,
    raw_title: text(params.capture.raw_title) || null,
    raw_content: text(params.capture.raw_content) || params.rawMessage,
    event_date: params.timestamp,
    status: "pending",
    confidence,
    media_type: params.contentType === "image"
      ? "foto"
      : params.contentType === "audio"
      ? "audio"
      : null,
    needs_review: needsReview,
    media_storage_bucket: params.storageBucket,
    media_storage_path: params.storagePath,
    media_file_name: params.fileName,
    media_content_type: params.mimeType,
    media_transcript: params.transcript,
    media_summary: params.mediaSummary,
    media_analysis: {
      image_text: params.imageText,
      missing_fields: parsed.missing_fields ?? [],
    },
    analysis_provider: OPENAI_API_KEY ? "openai" : "local",
    analysis_model: OPENAI_API_KEY ? OPENAI_MODEL : null,
    analysis_status: params.analysisStatus,
    analysis_error: params.analysisError ?? null,
    analyzed_at: new Date().toISOString(),
  };
}

async function insertFiscalEvent(
  supabase: ReturnType<typeof createClient>,
  parsed: RuleResult,
  params: FiscalEventPersistParams,
) {
  const payload = await buildFiscalEventPayload(supabase, parsed, params);

  const { data, error } = await supabase
    .from("fiscal_events")
    .insert(payload)
    .select()
    .single();

  if (!error) return asRecord(data);
  if (error.code !== "23505" || !params.contentHash || !params.fiscalId) {
    throw error;
  }

  const { data: existing, error: selectError } = await supabase
    .from("fiscal_events")
    .select("*")
    .eq("fiscal_id", params.fiscalId)
    .eq("content_hash", params.contentHash)
    .limit(1)
    .maybeSingle();
  if (selectError) throw selectError;
  return asRecord(existing);
}

async function updateFiscalEvent(
  supabase: ReturnType<typeof createClient>,
  eventId: number,
  parsed: RuleResult,
  params: FiscalEventPersistParams,
) {
  const payload = await buildFiscalEventPayload(supabase, parsed, params);
  const { data, error } = await supabase
    .from("fiscal_events")
    .update(payload)
    .eq("id", eventId)
    .select()
    .single();

  if (error) throw error;
  return asRecord(data);
}

async function createAiAction(
  supabase: ReturnType<typeof createClient>,
  event: Record<string, unknown>,
  capture: Record<string, unknown>,
) {
  const fiscalId = text(event.fiscal_id);
  if (!fiscalId) return;

  const category = text(event.category);
  const priority = text(event.priority, "normal");
  const needsReview = event.needs_review === true;
  const confidence = clampConfidence(event.confidence, 0.7);
  const mediaType = text(event.media_type);
  const amount = numberValue(event.amount);

  const shouldSuggest =
    priority === "alta" ||
    priority === "critica" ||
    needsReview ||
    confidence < 0.7 ||
    (category === "caixa" && amount !== null && Math.abs(amount) >= 50);

  if (!shouldSuggest) return;

  const title = needsReview
    ? "Revisar captura multimodal"
    : priority === "critica"
    ? "Acao critica no Balcao"
    : "Prioridade detectada no Balcao";

  await supabase.from("fiscal_ai_actions").insert({
    fiscal_id: fiscalId,
    intent: "analyze",
    source: "multimodal_inbox",
    status: "suggested",
    mode: "suggest",
    tool_name: "create_followup_event",
    title,
    description: text(event.description),
    reason: mediaType
      ? `Evento gerado a partir de ${mediaType} com confianca ${confidence.toFixed(2)}.`
      : `Evento ${category} com prioridade ${priority}.`,
    confidence,
    confirmation_required: true,
    arguments: {
      category,
      description: text(event.description),
      employee_name: nullableText(event.employee_name),
      amount,
      source_event_id: event.id,
    },
    target: {
      event_id: event.id,
      capture_id: capture.id,
      category,
      priority,
      media_type: mediaType || null,
    },
    context_snapshot: {
      capture,
      event,
    },
  });
}

async function processNeedsFile(
  supabase: ReturnType<typeof createClient>,
  params: {
    capture: Record<string, unknown>;
    req: AnalyzeRequest;
    contentType: string;
    timestamp: string;
    fiscalId: string | null;
    sender: string;
    source: string;
    rawMessage: string;
    contentHash: string | null;
  },
) {
  const label = params.contentType === "audio" ? "audio" : "foto";
  const description =
    `${label} recebido de ${params.sender || "alguem"} - arquivo ainda nao anexado para a IA analisar`;
  const parsed: RuleResult = {
    category: "midia_pendente",
    description,
    employee_name: params.sender || null,
    amount: null,
    confidence: 0.2,
    priority: "normal",
    needs_review: true,
    missing_fields: ["arquivo_original"],
  };
  const event = await insertFiscalEvent(supabase, parsed, {
    fiscalId: params.fiscalId,
    capture: params.capture,
    source: params.source,
    sender: params.sender,
    rawMessage: params.rawMessage || label,
    timestamp: params.timestamp,
    contentType: params.contentType,
    storageBucket: text(params.capture.storage_bucket, MEDIA_BUCKET),
    storagePath: null,
    fileName: null,
    mimeType: null,
    transcript: null,
    imageText: null,
    mediaSummary: null,
    contentHash: params.contentHash,
    analysisStatus: "needs_file",
  });

  await updateCapture(supabase, text(params.capture.id), {
    analysis_status: "needs_file",
    skipped_reason: "arquivo_original_ausente",
    fiscal_event_id: event.id,
    structured_result: parsed,
  });
  await createAiAction(supabase, event, params.capture);
  return event;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  try {
    const body = await req.json() as AnalyzeRequest;
    const capture = await loadOrCreateCapture(supabase, body);
    const captureId = text(capture.id);
    const timestamp = body.timestamp ??
      text(capture.event_date) ??
      new Date().toISOString();
    const source = body.source ?? text(capture.source, "whatsapp_notification");
    const sender = body.sender ?? text(capture.sender);
    const fiscalId = body.fiscal_id ?? nullableText(capture.fiscal_id);
    const contentType = inferContentType(body, capture);
    const storageBucket = body.media_storage_bucket ??
      text(capture.storage_bucket, MEDIA_BUCKET);
    const storagePath = body.media_storage_path ?? nullableText(capture.storage_path);
    const fileName = body.media_file_name ?? nullableText(capture.file_name);
    const mimeType = body.media_content_type ?? nullableText(capture.mime_type);
    const rawMessage = body.message ??
      text(capture.raw_text) ??
      text(capture.raw_content);
    const targetEventId = numberValue(body.target_event_id) ??
      numberValue(capture.fiscal_event_id);
    const contentHash = nullableText(capture.content_hash) ??
      await sha256([
        fiscalId ?? "anon",
        source,
        text(capture.source_title),
        sender,
        rawMessage,
        storagePath ?? "",
        minuteBucket(timestamp),
      ].join("|"));

    if (captureId) {
      await updateCapture(supabase, captureId, {
        fiscal_id: fiscalId,
        content_hash: contentHash,
        content_type: contentType,
        media_type: contentType === "image" ? "foto" : contentType,
        analysis_status: "processing",
      });
    }

    if ((contentType === "audio" || contentType === "image") && !storagePath) {
      const event = await processNeedsFile(supabase, {
        capture,
        req: body,
        contentType,
        timestamp,
        fiscalId,
        sender,
        source,
        rawMessage,
        contentHash,
      });
      return new Response(
        JSON.stringify({ success: true, event, capture_id: captureId, needs_file: true }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    let analysisText = rawMessage;
    let transcript: string | null = nullableText(capture.transcript);
    let imageText: string | null = nullableText(capture.image_text);
    let mediaSummary: string | null = nullableText(capture.summary);
    let parsed: RuleResult | null = null;
    let imageDataUrl: string | null = null;
    let analysisStatus = "analyzed";
    let analysisError: string | null = null;

    if (contentType === "audio" && storagePath) {
      const bytes = await downloadStorageFile(supabase, storageBucket, storagePath);
      transcript = await transcribeAudio(bytes, fileName ?? "audio", mimeType ?? "");
      analysisText = transcript || rawMessage;
    }

    if (contentType === "image" && storagePath) {
      const bytes = await downloadStorageFile(supabase, storageBucket, storagePath);
      const type = mimeType || "image/jpeg";
      imageDataUrl = `data:${type};base64,${bytesToBase64(bytes)}`;
      analysisText = rawMessage || "Foto recebida do WhatsApp/Balcao Fiscal";
    }

    if (contentType === "document" || contentType === "video") {
      analysisStatus = "needs_review";
      analysisError = "tipo_de_arquivo_sem_analise_automatica";
      parsed = {
        category: "midia_pendente",
        description: `${contentType} recebido para revisao manual`,
        employee_name: sender || null,
        amount: null,
        confidence: 0.2,
        priority: "normal",
        needs_review: true,
      };
    }

    if (!analysisText.trim() && !imageDataUrl && !parsed) {
      await updateCapture(supabase, captureId, {
        analysis_status: "skipped",
        skipped_reason: "conteudo_vazio",
      });
      return new Response(
        JSON.stringify({ success: true, skipped: true, reason: "conteudo_vazio" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (!parsed && !imageDataUrl && isNaoRelevante(analysisText)) {
      await updateCapture(supabase, captureId, {
        analysis_status: "skipped",
        skipped_reason: "nao_relevante",
        transcript,
      });
      return new Response(
        JSON.stringify({ success: true, skipped: true, reason: "nao_relevante" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (!parsed && contentType !== "image") {
      parsed = categorizarPorRegra(analysisText, sender, timestamp);
    }

    if (!parsed) {
      parsed = await categorizarComOpenAI({
        message: analysisText,
        sender,
        timestamp,
        contentType,
        transcript,
        imageDataUrl,
      });
      imageText = parsed.image_text ?? imageText;
      mediaSummary = parsed.media_summary ?? mediaSummary;
    }

    if (parsed.category === "nao_relevante") {
      await updateCapture(supabase, captureId, {
        analysis_status: "skipped",
        analysis_provider: OPENAI_API_KEY ? "openai" : "local",
        analysis_model: OPENAI_API_KEY ? OPENAI_MODEL : null,
        skipped_reason: "nao_relevante_ia",
        transcript,
        image_text: imageText,
        summary: mediaSummary,
        structured_result: parsed,
      });
      return new Response(
        JSON.stringify({ success: true, skipped: true, reason: "nao_relevante_ia" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const persistParams = {
      fiscalId,
      capture,
      source,
      sender,
      rawMessage: analysisText || rawMessage,
      timestamp,
      contentType,
      storageBucket,
      storagePath,
      fileName,
      mimeType,
      transcript,
      imageText,
      mediaSummary,
      contentHash,
      analysisStatus,
      analysisError,
    };
    const event = targetEventId
      ? await updateFiscalEvent(supabase, targetEventId, parsed, persistParams)
      : await insertFiscalEvent(supabase, parsed, persistParams);

    await updateCapture(supabase, captureId, {
      analysis_status: analysisStatus,
      analysis_provider: OPENAI_API_KEY ? "openai" : "local",
      analysis_model: OPENAI_API_KEY ? OPENAI_MODEL : null,
      transcript,
      image_text: imageText,
      summary: mediaSummary,
      structured_result: parsed,
      fiscal_event_id: event.id,
      error_message: analysisError,
    });

    await createAiAction(supabase, event, capture);

    return new Response(
      JSON.stringify({
        success: true,
        event,
        capture_id: captureId,
        provider: OPENAI_API_KEY ? "openai" : "local",
        model: OPENAI_API_KEY ? OPENAI_MODEL : null,
        transcription_model: contentType === "audio" ? OPENAI_TRANSCRIBE_MODEL : null,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("Erro na Edge Function:", err);
    return new Response(
      JSON.stringify({ success: false, error: String(err) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
