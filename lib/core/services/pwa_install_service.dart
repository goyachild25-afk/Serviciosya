import 'package:flutter/foundation.dart';

// Import condicional: cuando el compilador tiene dart:js_interop (Flutter web)
// usa la implementación real; en cualquier otra plataforma (o cuando corre
// `flutter test` en la VM, donde dart:js_interop no existe) usa el stub.
import 'pwa_install_service_stub.dart'
    if (dart.library.js_interop) 'pwa_install_service_web.dart' as impl;

class PwaInstallService {
  /// True si Chrome capturó beforeinstallprompt (Android)
  static bool get isInstallable {
    if (!kIsWeb) return false;
    return impl.isInstallable();
  }

  /// True si ya está instalada o corriendo en modo standalone
  static bool get isAlreadyInstalled {
    if (!kIsWeb) return false;
    return impl.isAlreadyInstalled();
  }

  /// True en iOS (Safari no soporta beforeinstallprompt)
  static bool get isIOS {
    if (!kIsWeb) return false;
    return impl.isIOS();
  }

  /// Dispara el diálogo nativo de instalación (Android/Chrome)
  static void triggerInstall() {
    if (!kIsWeb) return;
    impl.triggerInstall();
  }

  /// True si debe mostrarse el banner
  static bool get shouldShowBanner {
    if (isAlreadyInstalled) return false;
    return isInstallable || isIOS;
  }
}
