import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/maintenance_service.dart';

/// Pantalla que se muestra a los usuarios cuando el admin activa el modo
/// mantenimiento desde el panel. El provider `maintenanceModeProvider` es
/// Realtime, así que en el momento en que el admin apaga el toggle, todas
/// las sesiones no-admin son redirigidas de vuelta a `/` sin necesidad de
/// recargar.
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Con solo watchearlo aquí, cualquier cambio del toggle re-dispara el
    // redirect del router.
    ref.watch(maintenanceModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.handyman_outlined,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Estamos afinando ServiciosYa',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Volvemos en unos minutos. Gracias por tu paciencia — estamos haciendo mejoras para ti.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Indicador sutil de que la pantalla está viva y va a auto-refrescar
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'La app se reanudará automáticamente en cuanto terminemos.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
