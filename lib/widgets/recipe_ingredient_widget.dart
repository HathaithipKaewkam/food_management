import 'package:flutter/material.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/models/recipe.dart';


class RecipeIngredientWidget extends StatefulWidget {
 final List<IngredientUsage> ingredients;
  final Recipe recipe;
  final int currentNumber;
  final List<Map<String, dynamic>> userIngredients;
  const RecipeIngredientWidget({
    super.key,
    required this.ingredients,
    required this.recipe,
    required this.currentNumber,
     required this.userIngredients,
  });

  @override
  State<RecipeIngredientWidget> createState() => _RecipeIngredientWidgetState();
}

class _RecipeIngredientWidgetState extends State<RecipeIngredientWidget> {

   bool _hasIngredient(Ingredient recipeIngredient) {
  return widget.userIngredients.any((userIngredient) => 
      userIngredient['ingredient'] != null && 
      userIngredient['ingredient']['ingredientsName'] != null &&
      userIngredient['ingredient']['ingredientsName'].trim().toLowerCase() == 
      recipeIngredient.ingredientsName.trim().toLowerCase());
}

  Map<String, dynamic>? _getUserIngredient(Ingredient recipeIngredient) {
  try {
    return widget.userIngredients.firstWhere((userIngredient) => 
        userIngredient['ingredient'] != null && 
        userIngredient['ingredient']['ingredientsName'] != null &&
        userIngredient['ingredient']['ingredientsName'].trim().toLowerCase() == 
        recipeIngredient.ingredientsName.trim().toLowerCase());
  } catch (e) {
    return null;
  }
}

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Ingredients",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    
                    print("Add all ingredients to cart");
                  }, 
                  child: Text("Add All to Cart"), 
                ),
                
                
              ],
            ),
           
                Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "${widget.ingredients.length} items",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
            
          ],
        ),
        const SizedBox(height: 10),
        // Ingredient List
         Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.ingredients.map((ingredientUsage) {
            final ingredient = ingredientUsage.ingredient;
            final adjustedQuantityUsed = ingredientUsage.quantityUsed *
                widget.currentNumber /
                widget.recipe.servings;
            
            
            final hasIngredient = _hasIngredient(ingredient);
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Card(
                elevation: 1,
                color: Colors.white, 
                margin: EdgeInsets.zero,
                
                
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    children: [
                      // ไอคอนด้านซ้าย
                     Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: hasIngredient 
                            ? const Color(0xFF78d454).withOpacity(0.2) 
                            : Colors.redAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12), // สี่เหลี่ยมมน
                        ),
                        child: Center(
                          child: Icon(
                            Icons.dining, 
                            color: hasIngredient ? const Color(0xFF78d454) : Colors.redAccent,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // เนื้อหาหลัก (ชื่อและปริมาณ)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ingredient.ingredientsName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${adjustedQuantityUsed.toStringAsFixed(2)} ${ingredient.unit}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}