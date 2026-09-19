// import 'dart:io';

// import 'package:cofeelink/home.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class InfoScreen extends StatefulWidget {
//   const InfoScreen({super.key});

//   @override
//   State<InfoScreen> createState() => _InfoScreenState();
// }

// class _InfoScreenState extends State<InfoScreen> {
//   File? _profileImage;
//   final picker = ImagePicker();

//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController ageController = TextEditingController();
//   String? selectedGender;
//   String? selectedCategory;
//   final TextEditingController travelController = TextEditingController();

//   final List<String> genderOptions = ['Male', 'Female', 'Other'];
//   final List<String> categoryOptions = [
//     'Entrepreneurship',
//     'Social',
//     'Technology',
//     'Business',
//     'Real Estate',
//     'Beauty',
//     'Health',
//     'Food',
//     'Construction',
//     'Services',
//     'Investor',
//     'Consulting',
//     'Other',
//   ];

//   Future<void> _pickImage() async {
//     var status = await Permission.photos.request(); // For iOS
//     var storageStatus = await Permission.storage.request(); // For Android

//     if (status.isGranted || storageStatus.isGranted) {
//       final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//       if (pickedFile != null) {
//         setState(() => _profileImage = File(pickedFile.path));
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Storage permission denied")),
//       );
//     }
//   }

//   void _onContinue() async {
//     if (!isFormComplete) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
//       return;
//     }

//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         throw Exception("User not logged in");
//       }

//       final ref = FirebaseDatabase.instance.ref("users/${user.uid}");
//       final prefs = await SharedPreferences.getInstance();

//       // Upload image to Firebase Storage if selected
//       String imageUrl = "";
//       if (_profileImage != null) {
//         try {
//           final storageRef = FirebaseStorage.instance
//               .ref()
//               .child('profile_images')
//               .child('${user.uid}.jpg');

//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Uploading profile image...")),
//           );

//           await storageRef.putFile(_profileImage!);
//           imageUrl = await storageRef.getDownloadURL();
//           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//         } catch (e) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text("Failed to upload image: ${e.toString()}")),
//           );
//           return;
//         }
//       }

//       // Save to SharedPreferences
//       await prefs.setString('name', nameController.text.trim());
//       await prefs.setString('userId', user.uid);
//       await prefs.setString('age', ageController.text.trim());
//       await prefs.setString('gender', selectedGender ?? '');
//       await prefs.setString('category', selectedCategory ?? '');
//       await prefs.setString('travel', travelController.text.trim());
//       await prefs.setString('email', user.email ?? '');
//       if (imageUrl.isNotEmpty) {
//         await prefs.setString('profileImageUrl', imageUrl);
//       }

//       // Create new user data map
//       final userData = {
//         'name': nameController.text.trim(),
//         'age': ageController.text.trim(),
//         'gender': selectedGender,
//         'category': selectedCategory,
//         'travel': travelController.text.trim(),
//         'email': user.email,
//         'createdAt': ServerValue.timestamp,
//       };

//       // Only add image URL if we have one
//       if (imageUrl.isNotEmpty) {
//         userData['profileImageUrl'] = imageUrl;
//       }

//       // Set the data (this will create or overwrite)
//       await ref.set(userData);

//       // Show success dialog
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder:
//             (_) => Dialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: const [
//                     Icon(Icons.check_circle, color: Colors.green, size: 80),
//                     SizedBox(height: 16),
//                     Text(
//                       "Congratulations!",
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     Text("Your profile has been saved."),
//                   ],
//                 ),
//               ),
//             ),
//       );

//       await Future.delayed(const Duration(seconds: 2));
//       Navigator.of(context).pop(); // Close dialog
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const Home()),
//       );
//     } catch (e) {
//       print("🔥 Error saving data: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to save data: ${e.toString()}")),
//       );
//     }
//   }

//   bool get isFormComplete {
//     // return _profileImage != null &&
//     return nameController.text.isNotEmpty &&
//         ageController.text.isNotEmpty &&
//         selectedGender != null &&
//         selectedCategory != null &&
//         travelController.text.isNotEmpty;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;

//     return SafeArea(
//       child: LayoutBuilder(
//         builder:
//             (context, constraints) => Scaffold(
//               backgroundColor: Colors.white,
//               body: SafeArea(
//                 child: SingleChildScrollView(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: screenWidth < 400 ? 16 : 24,
//                     vertical: 16,
//                   ),
//                   child: Center(
//                     child: ConstrainedBox(
//                       constraints: const BoxConstraints(maxWidth: 500),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Container(
//                             height: 40,
//                             width: 40,
//                             decoration: BoxDecoration(
//                               border: Border.all(color: Colors.black),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: IconButton(
//                               icon: const Icon(Icons.arrow_back, size: 20),
//                               onPressed: () {
//                                 Navigator.pop(context);
//                               },
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           Center(
//                             child: Text(
//                               "Some basic about you",
//                               style: GoogleFonts.poly(
//                                 fontSize: 36,
//                                 fontStyle: FontStyle.italic,
//                                 color: const Color(0xFF007AFF),
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                           const SizedBox(height: 20),
//                           GestureDetector(
//                             onTap: _pickImage,
//                             child: Container(
//                               height: 120,
//                               decoration: BoxDecoration(
//                                 border: Border.all(color: Colors.black),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Center(
//                                 child:
//                                     _profileImage != null
//                                         ? Image.file(
//                                           _profileImage!,
//                                           height: 100,
//                                         )
//                                         : const Icon(
//                                           Icons.add,
//                                           size: 40,
//                                           color: Colors.blue,
//                                         ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 15),
//                           _buildTextField("Name", nameController),
//                           _buildTextField("Age", ageController, isNumber: true),
//                           _buildDropdown(
//                             "Gender",
//                             genderOptions,
//                             selectedGender,
//                             (value) => setState(() => selectedGender = value),
//                           ),
//                           _buildDropdown(
//                             "Add Categories",
//                             categoryOptions,
//                             selectedCategory,
//                             (value) => setState(() => selectedCategory = value),
//                           ),
//                           _buildTextField(
//                             "Where are you traveling today?",
//                             travelController,
//                           ),
//                           const SizedBox(height: 80),
//                           SizedBox(
//                             width: double.infinity,
//                             height: 50,
//                             child: ElevatedButton(
//                               onPressed: _onContinue,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xFF007AFF),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(30),
//                                 ),
//                               ),
//                               child: const Text(
//                                 "Save info and continue",
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//       ),
//     );
//   }

//   Widget _buildTextField(
//     String label,
//     TextEditingController controller, {
//     bool isNumber = false,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 15),
//       child: TextField(
//         controller: controller,
//         keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//         style: GoogleFonts.poly(),
//         decoration: InputDecoration(
//           labelText: label,
//           labelStyle: GoogleFonts.poly(),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       ),
//     );
//   }

//   Widget _buildDropdown(
//     String label,
//     List<String> items,
//     String? selectedValue,
//     ValueChanged<String?> onChanged,
//   ) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 15),
//       child: DropdownButtonFormField<String>(
//         value: selectedValue,
//         decoration: InputDecoration(
//           labelText: label,
//           labelStyle: GoogleFonts.poly(),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//         style: GoogleFonts.poly(color: Colors.black),
//         items:
//             items.map((item) {
//               return DropdownMenuItem(value: item, child: Text(item));
//             }).toList(),
//         onChanged: onChanged,
//       ),
//     );
//   }
// }

import 'dart:io';

import 'package:cofeelink/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  File? _profileImage;
  final picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String? selectedGender;
  List<String> selectedCategories = [];
  final TextEditingController travelController = TextEditingController();

  bool _isLoading = false;
  bool _isDropdownOpen = false; // Track dropdown state

  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  final List<String> categoryOptions = [
    'Entrepreneurship',
    'Social',
    'Technology',
    'Business',
    'Real Estate',
    'Beauty',
    'Health',
    'Food',
    'Construction',
    'Services',
    'Investor',
    'Consulting',
    'Other',
  ];

  Future<void> _pickImage() async {
    var status = await Permission.photos.request();
    var storageStatus = await Permission.storage.request();

    if (status.isGranted || storageStatus.isGranted) {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _profileImage = File(pickedFile.path));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission denied")),
      );
    }
  }

  void _onContinue() async {
    if (!isFormComplete) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final ref = FirebaseDatabase.instance.ref("users/${user.uid}");
      final prefs = await SharedPreferences.getInstance();

      String imageUrl = "";
      if (_profileImage != null) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_images')
              .child('${user.uid}.jpg');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Uploading profile image...")),
          );

          await storageRef.putFile(_profileImage!);
          imageUrl = await storageRef.getDownloadURL();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to upload image: ${e.toString()}")),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Save to SharedPreferences
      await prefs.setString('name', nameController.text.trim());
      await prefs.setString('userId', user.uid);
      await prefs.setString('age', ageController.text.trim());
      await prefs.setString('gender', selectedGender ?? '');
      await prefs.setStringList('categories', selectedCategories);
      await prefs.setString('travel', travelController.text.trim());
      await prefs.setString('email', user.email ?? '');
      if (imageUrl.isNotEmpty) {
        await prefs.setString('profileImageUrl', imageUrl);
      }

      // Create new user data map
      final userData = {
        'name': nameController.text.trim(),
        'age': ageController.text.trim(),
        'gender': selectedGender,
        'categories': selectedCategories,
        'travel': travelController.text.trim(),
        'email': user.email,
        'createdAt': ServerValue.timestamp,
      };

      if (imageUrl.isNotEmpty) {
        userData['profileImageUrl'] = imageUrl;
      }

      await ref.set(userData);

      setState(() {
        _isLoading = false;
      });

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green, size: 80),
                    SizedBox(height: 16),
                    Text(
                      "Congratulations!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text("Your profile has been saved."),
                  ],
                ),
              ),
            ),
      );

      await Future.delayed(const Duration(seconds: 2));
      Navigator.of(context).pop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
      );
    } catch (e) {
      print("🔥 Error saving data: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save data: ${e.toString()}")),
      );
    }
  }

  bool get isFormComplete {
    return nameController.text.isNotEmpty &&
        ageController.text.isNotEmpty &&
        selectedGender != null &&
        selectedCategories.isNotEmpty &&
        travelController.text.isNotEmpty;
  }

  void _removeCategory(String category) {
    setState(() {
      selectedCategories.remove(category);
    });
  }

  void _toggleCategory(String category) {
    setState(() {
      if (selectedCategories.contains(category)) {
        selectedCategories.remove(category);
      } else {
        selectedCategories.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        SafeArea(
          child: LayoutBuilder(
            builder:
                (context, constraints) => Scaffold(
                  backgroundColor: Colors.white,
                  body: SafeArea(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth < 400 ? 16 : 24,
                        vertical: 16,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back, size: 20),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: Text(
                                  "Some basic about you",
                                  style: GoogleFonts.poly(
                                    fontSize: 36,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF007AFF),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child:
                                        _profileImage != null
                                            ? Image.file(
                                              _profileImage!,
                                              height: 100,
                                            )
                                            : const Icon(
                                              Icons.add,
                                              size: 40,
                                              color: Colors.blue,
                                            ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              _buildTextField("Name", nameController),
                              _buildTextField(
                                "Age",
                                ageController,
                                isNumber: true,
                              ),
                              _buildDropdown(
                                "Gender",
                                genderOptions,
                                selectedGender,
                                (value) =>
                                    setState(() => selectedGender = value),
                              ),
                              _buildMultiSelectDropdown(),
                              _buildTextField(
                                "Where are you traveling today?",
                                travelController,
                              ),
                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _onContinue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF007AFF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    "Save info and continue",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.poly(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poly(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poly(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        style: GoogleFonts.poly(color: Colors.black),
        items:
            items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
        onChanged: onChanged,
      ),
    );
  }

  // Custom multi-select dropdown with chips inside the field
  Widget _buildMultiSelectDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputDecorator(
            decoration: InputDecoration(
              labelText: "Add Categories",
              labelStyle: GoogleFonts.poly(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display selected categories as chips inside the field
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        selectedCategories.map((category) {
                          return Chip(
                            label: Text(
                              category,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: const Color(0xFF007AFF),
                            labelStyle: const TextStyle(color: Colors.white),
                            deleteIcon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                            onDeleted: () => _removeCategory(category),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                  ),
                ),
                // Dropdown button
                PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (value) => _toggleCategory(value),
                  itemBuilder: (BuildContext context) {
                    return categoryOptions
                        .where(
                          (category) => !selectedCategories.contains(category),
                        )
                        .map((category) {
                          return PopupMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        })
                        .toList();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
