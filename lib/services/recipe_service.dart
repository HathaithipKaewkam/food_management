import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecipeService {
  final String apiKey = '36440b5c03cb475c993bed762cee0c75';
  final int cacheDuration = 10800000;
  final int maxRecipes = 5;
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

  // เพิ่มเมธอดนี้ในคลาส RecipeService:

Future<List<Map<String, dynamic>>> searchRecipes(String query, {
  String? cuisine,
  String? diet,
  String? mealType,
  int number = 10,
  bool includeNutrition = true
}) async {
  try {
    // ตรวจสอบ cache ก่อน
    final user = FirebaseAuth.instance.currentUser;
    final String cacheKey = 'search_${query.toLowerCase()}';
    
    if (user != null) {
      try {
        final cachedSearch = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cachedSearches')
            .doc(cacheKey)
            .get();
            
        if (cachedSearch.exists) {
          final cacheData = cachedSearch.data();
          final timestamp = cacheData?['timestamp'] ?? 0;
          
          // ถ้าแคชยังไม่หมดอายุ (ไม่เกิน 3 ชั่วโมง)
          if (DateTime.now().millisecondsSinceEpoch - timestamp < cacheDuration) {
            print("✅ Using cached search results for '$query'");
            return List<Map<String, dynamic>>.from(cacheData?['recipes'] ?? []);
          }
        }
      } catch (e) {
        print("❌ Error reading search cache: $e");
      }
    }
    
    final queryParams = {
      'apiKey': apiKey,
      'query': query,
      'number': number.toString(),
      'addRecipeInformation': 'true',
      'fillIngredients': 'true',
      'instructionsRequired': 'true',
    };
    
    // เพิ่มพารามิเตอร์ตามที่กำหนด
    if (cuisine != null && cuisine.isNotEmpty) {
      queryParams['cuisine'] = cuisine;
    }
    
    if (diet != null && diet.isNotEmpty) {
      queryParams['diet'] = diet;
    }
    
    if (mealType != null && mealType.isNotEmpty) {
      queryParams['type'] = mealType;
    }
    
    if (includeNutrition) {
      queryParams['addRecipeNutrition'] = 'true';
    }
  
    final uri = Uri.https('api.spoonacular.com', '/recipes/complexSearch', queryParams);
    
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
  final results = jsonData['results'] as List<dynamic>;
  final processedResults = results.map((item) {
        Map<String, dynamic> recipe = item as Map<String, dynamic>;
        
        // แปลง analyzedInstructions เป็น instructions
        List<String> instructions = [];
        if (recipe['analyzedInstructions'] != null && recipe['analyzedInstructions'] is List) {
          for (var instruction in recipe['analyzedInstructions']) {
            if (instruction != null && instruction['steps'] != null && instruction['steps'] is List) {
              for (var step in instruction['steps']) {
                if (step != null && step['step'] != null) {
                  instructions.add(step['step']);
                }
              }
            }
          }
        }
        recipe['instructions'] = instructions;
        
        // แปลง extendedIngredients เป็น ingredients ถ้าจำเป็น
        if (recipe.containsKey('extendedIngredients') && !recipe.containsKey('ingredients')) {
          recipe['ingredients'] = recipe['extendedIngredients'];
        }
        
        return recipe;
      }).toList();
      
      // บันทึกผลลัพธ์ลงแคช
      if (user != null && processedResults.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('cachedSearches')
              .doc(cacheKey)
              .set({
                'recipes': processedResults,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'query': query
              });
          print("✅ Cached search results for '$query'");
        } catch (e) {
          print("❌ Error writing to search cache: $e");
        }
      }
      
      return processedResults;
    } else {
      throw Exception('Failed to search recipes: ${response.statusCode}');
    }
  } catch (e) {
    print('Error searching recipes: $e');
    return [];
  }
}

  

  Future<List<String>> _getUserPreferenceTags() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return ['main course', 'easy', 'dinner'];
  }

  try {
    // ดึงข้อมูลความชอบของผู้ใช้จาก Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    // ตรวจสอบว่ามีข้อมูล preferences หรือไม่
    if (userDoc.exists && userDoc.data()?['preferences'] != null) {
      Map<String, dynamic> userPrefs = userDoc.data()!;
      
      List<String> tags = [];
      
      // ดึงข้อมูลประเภทอาหารที่ชอบ
      if (userPrefs['preferences']?['favoriteCuisines'] != null) {
        List<dynamic> cuisines = userPrefs['preferences']['favoriteCuisines'];
        for (var cuisine in cuisines) {
          tags.add(cuisine.toString().toLowerCase());
        }
      }
      
      // ดึงข้อมูลประเภทมื้ออาหารที่ชอบ
      if (userPrefs['preferences']?['mealTypes'] != null) {
        List<dynamic> mealTypes = userPrefs['preferences']['mealTypes'];
        for (var mealType in mealTypes) {
          tags.add(mealType.toString().toLowerCase());
        }
      }
      
      // ดึงข้อมูลรสชาติที่ชอบ
      if (userPrefs['preferences']?['favoriteTastes'] != null) {
        List<dynamic> tastes = userPrefs['preferences']['favoriteTastes'];
        for (var taste in tastes) {
          tags.add(taste.toString().toLowerCase());
        }
      }
      
      // ถ้ามีข้อจำกัดด้านอาหาร เช่น มังสวิรัติ
      if (userPrefs['preferences']?['dietaryRestrictions'] != null) {
        List<dynamic> restrictions = userPrefs['preferences']['dietaryRestrictions'];
        for (var restriction in restrictions) {
          tags.add(restriction.toString().toLowerCase());
        }
      }
      
      if (tags.isNotEmpty) {
        print("✅ ได้ ${tags.length} tags จากความชอบของผู้ใช้");
        return tags;
      }
    }
    
    return ['main course', 'easy', 'dinner'];
  } catch (e) {
    print("❌ เกิดข้อผิดพลาดในการดึงข้อมูลความชอบ: $e");
    return ['main course', 'easy', 'dinner'];
  }
}

  Future<List<Map<String, dynamic>>> getWeeklyRecipes(
      {int daysCount = 5}) async {
    final DateTime now = DateTime.now();
    final int weekNumber = _getWeekOfYear(now);
    final int year = now.year;

    try {
      // ลองดึงข้อมูลจาก Firestore ก่อน
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // ดูว่ามีข้อมูล weekly recipes ที่แคชไว้หรือไม่
        final cachedData = await FirebaseFirestore.instance
              .collection('users')
          .doc(user.uid)
          .collection('userWeeklyRecipes') 
            .doc('${user.uid}_week_${year}_$weekNumber')
            .get();

        // ถ้ามีข้อมูลแคช ตรวจสอบความใหม่
        if (cachedData.exists) {
          Map<String, dynamic> data = cachedData.data() as Map<String, dynamic>;
          final timestamp = data['createdAt']?.millisecondsSinceEpoch ?? 0;

          // ถ้าแคชไม่เก่าเกินไป (ไม่เกิน 24 ชั่วโมง)
          if (DateTime.now().millisecondsSinceEpoch - timestamp <
              cacheDuration) {
            List<Map<String, dynamic>> recipes =
                List<Map<String, dynamic>>.from(data['recipes'] ?? []);

            if (recipes.isNotEmpty) {
              print("✅ ใช้ข้อมูลสูตรอาหารประจำสัปดาห์จากแคช");
              return recipes.take(daysCount).toList();
            }
          }
        }
      }

      // ถ้าไม่มีแคชหรือแคชเก่าเกินไป ใช้ random endpoint
      final String apiUrl = 'https://api.spoonacular.com/recipes/random';

      final List<String> userTags = await _getUserPreferenceTags();
      String selectedTags = userTags.isNotEmpty
          ? (userTags..shuffle()).take(3).join(',')
          : 'main course,easy';

      // สร้าง parameters - ขอรับทุกข้อมูลที่ต้องการในครั้งเดียว
      Map<String, String> params = {
        'apiKey': apiKey,
        'number': daysCount.toString(),
        'tags': selectedTags,
        'addRecipeInformation': 'true',
        'fillIngredients': 'true',
        'addRecipeNutrition': 'true',
        'instructionsRequired': 'true',
        'limitLicense': 'true',
      };

      final uri = Uri.https('api.spoonacular.com', '/recipes/random', params);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        var data = responseData['recipes'] as List;
        List<Map<String, dynamic>> recipes = [];

        for (int i = 0; i < data.length && i < daysCount; i++) {
          var recipe = data[i];
          Map<String, dynamic> formattedRecipe =
              _extractWeeklyRecipeData(recipe, i);
          recipes.add(formattedRecipe);
        }

        // เก็บข้อมูลลงแคช
        if (recipes.isNotEmpty && user != null) {
          try {
            await FirebaseFirestore.instance
               .collection('users')
            .doc(user.uid)
            .collection('userWeeklyRecipes')
            .doc('week_${year}_$weekNumber')
                .set({
              'recipes': recipes,
              'createdAt': FieldValue.serverTimestamp(),
              'weekNumber': weekNumber,
              'year': year
            });
          } catch (e) {
            print("❌ Error saving weekly recipes to cache: $e");
          }
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

// Helper method สำหรับสกัดข้อมูลสูตรอาหารประจำสัปดาห์
  Map<String, dynamic> _extractWeeklyRecipeData(
      Map<String, dynamic> recipe, int dayIndex) {
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
      'dayOfWeek': _getDayName(dayIndex), // เพิ่มวันในสัปดาห์
    };

    // ดึงข้อมูลประเภทอาหาร
    if (recipe['dishTypes'] != null) {
      List<String> dishTypes = [];
      if (recipe['dishTypes'] is List) {
        dishTypes = (recipe['dishTypes'] as List)
            .map((type) => type.toString())
            .toList();
      } else if (recipe['dishTypes'] is String) {
        dishTypes = [recipe['dishTypes'].toString()];
      }
      formattedRecipe['dishTypes'] = dishTypes;
    } else {
      formattedRecipe['dishTypes'] = [];
    }

    // ดึงข้อมูลวัฒนธรรมอาหาร (cuisine)
    if (recipe['cuisines'] != null &&
        recipe['cuisines'] is List &&
        (recipe['cuisines'] as List).isNotEmpty) {
      formattedRecipe['cuisine'] = (recipe['cuisines'] as List)[0];
    } else {
      formattedRecipe['cuisine'] = 'Other';
    }

    // ดึงข้อมูลโภชนาการ
    if (recipe['nutrition'] != null &&
        recipe['nutrition']['nutrients'] is List) {
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
    if (recipe['analyzedInstructions'] != null &&
        recipe['analyzedInstructions'] is List) {
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

    return formattedRecipe;
  }

// Helper method to get day name
  String _getDayName(int dayIndex) {
    switch (dayIndex) {
      case 0:
        return 'Monday';
      case 1:
        return 'Tuesday';
      case 2:
        return 'Wednesday';
      case 3:
        return 'Thursday';
      case 4:
        return 'Friday';
      case 5:
        return 'Saturday';
      case 6:
        return 'Sunday';
      default:
        return 'Special Day';
    }
  }

// Helper method to calculate week of year
  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final dayDifference = date.difference(firstDayOfYear).inDays;
    return (dayDifference / 7).ceil() + 1;
  }

  Future<List<Map<String, dynamic>>> getRecipesWithImages(
         List<String> ingredients, {int number = 5}) async {
  if (ingredients.isEmpty) {
    return [];
  }


    String ingredientString = ingredients
        .map((e) => e.trim().toLowerCase())
        .map((e) => Uri.encodeComponent(e))
        .join(',');

    print("🔍 Searching recipes for: $ingredientString");

    // สร้าง cache key จากส่วนผสม
    final String cacheKey = 'ingredients_${ingredientString}';
    final user = FirebaseAuth.instance.currentUser;

    // ตรวจสอบแคชก่อน
    if (user != null) {
      try {
        final cachedSearch = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cachedSearches')
            .doc(cacheKey)
            .get();

        if (cachedSearch.exists) {
          final cacheData = cachedSearch.data();
          final timestamp = cacheData?['timestamp'] ?? 0;
          // ตรวจสอบว่าแคชยังไม่หมดอายุ (ไม่เกิน 24 ชั่วโมง)
          if (DateTime.now().millisecondsSinceEpoch - timestamp <
              cacheDuration) {
            print("✅ Using cached recipe search results");
            return List<Map<String, dynamic>>.from(cacheData?['recipes'] ?? []);
          }
        }
      } catch (e) {
        print("❌ Error reading search cache: $e");
      }
    }

    final String apiUrl =
        'https://api.spoonacular.com/recipes/findByIngredients';
    // อัปเดต parameters เพื่อให้ได้ข้อมูลในครั้งเดียว
    final Uri uri = Uri.parse(
        '$apiUrl?ingredients=$ingredientString&apiKey=$apiKey&number=$maxRecipes&ranking=2&limitLicense=true&fillIngredients=true');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        var data = json.decode(response.body) as List;
        List<Map<String, dynamic>> recipes = [];
        List<Future<void>> detailFutures = []; // รวบรวมการเรียก API ไว้

        // จำกัดจำนวนเหลือเพียง maxRecipes สูตร
        for (var recipe in data.take(maxRecipes)) {
          String title = recipe['title'] ?? 'Unknown Recipe';
          String image = recipe['image'] ?? '';
          int usedCount = recipe['usedIngredientCount'] ?? 0;
          int missedCount = recipe['missedIngredientCount'] ?? 0;
          int recipeId = recipe['id'];

          // สร้างข้อมูลพื้นฐานก่อน
          Map<String, dynamic> recipeData = {
            'id': recipeId,
            'title': title,
            'image': image,
            'usedIngredientCount': usedCount,
            'missedIngredientCount': missedCount,
            'matchPercentage': ((usedCount / (usedCount + missedCount)) * 100)
                .toStringAsFixed(0),
            'usedIngredients': recipe['usedIngredients'] ?? [],
          };

          recipes.add(recipeData);

          // เพิ่ม Future สำหรับการดึงข้อมูลเพิ่มเติม
          detailFutures.add(() async {
            var recipeInfo = await getRecipeInformation(recipeId);
            // อัปเดตข้อมูลที่เพิ่งดึงมา
            recipeData.addAll({
              'readyInMinutes': recipeInfo['readyInMinutes'],
              'dishTypes': recipeInfo['dishTypes'],
              'nutrition': recipeInfo['nutrition'],
              'instructions': recipeInfo['instructions'],
              'ingredients': recipeInfo['ingredients'],
              'servings': recipeInfo['servings'],
              'cuisine': recipeInfo['cuisines'] != null &&
                      recipeInfo['cuisines'] is List &&
                      (recipeInfo['cuisines'] as List).isNotEmpty
                  ? (recipeInfo['cuisines'] as List)[0]
                  : 'Other'
            });
          }());
        }

        // รอให้การดึงข้อมูลทั้งหมดเสร็จสิ้น
        await Future.wait(detailFutures);

        // บันทึกผลลัพธ์ลงแคช
        if (recipes.isNotEmpty && user != null) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('cachedSearches')
                .doc(cacheKey)
                .set({
              'recipes': recipes,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'ingredients': ingredients
            });
          } catch (e) {
            print("❌ Error writing to search cache: $e");
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
  bool forceRefresh = false,
  List<String> fallbackCuisines = const ['Asian', 'Chinese', 'Japanese', 'Indian', 'Vietnamese', 'Korean'],
  int limit = 5,
  List<String> includeIngredients = const []
}) async {
  print('🍎 Searching recipes with ingredients: $includeIngredients');
   final String cacheKey = 'cuisine_${primaryCuisine}_${fallbackCuisines.join('_')}_${limit}_ingredients_${includeIngredients.join('_')}';
    final user = FirebaseAuth.instance.currentUser;

    if (!forceRefresh && user != null) {
    try {
      final cachedSearch = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cachedSearches')
          .doc(cacheKey)
          .get();

      if (cachedSearch.exists) {
        final cacheData = cachedSearch.data();
        final timestamp = cacheData?['timestamp'] ?? 0;
        // ตรวจสอบว่าแคชยังไม่หมดอายุ (ไม่เกิน 24 ชั่วโมง)
        if (DateTime.now().millisecondsSinceEpoch - timestamp < cacheDuration) {
          print("✅ Using cached cuisine search results");
          return List<Map<String, dynamic>>.from(cacheData?['recipes'] ?? []);
        }
      }
    } catch (e) {
      print("❌ Error reading cuisine cache: $e");
    }
  } else if (forceRefresh) {
    print("⚡ Force refresh requested - skipping cache check");
  }



    // ลองค้นหาอาหารไทยก่อน
    List<Map<String, dynamic>> thaiRecipes =
        await _fetchRecipesByCuisine(primaryCuisine, limit);

    // ถ้าได้ครบตามจำนวนที่ต้องการแล้ว ให้ส่งกลับเลย
    if (thaiRecipes.length >= limit) {
      List<Map<String, dynamic>> recipes = thaiRecipes.take(limit).toList();

      // บันทึกผลลัพธ์ลงแคช
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('cachedSearches')
              .doc(cacheKey)
              .set({
            'recipes': recipes,
            'timestamp': DateTime.now().millisecondsSinceEpoch
          });
        } catch (e) {
          print("❌ Error writing to cuisine cache: $e");
        }
      }

      return recipes;
    }

    // ถ้าได้สูตรอาหารไม่ครบตามที่ต้องการ ให้ค้นหาจากวัฒนธรรมอื่นเพิ่มเติม
    List<Map<String, dynamic>> allRecipes = List.from(thaiRecipes);
    int remainingLimit = limit - thaiRecipes.length;

    // วนลูปค้นหาจากวัฒนธรรมอื่น
    for (String cuisine in fallbackCuisines) {
      if (remainingLimit <= 0) break; // ถ้าได้ครบจำนวนแล้วให้หยุด

      List<Map<String, dynamic>> cuisineRecipes =
          await _fetchRecipesByCuisine(cuisine, remainingLimit);

      if (cuisineRecipes.isNotEmpty) {
        allRecipes.addAll(cuisineRecipes);
        remainingLimit -= cuisineRecipes.length;
      }
    }

    // ถ้ายังไม่ครบ ลองค้นหาแบบไม่ระบุวัฒนธรรม
    if (allRecipes.length < limit) {
      List<Map<String, dynamic>> generalRecipes =
          await _fetchRecipesByCuisine('', limit - allRecipes.length);
      allRecipes.addAll(generalRecipes);
    }

    // บันทึกผลลัพธ์ลงแคช
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cachedSearches')
            .doc(cacheKey)
            .set({
          'recipes': allRecipes,
          'timestamp': DateTime.now().millisecondsSinceEpoch
        });
      } catch (e) {
        print("❌ Error writing to cuisine cache: $e");
      }
    }

    return allRecipes;
  }

  Future<List<Map<String, dynamic>>> _fetchRecipesByCuisine(
      String cuisine, int limit,
      {List<String> includeIngredients = const [],
      bool forceRefresh = false}) async {
    // สร้าง cache key
    final String cacheKey =
        'cuisine_fetch_${cuisine}_${limit}_${includeIngredients.join('_')}';
    final user = FirebaseAuth.instance.currentUser;

    if (!forceRefresh && user != null) {
    try {
      final cachedSearch = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cachedSearches')
          .doc(cacheKey)
          .get();

      if (cachedSearch.exists) {
        final cacheData = cachedSearch.data();
        final timestamp = cacheData?['timestamp'] ?? 0;
        if (DateTime.now().millisecondsSinceEpoch - timestamp < cacheDuration) {
          print("✅ Using cached cuisine fetch results for $cuisine");
          return List<Map<String, dynamic>>.from(cacheData?['recipes'] ?? []);
        }
      }
    } catch (e) {
      print("❌ Error reading cuisine fetch cache: $e");
    }
  } else if (forceRefresh) {
    print("⚡ Force refresh requested for $cuisine recipes");
  }


    // สร้าง Map parameters - เพิ่ม instructionsRequired=true เพื่อให้ได้ข้อมูลการทำอาหาร
    Map<String, String> params = {
      'apiKey': apiKey,
      'number': limit.toString(),
      'addRecipeInformation': 'true',
      'fillIngredients': 'true',
      'addRecipeNutrition': 'true',
      'instructionsRequired': 'true',
       'sort': 'min-missing-ingredients',
        'ranking': '2',
    };

     if (includeIngredients.isNotEmpty) {
    params['includeIngredients'] = includeIngredients.join(',');
  }

    // เพิ่ม cuisine ถ้ามี
    if (cuisine.isNotEmpty) {
      params['cuisine'] = cuisine;
    }

    // เพิ่ม includeIngredients ถ้ามี
    if (includeIngredients.isNotEmpty) {
      params['includeIngredients'] = includeIngredients.join(',');
    }

    // สร้าง URI
    final uri =
        Uri.https('api.spoonacular.com', '/recipes/complexSearch', params);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        var data = responseData['results'] as List;
        List<Map<String, dynamic>> recipes = [];

        for (var recipe in data) {
          // แปลงข้อมูลให้อยู่ในรูปแบบเดียวกับ getRecipesWithImages
          Map<String, dynamic> formattedRecipe =
              _extractRecipeData(recipe, cuisine);
          recipes.add(formattedRecipe);
        }

        // บันทึกผลลัพธ์ลงแคช
        if (user != null) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('cachedSearches')
                .doc(cacheKey)
                .set({
              'recipes': recipes,
              'timestamp': DateTime.now().millisecondsSinceEpoch
            });
          } catch (e) {
            print("❌ Error writing to cuisine fetch cache: $e");
          }
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

// Helper method สำหรับสกัดข้อมูลสูตรอาหาร
  Map<String, dynamic> _extractRecipeData(
      Map<String, dynamic> recipe, String cuisine) {
    int recipeId = recipe['id'];
    String title = recipe['title'] ?? 'Unknown Recipe';
    String image = recipe['image'] ?? '';

    // นับจำนวนส่วนผสมที่ตรงกัน
    int usedIngredientCount = 0;
    int missedIngredientCount = 0;

    // ถ้า API คืนค่าข้อมูลเกี่ยวกับส่วนผสม
    if (recipe['usedIngredients'] != null &&
        recipe['usedIngredients'] is List) {
      usedIngredientCount = (recipe['usedIngredients'] as List).length;
    }

    if (recipe['missedIngredients'] != null &&
        recipe['missedIngredients'] is List) {
      missedIngredientCount = (recipe['missedIngredients'] as List).length;
    }

    // สกัดคำแนะนำการทำอาหาร
    List<String> instructions = [];
    if (recipe['analyzedInstructions'] != null &&
        recipe['analyzedInstructions'] is List) {
      for (var instruction in recipe['analyzedInstructions']) {
        if (instruction['steps'] != null && instruction['steps'] is List) {
          for (var step in instruction['steps']) {
            instructions.add(step['step'] ?? '');
          }
        }
      }
    }

    // สกัดข้อมูลประเภทอาหาร
    List<String> dishTypes = [];
    if (recipe['dishTypes'] != null) {
      if (recipe['dishTypes'] is List) {
        dishTypes = (recipe['dishTypes'] as List)
            .map((type) => type.toString())
            .toList();
      } else if (recipe['dishTypes'] is String) {
        dishTypes = [recipe['dishTypes'].toString()];
      }
    }

    // สกัดข้อมูลโภชนาการ
    Map<String, dynamic> nutritionData = {};
    if (recipe['nutrition'] != null &&
        recipe['nutrition']['nutrients'] is List) {
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
    }

    return {
      'id': recipeId,
      'title': title,
      'image': image,
      'usedIngredientCount': usedIngredientCount,
      'missedIngredientCount': missedIngredientCount,
      'matchPercentage': usedIngredientCount + missedIngredientCount > 0
          ? ((usedIngredientCount /
                      (usedIngredientCount + missedIngredientCount)) *
                  100)
              .toStringAsFixed(0)
          : '0',
      'readyInMinutes': recipe['readyInMinutes']?.toString() ?? 'N/A',
      'cuisine': cuisine.isEmpty &&
              recipe['cuisines'] != null &&
              recipe['cuisines'] is List &&
              (recipe['cuisines'] as List).isNotEmpty
          ? (recipe['cuisines'] as List)[0]
          : cuisine.isEmpty
              ? 'Other'
              : cuisine,
      'usedIngredients': recipe['usedIngredients'] ?? [],
      'dishTypes': dishTypes,
      'nutrition': nutritionData,
      'instructions': instructions,
      'ingredients': recipe['extendedIngredients'] ?? [],
      'servings': recipe['servings'] ?? 1,
    };
  }

  

  Future<List<Map<String, dynamic>>> getTopRecipeByUserPreference({bool forceRefresh = false}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return [];
  }

  try {
    // ดึงข้อมูลความชอบของผู้ใช้
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists || userDoc.data()?['preferences'] == null) {
      print("⚠️ ไม่พบข้อมูลความชอบของผู้ใช้");
      return await _getDefaultTopRecipes(5,user.uid);
    }

    Map<String, dynamic> userPrefs = userDoc.data()!;
    List<String> cuisines = [];
    List<String> mealTypes = [];
    List<String> dietaryRestrictions = [];
    
    // ดึงข้อมูลประเภทอาหารที่ชอบ
    if (userPrefs['preferences']?['favoriteCuisines'] != null) {
      cuisines = List<String>.from(userPrefs['preferences']['favoriteCuisines']);
    }
    
    // ดึงข้อมูลประเภทมื้ออาหารที่ชอบ
    if (userPrefs['preferences']?['mealTypes'] != null) {
      mealTypes = List<String>.from(userPrefs['preferences']['mealTypes']);
    }
    
    // ดึงข้อมูลข้อจำกัดทางอาหาร
    if (userPrefs['preferences']?['dietaryRestrictions'] != null) {
      dietaryRestrictions = List<String>.from(userPrefs['preferences']['dietaryRestrictions']);
    }

    // ตรวจสอบแคชก่อน
    final String cacheKey = 'top_recipes_${cuisines.join('_')}_${mealTypes.join('_')}';
    
     final cachedDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userCachedRecipes') 
        .doc(cacheKey)
        .get();
        
    if (cachedDoc.exists) {
      final cacheData = cachedDoc.data();
      final timestamp = cacheData?['timestamp'] ?? 0;
      
      // ถ้าแคชไม่เกิน 24 ชั่วโมง ให้ใช้ข้อมูลจากแคช
      if (DateTime.now().millisecondsSinceEpoch - timestamp < cacheDuration) {
        print("✅ ใช้แคชสำหรับอาหารยอดนิยมตามความชอบของผู้ใช้");
        return List<Map<String, dynamic>>.from(cacheData?['recipes'] ?? []);
      }
    }

    // ถ้าไม่มีแคชหรือแคชเก่าเกินไป ดึงข้อมูลใหม่
    String cuisine = cuisines.isNotEmpty ? cuisines[0] : '';
    String mealType = mealTypes.isNotEmpty ? mealTypes[0] : '';
    String diet = dietaryRestrictions.isNotEmpty ? dietaryRestrictions[0] : '';
    
    Map<String, String> params = {
      'apiKey': apiKey,
      'number': '5', // เปลี่ยนเป็น 5 สูตร
      'sort': 'popularity',
      'addRecipeInformation': 'true',
      'fillIngredients': 'true',
      'addRecipeNutrition': 'true',
      'instructionsRequired': 'true',
    };
    
    if (cuisine.isNotEmpty) {
      params['cuisine'] = cuisine;
    }
    
    if (mealType.isNotEmpty) {
      params['type'] = mealType;
    }
    
    if (diet.isNotEmpty) {
      params['diet'] = diet;
    }
    
    final uri = Uri.https('api.spoonacular.com', '/recipes/complexSearch', params);
    
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      var results = responseData['results'] as List;
      
      if (results.isEmpty) {
        print("⚠️ ไม่พบสูตรอาหารตามความชอบของผู้ใช้");
        return await _getDefaultTopRecipes(5, user.uid);
      }
      
      List<Map<String, dynamic>> recipes = [];
      
      // แปลงข้อมูลจาก API เป็นรูปแบบที่ใช้ในแอป
      for (int i = 0; i < results.length; i++) {
        var recipe = results[i];
        var formattedRecipe = _extractWeeklyRecipeData(recipe, i);
        recipes.add(formattedRecipe);
      }
      
      // บันทึกลงแคช
      await FirebaseFirestore.instance
       .collection('users')
        .doc(user.uid)
          .collection('userCachedRecipes')
          .doc(cacheKey)
          .set({
            'recipes': recipes,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      print("✅ พบ ${recipes.length} สูตรอาหารยอดนิยมตามความชอบของผู้ใช้");
      return recipes;
    } else {
      print("❌ API Error: ${response.statusCode}");
      return await _getDefaultTopRecipes(5, user.uid);
    }
  } catch (e) {
    print("❌ เกิดข้อผิดพลาดในการดึงอาหารยอดนิยม: $e");
    return await _getDefaultTopRecipes(5,user.uid);
  }
}


Future<List<Map<String, dynamic>>> _getDefaultTopRecipes(int count , String userId) async {
  print("🔍 ใช้สูตรอาหารยอดนิยมทั่วไปแทน");
  
  // ตรวจสอบแคชก่อน
  final cachedDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('userCachedRecipes')
      .doc('default_top_recipes')
      .get();
      
  final int shortCacheDuration = 3600000; 

   if (cachedDoc.exists) {
    final cacheData = cachedDoc.data();
    final timestamp = cacheData?['timestamp'] ?? 0;
    
    if (DateTime.now().millisecondsSinceEpoch - timestamp < shortCacheDuration) {
      return List<Map<String, dynamic>>.from(cacheData?['recipes'] ?? []);
    }
  }
  

  try {
    int randomOffset = DateTime.now().millisecondsSinceEpoch % 50;
    Map<String, String> params = {
      'apiKey': apiKey,
      'number': count.toString(),
      'sort': 'popularity',
      'offset': randomOffset.toString(), 
      'addRecipeInformation': 'true',
      'fillIngredients': 'true',
      'addRecipeNutrition': 'true',
      'instructionsRequired': 'true',
    };
    
    final uri = Uri.https('api.spoonacular.com', '/recipes/complexSearch', params);
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      var results = responseData['results'] as List;
      
      if (results.isEmpty) {
        return [];
      }
      
      List<Map<String, dynamic>> recipes = [];
      
      // แปลงข้อมูลจาก API เป็นรูปแบบที่ใช้ในแอป
      for (int i = 0; i < results.length; i++) {
        var recipe = results[i];
        var formattedRecipe = _extractWeeklyRecipeData(recipe, i);
        recipes.add(formattedRecipe);
      }
      
      // บันทึกลงแคช
      await FirebaseFirestore.instance
           .collection('users')
        .doc(userId)
        .collection('userCachedRecipes')
        .doc('default_top_recipes')
          .set({
            'recipes': recipes,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      return recipes;
    } else {
      return [];
    }
  } catch (e) {
    print("❌ เกิดข้อผิดพลาดในการดึงอาหารยอดนิยมทั่วไป: $e");
    return [];
  }
}

  

  Future<Map<String, dynamic>> getRecipeInformation(int recipeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final cachedRecipe = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cachedRecipes')
            .doc(recipeId.toString())
            .get();

        if (cachedRecipe.exists) {
          // ตรวจสอบว่าแคชยังไม่หมดอายุ
          final cacheData = cachedRecipe.data();
          final timestamp = cacheData?['cachedAt'] ?? 0;

          if (DateTime.now().millisecondsSinceEpoch - timestamp <
              cacheDuration) {
            print("✅ Retrieved recipe $recipeId from cache");
            return cachedRecipe.data() as Map<String, dynamic>;
          } else {
            print("⚠️ Cache expired for recipe $recipeId");
          }
        }
      } catch (e) {
        print("❌ Error reading recipe cache: $e");
      }
    }

    try {
      final response = await http.get(Uri.parse(
          'https://api.spoonacular.com/recipes/$recipeId/information?apiKey=$apiKey&instructionsRequired=true'));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        // Safely handle dishTypes
        List<String> dishTypes = [];
        if (data['dishTypes'] != null) {
          if (data['dishTypes'] is List) {
            dishTypes =
                (data['dishTypes'] as List).map((x) => x.toString()).toList();
          } else if (data['dishTypes'] is String) {
            dishTypes = [data['dishTypes'].toString()];
          }
        }

        // Safely extract nutrition data
        Map<String, dynamic> nutritionData = {};
        if (data['nutrition'] != null &&
            data['nutrition']['nutrients'] is List) {
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
        if (data['analyzedInstructions'] != null &&
            data['analyzedInstructions'] is List) {
          for (var instruction in data['analyzedInstructions']) {
            if (instruction['steps'] != null && instruction['steps'] is List) {
              for (var step in instruction['steps']) {
                instructions.add(step['step'] ?? '');
              }
            }
          }
        }

        Map<String, dynamic> recipeData = {
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
          'cuisines': data['cuisines'] ?? [],
          'cachedAt': DateTime.now().millisecondsSinceEpoch,
        };

        // บันทึกข้อมูลลงแคช
        if (user != null) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('cachedRecipes')
                .doc(recipeId.toString())
                .set(recipeData);
            print("✅ Saved recipe $recipeId to cache");
          } catch (e) {
            print("❌ Error writing to recipe cache: $e");
          }
        }

        return recipeData;
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

  Future<Map<String, dynamic>?> getRecipeById(int recipeId) async {
  try {
    // เพิ่ม parameter includeInstructions=true
    final response = await http.get(
      Uri.parse('https://api.spoonacular.com/recipes/$recipeId/information?apiKey=$apiKey&includeNutrition=true&instructionsRequired=true')
    );
    
    if (response.statusCode == 200) {
      print("✅ Successfully fetched recipe details for ID: $recipeId");
      var responseData = json.decode(response.body);
      print("✅ Response data keys: ${responseData.keys.toList()}");
      
      // ตรวจสอบว่ามีข้อมูลขั้นตอนหรือไม่
      if (responseData['analyzedInstructions'] == null || 
          (responseData['analyzedInstructions'] is List && 
          (responseData['analyzedInstructions'] as List).isEmpty)) {
        print("⚠️ No analyzedInstructions found, checking for instructions...");
      }
      
      if (responseData['instructions'] == null || responseData['instructions'].toString().isEmpty) {
        print("⚠️ No instructions found either");
      }
      
      return responseData;
    } else {
      print("❌ API Error: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    print("❌ Error fetching recipe by ID: $e");
    return null;
  }
}
}
