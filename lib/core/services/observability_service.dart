import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'supabase_service.dart';

/// Servicio de observabilidad: errores + eventos de negocio.
///
/// Sentry se activa SOLO si el DSN se provee vía build-time flag:
///   flutter build web --dart-define=SENTRY_DSN=https://...@sentry.io/...
/// Sin DSN, `Sentry.init` no se ejecuta y `capture*` son no-op. Esto permite
/// desarrollar sin conectar Sentry y desplegar con Sentry sin cambiar código.
///
/// Los eventos de analytics se guardan en la tabla public.analytics_events
/// (creada por migración). Es intencionalmente barato — no reemplaza a
/// PostHog/Plausible/Mixpanel para análisis avanzado, pero da métricas
/// suficientes para decidir qué invertir en producto.
class ObservabilityService {
  ObservabilityService._();

  static const _sentryDsn =
      String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  static bool get isSentryEnabled => _sentryDsn.isNotEmpty;

  /// Inicializa Sentry si hay DSN. Llamar desde `main()` ANTES de runApp,
  /// y envolver `runApp(...)` en `SentryFlutter.wrapApp(...)` para captar
  /// errores del framework.
  static Future<void> init({
    required FutureOr<void> Function() appRunner,
  }) async {
    if (!isSentryEnabled) {
      // Sin DSN: ejecutar la app sin Sentry
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = _sentryDsn;
        options.tracesSampleRate = 0.2; // 20% de traces para no saturar
        options.attachScreenshot = false; // web: sensitivos legales
        options.beforeSend = (event, hint) {
          // Nunca reportar en debug builds
          if (kDebugMode) return null;
          return event;
        };
      },
      appRunner: appRunner,
    );
  }

  /// Captura de errores manuales para try/catch críticos.
  static Future<void> captureError(
    dynamic error, {
    StackTrace? stackTrace,
    String? hint,
  }) async {
    if (!isSentryEnabled) return;
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: hint == null ? null : Hint.withMap({'note': hint}),
    );
  }

  /// Emite un evento de analytics de negocio.
  ///
  /// `name` es el evento (ej. 'booking_created', 'first_payment', 'signup').
  /// `properties` es un JSON serializable con contexto adicional. El user_id
  /// se agrega automáticamente si hay sesión activa.
  ///
  /// Fire-and-forget: nunca bloquea el flujo del usuario. Los errores se
  /// silencian (analytics no puede romper la UX).
  static Future<void> trackEvent(
    String name, {
    Map<String, dynamic> properties = const {},
  }) async {
    try {
      final user = SupabaseService.currentUser;
      await SupabaseService.client.from('analytics_events').insert({
        'name': name,
        'user_id': user?.id,
        'properties': properties.isEmpty ? null : properties,
      });
    } catch (_) {
      // silencio intencional
    }
  }
}
