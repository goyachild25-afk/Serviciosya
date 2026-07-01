import 'dart:js_interop';

@JS('deferredPrompt')
external JSAny? get _deferredPrompt;

@JS('isInStandaloneMode')
external bool? get _isInStandaloneMode;

@JS('appInstalled')
external bool? get _appInstalled;

@JS('isIOS')
external bool? get _isIOS;

extension type _InstallPrompt(JSObject _) implements JSObject {
  external void prompt();
}

bool isInstallable() {
  try {
    return _deferredPrompt != null;
  } catch (_) {
    return false;
  }
}

bool isAlreadyInstalled() {
  try {
    return _isInStandaloneMode == true || _appInstalled == true;
  } catch (_) {
    return false;
  }
}

bool isIOS() {
  try {
    return _isIOS == true;
  } catch (_) {
    return false;
  }
}

void triggerInstall() {
  try {
    final p = _deferredPrompt;
    if (p != null) {
      _InstallPrompt(p as JSObject).prompt();
    }
  } catch (_) {}
}
