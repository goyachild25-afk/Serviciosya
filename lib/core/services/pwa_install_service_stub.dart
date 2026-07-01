// Stub para plataformas donde dart:js_interop no está disponible (VM, mobile).
bool isInstallable() => false;
bool isAlreadyInstalled() => false;
bool isIOS() => false;
void triggerInstall() {}
