-- Tabela de cartazes promocionais
-- Fase 3 — persistência e histórico de reimpressão

create table if not exists public.cartazes (
  id            uuid primary key default gen_random_uuid(),
  tipo          text not null
    check (tipo in ('proximoVencimento', 'aproveiteAgora', 'oferta')),
  tamanho       text not null
    check (tamanho in ('a6', 'a4', 'a3', 'a2')),
  titulo_linha_1 text not null,
  titulo_linha_2 text,
  subtitulo     text,
  detalhe       text,
  preco         numeric(10,2) not null,
  unidade       text,
  validade      text,
  png_path      text,
  pdf_path      text,
  created_at    timestamptz not null default now()
);

-- Índice para listar histórico do mais recente para o mais antigo
create index if not exists idx_cartazes_created_at
  on public.cartazes(created_at desc);
