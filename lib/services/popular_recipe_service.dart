import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'recipe_service.dart';

class PopularRecipeService {
  final RecipeService _recipeService = RecipeService();
  final String apiKey = '36440b5c03cb475c993bed762cee0c75';
  final int maxRecipes = 5; // จำกัดสูตรสูงสุดเหลือ 5 สูตร
  final int cacheDuration = 86400000; // 24 ชั่วโมง
  int randomOffset = DateTime.now().millisecondsSinceEpoch % 20;

  
  Future<List<Map<String, dynamic>>> getPopularRecipes({int limit = 5, String cuisine = 'Thai'}) async {
    // ตรวจสอบแคชก่อน
    User? user = FirebaseAuth.instance.currentUser;
    final String cacheKey = 'popular_recipes';
    
    if (user != null) {
      try {
        final cachedDoc = await FirebaseFirestore.instance
             .collection('users')
    .doc(user.uid)
            .collection('userPopularRecipes')
            .doc(cacheKey)
            .get();
            
        if (cachedDoc.exists) {
          final cacheData = cachedDoc.data();
          final timestamp = cacheData?['timestamp'] ?? 0;
          
          // ถ้าแคชไม่เกิน 24 ชั่วโมง ให้ใช้ข้อมูลจากแคช
          if (DateTime.now().millisecondsSinceEpoch - timestamp < cacheDuration) {
            print("✅ Using cached popular recipes");
            List<Map<String, dynamic>> recipes = List<Map<String, dynamic>>.from(cacheData?['recipes'] ?? []);
            return recipes.take(limit).toList();
          }
        }
      } catch (e) {
        print("❌ Error reading popular recipes cache: $e");
      }
    }
    
    final String apiUrl = 'https://api.spoonacular.com/recipes/complexSearch';
    
    // กำหนดจำนวนที่ต้องการดึงเป็น 5 สูตร
    Map<String, String> params = {
      
      'apiKey': apiKey,
      'number': limit.toString(), // ปรับให้ตรงกับ limit ที่เปลี่ยนเป็น 5
      'sort': 'popularity',
      'cuisine': cuisine,
      'addRecipeInformation': 'true',
      'fillIngredients': 'true',
      'addRecipeNutrition': 'true',
      'instructionsRequired': 'true',
      'offset': randomOffset.toString(),
    };
    
    final uri = Uri.https('api.spoonacular.com', '/recipes/complexSearch', params);
    
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        var data = responseData['results'] as List;
        List<Map<String, dynamic>> recipes = [];

        // จำกัดจำนวนสูตรที่จะประมวลผลเป็น 5 สูตร
        for (var recipe in data.take(limit)) {
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
            'cuisine': cuisine,
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

  
        _cacheDetailedPopularRecipes(recipes, cuisine);
        
        print("🔥 Found ${recipes.length} hot recipes");
        return recipes;
      } else {
        print("❌ API Error: ${response.statusCode}");
        return _getOfflinePopularRecipes(limit, cuisine);
      }
    } catch (e) {
      print("❌ API Error: $e");
      return _getOfflinePopularRecipes(limit, cuisine);
    }
  }

  Future<void> _cacheDetailedPopularRecipes(List<Map<String, dynamic>> recipes, String cuisine) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final String cacheKey = cuisine.isEmpty ? 'popular_recipes' : 'popular_recipes_${cuisine.toLowerCase()}';
        await FirebaseFirestore.instance
            .collection('cachedRecipes')
            .doc('popular_recipes')
            .set({
              'recipes': recipes,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'updatedAt': FieldValue.serverTimestamp(),
              'cuisine': cuisine,
            });
        
       print("✅ Cached ${recipes.length} detailed hot ${cuisine.isEmpty ? '' : cuisine + ' '}recipes to Firestore");
      } catch (e) {
        print("❌ Error caching hot recipes: $e");
      }
    }
    
    _cachePopularRecipes(recipes);
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
        
        print("✅ Cached ${recipeIds.length} hot recipe IDs to Firestore");
      } catch (e) {
        print("❌ Error caching hot recipes: $e");
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getOfflinePopularRecipes(int limit, String cuisine) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String cacheKey = cuisine.isEmpty ? 'popular_recipes' : 'popular_recipes_${cuisine.toLowerCase()}';
      try {
        // ลองดึงข้อมูลจากแคชแบบใหม่ที่มีรายละเอียดครบถ้วนก่อน
        final detailedCache = await FirebaseFirestore.instance
            .collection('cachedRecipes')
            .doc('popular_recipes')
            .get();
            
        if (detailedCache.exists) {
          Map<String, dynamic> cacheData = detailedCache.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> recipes = List<Map<String, dynamic>>.from(cacheData['recipes'] ?? []);
          
          print("📦 Retrieved ${recipes.length} detailed hot recipes from cache");
          return recipes.take(limit).toList();
        }
        
        // ถ้าไม่มีแคชแบบใหม่ ให้ใช้แคชแบบเดิม
        final cachedData = await FirebaseFirestore.instance
            .collection('hotRecipes')
            .doc('latest')
            .get();
        
        if (cachedData.exists) {
          Map<String, dynamic> data = cachedData.data() as Map<String, dynamic>;
          List<int> recipeIds = List<int>.from(data['recipeIds'] ?? []);
          List<Map<String, dynamic>> recipes = [];
          
          // จำกัดจำนวนสูตรอาหารที่ดึงจากแคช
          for (int id in recipeIds.take(limit)) {
            var recipeData = await _recipeService.getRecipeInformation(id);
            if (recipeData.isNotEmpty) {
              recipeData['isPopular'] = true;
              recipes.add(recipeData);
            }
          }
          
          print("📦 Retrieved ${recipes.length} hot recipes from ID cache");
          return recipes;
        }
      } catch (e) {
        print("❌ Error getting offline hot recipes: $e");
      }
    }
    
    return [];
  }
}