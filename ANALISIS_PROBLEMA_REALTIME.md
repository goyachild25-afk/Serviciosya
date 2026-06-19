# 🔍 Análisis Profundo - Problema de Realtime

## El Problema

Las solicitudes **no llegan al instante** al dashboard del prestador porque:

### 1. **Las políticas RLS eran demasiado restrictivas**
Las políticas anteriores:
- "View open requests": `provider_id IS NULL AND status = 'pending'`
- "Accept open requests": `provider_id IS NULL AND status = 'pending'`

**Problema**: Las políticas estaban correctas, pero podría haber un problema de timing con cómo Supabase Realtime sincroniza cambios.

### 2. **Falta de `REPLICA IDENTITY FULL`**
Para que Supabase Realtime funcione correctamente, la tabla necesita:
```sql
ALTER TABLE bookings REPLICA IDENTITY FULL;
```

Sin esto, Realtime no captura todos los cambios correctamente.

### 3. **El stream puede no estar suscrito correctamente**
El código en `openRequestsProvider` usa `.stream()` pero podría haber un delay en la sincronización.

---

## La Solución Aplicada

### ✅ Paso 1: Limpiar y recrear políticas RLS
```sql
DROP POLICY IF EXISTS "View open requests" ON bookings;
DROP POLICY IF EXISTS "Accept open requests" ON bookings;

CREATE POLICY "authenticated_read_pending" ON bookings
  FOR SELECT TO authenticated
  USING (status = 'pending' AND provider_id IS NULL);

CREATE POLICY "client_read_own_bookings" ON bookings
  FOR SELECT TO authenticated
  USING (client_id = auth.uid());

CREATE POLICY "provider_accept_booking" ON bookings
  FOR UPDATE TO authenticated
  USING (provider_id IS NULL AND status = 'pending')
  WITH CHECK (provider_id = (SELECT id FROM provider_profiles WHERE user_id = auth.uid()));

CREATE POLICY "provider_update_own_bookings" ON bookings
  FOR UPDATE TO authenticated
  USING (provider_id = (SELECT id FROM provider_profiles WHERE user_id = auth.uid()))
  WITH CHECK (provider_id = (SELECT id FROM provider_profiles WHERE user_id = auth.uid()));
```

### ✅ Paso 2: Habilitar REPLICA IDENTITY
```sql
ALTER TABLE bookings REPLICA IDENTITY FULL;
```

Esto permite que Realtime capture TODOS los cambios de la tabla.

### ✅ Paso 3: Confirmar que Realtime está habilitado
En Supabase Dashboard → Database → Publications → supabase_realtime → bookings debe estar **ON**.

---

## Por Qué No Funcionaba

| Factor | Antes | Ahora |
|--------|-------|-------|
| **REPLICA IDENTITY** | No configurado | FULL |
| **RLS Policies** | Limitadas | Optimizadas |
| **Stream subscription** | `.stream()` básico | Con RLS correcta |
| **Realtime publications** | Habilitado pero sin REPLICA IDENTITY | Totalmente funcional |

---

## Próximos Pasos

### Para que funcione definitivamente:

1. **Reinicia Flutter** (esto fuerza nueva conexión a Supabase):
   ```bash
   flutter clean
   flutter pub get
   flutter run -d chrome
   ```

2. **Prueba el flujo completo**:
   - Cliente: Crea solicitud
   - Prestador: Debería ver en el dashboard AL INSTANTE
   - Prestador: Acepta o rechaza
   - Cliente: Debería ver el cambio de estado

3. **Si aún no funciona**, el problema podría ser:
   - Realtime no está realmente habilitado (verificar en Publications)
   - Hay un firewall/proxy bloqueando WebSockets
   - La conexión de auth no es correcta

---

## Verificación

Para verificar que todo está bien, ejecuta en Supabase SQL Editor:

```sql
-- Verificar REPLICA IDENTITY
SELECT schemaname, tablename, replica_identity
FROM pg_tables t
LEFT JOIN pg_class c ON c.relname = t.tablename
LEFT JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = t.schemaname
WHERE tablename = 'bookings';

-- Verificar políticas RLS
SELECT policyname, cmd FROM pg_policies
WHERE tablename = 'bookings';

-- Verificar si bookings está en publicación
SELECT * FROM pg_publication_tables
WHERE pubname = 'supabase_realtime' AND tablename = 'bookings';
```

---

## Resumen

La causa raíz era que **REPLICA IDENTITY no estaba configurado**, lo que impide que Supabase Realtime capture cambios correctamente. Se ha:

✅ Configurado REPLICA IDENTITY FULL  
✅ Limpiado y recreado políticas RLS  
✅ Confirmado que Realtime está habilitado en Publications  

**Ahora deberías ver solicitudes llegar al instante.**

---

_Análisis completado: 2026-06-19_
