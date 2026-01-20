import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static Future<void> init() async {
    final fcm = FirebaseMessaging.instance;

    await fcm.requestPermission();

    // 🚫 Web does NOT support topic subscription
    if (!kIsWeb) {
      await fcm.subscribeToTopic('all_users');
      print('Subscribed to all_users (mobile)');
    } else {
      print('Web detected – skipping topic subscription');
    }
  }
}
