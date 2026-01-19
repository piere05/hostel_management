import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static Future<void> saveToken() async {
    try {
      // WEB SUPPORT
      if (kIsWeb) {
        final token = await FirebaseMessaging.instance.getToken(
          vapidKey:
              "BFtvbVMI9yatc9eBND0imAoib7m24lOUOG8haQ0e4BxfNyBDujxru8oFk5Lbwp_HrzZd-PXLCGkKQwZTNYBnT4E",
        );

        if (token != null) {
          await FirebaseFirestore.instance
              .collection('fcm_tokens')
              .doc(token)
              .set({
                'token': token,
                'platform': 'web',
                'createdAt': Timestamp.now(),
              });
        }
        return;
      }

      // ANDROID / IOS
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        await FirebaseFirestore.instance
            .collection('fcm_tokens')
            .doc(token)
            .set({
              'token': token,
              'platform': 'mobile',
              'createdAt': Timestamp.now(),
            });
      }
    } catch (e) {
      // DO NOTHING — prevents crash
    }
  }
}
