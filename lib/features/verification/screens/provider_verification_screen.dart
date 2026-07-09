import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/demo_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../core/utils/cedula_validator.dart';
import '../providers/verification_status_provider.dart';

class ProviderVerificationScreen extends ConsumerStatefulWidget {
  const ProviderVerificationScreen({super.key});

  @override
  ConsumerState<ProviderVerificationScreen> createState() =>
      _ProviderVerificationScreenState();
}

class _ProviderVerificationScreenState
    extends ConsumerState<ProviderVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idNumberCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _isSaving = false;
  bool _consentGiven = false;

  @override
  void dispose() {
    _idNumberCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // Captura la cédula + selfie en vivo a través del flujo hospedado de
  // Didit (necesario para la detección de "persona real" — no se puede
  // hacer sobre una foto ya tomada). El resultado llega después, de forma
  // asíncrona, vía webhook — aquí solo abrimos la sesión.
  Future<void> _startVerification() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar el procesamiento de tus documentos para continuar'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final isDemo = ref.read(demoModeProvider);
    if (isDemo) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) _showPendingDialog();
      setState(() => _isSaving = false);
      return;
    }

    try {
      final user = SupabaseService.currentUser!;

      // Guardar la información básica ya mismo — el resultado biométrico
      // de Didit llegará por webhook y se enlaza por user_id.
      await SupabaseService.client.from('verification_requests').upsert({
        'user_id': user.id,
        'id_number': CedulaValidator.format(_idNumberCtrl.text.trim()),
        'bio': _bioCtrl.text.trim(),
        'status': 'pending',
        'submitted_at': DateTime.now().toIso8601String(),
        'consent_given_at': DateTime.now().toIso8601String(),
      });

      await SupabaseService.client
          .from('provider_profiles')
          .update({'bio': _bioCtrl.text.trim()}).eq('user_id', user.id);

      final session = await SupabaseService.client.functions
          .invoke('didit-create-session');

      final data = session.data as Map<String, dynamic>?;
      final url = data?['url'] as String?;
      if (url == null) {
        throw Exception(data?['error'] ?? 'No se pudo iniciar la verificación');
      }

      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

      if (mounted) _showPendingDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo iniciar la verificación: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  size: 48, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verificación en curso',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Se abrió una pestaña nueva para completar la captura de tu cédula y selfie. Cuando termines ahí, tu solicitud quedará en revisión — el equipo de YALO la confirmará en 24-48 horas.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Refrescar el estado antes de intentar entrar al panel —
                // la puerta de seguridad lo consulta al llegar.
                ref.invalidate(myVerificationRequestProvider);
                Navigator.pop(context);
                context.go('/dashboard');
              },
              child: const Text('Entendido'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar mi identidad'),
        // La verificación es OBLIGATORIA para operar como prestador: los
        // prestadores entran a hogares y la seguridad del cliente no es
        // negociable. Si se llega desde el onboarding (sin stack detrás),
        // no hay flecha de volver — el único camino es completarla.
        automaticallyImplyLeading: false,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Sesión ya iniciada: esperar el resultado ──────────────────
              // Si el prestador abrió Didit pero el webhook aún no reporta,
              // que no crea que tiene que llenar todo de nuevo.
              Consumer(builder: (context, ref, _) {
                final row =
                    ref.watch(myVerificationRequestProvider).valueOrNull;
                final sessionStarted = row?['didit_session_id'] != null &&
                    !verificationGateOk(row);
                if (!sessionStarted) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ya iniciaste una verificación. Si completaste la captura en la pestaña de nuestro proveedor, toca Actualizar — el resultado puede tardar unos segundos en llegar.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Actualizar'),
                        onPressed: () =>
                            ref.invalidate(myVerificationRequestProvider),
                      ),
                    ],
                  ),
                );
              }),

              // Banner explicativo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_outlined,
                        color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿Por qué verificamos tu identidad?',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Para proteger a los clientes y darte el badge "Verificado" que aumenta tus solicitudes.',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Pasos
              _StepLabel(number: '1', label: 'Información básica'),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Número de cédula',
                hint: '000-0000000-0',
                controller: _idNumberCtrl,
                prefixIcon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                validator: (v) => CedulaValidator.errorMessage(v ?? ''),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Cuéntanos sobre ti',
                hint: 'Experiencia, especialidades, por qué confiar en ti...',
                controller: _bioCtrl,
                maxLines: 4,
                prefixIcon: Icons.person_outline,
                validator: (v) => v == null || v.length < 20
                    ? 'Escribe al menos 20 caracteres'
                    : null,
              ),
              const SizedBox(height: 24),

              _StepLabel(number: '2', label: 'Verificación de identidad'),
              const SizedBox(height: 4),
              const Text(
                'Captura tu cédula y una selfie en vivo — se abre en una pestaña segura de nuestro proveedor de verificación.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.camera_front_outlined,
                        size: 36, color: AppColors.primary),
                    const SizedBox(height: 10),
                    const Text(
                      'Cédula (frente y reverso) + selfie con detección de vida',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Consentimiento explícito para datos biométricos ────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _consentGiven,
                      onChanged: (v) =>
                          setState(() => _consentGiven = v ?? false),
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            setState(() => _consentGiven = !_consentGiven),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'Acepto que mi cédula y selfie sean procesadas para verificar mi identidad, incluyendo por un proveedor externo especializado. Se eliminan automáticamente 90 días después de la revisión — puedo pedir su borrado antes desde mi perfil. Ver detalles en Términos y Privacidad.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              PrimaryButton(
                label: 'Verificar mi identidad',
                onPressed: _consentGiven ? _startVerification : null,
                isLoading: _isSaving,
                icon: Icons.verified_user_outlined,
              ),
              const SizedBox(height: 12),
              const Text(
                '🔒 Tus documentos están protegidos y solo son accesibles por el equipo de YALO.',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String number;
  final String label;
  const _StepLabel({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(number,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    );
  }
}
