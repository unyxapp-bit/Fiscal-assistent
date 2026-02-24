# Migrations do Supabase

## Problema: Coluna `liberado_em` não existe

O erro ocorre porque a tabela `alocacoes` no Supabase não possui a coluna `liberado_em`, que é necessária para rastrear quando uma alocação foi liberada (quando o colaborador saiu do caixa).

## Como resolver

### Passo 1: Acessar o Supabase Dashboard

1. Acesse [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Selecione seu projeto
3. No menu lateral, clique em **SQL Editor**

### Passo 2: Executar a Migration

1. Clique em **New Query**
2. Copie todo o conteúdo do arquivo `add_liberado_em_column.sql`
3. Cole no editor SQL
4. Clique em **Run** (ou pressione Ctrl+Enter)
5. Verifique se a mensagem de sucesso aparece

### Passo 3: Verificar a Tabela

Após executar a migration, você pode verificar se a coluna foi criada executando:

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'alocacoes'
ORDER BY ordinal_position;
```

Você deve ver a coluna `liberado_em` do tipo `timestamp with time zone` na lista.

### Passo 4: Testar o App

Após executar a migration:
1. Reinicie o app Flutter
2. Tente fazer uma nova alocação
3. O erro não deve mais aparecer

## Schema Completo da Tabela `alocacoes`

A tabela `alocacoes` deve ter as seguintes colunas:

- `id` (uuid, PK)
- `colaborador_id` (uuid, FK -> colaboradores)
- `caixa_id` (uuid, FK -> caixas)
- `turno_escala_id` (uuid, nullable, FK -> turnos_escala)
- `alocado_em` (timestamptz)
- `liberado_em` (timestamptz, nullable) ← **Esta coluna estava faltando**
- `motivo_liberacao` (text, nullable)
- `alocado_por` (uuid, nullable)
- `observacoes` (text, nullable)
- `created_at` (timestamptz)
- `fiscal_id` (uuid, FK -> fiscais)

## Troubleshooting

### Erro: "permission denied"

Se você receber um erro de permissão, certifique-se de que está logado como o owner do projeto no Supabase.

### Erro: "relation alocacoes does not exist"

Se a tabela `alocacoes` não existir, você precisa criar a tabela completa primeiro. Entre em contato para obter o script de criação completo.
