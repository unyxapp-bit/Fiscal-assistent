-- ============================================================
-- Historico/auditoria da calculadora de desconto
-- Execute no SQL Editor do Supabase
-- ============================================================

CREATE TABLE IF NOT EXISTS public.desconto_calculos (
  id                            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fiscal_id                     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  modo                          TEXT NOT NULL DEFAULT 'comparacao',
  produto_codigo                TEXT NOT NULL DEFAULT '',
  produto_nome                  TEXT NOT NULL DEFAULT '',
  etiqueta_centavos             INTEGER NOT NULL DEFAULT 0,
  sistema_centavos              INTEGER NOT NULL DEFAULT 0,
  percentual                    NUMERIC(8,4),
  quantidade                    INTEGER NOT NULL DEFAULT 1,
  leve                          INTEGER,
  pague                         INTEGER,
  desconto_unitario_centavos    INTEGER NOT NULL DEFAULT 0,
  desconto_total_centavos       INTEGER NOT NULL DEFAULT 0,
  valor_final_total_centavos    INTEGER NOT NULL DEFAULT 0,
  mensagem_copiada              TEXT NOT NULL DEFAULT '',
  created_at                    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.desconto_calculos
  ADD COLUMN IF NOT EXISTS fiscal_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS modo TEXT NOT NULL DEFAULT 'comparacao',
  ADD COLUMN IF NOT EXISTS produto_codigo TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS produto_nome TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS etiqueta_centavos INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS sistema_centavos INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS percentual NUMERIC(8,4),
  ADD COLUMN IF NOT EXISTS quantidade INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS leve INTEGER,
  ADD COLUMN IF NOT EXISTS pague INTEGER,
  ADD COLUMN IF NOT EXISTS desconto_unitario_centavos INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS desconto_total_centavos INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS valor_final_total_centavos INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS mensagem_copiada TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS idx_desconto_calculos_fiscal_created_at
  ON public.desconto_calculos (fiscal_id, created_at DESC);

ALTER TABLE public.desconto_calculos ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'desconto_calculos'
      AND policyname = 'desconto_calculos_owner_all'
  ) THEN
    CREATE POLICY "desconto_calculos_owner_all"
      ON public.desconto_calculos
      FOR ALL
      USING (fiscal_id = auth.uid())
      WITH CHECK (fiscal_id = auth.uid());
  END IF;
END$$;
