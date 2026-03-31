-- Adiciona campos opcionais de cliente no modulo pizzaria
-- e remove obrigatoriedade de nome/codigo para permitir pedido sem cadastro completo.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'pedidos_pizza'
  ) THEN
    ALTER TABLE public.pedidos_pizza
      ALTER COLUMN nome_cliente DROP NOT NULL,
      ALTER COLUMN codigo_entrega DROP NOT NULL;

    ALTER TABLE public.pedidos_pizza
      ADD COLUMN IF NOT EXISTS endereco text,
      ADD COLUMN IF NOT EXISTS bairro text,
      ADD COLUMN IF NOT EXISTS telefone text,
      ADD COLUMN IF NOT EXISTS referencia text;
  END IF;
END $$;

