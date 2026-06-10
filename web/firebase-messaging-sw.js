// Firebase Messaging Service Worker — ServiciosYa
// Este archivo maneja notificaciones push cuando la app está cerrada o en background.
//
// IMPORTANTE: Reemplazar los valores de configuración con los de tu proyecto Firebase.
// Firebase Console → Project Settings → Your apps → Web → SDK setup and configuration

importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Reemplazar con tu configuración de Firebase
firebase.initializeApp({
  apiKey: 'REEMPLAZAR_CON_API_KEY',
  authDomain: 'REEMPLAZAR_CON_PROJECT_ID.firebaseapp.com',
  projectId: 'REEMPLAZAR_CON_PROJECT_ID',
  storageBucket: 'REEMPLAZAR_CON_PROJECT_ID.appspot.com',
  messagingSenderId: 'REEMPLAZAR_CON_SENDER_ID',
  appId: 'REEMPLAZAR_CON_APP_ID',
});

const messaging = firebase.messaging();

// Mostrar notificación en background
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? 'ServiciosYa';
  const body  = payload.notification?.body  ?? '';
  const icon  = '/icons/Icon-192.png';

  return self.registration.showNotification(title, {
    body,
    icon,
    badge: '/icons/Icon-192.png',
    data: payload.data,
    tag: payload.data?.booking_id ?? 'serviciosya',
  });
});

// Al hacer clic en la notificación → abrir la app en la ruta correcta
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const data = event.notification.data ?? {};
  let url = '/';
  if (data.type === 'new_message' && data.booking_id) {
    url = `/#/chat/${data.booking_id}`;
  } else if (data.booking_id) {
    url = '/#/bookings';
  }
  event.waitUntil(clients.openWindow(url));
});
