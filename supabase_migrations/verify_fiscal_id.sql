-- Verificar se a coluna fiscal_id existe na tabela alocacoes
-- Se não existir, precisa ser adicionada

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'alocacoes'
AND column_name = 'fiscal_id';

-- Se o resultado estiver vazio, execute o comando abaixo:
-- (remova o comentário -- se necessário)

-- ALTER TABLE alocacoes
-- ADD COLUMN fiscal_id UUID NOT NULL REFERENCES fiscais(id) ON DELETE CASCADE;

-- Criar índice para fiscal_id
-- CREATE INDEX IF NOT EXISTS idx_alocacoes_fiscal_id ON alocacoes(fiscal_id);
