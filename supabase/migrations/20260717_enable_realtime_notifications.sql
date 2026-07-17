-- notifications no estaba en la publicación de Realtime, aunque
-- notifications_provider.dart y live_notifications_service.dart asumen
-- que sí (usan .stream() y onPostgresChanges) — el banner flotante y el
-- contador de no leídas nunca se actualizaban en vivo, solo al reabrir
-- la pantalla. Mismo patrón que el bug de app_settings/verification_requests/
-- disputes encontrado antes.
alter publication supabase_realtime add table public.notifications;
