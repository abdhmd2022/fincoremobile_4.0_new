/*
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Initialize notification settings for Android & iOS (Darwin)
  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // ✅ Updated initialize method (no more onSelectNotification)
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onNotificationTap(response.payload);
      },
    );
  }

  // ✅ Handle tap on notification
  Future<void> _onNotificationTap(String? payload) async {
    // Handle navigation or logic when user taps notification
    // Example:
    // if (payload != null) print('Notification payload: $payload');
  }

  // ✅ Show notification for inactivity alert
  Future<void> showInactivityNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      '1', // channel ID
      'inactivityCheck', // channel name
      channelDescription: 'Notifies users after 7 days of inactivity',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Inactivity Alert',
      'You have been inactive for 7 days. Tap to open the app.',
      platformDetails,
      payload: 'inactivity_alert',
    );
  }
}
*/
