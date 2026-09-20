import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Firebase is configured for Android and Web only.',
        );
    }
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyBwrECPaiULLBj9jGTfQWZ1FQRxw5eJHXk',
    appId: '1:850119558458:web:55cf6257e823bcb8e5bc03',
    messagingSenderId: '850119558458',
    projectId: 'educational-platform-bd155',
    authDomain: 'educational-platform-bd155.firebaseapp.com',
    storageBucket: 'educational-platform-bd155.firebasestorage.app',
    measurementId: 'G-1PKESNBE4S',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyBvJCgCROyUzp1O-LSILi5guWSfFEKW8',
    appId: '1:850119558458:android:85d25360489c7b8ce5bc03',
    messagingSenderId: '850119558458',
    projectId: 'educational-platform-bd155',
    storageBucket: 'educational-platform-bd155.firebasestorage.app',
  );
}
