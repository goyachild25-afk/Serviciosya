import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Estado global del modo mantenimiento leído desde `public.app_settings`.
///
/// Es un StreamProvider que se refresca por Realtime cada vez que un admin
/// actualiza la fila `maintenance_mode`. Así, activar el toggle desde el
/// panel bloquea instantáneamente todas las sesiones no-admin abiertas —
/// sin tener que desplegar código ni pedirles a los usuarios que recarguen.
///
/// Fallback: si Realtime no está disponible o falla la suscripción, se
/// devuelve `false` (aplicación abierta) para no bloquear a nadie por un
/// problema de conectividad.
final maintenanceModeProvider = StreamProvider<bool>((ref) async* {
  try {
    // Emit inicial: leer valor actual
    final row = await SupabaseService.client
        .from('app_settings')
        .select('value')
        .eq('key', 'maintenance_mode')
        .maybeSingle();
    final initial = (row?['value'] as bool?) ?? false;
    yield initial;

    // Suscribirse a cambios en tiempo real
    final controller = StreamController<bool>();
    final channel = SupabaseService.client
        .channel('app_settings:maintenance_mode')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'app_settings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'key',
            value: 'maintenance_mode',
          ),
          callback: (payload) {
            final v = payload.newRecord['value'];
            if (v is bool) controller.add(v);
          },
        )
        .subscribe();

    ref.onDispose(() {
      controller.close();
      SupabaseService.client.removeChannel(channel);
    });

    yield* controller.stream;
  } catch (_) {
    yield false;
  }
});
