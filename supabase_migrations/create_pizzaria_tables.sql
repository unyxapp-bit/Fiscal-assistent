-- ============================================================
-- MÓDULO PIZZA — Fiscal Assistant
-- Execute no SQL Editor do Supabase
-- ============================================================

-- ENUMS
CREATE TYPE tamanho_pizza  AS ENUM ('grande', 'media');
CREATE TYPE status_pedido  AS ENUM ('aberto', 'pronto', 'entregue');

-- ------------------------------------------------------------
-- TABELA: pizzas
-- ------------------------------------------------------------
CREATE TABLE pizzas (
  id         uuid            PRIMARY KEY DEFAULT gen_random_uuid(),
  nome       text            NOT NULL,
  tamanho    tamanho_pizza   NOT NULL,
  ingredientes text,
  ativa      boolean         NOT NULL DEFAULT true,
  created_at timestamptz     DEFAULT now()
);

-- ------------------------------------------------------------
-- TABELA: pedidos_pizza
-- ------------------------------------------------------------
CREATE TABLE pedidos_pizza (
  id              uuid           PRIMARY KEY DEFAULT gen_random_uuid(),
  nome_cliente    text           NOT NULL,
  codigo_entrega  text           NOT NULL,
  data_pedido     date           NOT NULL DEFAULT CURRENT_DATE,
  horario_pedido  time           NOT NULL DEFAULT CURRENT_TIME,
  observacoes     text,
  status          status_pedido  NOT NULL DEFAULT 'aberto',
  created_at      timestamptz    DEFAULT now()
);

-- ------------------------------------------------------------
-- TABELA: itens_pedido
-- ------------------------------------------------------------
CREATE TABLE itens_pedido (
  id             uuid     PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id      uuid     NOT NULL REFERENCES pedidos_pizza(id) ON DELETE CASCADE,
  pizza_id       uuid     NOT NULL REFERENCES pizzas(id),
  pizza2_id      uuid     REFERENCES pizzas(id),   -- metade 2 (meio a meio)
  quantidade     int      NOT NULL DEFAULT 1,
  eh_meio_a_meio boolean  NOT NULL DEFAULT false,
  created_at     timestamptz DEFAULT now()
);

-- ------------------------------------------------------------
-- RLS
-- ------------------------------------------------------------
ALTER TABLE pizzas        ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos_pizza ENABLE ROW LEVEL SECURITY;
ALTER TABLE itens_pedido  ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pizza_auth_all"   ON pizzas        FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "pedido_auth_all"  ON pedidos_pizza FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "item_auth_all"    ON itens_pedido  FOR ALL USING (auth.role() = 'authenticated');

-- ------------------------------------------------------------
-- DADOS INICIAIS (opcional — ajuste os nomes)
-- ------------------------------------------------------------
INSERT INTO pizzas (nome, tamanho) VALUES
  ('Mussarela',        'grande'),
  ('Calabresa',        'grande'),
  ('Frango c/ Catupiry','grande'),
  ('Portuguesa',       'grande'),
  ('Margherita',       'grande'),
  ('Mussarela',        'media'),
  ('Calabresa',        'media'),
  ('Frango c/ Catupiry','media'),
  ('Portuguesa',       'media');
