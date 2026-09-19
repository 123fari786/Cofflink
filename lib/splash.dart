import 'package:cofeelink/home.dart';
import 'package:cofeelink/nextsplash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirstSplash extends StatefulWidget {
  const FirstSplash({super.key});

  @override
  State<FirstSplash> createState() => _FirstSplashState();
}

class _FirstSplashState extends State<FirstSplash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), _handleSplashLogic);
  }

  Future<void> _handleSplashLogic() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // ✅ User is logged in, go to Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
      );
    } else {
      // ❌ Not logged in
      final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

      if (isFirstLaunch) {
        await prefs.setBool('isFirstLaunch', false);
      }

      // Always go to Nextsplash for unauthenticated users
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Nextsplash()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset('assets/backsplash.png', fit: BoxFit.cover),
      ),
    );
  }
}
