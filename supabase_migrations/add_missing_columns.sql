-- Migration para adicionar colunas faltantes na tabela alocacoes
-- Mantém as colunas existentes e adiciona as novas necessárias

-- Adicionar colunas que faltam
ALTER TABLE alocacoes
ADD COLUMN IF NOT EXISTS alocado_em TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS motivo_liberacao TEXT,
ADD COLUMN IF NOT EXISTS alocado_por UUID,
ADD COLUMN IF NOT EXISTS turno_escala_id UUID;

-- Preencher alocado_em com base em horario_inicio para registros existentes
UPDATE alocacoes
SET alocado_em = horario_inicio
WHERE alocado_em IS NULL;

-- Preencher liberado_em com base em horario_fim para registros existentes
UPDATE alocacoes
SET liberado_em = horario_fim
WHERE liberado_em IS NULL AND horario_fim IS NOT NULL;

-- Tornar alocado_em obrigatório
ALTER TABLE alocacoes
ALTER COLUMN alocado_em SET NOT NULL;

-- Adicionar foreign key para turno_escala_id (se a tabela existir)
-- ALTER TABLE alocacoes
-- ADD CONSTRAINT fk_turno_escala
-- FOREIGN KEY (turno_escala_id) REFERENCES turnos_escala(id) ON DELETE SET NULL;

-- Verificar resultado
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'alocacoes'
ORDER BY ordinal_position;
