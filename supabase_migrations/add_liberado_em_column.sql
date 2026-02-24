-- Adiciona coluna liberado_em na tabela alocacoes
-- Execute este script no SQL Editor do Supabase

ALTER TABLE alocacoes
ADD COLUMN IF NOT EXISTS liberado_em TIMESTAMPTZ;

-- Adiciona comentário na coluna
COMMENT ON COLUMN alocacoes.liberado_em IS 'Data e hora em que a alocação foi liberada (colaborador saiu do caixa)';

-- Criar índice para otimizar queries de alocações ativas
CREATE INDEX IF NOT EXISTS idx_alocacoes_liberado_em
ON alocacoes(liberado_em)
WHERE liberado_em IS NULL;

-- Verificar se a coluna foi criada
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'alocacoes'
AND column_name = 'liberado_em';
