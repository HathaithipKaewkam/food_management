import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_project/common/colo_extension.dart';
import 'package:food_project/constants.dart';
import 'package:image_picker/image_picker.dart';

class CompleteProfile extends StatefulWidget {
  const CompleteProfile({super.key});

  @override
  _CompleteProfileState createState() => _CompleteProfileState();
}

class _CompleteProfileState extends State<CompleteProfile> {
  String selectedImage = 'assets/images/profile_men.png';
  String selectedGender = 'Male';
  final Map<String, String> genderImages = {
    'Male': 'assets/images/profile_men.png',
    'Female': 'assets/images/profile_women.png',
  };

  void _onGenderChanged(String? gender) {
    if (gender != null) {
      setState(() {
        selectedGender = gender;
        selectedImage = genderImages[gender]!;
      });
    }
  }

  Future<void> _uploadNewImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = pickedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Let's complete your profile"),
        backgroundColor: Colors.white,
        elevation: 1,
        titleTextStyle: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "It will help us to know more about you!",
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            // รูปภาพโปรไฟล์
            Center(
              child: GestureDetector(
                onTap: _uploadNewImage,
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Constants.primaryColor.withOpacity(.5),
                      width: 5.0,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: selectedImage.contains('assets/')
                        ? AssetImage(selectedImage) as ImageProvider
                        : FileImage(File(selectedImage)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // ตัวเลือกเพศ
            Container(
              decoration: BoxDecoration(
                color: TColor.lightGray,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Container(
                    alignment: Alignment.center,
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: const Icon(
                      Icons.people_alt,
                      color: Colors.black54,
                    ),
                  ),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedGender,
                        items: genderImages.keys
                            .map((gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(
                                    gender,
                                    style: TextStyle(
                                      color: TColor.gray,
                                      fontSize: 14,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: _onGenderChanged,
                        isExpanded: true,
                        hint: Text(
                          "Choose Gender",
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
