import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'app.dart';
import 'core/services/observability_service.dart';
import 'core/services/payment_service.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Locales para timeago en español
  timeago.setLocaleMessages('es', timeago.EsMessages());

  // Datos de localización para DateFormat('...', 'es') — sin esto, cualquier
  // DateFormat con locale 'es' lanza LocaleDataException en tiempo de
  // ejecución (ej: el panel admin rompía "Ingresos este mes · junio 2026").
  await initializeDateFormatting('es');

  // Sentry (si hay DSN) envuelve toda la ejecución para captar errores
  // sincrónicos y asincrónicos del framework. Sin DSN, es no-op.
  await ObservabilityService.init(appRunner: () async {
    // Inicializar Supabase
    try {
      await SupabaseService.initialize();
      await PaymentService.initialize();
    } catch (_) {
      // Sin credenciales reales → la app funciona en Modo Demo
    }

    runApp(
      const ProviderScope(
        child: YALOApp(),
      ),
    );
  });
}
