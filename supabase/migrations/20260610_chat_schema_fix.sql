-- Migración: arregla chat_messages para que coincida con el código Flutter
-- Ejecutar en Supabase Dashboard → SQL Editor

-- 1. Renombrar message_type → type (Flutter usa 'type')
ALTER TABLE chat_messages RENAME COLUMN message_type TO type;

-- 2. Cambiar el CHECK para incluir los tipos de negociación
ALTER TABLE chat_messages DROP CONSTRAINT IF EXISTS chat_messages_message_type_check;
ALTER TABLE chat_messages ADD CONSTRAINT chat_messages_type_check
  CHECK (type IN ('text', 'image', 'system', 'offer', 'counter_offer', 'offer_accepted', 'offer_rejected'));

-- 3. Agregar columna is_read (Flutter la inserta y la lee)
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS is_read BOOLEAN NOT NULL DEFAULT FALSE;

-- 4. Habilitar Realtime para la tabla (necesario para .stream() de Supabase Flutter)
-- Si ya existe la publicación "supabase_realtime", solo agregar la tabla
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
  END IF;
END $$;
