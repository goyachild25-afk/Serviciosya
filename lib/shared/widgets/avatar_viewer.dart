import 'package:flutter/material.dart';

/// Visor de foto de perfil a pantalla completa, estilo Instagram:
/// un toque sobre el avatar → imagen grande con zoom (pellizco hasta 5x);
/// un toque en cualquier parte o la X → cerrar.
///
/// Si no hay foto no abre nada: el toque simplemente no hace ruido.
Future<void> showAvatarViewer(
  BuildContext context, {
  required String? url,
  required String name,
}) async {
  if (url == null || url.isEmpty) return;

  await showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (ctx) => Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(ctx).pop(),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: InteractiveViewer(
                    maxScale: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : const SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.white70,
                                          strokeWidth: 2.5),
                                    ),
                                  ),
                        errorBuilder: (_, __, ___) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.white10,
                          child: const Icon(Icons.person_off_outlined,
                              size: 64, color: Colors.white38),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(ctx).pop(),
                  tooltip: 'Cerrar',
                ),
              ),
              Positioned(
                bottom: 28,
                left: 24,
                right: 24,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
