-- Timestamp dedicado del momento en que un prestador acepta una reserva.
-- updated_at no sirve para medir esto: se pisa en cada cambio de status
-- posterior (in_progress, completed), así que "tiempo hasta primera
-- aceptación" solo puede calcularse de verdad con una columna propia.
alter table public.bookings add column if not exists accepted_at timestamptz;
