import 'package:flutter/material.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/widgets/recipe_widget.dart';


class FavoriteScreen extends StatefulWidget {
  final List<Recipe> favoritedRecipes;
  const FavoriteScreen({super.key, required this.favoritedRecipes});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top:10, left: 0),
        child: ListView(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // ซ้าย-ขวา
                children: [
                  // ปุ่มย้อนกลับ
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Constants.primaryColor.withOpacity(.15),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Constants.primaryColor),
                      onPressed: () {
                        Navigator.pop(context); // กลับหน้าก่อนหน้า
                      },
                    ),
                  ),
                  // ชื่อหน้าจอ
                  Text(
                    'Favorites',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Constants.primaryColor,
                    ),
                  ),
                  // ปุ่ม List
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Constants.primaryColor.withOpacity(.15),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.list, color: Constants.primaryColor),
                      onPressed: () {
                        // เพิ่มฟังก์ชันเมื่อกดปุ่ม List
                        print('List icon pressed');
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Check if favorites list is empty

            widget.favoritedRecipes.isEmpty
                ? Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 230),
                        SizedBox(
                          height: 100,
                          child: Image.asset('assets/images/favorited.png'),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your favorited Recipes',
                          style: TextStyle(
                            color: Constants.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(left: 0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.favoritedRecipes.length,
                      itemBuilder: (BuildContext context, int index) {
                        return RecipeWidget(
                          index: index,
                          recipeScreenList: widget.favoritedRecipes, recipe: null,
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
