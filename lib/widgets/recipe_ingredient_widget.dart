import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/screens/cart/cart_screen.dart';


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

  bool _hasIngredient(Ingredient recipeIngredient, double recipeQuantity) {
  try {
   
    if (widget.userIngredients.isEmpty || recipeIngredient.ingredientsName.isEmpty) {
      return false;
    }
    
   
    for (var ing in widget.userIngredients) {
      if (ing['ingredient'] != null && ing['ingredient']['ingredientsName'] != null) {
      
      }
    }
    
    String recipeIngName = recipeIngredient.ingredientsName.trim().toLowerCase();
    String recipeUnit = recipeIngredient.unit.trim().toLowerCase();
    
    for (var userIngredient in widget.userIngredients) {
      if (userIngredient == null || userIngredient['ingredient'] == null) {
        continue;
      }
      
      String userIngName = userIngredient['ingredient']['ingredientsName']?.toString().trim().toLowerCase() ?? '';
      String userUnit = userIngredient['ingredient']['unit']?.toString().trim().toLowerCase() ?? '';
      double userQuantity = userIngredient['quantity'] is num ? (userIngredient['quantity'] as num).toDouble() : 0.0;
      
      // ชื่อวัตถุดิบตรงกัน
      if (userIngName == recipeIngName) {
       
        
        // ถ้าหน่วยตรงกัน เทียบปริมาณได้โดยตรง
        if (userUnit == recipeUnit) {
          return userQuantity >= recipeQuantity;
        } 
        // หากหน่วยไม่ตรงกัน แต่สามารถแปลงได้
        else if (canConvertUnits(userUnit, recipeUnit)) {
          double convertedQuantity = convertQuantity(userQuantity, userUnit, recipeUnit);
          return convertedQuantity >= recipeQuantity;
        } 
        // ถ้าหน่วยไม่ตรงกันและไม่สามารถแปลงได้ ให้ผ่านไปเนื่องจากไม่สามารถเปรียบเทียบได้
        else {
          return true; // อนุโลมให้ผ่านเนื่องจากมีวัตถุดิบชนิดนี้ แต่ไม่สามารถเปรียบเทียบปริมาณได้
        }
      }
    }
    
    return false; // ไม่พบวัตถุดิบ
  } catch (e) {
    print('Error in _hasIngredient: $e');
    return false;
  }
}

// ฟังก์ชันตรวจสอบว่าสามารถแปลงหน่วยได้หรือไม่
bool canConvertUnits(String fromUnit, String toUnit) {
  // กลุ่มหน่วยวัดที่สามารถแปลงระหว่างกันได้
  List<List<String>> convertibleUnitGroups = [
    ['g', 'gram', 'grams', 'kg', 'kilogram', 'kilograms'],
    ['ml', 'milliliter', 'milliliters', 'l', 'liter', 'liters'],
    ['tsp', 'teaspoon', 'teaspoons', 'tbsp', 'tablespoon', 'tablespoons', 'cup', 'cups']
  ];
  
  // ตรวจสอบว่าทั้งสองหน่วยอยู่ในกลุ่มเดียวกันหรือไม่
  for (var group in convertibleUnitGroups) {
    if (group.contains(fromUnit) && group.contains(toUnit)) {
      return true;
    }
  }
  
  return false;
}

// ฟังก์ชันแปลงปริมาณระหว่างหน่วยต่างๆ
double convertQuantity(double quantity, String fromUnit, String toUnit) {
  // แปลงหน่วยน้ำหนัก
  if (fromUnit == 'kg' && toUnit == 'g') {
    return quantity * 1000;
  } else if (fromUnit == 'g' && toUnit == 'kg') {
    return quantity / 1000;
  }
  
  // แปลงหน่วยปริมาตร
  else if (fromUnit == 'l' && toUnit == 'ml') {
    return quantity * 1000;
  } else if (fromUnit == 'ml' && toUnit == 'l') {
    return quantity / 1000;
  }
  
  // แปลงหน่วยทำอาหาร
  else if (fromUnit == 'tbsp' && toUnit == 'tsp') {
    return quantity * 3;
  } else if (fromUnit == 'tsp' && toUnit == 'tbsp') {
    return quantity / 3;
  } else if (fromUnit == 'cup' && toUnit == 'tbsp') {
    return quantity * 16;
  } else if (fromUnit == 'tbsp' && toUnit == 'cup') {
    return quantity / 16;
  } else if (fromUnit == 'cup' && toUnit == 'tsp') {
    return quantity * 48;
  } else if (fromUnit == 'tsp' && toUnit == 'cup') {
    return quantity / 48;
  }
  
  // หากไม่มีการแปลงที่กำหนด
  return quantity;
}

 Map<String, dynamic>? _getUserIngredient(Ingredient recipeIngredient) {
  try {
    String recipeIngName = recipeIngredient.ingredientsName.trim().toLowerCase();
    
    for (var userIngredient in widget.userIngredients) {
      if (userIngredient == null || userIngredient['ingredient'] == null) {
        continue;
      }
      
      String userIngName = userIngredient['ingredient']['ingredientsName']?.toString().trim().toLowerCase() ?? '';
      
      if (userIngName == recipeIngName) {
        return userIngredient;
      }
    }
    return null;
  } catch (e) {
    print('Error in _getUserIngredient: $e');
    return null;
  }
}

Future<void> _addToCart(String userId, Map<String, dynamic> ingredient) async {
  try {
    CollectionReference userCart = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('userCart');

    CollectionReference historyCart = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('historyCart');

    // ตรวจสอบว่ามีในตะกร้าแล้วหรือไม่
    QuerySnapshot cartQuery = await userCart
        .where('ingredientsName', isEqualTo: ingredient['ingredientsName'])
        .get();

    // ตรวจสอบว่ามีในวัตถุดิบของผู้ใช้แล้วหรือไม่ (เพื่อดึงค่า category, storage, source)
    QuerySnapshot userIngredientsQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('userIngredients')
        .where('ingredientsName', isEqualTo: ingredient['ingredientsName'])
        .get();

    // เตรียมข้อมูลสำหรับเพิ่ม/อัปเดต
    Map<String, dynamic> newIngredient = {...ingredient};
    
    // ถ้าผู้ใช้มีวัตถุดิบนี้อยู่แล้ว ให้ใช้ค่าเดิม
    if (userIngredientsQuery.docs.isNotEmpty) {
      var existingUserIngredient = userIngredientsQuery.docs.first.data() as Map<String, dynamic>;
      
      // ใช้ค่าเดิมจากวัตถุดิบของผู้ใช้
      newIngredient['category'] = existingUserIngredient['category'] ?? 'Fruits';
      newIngredient['storage'] = existingUserIngredient['storage'] ?? 'Fridge';
      newIngredient['source'] = existingUserIngredient['source'] ?? 'Supermarket';
      
      print("📍 Using existing values for ${ingredient['ingredientsName']}: Category=${newIngredient['category']}, Storage=${newIngredient['storage']}, Source=${newIngredient['source']}");
    } else {
      // ถ้าไม่มีวัตถุดิบนี้ ให้ใช้ค่า default
      newIngredient['category'] = ingredient['category'] ?? 'Fruits';
      newIngredient['storage'] = ingredient['storage'] ?? 'Fridge';
      newIngredient['source'] = ingredient['source'] ?? 'Supermarket';
      
      print("📍 Using default values for ${ingredient['ingredientsName']}: Category=${newIngredient['category']}, Storage=${newIngredient['storage']}, Source=${newIngredient['source']}");
    }

    // ถ้ามีในตะกร้าแล้ว อัปเดตปริมาณ
    if (cartQuery.docs.isNotEmpty) {
      DocumentSnapshot existingDoc = cartQuery.docs.first;
      double existingQuantity = (existingDoc['quantity'] is int)
          ? (existingDoc['quantity'] as int).toDouble()
          : (existingDoc['quantity'] as num?)?.toDouble() ?? 0.0;
      
      double newQuantity = existingQuantity + (ingredient['quantity'] as num).toDouble();
      
      await existingDoc.reference.update({
        'quantity': newQuantity,
        // อัปเดตค่าอื่นๆ ด้วยเพื่อให้แน่ใจว่าใช้ค่าล่าสุด
        'category': newIngredient['category'],
        'storage': newIngredient['storage'],
        'source': newIngredient['source'],
      });
      
      print("✅ Updated quantity for ${ingredient['ingredientsName']} to $newQuantity");
    } else {
      // เพิ่มวัตถุดิบใหม่
      await userCart.add(newIngredient);
      print("✅ Added new ingredient to cart: ${ingredient['ingredientsName']}");
    }

    // บันทึกประวัติ
    Map<String, dynamic> historyItem = {
      ...newIngredient,  // ใช้ข้อมูลที่ปรับแล้ว
      'addedAt': FieldValue.serverTimestamp(),
    };
    
    await historyCart.add(historyItem);
    print("✅ History saved for ${ingredient['ingredientsName']}");
  } catch (e) {
    print("❌ Error saving to cart: $e");
    throw e;
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
  onPressed: () async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please log in to add items to cart"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      
      // รายการวัตถุดิบที่ไม่มีหรือมีไม่เพียงพอ
      List<Map<String, dynamic>> ingredientsToAdd = [];
      
      for (var ingredientUsage in widget.ingredients) {
        final ingredient = ingredientUsage.ingredient;
        final adjustedQuantityUsed = ingredientUsage.quantityUsed * 
            widget.currentNumber / 
            widget.recipe.servings;
        
        final hasEnough = _hasIngredient(ingredient, adjustedQuantityUsed);
        
        if (!hasEnough) {
         Map<String, dynamic>? userIngredientInfo = _getUserIngredient(ingredient);
double userQuantity = 0.0;
if (userIngredientInfo != null && userIngredientInfo['quantity'] != null) {
  userQuantity = userIngredientInfo['quantity'] is num ? 
      (userIngredientInfo['quantity'] as num).toDouble() : 0.0;
}

double quantityToAdd = adjustedQuantityUsed - userQuantity;
if (quantityToAdd <= 0) quantityToAdd = adjustedQuantityUsed;



ingredientsToAdd.add({
  'ingredientsName': ingredient.ingredientsName,
  'imageUrl': ingredient.imageUrl,
  'unit': ingredient.unit,
  'quantity': quantityToAdd,
  'price': 0,
});
        }
      }
      
      if (ingredientsToAdd.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You have all required ingredients!"),
            backgroundColor: Color(0xFF78d454),
          ),
        );
        return;
      }
      
      // เพิ่มวัตถุดิบที่ไม่มีลงในตะกร้า
      for (var ingredient in ingredientsToAdd) {
        await _addToCart(user.uid, ingredient);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${ingredientsToAdd.length} ingredients added to cart"),
          backgroundColor: Color(0xFF78d454),
        ),
      );
    } catch (e) {
      print("Error adding ingredients to cart: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding ingredients to cart: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  },
  child: const Text(
    "Add All to Shopping list", 
    style: TextStyle(
      color: Color(0xFF78d454),
      fontWeight: FontWeight.bold,
    ),
  ),
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
            
            
           final hasIngredient = _hasIngredient(ingredient, adjustedQuantityUsed);
    
            // หาปริมาณที่ user มีอยู่
            Map<String, dynamic>? userIngredientInfo = _getUserIngredient(ingredient);
            double userQuantity = 0.0;
            if (userIngredientInfo != null && userIngredientInfo['quantity'] != null) {
              userQuantity = userIngredientInfo['quantity'] is num ? 
                  (userIngredientInfo['quantity'] as num).toDouble() : 0.0;
            }
            
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
                                color: userQuantity >= adjustedQuantityUsed 
                                ? const Color(0xFF78d454) 
                                : Colors.redAccent,

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