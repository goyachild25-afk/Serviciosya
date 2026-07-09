import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/demo_provider.dart';

/// Estado de verificación de identidad del prestador actual.
/// null = nunca ha iniciado el proceso.
final myVerificationRequestProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  if (ref.watch(demoModeProvider)) {
    // En demo el prestador se comporta como verificado
    return {'status': 'approved', 'didit_status': 'Approved'};
  }
  final user = SupabaseService.currentUser;
  if (user == null) return null;
  final row = await SupabaseService.client
      .from('verification_requests')
      .select(
          'status, didit_status, didit_session_id, id_front_url, submitted_at')
      .eq('user_id', user.id)
      .maybeSingle();
  return row;
});

/// La puerta de entrada al panel de prestador: ¿completó el proceso de
/// verificación de identidad? (No exige aún la aprobación del admin — esa
/// controla poder ACEPTAR solicitudes, no ver el panel.)
///
/// Cuenta como "completado":
/// - admin ya aprobó (status = approved), o
/// - la sesión de Didit registró actividad real (el webhook reportó
///   cualquier estado que implique que la captura ocurrió o está en curso), o
/// - solicitudes antiguas del flujo manual (subieron fotos localmente).
bool verificationGateOk(Map<String, dynamic>? row) {
  if (row == null) return false;
  if (row['status'] == 'approved') return true;
  const submitted = {'Approved', 'In Review', 'In Progress', 'Declined'};
  if (submitted.contains(row['didit_status'] as String?)) return true;
  if (row['id_front_url'] != null) return true; // flujo manual legado
  return false;
}
