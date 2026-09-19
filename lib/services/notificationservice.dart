import 'dart:convert';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:cofeelink/notification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class Notificationservice {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  void requestnotificationpermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
      badge: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("user granted permission");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print("user provisional granted permission");
    } else {
      Get.snackbar(
        'Notification permission denied',
        "Please allow notifications to receive updates.",
        snackPosition: SnackPosition.BOTTOM,
      );
      Future.delayed(Duration(seconds: 3), () {
        AppSettings.openAppSettings(type: AppSettingsType.notification);
      });
    }
  }

  Future<String> getDeviceToken() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    String? token = await messaging.getToken();
    print("token=>$token");
    return token!;
  }
}

// Initialize notification
void initLocalNotification(BuildContext context, RemoteMessage message) async {
  // For Android: Use the launcher icon or a custom notification icon
  var androidInitSetting = const AndroidInitializationSettings(
    '@mipmap/ic_launcher', // This should match your app icon
  );

  // For iOS
  var iosInitSetting = const DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    defaultPresentAlert: true,
    defaultPresentBadge: true,
    defaultPresentSound: true,
  );

  var initializationSettings = InitializationSettings(
    android: androidInitSetting,
    iOS: iosInitSetting,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (payload) {
      handleMessage(context, message);
    },
  );
}

// Firebase init
void Firebaseinit(BuildContext context) {
  FirebaseMessaging.onMessage.listen((message) {
    RemoteNotification? notification = message.notification;

    if (kDebugMode) {
      print("Notification Title: ${notification!.title}");
      print("Notification Body: ${notification.body}");
      print("Notification Data: ${message.data}");
    }

    if (Platform.isIOS) {
      iosForegroundMessage();
    }

    if (Platform.isAndroid) {
      // First initialize the local notifications
      initLocalNotification(context, message);
      // Then show the notification
      Shownotification(message);
    }
  });
}

// Function to show notification
Future<void> Shownotification(RemoteMessage message) async {
  try {
    // Channel ID - this should be unique for your app
    const String channelId = 'cofeelink_chat_channel';
    const String channelName = 'Chat Notifications';
    const String channelDescription = 'Notifications for chat messages';

    // Create Android Notification Channel (required for Android 8.0+)
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      showBadge: true,
      ledColor: Colors.blue,
    );

    // Create channel (only needs to be done once)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Android Notification Details
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          channel.id, // Use the channel ID
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: channel.sound,
          ticker: 'New message',
          color: const Color(
            0xFF2196F3,
          ), // Use Color value instead of resource reference
          icon: '@mipmap/ic_launcher', // Make sure this matches your app icon
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(
            message.notification?.body ?? '',
            htmlFormatBigText: true,
            contentTitle: message.notification?.title ?? 'New Message',
            htmlFormatContentTitle: true,
            summaryText: 'Chat message',
            htmlFormatSummaryText: true,
          ),
          autoCancel: true,
          ongoing: false,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.message,
          actions: [
            AndroidNotificationAction(
              'reply',
              'Reply',
              showsUserInterface: true,
            ),
          ],
        );

    // iOS Notification Details
    DarwinNotificationDetails darwinNotificationDetails =
        const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          badgeNumber: 1,
          subtitle: 'New message',
          threadIdentifier: 'chat-messages',
          categoryIdentifier: 'message',
        );

    // Merge Notification Details
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    // Generate a unique notification ID
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      100000,
    );

    // Show Notification
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? 'You have a new message',
      notificationDetails,
      payload: jsonEncode(message.data), // Pass the data as payload
    );

    if (kDebugMode) {
      print('✅ Notification shown successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error showing notification: $e');
    }
  }
}

// Background and terminated services
Future<void> setupinteractmessage(BuildContext context) async {
  // When app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((event) {
    handleMessage(context, event);
  });

  // When app is terminated
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null && message.data.isNotEmpty) {
      handleMessage(context, message);
    }
  });
}

// Handle message
Future<void> handleMessage(BuildContext context, RemoteMessage message) async {
  // Navigate to notification screen or chat screen based on data
  if (message.data['screen'] == 'chat') {
    // Navigate to specific chat
    // You might need to extract chatId from message.data
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Notiftion()),
    );
  }
}

Future iosForegroundMessage() async {
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}
