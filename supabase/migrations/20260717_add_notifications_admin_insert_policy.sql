-- Al quitar notifications_insert_system (WITH CHECK true, el hueco de
-- spoofing) quedó sin ninguna política de INSERT — bloqueaba incluso las
-- inserciones legítimas del panel Admin (ej. avisar al resolver una
-- disputa). Los triggers/Edge Functions siguen sin necesitar esto (ya
-- evitan RLS por completo), esto es solo para acciones admin desde el
-- cliente.
create policy "notifications_admin_insert"
on public.notifications for insert
to public
with check (is_admin());
