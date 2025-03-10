import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/cart_screen.dart';
import 'package:food_project/screens/home/home_screen.dart';
import 'package:food_project/screens/ingredient/ingredient_screen.dart';
import 'package:food_project/screens/ingredient/search_ingredient.dart';
import 'package:food_project/screens/profile_screen.dart';
import 'package:food_project/screens/recipe/recipe_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RootPage extends StatefulWidget {
  final String selectedGoal;
  final int initialIndex;
   const RootPage({
    Key? key, 
    this.selectedGoal = '', 
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _bottomNavIndex = 0;
  bool isNewUser = false; // ตรวจสอบว่าเป็น user ใหม่หรือไม่

  @override
  void initState() {
    super.initState();
    _bottomNavIndex = widget.initialIndex;
    checkIfUserIsNew().then((isNew) {
      setState(() {
        isNewUser = isNew;
        _bottomNavIndex = isNew ? 1 : 2; // ถ้าไม่มีวัตถุดิบ ไปหน้า IngredientScreen
      });

      if (isNewUser) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showAddIngredientAlert();
        });
      }
    });
  }

  /// ✅ ตรวจสอบว่าผู้ใช้มีวัตถุดิบหรือไม่
Future<bool> checkIfUserIsNew() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  // ดึงค่าจาก SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  bool? isNewUser = prefs.getBool('isNewUser');

  // ถ้ามีการตั้งค่าการตรวจสอบ user ใหม่แล้ว
  if (isNewUser != null) {
    return isNewUser;
  }

  // ตรวจสอบจาก Firestore ว่าผู้ใช้มีวัตถุดิบหรือไม่
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('userIngredients')
      .get();

  bool result = userDoc.docs.isEmpty;

  // บันทึกผลการตรวจสอบลงใน SharedPreferences
  prefs.setBool('isNewUser', result);

  // ตรวจสอบค่า initialIndex ที่ส่งมาจาก RootPage
  print('Initial Index: ${widget.initialIndex}');

  return result;
}



  void _showAddIngredientAlert() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/junk-food.png',
              width: 150, 
              height: 150, 
            ),
            SizedBox(height: 15), 
            Text(
              'No Ingredients Found',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Your ingredient list is empty. \nAdd one to get started.',
          style: TextStyle(color: Colors.black),
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          Center( // ใช้ Center เพื่อให้ปุ่มอยู่กลาง
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchIngredientScreen(),
                  ),
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFF325b51), // ตั้งค่าสีพื้นหลังของปุ่ม
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), // ตั้งค่าการเว้นระยะของปุ่ม
              ),
              child: Text(
                'Add Ingredients Now !',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}



  /// ✅ รายการหน้าในแอป
  List<Widget> _widgetOptions() {
    return [
      const RecipeScreen(),
      IngredientScreen(
        index: 0,
        ingredientList: Ingredient.ingredientList ?? [],
      ),
      const HomeScreen(selectedGoal: null),
      CartScreen(addedToCartIngredients: [], ingredient: {}),
      const ProfileScreen(),
    ];
  }

  /// ✅ รายการไอคอนแถบเมนู
  List<IconData> iconList = [
    FontAwesomeIcons.utensils,
    FontAwesomeIcons.drumstickBite,
    FontAwesomeIcons.home,
    FontAwesomeIcons.cartShopping,
    FontAwesomeIcons.solidUser,
  ];

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _bottomNavIndex,
        children: _widgetOptions(),
      ),
      bottomNavigationBar: AnimatedBottomNavigationBar(
        splashColor: const Color(0xFF325b51),
        activeColor: const Color(0xFF325b51),
        inactiveColor: Colors.black.withOpacity(.5),
        icons: iconList,
        activeIndex: _bottomNavIndex,
        gapLocation: GapLocation.none,
        notchSmoothness: NotchSmoothness.defaultEdge,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
      ),
    );
  }
}