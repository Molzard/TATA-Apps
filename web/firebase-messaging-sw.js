// Give the service worker access to Firebase Messaging.
// Note that you can only use Firebase Messaging here. Other Firebase libraries
// are not available in the service worker.
importScripts('https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js');

// Initialize the Firebase app in the service worker by passing in
// your app's Firebase config object.
// https://firebase.google.com/docs/web/setup#config-object
firebase.initializeApp({
  apiKey: 'AIzaSyCpgEcZuvQW70JHFbJ2mBHlM_hf8DsPWvQ',
  appId: '1:244660030535:web:ee21e126b63aa82c843562',
  messagingSenderId: '244660030535',
  projectId: 'printing-commerce',
  authDomain: 'printing-commerce.firebaseapp.com',
  storageBucket: 'printing-commerce.appspot.com',
  databaseURL: 'https://printing-commerce-default-rtdb.firebaseio.com',
  measurementId: 'G-MEASUREMENT_ID',
});

// Retrieve an instance of Firebase Messaging so that it can handle background
// messages.
const messaging = firebase.messaging();

// Optional: Add background message handler
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/favicon.png'
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click event
self.addEventListener("notificationclick", function (event) {
  console.log(
    "[firebase-messaging-sw.js] Notification click occurred: ",
    event
  );

  const clickedNotification = event.notification;
  clickedNotification.close();

  // Get data from the notification
  const chatId = clickedNotification.data.chat_id;
  const orderId = clickedNotification.data.order_id;

  // Handle the click with a promise to wait for a new/existing client
  const urlToOpen = chatId
    ? `/chat/detail/${chatId}`
    : orderId
    ? `/order-detail/${orderId}`
    : "/chat";

  event.waitUntil(
    clients
      .matchAll({
        type: "window",
        includeUncontrolled: true,
      })
      .then((windowClients) => {
        // Check if there is already a window client open
        for (let i = 0; i < windowClients.length; i++) {
          const client = windowClients[i];
          if (client.url.includes(urlToOpen) && "focus" in client) {
            return client.focus();
          }
        }

        // If no open window, open a new one
        if (clients.openWindow) {
          return clients.openWindow(urlToOpen);
        }
      })
  );
});
