import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show HttpMethod;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Pantalla de Privacidad y datos personales — Derechos ARCO (Ley 172-13).
///
/// Aquí el usuario puede ejercer:
///   • Acceso / Portabilidad → botón "Descargar mis datos" (edge fn export-my-data)
///   • Cancelación           → botón "Eliminar mi cuenta"    (edge fn delete-my-account)
///   • Rectificación         → link al perfil editable
///   • Oposición             → link a WhatsApp/correo de privacidad
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _exporting = false;
  bool _deleting = false;

  Future<void> _exportData() async {
    setState(() => _exporting = true);
    try {
      final resp = await SupabaseService.client.functions.invoke(
        'export-my-data',
        method: HttpMethod.get,
      );
      if (resp.status != 200) throw Exception('http ${resp.status}');
      // functions.invoke devuelve el JSON ya parseado en resp.data.
      final jsonStr =
          const JsonEncoder.withIndent('  ').convert(resp.data);

      // Ofrecer el JSON como descarga vía data URL. En Web abre; en móvil
      // el navegador embebido lo mostrará.
      final data = base64.encode(utf8.encode(jsonStr));
      final url = Uri.parse('data:application/json;base64,$data');
      final launched =
          await launchUrl(url, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(launched
                  ? '✅ Tu archivo se descargó. Revisa tus descargas.'
                  : 'Datos generados. Revisa tu carpeta de descargas.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No pudimos generar tu archivo. Intenta de nuevo o escribe a privacidad@serviciosya.do')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar tu cuenta?'),
        content: const Text(
          'Esta acción no se puede deshacer. Tus datos operativos serán anonimizados en 15 segundos y tu sesión se cerrará.\n\n'
          'Por obligación legal (Ley 11-92) conservamos tus datos financieros por 5 años y las evidencias de disputas por 10 años, todo anonimizado y sin identificarte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      final resp = await SupabaseService.client.functions.invoke(
        'delete-my-account',
        method: HttpMethod.post,
      );
      if (resp.status != 200) throw Exception('http ${resp.status}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Tu cuenta ha sido eliminada.'),
              duration: Duration(seconds: 4)),
        );
      }

      // Cerrar sesión localmente y redirigir a login
      await ref.read(authControllerProvider.notifier).signOut();
      if (mounted) context.go('/login');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No pudimos eliminar tu cuenta. Escribe a privacidad@serviciosya.do para asistencia manual.')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidad y mis datos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionHeader('Tus derechos (Ley 172-13)'),
          const SizedBox(height: 12),
          const Text(
            'La Ley 172-13 de la República Dominicana te otorga los siguientes derechos sobre tus datos personales. Puedes ejercerlos desde aquí en cualquier momento.',
            style: TextStyle(
                fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),

          // ── Descargar mis datos ────────────────────────────────
          _actionCard(
            icon: Icons.download_rounded,
            color: AppColors.primary,
            title: 'Descargar mis datos',
            description:
                'Obtén un archivo JSON con toda la información que ServiciosYa tiene sobre ti (perfil, reservas, chat, reseñas).',
            actionLabel: 'Descargar',
            loading: _exporting,
            onTap: _exportData,
          ),
          const SizedBox(height: 12),

          // ── Rectificar (link al perfil) ────────────────────────
          _actionCard(
            icon: Icons.edit_note_rounded,
            color: AppColors.info,
            title: 'Corregir mis datos',
            description:
                'Modifica tu nombre, teléfono, correo o dirección desde tu perfil.',
            actionLabel: 'Ir al perfil',
            onTap: () => context.push('/profile'),
          ),
          const SizedBox(height: 12),

          // ── Oposición (contactar) ──────────────────────────────
          _actionCard(
            icon: Icons.contact_support_outlined,
            color: AppColors.warning,
            title: 'Solicitar limitación u oposición',
            description:
                'Escribe a nuestro equipo de privacidad para restringir usos específicos de tus datos.',
            actionLabel: 'Escribir',
            onTap: () async {
              final uri = Uri(
                scheme: 'mailto',
                path: 'privacidad@serviciosya.do',
                query: 'subject=Oposicion%20al%20tratamiento%20de%20mis%20datos',
              );
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
          const SizedBox(height: 12),

          // ── Eliminar mi cuenta ─────────────────────────────────
          _actionCard(
            icon: Icons.delete_outline_rounded,
            color: AppColors.error,
            title: 'Eliminar mi cuenta',
            description:
                'Anonimiza permanentemente tu cuenta y todos tus datos operativos. Esta acción no se puede deshacer.',
            actionLabel: 'Eliminar',
            loading: _deleting,
            destructive: true,
            onTap: _confirmDelete,
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Contacto del Responsable del Tratamiento',
            style:
                TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'privacidad@serviciosya.do\nRespuesta dentro de 15 días hábiles.',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      );

  Widget _actionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required String actionLabel,
    bool loading = false,
    bool destructive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: destructive ? color : AppColors.textPrimary,
                      )),
                  const SizedBox(height: 4),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(actionLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
          ],
        ),
      ),
    );
  }
}
