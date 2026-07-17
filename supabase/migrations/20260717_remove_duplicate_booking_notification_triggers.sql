-- bookings tenía dos generaciones de triggers de notificación activas al
-- mismo tiempo: la vieja (on_new_booking/on_booking_accepted/
-- on_booking_completed/on_booking_rejected → trg_*, sin booking_id) y la
-- más completa y reciente (trigger_notify_booking_insert/update →
-- notify_booking_status_change, con booking_id y con soporte para
-- solicitudes broadcast que la vieja nunca tuvo). Cada aceptar/rechazar/
-- completar/solicitud directa nueva insertaba 2 filas en notifications —
-- una usable (con booking_id) y otra sin booking_id que no lleva a
-- ningún lado al tocarla. Se conserva la generación más completa.
--
-- _insert_notification() NO se toca — la usan trg_new_review y
-- update_provider_level, que no forman parte de esta duplicación.
drop trigger if exists on_new_booking on public.bookings;
drop trigger if exists on_booking_accepted on public.bookings;
drop trigger if exists on_booking_completed on public.bookings;
drop trigger if exists on_booking_rejected on public.bookings;

drop function if exists public.trg_new_booking();
drop function if exists public.trg_booking_accepted();
drop function if exists public.trg_booking_completed();
drop function if exists public.trg_booking_rejected();
