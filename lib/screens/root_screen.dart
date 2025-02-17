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

class RootPage extends StatefulWidget {
  final String selectedGoal;
  const RootPage({super.key, required this.selectedGoal});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _bottomNavIndex = 0;
  bool isNewUser = false; // ตรวจสอบว่าเป็น user ใหม่หรือไม่

  @override
  void initState() {
    super.initState();
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

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      return true; // ถ้าไม่มีข้อมูล user ถือว่าเป็น user ใหม่
    }

    // เช็คว่ามีวัตถุดิบใน collection 'ingredients' หรือไม่
    final ingredientDocs = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('ingredients')
        .get();

    return ingredientDocs.docs.isEmpty; // ถ้าไม่มีวัตถุดิบเลยถือว่าเป็น user ใหม่
  }

  /// ✅ Pop-up แจ้งให้เพิ่มวัตถุดิบ
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
              width: 150, // ขนาดรูปที่ต้องการ
              height: 150, // ขนาดรูปที่ต้องการ
            ),
            SizedBox(height: 15), // ระยะห่างระหว่างรูปกับข้อความ
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchIngredientScreen(),
                  ),
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
      const CartScreen(addedToCartIngredients: []),
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
        index: _bottomNavIndex, // ใช้ค่าที่ตั้งใน _bottomNavIndex
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