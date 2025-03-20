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

      List<String> preferences = snapshot.docs
          .map((doc) => doc['foodName'].toString())
          .toList();

      print("✅ Fetched preferences: $preferences");
      return preferences;
    } catch (e) {
      print("❌ Error fetching preferences: $e");
      return [];
    }
  }

  Future<String> fetchUserGoals(String userId) async {
    try {
      final doc = await _firestore
          .collection('userGoals')
          .doc(userId)
          .get();

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

      List<String> allergies = snapshot.docs
          .map((doc) => doc['foodName'].toString())
          .toList();

      print("✅ Fetched allergies: $allergies");
      return allergies;
    } catch (e) {
      print("❌ Error fetching allergies: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchIngredientsWithExpiry(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('userIngredients')
          .get();

      return snapshot.docs.map((doc) {
        return {
          'name': doc['ingredientsName'].toString(),
          'expiryDate': (doc['expirationDate'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      print("❌ Error fetching ingredients with expiry: $e");
      return [];
    }
  }

  

  Future<List<Map<String, dynamic>>> getRecommendedRecipes(String userId) async {
    try {

      print('🔍 Starting getRecommendedRecipes for user: $userId');
      // Fetch user data

      List<String> userIngredients = await fetchUserIngredients(userId);
      List<String> userPreferences = await fetchUserPreferences(userId);
      List<String> userAllergies = await fetchUserAllergies(userId);
      String userGoals = await fetchUserGoals(userId);
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      List<Map<String, dynamic>> ingredientsWithExpiry = await fetchIngredientsWithExpiry(userId);
      

      DocumentSnapshot macroDoc = await _firestore
          .collection('usersCaloriesMacronutrient')
          .doc(userId)
          .get();

      if (!macroDoc.exists) {
        print('⚠️ No macro data found');
        return [];
      }

      Map<String, dynamic> userMacroData = macroDoc.data() as Map<String, dynamic>;
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


      // Get recipes from API
      List<Map<String, dynamic>> allRecipes = await _recipeService.getRecipesWithImages(userIngredients);

      // Filter and score recipes
      List<Map<String, dynamic>> recommendedRecipes = [];
      ingredientsWithExpiry.sort((a, b) => 
        (a['expiryDate'] as DateTime).compareTo(b['expiryDate'] as DateTime));
      
      for (var recipe in allRecipes) {
        try {
          int score = 0;
          bool isValid = true;

          // Check ingredients match (40 points max)
          var usedIngredients = recipe['usedIngredients'] as List<dynamic>? ?? [];
           for (var ingredient in usedIngredients) {
            String ingredientName = ingredient['name'] ?? '';
            var matchingIngredient = ingredientsWithExpiry.firstWhere(
              (i) => i['name'].toLowerCase() == ingredientName.toLowerCase(),
              orElse: () => {'expiryDate': DateTime.now().add(const Duration(days: 365))}
            );

            // คำนวณวันที่เหลือก่อนหมดอายุ
            int daysUntilExpiry = (matchingIngredient['expiryDate'] as DateTime)
                .difference(DateTime.now()).inDays;

            // ให้คะแนนเพิ่มตามความใกล้วันหมดอายุ
            if (daysUntilExpiry <= 3) {
              score += 30; // ใกล้หมดมาก (0-3 วัน)
            } else if (daysUntilExpiry <= 7) {
              score += 20; // ใกล้หมด (4-7 วัน)
            } else if (daysUntilExpiry <= 14) {
              score += 10; // เริ่มใกล้หมด (8-14 วัน)
            }
          }
          double matchPercentage = usedIngredients.isEmpty ? 0 : 
              (recipe['usedIngredientCount'] ?? 0) / ((recipe['usedIngredientCount'] ?? 0) + (recipe['missedIngredientCount'] ?? 0)) * 100;
          score += (matchPercentage * 0.4).round();

          // Check allergies (mandatory)
          List<String> recipeIngredients = List<String>.from(usedIngredients.map((i) => i['name'] ?? ''));
          if (userAllergies.any((allergy) => recipeIngredients.contains(allergy))) {
            continue;
          }

          // Check preferences (10 points each)
          List<String> dishTypes = List<String>.from(recipe['dishTypes'] ?? []);
          for (String pref in userPreferences) {
            if (dishTypes.contains(pref)) {
              score += 10;
            }
          }

          // Check calories and macros (30 points max)
          Map<String, dynamic> recipeMacros = recipe['nutrition'] ?? {};
          if (recipeMacros.isNotEmpty) {
            bool caloriesMatch = isCaloriesInRange(
              recipeMacros['calories'], 
              userMacros['calories'],
              0.20 // 20% deviation allowed for calories
            );
            bool proteinMatch = isMacroInRange(
              recipeMacros['protein'], 
              userMacros['protein'],
              0.15 // 15% deviation allowed for macros
            );
            bool carbsMatch = isMacroInRange(
              recipeMacros['carbs'], 
              userMacros['carbs'],
              0.15
            );
            bool fatMatch = isMacroInRange(
              recipeMacros['fat'], 
              userMacros['fat'],
              0.15
            );

            if (caloriesMatch) score += 10;
            if (proteinMatch) score += 7;
            if (carbsMatch) score += 7;
            if (fatMatch) score += 6;

            // Add macro match percentage
            double macroMatchPercentage = ((caloriesMatch ? 1 : 0) + 
                                         (proteinMatch ? 1 : 0) + 
                                         (carbsMatch ? 1 : 0) + 
                                         (fatMatch ? 1 : 0)) * 25;
            
            recipe['macroMatchPercentage'] = macroMatchPercentage;
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
            });
          }
        } catch (e) {
          print('Error processing recipe: $e');
          continue;
        }
      }

      // Sort by score
      recommendedRecipes.sort((a, b) {
        if (a['usesExpiringIngredients'] != b['usesExpiringIngredients']) {
          return b['usesExpiringIngredients'] ? 1 : -1;
        }
        return (b['recommendationScore'] ?? 0).compareTo(a['recommendationScore'] ?? 0);
      });

      print('✅ Successfully fetched recommendations');
      return recommendedRecipes.take(10).toList();
    } catch (e) {
      print('Error getting recommended recipes: $e');
      return [];
    }
  }

  bool isCaloriesInRange(dynamic recipeCalories, dynamic userCalories, double allowedDeviation) {
    if (recipeCalories == null || userCalories == null) return false;
    double recipeValue = double.tryParse(recipeCalories.toString()) ?? 0;
    double userValue = double.tryParse(userCalories.toString()) ?? 0;
    double deviation = (recipeValue - userValue).abs();
    return deviation <= (userValue * allowedDeviation);
  }

  bool isMacroInRange(dynamic recipeMacro, dynamic userMacro, double allowedDeviation) {
    if (recipeMacro == null || userMacro == null) return false;
    double recipeValue = double.tryParse(recipeMacro.toString()) ?? 0;
    double userValue = double.tryParse(userMacro.toString()) ?? 0;
    double deviation = (recipeValue - userValue).abs();
    return deviation <= (userValue * allowedDeviation);
  }

  bool alignsWithGoal(Map<String, dynamic> recipe, String userGoal) {
    try {
      Map<String, dynamic> nutrition = recipe['nutrition'] ?? {};
      double calories = double.tryParse(nutrition['calories']?.toString() ?? '0') ?? 0;
      double protein = double.tryParse(nutrition['protein']?.toString() ?? '0') ?? 0;
      double carbs = double.tryParse(nutrition['carbs']?.toString() ?? '0') ?? 0;
      double fat = double.tryParse(nutrition['fat']?.toString() ?? '0') ?? 0;

      // Get user macro values with null safety
      double userCalories = double.tryParse(userMacros['calories'].toString()) ?? 0.0;
      double userProtein = double.tryParse(userMacros['protein'].toString()) ?? 0.0;
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
                 (carbs >= userCarbs * 0.7 && 
                  carbs <= userCarbs * 1.3) &&
                 (fat >= userFat * 0.7 && 
                  fat <= userFat * 1.3);
          
        case 'healthy eating':
          return calories >= 300 && calories <= userCalories * 0.5 &&
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