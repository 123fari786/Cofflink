// import 'package:cofeelink/splashsignup.dart';
// import 'package:flutter/material.dart';

// class Nextsplash extends StatefulWidget {
//   const Nextsplash({super.key});

//   @override
//   State<Nextsplash> createState() => _NextsplashState();
// }

// class _NextsplashState extends State<Nextsplash> {
//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Increased image height (75% of screen height)
//             SizedBox(
//               height: screenHeight * 0.85,
//               child: Center(
//                 child: Image.asset(
//                   'assets/NextSplash.png',
//                   fit: BoxFit.contain,
//                 ),
//               ),
//             ),

//             // Next Button
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20.0),
//               child: SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const Splash()),
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: const Text(
//                     'Next',
//                     style: TextStyle(fontSize: 16, color: Colors.white),
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:cofeelink/splashsignup.dart';
import 'package:flutter/material.dart';

class Nextsplash extends StatefulWidget {
  const Nextsplash({super.key});

  @override
  State<Nextsplash> createState() => _NextsplashState();
}

class _NextsplashState extends State<Nextsplash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Splash()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Image.asset(
            'assets/1000.png',
            fit: BoxFit.contain, // or BoxFit.fitWidth
            width:
                MediaQuery.of(context).size.width * 0.97, // 80% of screen width
            height: MediaQuery.of(context).size.height * 0.99, // 100% height
          ),
        ),
      ),
    );
  }
}
