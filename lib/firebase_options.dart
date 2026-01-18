import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    return android;
  }

  /// WEB CONFIG
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDc9VJKHwVg0zP1GzZay0vlA998Bsymx-M",
    authDomain: "hostel-management-app-ae99e.firebaseapp.com",
    projectId: "hostel-management-app-ae99e",
    storageBucket: "hostel-management-app-ae99e.firebasestorage.app",
    messagingSenderId: "746037469825",
    appId: "1:746037469825:web:ee49e5adbd7ca4f84fe380",
  );

  /// ANDROID CONFIG
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyDc9VJKHwVg0zP1GzZay0vlA998Bsymx-M",
    appId: "1:746037469825:android:85a1bb83524712694fe380",
    messagingSenderId: "746037469825",
    projectId: "hostel-management-app-ae99e",
    storageBucket: "hostel-management-app-ae99e.firebasestorage.app",
  );
}
