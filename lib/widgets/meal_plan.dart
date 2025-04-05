import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/screens/recipe/recipe_detail.dart';
import 'package:page_transition/page_transition.dart';

class MealPlanRecipeWidget extends StatelessWidget {
  final Recipe recipe;
  final Function onDelete;
   final String? recipeId;

  const MealPlanRecipeWidget({
    required this.recipe,
     this.recipeId,
    required this.onDelete,
    Key? key,
  }) : super(key: key);

  Widget _buildRecipeImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 120,
        height: 120,
        color: Color(0xFFF5F5F5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 40,
              color: Color(0xFF5CB77E),
            ),
          ],
        ),
      );
    } else if (imageUrl.startsWith('http')) {
      // ใช้ Network Image สำหรับ URL จากอินเทอร์เน็ต
      return Image.network(
        imageUrl,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 120,
            height: 120,
            color: Color(0xFFF5F5F5),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
                color: Color(0xFF5CB77E),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 120,
            height: 120,
            color: Color(0xFFF5F5F5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 40,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text(
                  'Image Error',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // ใช้ Asset Image
      try {
        return Image.asset(
          imageUrl,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 120,
              height: 120,
              color: Color(0xFFF5F5F5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 40,
                    color: Color(0xFF5CB77E),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No Image',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } catch (e) {
        return Container(
          width: 120,
          height: 120,
          color: Color(0xFFF5F5F5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 40,
                color: Color(0xFF5CB77E),
              ),
              SizedBox(height: 8),
              Text(
                'No Image',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> userIngredients = [];
    return Dismissible(
      key: Key(recipe.recipeId.toString()), 
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        onDelete();
      },
      child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageTransition(
            child: RecipeDetail(
              recipe: recipe,
              recipeId: recipe.recipeId,
             recipeDocId: recipe.recipeDocId ?? recipeId ?? recipe.recipeId.toString(),
              loadFullData: true,
            ),
            type: PageTransitionType.bottomToTop,
          ),
        );
      },
         onLongPress: () async {
        // 1. Check for missing ingredients
        List<Map<String, dynamic>> missingIngredients = [];
        int servingCount = 1; // จำนวน serving ที่ต้องการบริโภค
        
        // คำนวณปริมาณส่วนผสมที่ต้องการตามจำนวน serving
        for (var recipeIngredient in recipe.ingredients) {
          // Calculate the required amount adjusted for servings
          double requiredAmount = recipeIngredient.quantityUsed * (servingCount / recipe.servings);
          String ingredientName = recipeIngredient.ingredient.ingredientsName;
          String unit = recipeIngredient.ingredient.unit;
          
          // Check if user has this ingredient
          bool isFound = false;
          double availableAmount = 0;
          
          for (var userIngredient in userIngredients) {
            if (userIngredient['ingredient'] != null && 
                userIngredient['ingredient']['ingredientsName'] == ingredientName) {
              isFound = true;
              availableAmount = userIngredient['quantity'] ?? 0;
              break;
            }
          }
          
          // If ingredient not found or quantity insufficient, add to missing list
          if (!isFound || availableAmount < requiredAmount) {
            missingIngredients.add({
              'ingredientName': ingredientName,
              'requiredAmount': requiredAmount,
              'unit': unit,
              'availableAmount': isFound ? availableAmount : 0,
            });
          }
        }
        
        // แสดง Dialog ถ้ามีส่วนผสมที่ไม่เพียงพอ
        if (missingIngredients.isNotEmpty) {
          bool shouldProceed = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text(
                  "Missing Ingredients",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("You don't have enough of these ingredients:"),
                      const SizedBox(height: 14),
                      ...missingIngredients.map((ingredient) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            "• ${ingredient['ingredientName']} ${ingredient['requiredAmount'].toStringAsFixed(1)} ${ingredient['unit']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 10),
                      const Text("Do you still want to record your consumption?"),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Eat Anyway", style: TextStyle(color: Colors.green)),
                  ),
                ],
              );
            },
          ) ?? false;
          
          if (!shouldProceed) {
            return; // Exit if user cancelled
          }
        }
        
        // บันทึกการบริโภคถ้าผู้ใช้ยืนยัน
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please login to record consumption"),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
        
        try {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const Center(child: CircularProgressIndicator());
            },
          );
          
          final now = DateTime.now();
          final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
          
          double adjustedKcal = recipe.Kcal * (servingCount / recipe.servings);
          
          // บันทึกข้อมูลการบริโภคใน calorieConsumption collection
          await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('calorieConsumption')
            .add({
              'date': now, 
              'dateStr': dateStr,
              'recipeId': recipe.recipeId.toString(),
              'recipeName': recipe.recipeName,
              'kcal': adjustedKcal.round(),
              'protein': recipe.Protein * (servingCount / recipe.servings),
              'fat': recipe.Fat * (servingCount / recipe.servings),
              'carbo': recipe.Carbo * (servingCount / recipe.servings),
              'mealType': "", 
              'note': "No note",
              'quantity': servingCount,
              'unit': "servings",
            });

          // บันทึกข้อมูลการบริโภคใน eatingHistory collection
          await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('eatingHistory')
            .add({
              'date': now,
              'dateStr': dateStr,
              'recipeId': recipe.recipeId.toString(),
              'recipeName': recipe.recipeName,
              'imageUrl': recipe.imageUrl,
              'kcal': adjustedKcal.round(),
              'protein': recipe.Protein * (servingCount / recipe.servings),
              'fat': recipe.Fat * (servingCount / recipe.servings),
              'carbo': recipe.Carbo * (servingCount / recipe.servings),
              'mealType': "",
              'servings': servingCount,
            });
          
          // อัพเดตปริมาณส่วนผสมที่ผู้ใช้มี
          for (var recipeIngredient in recipe.ingredients) {
            String ingredientName = recipeIngredient.ingredient.ingredientsName;
            double requiredAmount = recipeIngredient.quantityUsed * (servingCount / recipe.servings);
            
            for (var userIngredient in userIngredients) {
              if (userIngredient['ingredient'] != null && 
                  userIngredient['ingredient']['ingredientsName'] == ingredientName) {
                
                double availableAmount = userIngredient['quantity'] ?? 0;
                
                if (availableAmount >= requiredAmount) {
                  String? docId;
                  try {
                    final snapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('userIngredients')
                      .where('ingredientsName', isEqualTo: ingredientName)
                      .get();
                    
                    if (snapshot.docs.isNotEmpty) {
                      docId = snapshot.docs.first.id;
                      
                      // Update the quantity
                      await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('userIngredients')
                        .doc(docId)
                        .update({
                          'quantity': availableAmount - requiredAmount
                        });
                    }
                  } catch (e) {
                    print("Error updating ingredient $ingredientName: $e");
                  }
                }
                break;
              }
            }
          }
          
          if (context.mounted) {
            Navigator.pop(context); // ปิด loading dialog
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Consumption recorded successfully!"),
                backgroundColor: Color(0xFF78d454),
              ),
            );
          }
        } catch (e) {
          // Close loading dialog if there's an error
          if (context.mounted) {
            Navigator.pop(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error recording consumption: $e"),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // รูปภาพอาหาร
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildRecipeImage(recipe.imageUrl),
              ),
              const SizedBox(width: 12),
              // ข้อมูลสูตรอาหาร
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อสูตรอาหาร
                    Text(
                      recipe.recipeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_sharp,
                          size: 18,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${recipe.Kcal} Kcal',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 5),
                         Icon(
                          Icons.people,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.servings} servings',
                         style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }
}