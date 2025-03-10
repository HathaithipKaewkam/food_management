import 'package:flutter/material.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/screens/recipe/favorite_screen.dart';
import 'package:food_project/screens/recipe/meal_schedule.dart';
import 'package:food_project/screens/recipe/myrecipe_screen.dart';
import 'package:food_project/screens/recipe/poupular_screen.dart';
import 'package:food_project/screens/recipe/recipe_detail.dart';
import 'package:food_project/screens/recipe/recommend_screen.dart';
import 'package:food_project/widgets/recipe_widget.dart';
import 'package:page_transition/page_transition.dart';


class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  int selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    // Get list of recipes
    List<Recipe> recipeList = Recipe.recipeList;

    // Recipe categories
    List<String> recipeTypes = [
      'All',
      'Appetizers',
      'Main Dishes',
      'Side Dishes',
      'Desserts',
      'Beverages',
    ];

    bool toggleIsFavorated(bool isFavorited) {
      return !isFavorited;
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    'Best Recipe For You',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Constants.blackColor,
                    ),
                  ),
                  const Spacer(),
                  Padding(
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: IconButton(
                      icon: Icon(
                        Icons.calendar_month,
                        size: 30,
                        color: Constants.blackColor,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MealScheduleScreen(),
                          ),
                        );
                      },
                      )
                    )
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 10),

            // Search Bar + Favorite Button Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    width: size.width * .65,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.black54.withOpacity(.6),
                        ),
                        Expanded(
                          child: TextField(
                            showCursor: true,
                            decoration: InputDecoration(
                              hintText: 'Search Recipe',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        Icon(
                          Icons.tune,
                          color: Colors.black54.withOpacity(.6),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                      width: 7), // Space between search and favorite button

                  // Favorite Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        List<Recipe> favoritedRecipes = recipeList
                            .where((recipe) => recipe.isFavorite)
                            .toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FavoriteScreen(
                                favoritedRecipes: favoritedRecipes),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 25,
                      ),
                    ),
                  ),
                  // Add button
                  const SizedBox(width: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.add,
                        color: Constants.blackColor,
                        size: 25,
                      ),
                      onPressed: () {
                        print("add icon pressed");
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Category Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: SizedBox(
                height: 30,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recipeTypes.length,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategoryIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 5),
                        decoration: BoxDecoration(
                          color: selectedCategoryIndex == index
                              ? Color(0xFF78d454)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border:
                              Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            recipeTypes[index],
                            style: TextStyle(
                              color: selectedCategoryIndex == index
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recommendation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextButton
                (onPressed: () => Navigator.push(
                  context, MaterialPageRoute(
                   builder: (context) =>
                  RecommendScreen(recipes: recipeList),)
                    ),
                child: const Text("See All"),
                )
              ],
            ),
          ),
            
            const SizedBox(height: 10),

            // Recipes 

            SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                Recipe.recipeList.length,
                (index) => GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        child: RecipeDetail(
                          recipe: Recipe.recipeList[index], // แก้จาก recipeList เป็น Recipe.recipeList
                          recipeId: Recipe.recipeList[index].recipeId,
                        ),
                        type: PageTransitionType.bottomToTop,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.only(left: 12),
                    margin: const EdgeInsets.only(right: 10),
                    width: 200,
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 130,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                image: DecorationImage(
                                  image: AssetImage(Recipe.recipeList[index].imageUrl),
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              Recipe.recipeList[index].category,
                              style: const TextStyle(
                                color: Color.fromARGB(179, 65, 64, 64),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              Recipe.recipeList[index].recipeName,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_filled_outlined,
                                  size: 18.0,
                                  color: Color(0xFF5CB77E),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${Recipe.recipeList[index].totalCookingTime()} min',
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey,
                                  ),
                                ),
                                const Text(
                                  " · ",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const Icon(
                                  Icons.local_fire_department_sharp,
                                  size: 18.0,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${Recipe.recipeList[index].Kcal} Kcal',
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          top: 1,
                          right: 4,
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                  color: Colors.grey.shade300, width: 1),
                            ),
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  Recipe.recipeList[index].isFavorite =
                                      !Recipe.recipeList[index].isFavorite;
                                });
                              },
                              icon: Icon(
                                Recipe.recipeList[index].isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Recipe.recipeList[index].isFavorite
                                    ? Colors.red
                                    : Colors.black54,
                              ),
                              iconSize: 20,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),


            
            // My Recipe
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Recipe',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextButton
                          (onPressed: () => Navigator.push(
                            context, MaterialPageRoute(
                            builder: (context) =>
                            MyrecipeScreen(recipes: recipeList),)
                              ),
                          child: const Text("See All"),
                          )
                        ],
                      ),
                    ),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: recipeList.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            child: RecipeDetail(
                              recipe: recipeList[index],
                              recipeId: recipeList[index].recipeId,
                            ),
                            type: PageTransitionType.bottomToTop,
                          ),
                        );
                      },
                      child: RecipeWidget(
                        index: index,
                        recipeScreenList: recipeList,
                        recipe: null,
                      ),
                    );
                  },
                ),
              ],
            ),
            // Recipe of The Week
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recipe of The Week',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                  TextButton
                    (onPressed: () => Navigator.push(
                      context, MaterialPageRoute(
                      builder: (context) =>
                      PoupularScreen(recipes: recipeList),)
                        ),
                    child: const Text("See All"),
                    )
                    ],
                  ),
                ),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: recipeList.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            child: RecipeDetail(
                              recipe: recipeList[index],
                              recipeId: recipeList[index].recipeId,
                            ),
                            type: PageTransitionType.bottomToTop,
                          ),
                        );
                      },
                      child: RecipeWidget(
                        index: index,
                        recipeScreenList: recipeList,
                        recipe: null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
