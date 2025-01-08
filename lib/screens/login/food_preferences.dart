import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/screens/login/food_allergies.dart';

class FoodPreferences extends StatefulWidget {
  @override
  _FoodPreferencesState createState() => _FoodPreferencesState();
}

class _FoodPreferencesState extends State<FoodPreferences> {
  String searchQuery = '';
  final List<Map<String, String>> foodPreferences = [
    {'name': 'Pizza', 'image': 'assets/images/pizza.png'},
    {'name': 'Sushi', 'image': 'assets/images/sushi.png'},
    {'name': 'Burger', 'image': 'assets/images/burger.png'},
    {'name': 'Pasta', 'image': 'assets/images/pasta.png'},
    {'name': 'Sandwich', 'image': 'assets/images/sandwich.png'},
    {'name': 'Fried Chicken', 'image': 'assets/images/fried_chicken.png'},
    {'name': 'Salad', 'image': 'assets/images/salad.png'},
    {'name': 'Soup', 'image': 'assets/images/soup.png'},
    {'name': 'Grill', 'image': 'assets/images/grill.png'},
    {'name': 'Shrimps', 'image': 'assets/images/shrimp.png'},
    {'name': 'Tacos', 'image': 'assets/images/tacos.png'},
    {'name': 'Steak', 'image': 'assets/images/steak.png'},
    {'name': 'Tom Yum Kung', 'image': 'assets/images/tom_yum_kung.png'},
    {'name': 'Som Tum', 'image': 'assets/images/som_tum.png'},
    {'name': 'Pad Thai', 'image': 'assets/images/pad_thai.png'},
    {'name': 'Fried Rice', 'image': 'assets/images/fried_rice.png'},
    {'name': 'Green Curry', 'image': 'assets/images/green_curry.png'},
    {'name': 'Donuts', 'image': 'assets/images/donuts.png'},
    {'name': 'Pancakes', 'image': 'assets/images/pancakes.png'},
    {'name': 'Noodles', 'image': 'assets/images/food_noodles.png'},
    {'name': 'Hot Dog', 'image': 'assets/images/hot_dog.png'},
    {'name': 'Fruits', 'image': 'assets/images/fruits.png'},
    {'name': 'Sticky Rice with Mango','image': 'assets/images/sticky_rice_mango.png'},
    {'name': 'Thai Iced Tea', 'image': 'assets/images/thai_iced_tea.png'},
    {'name': 'Coffee', 'image': 'assets/images/coffee.png'},
    {'name': 'Chocolate', 'image': 'assets/images/chocolate.png'},
    {'name': 'Ice Cream', 'image': 'assets/images/ice_cream.png'},
  ];

  final List<String> selectedPreferences = [];

  Future<void> saveFoodPreferences(
      String userId, List<String> selectedFoods) async {
    try {
      final preferencesRef = FirebaseFirestore.instance
          .collection('userPreferences')
          .doc(userId)
          .collection('preferences');

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

      print('Food preferences saved successfully.');
    } catch (e) {
      print('Error saving food preferences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFoods = foodPreferences.where((food) {
      return food['name']!.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(
            FontAwesomeIcons.arrowLeft,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FoodAllergies()),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tell us about your food preferences',
                style: TextStyle(
                  fontSize: 25,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You can choose more than one answer',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              // ค้นหาอาหาร
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: FaIcon(
                        FontAwesomeIcons.magnifyingGlass,
                        color: Colors.black54,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search for a specific food',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: filteredFoods.length,
                itemBuilder: (context, index) {
                  final food = filteredFoods[index];
                  final isSelected = selectedPreferences.contains(food['name']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedPreferences.remove(food['name']);
                        } else {
                          selectedPreferences.add(food['name']!);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFF78d454) : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            food['image']!,
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            food['name']!,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      String userId = user.uid;
                      await saveFoodPreferences(
                          userId, selectedPreferences.toList());
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => FoodAllergies()),
                      );
                    } else {
                      print("User not logged in");
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FoodAllergies()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF325b51),
                    minimumSize: const Size(50, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 80),
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
      ),
    );
  }
}
