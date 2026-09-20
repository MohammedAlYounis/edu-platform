importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBwrECPaiULLBj9jGTfQWZ1FQRxw5eJHXk',
  authDomain: 'educational-platform-bd155.firebaseapp.com',
  projectId: 'educational-platform-bd155',
  storageBucket: 'educational-platform-bd155.firebasestorage.app',
  messagingSenderId: '850119558458',
  appId: '1:850119558458:web:55cf6257e823bcb8e5bc03',
});

firebase.messaging();
