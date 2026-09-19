import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cofeelink/Login.dart';
import 'package:cofeelink/ProfileSection/changeemail.dart';
import 'package:cofeelink/ProfileSection/changepassward.dart';
import 'package:cofeelink/ProfileSection/versioninformation.dart';
import 'package:cofeelink/Rateus.dart';
import 'package:cofeelink/infoscreen.dart';
import 'package:cofeelink/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class Editprofile extends StatefulWidget {
  const Editprofile({super.key});

  @override
  State<Editprofile> createState() => _EditprofileState();
}

class _EditprofileState extends State<Editprofile> {
  String name = "";
  String age = "";
  String gender = "";
  String email = "";
  List<String> categories = []; // Changed from String to List<String>
  String travel = "";
  String profileImageUrl = "";
  bool _isLoading = true;
  bool isAccountSettingsOpen = false;
  bool isAppSettingsOpen = false;
  bool isSupportOpen = false;
  bool isAboutAppOpen = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Future<void> _loadUserData() async {
  //   final prefs = await SharedPreferences.getInstance();

  //   setState(() {
  //     name = prefs.getString('name') ?? 'Not set';
  //     age = prefs.getString('age') ?? 'Not set';
  //     gender = prefs.getString('gender') ?? 'Not set';
  //     email = prefs.getString('email') ?? 'Not set';
  //     categories = prefs.getStringList('categories') ?? ['Not set'];
  //     travel = prefs.getString('travel') ?? 'Not set';
  //     profileImageUrl = prefs.getString('profileImageUrl') ?? '';
  //     _isLoading = false;
  //   });
  // }
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final ref = FirebaseDatabase.instance.ref("users/${user.uid}");
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          name = (data['name'] ?? 'Not set').toString();
          age = (data['age'] ?? 'Not set').toString();
          gender = (data['gender'] ?? 'Not set').toString();
          email = (data['email'] ?? 'Not set').toString();
          categories =
              (data['categories'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              ['Not set'];
          travel = (data['travel'] ?? 'Not set').toString();
          profileImageUrl = (data['profileImageUrl'] ?? '').toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load profile: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isSmallScreen = width < 360;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "View",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        "Profile",
                        style: GoogleFonts.poly(
                          fontSize: isSmallScreen ? 28 : 36,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => Theme(
                              data: Theme.of(context),
                              child: AlertDialog(
                                title: const Text("Logout"),
                                content: const Text(
                                  "Are you sure you want to logout?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await FirebaseAuth.instance.signOut();
                                      Navigator.pop(context);
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const Login(),
                                        ),
                                      );
                                    },
                                    child: const Text("Yes"),
                                  ),
                                ],
                              ),
                            ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.all(width * 0.02),
                      child: Icon(
                        Icons.logout,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Profile Box
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: EdgeInsets.all(width * 0.04),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                profileImageUrl.isNotEmpty
                                    ? Image.network(
                                      profileImageUrl,
                                      width: width * 0.18,
                                      height: width * 0.18,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (
                                        context,
                                        child,
                                        loadingProgress,
                                      ) {
                                        if (loadingProgress == null)
                                          return child;
                                        return SizedBox(
                                          width: width * 0.18,
                                          height: width * 0.18,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Image.asset(
                                          'assets/Alex.png',
                                          width: width * 0.18,
                                          height: width * 0.18,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    )
                                    : Image.asset(
                                      'assets/Alex.png',
                                      width: width * 0.18,
                                      height: width * 0.18,
                                      fit: BoxFit.cover,
                                    ),
                          ),
                          SizedBox(width: width * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                _buildProfileInfoRow(context, "Age", age),
                                _buildProfileInfoRow(context, "Gender", gender),
                                // Display all categories as chips
                                _buildCategoriesRow(context, "Categories"),
                                _buildProfileInfoRow(
                                  context,
                                  "Traveling to",
                                  travel,
                                ),
                                _buildProfileInfoRow(context, "Email", email),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InfoScreen(),
                              ),
                            ).then((_) => _loadUserData());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: height * 0.018,
                            ),
                          ),
                          child: Text(
                            "Edit profile",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                "More setting",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingGroup(
                context: context,
                title: "Account Settings",
                isOpen: isAccountSettingsOpen,
                onTap: () {
                  setState(() {
                    isAccountSettingsOpen = !isAccountSettingsOpen;
                  });
                },
                options: const ["Change Password", "Change Email"],
                onOptionTap: (option) {
                  if (option == "Change Password") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    );
                  } else if (option == "Change Email") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangeEmailScreen(),
                      ),
                    );
                  }
                },
              ),
              _buildSettingGroup(
                context: context,
                title: "App Settings",
                isOpen: isAppSettingsOpen,
                onTap: () {
                  setState(() {
                    isAppSettingsOpen = !isAppSettingsOpen;
                  });
                },
                options: const [],
                onOptionTap: null,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8, right: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                      margin: const EdgeInsets.only(left: 8),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Theme Mode",
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, _) {
                              return Switch(
                                value: themeProvider.isDark,
                                onChanged: (value) {
                                  themeProvider.toggleTheme(value);
                                },
                                activeColor:
                                    Theme.of(context).colorScheme.primary,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // In your _EditprofileState class, update the Support & Help section:
              _buildSettingGroup(
                context: context,
                title: "Support & Help",
                isOpen: isSupportOpen,
                onTap: () {
                  setState(() {
                    isSupportOpen = !isSupportOpen;
                  });
                },
                options: const [
                  "Version info",
                  "Rate Us", // Add this new option
                  "Share App",
                  "Delete My Account",
                ],
                onOptionTap: (option) async {
                  if (option == "Version info") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VersionInfoScreen(),
                      ),
                    );
                  } else if (option == "Rate Us") {
                    // Add this case
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RateUsScreen(),
                      ),
                    );
                  } else if (option == "Share App") {
                    await _shareApp();
                  } else if (option == "Delete My Account") {
                    await _showDeleteAccountConfirmation();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this method to your class
  Future<void> _showDeleteAccountConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Yes, Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (result == true) {
      await _deleteAccount();
    }
  }

  Future<void> _shareApp() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      const appStoreLink =
          'https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME';
      final text = 'Check out ${packageInfo.appName} app! $appStoreLink';

      // Using Share.share() correctly
      final result = await Share.share(
        text,
        subject: 'Share ${packageInfo.appName}',
      );

      if (result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App shared successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing app: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        try {
          // Delete user data from Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();

          // Delete the auth account
          await user.delete();

          // Dismiss loading indicator
          Navigator.pop(context);

          // Navigate to login screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const Login()),
            (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
          );
        } catch (e) {
          // Dismiss loading indicator if there's an error
          Navigator.pop(context);
          rethrow;
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Widget _buildProfileInfoRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          TextSpan(text: value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  // New method to display categories as chips
  Widget _buildCategoriesRow(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children:
                categories.map((category) {
                  return Chip(
                    label: Text(category, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingGroup({
    required BuildContext context,
    required String title,
    required bool isOpen,
    required VoidCallback onTap,
    required List<String> options,
    Function(String)? onOptionTap,
    List<Widget> children = const [],
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Theme.of(context).iconTheme.color,
                ),
              ],
            ),
          ),
        ),
        if (isOpen) ...[
          ...options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(left: 12, top: 8, right: 10),
              child: GestureDetector(
                onTap: onOptionTap != null ? () => onOptionTap(option) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  margin: const EdgeInsets.only(left: 8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ),
            ),
          ),
          ...children,
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}
