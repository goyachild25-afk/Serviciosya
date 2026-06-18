import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final String nextRoute;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.nextRoute,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isSending = false;
  int _resendCooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _resendCooldown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 1) {
        t.cancel();
        if (mounted) setState(() => _resendCooldown = 0);
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _sendCode() async {
    if (_isSending) return;
    setState(() => _isSending = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .sendEmailOtp(widget.email);
      _startCooldown();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo enviar el código: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String get _code => _ctrls.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length < 6) return;
    setState(() => _isVerifying = true);
    try {
      await ref.read(authControllerProvider.notifier).verifyEmailOtp(
            email: widget.email,
            token: _code,
          );
      if (mounted) context.go(widget.nextRoute);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Código incorrecto o expirado. Inténtalo de nuevo.'),
            backgroundColor: AppColors.error,
          ),
        );
        // Limpia los campos para reintentar
        for (final c in _ctrls) {
          c.clear();
        }
        _nodes[0].requestFocus();
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1) {
      if (index < 5) {
        _nodes[index + 1].requestFocus();
      } else {
        _nodes[index].unfocus();
        _verify();
      }
    } else if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filled = _code.length == 6;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifica tu correo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_outlined,
                    size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Código de verificación',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Enviamos un código de 6 dígitos a\n${widget.email}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // ── PIN boxes ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Padding(
                    padding: EdgeInsets.only(right: i < 5 ? 10 : 0),
                    child: SizedBox(
                      width: 46,
                      height: 56,
                      child: TextFormField(
                        controller: _ctrls[i],
                        focusNode: _nodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _ctrls[i].text.isNotEmpty
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: _ctrls[i].text.isNotEmpty ? 2 : 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: _ctrls[i].text.isNotEmpty
                              ? AppColors.primaryLighter
                              : AppColors.surfaceVariant,
                        ),
                        onChanged: (v) => _onDigitChanged(i, v),
                        onTap: () {
                          _ctrls[i].selection = TextSelection.fromPosition(
                            TextPosition(offset: _ctrls[i].text.length),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                label: 'Verificar',
                onPressed: filled ? _verify : null,
                isLoading: _isVerifying,
              ),
              const SizedBox(height: 24),
              // ── Reenviar código ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿No recibiste el código? ',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  if (_resendCooldown > 0)
                    Text(
                      'Reenviar en ${_resendCooldown}s',
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 14),
                    )
                  else
                    GestureDetector(
                      onTap: _isSending ? null : _sendCode,
                      child: Text(
                        _isSending ? 'Enviando...' : 'Reenviar código',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'El código expira en 10 minutos.\nRevisa también tu carpeta de spam.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                  height: 1.5,
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
