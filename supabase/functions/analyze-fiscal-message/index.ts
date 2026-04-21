import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// ─────────────────────────────────────────────────────────────
//  FILTRO SOCIAL — descarta mensagens sem conteúdo fiscal
//  Exemplos reais do grupo: "Bom dia pessoal", "Ok", "Já veio",
//  "Não me lembro", "Blz", "Obrigada"
// ─────────────────────────────────────────────────────────────

const SOCIAL_EXACT = new Set([
  'ok', 'blz', 'beleza', 'obrigada', 'obrigado', 'obg', 'de nada',
  'sim', 'nao', 'não', 'tmj', 'vlw', 'valeu', 'combinado', 'entendido',
  'perfeito', 'certo', 'ta joia', 'tá joia', 'tá bom', 'ta bom',
  'já veio', 'ja veio', 'deu certo', 'deu certinho', 'ja deu certo',
  'já deu certo', 'ainda não', 'ainda nao', 'não me lembro', 'nao me lembro',
  'não lembro', 'nao lembro', 'bom dia', 'boa tarde', 'boa noite',
  'bom dia!', 'boa tarde!', 'boa noite!', 'bom dia pessoal',
  'boa tarde pessoal', 'boa noite pessoal', 'bom dia pessoal!',
  'boa noite!', 'já', 'nao sei', 'não sei', 'não troquei',
  'nao troquei', 'não troquei não', 'nao troquei nao',
]);

function isNaoRelevante(msg: string): boolean {
  const t = msg.trim();
  if (t.length <= 3) return true; // "ok", "blz", "já"

  const lower = t.toLowerCase();
  if (SOCIAL_EXACT.has(lower)) return true;

  // Mensagens curtas sem palavras-chave fiscais
  if (t.length <= 30) {
    const hasFiscal = /falt|sobr|atestado|ausente|caixa|vale|desconto|pos\b|tef\b|f[eé]rias|afastamento|atraso|entrar|horário|impressora|cooper/i.test(t);
    if (!hasFiscal) {
      if (/^(?:bom\s+dia|boa\s+(?:tarde|noite))\s*[!.,]?\s*(?:pessoal|gente|todos?)?\s*[!.]?\s*$/i.test(lower)) return true;
      if (/^n[aã]o\s+(?:me\s+)?(?:lembro|sei|acho)\s*(?:n[aã]o)?\s*[!.,]?\s*$/i.test(lower)) return true;
      if (/^n[aã]o\s+(?:troquei|dei|fiz|tenho|foi)\s*(?:n[aã]o)?\s*[!.,]?\s*$/i.test(lower)) return true;
      if (/^j[aá]\s+(?:veio|deu\s+certo|entrei|avisei|foi|vou)\s*[!.,]?\s*$/i.test(lower)) return true;
      if (/^(?:deu\s+(?:certo|certinho)|já\s+deu\s+certo|ja\s+deu\s+certo)\s*[!.]?\s*$/i.test(lower)) return true;
    }
  }

  return false;
}

// ─────────────────────────────────────────────────────────────
//  CATEGORIZAÇÃO POR REGRAS (custo zero)
//  Cobre ~80% das mensagens típicas do Balcão Fiscal.
// ─────────────────────────────────────────────────────────────

interface RuleResult {
  category: string;
  description: string;
  employee_name: string | null;
  amount: number | null;
  confidence: number;
}

function extrairValor(msg: string): number | null {
  // Prioridade: R$ 10,50 → R$10 → 10,50 reais → 10 reais → número decimal solto
  const match = msg.match(/R\$\s*([\d.,]+)/i) ??
                msg.match(/([\d]+[.,][\d]{2})\s*(?:reais?|centavos?)?/i) ??
                msg.match(/(\d+)\s*(?:real|reais)/i);
  if (!match) return null;
  const raw = match[1].replace(',', '.');
  const val = parseFloat(raw);
  return isNaN(val) ? null : val;
}

function extrairNome(msg: string, sender: string): string | null {
  const patterns = [
    /(?:de|da|do)\s+([A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+(?:\s+[A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+)?)/,
    /^([A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+)\s+(?:faltou|n[aã]o\s+veio|ausente|atestado|f[eé]rias|saiu|chegou|vai\s+entrar|vai\s+sair)/,
    /funcionário[:\s]+([A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+)/i,
    /op(?:erador)?\s+([A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+)/i,
    /caixa\s+(?:da?o?\s+)?([A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+)/i,
  ];
  for (const p of patterns) {
    const m = msg.match(p);
    if (m) return m[1];
  }
  if (sender && !/^\d/.test(sender) && sender.length > 3) return sender;
  return null;
}

function categorizarPorRegra(msg: string, sender: string): RuleResult | null {
  const m = msg.toLowerCase();

  // CAIXA — falta/sobra de dinheiro no caixa
  // Padrões reais: "O caixa da Talita faltou 9,90", "sobrou 10,76",
  // "Ta faltando um desconto de 0,60 centavos no caixa 106", "Segunda faltou 74,27"
  if (/falt(?:ou|a|ando)\s*r\$|sobr(?:ou|a)\s*r\$|diferen.a\s*(?:no\s*)?caixa|falta\s*(?:de\s*)?dinheiro/i.test(msg) ||
      /(?:caixa|cx)\b.{0,60}\b(?:falt|sobr)/i.test(msg) ||
      /(?:falt|sobr)(?:ou|a)\b.{0,60}\b(?:caixa|cx)\b/i.test(msg) ||
      /(?:falt|sobr)(?:ou|a|ando)\s+\d+[.,]\d{2}/i.test(msg) ||
      /(?:falt|sobr)(?:ou|a|ando)\s+\d+\s*(?:real|reais)/i.test(msg) ||
      /(?:ta|tá|está|esta)\s+faltando.{0,40}(?:caixa|desconto|r\$|\d)/i.test(msg)) {
    return {
      category: 'caixa',
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount: extrairValor(msg),
      confidence: 0.92,
    };
  }

  // ATESTADO — afastamento médico
  if (/atestado|afastamento|afastad[oa]|licen.a\s*m.dica|postinho|conjuntivite|m[eé]dico\s+receitou/i.test(msg)) {
    return {
      category: 'atestado',
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount: null,
      confidence: 0.93,
    };
  }

  // AUSÊNCIA — não veio trabalhar (sem atestado)
  if (/\bn[aã]o\s+veio\b|ausente|n[aã]o\s+apareceu|faltando\s+hoje|\bfaltou\b(?!.{0,30}r\$)(?!.{0,30}\d+[,.])/i.test(msg)) {
    return {
      category: 'ausencia',
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount: null,
      confidence: 0.88,
    };
  }

  // FÉRIAS
  if (/f[eé]rias|inicio\s*de\s*f[eé]rias|volta\s*de\s*f[eé]rias|entrou\s*de\s*f[eé]rias|saiu\s*de\s*f[eé]rias|sobre\s+as\s+f[eé]rias/i.test(msg)) {
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
  // Padrões reais: "Giulia vai entrar 8:00h", "Vou atrasar um pouquinho",
  // "A Fran vai entrar 07:00", "Yara vai entrar 07:50 segunda"
  if (/vai\s*(?:chegar|entrar|sair)|vou\s*(?:entrar|sair|chegar)|chegando\s*(?:mais\s*)?tarde|vai\s*sair\s*(?:mais\s*)?cedo|saindo\s*antes|atraso(?:ada)?|atrasar|hora\s*extra|ficando\s*depois|entrar?\s*\d{1,2}[h:]\d{0,2}|entrar?\s*(?:às|as)\s*\d|sair?\s*(?:às|as)\s*\d|\d{1,2}[h:]\d{2}\s*(?:segunda|terça|quarta|quinta|sexta|sábado|domingo|amanhã|hoje)/i.test(msg)) {
    return {
      category: 'horario_especial',
      description: msg.trim(),
      employee_name: extrairNome(msg, sender),
      amount: null,
      confidence: 0.85,
    };
  }

  // PROBLEMA OPERACIONAL — erros técnicos, TEF, impressora, POS
  // Padrões reais: "2 cartões no Tef", "fechando pos errado", "impressora com problema",
  // "cartão cobrado duas vezes", "pos duplicado"
  if (/pos\s*duplicad|c[oó]digo\s*n[aã]o\s*encontrad|sistema\s*(?:fora|caiu|erro)|erro\s*no\s*(?:sistema|terminal|pos|caixa)|n[aã]o\s*est[aá]\s*funcionando|terminal\s*travad|impressora.*problem|problem.*impressora|tef.*cart[aã]o|cart[aã]o.*tef|(?:dois|2)\s*cart[oã]es?.*tef|tef.*(?:dois|2)\s*cart[oã]es?|cart[aã]o\s*cobrado.*(?:duas?|2)\s*vez|pos\s*errado|fechando.*pos.*errado|vis[ae]\s*electron.*débito|pré.?pago.*errado/i.test(msg)) {
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
- caixa: falta ou sobra de dinheiro no caixa (ex: "caixa da Talita faltou 9,90", "sobrou 10,76")
- ausencia: funcionário que não veio trabalhar (ex: "Ingrid não veio")
- atestado: afastamento médico com atestado
- horario_especial: funcionário entrando ou saindo fora do horário (ex: "vai entrar 8:00h", "vou atrasar")
- ferias: aviso de início ou fim de férias
- vale: vale troca ou desconto emitido para cliente
- problema_operacional: erro técnico, POS errado, TEF com problemas, impressora, sistema
- aviso_geral: informes operacionais relevantes que não se enquadram acima (ex: instruções ao time, avisos sobre clientes, procedimentos)
- nao_relevante: mensagem puramente social ou conversacional sem informação fiscal (ex: "bom dia", "ok", "já veio", "não me lembro", "obrigada")

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
      model: "claude-haiku-4-5-20251001",
      max_tokens: 300,
      system: SYSTEM_PROMPT,
      messages: [
        {
          role: "user",
          content: `Remetente: ${sender || "Desconhecido"}\nMensagem: ${message}\n\nRetorne JSON com:\n{\n  "category": "uma das categorias acima",\n  "description": "resumo claro e curto em português (vazio se nao_relevante)",\n  "employee_name": "nome do funcionário ou null",\n  "amount": valor numérico (ex: 9.90) ou null,\n  "confidence": número entre 0.0 e 1.0\n}`,
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
//  MATCH DE COLABORADOR — fuzzy por nome
// ─────────────────────────────────────────────────────────────

interface ColaboradorRow { id: string; nome: string; }

/**
 * Tenta casar o nome extraído com a lista de colaboradores ativos.
 * Estratégias (em ordem de precisão):
 *   1. Exact match (normalizado)
 *   2. Nome extraído é prefixo do primeiro nome do colaborador ("Franci" → "Francielle")
 *   3. Primeiro nome do colaborador é prefixo do nome extraído
 *   4. Nome extraído contém o primeiro nome (≥4 letras)
 * Retorna o id do colaborador ou null se sem confiança suficiente.
 */
function matchColaborador(
  employeeName: string,
  colaboradores: ColaboradorRow[]
): string | null {
  if (!employeeName || employeeName.trim().length < 2) return null;

  const target = employeeName.toLowerCase().trim();

  for (const c of colaboradores) {
    const nome = c.nome.toLowerCase().trim();
    const firstName = nome.split(/\s+/)[0];

    if (nome === target) return c.id;
    if (firstName.startsWith(target) && target.length >= 3) return c.id;
    if (target.startsWith(firstName) && firstName.length >= 3) return c.id;
    if (nome.includes(target) && target.length >= 4) return c.id;
  }

  return null;
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

    // 1. Filtra mensagens puramente sociais (sem custo de IA)
    if (isNaoRelevante(message)) {
      return new Response(
        JSON.stringify({ success: true, skipped: true, reason: "nao_relevante" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Tenta regra local (custo zero)
    let parsed = categorizarPorRegra(message, sender ?? "");
    const usouIA = parsed === null;

    // 3. Fallback para Claude Haiku apenas se necessário
    if (!parsed) {
      parsed = await categorizarComIA(message, sender ?? "");
    }

    // 4. IA também pode devolver nao_relevante — descarta sem salvar
    if (parsed.category === "nao_relevante") {
      return new Response(
        JSON.stringify({ success: true, skipped: true, reason: "nao_relevante_ia" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Match automático de colaborador_id pelo employee_name extraído
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    let colaboradorId: string | null = null;
    if (parsed.employee_name) {
      const { data: colaboradores } = await supabase
        .from("colaboradores")
        .select("id, nome")
        .eq("ativo", true);
      if (colaboradores && colaboradores.length > 0) {
        colaboradorId = matchColaborador(
          parsed.employee_name,
          colaboradores as ColaboradorRow[]
        );
      }
    }

    // 6. Salva no banco
    const { data, error } = await supabase
      .from("fiscal_events")
      .insert({
        category: parsed.category,
        description: parsed.description,
        employee_name: parsed.employee_name,
        colaborador_id: colaboradorId,
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
      JSON.stringify({
        success: true,
        event: data,
        ia_used: usouIA,
        colaborador_matched: colaboradorId !== null,
      }),
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
