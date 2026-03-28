-- ============================================================
-- CHECKLIST: templates + execucoes
-- ============================================================

CREATE TABLE IF NOT EXISTS public.checklist_templates (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fiscal_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  titulo              TEXT NOT NULL DEFAULT '',
  descricao           TEXT NOT NULL DEFAULT '',
  icone_key           TEXT NOT NULL DEFAULT 'checklist',
  cor_hex             TEXT NOT NULL DEFAULT '4CAF50',
  itens               JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_default          BOOLEAN NOT NULL DEFAULT FALSE,
  periodizacao        TEXT NOT NULL DEFAULT 'qualquer_horario',
  horario_notificacao TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS checklist_templates_fiscal_created_idx
  ON public.checklist_templates (fiscal_id, created_at DESC);

ALTER TABLE public.checklist_templates ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "fiscal_rls_checklist_templates" ON public.checklist_templates
    USING (fiscal_id = auth.uid())
    WITH CHECK (fiscal_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS public.checklist_execucoes (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fiscal_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tipo           TEXT NOT NULL DEFAULT '',
  data           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  itens_marcados JSONB NOT NULL DEFAULT '{}'::jsonb,
  itens_snapshot JSONB NOT NULL DEFAULT '[]'::jsonb,
  concluido      BOOLEAN NOT NULL DEFAULT FALSE,
  concluido_em   TIMESTAMPTZ,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS checklist_execucoes_fiscal_data_idx
  ON public.checklist_execucoes (fiscal_id, data DESC);

CREATE INDEX IF NOT EXISTS checklist_execucoes_fiscal_tipo_idx
  ON public.checklist_execucoes (fiscal_id, tipo);

ALTER TABLE public.checklist_execucoes ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "fiscal_rls_checklist_execucoes" ON public.checklist_execucoes
    USING (fiscal_id = auth.uid())
    WITH CHECK (fiscal_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
