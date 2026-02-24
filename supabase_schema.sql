-- ============================================================
-- CISS Fiscal Assistant — Supabase Schema (idempotent)
-- Pode ser executado múltiplas vezes sem erros.
-- Execute no SQL Editor do Supabase Dashboard.
-- ============================================================

-- Helper: cria policy apenas se não existir
-- (evita erro "policy already exists")

-- ============================================================
-- 0. ALOCACOES (tabela pré-existente — garante colunas + RLS)
-- fiscal_id usa DEFAULT auth.uid() para funcionar sem enviá-lo no INSERT.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.alocacoes (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fiscal_id         UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  colaborador_id    TEXT NOT NULL,
  caixa_id          TEXT NOT NULL,
  turno_escala_id   TEXT,
  alocado_em        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  horario_inicio    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  data_alocacao     DATE NOT NULL DEFAULT CURRENT_DATE,
  liberado_em       TIMESTAMPTZ,
  horario_fim       TIMESTAMPTZ,
  status            TEXT NOT NULL DEFAULT 'ativo',
  motivo_liberacao  TEXT,
  alocado_por       TEXT,
  observacoes       TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS fiscal_id UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS turno_escala_id TEXT;
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS alocado_em TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS data_alocacao DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS liberado_em TIMESTAMPTZ;
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS horario_fim TIMESTAMPTZ;
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS motivo_liberacao TEXT;
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS alocado_por TEXT;
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS observacoes TEXT;
ALTER TABLE public.alocacoes ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "fiscal_rls_alocacoes" ON public.alocacoes
    USING (fiscal_id = auth.uid()) WITH CHECK (fiscal_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- 1. ENTREGAS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.entregas (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fiscal_id            UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  numero_nota          TEXT NOT NULL DEFAULT '',
  cliente_nome         TEXT NOT NULL DEFAULT '',
  bairro               TEXT NOT NULL DEFAULT '',
  cidade               TEXT NOT NULL DEFAULT '',
  endereco             TEXT NOT NULL DEFAULT '',
  telefone             TEXT,
  status               TEXT NOT NULL DEFAULT 'separada',
  separado_em          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  horario_marcado      TIMESTAMPTZ,
  saiu_para_entrega_em TIMESTAMPTZ,
  entregue_em          TIMESTAMPTZ,
  observacoes          TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.entregas ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "fiscal_rls_entregas" ON public.entregas
    USING (fiscal_id = auth.uid()) WITH CHECK (fiscal_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- 2. NOTAS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notas (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fiscal_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  titulo         TEXT NOT NULL DEFAULT '',
  conteudo       TEXT NOT NULL DEFAULT '',
  tipo           TEXT NOT NULL DEFAULT 'anotacao',
  concluida      BOOLEAN NOT NULL DEFAULT FALSE,
  importante     BOOLEAN NOT NULL DEFAULT FALSE,
  lembrete_ativo BOOLEAN NOT NULL DEFAULT TRUE,
  data_lembrete  TIMESTAMPTZ,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.notas ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "fiscal_rls_notas" ON public.notas
    USING (fiscal_id = auth.uid()) WITH CHECK (fiscal_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- 3. FORMULARIOS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.formularios (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fiscal_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  seed_key    TEXT,
  titulo      TEXT NOT NULL DEFAULT '',
  descricao   TEXT NOT NULL DEFAULT '',
  template    BOOLEAN NOT NULL DEFAULT FALSE,
  ativo       BOOLEAN NOT NULL DEFAULT TRUE,
  campos      JSONB NOT NULL DEFAULT '[]',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- Adiciona colunas que podem estar faltando em tabelas pré-existentes
ALTER TABLE public.formularios ADD COLUMN IF NOT EXISTS seed_key TEXT;
ALTER TABLE public.formularios ADD COLUMN IF NOT EXISTS descricao TEXT NOT NULL DEFAULT '';
ALTER TABLE public.formularios ADD COLUMN IF NOT EXISTS template BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.formularios ADD COLUMN IF NOT EXISTS ativo BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.formularios ADD COLUMN IF NOT EXISTS campos JSONB NOT NULL DEFAULT '[]';

CREATE UNIQUE INDEX IF NOT EXISTS formularios_fiscal_seed
  ON public.formularios (fiscal_id, seed_key) WHERE seed_key IS NOT NULL;
ALTER TABLE public.formularios ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "fiscal_rls_formularios" ON public.formularios
    USING (fiscal_id = auth.uid()) WITH CHECK (fiscal_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- 4. RESPOSTAS FORMULÁRIO
-- ============================================================
CREATE TABLE IF NOT EXISTS public.respostas_formulario (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fiscal_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  formulario_id UUID NOT NULL REFERENCES public.formularios(id) ON DELETE CASCADE,
  valores       JSONB NOT NULL DEFAULT '{}',
  preenchido_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.respostas_formulario ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "fiscal_rls_respostas" ON public.respostas_formulario
    USING (fiscal_id = auth.uid()) WITH CHECK (fiscal_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- 5. SNAPSHOTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.snapshots (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fiscal_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  data_hora   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  finalizado  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.snapshots ADD COLUMN IF NOT EXISTS finalizado BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.snapshots ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "fiscal_rls_snapshots" ON public.snapshots
    USING (fiscal_id = auth.uid()) WITH CHECK (fiscal_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- 6. PRESENÇAS SNAPSHOT
-- ============================================================
CREATE TABLE IF NOT EXISTS public.presencas_snapshot (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  snapshot_id      UUID NOT NULL REFERENCES public.snapshots(id) ON DELETE CASCADE,
  fiscal_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  colaborador_id   TEXT NOT NULL,
  status           TEXT NOT NULL DEFAULT 'pendente',
  horario_esperado TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  confirmado_em    TIMESTAMPTZ,
  minutos_atraso   INTEGER,
  observacao       TEXT,
  substituido_por  TEXT
);
ALTER TABLE public.presencas_snapshot ADD COLUMN IF NOT EXISTS confirmado_em TIMESTAMPTZ;
ALTER TABLE public.presencas_snapshot ADD COLUMN IF NOT EXISTS minutos_atraso INTEGER;
ALTER TABLE public.presencas_snapshot ADD COLUMN IF NOT EXISTS observacao TEXT;
ALTER TABLE public.presencas_snapshot ADD COLUMN IF NOT EXISTS substituido_por TEXT;
ALTER TABLE public.presencas_snapshot ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "fiscal_rls_presencas" ON public.presencas_snapshot
    USING (fiscal_id = auth.uid()) WITH CHECK (fiscal_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- 7. PROCEDIMENTOS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.procedimentos (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fiscal_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  seed_key       TEXT,
  titulo         TEXT NOT NULL DEFAULT '',
  descricao      TEXT NOT NULL DEFAULT '',
  categoria      TEXT NOT NULL DEFAULT 'rotina',
  passos         JSONB NOT NULL DEFAULT '[]',
  favorito       BOOLEAN NOT NULL DEFAULT FALSE,
  tempo_estimado INTEGER,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.procedimentos ADD COLUMN IF NOT EXISTS seed_key TEXT;
ALTER TABLE public.procedimentos ADD COLUMN IF NOT EXISTS descricao TEXT NOT NULL DEFAULT '';
ALTER TABLE public.procedimentos ADD COLUMN IF NOT EXISTS categoria TEXT NOT NULL DEFAULT 'rotina';
ALTER TABLE public.procedimentos ADD COLUMN IF NOT EXISTS passos JSONB NOT NULL DEFAULT '[]';
ALTER TABLE public.procedimentos ADD COLUMN IF NOT EXISTS favorito BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.procedimentos ADD COLUMN IF NOT EXISTS tempo_estimado INTEGER;

CREATE UNIQUE INDEX IF NOT EXISTS procedimentos_fiscal_seed
  ON public.procedimentos (fiscal_id, seed_key) WHERE seed_key IS NOT NULL;
ALTER TABLE public.procedimentos ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "fiscal_rls_procedimentos" ON public.procedimentos
    USING (fiscal_id = auth.uid()) WITH CHECK (fiscal_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- 8. PAUSAS CAFÉ
-- ============================================================
CREATE TABLE IF NOT EXISTS public.pausas_cafe (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fiscal_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  colaborador_id   TEXT NOT NULL,
  colaborador_nome TEXT NOT NULL DEFAULT '',
  iniciado_em      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  duracao_minutos  INTEGER NOT NULL DEFAULT 15,
  finalizado_em    TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.pausas_cafe ADD COLUMN IF NOT EXISTS colaborador_nome TEXT NOT NULL DEFAULT '';
ALTER TABLE public.pausas_cafe ADD COLUMN IF NOT EXISTS duracao_minutos INTEGER NOT NULL DEFAULT 15;
ALTER TABLE public.pausas_cafe ADD COLUMN IF NOT EXISTS finalizado_em TIMESTAMPTZ;
ALTER TABLE public.pausas_cafe ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "fiscal_rls_pausas_cafe" ON public.pausas_cafe
    USING (fiscal_id = auth.uid()) WITH CHECK (fiscal_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- 9. TURNOS ESCALA
-- ============================================================
CREATE TABLE IF NOT EXISTS public.turnos_escala (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fiscal_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  colaborador_id   TEXT NOT NULL,
  colaborador_nome TEXT NOT NULL DEFAULT '',
  departamento     TEXT NOT NULL DEFAULT 'fiscal',
  data             DATE NOT NULL DEFAULT CURRENT_DATE,
  entrada          TEXT,
  intervalo        TEXT,
  retorno          TEXT,
  saida            TEXT,
  folga            BOOLEAN NOT NULL DEFAULT FALSE,
  feriado          BOOLEAN NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- Adiciona colunas que podem estar faltando em tabelas pré-existentes
ALTER TABLE public.turnos_escala ADD COLUMN IF NOT EXISTS colaborador_nome TEXT NOT NULL DEFAULT '';
ALTER TABLE public.turnos_escala ADD COLUMN IF NOT EXISTS departamento TEXT NOT NULL DEFAULT 'fiscal';
ALTER TABLE public.turnos_escala ADD COLUMN IF NOT EXISTS entrada TEXT;
ALTER TABLE public.turnos_escala ADD COLUMN IF NOT EXISTS intervalo TEXT;
ALTER TABLE public.turnos_escala ADD COLUMN IF NOT EXISTS retorno TEXT;
ALTER TABLE public.turnos_escala ADD COLUMN IF NOT EXISTS saida TEXT;
ALTER TABLE public.turnos_escala ADD COLUMN IF NOT EXISTS folga BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.turnos_escala ADD COLUMN IF NOT EXISTS feriado BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.turnos_escala ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
-- Constraint UNIQUE (idempotente via índice)
CREATE UNIQUE INDEX IF NOT EXISTS turnos_escala_fiscal_colab_data
  ON public.turnos_escala (fiscal_id, colaborador_id, data);
ALTER TABLE public.turnos_escala ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "fiscal_rls_turnos" ON public.turnos_escala
    USING (fiscal_id = auth.uid()) WITH CHECK (fiscal_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- 10. CAIXAS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.caixas (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fiscal_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  numero        INTEGER NOT NULL,
  tipo          TEXT NOT NULL DEFAULT 'normal',
  ativo         BOOLEAN NOT NULL DEFAULT TRUE,
  em_manutencao BOOLEAN NOT NULL DEFAULT FALSE,
  observacoes   TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.caixas ADD COLUMN IF NOT EXISTS tipo TEXT NOT NULL DEFAULT 'normal';
ALTER TABLE public.caixas ADD COLUMN IF NOT EXISTS em_manutencao BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.caixas ADD COLUMN IF NOT EXISTS observacoes TEXT;
ALTER TABLE public.caixas ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "fiscal_rls_caixas" ON public.caixas
    USING (fiscal_id = auth.uid()) WITH CHECK (fiscal_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- 11. COLABORADORES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.colaboradores (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fiscal_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nome          TEXT NOT NULL DEFAULT '',
  matricula     TEXT NOT NULL DEFAULT '',
  departamento  TEXT NOT NULL DEFAULT 'fiscal',
  cargo         TEXT NOT NULL DEFAULT '',
  ativo         BOOLEAN NOT NULL DEFAULT TRUE,
  foto_url      TEXT,
  telefone      TEXT,
  email         TEXT,
  observacoes   TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.colaboradores ADD COLUMN IF NOT EXISTS cargo TEXT NOT NULL DEFAULT '';
ALTER TABLE public.colaboradores ADD COLUMN IF NOT EXISTS foto_url TEXT;
ALTER TABLE public.colaboradores ADD COLUMN IF NOT EXISTS telefone TEXT;
ALTER TABLE public.colaboradores ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.colaboradores ADD COLUMN IF NOT EXISTS observacoes TEXT;
ALTER TABLE public.colaboradores ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "fiscal_rls_colaboradores" ON public.colaboradores
    USING (fiscal_id = auth.uid()) WITH CHECK (fiscal_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- 12. FISCAIS (perfis)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.fiscais (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nome        TEXT NOT NULL DEFAULT '',
  email       TEXT NOT NULL DEFAULT '',
  loja        TEXT,
  cargo       TEXT,
  telefone    TEXT,
  ativo       BOOLEAN NOT NULL DEFAULT TRUE,
  foto_url    TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.fiscais ADD COLUMN IF NOT EXISTS loja TEXT;
ALTER TABLE public.fiscais ADD COLUMN IF NOT EXISTS cargo TEXT;
ALTER TABLE public.fiscais ADD COLUMN IF NOT EXISTS telefone TEXT;
ALTER TABLE public.fiscais ADD COLUMN IF NOT EXISTS foto_url TEXT;
ALTER TABLE public.fiscais ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "fiscal_rls_fiscais" ON public.fiscais
    USING (id = auth.uid()) WITH CHECK (id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
