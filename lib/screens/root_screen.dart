import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/cart_screen.dart';
import 'package:food_project/screens/home/home_screen.dart';
import 'package:food_project/screens/ingredient/ingredient_screen.dart';
import 'package:food_project/screens/profile_screen.dart';
import 'package:food_project/screens/recipe/recipe_screen.dart';





class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  List<Ingredient> myCart = [];

  int _bottomNavIndex = 0;

  // List of the pages
  List<Widget> _widgetOptions() {
    return [
      const RecipeScreen(),
       IngredientScreen(
        index: 0, 
        ingredientList: Ingredient.ingredientList, 
      ),
      const HomeScreen(selectedGoal: null,),
      const CartScreen(addedToCartIngredients: [],),
      const ProfileScreen(),
    ];
  }

  // List of the pages icons
  List<IconData> iconList = [
    Icons.book,
    Icons.fastfood,
    Icons.home,
    Icons.shopping_cart,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _bottomNavIndex,
        children: _widgetOptions(),
      ),
      bottomNavigationBar: AnimatedBottomNavigationBar(
        splashColor: const Color.fromARGB(255, 74, 144, 226),
        activeColor: const Color.fromARGB(255, 74, 144, 226),
        inactiveColor: Colors.black.withOpacity(.5),
        icons: iconList,
        activeIndex: _bottomNavIndex,
        gapLocation:
            GapLocation.none, // ลบการเว้นช่องสำหรับ FloatingActionButton
        notchSmoothness: NotchSmoothness.defaultEdge,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
            final List<Ingredient> addedToCartIngredients =
                Ingredient.addedToCartIngredients();
            myCart = addedToCartIngredients.toSet().toList();
          });
        },
      ),
    );
  }
}
