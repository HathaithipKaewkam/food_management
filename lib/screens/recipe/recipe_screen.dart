import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/screens/recipe/create_recipe.dart';
import 'package:food_project/screens/recipe/myrecipe_screen.dart';
import 'package:food_project/screens/recipe/popular_screen.dart';
import 'package:food_project/screens/recipe/week_screen.dart';
import 'package:food_project/screens/recipe/recipe_detail.dart';
import 'package:food_project/screens/recipe/recommend_screen.dart';
import 'package:food_project/screens/recipe/schedule_screen.dart';
import 'package:food_project/services/popular_recipe_service.dart';
import 'package:food_project/services/recipe_reccomend_service.dart';
import 'package:food_project/services/recipe_service.dart';
import 'package:food_project/widgets/recipe_widget.dart';
import 'package:page_transition/page_transition.dart';

class RecipeScreen extends StatefulWidget {
  final bool isSelecting;
  final DateTime? preselectedDate;
  final String? preselectedMealType;

  const RecipeScreen({
    Key? key,
    this.isSelecting = false,
    this.preselectedDate,
    this.preselectedMealType,
  }) : super(key: key);
  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  int selectedCategoryIndex = 0;
  final RecipeRecommendationService _recommendationService =
      RecipeRecommendationService();
  List<Map<String, dynamic>> recommendedRecipes = [];
  bool isLoading = true;
  List<Recipe> userRecipes = [];
  bool isLoadingUserRecipes = true;
  List<Map<String, dynamic>> weeklyRecipes = [];
  bool isLoadingWeeklyRecipes = true;
  final RecipeService _recipeService = RecipeService();
  List<Map<String, dynamic>> popularRecipes = [];
  bool isLoadingPopularRecipes = true;
  final PopularRecipeService _popularRecipeService = PopularRecipeService();
  List<Map<String, dynamic>> topUserPreferenceRecipes = [];
bool isLoadingTopRecipe = true;
 final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _loadUserRecipes();
    _loadPopularRecipes();
    _loadTopUserPreferenceRecipe();
  }

   @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  int _safeParseInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    if (value is double) {
      return value.toInt();
    }

    return 0;
  }

  Future<void> _loadUserRecipes() async {
    print('Starting to load user recipes...');
    try {
      setState(() {
        isLoadingUserRecipes = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userRecipesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('userRecipe')
            .orderBy('createdAt', descending: true)
            .get();

        print(
            'Found ${userRecipesSnapshot.docs.length} user recipes in Firestore');

        List<Recipe> loadedRecipes = [];

        for (var doc in userRecipesSnapshot.docs) {
          try {
            final data = doc.data();

            // แปลงข้อมูล ingredients จาก Firestore เป็น IngredientUsage objects
            List<IngredientUsage> ingredients = [];
            if (data.containsKey('ingredients') &&
                data['ingredients'] is List) {
              for (var ingData in (data['ingredients'] as List<dynamic>)) {
                if (ingData is Map<String, dynamic>) {
                  final ingredient = Ingredient(
                    ingredientsName: ingData['name'] ?? '',
                    unit: ingData['unit'] ?? '',
                    quantity: 0,
                    minQuantity: 0,
                    category: 'Other',
                    storage: 'Pantry',
                    source: 'Recipe',
                    userId: user.uid,
                    ingredientId:
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    imageUrl: 'assets/images/ingredient_placeholder.png',
                    expirationDate: DateTime.now().add(Duration(days: 30)),
                    kcal: 0,
                  );

                  ingredients.add(IngredientUsage(
                    ingredient: ingredient,
                    quantityUsed: (ingData['amount'] ?? 0).toDouble(),
                  ));
                }
              }
            }

            // สร้าง Recipe object จากข้อมูลใน Firestore
            Recipe recipe = Recipe(
              recipeId: data['recipeId'] ?? 0,
              recipeName: data['recipeName'] ?? '',
              description: data['description'] ?? '',
              ingredients: ingredients,
              instructions: List<String>.from(data['instructions'] ?? []),
              preparationTime: data['preparationTime'] ?? 0,
              cookingTime: data['cookingTime'] ?? 0,
              servings: data['servings'] ?? 1,
              category: data['category'] ?? 'Other',
              imageUrl: data['imageUrl'] ?? '',
              Protein: (data['Protein'] ?? 0).toDouble(),
              Fat: (data['Fat'] ?? 0).toDouble(),
              Carbo: (data['Carbo'] ?? 0).toDouble(),
              Kcal: data['Kcal'] ?? 0,
              isFavorite: data['isFavorite'] ?? false,
              recipeDocId: doc.id,
              createdBy: data['createdBy'],
            );

            loadedRecipes.add(recipe);
          } catch (e) {
            print('Error parsing recipe ${doc.id}: $e');
            // ข้ามข้อมูลที่มีปัญหาและทำงานต่อ
          }
        }

        print('Finished loading ${loadedRecipes.length} recipes');

        setState(() {
          userRecipes = loadedRecipes;
          isLoadingUserRecipes = false;
        });
      } else {
        setState(() {
          isLoadingUserRecipes = false;
          userRecipes = [];
        });
      }
    } catch (e) {
      print('Error loading user recipes: $e');
      setState(() {
        isLoadingUserRecipes = false;
      });
    }
  }

  List<Map<String, dynamic>> _convertRecipeData(
      List<Map<String, dynamic>> recipes) {
    return recipes.map((recipe) {
      // แปลง extendedIngredients เป็น ingredients ถ้าจำเป็น
      if (recipe.containsKey('extendedIngredients') &&
          !recipe.containsKey('ingredients')) {
        recipe['ingredients'] = recipe['extendedIngredients'];
      }

      // แปลง analyzedInstructions เป็น instructions ถ้าจำเป็น
      if (recipe.containsKey('analyzedInstructions') &&
          !recipe.containsKey('instructions')) {
        List<String> steps = [];
        for (var instruction in recipe['analyzedInstructions']) {
          if (instruction != null && instruction.containsKey('steps')) {
            for (var step in instruction['steps']) {
              if (step != null && step.containsKey('step')) {
                steps.add(step['step']);
              }
            }
          }
        }
        recipe['instructions'] = steps;
      }

      return recipe;
    }).toList();
  }

  Future<void> _loadTopUserPreferenceRecipe() async {
    try {
      setState(() {
        isLoadingTopRecipe = true;
      });

      final recipes = await _recipeService.getTopRecipeByUserPreference();

      if (mounted) {
        setState(() {
          topUserPreferenceRecipes = recipes; 
          isLoadingTopRecipe = false;
        });
      }
    } catch (e) {
      print('❌ Error loading top recipe by user preference: $e');
      if (mounted) {
        setState(() {
          isLoadingTopRecipe = false;
        });
      }
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(() {
        isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final recipes =
            await _recommendationService.getRecommendedRecipes(user.uid);

        if (recipes.isNotEmpty) {
          print('First recipe: ${recipes[0]['title']}');
        }

        if (mounted) {
          setState(() {
            recommendedRecipes = recipes;
            isLoading = false;
          });
        }
      } else {
        print('⚠️ No user logged in');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading recommendations: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          recommendedRecipes = [];
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPopularRecipes() async {
    try {
      setState(() {
        isLoadingPopularRecipes = true;
      });

      print("🔍 Starting to load popular Thai recipes");
      final recipes = await _popularRecipeService.getPopularRecipes(
          limit: 10, cuisine: 'Thai');

      print("📊 Found ${recipes.length} popular Thai recipes");

      if (mounted) {
        setState(() {
          popularRecipes = recipes;
          isLoadingPopularRecipes = false;
        });
      }
    } catch (e) {
      print('❌ Error loading popular recipes: $e');
      if (mounted) {
        setState(() {
          isLoadingPopularRecipes = false;
        });
      }
    }
  }

   void _searchRecipes(String query) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  
  _debounce = Timer(const Duration(milliseconds: 500), () async {
    if (query.trim().isEmpty) {
      setState(() {
        searchQuery = '';
        isSearching = false;
        searchResults = [];
      });
      return;
    }
    
    setState(() {
      isSearching = true;
      searchQuery = query.trim().toLowerCase();
    });
    
    try {
      // ค้นหาแบบ Server-side จาก API
      final apiResults = await _recipeService.searchRecipes(searchQuery);
      
      // ค้นหาจาก user recipes เพิ่มเติม (เนื่องจาก API ไม่มีข้อมูลนี้)
      final userRecipeResults = userRecipes.where((recipe) {
        return recipe.recipeName.toLowerCase().contains(searchQuery);
      }).map((recipe) {
        return {
          'id': recipe.recipeId,
          'title': recipe.recipeName,
          'image': recipe.imageUrl,
          'readyInMinutes': recipe.preparationTime + recipe.cookingTime,
          'servings': recipe.servings,
          'summary': recipe.description,
          'ingredients': recipe.ingredients.map((ing) => {
            'id': ing.ingredient.ingredientId,
            'name': ing.ingredient.ingredientsName,
            'amount': ing.quantityUsed,
            'unit': ing.ingredient.unit,
          }).toList(),
          'instructions': recipe.instructions,
          'dishTypes': [recipe.category],
          'nutrition': {
            'protein': recipe.Protein,
            'fat': recipe.Fat,
            'carbs': recipe.Carbo,
            'calories': recipe.Kcal,
          },
          'isUserRecipe': true,
          'recipeDocId': recipe.recipeDocId,
        };
      }).toList();
      
      // รวมผลลัพธ์ทั้งหมด
      List<Map<String, dynamic>> allResults = [];
      allResults.addAll(apiResults);
      allResults.addAll(userRecipeResults);
      
      // ตัดข้อมูลซ้ำออกตาม ID
      final Map<dynamic, Map<String, dynamic>> uniqueResults = {};
      for (var recipe in allResults) {
        if (!uniqueResults.containsKey(recipe['id'])) {
          uniqueResults[recipe['id']] = recipe;
        }
      }
      
      setState(() {
        searchResults = uniqueResults.values.toList();
        isSearching = false;
      });
    } catch (e) {
      print("Error searching recipes: $e");
      setState(() {
        isSearching = false;
      });
    }
  });
}

  @override
  Widget build(BuildContext context) {
    print("DEBUG: RecipeScreen.build - isSelecting: ${widget.isSelecting}");
    Size size = MediaQuery.of(context).size;

    List<Recipe> recipeList = [];

    List<String> recipeTypes = [
      'All',
      'Breakfast',
      'Lunch',
      'Dinner',
      'Appetizers',
      'Main Dishes',
      'Side Dishes',
      'Soups',
      'Snacks',
      'Desserts',
      'Beverages',
    ];

    

    List<String> _extractInstructionsFromAnalyzed(
        List<dynamic> analyzedInstructions) {
      List<String> instructions = [];
      for (var instruction in analyzedInstructions) {
        if (instruction != null && instruction.containsKey('steps')) {
          for (var step in instruction['steps']) {
            if (step != null && step.containsKey('step')) {
              instructions.add(step['step']);
            }
          }
        }
      }
      return instructions;
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
                                    builder: (context) =>
                                        const ScheduleScreen(),
                                  ),
                                );
                              },
                            )))
                  ],
                ),
              ),

              const SizedBox(height: 5),

              // Search Bar 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      width: size.width * .80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1),
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
  controller: searchController,
  onChanged: _searchRecipes,
  showCursor: true,
  decoration: InputDecoration(
    hintText: 'Search Recipe',
    hintStyle: TextStyle(color: Colors.grey.shade400),
    border: InputBorder.none,
    suffixIcon: searchController.text.isNotEmpty 
      ? IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            searchController.clear();
            _searchRecipes('');
          },
        )
      : null,
  ),
  style: const TextStyle(color: Colors.black),
),
                          ),
                        ],
                      ),
                    ),

                    // Add button
                    const SizedBox(width: 5),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1),
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
                          _showCreateRecipeModal(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
               if (searchQuery.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Results for "${searchQuery}"',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${searchResults.length} found',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                  isSearching
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              color: Color(0xFF5CB77E),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Searching for "${searchQuery}"...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                     : searchResults.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No recipes found for "${searchQuery}"',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Try different keywords or ingredients',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                        : ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final recipe = searchResults[index];
                          final bool isUserRecipe = recipe['isUserRecipe'] == true;
                          
                          final ingredients = (recipe['ingredients'] as List<dynamic>? ?? []).map((ingredient) {
                            return IngredientUsage(
                              ingredient: Ingredient.fromAPI(
                                id: ingredient['id']?.toString() ?? '',
                                name: ingredient['name'] ?? '',
                                amount: ingredient['amount']?.toDouble() ?? 0.0,
                                unit: ingredient['unit'] ?? '',
                              ),
                              quantityUsed: ingredient['amount']?.toDouble() ?? 0.0,
                            );
                          }).toList();
                          
                          final instructions = (recipe['instructions'] as List<dynamic>? ?? [])
                              .map((step) => step.toString())
                              .toList();
                               return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageTransition(
                                  child: RecipeDetail(
                                    recipeId: _safeParseInt(recipe['id']),
                                    recipeDocId: recipe['recipeDocId'] ?? recipe['id'].toString(),
                                    recipe: Recipe(
                                      recipeId: _safeParseInt(recipe['id']),
                                      recipeName: recipe['title'] ?? '',
                                      description: recipe['summary'] ?? '',
                                      ingredients: ingredients,
                                      instructions: instructions,
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
                                  type: PageTransitionType.bottomToTop,
                                ),
                              );
                            },
                               child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              margin: EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // รูปภาพอาหาร
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      recipe['image'] ?? '',
                                      width: 100,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 100, 
                                          height: 80,
                                          color: Colors.grey[200],
                                          child: Icon(Icons.image_not_supported, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                   Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // สัญลักษณ์แสดงว่าเป็น user recipe
      if (isUserRecipe)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          margin: EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'My Recipe',
            style: TextStyle(
              color: Colors.green[800],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      // ชื่อสูตรอาหาร
      Text(
        recipe['title'] ?? '',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      SizedBox(height: 4),
      // ประเภทอาหาร
      Text(
        recipe['dishTypes'] != null && recipe['dishTypes'] is List && (recipe['dishTypes'] as List).isNotEmpty
            ? (recipe['dishTypes'] as List)[0]
            : 'Main Course',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
      SizedBox(height: 4),
      // เวลาและแคลอรี่
      Row(
        children: [
          Icon(Icons.timer, size: 16, color: Colors.grey[600]),
          SizedBox(width: 4),
          Text(
            '${recipe['readyInMinutes'] ?? 0} min',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.local_fire_department, size: 16, color: Colors.red[400]),
          SizedBox(width: 4),
          Text(
            '${recipe['nutrition']?['calories']?.toInt() ?? 0} kcal',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ],
      ),
    ],
  ),
),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            )
          else
          SizedBox(height: 10),
          Column (
            children : [

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
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1),
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
                    TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecommendScreen(
                              recipes: recipeList,
                              recommendedRecipes: recommendedRecipes,
                            ),
                          )),
                      child: const Text(
                        "See All",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Recipes Recommendation

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF5CB77E),
                        ),
                      )
                    : Row(
                        children: recommendedRecipes.isEmpty
                            ? [
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No recommendations available'),
                                )
                              ]
                            : recommendedRecipes.map((recipe) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Container(
                                    width: 200,
                                    height: 240,
                                    margin: const EdgeInsets.only(right: 10),
                                    child: GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => RecipeDetail(
                                            recipeId: recipe['id'] is int
                                                ? recipe['id']
                                                : int.parse(
                                                    recipe['id'].toString()),
                                            recipeDocId:
                                                recipe['id'].toString(),
                                            recipe: Recipe(
                                              recipeId: recipe['id'] is int
                                                  ? recipe['id']
                                                  : int.parse(
                                                      recipe['id'].toString()),
                                              recipeName: recipe['title'] ?? '',
                                              description:
                                                  recipe['summary'] ?? '',
                                              ingredients:
                                                  (recipe['extendedIngredients']
                                                              as List<
                                                                  dynamic>? ??
                                                          [])
                                                      .map((ingredient) {
                                                return IngredientUsage(
                                                  ingredient:
                                                      Ingredient.fromAPI(
                                                    id: ingredient['id']
                                                            ?.toString() ??
                                                        '',
                                                    name: ingredient['name'] ??
                                                        '',
                                                    amount: ingredient['amount']
                                                            ?.toDouble() ??
                                                        0.0,
                                                    unit: ingredient['unit'] ??
                                                        '',
                                                  ),
                                                  quantityUsed:
                                                      ingredient['amount']
                                                              ?.toDouble() ??
                                                          0.0,
                                                );
                                              }).toList(),
                                              instructions: (recipe[
                                                              'instructions']
                                                          as List<dynamic>? ??
                                                      [])
                                                  .map(
                                                      (step) => step.toString())
                                                  .toList(),
                                              preparationTime: int.tryParse(
                                                      recipe['readyInMinutes']
                                                              ?.toString() ??
                                                          '0') ??
                                                  0,
                                              cookingTime: 0,
                                              servings: recipe['servings'] ?? 1,
                                              category: (recipe['dishTypes']
                                                              as List<
                                                                  dynamic>? ??
                                                          [])
                                                      .isNotEmpty
                                                  ? recipe['dishTypes'][0]
                                                  : 'Main Course',
                                              imageUrl: recipe['image'] ?? '',
                                              Protein: recipe['nutrition']
                                                          ?['protein']
                                                      ?.toDouble() ??
                                                  0.0,
                                              Fat: recipe['nutrition']?['fat']
                                                      ?.toDouble() ??
                                                  0.0,
                                              Carbo: recipe['nutrition']
                                                          ?['carbs']
                                                      ?.toDouble() ??
                                                  0.0,
                                              Kcal: recipe['nutrition']
                                                          ?['calories']
                                                      ?.toInt() ??
                                                  0,
                                              isFavorite:
                                                  recipe['isFavorite'] ?? false,
                                            ),
                                          ),
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 200,
                                                height: 130,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  child: Image.network(
                                                    recipe['image'] ?? '',
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: 130,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Container(
                                                        color: Colors.grey[200],
                                                        alignment:
                                                            Alignment.center,
                                                        child: const Icon(
                                                            Icons.broken_image,
                                                            size: 50,
                                                            color: Colors.grey),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                recipe['dishTypes']?.first ??
                                                    'Recipe',
                                                style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      179, 65, 64, 64),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 7),
                                              Text(
                                                recipe['title'] ??
                                                    'Untitled Recipe',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
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
                                                    Icons
                                                        .access_time_filled_outlined,
                                                    size: 18.0,
                                                    color: Color(0xFF5CB77E),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    '${recipe['readyInMinutes'] ?? 0} min',
                                                    style: const TextStyle(
                                                      fontSize: 12.0,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  const Text(
                                                    " · ",
                                                    style: TextStyle(
                                                        color: Colors.grey),
                                                  ),
                                                  const Icon(
                                                    Icons
                                                        .local_fire_department_sharp,
                                                    size: 18.0,
                                                    color: Colors.red,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    '${recipe['nutrition']?['calories'] ?? 0} Kcal',
                                                    style: const TextStyle(
                                                      fontSize: 12.0,
                                                      color: Colors.grey,
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
                              }).toList(),
                      ),
              ),

              // My Recipe
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
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MyrecipeScreen(recipes: recipeList),
                            ),
                          ).then((_) {
                            // รีโหลดข้อมูลเมื่อกลับมา
                            _loadUserRecipes();
                          }),
                          child: const Text(
                            "See All",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  // แสดง UI ตามสถานะของ userRecipes (ไม่ใช้ StreamBuilder)
                  isLoadingUserRecipes
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFF5CB77E),
                            ),
                          ),
                        )
                      : userRecipes.isEmpty
                          ? Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 30.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.restaurant_menu,
                                      size: 50,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'You haven\'t created any recipes yet',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        _showCreateRecipeModal(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF78d454),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text('Create Recipe'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: userRecipes.length > 5
                                  ? 5
                                  : userRecipes.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    if (widget.isSelecting) {
                                      Navigator.pop(
                                          context, userRecipes[index]);
                                    } else {
                                      Navigator.push(
                                        context,
                                        PageTransition(
                                          child: RecipeDetail(
                                            recipe: userRecipes[index],
                                            recipeId:
                                                userRecipes[index].recipeId,
                                            recipeDocId: userRecipes[index]
                                                    .recipeDocId ??
                                                userRecipes[index]
                                                    .recipeId
                                                    .toString(),
                                          ),
                                          type: PageTransitionType.bottomToTop,
                                        ),
                                      ).then((_) {
                                        // รีโหลดข้อมูลเมื่อกลับมา
                                        _loadUserRecipes();
                                      });
                                    }
                                  },
                                  child: RecipeWidget(
                                    index: index,
                                    recipeScreenList: userRecipes,
                                    recipe: null,
                                    isSelecting: widget.isSelecting,
                                    preselectedDate: widget.preselectedDate,
                                    preselectedMealType:
                                        widget.preselectedMealType,
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
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WeekScreen(
                                  weeklyRecipes: topUserPreferenceRecipes,
                              ),
                            ),
                          ),
                          child: const Text(
                            "See All",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  isLoadingTopRecipe
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFF5CB77E),
                            ),
                          ),
                        )
                      : topUserPreferenceRecipes.isEmpty
                          ? Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 30.0),
                                child: Text(
                                  'No weekly recipes available',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: 5,
                              itemBuilder: (context, index) {
                                final recipe = topUserPreferenceRecipes[index]; 
                                return GestureDetector(
                                  onTap: () {
                                    if (widget.isSelecting) {
                                    Navigator.pop(context, recipe);
                                    } else {
                                        Navigator.push(
                    context,
                    PageTransition(
                      child: RecipeDetail(
                        recipeId: recipe['id'] is int
                            ? recipe['id']
                            : int.parse(recipe['id'].toString()),
                        recipeDocId: recipe['id'].toString(),
                        recipe: Recipe(
                          recipeId: recipe['id'] is int
                              ? recipe['id']
                              : int.parse(recipe['id'].toString()),
                          recipeName: recipe['title'] ?? '',
                          description: recipe['summary'] ?? '',
                          ingredients: (recipe['ingredients'] as List<dynamic>? ?? [])
                              .map((ingredient) {
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
                                              preparationTime: int.tryParse(
                                  recipe['readyInMinutes']?.toString() ?? '0') ??
                              0,
                          cookingTime: 0,
                          servings: recipe['servings'] ?? 1,
                          category: recipe['dishTypes'] != null &&
                                  recipe['dishTypes'] is List &&
                                  (recipe['dishTypes'] as List).isNotEmpty
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
                                          type: PageTransitionType.bottomToTop,
                                        ),
                                      );
                                    }
                                  },
                                  child: RecipeWidget(
                                    index: index,
                                    recipeScreenList: null,
                                    isSelecting: widget.isSelecting,
                                    preselectedDate: widget.preselectedDate,
                                    preselectedMealType:
                                        widget.preselectedMealType,
                                    recipe: Recipe(
                                       recipeId: _safeParseInt(recipe['id']),
                  recipeName: recipe['title'] ?? '',
                  description: recipe['summary'] ?? '',
                  ingredients: (recipe['ingredients'] as List<dynamic>? ?? [])
                      .map((ingredient) {
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
                  preparationTime: int.tryParse(
                          recipe['readyInMinutes']?.toString() ?? '0') ??
                      0,
                  cookingTime: 0,
                  servings: recipe['servings'] ?? 1,
                  category: recipe['dishTypes'] != null &&
                          recipe['dishTypes'] is List &&
                          (recipe['dishTypes'] as List).isNotEmpty
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
                                );
                              },
                            ),
                ],
              ),
              // Popular Recipes
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
                          'Popular Recipes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PopularScreen(
                                popularRecipes: popularRecipes,
                              ),
                            ),
                          ),
                          child: const Text(
                            "See All",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  isLoadingPopularRecipes
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFF5CB77E),
                            ),
                          ),
                        )
                      : popularRecipes.isEmpty
                          ? Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 30.0),
                                child: Text(
                                  'No popular recipes available',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: popularRecipes.length > 3
                                  ? 3
                                  : popularRecipes.length,
                              itemBuilder: (context, index) {
                                final recipe = popularRecipes[index];
                                final ingredients = (recipe['ingredients'] as List<dynamic>? ?? []).map((ingredient) {
      return IngredientUsage(
        ingredient: Ingredient.fromAPI(
          id: ingredient['id']?.toString() ?? '',
          name: ingredient['name'] ?? '',
          amount: ingredient['amount']?.toDouble() ?? 0.0,
          unit: ingredient['unit'] ?? '',
        ),
        quantityUsed: ingredient['amount']?.toDouble() ?? 0.0,
      );
    }).toList();

    final instructions = (recipe['instructions'] as List<dynamic>? ?? []).map((step) {
      return step.toString();
    }).toList();
                                return GestureDetector(
                                  onTap: () {
                                    if (widget.isSelecting) {
                                      Navigator.pop(
                                          context, userRecipes[index]);
                                    } else {
                                      Navigator.push(
                                        context,
                                        PageTransition(
                                                     child: RecipeDetail(
              recipeId: recipe['id'] is int ? recipe['id'] : int.parse(recipe['id'].toString()),
              recipeDocId: recipe['id'].toString(),
              recipe: Recipe(
                recipeId: recipe['id'] is int ? recipe['id'] : int.parse(recipe['id'].toString()),
                recipeName: recipe['title'] ?? '',
                description: recipe['summary'] ?? '',
                ingredients: ingredients, // ส่ง ingredients ที่แปลงแล้ว
                instructions: instructions, // ส่ง instructions ที่แปลงแล้ว
                preparationTime: int.tryParse(recipe['readyInMinutes']?.toString() ?? '0') ?? 0,
                cookingTime: 0,
                servings: recipe['servings'] ?? 1,
                category: recipe['dishTypes'] != null &&
                        recipe['dishTypes'] is List &&
                        (recipe['dishTypes'] as List).isNotEmpty
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
                                          type: PageTransitionType.bottomToTop,
                                        ),
                                      );
                                    }
                                  },
                                  child: RecipeWidget(
                                     index: 0,
        recipeScreenList: null,
        isSelecting: widget.isSelecting,
        preselectedDate: widget.preselectedDate,
        preselectedMealType: widget.preselectedMealType,
        recipe: Recipe(
          recipeId: recipe['id'] is int ? recipe['id'] : int.parse(recipe['id'].toString()),
          recipeName: recipe['title'] ?? '',
          description: '',
          ingredients: ingredients, // ส่ง ingredients ที่แปลงแล้ว
          instructions: instructions, // ส่ง instructions ที่แปลงแล้ว
          preparationTime: int.tryParse(recipe['readyInMinutes']?.toString() ?? '0') ?? 0,
          cookingTime: 0,
          servings: recipe['servings'] ?? 1,
          category: recipe['dishTypes'] != null &&
                  recipe['dishTypes'] is List &&
                  (recipe['dishTypes'] as List).isNotEmpty
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
                                );
                              },
                            ),
                ],
              ),
            ]
            )
              ]
              ),  ));
  }


void _showCreateRecipeModal(BuildContext context) {
  final TextEditingController recipeNameController = TextEditingController();
  final TextEditingController cookingTimeController = TextEditingController();
  final TextEditingController servingsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Recipe',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Recipe Name Section Header
              Text(
                'Recipe Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),

              // Recipe Name Field
              TextFormField(
                controller: recipeNameController,
                maxLength: 50,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter recipe name',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.restaurant_menu),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a recipe name';
                  }
                  if (value.length < 3) {
                    return 'Recipe name must be at least 3 characters';
                  }
                  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                    return 'Only letters and spaces are allowed';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Cooking Details Section Header
              Text(
                'Cooking Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),

              // Cooking Time and Servings in same row
              Row(
                children: [
                  // Cooking Time Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cooking Time',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 6),
                        TextFormField(
                          controller: cookingTimeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            hintText: 'Minutes',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.timer),
                            suffixText: 'min',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            int? parsedValue = int.tryParse(value);
                            if (parsedValue == null) {
                              return 'Numbers only';
                            }
                            if (parsedValue <= 0) {
                              return 'Must be greater than 0';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),

                  // Servings Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Servings',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 6),
                        TextFormField(
                          controller: servingsController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            hintText: 'People',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.people),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            int? parsedValue = int.tryParse(value);
                            if (parsedValue == null) {
                              return 'Numbers only';
                            }
                            if (parsedValue <= 0) {
                              return 'Must be greater than 0';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Instructions text
              Text(
                'Continue to add ingredients and instructions on the next screen',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 16),

              // Buttons (Cancel and Create)
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.grey[200],
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),

                  // Create Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // เก็บข้อมูลเบื้องต้น
                          final initialRecipeData = {
                            'recipeName': recipeNameController.text,
                            'totalCookingTime':
                                int.parse(cookingTimeController.text),
                            'servings': int.parse(servingsController.text),
                          };

                          Navigator.pop(context);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateRecipeScreen(
                                initialData: initialRecipeData,
                                onRecipeCreated: () {
                                  if (context.findAncestorStateOfType<
                                          _RecipeScreenState>() !=
                                      null) {
                                    context
                                        .findAncestorStateOfType<
                                            _RecipeScreenState>()!
                                        ._loadUserRecipes();
                                  }
                                },
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFF78d454),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
}