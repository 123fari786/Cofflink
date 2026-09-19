import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import "package:badges/badges.dart" as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cofeelink/Editprofile.dart';
import 'package:cofeelink/chat.dart';
import 'package:cofeelink/notification.dart';
import 'package:cofeelink/services/notification_controller.dart';
import 'package:cofeelink/services/notificationservice.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  Notificationservice notificationService = Notificationservice();
  int currentIndex = 0;

  final List<Widget> screens = [
    const HomeScreenContent(),
    Chatscreen(),
    const Editprofile(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeNotifications();

    // Setup Firebase messaging
    Firebaseinit(context);
    setupinteractmessage(context);
  }

  Future<void> _initializeNotifications() async {
    // Request notification permissions
    notificationService.requestnotificationpermission();

    // Get device token
    String? token = await notificationService.getDeviceToken();

    // Save device token to Firestore for current user
    if (token != null && FirebaseAuth.instance.currentUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
            'deviceToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });
      print("Device token saved to Firestore: $token");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'status': 'online',
          'lastActive': FieldValue.serverTimestamp(),
        });
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'status': 'offline',
          'lastActive': FieldValue.serverTimestamp(),
        });
        break;

      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'status': 'offline',
        'lastActive': FieldValue.serverTimestamp(),
      });
    }

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ Move build() here inside the _HomeState class
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        backgroundColor:
            Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).unselectedWidgetColor,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/home.png',
              width: width * 0.06,
              height: width * 0.06,
              color:
                  currentIndex == 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).iconTheme.color,
            ),
            label: 'Flight',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/chat.png',
              width: width * 0.08,
              height: width * 0.08,
              color:
                  currentIndex == 1
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).iconTheme.color,
            ),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/profile.png',
              width: width * 0.06,
              height: width * 0.06,
              color:
                  currentIndex == 2
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).iconTheme.color,
            ),
            label: 'Profile',
          ),
        ],
      ),
      body: SafeArea(child: screens[currentIndex]),
    );
  }
}

class AppUser {
  final String name;
  final bool isOnline;
  final LatLng position;
  final String? flightNumber;
  final String? seatNumber;
  final String userId;
  final String? profileImageUrl;

  AppUser({
    required this.name,
    required this.isOnline,
    required this.position,
    this.flightNumber,
    this.seatNumber,
    required this.userId,
    this.profileImageUrl,
  });
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent>
    with WidgetsBindingObserver {
  final NotificationController notificationController = Get.put(
    NotificationController(),
  );

  late NearbyService nearbyService;
  late StreamSubscription<List<Device>> deviceSubscription;
  List<Device> visibleDevices = [];
  String? userStatus;

  String userName = "Guest";
  LatLng? _currentPosition;
  // To this:
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controller = Completer();
  bool _isMapReady = false;
  LatLng? _fallbackPosition;
  final Set<Marker> _markers = {};
  final List<AppUser> _appUsers = [];
  Timer? _locationTimer;
  final databaseRef = FirebaseDatabase.instance.ref("users");
  Map<String, dynamic>? flightDetails;
  bool _isLoadingFlight = false;
  String? _flightError;
  String? _seatNumber;
  String? currentUserId;
  User? loginuser;

  @override
  void initState() {
    super.initState();
    loginuser = FirebaseAuth.instance.currentUser;
    WidgetsBinding.instance.addObserver(this); // ← Add this line
    // Initialize notifications first
    _initNotifications();

    initNearbyDiscovery();
    _loadUserName();
    _getCurrentLocation();
    _fetchUsers();
    _startLocationUpdates();
    _loadFlightDetails();

    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (currentUserId != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({'lastActive': FieldValue.serverTimestamp()});
      }
    });
    updateuser('online');
    _fallbackPosition = const LatLng(37.7749, -122.4194); // San Francisco
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  void _initializeMap() async {
    try {
      // Ensure location is obtained
      await _getCurrentLocation();

      // Add a small delay to ensure map controller is ready
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          _isMapReady = true;
        });
        _updateMarkers();
      }
    } catch (e) {
      print("Map initialization error: $e");
      if (mounted) {
        setState(() {
          _isMapReady = true;
          _currentPosition = _fallbackPosition;
        });
      }
    }
  }

  void _initNotifications() async {
    // Ensure device token is saved for current user
    if (loginuser != null) {
      final token = await Notificationservice().getDeviceToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(loginuser!.uid)
            .update({'deviceToken': token});
        print("Device token saved for user: $token");
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("Lifecycle state: $state");

    switch (state) {
      case AppLifecycleState.resumed:
        // User came back to the app
        updateuser("online");
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // User left the app (background, switch, or closed)
        updateuser("offline");
        break;

      // AppLifecycleState.hidden is only for web — can ignore on mobile
      case AppLifecycleState.hidden:
        break;
    }
  }

  // updateuser(String status) async {
  //   print("Setting user status to: $status");

  //   if (loginuser != null) {
  //     await FirebaseFirestore.instance
  //         .collection("users")
  //         .doc(loginuser!.uid)
  //         .update({"status": status});
  //   }
  // }

  Future<void> updateuser(String status) async {
    final uid = loginuser?.uid; // <— single source of truth
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'status': status,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _loadUserStatus() async {
    if (currentUserId != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(currentUserId)
              .get();
      setState(() {
        userStatus = doc.data()?['status'] ?? "offline";
      });
    }
  }

  // Future<void> _loadUserName() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final name = prefs.getString('name');
  //   final userId = prefs.getString('userId');

  //   if (name != null && name.isNotEmpty && userId != null) {
  //     setState(() {
  //       userName = name;
  //       currentUserId = userId;
  //     });

  //     // Update user's online status and last active time
  //     await FirebaseFirestore.instance.collection('users').doc(userId).update({
  //       'status': 'online',
  //       'lastActive': FieldValue.serverTimestamp(),
  //     });
  //   }
  // }
  Future<void> _loadUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final ref = FirebaseDatabase.instance.ref("users/${user.uid}");
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          userName = (data['name'] ?? 'Guest').toString();
          currentUserId = user.uid;
        });

        // Update user's online status and last active time
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'status': 'online',
              'lastActive': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      print("Error loading user data: $e");
      // Fallback to SharedPreferences if needed
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name');
      final userId = prefs.getString('userId');

      if (name != null && name.isNotEmpty && userId != null) {
        setState(() {
          userName = name;
          currentUserId = userId;
        });
      }
    }
  }

  void _fetchUsers() {
    FirebaseFirestore.instance.collection('users').snapshots().listen((
      snapshot,
    ) {
      if (currentUserId == null) return;

      final List<AppUser> users = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lastActive = data['lastActive'] as Timestamp?;
        final isOnline =
            lastActive != null &&
            DateTime.now().difference(lastActive.toDate()).inMinutes < 5;

        // Skip own user
        if (doc.id != currentUserId) {
          final double lat =
              double.tryParse(data['latitude']?.toString() ?? '0') ?? 0;
          final double lng =
              double.tryParse(data['longitude']?.toString() ?? '0') ?? 0;

          users.add(
            AppUser(
              name: data['username'] ?? 'Unknown',
              isOnline: isOnline,
              position: LatLng(lat, lng),
              flightNumber: data['flightNumber'],
              seatNumber: data['seatNumber'],
              userId: doc.id,
              profileImageUrl: data['profileImageUrl'],
            ),
          );
        }
      }

      setState(() {
        _appUsers.clear();
        _appUsers.addAll(users);
      });

      _updateMarkers();
    });
  }

  Widget _buildNearbyUsers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 70,
          child: StreamBuilder(
            stream:
                FirebaseFirestore.instance
                    .collection("users")
                    .where("status", isEqualTo: "online")
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs;

              return ListView.builder(
                itemCount: users.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, i) {
                  var user = users[i];
                  final userId = user.id;

                  if (userId == currentUserId) {
                    return const SizedBox.shrink();
                  }

                  return FutureBuilder<DataSnapshot>(
                    future:
                        FirebaseDatabase.instance
                            .ref("users/$userId/profileImageUrl")
                            .get(),
                    builder: (context, imageSnapshot) {
                      String profileImageUrl = "";

                      if (imageSnapshot.hasData &&
                          imageSnapshot.data!.value != null) {
                        profileImageUrl = imageSnapshot.data!.value.toString();
                      }

                      return GestureDetector(
                        onTap: () {
                          if (userId == currentUserId) {
                            showDialog(
                              context: context,
                              builder:
                                  (_) => AlertDialog(
                                    title: const Text("My Profile"),
                                    content: const Text(
                                      "This is your own profile.",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Close"),
                                      ),
                                    ],
                                  ),
                            );
                          } else {
                            _showUserDialog(userId);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        Theme.of(context).cardColor,
                                    backgroundImage:
                                        profileImageUrl.isNotEmpty
                                            ? NetworkImage(profileImageUrl)
                                            : const AssetImage(
                                              "assets/Alex.png",
                                            ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                ),
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
      ],
    );
  }

  void _showUserDialog(String uid) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == currentUid) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("My Profile"),
              content: const Text("This is your own profile."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            ),
      );
      return;
    }

    try {
      final ref = FirebaseDatabase.instance.ref("users/$uid");
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        print("User data not found in Realtime Database");
        return;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final profileImageUrl = data['profileImageUrl'];
      final userName = data["name"]?.toString() ?? "User";

      // ---------------- FIRST DIALOG (Profile + Start Chat) ----------------
      showDialog(
        context: context,
        barrierDismissible: true,
        builder:
            (_) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2),
                            backgroundImage:
                                profileImageUrl != null &&
                                        profileImageUrl.toString().isNotEmpty
                                    ? NetworkImage(profileImageUrl)
                                    : const AssetImage("assets/Alex.png")
                                        as ImageProvider,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "${data["age"]?.toString() ?? "--"} years old",
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Detail Info
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            icon: Icons.work_outline,
                            label: "Category",
                            value:
                                data["category"]?.toString() ?? "Not specified",
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.transgender,
                            label: "Gender",
                            value:
                                data["gender"]?.toString() ?? "Not specified",
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.flight_takeoff,
                            label: "Traveling to",
                            value:
                                data["travel"]?.toString() ?? "Not specified",
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 15),
                          const Text(
                            "Meet people on the same place wherever you go...",
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context); // close profile dialog

                                // ---------------- SECOND DIALOG (Please Wait) ----------------
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder:
                                      (_) => Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Image.asset(
                                                "assets/pleasewait.png",
                                                height: 180,
                                              ),
                                              const SizedBox(height: 20),
                                              const Text(
                                                "Please Wait",
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              const Text(
                                                "Your request is submitted successfully.",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                );

                                // Auto close after 3s -> show THIRD DIALOG
                                Future.delayed(const Duration(seconds: 3), () {
                                  Navigator.pop(context); // close second dialog

                                  // ---------------- THIRD DIALOG (Congratulations) ----------------
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder:
                                        (_) => Dialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Image.asset(
                                                  "assets/congrats.png",
                                                  height: 180,
                                                ),
                                                const SizedBox(height: 20),
                                                const Text(
                                                  "Congratulations",
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                const Text(
                                                  "Your request is accepted successfully.\nYou can start chat by pressing the below button",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(
                                                      context,
                                                    ); // close dialog
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (_) => Chatscreen(
                                                              initialUserId:
                                                                  uid,
                                                              initialUserName:
                                                                  userName,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blue,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 30,
                                                          vertical: 15,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    "Start Opportunities",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                  );
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Start Chat",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );
    } catch (e) {
      print("Error showing user dialog: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load user profile")),
      );
    }
  }

  // Helper widget for detail rows
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.black)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Separate method for the request submitted dialog
  void _showRequestSubmittedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Request Sent!",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Your chat request has been sent successfully.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "OK",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<BitmapDescriptor> _createCustomMarker(String name) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.blue;
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw the marker circle
    canvas.drawCircle(Offset(50, 50), 30, paint);

    // Add the name text
    textPainter.text = TextSpan(
      text: name,
      style: TextStyle(
        fontSize: 20,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(50 - textPainter.width / 2, 50 - textPainter.height / 2),
    );

    final img = await pictureRecorder.endRecording().toImage(100, 100);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _loadFlightDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    final snapshot = await databaseRef.child(userId).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _seatNumber = data['seatNumber']?.toString();
        if (data['flightDetails'] != null) {
          flightDetails = jsonDecode(data['flightDetails']);
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useFallbackPosition();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useFallbackPosition();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useFallbackPosition();
        return;
      }

      // Directly get position without complex timeout
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
      } catch (e) {
        print("Failed to get location: $e");
        _useFallbackPosition();
        return;
      }

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        _updateMarkers();

        // Save location to Firebase
        await _saveLocationToFirebase(position.latitude, position.longitude);
      }
    } catch (e) {
      print("Error in _getCurrentLocation: $e");
      _useFallbackPosition();
    }
  }

  void _useFallbackPosition() {
    if (mounted) {
      setState(() {
        _currentPosition = _fallbackPosition;
      });
      _updateMarkers();
    }
  }

  Future<void> _saveLocationToFirebase(
    double latitude,
    double longitude,
  ) async {
    if (currentUserId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId!)
            .update({
              'latitude': latitude.toString(),
              'longitude': longitude.toString(),
              'locationUpdated': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        print("Error saving location to Firebase: $e");
      }
    }
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _getCurrentLocation();
    });
  }

  void initNearbyDiscovery() async {
    print('[DEBUG] Initializing Nearby Service...');
    nearbyService = NearbyService();

    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      String devInfo = "Unknown";

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        devInfo = androidInfo.model ?? "Android Device";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        devInfo = iosInfo.utsname.machine ?? "iOS Device";
      }
      print('[DEBUG] Device name: $devInfo');

      await _requestPermissions();

      await nearbyService.init(
        serviceType: 'cofeelink',
        deviceName: devInfo,
        strategy: Strategy.P2P_CLUSTER,
        callback: (isRunning) async {
          print('[DEBUG] Service initialized. Running: $isRunning');
          if (isRunning) {
            print('[DEBUG] Starting advertising...');
            await nearbyService.startAdvertisingPeer();
            print('[DEBUG] Advertising started');

            print('[DEBUG] Starting browsing...');
            await nearbyService.startBrowsingForPeers();
            print('[DEBUG] Browsing started');

            // Add periodic discovery refresh
            Timer.periodic(Duration(seconds: 15), (timer) async {
              print('[DEBUG] Refreshing discovery...');
              await nearbyService.stopBrowsingForPeers();
              await nearbyService.startBrowsingForPeers();
            });
          }
        },
      );

      nearbyService.stateChangedSubscription(
        callback: (devices) {
          print('[DEBUG] Nearby devices updated: ${devices.length} devices');
          for (var device in devices) {
            print(
              ' - ${device.deviceName} (${device.deviceId}): ${device.state}',
            );
          }
          setState(() {
            visibleDevices =
                devices
                    .where((d) => d.state == SessionState.notConnected)
                    .toList();
          });
        },
      );
    } catch (e) {
      print('[ERROR] Bluetooth initialization failed: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 31) {
        // Android 12+
        await [
          Permission.bluetoothScan,
          Permission.bluetoothAdvertise,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse,
        ].request();
      } else if (sdkInt >= 23) {
        // Android 6 to Android 11 (API 23 - 30)
        await [Permission.bluetooth, Permission.locationWhenInUse].request();
      } else {
        // Below Android 6 (rare)
        await Permission.location.request();
      }

      // Check and handle if permission is denied
      if (!await Permission.locationWhenInUse.isGranted) {
        throw Exception('Location permission is required.');
      }
    } else if (Platform.isIOS) {
      await [Permission.bluetooth, Permission.locationWhenInUse].request();

      if (!await Permission.locationWhenInUse.isGranted) {
        throw Exception('Location permission is required.');
      }
    }
  }

  void _updateMarkers() async {
    if (_currentPosition == null || !_isMapReady) return;

    setState(() {
      _markers.clear();
    });

    // Add current user marker
    final currentUserIcon = await _createCustomMarker('You');
    _markers.add(
      Marker(
        markerId: const MarkerId('current_user'),
        position: _currentPosition!,
        icon: currentUserIcon,
        infoWindow: InfoWindow(
          title: userName,
          snippet:
              flightDetails != null
                  ? 'Flight: ${flightDetails!['flight']['iata']}\nSeat: $_seatNumber'
                  : null,
        ),
      ),
    );

    // Add other users' markers
    for (var user in _appUsers) {
      final userIcon = await _createCustomMarker(user.name);
      _markers.add(
        Marker(
          markerId: MarkerId(user.userId),
          position: user.position,
          icon: userIcon,
          infoWindow: InfoWindow(
            title: user.name,
            snippet:
                user.flightNumber != null
                    ? 'Flight: ${user.flightNumber}\nSeat: ${user.seatNumber}'
                    : null,
          ),
        ),
      );
    }

    // Move camera to current position
    if (_mapController != null) {
      try {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, 15),
        );
      } catch (e) {
        print("Error moving camera: $e");
      }
    }
  }

  // Add this to dispose() to mark user as offline when leaving
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // ✅ Clean up

    _locationTimer?.cancel();
    nearbyService.stopBrowsingForPeers();
    nearbyService.stopAdvertisingPeer();

    if (currentUserId != null) {
      FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'status': 'offline',
        'lastActive': FieldValue.serverTimestamp(),
      });
    }

    super.dispose();
  }

  void _showFlightInputDialog() {
    final flightNumberController = TextEditingController();
    final seatNumberController = TextEditingController(text: _seatNumber);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Enter Flight Details"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: flightNumberController,
                      decoration: const InputDecoration(
                        labelText: "Flight Number (e.g., AA123)",
                        hintText: "Enter IATA flight number",
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: seatNumberController,
                      decoration: const InputDecoration(
                        labelText: "Seat Number",
                        hintText: "e.g., 12A",
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingFlight)
                      const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("Fetching flight details..."),
                        ],
                      ),
                    if (_flightError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _flightError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      _isLoadingFlight ? null : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed:
                      _isLoadingFlight
                          ? null
                          : () async {
                            final flightNumber =
                                flightNumberController.text.trim();
                            final seatNumber = seatNumberController.text.trim();

                            if (flightNumber.isEmpty) {
                              setState(() {
                                _flightError = "Please enter a flight number";
                              });
                              return;
                            }

                            setState(() {
                              _isLoadingFlight = true;
                              _flightError = null;
                            });

                            try {
                              // Mock response for testing - remove in production
                              // final mockResponse = {
                              //   "data": [
                              //     {
                              //       "flight": {"iata": flightNumber, "number": "123"},
                              //       "airline": {"name": "Test Airline"},
                              //       "departure": {
                              //         "airport": "Test Departure",
                              //         "iata": "TST",
                              //         "scheduled": "2023-01-01T12:00:00"
                              //       },
                              //       "arrival": {
                              //         "airport": "Test Arrival",
                              //         "iata": "TAR",
                              //         "scheduled": "2023-01-01T14:00:00"
                              //       },
                              //       "flight_status": "scheduled"
                              //     }
                              //   ]
                              // };
                              // await Future.delayed(Duration(seconds: 2)); // Simulate delay
                              // final data = mockResponse;

                              // Real API call
                              const apiKey = 'c62cf1342c239af49e529c746557861c';
                              final url = Uri.parse(
                                'https://api.aviationstack.com/v1/flights?access_key=$apiKey&flight_iata=${flightNumber.toUpperCase()}',
                              );

                              final response = await http.get(url);
                              final data = jsonDecode(response.body);

                              if (response.statusCode == 200) {
                                final flights = data['data'] as List<dynamic>?;

                                if (flights == null || flights.isEmpty) {
                                  setState(() {
                                    _flightError = "No flight found";
                                  });
                                  return;
                                }

                                final flight =
                                    flights[0] as Map<String, dynamic>;

                                // Update main state
                                if (mounted) {
                                  setState(() {
                                    flightDetails = flight;
                                    _seatNumber = seatNumber;
                                  });
                                  await _saveFlightDetailsToFirebase(
                                    flight,
                                    seatNumber,
                                  );
                                  Navigator.pop(context);
                                }
                              } else {
                                setState(() {
                                  _flightError =
                                      "Error: ${response.statusCode}";
                                });
                              }
                            } catch (e) {
                              setState(() {
                                _flightError =
                                    "Failed to load: ${e.toString()}";
                              });
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoadingFlight = false;
                                });
                              }
                            }
                          },
                  child: const Text("Search"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveFlightDetailsToFirebase(
    Map<String, dynamic> flight,
    String seatNumber,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      await databaseRef.child(userId).update({
        'flightNumber': flight['flight']['iata'],
        'flightDetails': jsonEncode(flight),
        'seatNumber': seatNumber,
      });
    }
  }

  Widget buildUserStatus() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Text("User not logged in");
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final username = data['username'] ?? 'Unknown';
        final status = data['status'] ?? 'offline';

        // Get image from SharedPreferences instead of Firestore
        // return FutureBuilder<SharedPreferences>(
        //   future: SharedPreferences.getInstance(),
        //   builder: (context, prefsSnapshot) {
        //     if (!prefsSnapshot.hasData) {
        //       return const Center(child: CircularProgressIndicator());
        //     }

        // final prefs = prefsSnapshot.data!;
        // final imageUrl = prefs.getString('profileImageUrl');
        return StreamBuilder<DatabaseEvent>(
          stream:
              FirebaseDatabase.instance
                  .ref("users/$uid/profileImageUrl")
                  .onValue,
          builder: (context, imageSnapshot) {
            String? imageUrl;

            if (imageSnapshot.hasData &&
                imageSnapshot.data!.snapshot.value != null) {
              imageUrl = imageSnapshot.data!.snapshot.value.toString();
            }
            return Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage:
                          imageUrl != null
                              ? NetworkImage(
                                imageUrl,
                              ) // Use from SharedPreferences
                              : const AssetImage('assets/Alex.png')
                                  as ImageProvider, // Fallback
                      backgroundColor: Colors.grey[300],
                    ),
                    // Status dot (top-left) - remains unchanged
                    Positioned(
                      top: 2,
                      left: 2,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: status == 'online' ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final List<AppUser> nearbyOnlineUsers =
        _appUsers.where((user) {
          if (_currentPosition == null || currentUserId == null) return false;
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            user.position.latitude,
            user.position.longitude,
          );
          return user.userId != currentUserId &&
              user.isOnline &&
              distance <= 1000;
        }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Top icons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _showFlightInputDialog,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          Theme.of(
                            context,
                          ).dividerColor, // Use theme divider color
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color:
                        Theme.of(
                          context,
                        ).cardColor, // Optional: add background color
                  ),
                  padding: EdgeInsets.all(width * 0.02),
                  child: Image.asset(
                    'assets/airplane.png', // Your airplane icon path
                    width: width * 0.05,
                    height: width * 0.05,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
              // InkWell(
              //   onTap: () async {
              //     // //   EasyLoading.show();
              //     // await SendNotificationService.sendnotificationusingApi(
              //     //   token:
              //     //       "fZmIc8soQR-RVE1mxColQt:APA91bFt4XWEv-YYVEqxEMaqB6NzqdiXL_gGmtSJdD6sAu77DqtdshOVAnH1gkE9bnZGIYSifM7ztmbHoBpdtuI5Cpa-2reoGdRirVyACP0ERh_SYcWBfsg",
              //     //   title: "Notification",
              //     //   body: "Notification Body",
              //     //   data: {"screen": "Farhan"},
              //     // );
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => Notiftion()),
              //     );
              //     // EasyLoading.dismiss();
              //   },
              //   child: Container(
              //     decoration: BoxDecoration(
              //       border: Border.all(color: Colors.black),
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //     padding: EdgeInsets.all(width * 0.02),
              //     child: const Icon(
              //       Icons.notifications_none,
              //       color: Colors.black,
              //     ),
              //   ),
              // ),
              // Replace the Obx part in your home screen with this:
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
                          MaterialPageRoute(builder: (context) => Notiftion()),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(width * 0.02),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                Theme.of(
                                  context,
                                ).dividerColor, // Use theme divider color
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.notifications_none,
                          color:
                              Theme.of(
                                context,
                              ).iconTheme.color, // Use theme icon color
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: height * 0.015),

          // 🔹 Greeting + Your Status
          Text(
            'Hello!',
            style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          Text(
            userName,
            style: TextStyle(
              fontSize: 26,
              color: Theme.of(context).colorScheme.primary,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
            ),
          ),
          buildUserStatus(),

          SizedBox(height: height * 0.025),
          Text(
            'Live people near me',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 8),
          _buildNearbyUsers(),
          SizedBox(height: height * 0.025),
          Text(
            'All People location',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: height * 0.01),
          Container(
            height: height * 0.25,
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).dividerColor,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  if (!_isMapReady || _currentPosition == null)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text("Loading Map..."),
                        ],
                      ),
                    ),

                  if (_isMapReady && _currentPosition != null)
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition!,
                        zoom: 15,
                      ),
                      markers: _markers,
                      onMapCreated: (controller) async {
                        // Store controller in both variables
                        setState(() {
                          _mapController = controller;
                        });
                        _controller.complete(controller);

                        // Add small delay to ensure map is fully loaded
                        await Future.delayed(const Duration(milliseconds: 300));
                        _updateMarkers();
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      compassEnabled: true,
                      mapToolbarEnabled: true,
                      // Add these options for better compatibility
                      buildingsEnabled: true,
                      indoorViewEnabled: true,
                      trafficEnabled: false,
                      rotateGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      zoomGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      onCameraIdle: () {
                        // Camera movement complete
                      },
                      onCameraMoveStarted: () {
                        // Camera movement started
                      },
                    ),
                ],
              ),
            ),
          ),

          // 🔹 Flight Details
          if (flightDetails != null) ...[
            SizedBox(height: height * 0.025),
            Text(
              'Flight Information',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: height * 0.01),
            Container(
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FlightDetailRow(
                    label: 'Flight:',
                    value:
                        '${flightDetails!['airline']['name']} (${flightDetails!['flight']['iata']})',
                  ),
                  _FlightDetailRow(
                    label: 'From:',
                    value:
                        '${flightDetails!['departure']['airport']} (${flightDetails!['departure']['iata']})',
                  ),
                  _FlightDetailRow(
                    label: 'To:',
                    value:
                        '${flightDetails!['arrival']['airport']} (${flightDetails!['arrival']['iata']})',
                  ),
                  _FlightDetailRow(
                    label: 'Status:',
                    value: flightDetails!['flight_status'],
                  ),
                  _FlightDetailRow(
                    label: 'Scheduled Departure:',
                    value: flightDetails!['departure']['scheduled'],
                  ),
                  _FlightDetailRow(
                    label: 'Scheduled Arrival:',
                    value: flightDetails!['arrival']['scheduled'],
                  ),
                  if (_seatNumber != null && _seatNumber!.isNotEmpty)
                    _FlightDetailRow(label: 'Your Seat:', value: _seatNumber!),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FlightDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _FlightDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileItem extends StatelessWidget {
  final String? imagePath;
  final String name;
  final bool isOnline;
  final String? flightNumber;
  final String? seatNumber;

  const ProfileItem({
    super.key,
    this.imagePath,
    required this.name,
    required this.isOnline,
    this.flightNumber,
    this.seatNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage:
                    imagePath != null
                        ? NetworkImage(imagePath!)
                        : const AssetImage('assets/Alex.png') as ImageProvider,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            name,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (flightNumber != null) ...[
            const SizedBox(height: 2),
            Text(
              flightNumber!,
              style: const TextStyle(fontSize: 10, color: Colors.blue),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (seatNumber != null) ...[
            const SizedBox(height: 2),
            Text(
              'Seat: $seatNumber',
              style: const TextStyle(fontSize: 10, color: Colors.green),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
