import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const OPENAI_MODEL =
  Deno.env.get("OPENAI_VISION_MODEL") ?? Deno.env.get("OPENAI_MODEL") ?? "gpt-5.4-mini";

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

function normalizeDraft(raw: Record<string, unknown>): DeliveryCouponDraft {
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
  };
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
}) {
  if (!OPENAI_API_KEY) {
    throw new Error("OPENAI_API_KEY nao configurada na Supabase Function.");
  }

  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      max_output_tokens: params.maxOutputTokens,
      truncation: "auto",
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
  return normalizeDraft(parseJsonObject(raw));
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
    let result: DeliveryCouponDraft;

    try {
      result = await callOpenAI({
        dataUrl,
        fileName,
        mimeType,
        detail: "auto",
        maxOutputTokens: 850,
      });
    } catch (error) {
      if (!isTokenLimitError(error)) throw error;
      result = await callOpenAI({
        dataUrl,
        fileName,
        mimeType,
        detail: "low",
        maxOutputTokens: 650,
      });
    }

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
