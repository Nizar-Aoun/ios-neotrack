// Import Firebase scripts for service worker
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAJwvPHxiMA9WaBpevo2TAFkM1707aeLHY",
  authDomain: "neotrack-91425.firebaseapp.com",
  projectId: "neotrack-91425",
  storageBucket: "neotrack-91425.firebasestorage.app",
  messagingSenderId: "1040651729001",
  appId: "1:1040651729001:web:3ab2ec5f55c7e4a6f0caf8",
  measurementId: "G-41FX0P0GVP"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message received:', payload);

  const title = payload.notification?.title || 'NeoTrack Notification';
  const iconUrl = new URL('icons/Icon-192.png', self.location.href).toString();
  const options = {
    body: payload.notification?.body || 'You have a new notification',
    icon: iconUrl,
    badge: iconUrl,
    tag: payload.data?.type || 'notification',
    data: payload.data,
    requireInteraction: true,
    vibrate: [200, 100, 200]
  };

  return self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification clicked:', event.notification.tag);

  event.notification.close();
  const appUrl = new URL('./#/notifications', self.location.href).toString();

  event.waitUntil(
    clients.openWindow(appUrl)
  );
});
