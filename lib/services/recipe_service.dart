import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecipeService {
  final String apiKey = 'bd24cc0518a546b3a16d79dee986ea98';
  Future<List<String>> fetchUserIngredients() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('userIngredients')
            .get();

        print("✅ Fetched ${snapshot.docs.length} ingredients.");
        return snapshot.docs.map((doc) => doc['name'].toString()).toList();
      } catch (e) {
        print("Error fetching ingredients: $e");
        return [];
      }
    } else {
      print("No user is logged in.");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyRecipes({int daysCount = 7}) async {
  final DateTime now = DateTime.now();
  final int weekNumber = _getWeekOfYear(now); 
  
  try {
    // ลองดึงข้อมูลจาก Firestore ก่อน
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // ดูว่ามีข้อมูล weekly recipes ที่แคชไว้หรือไม่
      final cachedData = await FirebaseFirestore.instance
          .collection('weeklyRecipes')
          .doc('week_$weekNumber')
          .get();
      
      // ถ้ามีข้อมูลแคช ดึงรายละเอียดสูตรจาก recipeIds
      if (cachedData.exists) {
        Map<String, dynamic> data = cachedData.data() as Map<String, dynamic>;
        List<int> recipeIds = List<int>.from(data['recipeIds'] ?? []);
        List<Map<String, dynamic>> recipes = [];
        
        for (int i = 0; i < recipeIds.length && i < daysCount; i++) {
          var recipeData = await getRecipeInformation(recipeIds[i]);
          if (recipeData.isNotEmpty) {
            // เพิ่มข้อมูลวันในสัปดาห์
            recipeData['dayOfWeek'] = _getDayName(i);
            recipes.add(recipeData);
          }
        }
        
        if (recipes.isNotEmpty) {
          return recipes;
        }
      }
    }
    
    // ใช้ random endpoint ถ้าไม่มีข้อมูลในแคช
    final String apiKey = '36440b5c03cb475c993bed762cee0c75';
    final String apiUrl = 'https://api.spoonacular.com/recipes/random';

   final List<String> userTags = await _getUserPreferenceTags();
    String selectedTags = userTags.isNotEmpty
    ? (userTags..shuffle()).take(3).join(',')
    : 'main course,easy'; 
    
    // สร้าง parameters
    Map<String, String> params = {
      'apiKey': apiKey,
      'number': daysCount.toString(),
      'tags': selectedTags,
      'addRecipeInformation': 'true',
      'fillIngredients': 'true',
      'addRecipeNutrition': 'true',
    };
    
    final uri = Uri.https('api.spoonacular.com', '/recipes/random', params);
    
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      var data = responseData['recipes'] as List;
      List<Map<String, dynamic>> recipes = [];
      
      for (int i = 0; i < data.length; i++) {
        var recipe = data[i];
        int recipeId = recipe['id'];
        String title = recipe['title'] ?? 'Unknown Recipe';
        String image = recipe['image'] ?? '';
        int readyInMinutes = recipe['readyInMinutes'] ?? 0;
        
        // แปลงข้อมูลให้อยู่ในรูปแบบเดียวกับ getRecipesByCuisine
        Map<String, dynamic> formattedRecipe = {
          'id': recipeId,
          'title': title,
          'image': image,
          'readyInMinutes': readyInMinutes.toString(),
          'dayOfWeek': _getDayName(i),  // เพิ่มวันในสัปดาห์
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
      
      // เก็บข้อมูลลงแคช
      if (recipes.isNotEmpty && user != null) {
        List<int> recipeIds = [];
        for (var recipe in recipes) {
          if (recipe['id'] != null) {
            recipeIds.add(recipe['id'] is int ? recipe['id'] : int.parse(recipe['id'].toString()));
          }
        }
        
        await FirebaseFirestore.instance
            .collection('weeklyRecipes')
            .doc('week_$weekNumber')
            .set({
              'recipeIds': recipeIds,
              'createdAt': FieldValue.serverTimestamp(),
              'weekNumber': weekNumber,
              'year': now.year
            });
      }
      
      print("✅ ได้ ${recipes.length} เมนูอาหารประจำสัปดาห์");
      return recipes;
    } else {
      print("❌ API Error: ${response.statusCode}");
      return [];
    }
  } catch (e) {
    print("❌ เกิดข้อผิดพลาดในการดึงสูตรอาหารประจำสัปดาห์: $e");
    return [];
  }
}

// Helper method to get day name
String _getDayName(int dayIndex) {
  switch (dayIndex) {
    case 0: return 'Monday';
    case 1: return 'Tuesday';
    case 2: return 'Wednesday';
    case 3: return 'Thursday';
    case 4: return 'Friday';
    case 5: return 'Saturday';
    case 6: return 'Sunday';
    default: return 'Special Day'; 
  }
}

// Helper method to calculate week of year
int _getWeekOfYear(DateTime date) {
  final firstDayOfYear = DateTime(date.year, 1, 1);
  final dayDifference = date.difference(firstDayOfYear).inDays;
  return (dayDifference / 7).ceil() + 1;
}


  Future<List<Map<String, dynamic>>> getRecipesWithImages(
      List<String> ingredients) async {
    if (ingredients.isEmpty) {
      print("❌ No ingredients provided for the recipe search.");
      return [];
    }

    String ingredientString = ingredients
        .map((e) => e.trim().toLowerCase())
        .map((e) => Uri.encodeComponent(e))
        .join(',');

    print("🔍 Searching recipes for: $ingredientString");

    final String apiUrl =
        'https://api.spoonacular.com/recipes/findByIngredients';
    final String apiKey = '36440b5c03cb475c993bed762cee0c75';
    // Set number=10 for exact number of recipes and ranking=2 for best matches
    final Uri uri = Uri.parse(
        '$apiUrl?ingredients=$ingredientString&apiKey=$apiKey&number=5&ranking=2&limitLicense=true');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        var data = json.decode(response.body) as List;
        List<Map<String, dynamic>> recipes = [];

        // Take only the first 10 recipes
        for (var recipe in data.take(10)) {
          String title = recipe['title'] ?? 'Unknown Recipe';
        String image = recipe['image'] ?? '';
        int usedCount = recipe['usedIngredientCount'] ?? 0;
        int missedCount = recipe['missedIngredientCount'] ?? 0;
        int recipeId = recipe['id'];
        
        // Get detailed recipe information
        var recipeInfo = await getRecipeInformation(recipeId);
        
        recipes.add({
          'id': recipeId,
          'title': title,
          'image': image,
          'usedIngredientCount': usedCount,
          'missedIngredientCount': missedCount,
          'matchPercentage': ((usedCount / (usedCount + missedCount)) * 100)
              .toStringAsFixed(0),
          'readyInMinutes': recipeInfo['readyInMinutes'],
          'dishTypes': recipeInfo['dishTypes'],
          'nutrition': recipeInfo['nutrition'],
          'instructions': recipeInfo['instructions'],
          'ingredients': recipeInfo['ingredients'],
          'servings': recipeInfo['servings'],
          'usedIngredients': recipe['usedIngredients'] ?? [],
           'cuisine': recipeInfo['cuisines'] != null && recipeInfo['cuisines'] is List && 
      (recipeInfo['cuisines'] as List).isNotEmpty ? 
      (recipeInfo['cuisines'] as List)[0] : 'Other' 
        });
        
        // Create a readable dish type string for logging
        String dishTypesString = "unknown";
        if (recipeInfo['dishTypes'] is List && (recipeInfo['dishTypes'] as List).isNotEmpty) {
          dishTypesString = (recipeInfo['dishTypes'] as List).join(", ");
        }
        
       
      }

      print("📊 Found ${recipes.length} recipes");
      return recipes;
    } else {
      print("❌ API Error: ${response.statusCode}");
      return [];
    }
  } catch (e) {
    print("❌ API Error: $e");
    return [];
  }
}

Future<List<Map<String, dynamic>>> getRecipesByCuisine({
  String primaryCuisine = 'Thai', 
  List<String> fallbackCuisines = const ['Asian', 'Chinese', 'Japanese', 'Indian' ,'Vietnamese', 'Korean' ],
  int limit = 10,
  List<String> includeIngredients = const [] 
}) async {
 
  
  // ลองค้นหาอาหารไทยก่อน
  List<Map<String, dynamic>> thaiRecipes = await _fetchRecipesByCuisine(primaryCuisine, limit);
  
  // ถ้าได้ครบตามจำนวนที่ต้องการแล้ว ให้ส่งกลับเลย
  if (thaiRecipes.length >= limit) {
   
    return thaiRecipes.take(limit).toList();
  }
  
  // ถ้าได้สูตรอาหารไม่ครบตามที่ต้องการ ให้ค้นหาจากวัฒนธรรมอื่นเพิ่มเติม
  
  
  List<Map<String, dynamic>> allRecipes = List.from(thaiRecipes);
  int remainingLimit = limit - thaiRecipes.length;
  
  // วนลูปค้นหาจากวัฒนธรรมอื่น
  for (String cuisine in fallbackCuisines) {
    if (remainingLimit <= 0) break; // ถ้าได้ครบจำนวนแล้วให้หยุด
    
    List<Map<String, dynamic>> cuisineRecipes = await _fetchRecipesByCuisine(cuisine, remainingLimit);
    
    if (cuisineRecipes.isNotEmpty) {
     
      allRecipes.addAll(cuisineRecipes);
      remainingLimit -= cuisineRecipes.length;
    }
  }
  
  // ถ้ายังไม่ครบ ลองค้นหาแบบไม่ระบุวัฒนธรรม
  if (allRecipes.length < limit) {
   
    List<Map<String, dynamic>> generalRecipes = await _fetchRecipesByCuisine('', limit - allRecipes.length);
    allRecipes.addAll(generalRecipes);
  }
  
  
  return allRecipes;
}

Future<List<Map<String, dynamic>>> _fetchRecipesByCuisine(
  String cuisine, 
  int limit, 
  [List<String> includeIngredients = const []]
) async {
  final String apiUrl = 'https://api.spoonacular.com/recipes/complexSearch';
  final String apiKey = '36440b5c03cb475c993bed762cee0c75';
  
  // สร้าง Map parameters
  Map<String, String> params = {
    'apiKey': apiKey,
    'number': limit.toString(),
    'addRecipeInformation': 'true',
    'fillIngredients': 'true',
    'addRecipeNutrition': 'true',
    'sort': 'popularity',
  };
  
  // เพิ่ม cuisine ถ้ามี
  if (cuisine.isNotEmpty) {
    params['cuisine'] = cuisine;
  }
  
  // เพิ่ม includeIngredients ถ้ามี
  if (includeIngredients.isNotEmpty) {
    params['includeIngredients'] = includeIngredients.join(',');
  }
  
  // สร้าง URI
  final uri = Uri.https('api.spoonacular.com', '/recipes/complexSearch', params);
  
  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      var data = responseData['results'] as List;
      List<Map<String, dynamic>> recipes = [];

      for (var recipe in data) {
        // ถ้าใช้ complexSearch API กับ addRecipeInformation=true จะได้ข้อมูลเพิ่มเติมมาเลย
        int recipeId = recipe['id'];
        String title = recipe['title'] ?? 'Unknown Recipe';
        String image = recipe['image'] ?? '';
        
        // นับจำนวนส่วนผสมที่ตรงกัน
        int usedIngredientCount = 0;
        int missedIngredientCount = 0;
        
        // ถ้า API คืนค่าข้อมูลเกี่ยวกับส่วนผสม
        if (recipe['usedIngredients'] != null && recipe['usedIngredients'] is List) {
          usedIngredientCount = (recipe['usedIngredients'] as List).length;
        }
        
        if (recipe['missedIngredients'] != null && recipe['missedIngredients'] is List) {
          missedIngredientCount = (recipe['missedIngredients'] as List).length;
        }
        
        // แปลงข้อมูลให้อยู่ในรูปแบบเดียวกับ getRecipesWithImages
        Map<String, dynamic> formattedRecipe = {
          'id': recipeId,
          'title': title,
          'image': image,
          'usedIngredientCount': usedIngredientCount,
          'missedIngredientCount': missedIngredientCount,
          'matchPercentage': usedIngredientCount + missedIngredientCount > 0 
              ? ((usedIngredientCount / (usedIngredientCount + missedIngredientCount)) * 100).toStringAsFixed(0)
              : '0',
          'readyInMinutes': recipe['readyInMinutes']?.toString() ?? 'N/A',
          'cuisine': cuisine,
          'usedIngredients': recipe['usedIngredients'] ?? [],
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
        
        recipes.add(formattedRecipe);
       
      }

      return recipes;
    } else {
      print("❌ API Error: ${response.statusCode}");
      return [];
    }
  } catch (e) {
    print("❌ API Error: $e");
    return [];
  }
}

Future<Map<String, dynamic>> getRecipeInformation(int recipeId) async {
  final String apiKey = '36440b5c03cb475c993bed762cee0c75';
  final String apiUrl =
      'https://api.spoonacular.com/recipes/$recipeId/information?apiKey=$apiKey';

  try {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      
      // Safely handle dishTypes
      List<String> dishTypes = [];
      if (data['dishTypes'] != null) {
        if (data['dishTypes'] is List) {
          dishTypes = (data['dishTypes'] as List).map((x) => x.toString()).toList();
        } else if (data['dishTypes'] is String) {
          dishTypes = [data['dishTypes'].toString()];
        }
      }
      
      // Safely extract nutrition data
      Map<String, dynamic> nutritionData = {};
      if (data['nutrition'] != null && data['nutrition']['nutrients'] is List) {
        final nutrients = data['nutrition']['nutrients'] as List;
        
        // Extract specific nutrients by name
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
      }
      
      // Extract instructions
      List<String> instructions = [];
      if (data['analyzedInstructions'] != null && data['analyzedInstructions'] is List) {
        for (var instruction in data['analyzedInstructions']) {
          if (instruction['steps'] != null && instruction['steps'] is List) {
            for (var step in instruction['steps']) {
              instructions.add(step['step'] ?? '');
            }
          }
        }
      }
      
      return {
        'id': data['id'] ?? recipeId,
        'readyInMinutes': (data['readyInMinutes'] is int 
    ? data['readyInMinutes'] 
    : int.tryParse(data['readyInMinutes'].toString()) ?? 0),
        'title': data['title'] ?? '',
        'image': data['image'] ?? '',
        'dishTypes': dishTypes,
        'nutrition': nutritionData,
        'instructions': instructions,
        'ingredients': data['extendedIngredients'] ?? [],
        'servings': data['servings'] ?? 1,
        'cuisines': data['cuisines'] ?? []
      };
    } else {
      print("❌ API Error: ${response.statusCode}");
      return {};
    }
  } catch (e, stackTrace) {
    print("❌ Error fetching recipe information: $e");
    print("Stack trace: $stackTrace");
    return {};
  }
}



Future<List<String>> _getUserPreferenceTags() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('userPreferences')
        .doc(user.uid)
        .collection('preferences')
        .get();

    final List<String> tags = snapshot.docs
        .map((doc) => doc['foodName'].toString().toLowerCase())
        .toList();

    return tags;
  } catch (e) {
    print('❌ ดึง user preference tags ไม่ได้: $e');
    return [];
  }
}





}

