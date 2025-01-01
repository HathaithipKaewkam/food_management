import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/screens/login/calories_screen.dart';

class FoodAllergies extends StatefulWidget {
  @override
  _FoodAllergiesState createState() => _FoodAllergiesState();
}

class _FoodAllergiesState extends State<FoodAllergies> {
  final List<Map<String, String>> foodAFoodAllergies = [
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

  final Set<String> selectedAFoodAllergies = {};

  @override
  Widget build(BuildContext context) {
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
                      MaterialPageRoute(builder: (context) =>
                      CaloriesMacronutrient()),);
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
              const SizedBox(height: 20),
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
                itemCount: foodAFoodAllergies.length,
                itemBuilder: (context, index) {
                  final food = foodAFoodAllergies[index];
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

              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                            CaloriesMacronutrient()),);
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
