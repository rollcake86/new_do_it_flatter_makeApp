import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import 'data/constant.dart';
import 'firebase_options.dart';
import 'view/intro/intro_page.dart';

/// 백그라운드 메시지 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupFlutterNotifications();
  showFlutterNotification(message);
  // 백그라운드에서 다른 Firebase 서비스를 사용하려면 `initializeApp`를 호출해야 합니다.
  print('Handling a background message ${message.messageId}');
}

/// 헤드업 알림을 위한 [AndroidNotificationChannel] 생성
late AndroidNotificationChannel channel;

bool isFlutterLocalNotificationsInitialized = false;

/// Flutter Local Notifications 설정
Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'honey_bee_channel', // 채널 ID
    'SNS 알림', // 채널 이름
    description: '허니비 어플에서 사용하는 SNS 알림입니다', // 채널 설명
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'noti_launch',
        ),
      ),
    );
  }
}

late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await setupFlutterNotifications();
  runApp(const MyApp());
}

String? initialMessage;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _token;

  @override
  void initState() {
    super.initState();
    // 초기 메시지 처리
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      setState(() {
        initialMessage = message?.data.toString();
      });
    });

    // 포그라운드 메시지 리스너
    FirebaseMessaging.onMessage.listen(showFlutterNotification);

    // 앱이 백그라운드에서 열렸을 때의 리스너
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // 필요하다면 특정 화면으로 이동하는 로직 등을 추가할 수 있습니다.
    });

    // FCM 토큰 가져오기
    FirebaseMessaging.instance.getToken().then((String? token) {
      setState(() {
        _token = token;
      });
      print('FCM Token: $token');
      // 이 토큰을 서버에 저장하거나 특정 용도로 사용할 수 있습니다.
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: Constant.APP_NAME,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: IntroPage(),
    );
  }
}

