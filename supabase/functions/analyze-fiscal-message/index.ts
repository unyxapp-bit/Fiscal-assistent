import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// ─────────────────────────────────────────────────────────────
//  CATEGORIZAÇÃO POR REGRAS (custo zero)
//  Cobre ~80% das mensagens típicas de um balcão fiscal.
// ─────────────────────────────────────────────────────────────

interface RuleResult {
  category: string;
  description: string;
  employee_name: string | null;
  amount: number | null;
  confidence: number;
}

function extrairValor(msg: string): number | null {
  // Prioridade: R$ 10,50 → R$10 → 10,50 reais → 10 reais
  const match = msg.match(/R\$\s*([\d.,]+)/i) ??
                msg.match(/([\d]+[.,][\d]{2})\s*(?:reais?)?/i) ??
                msg.match(/(\d+)\s*(?:real|reais)/i);
  if (!match) return null;
  const raw = match[1].replace(',', '.');
  const val = parseFloat(raw);
  return isNaN(val) ? null : val;
}

function extrairNome(msg: string, sender: string): string | null {
  // Padrões: "de João", "da Maria", "o João faltou", "funcionário: Ana"
  const patterns = [
    /(?:de|da|do)\s+([A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+(?:\s+[A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+)?)/,
    /^([A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+)\s+(?:faltou|não veio|ausente|atestado|férias|saiu|chegou)/,
    /funcionário[:\s]+([A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+)/i,
  ];
  for (const p of patterns) {
    const m = msg.match(p);
    if (m) return m[1];
  }
  // Se o sender parece um nome (não é número de telefone), usa sender
  if (sender && !/^\d/.test(sender) && sender.length > 3) return sender;
  return null;
}

function categorizarPorRegra(msg: string, sender: string): RuleResult | null {
  const m = msg.toLowerCase();

  // CAIXA — falta/sobra de dinheiro
  // Exemplos: "caixa da Ana faltou 10 reais", "faltou R$ 5", "sobrou 2,50 reais no caixa"
  if (/falt(?:ou|a)\s*r\$|sobr(?:ou|a)\s*r\$|diferen.a\s*(?:no\s*)?caixa|falta\s*(?:de\s*)?dinheiro|caixa\s*falt|(?:caixa|cx)\b.{0,50}\b(?:falt|sobr)|(?:falt|sobr)(?:ou|a)\s+\d+.{0,20}reais?/i.test(msg)) {
    return {
      category: 'caixa',
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount: extrairValor(msg),
      confidence: 0.92,
    };
  }

  // ATESTADO — afastamento médico
  if (/atestado|afastamento|afastad[oa]|licen.a\s*m.dica/i.test(msg)) {
    return {
      category: 'atestado',
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount: null,
      confidence: 0.93,
    };
  }

  // AUSÊNCIA — não veio trabalhar (sem mencionar atestado)
  if (/faltou|n.o\s*veio|ausente|n.o\s*apareceu|faltando hoje/i.test(msg)) {
    return {
      category: 'ausencia',
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount: null,
      confidence: 0.88,
    };
  }

  // FÉRIAS
  if (/f.rias|inicio\s*de\s*f.rias|volta\s*de\s*f.rias|entrou\s*de\s*f.rias|saiu\s*de\s*f.rias/i.test(msg)) {
    return {
      category: 'ferias',
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount: null,
      confidence: 0.92,
    };
  }

  // VALE TROCA / DESCONTO
  if (/vale\s*troca|vale\s*desconto|desconto\s*para\s*cliente|cupom\s*de\s*desconto/i.test(msg)) {
    return {
      category: 'vale',
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount: extrairValor(msg),
      confidence: 0.90,
    };
  }

  // HORÁRIO ESPECIAL — entrada/saída fora do horário
  if (/vai\s*chegar|chegando\s*(?:mais\s*)?tarde|vai\s*sair\s*(?:mais\s*)?cedo|saindo\s*antes|atraso(?:ada)?|hora\s*extra|ficando\s*depois/i.test(msg)) {
    return {
      category: 'horario_especial',
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount: null,
      confidence: 0.85,
    };
  }

  // PROBLEMA OPERACIONAL — erros técnicos
  if (/pos\s*duplicad|c.digo\s*n.o\s*encontrad|sistema\s*(?:fora|caiu|erro)|erro\s*no\s*(?:sistema|terminal|pos|caixa)|n.o\s*est.\s*funcionando|terminal\s*travad/i.test(msg)) {
    return {
      category: 'problema_operacional',
      description: msg.trim(),
      employee_name: null,
      amount: null,
      confidence: 0.87,
    };
  }

  // Não reconheceu — vai para IA
  return null;
}

// ─────────────────────────────────────────────────────────────
//  CATEGORIZAÇÃO POR IA (Claude Haiku — fallback econômico)
// ─────────────────────────────────────────────────────────────

const SYSTEM_PROMPT = `Você analisa mensagens de um grupo de fiscais de supermercado chamado "Balcão Fiscal".

Categorias disponíveis:
- caixa: falta ou sobra de dinheiro no caixa (sempre tem valor em R$)
- ausencia: funcionário que não veio trabalhar
- atestado: afastamento médico com atestado
- horario_especial: funcionário entrando ou saindo fora do horário padrão
- ferias: aviso de início ou fim de férias
- vale: vale troca ou desconto emitido para cliente
- problema_operacional: erro técnico, POS duplicado, código não encontrado, sistema
- aviso_geral: demais informes, recados, perguntas

Retorne APENAS um JSON válido, sem texto antes ou depois, sem markdown.`;

async function categorizarComIA(
  message: string,
  sender: string
): Promise<RuleResult> {
  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-haiku-4-5-20251001",  // Haiku: ~20x mais barato que Sonnet
      max_tokens: 300,
      system: SYSTEM_PROMPT,
      messages: [
        {
          role: "user",
          content: `Remetente: ${sender || "Desconhecido"}\nMensagem: ${message}\n\nRetorne JSON com:\n{\n  "category": "uma das categorias acima",\n  "description": "resumo claro e curto em português",\n  "employee_name": "nome do funcionário ou null",\n  "amount": valor numérico (ex: 9.90) ou null,\n  "confidence": número entre 0.0 e 1.0\n}`,
        },
      ],
    }),
  });

  const data = await response.json();
  const rawText = data.content?.[0]?.text ?? "";

  try {
    const clean = rawText.replace(/```json|```/g, "").trim();
    return JSON.parse(clean);
  } catch {
    return {
      category: "aviso_geral",
      description: message,
      employee_name: null,
      amount: null,
      confidence: 0.5,
    };
  }
}

// ─────────────────────────────────────────────────────────────
//  HANDLER PRINCIPAL
// ─────────────────────────────────────────────────────────────

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { sender, message, timestamp } = await req.json();

    if (!message || message.trim() === "") {
      return new Response(JSON.stringify({ error: "Mensagem vazia" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1. Tenta regra local (custo zero)
    let parsed = categorizarPorRegra(message, sender ?? "");
    const usouIA = parsed === null;

    // 2. Fallback para Claude Haiku apenas se necessário
    if (!parsed) {
      parsed = await categorizarComIA(message, sender ?? "");
    }

    // 3. Salva no banco
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const { data, error } = await supabase
      .from("fiscal_events")
      .insert({
        category: parsed.category,
        description: parsed.description,
        employee_name: parsed.employee_name,
        amount: parsed.amount,
        sender: sender || null,
        raw_message: message,
        event_date: timestamp ?? new Date().toISOString(),
        status: "pending",
        confidence: parsed.confidence,
      })
      .select()
      .single();

    if (error) throw error;

    return new Response(
      JSON.stringify({ success: true, event: data, ia_used: usouIA }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Erro na Edge Function:", err);
    return new Response(
      JSON.stringify({ success: false, error: String(err) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
