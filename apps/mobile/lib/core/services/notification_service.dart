import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static final _db = Supabase.instance.client;

  static Future<void> init() async {
    // Request permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get token and save to DB
    final token = await _fcm.getToken();
    if (token != null) await _saveToken(token);

    // Refresh token when it changes
    _fcm.onTokenRefresh.listen(_saveToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_showInAppBanner);
  }

  static Future<void> _saveToken(String token) async {
    final authUser = _db.auth.currentUser;
    if (authUser == null) return;
    try {
      await _db
          .from('users')
          .update({'device_token': token})
          .eq('auth_user_id', authUser.id);
    } catch (_) {}
  }

  static void _showInAppBanner(RemoteMessage message) {
    // Will show via a global snackbar — wired up in main
    debugPrint('FCM foreground: ${message.notification?.title}');
  }
}
