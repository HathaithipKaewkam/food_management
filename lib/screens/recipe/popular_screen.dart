import 'package:flutter/material.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/recipe/recipe_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PopularScreen extends StatefulWidget {
  final List<Map<String, dynamic>> popularRecipes;
  
  const PopularScreen({Key? key, required this.popularRecipes}) : super(key: key);

  @override
  State<PopularScreen> createState() => _PopularScreen();
}

class _PopularScreen extends State<PopularScreen> {
  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 10, left: 7, right: 7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        fixedSize: const Size(40, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back),
                      color: Colors.black,
                    ),
                    const Spacer(),
                    const Text(
                      "Popular Recipes",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        fixedSize: const Size(40, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22)
                        ),
                      ),
                      icon: const Icon(Icons.more_horiz),
                      color: Colors.black,
                    ),
                  ]
                ),
                
                widget.popularRecipes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 100.0),
                        child: Column(
                          children: [
                            Icon(Icons.restaurant, size: 50, color: Colors.grey),
                            SizedBox(height: 20),
                            Text(
                              'No popular recipes available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, 
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.85, 
                      ),
                      itemCount: widget.popularRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = widget.popularRecipes[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipeDetail(
                                recipeDocId: recipe['id']?.toString() ?? '0',
                                recipeId: recipe['id'] is int ? recipe['id'] : int.parse(recipe['id'].toString()),
                                recipe: Recipe(
                                  recipeId: recipe['id'] is int ? recipe['id'] : int.parse(recipe['id'].toString()),
                                  recipeName: recipe['title'] ?? '',
                                  description: '',
                                  ingredients: (recipe['ingredients'] as List<dynamic>? ?? []).map((ingredient) {
                                    return IngredientUsage(
                                      ingredient: Ingredient.fromAPI(
                                        id: ingredient['id']?.toString() ?? '',
                                        name: ingredient['name'] ?? '',
                                        amount: ingredient['amount']?.toDouble() ?? 0.0,
                                        unit: ingredient['unit'] ?? '',
                                      ),
                                      quantityUsed: ingredient['amount']?.toDouble() ?? 0.0,
                                    );
                                  }).toList(),
                                  instructions: (recipe['instructions'] as List<dynamic>? ?? [])
                                      .map((step) => step.toString())
                                      .toList(),
                                  preparationTime: int.tryParse(recipe['readyInMinutes']?.toString() ?? '0') ?? 0,
                                  cookingTime: 0,
                                  servings: recipe['servings'] ?? 1,
                                  category: recipe['dishTypes'] != null && recipe['dishTypes'] is List && (recipe['dishTypes'] as List).isNotEmpty
                                      ? (recipe['dishTypes'] as List)[0]
                                      : 'Main Course',
                                  imageUrl: recipe['image'] ?? '',
                                  Protein: recipe['nutrition']?['protein']?.toDouble() ?? 0.0,
                                  Fat: recipe['nutrition']?['fat']?.toDouble() ?? 0.0,
                                  Carbo: recipe['nutrition']?['carbs']?.toDouble() ?? 0.0,
                                  Kcal: recipe['nutrition']?['calories']?.toInt() ?? 0,
                                  isFavorite: false,
                                ),
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: SizedBox(
                              width: double.infinity,
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Container(
                                          width: double.infinity,
                                          height: 130,
                                          child: Image.network(
                                            recipe['image'] ?? '',
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: Icon(Icons.broken_image, size: 50, color: Colors.grey[700]),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        recipe['title'] ?? 'Unknown Recipe',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time_filled_outlined,
                                            size: 18,
                                            color: Color(0xFF5CB77E),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${recipe['readyInMinutes'] ?? 0} min',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const Text(
                                            " · ",
                                            style: TextStyle(color: Colors.black),
                                          ),
                                          const Icon(
                                            Icons.local_fire_department_sharp,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${recipe['nutrition']?['calories'] ?? 0} Kcal',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}