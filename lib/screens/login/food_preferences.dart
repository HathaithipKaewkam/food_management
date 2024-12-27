import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FoodPreferences extends StatefulWidget {
  @override
  _FoodPreferencesState createState() => _FoodPreferencesState();
}

class _FoodPreferencesState extends State<FoodPreferences> {
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
    {'name': 'Sticky Rice with Mango', 'image': 'assets/images/sticky_rice_mango.png'},
    {'name': 'Thai Iced Tea', 'image': 'assets/images/thai_iced_tea.png'},
    {'name': 'Coffee', 'image': 'assets/images/coffee.png'},
    {'name': 'Chocolate', 'image': 'assets/images/chocolate.png'},
    {'name': 'Ice Cream', 'image': 'assets/images/ice_cream.png'},
  ];

  final Set<String> selectedPreferences = {};

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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only( left: 15 , right: 15 , bottom: 10),
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
                child: const Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: FaIcon(
                        FontAwesomeIcons.magnifyingGlass,
                        color: Colors.black54,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for a specific food',
                          border: InputBorder.none,
                        ),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
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
                ),
                itemCount: foodPreferences.length,
                itemBuilder: (context, index) {
                  final food = foodPreferences[index];
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
                        color: isSelected ? const Color(0xFF78d454) : Colors.white,
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
                            fit: BoxFit.cover,
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
                  onPressed: () {
                    // Handle continue
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
