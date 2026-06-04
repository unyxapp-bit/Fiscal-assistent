# Plano de Implantação — Resiliência da IA Fiscal

> **Objetivo:** A IA Fiscal nunca mostra "limite esgotado" ou erro de token.  
> **Estratégia:** 6 níveis de fallback — OpenAI → OpenAI Mini → Gemini → Gemini Lite → Local Edge → Local Flutter.

---

## Índice

1. [Visão geral da arquitetura](#1-visão-geral-da-arquitetura)
2. [Pré-requisitos](#2-pré-requisitos)
3. [Passo 1 — Configurar secrets no Supabase](#3-passo-1--configurar-secrets-no-supabase)
4. [Passo 2 — Edge Function: orquestrador com fallback](#4-passo-2--edge-function-orquestrador-com-fallback)
5. [Passo 3 — Edge Function: chamada OpenAI](#5-passo-3--edge-function-chamada-openai)
6. [Passo 4 — Edge Function: chamada Gemini](#6-passo-4--edge-function-chamada-gemini)
7. [Passo 5 — Edge Function: análise local offline](#7-passo-5--edge-function-análise-local-offline)
8. [Passo 6 — Edge Function: filtro de contexto](#8-passo-6--edge-function-filtro-de-contexto)
9. [Passo 7 — Flutter: FiscalAiService com dupla proteção](#9-passo-7--flutter-fiscalaiservice-com-dupla-proteção)
10. [Passo 8 — Flutter: modelo FiscalAiInsight com campo fonte](#10-passo-8--flutter-modelo-fiscalaiinsight-com-campo-fonte)
11. [Passo 9 — Flutter: widget de status da IA](#11-passo-9--flutter-widget-de-status-da-ia)
12. [Passo 10 — Corrigir fiscal_id nos eventos criados pela IA](#12-passo-10--corrigir-fiscal_id-nos-eventos-criados-pela-ia)
13. [Passo 11 — Structured Outputs: schema JSON](#13-passo-11--structured-outputs-schema-json)
14. [Passo 12 — Deploy e validação](#14-passo-12--deploy-e-validação)
15. [Resumo dos secrets necessários](#15-resumo-dos-secrets-necessários)
16. [Tabela de fontes e UX](#16-tabela-de-fontes-e-ux)

---

## 1. Visão geral da arquitetura

```
Flutter App
  │
  ├─ Sem internet? ──────────────────────────────► Análise local Flutter  (fonte: sem_conexao)
  │
  ├─ Chama Edge Function (timeout 30s)
  │     │
  │     ├─ Timeout/erro HTTP? ──────────────────► Análise local Flutter  (fonte: timeout_edge)
  │     │
  │     └─ Edge Function responde:
  │           │
  │           ├─ 1. GPT-4o          contexto completo  ──► ok → retorna (fonte: ia_completa)
  │           ├─ 2. GPT-4o-mini     contexto reduzido  ──► ok → retorna (fonte: ia_mini)
  │           ├─ 3. Gemini 2.0 Flash contexto reduzido ──► ok → retorna (fonte: ia_gemini)
  │           ├─ 4. Gemini Flash-Lite contexto mínimo  ──► ok → retorna (fonte: ia_gemini_lite)
  │           └─ 5. Análise local Edge (sem API)       ──► sempre retorna (fonte: local_offline)
  │
  └─ Flutter lê campo "fonte" e exibe badge correto
```

**Regra de ouro:** A Edge Function **nunca retorna HTTP 500**. Sempre devolve JSON com o campo `fonte`. O Flutter **nunca exibe mensagem de erro técnico** ao usuário.

---

## 2. Pré-requisitos

- Supabase CLI instalado (`npm install -g supabase`)
- Projeto Supabase com Edge Functions ativas
- Chave de API da OpenAI — https://platform.openai.com/api-keys
- Chave de API do Gemini — https://aistudio.google.com/app/apikey (gratuita)
- Flutter com pacote `supabase_flutter` configurado

---

## 3. Passo 1 — Configurar secrets no Supabase

### Via Supabase Dashboard

1. Acesse **Project Settings → Edge Functions → Secrets**
2. Adicione cada secret abaixo:

| Secret | Valor |
|---|---|
| `OPENAI_API_KEY` | sua chave OpenAI |
| `OPENAI_AGENT_MODEL` | `gpt-4o` |
| `OPENAI_MINI_MODEL` | `gpt-4o-mini` |
| `OPENAI_VISION_MODEL` | `gpt-4o` |
| `OPENAI_TRANSCRIBE_MODEL` | `whisper-1` |
| `GEMINI_API_KEY` | sua chave Gemini |
| `GEMINI_MODEL` | `gemini-2.0-flash` |
| `GEMINI_LITE_MODEL` | `gemini-2.0-flash-lite` |

### Via CLI (alternativa)

```bash
supabase secrets set OPENAI_API_KEY=sk-...
supabase secrets set OPENAI_AGENT_MODEL=gpt-4o
supabase secrets set OPENAI_MINI_MODEL=gpt-4o-mini
supabase secrets set GEMINI_API_KEY=AIza...
supabase secrets set GEMINI_MODEL=gemini-2.0-flash
supabase secrets set GEMINI_LITE_MODEL=gemini-2.0-flash-lite
```

> **Atenção:** Após adicionar os secrets, remova o antigo `OPENAI_MODEL` genérico para evitar conflito.

```bash
supabase secrets unset OPENAI_MODEL
```

---

## 4. Passo 2 — Edge Function: orquestrador com fallback

Arquivo: `supabase/functions/fiscal-ai-agent/index.ts`

Substitua a função principal de chamada da IA pelo orquestrador abaixo:

```typescript
// Modelos configurados via secrets
const MODELS = {
  agent:      Deno.env.get('OPENAI_AGENT_MODEL')    ?? 'gpt-4o',
  mini:       Deno.env.get('OPENAI_MINI_MODEL')      ?? 'gpt-4o-mini',
  gemini:     Deno.env.get('GEMINI_MODEL')            ?? 'gemini-2.0-flash',
  geminiLite: Deno.env.get('GEMINI_LITE_MODEL')       ?? 'gemini-2.0-flash-lite',
}

async function chamarIAComFallback(ctx: ContextoFiscal) {

  // Tentativa 1: GPT-4o com contexto completo
  const r1 = await tentarOpenAI(MODELS.agent, montarContexto(ctx, 'completo'))
  if (r1.ok) return { ...r1.resposta, fonte: 'ia_completa' }

  // Tentativa 2: GPT-4o-mini com contexto reduzido
  if (r1.erro === 'rate_limit' || r1.erro === 'token_limit' || r1.erro === 'timeout') {
    const r2 = await tentarOpenAI(MODELS.mini, montarContexto(ctx, 'reduzido'))
    if (r2.ok) return { ...r2.resposta, fonte: 'ia_mini' }
  }

  // Tentativa 3: Gemini 2.0 Flash — API independente da OpenAI
  const r3 = await tentarGemini(MODELS.gemini, montarContexto(ctx, 'reduzido'))
  if (r3.ok) return { ...r3.resposta, fonte: 'ia_gemini' }

  // Tentativa 4: Gemini Flash-Lite — gratuito, mais leve
  const r4 = await tentarGemini(MODELS.geminiLite, montarContexto(ctx, 'minimo'))
  if (r4.ok) return { ...r4.resposta, fonte: 'ia_gemini_lite' }

  // Tentativa 5: análise local — nunca falha, sem API externa
  return { ...analisarLocalmente(ctx), fonte: 'local_offline' }
}
```

---

## 5. Passo 3 — Edge Function: chamada OpenAI

Adicione esta função ao arquivo da Edge Function:

```typescript
async function tentarOpenAI(model: string, contexto: object) {
  const ctrl  = new AbortController()
  const timer = setTimeout(() => ctrl.abort(), 25_000) // 25s por tentativa

  try {
    const res = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      signal: ctrl.signal,
      headers: {
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model,
        max_tokens: 1000,
        response_format: {
          type: 'json_schema',
          json_schema: FISCAL_SCHEMA, // ver Passo 11
        },
        messages: montarMensagensOpenAI(contexto),
      }),
    })
    clearTimeout(timer)

    if (res.status === 429) return { ok: false, erro: 'rate_limit' }
    if (res.status === 400) return { ok: false, erro: 'token_limit' }
    if (!res.ok)            return { ok: false, erro: 'api_error' }

    const data = await res.json()
    const content = data.choices?.[0]?.message?.content
    if (!content) return { ok: false, erro: 'resposta_vazia' }

    return { ok: true, resposta: JSON.parse(content) }

  } catch (e) {
    clearTimeout(timer)
    if (e.name === 'AbortError') return { ok: false, erro: 'timeout' }
    return { ok: false, erro: 'network' }
  }
}

function montarMensagensOpenAI(contexto: object) {
  return [
    {
      role: 'system',
      content: `Você é um assistente fiscal. Analise o contexto e retorne insights e ações sugeridas.
Responda SOMENTE com JSON válido seguindo o schema fornecido.`,
    },
    {
      role: 'user',
      content: JSON.stringify(contexto),
    },
  ]
}
```

---

## 6. Passo 4 — Edge Function: chamada Gemini

Adicione esta função ao arquivo da Edge Function:

```typescript
async function tentarGemini(model: string, contexto: object) {
  const key = Deno.env.get('GEMINI_API_KEY')
  if (!key) return { ok: false, erro: 'sem_chave' }

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${key}`

  const ctrl  = new AbortController()
  const timer = setTimeout(() => ctrl.abort(), 25_000)

  try {
    const res = await fetch(url, {
      method: 'POST',
      signal: ctrl.signal,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            parts: [{ text: montarPromptGemini(contexto) }],
          },
        ],
        generationConfig: {
          responseMimeType: 'application/json',
          responseSchema: FISCAL_SCHEMA_GEMINI, // ver Passo 11
        },
      }),
    })
    clearTimeout(timer)

    if (res.status === 429) return { ok: false, erro: 'rate_limit' }
    if (res.status === 503) return { ok: false, erro: 'indisponivel' }
    if (!res.ok)            return { ok: false, erro: 'api_error' }

    const data  = await res.json()
    const text  = data.candidates?.[0]?.content?.parts?.[0]?.text
    if (!text) return { ok: false, erro: 'resposta_vazia' }

    return { ok: true, resposta: JSON.parse(text) }

  } catch (e) {
    clearTimeout(timer)
    if (e.name === 'AbortError') return { ok: false, erro: 'timeout' }
    return { ok: false, erro: 'network' }
  }
}

function montarPromptGemini(contexto: object): string {
  return `Você é um assistente fiscal. Analise o contexto abaixo e retorne insights e ações sugeridas.
Responda SOMENTE com JSON válido seguindo o schema configurado.

CONTEXTO:
${JSON.stringify(contexto, null, 2)}`
}
```

---

## 7. Passo 5 — Edge Function: análise local offline

Esta função roda dentro da própria Edge Function sem chamar nenhuma API. **Nunca lança exceção.**

```typescript
function analisarLocalmente(ctx: ContextoFiscal) {
  const pendencias = ctx.eventos.filter(e => e.status === 'aberto')
  const criticos   = pendencias.filter(e => e.critico === true || (e.atraso_min ?? 0) > 30)

  return {
    resumo: `${pendencias.length} pendência(s) aberta(s). ${criticos.length} crítica(s).`,
    insights: criticos.slice(0, 3).map(e => ({
      tipo:      'alerta',
      titulo:    e.tipo ?? 'Evento pendente',
      descricao: `Evento ${e.id} em aberto${e.atraso_min ? ` há ${e.atraso_min} min` : ''}.`,
      evento_id: e.id,
    })),
    acoes_sugeridas: criticos.length > 0
      ? [{ acao: 'revisar_pendencias', label: 'Revisar pendências críticas', fiscal_id: ctx.fiscal_id }]
      : [],
  }
}
```

---

## 8. Passo 6 — Edge Function: filtro de contexto

Substitui a montagem atual do contexto que enviava até 120+ itens:

```typescript
type NivelContexto = 'completo' | 'reduzido' | 'minimo'

function montarContexto(ctx: ContextoFiscal, nivel: NivelContexto) {
  const limites = {
    completo: { eventos: 20, colaboradores: 15, caixas: 10, chars: 300 },
    reduzido: { eventos: 8,  colaboradores: 5,  caixas: 5,  chars: 150 },
    minimo:   { eventos: 3,  colaboradores: 0,  caixas: 0,  chars: 80  },
  }
  const L = limites[nivel]

  return {
    fiscal_id: ctx.fiscal_id,

    pendencias: ctx.eventos
      .filter(e => e.status === 'aberto' || e.critico === true)
      .slice(0, L.eventos)
      .map(e => ({
        id:     e.id,
        tipo:   e.tipo,
        resumo: e.texto?.slice(0, L.chars) ?? '',
        critico: e.critico ?? false,
      })),

    equipe: nivel === 'minimo' ? [] :
      ctx.colaboradores
        .filter(c => c.ativo)
        .slice(0, L.colaboradores)
        .map(c => ({ nome: c.nome, status: c.status })),

    caixas: nivel === 'minimo' ? [] :
      ctx.caixas
        .filter(c => c.aberta)
        .slice(0, L.caixas)
        .map(c => ({ id: c.id, nome: c.nome, saldo: c.saldo })),
  }
}
```

---

## 9. Passo 7 — Flutter: FiscalAiService com dupla proteção

Arquivo: `lib/services/fiscal_ai_service.dart`

```dart
import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fiscal_ai_insight.dart';
import '../models/fiscal_contexto.dart';

class FiscalAiService {
  final _supabase = Supabase.instance.client;

  Future<FiscalAiInsight> analisar(FiscalContexto ctx) async {
    // Proteção 1: sem internet → análise local imediata
    if (!await _temConexao()) {
      return _analisarLocalmente(ctx, fonte: 'sem_conexao');
    }

    try {
      // Proteção 2: timeout de 30s na chamada da Edge Function
      final resp = await _supabase.functions
          .invoke(
            'fiscal-ai-agent',
            body: _montarPayload(ctx),
          )
          .timeout(const Duration(seconds: 30));

      if (resp.data == null) {
        return _analisarLocalmente(ctx, fonte: 'resposta_vazia');
      }

      return FiscalAiInsight.fromJson(resp.data as Map<String, dynamic>);

    } on TimeoutException {
      // Proteção 3: Edge demorou demais
      return _analisarLocalmente(ctx, fonte: 'timeout_edge');

    } catch (e) {
      // Proteção 4: qualquer erro de rede ou HTTP
      return _analisarLocalmente(ctx, fonte: 'erro_edge');
    }
  }

  // Filtra contexto antes de enviar — evita payload gigante
  Map<String, dynamic> _montarPayload(FiscalContexto ctx) {
    return {
      'fiscal_id': ctx.fiscalId,
      'eventos': ctx.eventos
          .where((e) => e.status == 'aberto')
          .take(15)
          .map((e) => {
                'id': e.id,
                'tipo': e.tipo,
                'resumo': e.texto?.substring(0, min(200, e.texto?.length ?? 0)),
                'critico': e.critico,
              })
          .toList(),
    };
  }

  // Fallback local no Flutter — sem nenhuma chamada de rede
  FiscalAiInsight _analisarLocalmente(
    FiscalContexto ctx, {
    required String fonte,
  }) {
    final pendencias = ctx.eventos.where((e) => e.status == 'aberto').toList();
    final criticos = pendencias.where((e) => e.critico == true).toList();

    return FiscalAiInsight(
      resumo: '${pendencias.length} pendência(s) aberta(s), '
          '${criticos.length} crítica(s).',
      insights: criticos
          .take(3)
          .map((e) => FiscalInsight(
                tipo: 'alerta',
                titulo: e.tipo ?? 'Evento pendente',
                descricao: 'Pendente: ${e.id}',
              ))
          .toList(),
      acoesSupgeridas: [],
      fonte: fonte,
      analisadoEm: DateTime.now(),
    );
  }

  Future<bool> _temConexao() async {
    try {
      // Tenta um ping leve no Supabase
      await _supabase.from('fiscal_events').select('id').limit(1)
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }
}
```

---

## 10. Passo 8 — Flutter: modelo FiscalAiInsight com campo fonte

Arquivo: `lib/models/fiscal_ai_insight.dart`

```dart
class FiscalAiInsight {
  final String resumo;
  final List<FiscalInsight> insights;
  final List<Map<String, dynamic>> acoesSupgeridas;
  final String fonte; // ia_completa | ia_mini | ia_gemini | ia_gemini_lite | local_offline | sem_conexao | timeout_edge | erro_edge
  final DateTime analisadoEm;

  const FiscalAiInsight({
    required this.resumo,
    required this.insights,
    required this.acoesSupgeridas,
    required this.fonte,
    required this.analisadoEm,
  });

  factory FiscalAiInsight.fromJson(Map<String, dynamic> json) {
    return FiscalAiInsight(
      resumo:           json['resumo'] as String? ?? '',
      insights:         (json['insights'] as List? ?? [])
                          .map((i) => FiscalInsight.fromJson(i))
                          .toList(),
      acoesSupgeridas:  (json['acoes_sugeridas'] as List? ?? [])
                          .cast<Map<String, dynamic>>(),
      fonte:            json['fonte'] as String? ?? 'desconhecido',
      analisadoEm:      DateTime.now(),
    );
  }

  // Helpers de UX
  bool get isIaExterna =>
      fonte == 'ia_completa' || fonte == 'ia_mini' ||
      fonte == 'ia_gemini'   || fonte == 'ia_gemini_lite';

  bool get isLocal =>
      fonte == 'local_offline' || fonte == 'sem_conexao' ||
      fonte == 'timeout_edge'  || fonte == 'erro_edge';

  bool get iaDegradada => fonte == 'ia_mini' || fonte == 'ia_gemini_lite';
}

class FiscalInsight {
  final String tipo;
  final String titulo;
  final String descricao;

  const FiscalInsight({
    required this.tipo,
    required this.titulo,
    required this.descricao,
  });

  factory FiscalInsight.fromJson(Map<String, dynamic> json) {
    return FiscalInsight(
      tipo:      json['tipo']      as String? ?? '',
      titulo:    json['titulo']    as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
    );
  }
}
```

---

## 11. Passo 9 — Flutter: widget de status da IA

Arquivo: `lib/widgets/fiscal_ai_status_badge.dart`

```dart
import 'package:flutter/material.dart';
import '../models/fiscal_ai_insight.dart';

class FiscalAiStatusBadge extends StatelessWidget {
  final FiscalAiInsight insight;
  final VoidCallback? onTentarNovamente;

  const FiscalAiStatusBadge({
    super.key,
    required this.insight,
    this.onTentarNovamente,
  });

  @override
  Widget build(BuildContext context) {
    final config = _configParaFonte(insight.fonte);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: config.cor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: config.cor.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(config.icone, size: 12, color: config.cor),
              const SizedBox(width: 5),
              Text(
                config.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: config.cor,
                ),
              ),
            ],
          ),
        ),
        if (insight.isLocal && onTentarNovamente != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTentarNovamente,
            child: Text(
              'Tentar novamente',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }

  _BadgeConfig _configParaFonte(String fonte) {
    switch (fonte) {
      case 'ia_completa':
        return _BadgeConfig(Icons.check_circle_outline, Colors.green, 'IA completa');
      case 'ia_mini':
        return _BadgeConfig(Icons.info_outline, Colors.blue, 'IA resumida');
      case 'ia_gemini':
        return _BadgeConfig(Icons.auto_awesome_outlined, Colors.teal, 'Gemini');
      case 'ia_gemini_lite':
        return _BadgeConfig(Icons.auto_awesome_outlined, Colors.teal.shade300, 'Gemini Lite');
      case 'local_offline':
        return _BadgeConfig(Icons.cloud_off_outlined, Colors.orange, 'Modo local');
      case 'sem_conexao':
        return _BadgeConfig(Icons.wifi_off_outlined, Colors.red, 'Sem conexão');
      case 'timeout_edge':
      case 'erro_edge':
        return _BadgeConfig(Icons.warning_amber_outlined, Colors.orange, 'Modo local');
      default:
        return _BadgeConfig(Icons.help_outline, Colors.grey, fonte);
    }
  }
}

class _BadgeConfig {
  final IconData icone;
  final Color cor;
  final String label;
  const _BadgeConfig(this.icone, this.cor, this.label);
}
```

**Como usar na tela:**

```dart
FiscalAiStatusBadge(
  insight: _insight,
  onTentarNovamente: () => _carregarAnalise(forcaCompleta: true),
),
```

---

## 12. Passo 10 — Corrigir fiscal_id nos eventos criados pela IA

Arquivo: `supabase/functions/fiscal-ai-agent/index.ts`

Localize a ferramenta `create_followup_event` e adicione o `fiscal_id`:

```typescript
// ANTES (com bug — fiscal_id ausente)
const { error } = await supabase
  .from('fiscal_events')
  .insert({
    type:    args.type,
    message: args.message,
    // fiscal_id FALTANDO — bug!
  })

// DEPOIS (corrigido)
const { error } = await supabase
  .from('fiscal_events')
  .insert({
    type:      args.type,
    message:   args.message,
    fiscal_id: ctx.fiscal_id, // sempre incluir o fiscal_id do contexto atual
    created_by: 'fiscal_ai',
    created_at: new Date().toISOString(),
  })
```

---

## 13. Passo 11 — Structured Outputs: schema JSON

### Schema para OpenAI (`json_schema`)

```typescript
const FISCAL_SCHEMA = {
  name: 'fiscal_ai_response',
  strict: true,
  schema: {
    type: 'object',
    properties: {
      resumo: { type: 'string' },
      insights: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            tipo:      { type: 'string', enum: ['alerta', 'info', 'sugestao'] },
            titulo:    { type: 'string' },
            descricao: { type: 'string' },
            evento_id: { type: 'string' },
          },
          required: ['tipo', 'titulo', 'descricao'],
          additionalProperties: false,
        },
      },
      acoes_sugeridas: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            acao:      { type: 'string' },
            label:     { type: 'string' },
            fiscal_id: { type: 'string' },
          },
          required: ['acao', 'label', 'fiscal_id'],
          additionalProperties: false,
        },
      },
    },
    required: ['resumo', 'insights', 'acoes_sugeridas'],
    additionalProperties: false,
  },
}
```

### Schema para Gemini (`responseSchema`)

```typescript
const FISCAL_SCHEMA_GEMINI = {
  type: 'OBJECT',
  properties: {
    resumo: { type: 'STRING' },
    insights: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          tipo:      { type: 'STRING' },
          titulo:    { type: 'STRING' },
          descricao: { type: 'STRING' },
          evento_id: { type: 'STRING' },
        },
        required: ['tipo', 'titulo', 'descricao'],
      },
    },
    acoes_sugeridas: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          acao:      { type: 'STRING' },
          label:     { type: 'STRING' },
          fiscal_id: { type: 'STRING' },
        },
        required: ['acao', 'label', 'fiscal_id'],
      },
    },
  },
  required: ['resumo', 'insights', 'acoes_sugeridas'],
}
```

> **Atenção:** O Gemini usa tipos em MAIÚSCULO (`STRING`, `OBJECT`, `ARRAY`). O OpenAI usa minúsculo (`string`, `object`, `array`). São schemas diferentes mesmo que a estrutura seja igual.

---

## 14. Passo 12 — Deploy e validação

### Deploy da Edge Function

```bash
# Deploy da função atualizada
supabase functions deploy fiscal-ai-agent

# Verificar se os secrets estão aplicados
supabase secrets list
```

### Checklist de validação

- [ ] Secrets `OPENAI_API_KEY` e `GEMINI_API_KEY` configurados
- [ ] Edge Function deployada sem erros
- [ ] Testar chamada com contexto grande — deve usar `gpt-4o-mini` ou Gemini automaticamente
- [ ] Testar com `OPENAI_API_KEY` inválida — deve usar Gemini
- [ ] Testar com ambas as chaves inválidas — deve retornar `local_offline`
- [ ] Testar Flutter sem internet — deve retornar `sem_conexao` com análise local
- [ ] Verificar que `fiscal_id` aparece nos eventos criados pela IA no Supabase
- [ ] Verificar badge de status na tela IA Fiscal

### Teste rápido da Edge Function via curl

```bash
curl -X POST \
  'https://SEU_PROJETO.supabase.co/functions/v1/fiscal-ai-agent' \
  -H 'Authorization: Bearer SEU_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "fiscal_id": "test-123",
    "eventos": [
      { "id": "e1", "tipo": "atraso", "status": "aberto", "critico": true, "texto": "Colaborador não chegou" }
    ]
  }'
```

A resposta deve sempre conter `{ "fonte": "...", "resumo": "...", "insights": [...] }`.

---

## 15. Resumo dos secrets necessários

| Secret | Obrigatório | Descrição |
|---|---|---|
| `OPENAI_API_KEY` | Sim | Chave OpenAI |
| `OPENAI_AGENT_MODEL` | Sim | `gpt-4o` |
| `OPENAI_MINI_MODEL` | Sim | `gpt-4o-mini` |
| `OPENAI_VISION_MODEL` | Sim | `gpt-4o` (análise de cupons) |
| `OPENAI_TRANSCRIBE_MODEL` | Sim | `whisper-1` |
| `GEMINI_API_KEY` | Sim | Chave Gemini (gratuita) |
| `GEMINI_MODEL` | Sim | `gemini-2.0-flash` |
| `GEMINI_LITE_MODEL` | Sim | `gemini-2.0-flash-lite` |
| `OPENAI_MODEL` | Remover | Substituído pelos específicos acima |

---

## 16. Tabela de fontes e UX

| Campo `fonte` | Origem | Badge Flutter | Ação disponível |
|---|---|---|---|
| `ia_completa` | GPT-4o | Nenhum (padrão) | — |
| `ia_mini` | GPT-4o-mini | 🔵 "IA resumida" | "Tentar com IA completa" |
| `ia_gemini` | Gemini 2.0 Flash | 🟢 "Gemini" | — |
| `ia_gemini_lite` | Gemini Flash-Lite | 🟢 "Gemini Lite" | "Tentar novamente" |
| `local_offline` | Edge local | 🟡 "Modo local" | "Tentar novamente" |
| `sem_conexao` | Flutter local | 🔴 "Sem conexão" | "Tentar novamente" |
| `timeout_edge` | Flutter local | 🟡 "Modo local" | "Tentar novamente" |
| `erro_edge` | Flutter local | 🟡 "Modo local" | "Tentar novamente" |

---

*Documento gerado para o projeto Fiscal AI — Supabase Edge Functions + Flutter*
