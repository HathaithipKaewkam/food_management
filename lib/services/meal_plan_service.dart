import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_project/models/recipe.dart';

class MealPlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a recipe to meal plan
Future<bool> addRecipeToMealPlan({
  required Recipe recipe, 
  required DateTime date,
  required String mealType,
  int servings = 1,
}) async {
  try {
    final user = _auth.currentUser;
    if (user == null) return false;

    // แปลงข้อมูลส่วนผสมเพื่อบันทึก
    List<Map<String, dynamic>> ingredientsData = recipe.ingredients.map((ing) {
      return {
        'name': ing.ingredient.ingredientsName,
        'unit': ing.ingredient.unit,
        'amount': ing.quantityUsed,
      };
    }).toList();

    // คำนวณปริมาณสารอาหารตามจำนวน servings
    double adjustedCalories = recipe.Kcal * (servings / recipe.servings);
    double adjustedProtein = recipe.Protein * (servings / recipe.servings);
    double adjustedFat = recipe.Fat * (servings / recipe.servings);
    double adjustedCarbo = recipe.Carbo * (servings / recipe.servings);
    
    // Format date for document ID
    String dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    String mealId = "$dateStr-$mealType";
    
    // ตรวจสอบว่ามี meal plan อยู่แล้วหรือไม่
    DocumentSnapshot mealDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('mealPlan')
        .doc(mealId)
        .get();
    
    if (mealDoc.exists) {
      // อัพเดท meal plan ที่มีอยู่แล้ว
      List<Map<String, dynamic>> recipes = [];
      
      // ดึงข้อมูล recipes ที่มีอยู่เดิม
      var data = mealDoc.data() as Map<String, dynamic>;
      if (data.containsKey('recipes') && data['recipes'] is List) {
        recipes = List<Map<String, dynamic>>.from(data['recipes']);
      }
      
      // ตรวจสอบว่ามีสูตรอาหารนี้ในแผนมื้ออาหารแล้วหรือไม่
      bool recipeExists = recipes.any((r) => r['recipeId'] == recipe.recipeId.toString());
      
      if (!recipeExists) {
        // เพิ่มสูตรอาหารใหม่พร้อมข้อมูลครบถ้วน
        recipes.add({
          'recipeId': recipe.recipeId.toString(),
          'recipeName': recipe.recipeName,
          'imageUrl': recipe.imageUrl,
          'servings': servings,
          'kcal': adjustedCalories.round(),
          'protein': adjustedProtein,
          'fat': adjustedFat,
          'carbo': adjustedCarbo,
          'preparationTime': recipe.preparationTime,
          'cookingTime': recipe.cookingTime,
          'category': recipe.category,
          'ingredients': ingredientsData,
          'instructions': recipe.instructions,
        });
        
        // คำนวณแคลอรี่รวมใหม่
     int totalCalories = recipes.fold<int>(0, (int sum, recipe) {
  final recipeKcal = recipe['kcal'];
  final int kcalValue = recipeKcal is int ? recipeKcal : recipeKcal.round();
  return sum + kcalValue;
});
        
        // อัพเดทเอกสาร meal plan
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('mealPlan')
            .doc(mealId)
            .update({
              'recipes': recipes,
              'totalCalories': totalCalories,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
    } else {
      // สร้าง meal plan ใหม่
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('mealPlan')
          .doc(mealId)
          .set({
            'date': date,
            'dateStr': dateStr,
            'mealType': mealType,
            'recipes': [{
              'recipeId': recipe.recipeId.toString(),
              'recipeName': recipe.recipeName,
              'imageUrl': recipe.imageUrl,
              'servings': servings,
              'kcal': adjustedCalories.round(),
              'protein': adjustedProtein,
              'fat': adjustedFat,
              'carbo': adjustedCarbo,
              'preparationTime': recipe.preparationTime,
              'cookingTime': recipe.cookingTime,
              'category': recipe.category,
              'ingredients': ingredientsData,
              'instructions': recipe.instructions,
            }],
            'totalCalories': adjustedCalories.round(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    }
    
    return true;
  } catch (e) {
    print('Error adding recipe to meal plan: $e');
    return false;
  }
}
  
  // Get all meal plans for a specific date
  Future<Map<String, dynamic>> getMealPlansForDate(DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};
      
      String dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      // Get all meal types for this date
      QuerySnapshot mealPlanSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('mealPlan')
          .where('dateStr', isEqualTo: dateStr)
          .get();
      
      Map<String, dynamic> mealPlans = {
        'breakfast': {'recipes': [], 'totalCalories': 0},
        'lunch': {'recipes': [], 'totalCalories': 0},
        'dinner': {'recipes': [], 'totalCalories': 0},
        'snack': {'recipes': [], 'totalCalories': 0},
      };
      
      for (var doc in mealPlanSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('mealType') && mealPlans.containsKey(data['mealType'])) {
          mealPlans[data['mealType']] = {
            'recipes': data['recipes'] ?? [],
            'totalCalories': data['totalCalories'] ?? 0,
          };
        }
      }
      
      return mealPlans;
    } catch (e) {
      print('Error getting meal plans: $e');
      return {};
    }
  }
  
  // Remove a recipe from meal plan
  Future<bool> removeRecipeFromMealPlan({
    required String recipeId,
    required DateTime date,
    required String mealType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      String dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      String mealId = "$dateStr-$mealType";
      
      DocumentSnapshot mealDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('mealPlan')
          .doc(mealId)
          .get();
      
      if (mealDoc.exists) {
        var data = mealDoc.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> recipes = List<Map<String, dynamic>>.from(data['recipes']);
        
        // Remove recipe by ID
        recipes.removeWhere((recipe) => recipe['recipeId'] == recipeId);
        
        // Calculate new total calories
      int totalCalories = recipes.fold<int>(0, (int sum, recipe) {
  final recipeKcal = recipe['kcal'];
  final int kcalValue = recipeKcal is int ? recipeKcal : recipeKcal.round();
  return sum + kcalValue;
});
        
        // If no recipes left, delete the document
        if (recipes.isEmpty) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('mealPlan')
              .doc(mealId)
              .delete();
        } else {
          // Update with remaining recipes
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('mealPlan')
              .doc(mealId)
              .update({
                'recipes': recipes,
                'totalCalories': totalCalories,
                'updatedAt': FieldValue.serverTimestamp(),
              });
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error removing recipe from meal plan: $e');
      return false;
    }
  }
}