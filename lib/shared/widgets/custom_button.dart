import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

// ── Botón primario con gradiente y animación de pulsación ───────────────────
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final double? height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.height,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isLoading && widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeInOut,
        child: SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          height: widget.height ?? 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: enabled ? AppColors.primaryGradient : null,
              color: enabled ? null : AppColors.border,
              borderRadius: BorderRadius.circular(18),
              boxShadow: enabled && !_pressed ? AppColors.buttonShadow : null,
            ),
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Botón secundario con animación de pulsación ──────────────────────────────
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isLoading && widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeInOut,
        child: SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          height: 56,
          child: OutlinedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: EdgeInsets.zero,
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Botón de texto con subrayado suave ───────────────────────────────────────
class TextLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const TextLinkButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: GoogleFonts.nunito(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primaryLight,
          decorationThickness: 1.5,
        ),
      ),
    );
  }
}

// ── Botón de acento (coral/cálido) con animación de pulsación ───────────────
class AccentButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;

  const AccentButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
  });

  @override
  State<AccentButton> createState() => _AccentButtonState();
}

class _AccentButtonState extends State<AccentButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isLoading && widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeInOut,
        child: SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: enabled ? AppColors.warmGradient : null,
              color: enabled ? null : AppColors.border,
              borderRadius: BorderRadius.circular(18),
              boxShadow: enabled && !_pressed ? AppColors.accentShadow : null,
            ),
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
