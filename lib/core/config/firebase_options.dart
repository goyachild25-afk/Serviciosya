// CONFIGURACIÓN FIREBASE — ServiciosYa
//
// Para completar la configuración de notificaciones push:
//
// 1. Ir a https://console.firebase.google.com
// 2. Crear proyecto "ServiciosYa" (o usar uno existente)
// 3. Agregar app Web:
//    - Nombre: ServiciosYa Web
//    - Copiar los valores en la sección WEB abajo
// 4. Para Android:
//    - Package name: com.serviciosya.app
//    - Descargar google-services.json → android/app/
// 5. Para iOS:
//    - Bundle ID: com.serviciosya.app
//    - Descargar GoogleService-Info.plist → ios/Runner/
// 6. En Firebase Console → Project Settings → Cloud Messaging:
//    - Generar par de claves VAPID → copiar la clave pública abajo (webVapidKey)
// 7. Correr: flutter pub get

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class AppFirebaseOptions {
  // VAPID key para push en web — Firebase Console → Cloud Messaging → Web Push certificates
  static const String webVapidKey = 'REEMPLAZAR_CON_VAPID_KEY_DE_FIREBASE';
}

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // ── WEB ───────────────────────────────────────────────────────────────────────
  // Firebase Console → Project Settings → Your apps → Web → SDK setup
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REEMPLAZAR_CON_API_KEY',
    appId: 'REEMPLAZAR_CON_APP_ID',
    messagingSenderId: 'REEMPLAZAR_CON_SENDER_ID',
    projectId: 'REEMPLAZAR_CON_PROJECT_ID',
    authDomain: 'REEMPLAZAR_CON_PROJECT_ID.firebaseapp.com',
    storageBucket: 'REEMPLAZAR_CON_PROJECT_ID.appspot.com',
    measurementId: 'REEMPLAZAR_CON_MEASUREMENT_ID',
  );

  // ── ANDROID ───────────────────────────────────────────────────────────────────
  // Firebase Console → Project Settings → Your apps → Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REEMPLAZAR_CON_API_KEY_ANDROID',
    appId: 'REEMPLAZAR_CON_APP_ID_ANDROID',
    messagingSenderId: 'REEMPLAZAR_CON_SENDER_ID',
    projectId: 'REEMPLAZAR_CON_PROJECT_ID',
    storageBucket: 'REEMPLAZAR_CON_PROJECT_ID.appspot.com',
  );

  // ── iOS ───────────────────────────────────────────────────────────────────────
  // Firebase Console → Project Settings → Your apps → iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REEMPLAZAR_CON_API_KEY_IOS',
    appId: 'REEMPLAZAR_CON_APP_ID_IOS',
    messagingSenderId: 'REEMPLAZAR_CON_SENDER_ID',
    projectId: 'REEMPLAZAR_CON_PROJECT_ID',
    storageBucket: 'REEMPLAZAR_CON_PROJECT_ID.appspot.com',
    iosBundleId: 'com.serviciosya.app',
  );
}
