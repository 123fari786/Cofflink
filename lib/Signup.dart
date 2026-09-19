import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cofeelink/Login.dart';
import 'package:cofeelink/services/notificationservice.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Future<void> _signupWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;
    Notificationservice notificationservice = Notificationservice();
    String userDevicetoken = await notificationservice.getDeviceToken() ?? '';
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Create user with email and password
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      User? user = userCredential.user;

      if (user != null) {
        // Save user to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'status': 'online',
          'profileImageUrl': '',
          'created_at': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'deviceToken': userDevicetoken, // ✅ Save token here
        });

        // Close loading dialog
        Navigator.of(context).pop();

        // Show success dialog for 3 seconds
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            Future.delayed(const Duration(seconds: 3), () {
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop(); // Close dialog
              }
            });

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.greenAccent.shade700,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Successfully Registered',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        // Navigate to Login after dialog closes
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      } else {
        errorMessage = 'Error occurred: ${e.message}';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Image.asset('assets/back.png', fit: BoxFit.contain),
              ),
            ),
            SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth < 400 ? 16 : 24,
                      vertical: 16,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back button
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Welcome to',
                            style: GoogleFonts.poly(
                              fontSize: 32,
                              color: Colors.blue,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          Text(
                            'Cofflink',
                            style: GoogleFonts.poly(
                              fontSize: 34,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Sign up',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Username
                          _buildTextField(
                            label: "Username",
                            hint: "Enter username",
                            controller: usernameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Username is required";
                              } else if (!RegExp(
                                r'^[a-zA-Z0-9_]+$',
                              ).hasMatch(value)) {
                                return "Only letters, numbers, and _ allowed";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email
                          _buildTextField(
                            label: "Email",
                            hint: "Enter email here",
                            controller: emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Email is required";
                              } else if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return "Enter a valid email";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _buildTextField(
                            label: "Password",
                            hint: "Enter password",
                            controller: passwordController,
                            obscure: _obscurePassword,
                            toggleVisibility:
                                () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Password is required";
                              } else if (value.length < 8 ||
                                  !RegExp(r'\d').hasMatch(value)) {
                                return "Min 8 chars and include numbers";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          _buildTextField(
                            label: "Confirm Password",
                            hint: "Re-enter password",
                            controller: confirmPasswordController,
                            obscure: _obscureConfirmPassword,
                            toggleVisibility:
                                () => setState(
                                  () =>
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Confirm password is required";
                              } else if (value != passwordController.text) {
                                return "Passwords do not match";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _signupWithEmailPassword();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text(
                                'Signup',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Terms text
                          Center(
                            child: Text.rich(
                              TextSpan(
                                text:
                                    'By continuing with the registration, you are accepting our ',
                                style: const TextStyle(fontSize: 12),
                                children: [
                                  TextSpan(
                                    text: 'terms and conditions',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
    VoidCallback? toggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon:
                toggleVisibility != null
                    ? IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: toggleVisibility,
                    )
                    : null,
          ),
        ),
      ],
    );
  }
}
