-- Adiciona suporte opcional de foto/arquivo para notas e ocorrencias.
-- Execute no SQL Editor do Supabase.

-- 1) Colunas opcionais em notas
ALTER TABLE public.notas
  ADD COLUMN IF NOT EXISTS foto_url TEXT,
  ADD COLUMN IF NOT EXISTS foto_nome TEXT,
  ADD COLUMN IF NOT EXISTS arquivo_url TEXT,
  ADD COLUMN IF NOT EXISTS arquivo_nome TEXT;

-- 2) Colunas opcionais em ocorrencias (se a tabela existir)
ALTER TABLE IF EXISTS public.ocorrencias
  ADD COLUMN IF NOT EXISTS foto_url TEXT,
  ADD COLUMN IF NOT EXISTS foto_nome TEXT,
  ADD COLUMN IF NOT EXISTS arquivo_url TEXT,
  ADD COLUMN IF NOT EXISTS arquivo_nome TEXT;

-- 3) Bucket para anexos (publico para leitura via URL)
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('anexos', 'anexos', true, 10485760)
ON CONFLICT (id) DO NOTHING;

-- 4) Politicas para upload/update/delete de anexos pelo proprio fiscal
DO $$
BEGIN
  CREATE POLICY "anexos_insert_own_folder"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'anexos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE POLICY "anexos_update_own_folder"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'anexos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'anexos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE POLICY "anexos_delete_own_folder"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'anexos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
