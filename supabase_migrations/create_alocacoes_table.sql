-- Script completo para criar a tabela alocacoes no Supabase
-- Use este script apenas se a tabela não existir ou precisar ser recriada

-- Criar tabela alocacoes
CREATE TABLE IF NOT EXISTS alocacoes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  fiscal_id UUID NOT NULL REFERENCES fiscais(id) ON DELETE CASCADE,
  colaborador_id UUID NOT NULL REFERENCES colaboradores(id) ON DELETE CASCADE,
  caixa_id UUID NOT NULL REFERENCES caixas(id) ON DELETE CASCADE,
  turno_escala_id UUID REFERENCES turnos_escala(id) ON DELETE SET NULL,

  -- Timestamps da alocação
  alocado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  liberado_em TIMESTAMPTZ,

  -- Informações adicionais
  motivo_liberacao TEXT,
  alocado_por UUID REFERENCES auth.users(id),
  observacoes TEXT,

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Constraints
  CONSTRAINT alocacao_periodo_valido CHECK (
    liberado_em IS NULL OR liberado_em >= alocado_em
  )
);

-- Criar índices para otimização
CREATE INDEX IF NOT EXISTS idx_alocacoes_fiscal_id ON alocacoes(fiscal_id);
CREATE INDEX IF NOT EXISTS idx_alocacoes_colaborador_id ON alocacoes(colaborador_id);
CREATE INDEX IF NOT EXISTS idx_alocacoes_caixa_id ON alocacoes(caixa_id);
CREATE INDEX IF NOT EXISTS idx_alocacoes_alocado_em ON alocacoes(alocado_em DESC);

-- Índice para alocações ativas (liberado_em IS NULL)
CREATE INDEX IF NOT EXISTS idx_alocacoes_ativas
ON alocacoes(fiscal_id, colaborador_id, caixa_id)
WHERE liberado_em IS NULL;

-- Comentários nas colunas
COMMENT ON TABLE alocacoes IS 'Registro de alocações de colaboradores em caixas';
COMMENT ON COLUMN alocacoes.fiscal_id IS 'ID do fiscal responsável';
COMMENT ON COLUMN alocacoes.colaborador_id IS 'ID do colaborador alocado';
COMMENT ON COLUMN alocacoes.caixa_id IS 'ID do caixa onde foi alocado';
COMMENT ON COLUMN alocacoes.alocado_em IS 'Data/hora que o colaborador foi alocado no caixa';
COMMENT ON COLUMN alocacoes.liberado_em IS 'Data/hora que o colaborador foi liberado do caixa (NULL = ainda ativo)';
COMMENT ON COLUMN alocacoes.motivo_liberacao IS 'Motivo da liberação (intervalo, troca, fim turno, etc)';

-- Habilitar Row Level Security (RLS)
ALTER TABLE alocacoes ENABLE ROW LEVEL SECURITY;

-- Políticas de acesso
-- Fiscal pode ver e gerenciar suas próprias alocações
CREATE POLICY "Fiscais podem ver suas alocações"
  ON alocacoes FOR SELECT
  USING (fiscal_id = auth.uid());

CREATE POLICY "Fiscais podem criar alocações"
  ON alocacoes FOR INSERT
  WITH CHECK (fiscal_id = auth.uid());

CREATE POLICY "Fiscais podem atualizar suas alocações"
  ON alocacoes FOR UPDATE
  USING (fiscal_id = auth.uid());

CREATE POLICY "Fiscais podem deletar suas alocações"
  ON alocacoes FOR DELETE
  USING (fiscal_id = auth.uid());

-- Habilitar Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE alocacoes;

-- Verificar se tudo foi criado corretamente
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'alocacoes'
ORDER BY ordinal_position;
