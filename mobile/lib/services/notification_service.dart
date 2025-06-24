import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class NotificationService {

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  static final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('🔥 Background message received: ${message.messageId}');
    print('🔥 Message data: ${message.data}');
    print('🔥 Message notification: ${message.notification?.title} - ${message.notification?.body}');
    
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
    );

    await _initializeLocalNotification();
    await _showFlutterNotification(message);
  }

  static Future<void> initializeNotification() async {
    print('🔔 Initializing notification service...');
    await _initializeLocalNotification();
    await _getInitialMessage();
    
    // Request permission for iOS
    NotificationSettings settings = await firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    print('🔔 User granted permission: ${settings.authorizationStatus}');
    
    // Get FCM token
    String? token = await firebaseMessaging.getToken();
    print('🔔 FCM Token: $token');
    
    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Foreground message received: ${message.messageId}');
      print('🔔 Message data: ${message.data}');
      print('🔔 Message notification: ${message.notification?.title} - ${message.notification?.body}');
      _showFlutterNotification(message);
    });
    
    // Listen to message opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Message opened from background: ${message.messageId}');
      print('🔔 Message data: ${message.data}');
    });
  }

  static Future<void> _showFlutterNotification(RemoteMessage message) async {
    print('🔔 Showing local notification...');
    RemoteNotification? notification = message.notification;
    Map<String, dynamic>? data = message.data;

    String? title = notification?.title ?? data['title'] ?? 'No Title';
    String? body = notification?.body ?? data['body'] ?? 'No Body';

    print('🔔 Notification title: $title');
    print('🔔 Notification body: $body');

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'CHANNEL_ID',
        'CHANNEL_NAME',
        channelDescription: 'Notification channel for basic test',
        importance: Importance.high,
        priority: Priority.high,
        
    );

    DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await flutterLocalNotificationsPlugin.show(
          0,
          title,
          body,
          notificationDetails,
      );
      print('🔔 Local notification shown successfully');
    } catch (e) {
      print('🔔 Error showing local notification: $e');
    }
    
  }

  static Future<void> _initializeLocalNotification() async {
    print('🔔 Initializing local notifications...');
    const AndroidInitializationSettings androidInit = 
        AndroidInitializationSettings('@drawable/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

    final InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    
    try {
      await flutterLocalNotificationsPlugin.initialize(
          initSettings, 
          onDidReceiveNotificationResponse: (NotificationResponse response) {
             print("🔔 User tapped on notification: ${response.payload}");
      });
      print('🔔 Local notifications initialized successfully');
    } catch (e) {
      print('🔔 Error initializing local notifications: $e');
    }
  }

  static Future<void> _getInitialMessage() async {
    print('🔔 Getting initial message...');
    RemoteMessage? message = await firebaseMessaging.getInitialMessage();

    if (message != null) {
        print("🔔 App launched from terminated state via notification: ${message.data}");
    } else {
        print("🔔 No initial message found");
    }
  }
}