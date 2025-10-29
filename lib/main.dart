// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:FincoreGo/Constants.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'SharedPreferencesService.dart';
import 'SplashScreen.dart';

// 🔔 Local Notification Plugin
/*final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();*/

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferencesService.init();
  /*await Firebase.initializeApp();*/

  // await _initializeLocalNotifications();
  // await _setupFirebaseMessaging();

  runApp(const MyApp());
}

// ✅ Local notifications setup (for Android & iOS)
/*
Future<void> _initializeLocalNotifications() async {
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

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint('🔔 Notification tapped → ${response.payload}');
    },
  );
}
*/

// ✅ Firebase Messaging setup
/*
Future<void> _setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission (iOS only)
  await requestPermission();

  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // When app is opened from a terminated state by tapping a notification
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      showNotification(message);
    }
  });

  // Foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    showNotification(message);
  });
}

// ✅ Display a local notification
Future<void> showNotification(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;
  if (notification != null) {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      '1',
      'fincore',
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
      notification.title,
      notification.body,
      platformDetails,
      payload: 'item x',
    );
  }
}

// ✅ Background notification handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  showNotification(message);
}

// ✅ iOS permission request
Future<void> requestPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint('✅ User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    debugPrint('⚠️ User granted provisional permission');
  } else {
    debugPrint('❌ User declined or has not accepted permission');
  }
}
*/

// ✅ App lifecycle tracking
@override
void didChangeAppLifecycleState(AppLifecycleState state) async {
  if (state == AppLifecycleState.hidden ||
      state == AppLifecycleState.paused ||
      state == AppLifecycleState.detached ||
      state == AppLifecycleState.inactive) {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('lastActive', DateTime.now().millisecondsSinceEpoch);
  }
}

// ✅ Root widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      title: 'Fincore Go',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // 👇 Add this block to change the global CircularProgressIndicator color
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: app_color, // change to your preferred color
          circularTrackColor: Colors.white, // optional
        ),
        // 👇 Change focus, cursor, splash, and highlight colors globally
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
          secondary: app_color, // for older Material widgets
        ),
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: app_color, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          labelStyle: TextStyle(color: Colors.black54),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: app_color,          // blinking cursor
          selectionColor: Color(0x332196F3), // text highlight
          selectionHandleColor: app_color, // handle color
        ),
        splashColor: app_color.withOpacity(0.2), // ripple effect
        highlightColor: Colors.transparent,        // optional, removes default purple glow
      ),


      home:  SplashScreen(),
    );
  }
}
