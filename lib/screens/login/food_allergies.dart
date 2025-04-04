import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/screens/login/calories_screen.dart';
import 'package:food_project/screens/login/goal_screen.dart';

class FoodAllergies extends StatefulWidget {
  @override
  _FoodAllergiesState createState() => _FoodAllergiesState();
}

class _FoodAllergiesState extends State<FoodAllergies> {
  final List<Map<String, String>> foodAllergies = [
    {'name': 'Milk', 'image': 'assets/images/allergies_milk.jpg'},
    {'name': 'Eggs', 'image': 'assets/images/allergies_egg.jpg'},
    {'name': 'Peanuts', 'image': 'assets/images/allergies_peanuts.jpg'},
    {'name': 'Wheat', 'image': 'assets/images/allergies_wheat.jpg'},
    {'name': 'Soybeans', 'image': 'assets/images/allergies_soybeans.jpg'},
    {'name': 'Shrimp', 'image': 'assets/images/allergies_shrimp.jpg'},
    {'name': 'Crab', 'image': 'assets/images/allergies_crab.jpg'},
    {'name': 'Squid', 'image': 'assets/images/allergies_squid.jpg'},
    {'name': 'Oyster', 'image': 'assets/images/allergies_oyster.jpg'},
    {'name': 'Corn', 'image': 'assets/images/allergies_corn.jpg'},
    {'name': 'Gluten', 'image': 'assets/images/allergies_gluten.jpg'},
    {'name': 'Alcohol', 'image': 'assets/images/allergies_alcohol.jpg'},
    
  ];

  final List<String> selectedAFoodAllergies = [];

  Future<void> saveFoodPreferences(
      String userId, List<String> selectedFoods) async {
    try {
      final preferencesRef = FirebaseFirestore.instance
          .collection('userAllergies')
          .doc(userId)
          .collection('Allergies');

      final existingPreferencesSnapshot = await preferencesRef.get();
      for (var doc in existingPreferencesSnapshot.docs) {
        await doc.reference.delete();
      }

      for (var food in selectedFoods) {
        await preferencesRef.add({
          'foodName': food,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      print('Food Allergies saved successfully.');
    } catch (e) {
      print('Error saving food Allergies: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 30, left: 5),
            child: Column
            (crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                    color: Colors.black,
                    iconSize: 20,
                  ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CaloriesMacronutrient()),
              );
            },
            child: const Text(
              'Skip',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        
                  
                ],
              ),
      Padding(
          padding: const EdgeInsets.only( left: 15 , right: 15 , bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Do you have any allergies ?',
                style: TextStyle(
                  fontSize: 25,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                 "Select from the list what are you allergic on or just skip this step if you don't have any",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              
              // Grid ของอาหาร
             GridView.builder(
                shrinkWrap: true, // ให้ GridView ไม่ขยายเกินพื้นที่
                physics: const NeverScrollableScrollPhysics(), // ปิดการเลื่อนใน GridView
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 อันต่อแถว
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8, // ปรับอัตราส่วนเพื่อเพิ่มพื้นที่สำหรับชื่อ
                ),
                itemCount: foodAllergies.length,
                itemBuilder: (context, index) {
                  final food = foodAllergies[index];
                  final isSelected = selectedAFoodAllergies.contains(food['name']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedAFoodAllergies.remove(food['name']);
                        } else {
                          selectedAFoodAllergies.add(food['name']!);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF78d454) : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                              child: Image.asset(
                                food['image']!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover, // ทำให้รูปเต็มกรอบ
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              food['name']!,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      String userId = user.uid;
                      await saveFoodPreferences(
                          userId, selectedAFoodAllergies.toList());
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GoalScreen()),
                      );
                    } else {
                      print("User not logged in");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF325b51),
                    minimumSize: const Size(50, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 80),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ]
      ),
    )
    );
  }
}
