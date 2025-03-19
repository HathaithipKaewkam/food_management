import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_project/screens/root_screen.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final CarouselSliderController? buttonCarouselController = CarouselSliderController();
  int selectedGoalIndex = 0;

  List goalArr = [
    {
      "image": "assets/images/goal_build_muscle.png",
      "title": "Build Muscle",
      "subtitle": "Focus on protein-rich meals to\nsupport muscle growth."
    },
    {
      "image": "assets/images/goal_lose_weight.png",
      "title": "Lose Weight",
      "subtitle":
          "Low-calorie meals with balanced\nnutrition to support weight loss."
    },
    {
      "image": "assets/images/goal_balanced_diet.png",
      "title": "Balanced Diet",
      "subtitle": "Meals that provide a balance of\ncarbs, proteins, and fats."
    },
    {
      "image": "assets/images/goal_healthy_food.png",
      "title": "Healthy Eating",
      "subtitle": "Focus on nutrient-dense and\nminimally processed foods."
    },
  ];

  Future<void> saveGoalToDatabase(String goal) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      await FirebaseFirestore.instance
          .collection('userGoals')
          .doc(user.uid)
          .set({'goal': goal, 'timestamp': FieldValue.serverTimestamp()});
      print('Goal saved successfully.');
    } catch (e) {
      print('Error saving goal: $e');
    }
  }
}


  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: CarouselSlider(
                items: goalArr
                    .map(
                      (gObj) => Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Colors.greenAccent, Colors.lightGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: EdgeInsets.symmetric(
                            vertical: media.width * 0.1, horizontal: 25),
                        alignment: Alignment.center,
                        child: FittedBox(
                          child: Column(
                            children: [
                              Image.asset(
                                gObj["image"].toString(),
                                width: media.width * 0.5,
                                fit: BoxFit.fitWidth,
                              ),
                              SizedBox(
                                height: media.width * 0.1,
                              ),
                              Text(
                                gObj["title"].toString(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700),
                              ),
                              Container(
                                width: media.width * 0.1,
                                height: 1,
                                color: Colors.white,
                              ),
                              SizedBox(
                                height: media.width * 0.02,
                              ),
                              Text(
                                gObj["subtitle"].toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
                carouselController: buttonCarouselController,
                options: CarouselOptions(
                  autoPlay: false,
                  enlargeCenterPage: true,
                  viewportFraction: 0.7,
                  aspectRatio: 0.74,
                  initialPage: 0,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 40),
              width: media.width,
              child: Column(
                children: [
                  SizedBox(
                    height: media.width * 0.05,
                  ),
                  const Text(
                    "What is your goal ?",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    "It will help us to choose a best\nmeal for you",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: media.width * 0.05,
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.only(bottom: media.height * 0.05),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          String selectedGoal = goalArr[selectedGoalIndex]["title"]!;
                          await saveGoalToDatabase(selectedGoal);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                              builder: (context) =>
                                  RootPage(selectedGoal: selectedGoal),
                            ),      
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
                          'Confirm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
