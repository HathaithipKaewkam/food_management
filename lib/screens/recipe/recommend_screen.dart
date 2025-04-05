import 'package:flutter/material.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/screens/recipe/recipe_detail.dart';


class RecommendScreen extends StatefulWidget {
  final List<Recipe> recipes;
  final List<Map<String, dynamic>>? recommendedRecipes; // Add parameter for recommended recipes
  
  const RecommendScreen({
    Key? key, 
    required this.recipes, 
    this.recommendedRecipes, // Make it optional with default value
  }) : super(key: key);

  @override
  State<RecommendScreen> createState() => _RecommendScreen();
}

class _RecommendScreen extends State<RecommendScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.only(left: 7 , right: 7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  fixedSize: const Size(40, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.arrow_back),
                color: Colors.black,
              ),
              const Spacer(),
              const Text(
                "Recommend recipe",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  fixedSize: const Size(40, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22)),
                ),
                icon: const Icon(Icons.more_horiz),
                color: Colors.black,
              ),
            ]),
            
            // Display recommended recipes if available
            if (widget.recommendedRecipes != null && widget.recommendedRecipes!.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Number of columns
                  crossAxisSpacing: 15, // Spacing between columns
                  mainAxisSpacing: 20, // Spacing between rows
                  childAspectRatio: 0.7, // Adjust height of grid items
                ),
                itemCount: widget.recommendedRecipes!.length,
                itemBuilder: (context, index) {
                  final recipe = widget.recommendedRecipes![index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetail(
                          recipeDocId: recipe['id']?.toString() ?? '0',
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Recipe Image
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                ),
                                child: Image.network(
                                  recipe['image'] ?? '',
                                  width: double.infinity,
                                  height: 130,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 130,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Recipe Name
                                    Text(
                                      recipe['title'] ?? 'Untitled Recipe',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    // Cooking time and calories
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
                                            fontSize: 12,
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
                              ),
                            ],
                          ),
                          // Favorite button
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
                                  // Add favorite functionality if needed
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
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              // Original grid view for regular recipes
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15, 
                  mainAxisSpacing: 20,
                ),
                itemCount: widget.recipes.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetail(
                          recipeDocId: widget.recipes[index].recipeDocId ?? '0',
                          recipe: widget.recipes[index],
                          recipeId: widget.recipes[index].recipeId,
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
                              Container(
                                width: double.infinity,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  image: DecorationImage(
                                    image: AssetImage(widget.recipes[index].imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.recipes[index].recipeName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
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
                                    '${widget.recipes[index].totalCookingTime()} min',
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
                                    '${widget.recipes[index].Kcal} Kcal',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
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
                                    widget.recipes[index].isFavorite =
                                        !widget.recipes[index].isFavorite;
                                  });
                                },
                                icon: Icon(
                                  widget.recipes[index].isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: widget.recipes[index].isFavorite
                                      ? Colors.red
                                      : Colors.black54,
                                ),
                                iconSize: 20,
                              ),
                            ),
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
      )
    ),
  )
);
}
}