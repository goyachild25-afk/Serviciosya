-- Cierra el bypass de verificación de identidad a nivel de base de datos.
-- La app bloqueaba el botón "Aceptar" si is_verified != true, pero eso era
-- solo una guardia de UI — la política RLS real que permite aceptar una
-- reserva abierta no verificaba nada, así que cualquier prestador
-- (verificado o no) podía asignarse una reserva llamando la API directo
-- con su propio JWT, sin pasar por la app.
drop policy if exists "bookings_provider_accept" on public.bookings;
create policy "bookings_provider_accept"
on public.bookings for update
to public
using (
  (provider_id is null) and (status = 'pending')
)
with check (
  provider_id = (
    select provider_profiles.id from provider_profiles
    where provider_profiles.user_id = (select auth.uid())
    and provider_profiles.is_verified = true
  )
);

-- Reservas directas (el cliente elige un prestador específico de la lista):
-- el INSERT tampoco verificaba que ese prestador estuviera verificado.
-- Mismo hueco, otro camino de asignar provider_id a una reserva.
drop policy if exists "bookings_client_insert" on public.bookings;
create policy "bookings_client_insert"
on public.bookings for insert
to public
with check (
  (select auth.uid()) = client_id
  and (
    provider_id is null
    or exists (
      select 1 from provider_profiles pp
      where pp.id = provider_id and pp.is_verified = true
    )
  )
);
