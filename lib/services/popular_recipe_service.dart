import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'recipe_service.dart';

class PopularRecipeService {
  final RecipeService _recipeService = RecipeService();
  final String apiKey = '36440b5c03cb475c993bed762cee0c75';
  
  Future<List<Map<String, dynamic>>> getPopularRecipes({int limit = 10 }) async {
    final String apiUrl = 'https://api.spoonacular.com/recipes/complexSearch';
    
    Map<String, String> params = {
      'apiKey': apiKey,
      'number': limit.toString(),
      'sort': 'popularity',
      'addRecipeInformation': 'true',
      'fillIngredients': 'true',
      'addRecipeNutrition': 'true',
    };
    
    final uri = Uri.https('api.spoonacular.com', '/recipes/complexSearch', params); // แก้ไข URI ให้ถูกต้อง
    
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        var data = responseData['results'] as List; // ใช้ 'results' แทน 'recipes'
        List<Map<String, dynamic>> recipes = [];

        for (var recipe in data) {
          int recipeId = recipe['id'];
          String title = recipe['title'] ?? 'Unknown Recipe';
          String image = recipe['image'] ?? '';
          int readyInMinutes = recipe['readyInMinutes'] ?? 0;
          
          // นับความนิยม (popularity) จาก aggregateLikes
          int popularity = recipe['aggregateLikes'] ?? 0;
          
          // แปลงข้อมูลให้อยู่ในรูปแบบเดียวกับที่ใช้ในแอป
          Map<String, dynamic> formattedRecipe = {
            'id': recipeId,
            'title': title,
            'image': image,
            'readyInMinutes': readyInMinutes.toString(),
            'popularity': popularity,
            'isPopular': true,
          };
          
          // ดึงข้อมูลประเภทอาหาร
          if (recipe['dishTypes'] != null) {
            List<String> dishTypes = [];
            if (recipe['dishTypes'] is List) {
              dishTypes = (recipe['dishTypes'] as List).map((type) => type.toString()).toList();
            } else if (recipe['dishTypes'] is String) {
              dishTypes = [recipe['dishTypes'].toString()];
            }
            formattedRecipe['dishTypes'] = dishTypes;
          } else {
            formattedRecipe['dishTypes'] = [];
          }
          
          // ดึงข้อมูลวัฒนธรรมอาหาร (cuisine)
          if (recipe['cuisines'] != null && recipe['cuisines'] is List && (recipe['cuisines'] as List).isNotEmpty) {
            formattedRecipe['cuisine'] = (recipe['cuisines'] as List)[0];
          } else {
            formattedRecipe['cuisine'] = 'Other';
          }
          
          // ดึงข้อมูลโภชนาการ
          if (recipe['nutrition'] != null && recipe['nutrition']['nutrients'] is List) {
            Map<String, dynamic> nutritionData = {};
            final nutrients = recipe['nutrition']['nutrients'] as List;
            
            for (var nutrient in nutrients) {
              if (nutrient['name'] == 'Calories') {
                nutritionData['calories'] = nutrient['amount'];
              } else if (nutrient['name'] == 'Fat') {
                nutritionData['fat'] = nutrient['amount'];
              } else if (nutrient['name'] == 'Carbohydrates') {
                nutritionData['carbs'] = nutrient['amount'];
              } else if (nutrient['name'] == 'Protein') {
                nutritionData['protein'] = nutrient['amount'];
              }
            }
            formattedRecipe['nutrition'] = nutritionData;
          }
          
          // ถ้ามีคำแนะนำการทำอาหาร
          if (recipe['analyzedInstructions'] != null && recipe['analyzedInstructions'] is List) {
            List<String> instructions = [];
            for (var instruction in recipe['analyzedInstructions']) {
              if (instruction['steps'] != null && instruction['steps'] is List) {
                for (var step in instruction['steps']) {
                  instructions.add(step['step'] ?? '');
                }
              }
            }
            formattedRecipe['instructions'] = instructions;
          }
          
          // เพิ่มข้อมูลส่วนผสม
          formattedRecipe['ingredients'] = recipe['extendedIngredients'] ?? [];
          formattedRecipe['servings'] = recipe['servings'] ?? 1;
          
          recipes.add(formattedRecipe);
        }

        // บันทึกข้อมูล popular recipes ลง Firestore สำหรับใช้งานแบบ offline หรือลดการเรียก API
        _cachePopularRecipes(recipes);
        
        print("🔥 Found ${recipes.length} hot recipes");
        return recipes;
      } else {
        print("❌ API Error: ${response.statusCode}");
        return _getOfflinePopularRecipes(limit);
      }
    } catch (e) {
      print("❌ API Error: $e");
      return _getOfflinePopularRecipes(limit);
    }
  }

  Future<void> _cachePopularRecipes(List<Map<String, dynamic>> recipes) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        List<int> recipeIds = [];
        for (var recipe in recipes) {
          if (recipe['id'] != null) {
            recipeIds.add(recipe['id'] is int ? recipe['id'] : int.parse(recipe['id'].toString()));
          }
        }
        
        await FirebaseFirestore.instance
            .collection('hotRecipes')
            .doc('latest')
            .set({
              'recipeIds': recipeIds,
              'updatedAt': FieldValue.serverTimestamp(),
            });
        
        print("✅ Cached ${recipeIds.length} hot recipes to Firestore");
      } catch (e) {
        print("❌ Error caching hot recipes: $e");
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getOfflinePopularRecipes(int limit) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final cachedData = await FirebaseFirestore.instance
            .collection('hotRecipes')
            .doc('latest')
            .get();
        
        if (cachedData.exists) {
          Map<String, dynamic> data = cachedData.data() as Map<String, dynamic>;
          List<int> recipeIds = List<int>.from(data['recipeIds'] ?? []);
          List<Map<String, dynamic>> recipes = [];
          
          for (int id in recipeIds.take(limit)) {
            var recipeData = await _recipeService.getRecipeInformation(id);
            if (recipeData.isNotEmpty) {
              recipeData['isPopular'] = true;
              recipes.add(recipeData);
            }
          }
          
          print("📦 Retrieved ${recipes.length} hot recipes from cache");
          return recipes;
        }
      } catch (e) {
        print("❌ Error getting offline hot recipes: $e");
      }
    }
    
    return [];
  }
}