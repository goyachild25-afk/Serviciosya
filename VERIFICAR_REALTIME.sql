-- ============================================================
-- VERIFICAR Y ARREGLAR REALTIME PARA TABLA BOOKINGS
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- ============================================================

-- 1. VERIFICAR que Realtime está habilitado en la publicación
SELECT * FROM pg_publication_tables
WHERE pubname = 'supabase_realtime';

-- 2. VERIFICAR que bookings está en la publicación
-- (debería aparecer en el resultado anterior)

-- 3. VERIFICAR las políticas RLS
SELECT * FROM pg_policies
WHERE tablename = 'bookings'
ORDER BY policyname;

-- 4. HABILITAR RLS si no está
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- 5. CREAR políticas RLS CORRECTAS
-- (Estas permiten a cualquier usuario autenticado ver solicitudes pending)

DROP POLICY IF EXISTS "authenticated_read_pending" ON bookings;
CREATE POLICY "authenticated_read_pending" ON bookings
  FOR SELECT TO authenticated
  USING (
    status = 'pending' AND (
      provider_id IS NULL OR
      provider_id = (SELECT id FROM provider_profiles WHERE user_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "client_read_own_bookings" ON bookings;
CREATE POLICY "client_read_own_bookings" ON bookings
  FOR SELECT TO authenticated
  USING (client_id = auth.uid());

DROP POLICY IF EXISTS "provider_accept_booking" ON bookings;
CREATE POLICY "provider_accept_booking" ON bookings
  FOR UPDATE TO authenticated
  USING (
    provider_id IS NULL AND
    status = 'pending' AND
    EXISTS (SELECT 1 FROM provider_profiles WHERE user_id = auth.uid())
  )
  WITH CHECK (
    provider_id = (SELECT id FROM provider_profiles WHERE user_id = auth.uid())
  );

DROP POLICY IF EXISTS "provider_update_own_bookings" ON bookings;
CREATE POLICY "provider_update_own_bookings" ON bookings
  FOR UPDATE TO authenticated
  USING (provider_id = (SELECT id FROM provider_profiles WHERE user_id = auth.uid()))
  WITH CHECK (provider_id = (SELECT id FROM provider_profiles WHERE user_id = auth.uid()));

-- 6. VERIFICAR que la tabla está en la publicación supabase_realtime
-- Si NO aparece, ejecutar:
-- ALTER PUBLICATION supabase_realtime ADD TABLE bookings;

-- 7. VERIFICAR que REPLICA IDENTITY está configurado para Realtime
ALTER TABLE bookings REPLICA IDENTITY FULL;

-- 8. VERIFICAR el resultado
SELECT
  schemaname,
  tablename,
  (SELECT rolname FROM pg_roles WHERE oid = relowner) as owner
FROM pg_tables
WHERE tablename = 'bookings';

SELECT policyname, cmd, QUAL, WITH_CHECK
FROM pg_policies
WHERE tablename = 'bookings';
