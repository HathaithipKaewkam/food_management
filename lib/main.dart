import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:food_project/screens/home/home_screen.dart';
import 'package:food_project/screens/ingredient/add_ingredient.dart';
import 'package:food_project/screens/ingredient/history_ingredient.dart';
import 'package:food_project/screens/onboarding_screen.dart';
import 'package:food_project/screens/root_screen.dart';
import 'package:quick_actions/quick_actions.dart';



import 'firebase_options.dart';


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
      home: OnboardingScreen(),
    );
  }
}

