-- Script para verificar o schema atual da tabela alocacoes
-- Execute este SQL no Supabase e me mostre o resultado

SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'alocacoes'
ORDER BY ordinal_position;
