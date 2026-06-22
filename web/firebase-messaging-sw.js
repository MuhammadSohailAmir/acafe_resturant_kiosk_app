// Firebase background messaging service worker for the A/CAFÉ customer web app.
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

firebase.initializeApp({
    apiKey: "AIzaSyAXGwobGlroK3Ex_3eDfU4_dQDm8iBk1To",
    authDomain: "acafe-2d9df.firebaseapp.com",
    projectId: "acafe-2d9df",
    storageBucket: "acafe-2d9df.firebasestorage.app",
    messagingSenderId: "130585563604",
    appId: "1:130585563604:web:45d7256610ff3f061f0641",
    measurementId: "G-X6W4T2LLD9"
});

const messaging = firebase.messaging();

// Fires when a push arrives while the customer web tab is NOT in the foreground
// (e.g. the staff is changing the status from the kitchen tab). Without this,
// status-change notifications were silently dropped and only appeared in the
// in-app history. We surface a real OS notification here so the customer is
// alerted live.
messaging.onBackgroundMessage((message) => {
    const data = message.data || {};
    const notification = message.notification || {};

    const title = notification.title || data.title || 'A/CAFÉ';
    const body = notification.body || data.body || '';

    self.registration.showNotification(title, {
        body: body,
        icon: '/favicon.png',
        badge: '/favicon.png',
        // Group by order so repeated status changes for the same order replace
        // the previous one instead of stacking.
        tag: data.order_id ? 'order-' + data.order_id : undefined,
        renotify: true,
        data: data,
    });
});

// Focus (or open) the app when the customer clicks the notification.
self.addEventListener('notificationclick', (event) => {
    event.notification.close();
    event.waitUntil(
        clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
            for (const client of clientList) {
                if ('focus' in client) {
                    return client.focus();
                }
            }
            if (clients.openWindow) {
                return clients.openWindow('/');
            }
        })
    );
});
