-- ============================================================
-- Tabela de configuracao profissional do cupom da pizzaria
-- Execute no SQL Editor do Supabase
-- ============================================================

CREATE TABLE IF NOT EXISTS public.cupom_configuracoes (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fiscal_id                   UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  titulo_cabecalho            TEXT NOT NULL DEFAULT 'PIZZARIA CARROSSEL',
  subtitulo_cabecalho         TEXT NOT NULL DEFAULT '',
  cnpj                        TEXT NOT NULL DEFAULT '',
  endereco_linha1             TEXT NOT NULL DEFAULT '',
  endereco_linha2             TEXT NOT NULL DEFAULT '',
  telefone                    TEXT NOT NULL DEFAULT '',
  whatsapp                    TEXT NOT NULL DEFAULT '',
  instagram                   TEXT NOT NULL DEFAULT '',
  website                     TEXT NOT NULL DEFAULT '',
  mensagem_topo               TEXT NOT NULL DEFAULT '',
  mensagem_final              TEXT NOT NULL DEFAULT 'BOM APETITE!',
  observacao_padrao           TEXT NOT NULL DEFAULT '',
  exibir_data_hora_emissao    BOOLEAN NOT NULL DEFAULT true,
  tamanho_fonte               NUMERIC(4,1) NOT NULL DEFAULT 12,
  centralizar_cabecalho       BOOLEAN NOT NULL DEFAULT true,
  centralizar_rodape          BOOLEAN NOT NULL DEFAULT true,
  texto_destaque              TEXT NOT NULL DEFAULT '',
  termo_destaque_item         TEXT NOT NULL DEFAULT '',
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.cupom_configuracoes
  ADD COLUMN IF NOT EXISTS fiscal_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS titulo_cabecalho TEXT NOT NULL DEFAULT 'PIZZARIA CARROSSEL',
  ADD COLUMN IF NOT EXISTS subtitulo_cabecalho TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS cnpj TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS endereco_linha1 TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS endereco_linha2 TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS telefone TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS whatsapp TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS instagram TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS website TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS mensagem_topo TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS mensagem_final TEXT NOT NULL DEFAULT 'BOM APETITE!',
  ADD COLUMN IF NOT EXISTS observacao_padrao TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS exibir_data_hora_emissao BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS tamanho_fonte NUMERIC(4,1) NOT NULL DEFAULT 12,
  ADD COLUMN IF NOT EXISTS centralizar_cabecalho BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS centralizar_rodape BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS texto_destaque TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS termo_destaque_item TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- Garante que fiscal_id tenha dono quando houver linhas antigas
UPDATE public.cupom_configuracoes
SET fiscal_id = auth.uid()
WHERE fiscal_id IS NULL
  AND auth.uid() IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_cupom_configuracoes_fiscal
  ON public.cupom_configuracoes (fiscal_id);

CREATE OR REPLACE FUNCTION public.set_cupom_configuracoes_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_cupom_configuracoes_updated_at ON public.cupom_configuracoes;
CREATE TRIGGER trg_cupom_configuracoes_updated_at
BEFORE UPDATE ON public.cupom_configuracoes
FOR EACH ROW
EXECUTE FUNCTION public.set_cupom_configuracoes_updated_at();

ALTER TABLE public.cupom_configuracoes ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'cupom_configuracoes'
      AND policyname = 'cupom_configuracoes_owner_all'
  ) THEN
    CREATE POLICY "cupom_configuracoes_owner_all"
      ON public.cupom_configuracoes
      FOR ALL
      USING (fiscal_id = auth.uid())
      WITH CHECK (fiscal_id = auth.uid());
  END IF;
END$$;
