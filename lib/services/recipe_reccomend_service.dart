import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_project/services/recipe_service.dart';

class RecipeRecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RecipeService _recipeService = RecipeService();
  late Map<String, dynamic> userMacros;

  Future<List<String>> fetchUserIngredients(String userId) async {
    try {
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('userIngredients')
          .get();

      List<String> ingredients = snapshot.docs
          .map((doc) => doc['ingredientsName'].toString())
          .toList();

      print("✅ Fetched ${ingredients.length} ingredients: $ingredients");
      return ingredients;
    } catch (e) {
      print("❌ Error fetching ingredients: $e");
      return [];
    }
  }

  Future<List<String>> fetchUserPreferences(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('userPreferences')
          .doc(userId)
          .collection('preferences')
          .get();

      List<String> preferences =
          snapshot.docs.map((doc) => doc['foodName'].toString()).toList();

      print("✅ Fetched preferences: $preferences");
      return preferences;
    } catch (e) {
      print("❌ Error fetching preferences: $e");
      return [];
    }
  }

  Future<String> fetchUserGoals(String userId) async {
    try {
      final doc = await _firestore.collection('userGoals').doc(userId).get();

      String goal = doc.data()?['goal'] ?? '';
      print("✅ Fetched goal: $goal");
      return goal;
    } catch (e) {
      print("❌ Error fetching goals: $e");
      return '';
    }
  }

  Future<List<String>> fetchUserAllergies(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('userAllergies')
          .doc(userId)
          .collection('Allergies')
          .get();

      List<String> allergies =
          snapshot.docs.map((doc) => doc['foodName'].toString()).toList();

      print("✅ Fetched allergies: $allergies");
      return allergies;
    } catch (e) {
      print("❌ Error fetching allergies: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchIngredientsWithExpiry(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('userIngredients')
          .get();

      return snapshot.docs.map((doc) {
        DateTime expiryDate;

        try {
          if (doc['expirationDate'] is Timestamp) {
            expiryDate = (doc['expirationDate'] as Timestamp).toDate();
          } else if (doc['expirationDate'] is String) {
            expiryDate = DateTime.parse(doc['expirationDate']);
          } else {
            print(
                "⚠️ Unexpected expirationDate type: ${doc['expirationDate'].runtimeType} for ${doc['ingredientsName']}");
            expiryDate = DateTime.now().add(Duration(days: 30)); // ค่า default
          }
        } catch (e) {
          print(
              "⚠️ Error parsing expirationDate for ${doc['ingredientsName']}: $e");
          expiryDate = DateTime.now().add(Duration(days: 30)); // ค่า default
        }

        return {
          'name': doc['ingredientsName'].toString(),
          'expiryDate': expiryDate,
        };
      }).toList();
    } catch (e) {
      print("❌ Error fetching ingredients with expiry: $e");
      return [];
    }
  }

  Future<List<String>> fetchNotRecommendedRecipes(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notRecommendedRecipes')
          .get();

      List<String> notRecommendedIds = snapshot.docs
          .map((doc) => doc['recipeId'].toString())
          .toList();

      print("✅ Fetched ${notRecommendedIds.length} not recommended recipes");
      return notRecommendedIds;
    } catch (e) {
      print("❌ Error fetching not recommended recipes: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecommendedRecipes(
      String userId) async {
    try {
      print('🔍 Starting getRecommendedRecipes for user: $userId');

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
  
  // สร้างคีย์แคชที่มีการเปลี่ยนแปลงเมื่อข้อมูลเปลี่ยน
  Timestamp lastUpdated;
      if (userDoc.exists) {
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null && userData.containsKey('lastUpdated')) {
          lastUpdated = userData['lastUpdated'];
        } else {
          lastUpdated = Timestamp.now();
        }
      } else {
        lastUpdated = Timestamp.now();
      }
  
  // ดึงข้อมูลวัตถุดิบที่ใกล้หมดอายุเพื่อสร้าง signature
  List<Map<String, dynamic>> expiringIngredients = await fetchIngredientsWithExpiry(userId);
  expiringIngredients.sort((a, b) {
    DateTime aDate = a['expiryDate'] is DateTime ? a['expiryDate'] : DateTime.now();
    DateTime bDate = b['expiryDate'] is DateTime ? b['expiryDate'] : DateTime.now();
    return aDate.compareTo(bDate);
  });
  
  // สร้าง signature จากวัตถุดิบที่ใกล้หมดอายุใน 7 วัน
  List<String> expiringSoon = [];
  for (var ingredient in expiringIngredients) {
    DateTime expiryDate = ingredient['expiryDate'] is DateTime 
        ? ingredient['expiryDate'] 
        : DateTime.now().add(Duration(days: 30));
        
    if (expiryDate.difference(DateTime.now()).inDays <= 7) {
      expiringSoon.add(ingredient['name']);
    }
  }
  String ingredientSignature = expiringSoon.join(',');
  
  // สร้างคีย์แคชใหม่ที่เปลี่ยนเมื่อข้อมูลเปลี่ยน
  String cacheKey = 'user_${userId}_${lastUpdated.millisecondsSinceEpoch}_${ingredientSignature.hashCode}';
  
  // ลดอายุแคชลงเหลือ 1 ชั่วโมง
  final int shortCacheDuration = 3600000; // 1 ชั่วโมง
      
      // ตรวจสอบแคชก่อน
        DocumentSnapshot cachedRecommendations = await _firestore
      .collection('users')
      .doc(userId)
      .collection('userCachedRecommendations') // แยกแคชตามผู้ใช้
      .doc(cacheKey)
          .get();

         
  if (cachedRecommendations.exists) {
    Map<String, dynamic> cachedData = cachedRecommendations.data() as Map<String, dynamic>;
    int timestamp = cachedData['timestamp'] ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - timestamp < shortCacheDuration) {
      print('✅ Using cached recommendations');
      return List<Map<String, dynamic>>.from(cachedData['recipes'] ?? []);
    }
  }
      
      // Fetch user data
      List<String> userIngredients = await fetchUserIngredients(userId);
      List<String> userPreferences = await fetchUserPreferences(userId);
      List<String> userAllergies = await fetchUserAllergies(userId);
      String userGoals = await fetchUserGoals(userId);
      List<Map<String, dynamic>> ingredientsWithExpiry =
          await fetchIngredientsWithExpiry(userId);
      List<String> notRecommendedIds = await fetchNotRecommendedRecipes(userId);

      DocumentSnapshot macroDoc = await _firestore
          .collection('usersCaloriesMacronutrient')
          .doc(userId)
          .get();

       if (!macroDoc.exists) {
        print('⚠️ No macro data found, using default values');
        userMacros = {
          'calories': 2000.0,
          'protein': 75.0,
          'carbs': 250.0,
          'fat': 65.0
        };
      } else {
        Map<String, dynamic> userMacroData =
            macroDoc.data() as Map<String, dynamic>;
        userMacros = {
          'calories': userMacroData['caloriesPerDay'] ?? 2000.0,
          'protein': userMacroData['proteinGrams'] ?? 75.0,
          'carbs': userMacroData['carbsGrams'] ?? 250.0,
          'fat': userMacroData['fatGrams'] ?? 65.0
        };
      }

      Map<String, dynamic> userMacroData =
          macroDoc.data() as Map<String, dynamic>;
      userMacros = {
        'calories': userMacroData['caloriesPerDay'] ?? 0.0,
        'protein': userMacroData['proteinGrams'] ?? 0.0,
        'carbs': userMacroData['carbsGrams'] ?? 0.0,
        'fat': userMacroData['fatGrams'] ?? 0.0
      };

      // Log all fetched data
      print('📊 User Data Summary:');
      print('- Ingredients: $userIngredients');
      print('- Preferences: $userPreferences');
      print('- Allergies: $userAllergies');
      print('- Goal: $userGoals');
      print('- Macros: $userMacros');

      // เรียกวัตถุดิบที่ใกล้หมดอายุก่อน
      ingredientsWithExpiry.sort((a, b) {
        DateTime aDate = a['expiryDate'] is DateTime ? a['expiryDate'] : DateTime.now();
        DateTime bDate = b['expiryDate'] is DateTime ? b['expiryDate'] : DateTime.now();
        return aDate.compareTo(bDate);
      });
      
      // เลือกวัตถุดิบที่ใกล้หมดอายุ 3 อย่างแรก (หรือน้อยกว่าถ้ามีไม่ถึง)
      List<String> priorityIngredients = [];
      for (var ingredient in ingredientsWithExpiry) {
        if (priorityIngredients.length < 3) {
          priorityIngredients.add(ingredient['name']);
        } else {
          break;
        }
      }
      
      // เอาวัตถุดิบที่เหลือถ้ามีไม่ถึง 3 อย่าง
      if (priorityIngredients.length < 3 && userIngredients.isNotEmpty) {
        for (var ingredient in userIngredients) {
          if (!priorityIngredients.contains(ingredient) && priorityIngredients.length < 3) {
            priorityIngredients.add(ingredient);
          }
        }
      }

      // เรียก API เพียงครั้งเดียว โดยใช้ getRecipesByCuisine พร้อมระบุวัตถุดิบที่มีอยู่
      List<Map<String, dynamic>> recipes = await _recipeService.getRecipesByCuisine(
        primaryCuisine: 'Thai',
        fallbackCuisines: ['Asian', 'Chinese', 'Japanese'],
        limit: 5,
        includeIngredients: priorityIngredients,
      );
      
      // กรองรายการอาหารที่ไม่แนะนำออก
      List<Map<String, dynamic>> filteredRecipes = recipes.where((recipe) {
        int recipeId = recipe['id'] is int ? recipe['id'] : int.parse(recipe['id'].toString());
        return !notRecommendedIds.contains(recipeId.toString());
      }).toList();

      // Filter and score recipes
      List<Map<String, dynamic>> recommendedRecipes = [];

      for (var recipe in filteredRecipes) {
        try {
          int score = 0;
          bool isValid = true;
          bool isThaiCuisine = recipe['cuisine'] == 'Thai';
          
          if (isThaiCuisine) {
            score += 30; // เพิ่มคะแนนให้อาหารไทย
          }

          // Check ingredients match (40 points max)
          var usedIngredients = recipe['usedIngredients'] as List<dynamic>? ?? [];
          for (var ingredient in usedIngredients) {
            String ingredientName = ingredient['name'] ?? '';
            Map<String, dynamic> defaultIngredient = {
              'expiryDate': DateTime.now().add(const Duration(days: 365)),
              'name': ingredientName
            };

            var matchingIngredient = ingredientsWithExpiry.firstWhere(
                (i) => i['name'].toLowerCase() == ingredientName.toLowerCase(),
                orElse: () => defaultIngredient);

            DateTime expiryDate = matchingIngredient['expiryDate'] is DateTime
                ? matchingIngredient['expiryDate']
                : DateTime.now().add(const Duration(days: 365));
            int daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;

            if (daysUntilExpiry <= 3) {
              score += 30;
            } else if (daysUntilExpiry <= 7) {
              score += 20;
            } else if (daysUntilExpiry <= 14) {
              score += 10;
            }
          }
          
          // Calculate match percentage
          int usedCount = recipe['usedIngredientCount'] is int
              ? recipe['usedIngredientCount']
              : int.tryParse(recipe['usedIngredientCount']?.toString() ?? '0') ?? 0;
          int missedCount = recipe['missedIngredientCount'] is int
              ? recipe['missedIngredientCount']
              : int.tryParse(recipe['missedIngredientCount']?.toString() ?? '0') ?? 0;

          double matchPercentage = (usedCount + missedCount) > 0
              ? (usedCount / (usedCount + missedCount)) * 100
              : 0;
          score += (matchPercentage * 0.4).round();
          
          // Check allergies (mandatory) - with safe extraction
          List<String> recipeIngredients = [];
          try {
            if (usedIngredients is List) {
              recipeIngredients = usedIngredients
                  .where((i) => i is Map && i['name'] != null)
                  .map((i) => i['name'].toString())
                  .toList();
            }
          } catch (e) {
            print('Warning: Error extracting ingredients: $e');
          }

          if (userAllergies.any((allergy) => recipeIngredients.contains(allergy))) {
            continue;
          }

          // Check preferences (10 points each)
          List<String> dishTypes = [];
          if (recipe['dishTypes'] != null) {
            if (recipe['dishTypes'] is List) {
              dishTypes = (recipe['dishTypes'] as List)
                  .map((type) => type.toString().toLowerCase())
                  .toList();
            } else if (recipe['dishTypes'] is String) {
              dishTypes = [recipe['dishTypes'].toString().toLowerCase()];
            }
          }

          for (String pref in userPreferences) {
            if (dishTypes.any((type) => type.contains(pref.toLowerCase()))) {
              score += 10;
            }
          }

          // Check calories and macros (30 points max)
          Map<String, dynamic> nutrition = recipe['nutrition'] ?? {};
          if (nutrition.isNotEmpty) {
            // Extract nutrition values with safe conversion
            double calories = nutrition['calories'] is num
                ? nutrition['calories'].toDouble()
                : double.tryParse(nutrition['calories']?.toString() ?? '0') ?? 0;
            double protein = nutrition['protein'] is num
                ? nutrition['protein'].toDouble()
                : double.tryParse(nutrition['protein']?.toString() ?? '0') ?? 0;
            double carbs = nutrition['carbs'] is num
                ? nutrition['carbs'].toDouble()
                : double.tryParse(nutrition['carbs']?.toString() ?? '0') ?? 0;
            double fat = nutrition['fat'] is num
                ? nutrition['fat'].toDouble()
                : double.tryParse(nutrition['fat']?.toString() ?? '0') ?? 0;

            // Create a Map with the extracted values (replacing the undefined recipeMacros)
            Map<String, dynamic> extractedMacros = {
              'calories': calories,
              'protein': protein,
              'carbs': carbs,
              'fat': fat
            };
            recipe['extractedMacros'] = extractedMacros;

            if (nutrition.isNotEmpty) {
              bool caloriesMatch = isCaloriesInRange(
                  calories, // Use direct value instead of accessing through recipeMacros
                  userMacros['calories'],
                  0.20 // 20% deviation allowed for calories
                  );
              bool proteinMatch = isMacroInRange(protein, userMacros['protein'],
                  0.15 // 15% deviation allowed for macros
                  );
              bool carbsMatch = isMacroInRange(carbs, userMacros['carbs'], 0.15);
              bool fatMatch = isMacroInRange(fat, userMacros['fat'], 0.15);

              if (caloriesMatch) score += 10;
              if (proteinMatch) score += 7;
              if (carbsMatch) score += 7;
              if (fatMatch) score += 6;

              // Add macro match percentage
              double macroMatchPercentage = ((caloriesMatch ? 1 : 0) +
                      (proteinMatch ? 1 : 0) +
                      (carbsMatch ? 1 : 0) +
                      (fatMatch ? 1 : 0)) *
                  25;

              recipe['macroMatchPercentage'] = macroMatchPercentage;
            }
          }

          // Check goal alignment (20 points)
          if (alignsWithGoal(recipe, userGoals)) {
            score += 20;
          }

          if (isValid) {
            recommendedRecipes.add({
              ...recipe,
              'recommendationScore': score,
              'matchPercentage': matchPercentage,
              'usesExpiringIngredients': score > 0,
              'isThaiCuisine': isThaiCuisine,
            });
          }
        } catch (e) {
          print('Error processing recipe: $e');
          continue;
        }
      }

      // Sort by score
      recommendedRecipes.sort((a, b) {
        if (a['isThaiCuisine'] != b['isThaiCuisine']) {
          return a['isThaiCuisine'] == true ? -1 : 1;
        }
        if (a['usesExpiringIngredients'] != b['usesExpiringIngredients']) {
          return b['usesExpiringIngredients'] ? 1 : -1;
        }
        return (b['recommendationScore'] ?? 0)
            .compareTo(a['recommendationScore'] ?? 0);
      });

      // แคชผลลัพธ์
      try {
  await _firestore
      .collection('users')
      .doc(userId)
      .collection('userCachedRecommendations')
      .doc(cacheKey)
      .set({
    'recipes': recommendedRecipes,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
  
  // ลบแคชเก่าที่ไม่ใช้แล้ว (optional)
  QuerySnapshot oldCaches = await _firestore
      .collection('users')
      .doc(userId)
      .collection('userCachedRecommendations')
      .where(FieldPath.documentId, isNotEqualTo: cacheKey)
      .get();
      
  for (var doc in oldCaches.docs) {
    await doc.reference.delete();
  }
} catch (e) {
  print('⚠️ Error caching recommendations: $e');
}
      print('✅ Successfully fetched recommendations: ${recommendedRecipes.length} recipes');
      
      // คืนค่าคำแนะนำสุดท้าย (จำกัด 5 รายการ)
      return recommendedRecipes.take(5).toList();
    } catch (e) {
      print('Error getting recommended recipes: $e');
      return [];
    }
  }

  bool isCaloriesInRange(
      dynamic recipeCalories, dynamic userCalories, double allowedDeviation) {
    if (recipeCalories == null || userCalories == null) return false;
    double recipeValue = double.tryParse(recipeCalories.toString()) ?? 0;
    double userValue = double.tryParse(userCalories.toString()) ?? 0;
    double deviation = (recipeValue - userValue).abs();
    return deviation <= (userValue * allowedDeviation);
  }

  bool isMacroInRange(
      dynamic recipeMacro, dynamic userMacro, double allowedDeviation) {
    if (recipeMacro == null || userMacro == null) return false;
    double recipeValue = double.tryParse(recipeMacro.toString()) ?? 0;
    double userValue = double.tryParse(userMacro.toString()) ?? 0;
    double deviation = (recipeValue - userValue).abs();
    return deviation <= (userValue * allowedDeviation);
  }

  bool alignsWithGoal(Map<String, dynamic> recipe, String userGoal) {
    try {
      Map<String, dynamic> nutrition = recipe['nutrition'] ?? {};
      double calories =
          double.tryParse(nutrition['calories']?.toString() ?? '0') ?? 0;
      double protein =
          double.tryParse(nutrition['protein']?.toString() ?? '0') ?? 0;
      double carbs =
          double.tryParse(nutrition['carbs']?.toString() ?? '0') ?? 0;
      double fat = double.tryParse(nutrition['fat']?.toString() ?? '0') ?? 0;

      // Get user macro values with null safety
      double userCalories =
          double.tryParse(userMacros['calories'].toString()) ?? 0.0;
      double userProtein =
          double.tryParse(userMacros['protein'].toString()) ?? 0.0;
      double userCarbs = double.tryParse(userMacros['carbs'].toString()) ?? 0.0;
      double userFat = double.tryParse(userMacros['fat'].toString()) ?? 0.0;

      switch (userGoal.toLowerCase()) {
        case 'build muscle':
          return protein >= userProtein * 0.3 &&
              calories >= userCalories * 0.3 &&
              carbs >= userCarbs * 0.3;

        case 'lose weight':
          return calories <= userCalories * 0.4 &&
              protein >= userProtein * 0.25;

        case 'balanced diet':
          return (protein >= userProtein * 0.7 &&
                  protein <= userProtein * 1.3) &&
              (carbs >= userCarbs * 0.7 && carbs <= userCarbs * 1.3) &&
              (fat >= userFat * 0.7 && fat <= userFat * 1.3);

        case 'healthy eating':
          return calories >= 300 &&
              calories <= userCalories * 0.5 &&
              protein >= userProtein * 0.2 &&
              carbs >= userCarbs * 0.2 &&
              fat >= userFat * 0.2;

        default:
          return true;
      }
    } catch (e) {
      print('Error checking goal alignment: $e');
      return false;
    }
  }
}