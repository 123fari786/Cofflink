import 'dart:convert';

import 'package:cofeelink/services/getservices.dart';
import 'package:http/http.dart' as http;

class SendNotificationService {
  static Future<void> sendnotificationusingApi({
    required String? token,
    required String? title,
    required String? body,
    required Map<String, dynamic>? data,
  }) async {
    try {
      String serverkey = await GetServiceKey().getServiceToken();
      print("notification server key=>${serverkey}");

      // Use FCM HTTP v1 API
      String url =
          "https://fcm.googleapis.com/v1/projects/cofflink-11119/messages:send";

      var header = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverkey',
      };

      // Proper FCM v1 message structure
      Map<String, dynamic> message = {
        "message": {
          "token": token,
          "notification": {
            "body": body,
            "title": title,
            "image":
                "https://your-image-url.com/logo.png", // Optional: add logo image
          },
          "data": data,
          "android": {
            "priority": "high",
            "notification": {
              "sound": "default",
              "channel_id": "cofeelink_chat_channel", // Match channel ID
              "icon": "@mipmap/ic_launcher",
              "color": "#2196F3",
              "tag": "chat_message_${DateTime.now().millisecondsSinceEpoch}",
            },
          },
          "apns": {
            "payload": {
              "aps": {
                "sound": "default",
                "badge": 1,
                "alert": {
                  "body": body,
                  "title": title,
                  "subtitle": "Chat Message",
                },
              },
            },
          },
          "webpush": {
            "headers": {"Urgency": "high"},
          },
        },
      };
      final http.Response response = await http.post(
        Uri.parse(url),
        headers: header,
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print("✅ Notification Send Successfully");
        print("Response: ${response.body}");
      } else {
        print("❌ Notification not sent. Status: ${response.statusCode}");
        print("Response: ${response.body}");
      }
    } catch (e) {
      print("🔥 Error sending notification: $e");
    }
  }
}
