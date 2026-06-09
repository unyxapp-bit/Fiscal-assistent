import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const OPENAI_MODEL =
  Deno.env.get("OPENAI_VISION_MODEL") ?? Deno.env.get("OPENAI_MODEL") ?? "gpt-5-mini";
const OPENAI_MINI_MODEL =
  Deno.env.get("OPENAI_MINI_MODEL") ?? "gpt-5-nano";
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const GEMINI_MODEL =
  Deno.env.get("GEMINI_VISION_MODEL") ?? Deno.env.get("GEMINI_MODEL") ?? "gemini-2.0-flash";
const GEMINI_LITE_MODEL =
  Deno.env.get("GEMINI_LITE_MODEL") ?? "gemini-2.0-flash-lite";
const PROMPT_CACHE_KEY = "extract-delivery-coupon-v2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface ExtractDeliveryCouponRequest {
  fiscal_id?: string | null;
  file_name?: string | null;
  mime_type?: string | null;
  image_base64?: string | null;
}

interface DeliveryCouponDraft {
  numero_nota: string;
  cliente_nome: string;
  telefone: string;
  endereco: string;
  bairro: string;
  cidade: string;
  horario_marcado: string | null;
  observacoes: string;
  confidence: number;
  missing_fields: string[];
  raw_text: string;
  provider?: string;
  model?: string | null;
  source?: string;
  fonte?: string;
  warning?: string | null;
}

type ImageDetail = "auto" | "low";

function asRecord(value: unknown): Record<string, unknown> {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return {};
}

function text(value: unknown, fallback = "") {
  return typeof value === "string" ? value.trim() : fallback;
}

function nullableText(value: unknown): string | null {
  const result = text(value);
  return result ? result : null;
}

function numberValue(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", "."));
    if (Number.isFinite(parsed)) return parsed;
  }
  return null;
}

function confidence(value: unknown) {
  const parsed = numberValue(value);
  if (parsed === null) return 0.65;
  return Math.max(0, Math.min(1, parsed));
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

function openAiResponseText(data: Record<string, unknown>) {
  const directText = text(data.output_text);
  if (directText) return directText;

  const output = Array.isArray(data.output) ? data.output : [];
  const chunks: string[] = [];
  for (const item of output) {
    const content = asRecord(item).content;
    if (!Array.isArray(content)) continue;
    for (const part of content) {
      const value = text(asRecord(part).text);
      if (value) chunks.push(value);
    }
  }
  return chunks.join("");
}

function parseJsonObject(raw: string): Record<string, unknown> {
  const clean = raw.replace(/```json|```/g, "").trim();
  const first = clean.indexOf("{");
  const last = clean.lastIndexOf("}");
  if (first >= 0 && last > first) {
    return asRecord(JSON.parse(clean.slice(first, last + 1)));
  }
  return asRecord(JSON.parse(clean));
}

function normalizeCidade(value: string) {
  const normalized = value
    .toLowerCase()
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .trim();
  if (normalized === "baependi") return "Baependi";
  if (normalized === "caxambu") return "Caxambu";
  if (normalized === "cruzilia") return "Cruzilia";
  return value.trim();
}

function normalizePhone(value: string) {
  return value.replace(/\s+/g, " ").trim();
}

function normalizeNota(value: string) {
  const match = value.match(/\d{2,}/);
  return match ? match[0] : value.trim();
}

function normalizeHorario(value: unknown) {
  const raw = nullableText(value);
  if (!raw) return null;
  const match = raw.match(/^(\d{1,2})[:h](\d{2})$/);
  if (!match) return null;
  const hour = Number(match[1]);
  const minute = Number(match[2]);
  if (hour > 23 || minute > 59) return null;
  return `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
}

function normalizeDraft(
  raw: Record<string, unknown>,
  meta: Partial<Pick<DeliveryCouponDraft, "provider" | "model" | "source" | "fonte" | "warning">> = {},
): DeliveryCouponDraft {
  const numeroNota = normalizeNota(
    text(raw.numero_nota) || text(raw.numeroNota) || text(raw.nota) ||
      text(raw.nf),
  );
  const clienteNome = text(raw.cliente_nome) || text(raw.clienteNome) ||
    text(raw.cliente) || text(raw.nome_cliente);
  const endereco = text(raw.endereco) || text(raw.address);
  const bairro = text(raw.bairro) || text(raw.district);
  const cidade = normalizeCidade(text(raw.cidade) || text(raw.city));
  const telefone = normalizePhone(text(raw.telefone) || text(raw.phone));
  const rawText = text(raw.raw_text) || text(raw.image_text) ||
    text(raw.texto_lido);
  const handwritten = text(raw.handwritten_notes) ||
    text(raw.manuscrito) ||
    text(raw.anotacao_manuscrita);
  const observacoesParts = [
    text(raw.observacoes) || text(raw.notes),
    handwritten ? `Manuscrito: ${handwritten}` : "",
  ].filter((item) => item.trim().length > 0);

  const missing = new Set<string>();
  if (!numeroNota) missing.add("numero_nota");
  if (!clienteNome) missing.add("cliente_nome");
  if (!endereco) missing.add("endereco");
  if (!bairro) missing.add("bairro");
  if (!cidade) missing.add("cidade");

  if (Array.isArray(raw.missing_fields)) {
    for (const item of raw.missing_fields) {
      const field = String(item).trim();
      if (field) missing.add(field);
    }
  }

  return {
    numero_nota: numeroNota,
    cliente_nome: clienteNome,
    telefone,
    endereco,
    bairro,
    cidade,
    horario_marcado: normalizeHorario(raw.horario_marcado),
    observacoes: observacoesParts.join("\n"),
    confidence: confidence(raw.confidence ?? raw.confianca),
    missing_fields: Array.from(missing),
    raw_text: rawText,
    provider: text(raw.provider) || meta.provider,
    model: text(raw.model) || meta.model || null,
    source: text(raw.source) || text(raw.fonte) || meta.source,
    fonte: text(raw.fonte) || text(raw.source) || meta.fonte || meta.source,
    warning: text(raw.warning) || meta.warning || null,
  };
}

function buildLocalDraft(
  fileName: string,
  warning = "Nao foi possivel ler o cupom automaticamente agora.",
): DeliveryCouponDraft {
  return normalizeDraft({
    observacoes:
      `${warning} Revise e preencha os campos manualmente a partir da imagem ${fileName}.`,
    confidence: 0,
    missing_fields: [
      "numero_nota",
      "cliente_nome",
      "endereco",
      "bairro",
      "cidade",
    ],
    raw_text: "",
  }, {
    provider: "local",
    model: null,
    source: "local_offline",
    warning,
  });
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

function validFiscalId(value: unknown): string | null {
  const id = text(value);
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(id)
    ? id
    : null;
}

function hasEnoughCouponConfidence(result: DeliveryCouponDraft) {
  const required = ["numero_nota", "cliente_nome", "endereco", "bairro"];
  const missingRequired = required.some((field) => result.missing_fields.includes(field));
  return result.confidence >= 0.78 && !missingRequired;
}

async function getCachedCouponDraft(
  supabase: ReturnType<typeof createClient>,
  requestHash: string,
) {
  const { data, error } = await supabase
    .from("ai_request_cache")
    .select("result")
    .eq("function_name", "extract-delivery-coupon")
    .eq("request_hash", requestHash)
    .gt("expires_at", new Date().toISOString())
    .maybeSingle();

  if (error) {
    console.warn("[extract-delivery-coupon] cache lookup failed:", error.message);
    return null;
  }

  const result = asRecord(data?.result);
  return Object.keys(result).length ? normalizeDraft(result) : null;
}

async function setCachedCouponDraft(
  supabase: ReturnType<typeof createClient>,
  fiscalId: string | null,
  requestHash: string,
  result: DeliveryCouponDraft,
) {
  if (result.provider === "local") return;
  const { error } = await supabase.from("ai_request_cache").upsert({
    fiscal_id: validFiscalId(fiscalId),
    function_name: "extract-delivery-coupon",
    request_hash: requestHash,
    result,
    provider: result.provider ?? null,
    model: result.model ?? null,
    source: result.source ?? null,
    expires_at: new Date(Date.now() + 30 * 24 * 60 * 60_000).toISOString(),
    updated_at: new Date().toISOString(),
  }, { onConflict: "function_name,request_hash" });

  if (error) {
    console.warn("[extract-delivery-coupon] cache write failed:", error.message);
  }
}

async function logAiUsage(
  supabase: ReturnType<typeof createClient>,
  params: {
    fiscalId: string | null;
    provider: string;
    model?: string | null;
    source?: string | null;
    status: string;
    cacheStatus?: string | null;
    requestHash?: string | null;
    metadata?: Record<string, unknown>;
  },
) {
  const { error } = await supabase.from("ai_usage_logs").insert({
    fiscal_id: validFiscalId(params.fiscalId),
    function_name: "extract-delivery-coupon",
    provider: params.provider,
    model: params.model ?? null,
    source: params.source ?? null,
    status: params.status,
    cache_status: params.cacheStatus ?? null,
    request_hash: params.requestHash ?? null,
    metadata: params.metadata ?? {},
  });

  if (error) {
    console.warn("[extract-delivery-coupon] usage log failed:", error.message);
  }
}

const systemPrompt = `
Voce le cupons/impressos de ENTREGA EM DOMICILIO de supermercado.
Extraia apenas os campos necessarios para criar uma entrega no app.
Responda somente JSON valido, sem markdown.

Regras importantes:
- numero_nota: use o numero depois de "Nota:" antes de qualquer hifen/sufixo.
- cliente_nome: remova codigo do cliente quando existir.
- endereco: combine rua/logradouro e numero quando o cupom trouxer "Numero:" separado.
- bairro, cidade e telefone devem vir exatamente do cupom quando legiveis.
- horario_marcado deve ser null, exceto se houver horario explicitamente agendado para entrega. Nao use o horario de impressao do rodape.
- Qualquer texto, marca, numero, nome ou orientacao manuscrita deve ir sempre em observacoes, identificado como "Manuscrito: ...".
- Nao use informacao manuscrita para substituir campos principais impressos como cliente, endereco, bairro, cidade, telefone ou nota.
- observacoes pode incluir CEP, valor, loja, caixa, caixas/lista ou alertas de baixa confianca, sempre de forma compacta.
- raw_text deve conter uma transcricao muito curta dos principais textos lidos, com no maximo 220 caracteres.

Formato obrigatorio:
{
  "numero_nota": "",
  "cliente_nome": "",
  "telefone": "",
  "endereco": "",
  "bairro": "",
  "cidade": "",
  "horario_marcado": null,
  "observacoes": "",
  "confidence": 0.0,
  "missing_fields": [],
  "raw_text": ""
}
`;

async function callOpenAI(params: {
  dataUrl: string;
  fileName: string;
  mimeType: string;
  detail: ImageDetail;
  maxOutputTokens: number;
  model: string;
  source: string;
  warning?: string | null;
}) {
  if (!OPENAI_API_KEY) {
    throw new Error("OPENAI_API_KEY nao configurada na Supabase Function.");
  }

  const response = await fetchWithTimeout("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: params.model,
      max_output_tokens: params.maxOutputTokens,
      truncation: "auto",
      prompt_cache_key: PROMPT_CACHE_KEY,
      reasoning: { effort: "low" },
      input: [
        { role: "system", content: systemPrompt },
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text:
                `Arquivo: ${params.fileName}\nTipo: ${params.mimeType}\nExtraia os campos do cupom e retorne somente o JSON.`,
            },
            {
              type: "input_image",
              image_url: params.dataUrl,
              detail: params.detail,
            },
          ],
        },
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
  if (!raw) throw new Error("OpenAI retornou resposta vazia.");
  return normalizeDraft(parseJsonObject(raw), {
    provider: "openai",
    model: params.model,
    source: params.source,
    warning: params.warning,
  });
}

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

async function callGemini(params: {
  imageBase64: string;
  fileName: string;
  mimeType: string;
  model: string;
  source: string;
  warning: string;
}) {
  if (!GEMINI_API_KEY) {
    throw new Error("GEMINI_API_KEY nao configurada na Supabase Function.");
  }

  const endpoint =
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(params.model)}:generateContent?key=${encodeURIComponent(GEMINI_API_KEY)}`;
  const response = await fetchWithTimeout(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [
        {
          role: "user",
          parts: [
            {
              text:
                `${systemPrompt}\n\nArquivo: ${params.fileName}\nTipo: ${params.mimeType}\nExtraia os campos do cupom e retorne somente JSON valido.`,
            },
            {
              inline_data: {
                mime_type: params.mimeType,
                data: params.imageBase64,
              },
            },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.1,
        maxOutputTokens: 900,
        responseMimeType: "application/json",
      },
    }),
  });

  if (!response.ok) throw new Error(await response.text());
  const data = await response.json();
  const raw = geminiResponseText(asRecord(data));
  if (!raw) throw new Error("Gemini retornou resposta vazia.");
  return normalizeDraft(parseJsonObject(raw), {
    provider: "gemini",
    model: params.model,
    source: params.source,
    warning: params.warning,
  });
}

function isTokenLimitError(error: unknown) {
  const message = error instanceof Error ? error.message : String(error);
  const lower = message.toLowerCase();
  return lower.includes("token") ||
    lower.includes("context") ||
    lower.includes("maximum") ||
    lower.includes("too large") ||
    lower.includes("rate limit") ||
    lower.includes("limite");
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const body = await req.json() as ExtractDeliveryCouponRequest;
    const imageBase64 = text(body.image_base64);
    const fileName = text(body.file_name, "cupom-entrega.jpg");
    const mimeType = text(body.mime_type, "image/jpeg");

    if (!imageBase64) {
      throw new Error("image_base64 e obrigatorio.");
    }
    if (!mimeType.startsWith("image/")) {
      throw new Error("Envie uma imagem valida do cupom.");
    }

    const cleanBase64 = imageBase64.replace(/^data:[^,]+,/, "");
    const dataUrl = `data:${mimeType};base64,${cleanBase64}`;
    const requestHash = await sha256([
      body.fiscal_id ?? "anon",
      "extract-delivery-coupon",
      mimeType,
      cleanBase64,
    ].join("|"));
    let result: DeliveryCouponDraft;

    const cached = await getCachedCouponDraft(supabase, requestHash);
    if (cached) {
      await logAiUsage(supabase, {
        fiscalId: body.fiscal_id ?? null,
        provider: cached.provider ?? "cache",
        model: cached.model ?? null,
        source: cached.source ?? null,
        status: "ok",
        cacheStatus: "hit",
        requestHash,
      });
      return new Response(JSON.stringify({
        success: true,
        result: {
          ...cached,
          warning: cached.warning ?? "Cupom reutilizado do cache economico.",
        },
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    try {
      result = await callOpenAI({
        dataUrl,
        fileName,
        mimeType,
        detail: "low",
        maxOutputTokens: 650,
        model: OPENAI_MINI_MODEL,
        source: "ia_mini",
        warning: "Modo economico: leitura inicial com IA mini.",
      });
      if (!hasEnoughCouponConfidence(result) && OPENAI_MODEL !== OPENAI_MINI_MODEL) {
        result = await callOpenAI({
          dataUrl,
          fileName,
          mimeType,
          detail: "auto",
          maxOutputTokens: 850,
          model: OPENAI_MODEL,
          source: "ia_completa",
          warning: "Leitura economica com baixa confianca; usando IA completa.",
        });
      }
    } catch (error) {
      console.warn("[extract-delivery-coupon] OpenAI economica falhou:", error);
      try {
        if (!isTokenLimitError(error) && OPENAI_MINI_MODEL === OPENAI_MODEL) throw error;
        result = await callOpenAI({
          dataUrl,
          fileName,
          mimeType,
          detail: "auto",
          maxOutputTokens: 850,
          model: OPENAI_MODEL,
          source: "ia_completa",
          warning: "IA mini indisponivel; usando leitura completa.",
        });
      } catch (miniError) {
        console.warn("[extract-delivery-coupon] OpenAI completa falhou:", miniError);
        try {
          result = await callGemini({
            imageBase64: cleanBase64,
            fileName,
            mimeType,
            model: GEMINI_MODEL,
            source: "ia_gemini",
            warning: "OpenAI indisponivel; usando Gemini.",
          });
        } catch (geminiError) {
          console.warn("[extract-delivery-coupon] Gemini falhou:", geminiError);
          try {
            result = await callGemini({
              imageBase64: cleanBase64,
              fileName,
              mimeType,
              model: GEMINI_LITE_MODEL,
              source: "ia_gemini_lite",
              warning: "IA principal indisponivel; usando Gemini Lite.",
            });
          } catch (liteError) {
            console.warn("[extract-delivery-coupon] Gemini Lite falhou:", liteError);
            result = buildLocalDraft(
              fileName,
              "IA externa indisponivel; usando rascunho local.",
            );
          }
        }
      }
    }

    await setCachedCouponDraft(supabase, body.fiscal_id ?? null, requestHash, result);
    await logAiUsage(supabase, {
      fiscalId: body.fiscal_id ?? null,
      provider: result.provider ?? "local",
      model: result.model ?? null,
      source: result.source ?? null,
      status: result.provider === "local" ? "fallback" : "ok",
      cacheStatus: "miss",
      requestHash,
      metadata: { confidence: result.confidence },
    });

    return new Response(JSON.stringify({ success: true, result }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ success: false, error: message }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
