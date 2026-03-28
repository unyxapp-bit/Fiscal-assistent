-- ============================================================
-- GUIA RAPIDO
-- ============================================================

CREATE TABLE IF NOT EXISTS public.guia_rapido (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fiscal_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  titulo     TEXT NOT NULL DEFAULT '',
  categoria  TEXT NOT NULL DEFAULT '',
  cor_hex    TEXT NOT NULL DEFAULT '607D8B',
  icone_key  TEXT NOT NULL DEFAULT 'outro',
  passos     JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS guia_rapido_fiscal_categoria_titulo_idx
  ON public.guia_rapido (fiscal_id, categoria, titulo);

ALTER TABLE public.guia_rapido ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "fiscal_rls_guia_rapido" ON public.guia_rapido
    USING (fiscal_id = auth.uid())
    WITH CHECK (fiscal_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
