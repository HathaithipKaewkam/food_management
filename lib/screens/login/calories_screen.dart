import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/screens/login/goal_screen.dart';
import 'package:food_project/screens/root_screen.dart';

class CaloriesMacronutrient extends StatefulWidget {
  @override
  _CaloriesMacronutrientState createState() => _CaloriesMacronutrientState();
}

class _CaloriesMacronutrientState extends State<CaloriesMacronutrient> {
  String userName = ""; 
  double caloriesPerDay = 0.0;
  double proteinPercentage = 0.3; 
  double carbsPercentage = 0.4;   
  double fatPercentage = 0.3;    
  double proteinGrams = 0.0;
  double carbsGrams = 0.0;
  double fatGrams = 0.0;

  
  int age = 0;
  double weight = 0.0;  
  double height = 0.0; 
  String gender = '';  
  String activity = '';  
  String goal = "";

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchUserProfile();
    _fetchUserGoal();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users') 
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userName = userDoc['username'] ?? '';
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    } else {
      print("User not logged in");
    }
  }
  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('userProfiles') 
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            weight = userDoc['weight'] ?? 0.0;
            height = userDoc['height'] ?? 0.0;
            gender = userDoc['gender'] ?? '';
            activity = userDoc['activity'] ?? '';
            DateTime birthday = DateTime.parse(userDoc['birthday']);
            age = _calculateAge(birthday);
          });
          calculateCalories();
        }
      } catch (e) {
        print('Error fetching user profile: $e');
      }
    } else {
      print("User not logged in");
    }
  }

  Future<void> _fetchUserGoal() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      DocumentSnapshot goalDoc = await FirebaseFirestore.instance
          .collection('userGoals')
          .doc(user.uid)
          .get();

      if (goalDoc.exists) {
        setState(() {
          goal = goalDoc['goal'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching user goal: $e');
    }
  }
}

   int _calculateAge(DateTime birthday) {
    DateTime today = DateTime.now();
    int age = today.year - birthday.year;
    if (today.month < birthday.month || (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }
    return age;
  }


  void calculateCalories() {
  if (weight == 0.0 || height == 0.0 || age == 0 || gender.isEmpty || activity.isEmpty) {
    print("Missing data for calculation");
    return;
  }
  
  // คำนวณ BMR เหมือนเดิม
  double bmr;
  if (gender == 'Male') {
    bmr = 10 * weight + 6.25 * height - 5 * age + 5;
  } else {
    bmr = 10 * weight + 6.25 * height - 5 * age - 161;
  }

  // คำนวณ activity multiplier เหมือนเดิม
  double activityMultiplier;
  switch (activity) {
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

  double tdee = bmr * activityMultiplier;

  switch (goal) {
    case 'Lose Weight':
      caloriesPerDay = tdee * 0.8; 
     
      proteinPercentage = 0.35; 
      carbsPercentage = 0.35;   
      fatPercentage = 0.3;     
      break;
      
    case 'Build Muscle':
      caloriesPerDay = tdee * 1.1; 
      proteinPercentage = 0.4; 
      carbsPercentage = 0.4;   
      fatPercentage = 0.2;      
      break;
      
    case 'Balanced Diet':
      caloriesPerDay = tdee; 
      proteinPercentage = 0.3;
      carbsPercentage = 0.4;
      fatPercentage = 0.3;
      break;
      
    case 'Healthy Eating':
      caloriesPerDay = tdee; 
      proteinPercentage = 0.3;
      carbsPercentage = 0.45; 
      fatPercentage = 0.25;  
      break;
      
    default:
      caloriesPerDay = tdee;
  }

  proteinGrams = (caloriesPerDay * proteinPercentage) / 4; 
  carbsGrams = (caloriesPerDay * carbsPercentage) / 4; 
  fatGrams = (caloriesPerDay * fatPercentage) / 9; 

  setState(() {});
  saveToDatabase();
}

  Future<void> saveToDatabase() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      await FirebaseFirestore.instance
          .collection('usersCaloriesMacronutrient')
          .doc(user.uid)
          .set({
        'caloriesPerDay': caloriesPerDay,
        'proteinGrams': proteinGrams,
        'carbsGrams': carbsGrams,
        'fatGrams': fatGrams,
         'goal': goal, 
        'proteinPercentage': proteinPercentage,
        'carbsPercentage': carbsPercentage,     
        'fatPercentage': fatPercentage,       
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); 

      await FirebaseFirestore.instance
          .collection('usersCaloriesMacronutrient')
          .doc(user.uid)
          .update({
        'history': FieldValue.arrayUnion([
          {
            'date': FieldValue.serverTimestamp(),
            'caloriesPerDay': caloriesPerDay,
            'proteinGrams': proteinGrams,
            'carbsGrams': carbsGrams,
            'fatGrams': fatGrams,
          }
        ]),
      });

      print('Data saved successfully.');
    } catch (e) {
      print('Error saving data: $e');
    }
  } else {
    print("User not logged in");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(
            FontAwesomeIcons.arrowLeft,
            color: Colors.black,
            size: 20,
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
                              MaterialPageRoute(
                              builder: (context) =>
                                  RootPage(),
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
