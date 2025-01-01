import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/screens/login/goal_screen.dart';

class CaloriesMacronutrient extends StatefulWidget {
  @override
  _CaloriesMacronutrientState createState() => _CaloriesMacronutrientState();
}

class _CaloriesMacronutrientState extends State<CaloriesMacronutrient> {
  String userName = "Moodeng"; 
  double caloriesPerDay = 0.0;
  double proteinPercentage = 0.3; // 30% for Protein
  double carbsPercentage = 0.4;   // 40% for Carbs
  double fatPercentage = 0.3;     // 30% for Fat
  double proteinGrams = 0.0;
  double carbsGrams = 0.0;
  double fatGrams = 0.0;

  // Sample input: Age, Weight, Height, Gender, Activity Level
  int age = 30;
  double weight = 70;  // kg
  double height = 175; // cm
  String gender = 'Male';  // 'Male' or 'Female'
  String activityLevel = 'Moderate';  // 'Sedentary', 'Light', 'Moderate', 'Active'

  @override
  void initState() {
    super.initState();
    calculateCalories();
  }

  void calculateCalories() {
    double bmr;
    if (gender == 'Male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    double activityMultiplier;
    switch (activityLevel) {
      case 'Sedentary':
        activityMultiplier = 1.2;
        break;
      case 'Light':
        activityMultiplier = 1.375;
        break;
      case 'Moderate':
        activityMultiplier = 1.55;
        break;
      case 'Active':
        activityMultiplier = 1.725;
        break;
      default:
        activityMultiplier = 1.2;
    }


    caloriesPerDay = bmr * activityMultiplier;

    proteinGrams = (caloriesPerDay * proteinPercentage) / 4; // 1g protein = 4 calories
    carbsGrams = (caloriesPerDay * carbsPercentage) / 4; // 1g carbs = 4 calories
    fatGrams = (caloriesPerDay * fatPercentage) / 9; // 1g fat = 9 calories

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Center(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Hi, $userName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Your Daily Calories Requirement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                FaIcon(
                  FontAwesomeIcons.fire,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  Image(
                    image: AssetImage('assets/images/calories.png'),
                    width: 200,
                    height: 200,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              '${caloriesPerDay.toStringAsFixed(0)} kcal',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Macronutrient Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Protein Section
                  Column(
                    children: [
                      Image.asset('assets/images/protein.png', width: 80, height: 80),
                      const SizedBox(height: 8),
                      const Text(
                        'Protein',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${proteinGrams.toStringAsFixed(1)} g',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                color: Colors.green),
                      ),
                    ],
                  ),
                  // Fat Section
                  Column(
                    children: [
                      Image.asset('assets/images/fat.png', width: 80, height: 80),
                      const SizedBox(height: 8),
                      const Text(
                        'Fat',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${fatGrams.toStringAsFixed(1)} g',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                color: Colors.green),
                      ),
                    ],
                  ),
                  // Carbs Section
                  Column(
                    children: [
                      Image.asset('assets/images/carbo.png', width: 80, height: 80),
                      const SizedBox(height: 8),
                      const Text(
                        'Carbs',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${carbsGrams.toStringAsFixed(1)} g',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
          Center(
            child: ElevatedButton(
              onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>
                       const GoalScreen()),);
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
