-- Tabla para tokens FCM de push notifications
-- Ejecutar en Supabase Dashboard → SQL Editor

CREATE TABLE IF NOT EXISTS device_tokens (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  token       TEXT NOT NULL,
  platform    TEXT NOT NULL DEFAULT 'android', -- 'web', 'android', 'ios'
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, token)
);

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- Solo el propio usuario puede ver/gestionar sus tokens
CREATE POLICY "users_own_tokens" ON device_tokens
  FOR ALL USING (auth.uid() = user_id);

-- El service role puede leer todos los tokens (para enviar notificaciones)
CREATE POLICY "service_can_read_tokens" ON device_tokens
  FOR SELECT USING (true);

-- Índice para buscar tokens por usuario
CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON device_tokens(user_id);
