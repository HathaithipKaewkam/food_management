import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/screens/login/food_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompleteProfile extends StatefulWidget {
  const CompleteProfile({super.key});

  @override
  _CompleteProfileState createState() => _CompleteProfileState();
}

class _CompleteProfileState extends State<CompleteProfile> {
  String selectedImage = 'assets/images/default_profile.png';
  String selectedGender = '';
  DateTime? selectedDate;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String selectedActivity = '';
  bool _isLoading = false;

  bool _isFormValid() {
    return selectedGender.isNotEmpty &&
        selectedDate != null &&
        _weightController.text.isNotEmpty &&
        double.tryParse(_weightController.text) != null &&
        _heightController.text.isNotEmpty &&
        double.tryParse(_heightController.text) != null &&
        selectedActivity.isNotEmpty;
  }

  final Map<String, String> genderImages = {
    'Male': 'assets/images/profile_men.png',
    'Female': 'assets/images/profile_women.png',
  };

  void _onGenderChanged(String? gender) {
    if (gender != null) {
      setState(() {
        selectedGender = gender;
        selectedImage = gender == 'Male'
            ? 'assets/images/profile_men.png'
            : 'assets/images/profile_women.png';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> addUserProfile({
    required String userId,
    required String gender,
    required DateTime birthday,
    required double weight,
    required double height,
    required String activity,
  }) async {
    final userProfileRef = FirebaseFirestore.instance.collection('userProfiles').doc(userId);

    await userProfileRef.set({
      'gender': gender,
      'birthday': birthday.toIso8601String(),
      'weight': weight,
      'height': height,
      'activity': activity,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String? userId = currentUser?.uid;

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
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "It will help us to know more about you!",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            // Profile Picture
            Center(
              child: GestureDetector(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: selectedImage.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          )
                        : Image(
                            image: selectedImage.contains('assets/')
                                ? AssetImage(selectedImage) as ImageProvider
                                : FileImage(File(selectedImage)),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Gender
            _buildDropdown(
              icon: FontAwesomeIcons.venusMars,
              value: selectedGender.isEmpty ? null : selectedGender,
              hint: "Choose Gender",
              items: genderImages.keys.toList(),
              onChanged: _onGenderChanged,
            ),
            const SizedBox(height: 20),
            // Date of Birth
            _buildDatePicker(context),
            const SizedBox(height: 20),
            // Weight
            _buildTextInput(
              icon: FontAwesomeIcons.weightScale,
              controller: _weightController,
              hint: "Enter your weight",
              unit: "KG",
            ),
            const SizedBox(height: 20),
            // Height
            _buildTextInput(
              icon: FontAwesomeIcons.person,
              controller: _heightController,
              hint: "Enter your height",
              unit: "CM",
            ),
            const SizedBox(height: 20),
            // Activity
            _buildDropdown(
              icon: FontAwesomeIcons.dumbbell,
              value: selectedActivity.isEmpty ? null : selectedActivity,
              hint: "Choose Activity",
              items: ['Sedentary', 'Light', 'Moderate', 'Active'],
              onChanged: (value) {
                setState(() {
                  selectedActivity = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            // Next Button
            Center(
              child: ElevatedButton(
                onPressed: _isFormValid()
                    ? () async {
                        if (userId != null) {
                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            await addUserProfile(
                              userId: userId,
                              gender: selectedGender,
                              birthday: selectedDate!,
                              weight: double.parse(_weightController.text),
                              height: double.parse(_heightController.text),
                              activity: selectedActivity,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FoodPreferences()),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to save profile: $e")),
                            );
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF325b51),
                  minimumSize: const Size(50, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Next",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            alignment: Alignment.center,
            width: 50,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: FaIcon(icon, color: Colors.black54),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                items: items.map((item) {
                  return DropdownMenuItem(value: item, child: Text(item));
                }).toList(),
                onChanged: onChanged,
                isExpanded: true,
                hint: Text(hint),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            alignment: Alignment.center,
            width: 50,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: const FaIcon(FontAwesomeIcons.calendarDays, color: Colors.black54),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  selectedDate != null
                      ? DateFormat('d MMMM yyyy').format(selectedDate!)
                      : "Select Date of Birth",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selectedDate != null ? Colors.black : Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput({
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    required String unit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            alignment: Alignment.center,
            width: 50,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: FaIcon(icon, color: Colors.black54),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                hintStyle: const TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black54),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.greenAccent, Colors.lightGreen],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(unit, 
                    style: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
