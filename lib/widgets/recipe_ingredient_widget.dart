import 'package:flutter/material.dart';
import 'package:food_project/models/recipe.dart';


class RecipeIngredientWidget extends StatefulWidget {
  final List<IngredientUsage> ingredients; // รับ List<Ingredient>
  final Recipe recipe;
  final int currentNumber;

  const RecipeIngredientWidget({
    super.key,
    required this.ingredients,
    required this.recipe,
    required this.currentNumber,
  });

  @override
  State<RecipeIngredientWidget> createState() => _RecipeIngredientWidgetState();
}

class _RecipeIngredientWidgetState extends State<RecipeIngredientWidget> {

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
            final ingredient = ingredientUsage.ingredient; // ดึงข้อมูลวัตถุดิบ
            final adjustedQuantityUsed = ingredientUsage.quantityUsed *
                widget.currentNumber /
                widget.recipe.servings;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  // รูปภาพวัตถุดิบ
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image: AssetImage(ingredient.imageUrl),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ชื่อวัตถุดิบ
                  Text(
                    ingredient.ingredientsName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // ปริมาณที่ใช้
                  Text(
                    '${adjustedQuantityUsed.toStringAsFixed(2)} ${ingredient.unit}', // จำนวน + หน่วย
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
