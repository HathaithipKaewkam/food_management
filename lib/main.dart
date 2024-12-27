import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:food_project/screens/login/complete_profile.dart';
import 'package:food_project/screens/login/food_preferences.dart';
import 'firebase_options.dart';
import 'package:food_project/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Onboarding Screen',
      home: FoodPreferences(),
    );
  }
}
