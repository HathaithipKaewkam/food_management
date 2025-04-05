import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/screens/recipe/create_recipe.dart';
import 'package:food_project/screens/recipe/favorite_screen.dart';
import 'package:food_project/screens/recipe/myrecipe_screen.dart';
import 'package:food_project/screens/recipe/poupular_screen.dart';
import 'package:food_project/screens/recipe/recipe_detail.dart';
import 'package:food_project/screens/recipe/recommend_screen.dart';
import 'package:food_project/screens/recipe/schedule_screen.dart';
import 'package:food_project/services/recipe_reccomend_service.dart';
import 'package:food_project/widgets/recipe_widget.dart';
import 'package:page_transition/page_transition.dart';


class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  int selectedCategoryIndex = 0;
  final RecipeRecommendationService _recommendationService = RecipeRecommendationService();
  List<Map<String, dynamic>> recommendedRecipes = [];
  bool isLoading = true;
  List<Recipe> userRecipes = [];
  bool isLoadingUserRecipes = true;
  


  @override
  void initState() {
    super.initState();
    _loadRecommendations();
     _loadUserRecipes();
  }

  Future<void> _loadUserRecipes() async {
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
            print('Found ${userRecipesSnapshot.docs.length} recipes in Firestore');

      List<Recipe> loadedRecipes = [];
      
      for (var doc in userRecipesSnapshot.docs) {
        final data = doc.data();
        
        // แปลงข้อมูล ingredients จาก Firestore เป็น IngredientUsage objects
        List<IngredientUsage> ingredients = [];
        for (var ingData in (data['ingredients'] as List<dynamic>? ?? [])) {
          final ingredient = Ingredient(
            ingredientsName: ingData['name'] ?? '',
            unit: ingData['unit'] ?? '',
            quantity: 0,
            minQuantity: 0,
            category: 'Other',
            storage: 'Pantry',
            source: 'Recipe',
            userId: user.uid,
            ingredientId: DateTime.now().millisecondsSinceEpoch.toString(),
            imageUrl: 'assets/images/ingredient_placeholder.png',
            expirationDate: DateTime.now().add(Duration(days: 30)),
            kcal: 0,
          );
          
          ingredients.add(IngredientUsage(
            ingredient: ingredient,
            quantityUsed: (ingData['amount'] ?? 0).toDouble(),
          ));
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
        );
        
        loadedRecipes.add(recipe);
      }
      
      if (mounted) {
        setState(() {
          userRecipes = loadedRecipes;
          isLoadingUserRecipes = false;
        });
      }
    } else {
      setState(() {
        isLoadingUserRecipes = false;
      });
    }
  } catch (e) {
    print('Error loading user recipes: $e');
    if (mounted) {
      setState(() {
        isLoadingUserRecipes = false;
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
     
      
    
      
      final recipes = await _recommendationService.getRecommendedRecipes(user.uid);
      
  
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




  @override
  Widget build(BuildContext context) {
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

    bool toggleIsFavorated(bool isFavorited) {
      return !isFavorited;
    }

    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 0 ),
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
                            builder: (context) => const ScheduleScreen(),
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
                      width: 10), 

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
                  const SizedBox(width: 10),
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
                          _showCreateRecipeModal(context);
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
                TextButton(
  onPressed: () => Navigator.push(
    context, 
    MaterialPageRoute(
      builder: (context) => RecommendScreen(
        recipes: recipeList,
        recommendedRecipes: recommendedRecipes,
      ),
    )
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
                    height: 250,
                    margin: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                        builder: (context) => RecipeDetail(
                          recipeId: int.tryParse(recipe['id']?.toString() ?? '0') ?? 0,
                          recipe: Recipe(
                            recipeId: int.tryParse(recipe['id']?.toString() ?? '0') ?? 0,
                            recipeName: recipe['title'] ?? '',
                            description: recipe['summary'] ?? '',
                            ingredients: (recipe['extendedIngredients'] as List<dynamic>? ?? []).map((ingredient) {
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
                            instructions: (recipe['analyzedInstructions']?[0]?['steps'] as List<dynamic>? ?? [])
                                .map((step) => step['step'].toString())
                                .toList(),
                            preparationTime: (recipe['preparationMinutes'] ?? 0),
                            cookingTime: (recipe['cookingMinutes'] ?? recipe['readyInMinutes'] ?? 0),
                            servings: recipe['servings'] ?? 1,
                            category: (recipe['dishTypes'] as List<dynamic>? ?? []).isNotEmpty 
                                ? recipe['dishTypes'][0] 
                                : 'Main Course',
                            imageUrl: recipe['image'] ?? '',
                            Protein: double.tryParse(recipe['nutrition']?['nutrients']
                                ?.firstWhere((n) => n['name'] == 'Protein', orElse: () => {'amount': '0'})['amount']
                                ?.toString() ?? '0') ?? 0.0,
                            Fat: double.tryParse(recipe['nutrition']?['nutrients']
                                ?.firstWhere((n) => n['name'] == 'Fat', orElse: () => {'amount': '0'})['amount']
                                ?.toString() ?? '0') ?? 0.0,
                            Carbo: double.tryParse(recipe['nutrition']?['nutrients']
                                ?.firstWhere((n) => n['name'] == 'Carbohydrates', orElse: () => {'amount': '0'})['amount']
                                ?.toString() ?? '0') ?? 0.0,
                            Kcal: int.tryParse(recipe['nutrition']?['nutrients']
                                ?.firstWhere((n) => n['name'] == 'Calories', orElse: () => {'amount': '0'})['amount']
                                ?.toString() ?? '0') ?? 0,
                            isFavorite: recipe['isFavorite'] ?? false,
                          ),
                        ),
                      ),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 200,
                                height: 130,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(
                                    recipe['image'] ?? '',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 130,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                recipe['dishTypes']?.first ?? 'Recipe',
                                style: const TextStyle(
                                  color: Color.fromARGB(179, 65, 64, 64),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                recipe['title'] ?? 'Untitled Recipe',
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
                                    Icons.access_time_filled_outlined,
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
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const Icon(
                                    Icons.local_fire_department_sharp,
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
                          Positioned(
                            top: 1,
                            right: 4,
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.grey.shade300, width: 1),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  // Handle favorite toggle
                                },
                                icon: Icon(
                                  recipe['isFavorite'] == true
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: recipe['isFavorite'] == true
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
                );
              }).toList(),
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
                          child: const Text("See All",
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
            padding: const EdgeInsets.symmetric(vertical: 30.0),
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
          itemCount: userRecipes.length > 3 ? 3 : userRecipes.length, 
          itemBuilder: (context, index) {
            print('Building recipe at index $index: ${userRecipes[index].recipeName}');
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageTransition(
                    child: RecipeDetail(
                      recipe: userRecipes[index],
                      recipeId: userRecipes[index].recipeId,
                    ),
                    type: PageTransitionType.bottomToTop,
                  ),
                   ).then((_) {
               
                _loadUserRecipes();
        }
                );
              },
              child: RecipeWidget(
                index: index,
                recipeScreenList: userRecipes,
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
                    child: const Text("See All",
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
         ) );
                    },
                  ),
                ],
              ),
           ] 
           ) 
            ));
}
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
        height: MediaQuery.of(context).size.height * 0.55, 
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
                              'totalCookingTime': int.parse(cookingTimeController.text),
                              'servings': int.parse(servingsController.text),
                            };
                            
                           
                            Navigator.pop(context);
                            
                          
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateRecipeScreen(
                                  initialData: initialRecipeData,
                                 
                                  onRecipeCreated: () {
                                  
                                    if (context.findAncestorStateOfType<_RecipeScreenState>() != null) {
                                      context.findAncestorStateOfType<_RecipeScreenState>()!._loadUserRecipes();
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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