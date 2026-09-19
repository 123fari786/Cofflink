// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class Chatscreen extends StatefulWidget {
//   final String? initialUserId;
//   final String? initialUserName;

//   const Chatscreen({this.initialUserId, this.initialUserName, Key? key})
//     : super(key: key);

//   @override
//   State<Chatscreen> createState() => _ChatscreenState();
// }

// class _ChatscreenState extends State<Chatscreen> with WidgetsBindingObserver {
//   User? loginuser;
//   bool _initialUserSelected = false;

//   final auth = FirebaseAuth.instance;
//   TextEditingController msg = TextEditingController();
//   final storemessage = FirebaseFirestore.instance;
//   Map? map;
//   String? userdata;

//   String? selectedUserId;
//   String? selectedUserName;

//   void getCurrentUser() {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       setState(() {
//         loginuser = user;
//       });
//       updateuser("online"); // Set status after user is loaded
//     }
//   }

//   void updateuser(String status) async {
//     if (loginuser == null) {
//       print("User not available yet, skipping status update.");
//       return;
//     }

//     try {
//       await FirebaseFirestore.instance
//           .collection("users")
//           .doc(loginuser!.uid)
//           .update({"status": status});

//       print("Status updated to: $status");
//     } catch (e) {
//       print("Error updating status: $e");
//     }
//   }

//   userData() async {
//     if (loginuser != null) {
//       await FirebaseFirestore.instance
//           .collection("users")
//           .doc(loginuser!.uid)
//           .get()
//           .then((value) {
//             setState(() {
//               map = value.data();
//               userdata = map?['status'];
//             });
//           });
//     }
//   }

//   String getChatId(String uid1, String uid2) {
//     final sorted = [uid1, uid2]..sort();
//     return "${sorted[0]}_${sorted[1]}";
//   }

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     getCurrentUser();
//     userData();
//     if (widget.initialUserId != null) {
//       selectedUserId = widget.initialUserId;
//       selectedUserName = widget.initialUserName;
//       _initialUserSelected = true;
//     }

//     Future.delayed(const Duration(milliseconds: 100), () {
//       updateuser("online");
//     });
//   }

//   @override
//   void dispose() {
//     updateuser("offline");
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     print("App lifecycle changed: $state");

//     switch (state) {
//       case AppLifecycleState.resumed:
//         updateuser("online");
//         break;
//       case AppLifecycleState.paused:
//       case AppLifecycleState.inactive:
//       case AppLifecycleState.detached:
//         updateuser("offline");
//         break;
//       case AppLifecycleState.hidden:
//         // No need to handle this for mobile
//         break;
//     }
//   }

//   Future<void> _markMessagesAsRead(List<QueryDocumentSnapshot> messages) async {
//     if (selectedUserId == null || loginuser == null) return;

//     final batch = FirebaseFirestore.instance.batch();
//     final chatId = getChatId(loginuser!.uid, selectedUserId!);
//     bool needsUpdate = false;

//     for (var message in messages) {
//       final data = message.data() as Map<String, dynamic>;

//       // Mark messages sent to me as read
//       if (data["receiverId"] == loginuser!.uid &&
//           (data["isRead"] == null || data["isRead"] == false)) {
//         batch.update(
//           FirebaseFirestore.instance
//               .collection("chats")
//               .doc(chatId)
//               .collection("messages")
//               .doc(message.id),
//           {"isRead": true},
//         );
//         needsUpdate = true;
//       }
//     }

//     if (needsUpdate) {
//       await batch.commit();
//     }
//   }

//   Widget _buildMessageStatus(bool isMe, bool isRead) {
//     if (!isMe) return SizedBox(); // Only show status for my messages

//     return Padding(
//       padding: const EdgeInsets.only(left: 4.0),
//       child: Icon(
//         Icons.done_all,
//         size: 16,
//         color: isRead ? Colors.blue : Colors.grey,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (loginuser == null) {
//       return Scaffold(body: Center(child: Text("Not for Any User Login")));
//     }

//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         toolbarHeight: 80,
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(left: 5.0, top: 12.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text("Live", style: TextStyle(fontSize: 18)),
//                   Text(
//                     "Chat",
//                     style: GoogleFonts.poly(
//                       fontSize: 32,
//                       color: Colors.blue,
//                       fontStyle: FontStyle.italic,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.only(top: 8.0, right: 8.0),
//               child: IconButton(
//                 icon: Icon(Icons.notifications_none),
//                 onPressed: () {
//                   // Handle bell press here
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),

//       body: Padding(
//         padding: const EdgeInsets.only(top: 10, left: 8),
//         child: Column(
//           children: [
//             SizedBox(
//               height: 80,
//               child: StreamBuilder(
//                 stream:
//                     FirebaseFirestore.instance
//                         .collection("users")
//                         .orderBy("status", descending: true)
//                         .snapshots(),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) {
//                     return Center(child: CircularProgressIndicator());
//                   }

//                   var users =
//                       snapshot.data!.docs
//                           .where((user) => user.id != loginuser!.uid)
//                           .toList();

//                   if (!_initialUserSelected && users.isNotEmpty) {
//                     var firstUser = users.first;
//                     selectedUserId = firstUser.id;
//                     selectedUserName = firstUser["username"] ?? "User";
//                     _initialUserSelected = true;
//                   }

//                   return ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     itemCount: users.length,
//                     itemBuilder: (context, i) {
//                       var user = users[i];
//                       String status = user["status"] ?? "offline";
//                       bool isSelected = selectedUserId == user.id;

//                       return GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             selectedUserId = user.id;
//                             selectedUserName = user["username"] ?? "User";
//                           });
//                         },
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 8),
//                           child: Column(
//                             children: [
//                               Stack(
//                                 children: [
//                                   Container(
//                                     padding:
//                                         isSelected
//                                             ? EdgeInsets.all(2.5)
//                                             : EdgeInsets.zero,
//                                     decoration: BoxDecoration(
//                                       shape: BoxShape.circle,
//                                       border: Border.all(
//                                         color:
//                                             isSelected
//                                                 ? (status == "online"
//                                                     ? Colors.green
//                                                     : Colors.red)
//                                                 : Colors.transparent,
//                                         width: 2,
//                                       ),
//                                     ),
//                                     child: CircleAvatar(
//                                       radius: 22,
//                                       backgroundImage: AssetImage(
//                                         "assets/Alex.png",
//                                       ),
//                                     ),
//                                   ),
//                                   Positioned(
//                                     right: 0,
//                                     top: 0,
//                                     child: Container(
//                                       width: 12,
//                                       height: 12,
//                                       decoration: BoxDecoration(
//                                         color:
//                                             status == "online"
//                                                 ? Colors.green
//                                                 : Colors.red,
//                                         shape: BoxShape.circle,
//                                         border: Border.all(
//                                           color: Colors.white,
//                                           width: 2,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 user["username"] ?? "Unknown",
//                                 style: TextStyle(fontSize: 12),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),

//             Expanded(
//               child:
//                   selectedUserId == null
//                       ? Center(child: Text("Select a user to start chat"))
//                       : StreamBuilder(
//                         stream:
//                             FirebaseFirestore.instance
//                                 .collection("chats")
//                                 .doc(getChatId(loginuser!.uid, selectedUserId!))
//                                 .collection("messages")
//                                 .orderBy("timestamp", descending: false)
//                                 .snapshots(),
//                         builder: (context, snapshot) {
//                           if (!snapshot.hasData) {
//                             return Center(child: CircularProgressIndicator());
//                           }
//                           // Mark messages as read when they're viewed
//                           WidgetsBinding.instance.addPostFrameCallback((_) {
//                             _markMessagesAsRead(snapshot.data!.docs);
//                           });
//                           var messages = snapshot.data!.docs;

//                           if (messages.isEmpty) {
//                             return Center(child: Text("No messages yet"));
//                           }

//                           return ListView.builder(
//                             itemCount: messages.length,
//                             itemBuilder: (context, index) {
//                               var msgData = messages[index].data();
//                               bool isMe = msgData["senderId"] == loginuser!.uid;
//                               bool isRead = msgData["isRead"] ?? false;

//                               return Align(
//                                 alignment:
//                                     isMe
//                                         ? Alignment.centerRight
//                                         : Alignment.centerLeft,
//                                 child: Container(
//                                   margin: EdgeInsets.symmetric(
//                                     vertical: 4,
//                                     horizontal: 10,
//                                   ),
//                                   padding: EdgeInsets.all(10),
//                                   decoration: BoxDecoration(
//                                     color:
//                                         isMe
//                                             ? Colors.blue[100]
//                                             : Colors.grey[300],
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Text(msgData["message"]),
//                                       // _buildMessageStatus(isMe, isRead),
//                                       if (isMe) // Only show status for your own messages
//                                         Padding(
//                                           padding: const EdgeInsets.only(
//                                             left: 4.0,
//                                           ),
//                                           child: Icon(
//                                             Icons.done_all,
//                                             size: 16,
//                                             color:
//                                                 isRead
//                                                     ? const Color.fromARGB(
//                                                       255,
//                                                       157,
//                                                       255,
//                                                       0,
//                                                     )
//                                                     : const Color.fromARGB(
//                                                       255,
//                                                       158,
//                                                       158,
//                                                       158,
//                                                     ),
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           );
//                         },
//                       ),
//             ),

//             if (selectedUserId != null)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 10),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: msg,
//                         decoration: InputDecoration(
//                           hintText: "Enter Message...",
//                           hintStyle: TextStyle(color: Colors.grey),
//                           filled: true,
//                           fillColor: Colors.white,
//                           contentPadding: EdgeInsets.symmetric(
//                             vertical: 14,
//                             horizontal: 20,
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(30),
//                             borderSide: BorderSide(
//                               color: const Color.fromARGB(255, 23, 47, 66),
//                             ),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(30),
//                             borderSide: BorderSide(
//                               color: Colors.blue,
//                               width: 1.5,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.send),
//                       onPressed: () async {
//                         if (msg.text.trim().isNotEmpty &&
//                             loginuser != null &&
//                             selectedUserId != null) {
//                           final chatId = getChatId(
//                             loginuser!.uid,
//                             selectedUserId!,
//                           );

//                           // Add the message
//                           await FirebaseFirestore.instance
//                               .collection("chats")
//                               .doc(chatId)
//                               .collection("messages")
//                               .add({
//                                 "senderId": loginuser!.uid,
//                                 "receiverId": selectedUserId!,
//                                 "message": msg.text.trim(),
//                                 "timestamp": FieldValue.serverTimestamp(),
//                                 "isRead": false, // Initially not read
//                                 "senderName":
//                                     loginuser!.displayName ?? "You", // Optional
//                               });

//                           msg.clear();
//                         }
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';

import "package:badges/badges.dart" as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cofeelink/notification.dart' show Notiftion;
import 'package:cofeelink/notification.dart';
import 'package:cofeelink/services/notification_controller.dart';
import 'package:cofeelink/services/notificationservice.dart';
import 'package:cofeelink/services/send_notification_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class Chatscreen extends StatefulWidget {
  final String? initialUserId;
  final String? initialUserName;

  const Chatscreen({this.initialUserId, this.initialUserName, Key? key})
    : super(key: key);

  @override
  State<Chatscreen> createState() => _ChatscreenState();
}

class _ChatscreenState extends State<Chatscreen> with WidgetsBindingObserver {
  final NotificationController notificationController = Get.put(
    NotificationController(),
  );
  User? loginuser;
  bool _initialUserSelected = false;
  final Notificationservice _notificationService = Notificationservice();
  final ScrollController _scrollController = ScrollController();
  bool _isMounted = false;
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;
  bool _isSendingMessage = false;

  final auth = FirebaseAuth.instance;
  TextEditingController msg = TextEditingController();
  final storemessage = FirebaseFirestore.instance;
  Map? map;
  String? userdata;

  String? selectedUserId;
  String? selectedUserName;
  String? selectedUserDeviceToken;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addObserver(this);

    // Initialize scroll controller
    _scrollController.addListener(() {
      // You can add scroll position tracking if needed
    });

    // Start listening to connectivity changes
    _startConnectivityListener();

    // Get user data first
    getCurrentUser();
    userData();

    if (widget.initialUserId != null) {
      selectedUserId = widget.initialUserId;
      selectedUserName = widget.initialUserName;
      _initialUserSelected = true;
      _getRecipientDeviceToken(widget.initialUserId!);
      _ensureChatExists(widget.initialUserId!);
    }

    // Update user status after a slight delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_isMounted && _isOnline) {
        updateuser("online");
      }
    });

    // Better approach for initial scroll
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_isMounted) return;

      await Future.delayed(const Duration(milliseconds: 100));

      if (_scrollController.hasClients && _isMounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startConnectivityListener() async {
    // Check initial connectivity
    var connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult as ConnectivityResult);

    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) {
            _updateConnectionStatus(result);
          }
          as void Function(List<ConnectivityResult> event)?,
    );
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (!_isMounted) return;

    bool wasOnline = _isOnline;
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });

    // Update user status only when online
    if (_isOnline && loginuser != null) {
      updateuser("online");
    } else if (!_isOnline && wasOnline && loginuser != null) {
      // Don't update to offline here - maintain last status
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  void getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _isMounted) {
      setState(() {
        loginuser = user;
      });
      if (_isOnline) {
        updateuser("online");
      }
    }
  }

  void updateuser(String status) async {
    if (loginuser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(loginuser!.uid)
          .update({"status": status});
    } catch (e) {
      print("Error updating status: $e");
    }
  }

  userData() async {
    if (loginuser != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(loginuser!.uid)
          .get()
          .then((value) {
            if (_isMounted) {
              setState(() {
                map = value.data();
                userdata = map?['status'];
              });
            }
          });
    }
  }

  Future<void> _getRecipientDeviceToken(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userDoc.exists && _isMounted) {
        setState(() {
          selectedUserDeviceToken = userDoc['deviceToken'];
        });
      }
    } catch (e) {
      print("Error getting recipient device token: $e");
    }
  }

  String getChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }

  Future<void> _ensureChatExists(String otherUserId) async {
    if (loginuser == null || !_isOnline) return;

    final chatId = getChatId(loginuser!.uid, otherUserId);
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        'participants': [loginuser!.uid, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _sendPushNotification(String message) async {
    if (!_isOnline) return;

    if (selectedUserDeviceToken == null ||
        selectedUserName == null ||
        loginuser == null) {
      print("Cannot send notification - missing data");
      return;
    }

    try {
      DocumentSnapshot senderDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(loginuser!.uid)
              .get();

      String senderName = senderDoc['username'] ?? 'Someone';
      String chatId = getChatId(loginuser!.uid, selectedUserId!);
      String notificationId = DateTime.now().millisecondsSinceEpoch.toString();

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(selectedUserId)
          .collection('messages')
          .doc(notificationId)
          .set({
            'notificationId': notificationId,
            'senderId': loginuser!.uid,
            'senderName': senderName,
            'message': message,
            'chatId': chatId,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'targetScreen': 'chat',
          });

      await SendNotificationService.sendnotificationusingApi(
        token: selectedUserDeviceToken!,
        title: senderName,
        body: message,
        data: {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "id": "1",
          "status": "done",
          "screen": "chat",
          "senderId": loginuser!.uid,
          "senderName": senderName,
          "chatId": chatId,
          "notificationId": notificationId,
          "type": "message",
        },
      );

      print("✅ Notification sent successfully to $selectedUserName");
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  Future<void> _markMessagesAsRead(List<QueryDocumentSnapshot> messages) async {
    if (selectedUserId == null || loginuser == null || !_isOnline) return;

    final batch = FirebaseFirestore.instance.batch();
    final chatId = getChatId(loginuser!.uid, selectedUserId!);
    bool needsUpdate = false;

    for (var message in messages) {
      final data = message.data() as Map<String, dynamic>;
      if (data["receiverId"] == loginuser!.uid &&
          (data["isRead"] == null || data["isRead"] == false)) {
        batch.update(
          FirebaseFirestore.instance
              .collection("chats")
              .doc(chatId)
              .collection("messages")
              .doc(message.id),
          {"isRead": true},
        );
        needsUpdate = true;
      }
    }

    if (needsUpdate) {
      await batch.commit();
    }
  }

  Future<void> _sendMessage() async {
    // Double-check internet connection before proceeding
    bool hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      setState(() {
        _isOnline = false;
      });
      _showNoInternetError();
      return;
    }

    if (msg.text.trim().isEmpty ||
        loginuser == null ||
        selectedUserId == null) {
      return;
    }

    // Check if already sending
    if (_isSendingMessage) return;

    // Final internet check before sending
    if (!_isOnline) {
      _showNoInternetError();
      return;
    }

    setState(() {
      _isSendingMessage = true;
    });

    final chatId = getChatId(loginuser!.uid, selectedUserId!);
    final message = msg.text.trim();
    msg.clear();

    try {
      // Check one more time before Firestore operation
      hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        _showNoInternetError();
        return;
      }

      await _ensureChatExists(selectedUserId!);

      // Add the message
      await FirebaseFirestore.instance
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .add({
            "senderId": loginuser!.uid,
            "receiverId": selectedUserId!,
            "message": message,
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false,
            "senderName": loginuser!.displayName ?? "You",
          });

      await FirebaseFirestore.instance.collection("chats").doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // Send push notification
      await _sendPushNotification(message);

      // Auto-scroll to bottom after sending
      Future.delayed(Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Show success message
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text("Message sent successfully!"),
      //     backgroundColor: Colors.green,
      //     duration: Duration(seconds: 2),
      //   ),
      // );
    } catch (e) {
      print("Error sending message: $e");
      // Check if error is due to no internet
      if (e.toString().contains('network') ||
          e.toString().contains('internet') ||
          e.toString().contains('connectivity')) {
        setState(() {
          _isOnline = false;
        });
        _showNoInternetError();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send message. Please try again."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isSendingMessage = false;
      });
    }
  }

  void _showNoInternetError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "No internet connection. Please check your network and try again.",
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: () {
            // Check connection again
            _startConnectivityListener();
          },
        ),
      ),
    );
  }

  String _formatMessageTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('hh:mm a').format(date);
  }

  String _formatDateHeader(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> msgData,
    bool isMe,
    String recipientStatus,
  ) {
    bool isRead = msgData["isRead"] ?? false;
    Timestamp? timestamp = msgData["timestamp"];
    String timeText = timestamp != null ? _formatMessageTime(timestamp) : '';

    IconData tickIcon = Icons.check;
    Color tickColor = Colors.grey;

    if (isMe) {
      if (recipientStatus == "offline") {
        tickIcon = Icons.check;
        tickColor = const Color.fromARGB(255, 252, 3, 3);
      } else {
        tickIcon = Icons.done_all;
        tickColor =
            isRead
                ? const Color.fromARGB(255, 115, 255, 0)
                : const Color.fromARGB(255, 255, 0, 0);
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) Expanded(child: SizedBox()),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isMe
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                        : Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msgData["message"],
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        timeText,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      if (isMe) SizedBox(width: 4),
                      if (isMe) Icon(tickIcon, size: 12, color: tickColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loginuser == null) {
      return Scaffold(body: Center(child: Text("Please login to chat")));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 5.0, top: 1.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Live", style: TextStyle(fontSize: 18)),
                  Text(
                    "Chat",
                    style: GoogleFonts.poly(
                      fontSize: 32,
                      color: Colors.blue,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                StreamBuilder<int>(
                  stream: notificationController.getNotificationCountStream(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;

                    final width = MediaQuery.of(context).size.width;

                    return badges.Badge(
                      showBadge: count > 0,
                      badgeContent: Text(
                        "$count",
                        style: const TextStyle(color: Colors.white),
                      ),
                      position: badges.BadgePosition.topEnd(top: 0, end: 1),
                      child: InkWell(
                        onTap: () {
                          notificationController.markNotificationsAsSeen();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Notiftion(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(width * 0.02),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.notifications_none,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10, left: 8),
        child: Column(
          children: [
            if (!_isOnline)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.red.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You are offline. Connect to internet to send messages.",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(
              height: 80,
              child: StreamBuilder(
                stream:
                    FirebaseFirestore.instance
                        .collection("users")
                        .orderBy("status", descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var users =
                      snapshot.data!.docs
                          .where((user) => user.id != loginuser!.uid)
                          .toList();

                  if (!_initialUserSelected && users.isNotEmpty) {
                    var firstUser = users.first;
                    selectedUserId = firstUser.id;
                    selectedUserName = firstUser["username"] ?? "User";
                    _initialUserSelected = true;
                    _getRecipientDeviceToken(firstUser.id);
                    _ensureChatExists(firstUser.id);
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: users.length,
                    itemBuilder: (context, i) {
                      var user = users[i];
                      String status = user["status"] ?? "offline";
                      bool isSelected = selectedUserId == user.id;

                      return FutureBuilder<DataSnapshot>(
                        future:
                            FirebaseDatabase.instance
                                .ref("users/${user.id}/profileImageUrl")
                                .get(),
                        builder: (context, snapshot) {
                          String? profileImageUrl;
                          if (snapshot.hasData &&
                              snapshot.data!.value != null) {
                            profileImageUrl = snapshot.data!.value.toString();
                          }

                          return GestureDetector(
                            onTap: () {
                              if (_isMounted) {
                                setState(() {
                                  selectedUserId = user.id;
                                  selectedUserName = user["username"] ?? "User";
                                });
                              }
                              _getRecipientDeviceToken(user.id);
                              _ensureChatExists(user.id);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        padding:
                                            isSelected
                                                ? EdgeInsets.all(2.5)
                                                : EdgeInsets.zero,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? (status == "online"
                                                        ? Colors.green
                                                        : Colors.red)
                                                    : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 22,
                                          backgroundColor: Colors.grey.shade300,
                                          child: ClipOval(
                                            child:
                                                (profileImageUrl != null &&
                                                        profileImageUrl
                                                            .isNotEmpty)
                                                    ? Image.network(
                                                      profileImageUrl,
                                                      width: 44,
                                                      height: 44,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Image.asset(
                                                          "assets/Alex.png",
                                                          width: 44,
                                                          height: 44,
                                                          fit: BoxFit.cover,
                                                        );
                                                      },
                                                      loadingBuilder: (
                                                        context,
                                                        child,
                                                        loadingProgress,
                                                      ) {
                                                        if (loadingProgress ==
                                                            null)
                                                          return child;
                                                        return Image.asset(
                                                          "assets/Alex.png",
                                                          width: 44,
                                                          height: 44,
                                                          fit: BoxFit.cover,
                                                        );
                                                      },
                                                    )
                                                    : Image.asset(
                                                      "assets/Alex.png",
                                                      width: 44,
                                                      height: 44,
                                                      fit: BoxFit.cover,
                                                    ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color:
                                                status == "online"
                                                    ? Colors.green
                                                    : Colors.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user["username"] ?? "Unknown",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            Expanded(
              child:
                  selectedUserId == null
                      ? Center(child: Text("Select a user to start chat"))
                      : StreamBuilder(
                        stream:
                            FirebaseFirestore.instance
                                .collection("chats")
                                .doc(getChatId(loginuser!.uid, selectedUserId!))
                                .collection("messages")
                                .orderBy("timestamp", descending: false)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (_isOnline) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _markMessagesAsRead(snapshot.data!.docs);
                            });
                          }

                          if (_scrollController.hasClients &&
                              snapshot.data!.docs.isNotEmpty) {
                            _scrollController.jumpTo(
                              _scrollController.position.maxScrollExtent,
                            );
                          }

                          var messages = snapshot.data!.docs;

                          if (messages.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("No messages yet"),
                                  if (!_isOnline)
                                    Text(
                                      "You are currently offline",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }

                          return StreamBuilder<DocumentSnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(selectedUserId!)
                                    .snapshots(),
                            builder: (context, userSnapshot) {
                              String recipientStatus = "offline";
                              if (userSnapshot.hasData &&
                                  userSnapshot.data!.exists) {
                                recipientStatus =
                                    userSnapshot.data!['status'] ?? "offline";
                              }

                              return ListView.builder(
                                controller: _scrollController,
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  var msgData = messages[index].data();
                                  bool isMe =
                                      msgData["senderId"] == loginuser!.uid;
                                  Timestamp? timestamp = msgData["timestamp"];

                                  bool showDateHeader = false;
                                  if (timestamp != null) {
                                    if (index == 0) {
                                      showDateHeader = true;
                                    } else {
                                      var prevMsgData =
                                          messages[index - 1].data();
                                      Timestamp? prevTimestamp =
                                          prevMsgData["timestamp"];
                                      if (prevTimestamp != null) {
                                        final currentDate = timestamp.toDate();
                                        final prevDate = prevTimestamp.toDate();
                                        showDateHeader =
                                            !(currentDate.year ==
                                                    prevDate.year &&
                                                currentDate.month ==
                                                    prevDate.month &&
                                                currentDate.day ==
                                                    prevDate.day);
                                      }
                                    }
                                  }

                                  return Column(
                                    children: [
                                      if (showDateHeader && timestamp != null)
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            _formatDateHeader(timestamp),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      _buildMessageBubble(
                                        msgData,
                                        isMe,
                                        recipientStatus,
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
            ),
            if (selectedUserId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 8, right: 8),
                child: Column(
                  children: [
                    if (!_isOnline)
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Messages cannot be sent while offline.",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: msg,
                            decoration: InputDecoration(
                              hintText:
                                  _isOnline
                                      ? "Type a message..."
                                      : "Connect to internet to send messages",
                              hintStyle: TextStyle(
                                color:
                                    _isOnline
                                        ? Colors.grey
                                        : Colors.grey.withOpacity(0.5),
                              ),
                              filled: true,
                              fillColor:
                                  _isOnline ? Colors.white : Colors.grey[200],
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 20,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(
                                  color:
                                      _isOnline
                                          ? Color.fromARGB(255, 23, 47, 66)
                                          : Colors.grey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(
                                  color: _isOnline ? Colors.blue : Colors.grey,
                                  width: 1.5,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                            ),
                            maxLines: null,
                            onSubmitted: (value) {
                              if (_isOnline && !_isSendingMessage) {
                                _sendMessage();
                              }
                            },
                            enabled: _isOnline && !_isSendingMessage,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _isOnline && !_isSendingMessage
                                    ? Colors.blue
                                    : Colors.grey,
                          ),
                          child: IconButton(
                            icon:
                                _isSendingMessage
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : Icon(Icons.send, color: Colors.white),
                            onPressed:
                                _isOnline && !_isSendingMessage
                                    ? _sendMessage
                                    : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isMounted = false;

    if (_connectivitySubscription != null) {
      _connectivitySubscription!.cancel();
    }

    if (_isOnline) {
      updateuser("offline");
    }

    WidgetsBinding.instance.removeObserver(this);
    msg.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isMounted) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (_isOnline && loginuser != null) {
          updateuser("online");
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        if (loginuser != null) {
          updateuser("offline");
        }
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
}
