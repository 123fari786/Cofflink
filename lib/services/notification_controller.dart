import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class NotificationController extends GetxController {
  final user = FirebaseAuth.instance.currentUser;

  // Get stream of unread notifications count
  Stream<int> getNotificationCountStream() {
    if (user == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection("notifications")
        .doc(user!.uid)
        .collection("messages")
        .where("isRead", isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark all notifications as seen
  Future<void> markNotificationsAsSeen() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection("notifications")
              .doc(user!.uid)
              .collection("messages")
              .where("isRead", isEqualTo: false)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      print("Error marking notifications as seen: $e");
    }
  }

  // Update unread count manually
  void updateUnreadCount() {
    update(); // This triggers GetX to rebuild observers
  }
}
