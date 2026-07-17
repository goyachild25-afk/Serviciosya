-- notifications: WITH CHECK (true) para el rol public dejaba que CUALQUIER
-- usuario logueado insertara una notificación falsa en el feed de
-- CUALQUIER otro usuario (phishing dentro de la app: "tu reserva fue
-- aceptada", etc.). Verificado: ningún código cliente inserta en
-- notifications — los únicos escritores reales son triggers SECURITY
-- DEFINER y Edge Functions con service_role, y ambos ya evitan RLS por
-- completo (corren como el dueño de la función / rol de servicio). La
-- política no protegía nada legítimo.
drop policy if exists "notifications_insert_system" on public.notifications;

-- verification_requests: no existía política de UPDATE para el dueño de la
-- fila. user_id es UNIQUE, así que el upsert de
-- provider_verification_screen.dart se vuelve un UPDATE en cuanto ya existe
-- una fila (ej. tras un rechazo) — sin política, ese UPDATE truena con
-- RLS y un prestador rechazado no puede reenviar nunca. El WITH CHECK
-- fuerza status='pending' para que no pueda auto-aprobarse.
create policy "verif_own_update"
on public.verification_requests for update
to public
using ((select auth.uid()) = user_id)
with check (
  (select auth.uid()) = user_id
  and status = 'pending'
);
