import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';

import '../../features/auth/providers/auth_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(ref);
  
  // Listen for auth changes to sync token when user logs in
  ref.listen(authStateProvider, (previous, next) async {
    final user = next.value;
    if (user != null) {
       final token = await FirebaseMessaging.instance.getToken();
       if (token != null) {
          service.syncToken(token);
       }
    }
  });

  return service;
});

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  Future<void> initialize() async {
    // 1. Request Permissions
    await _requestPermission();

    // 2. Initialize Local Notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // 3. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // 4. Background Message Handler (when app is opened from background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked in background: ${message.data}');
      // TODO: Navigate based on data type (chat, connection, etc.)
    });

    // 5. Get Token and Sync
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      await syncToken(token);
    }

    // 6. Listen for Token Refresh
    _firebaseMessaging.onTokenRefresh.listen(syncToken);
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // id
            'High Importance Notifications', // title
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<void> syncToken(String token) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.put('/user/device-token', data: {'fcmToken': token}); 
      print('FCM Token synced to backend');
    } catch (e) {
      print('Failed to sync FCM token: $e');
    }
  }
}
