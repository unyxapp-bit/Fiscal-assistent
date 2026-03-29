-- Add field "ingredientes" to existing pizzas table
ALTER TABLE IF EXISTS pizzas
ADD COLUMN IF NOT EXISTS ingredientes text;
