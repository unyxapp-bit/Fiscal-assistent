-- ============================================================
-- CISS Fiscal Assistant — Patch de Adaptação do Schema Real
-- Execute no SQL Editor do Supabase Dashboard.
-- Adiciona colunas faltando às tabelas existentes.
-- ============================================================

-- ============================================================
-- 1. ALOCACOES: adicionar colunas que o app usa
-- ============================================================
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS fiscal_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS caixa_id TEXT;
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS turno_escala_id TEXT;
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS alocado_em TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS horario_inicio TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS data_alocacao DATE DEFAULT CURRENT_DATE;
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS liberado_em TIMESTAMPTZ;
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS horario_fim TIMESTAMPTZ;
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS motivo_liberacao TEXT;
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS alocado_por TEXT;
ALTER TABLE public.alocacoes ADD COLUMN IF NOT EXISTS observacoes TEXT;

-- RLS para alocacoes
-- Recria a policy para incluir suporte a linhas antigas (fiscal_id IS NULL)
ALTER TABLE public.alocacoes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "fiscal_rls_alocacoes" ON public.alocacoes;
CREATE POLICY "fiscal_rls_alocacoes" ON public.alocacoes
  USING (fiscal_id = auth.uid() OR fiscal_id IS NULL)
  WITH CHECK (fiscal_id = auth.uid() OR fiscal_id IS NULL);

-- ============================================================
-- 2. CAIXAS: adicionar em_manutencao
-- ============================================================
ALTER TABLE public.caixas ADD COLUMN IF NOT EXISTS em_manutencao BOOLEAN NOT NULL DEFAULT FALSE;

-- ============================================================
-- 3. COLABORADORES: adicionar avatar_iniciais
-- ============================================================
ALTER TABLE public.colaboradores ADD COLUMN IF NOT EXISTS avatar_iniciais TEXT;

-- ============================================================
-- 4. TURNOS_ESCALA: adicionar fiscal_id para RLS
-- ============================================================
ALTER TABLE public.turnos_escala ADD COLUMN IF NOT EXISTS fiscal_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.turnos_escala ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "fiscal_rls_turnos" ON public.turnos_escala;
CREATE POLICY "fiscal_rls_turnos" ON public.turnos_escala
  USING (fiscal_id = auth.uid() OR fiscal_id IS NULL)
  WITH CHECK (fiscal_id = auth.uid() OR fiscal_id IS NULL);

-- ============================================================
-- 5. NOTAS: garantir lembrete_ativo
-- ============================================================
ALTER TABLE public.notas ADD COLUMN IF NOT EXISTS lembrete_ativo BOOLEAN NOT NULL DEFAULT TRUE;

-- ============================================================
-- FIM DO PATCH
-- ============================================================
