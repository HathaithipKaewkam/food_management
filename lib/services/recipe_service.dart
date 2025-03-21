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
    final String apiKey = 'bd24cc0518a546b3a16d79dee986ea98';
    // Set number=10 for exact number of recipes and ranking=2 for best matches
    final Uri uri = Uri.parse(
        '$apiUrl?ingredients=$ingredientString&apiKey=$apiKey&number=10&ranking=2&limitLicense=true');

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
          var recipeInfo = await getRecipeInformation(recipeId);
          String readyInMinutes = recipeInfo['readyInMinutes'] ?? 'N/A';
         String dishType = 'Main Course';
            if (recipeInfo['dishTypes'] != null && recipeInfo['dishTypes'] is List) {
              var types = recipeInfo['dishTypes'] as List<String>;
              if (types.isNotEmpty) {
                dishType = types.first;
              }
            }
          
          recipes.add({
            'title': title,
            'image': image,
            'usedIngredientCount': usedCount.toString(),
            'missedIngredientCount': missedCount.toString(),
            'matchPercentage': ((usedCount / (usedCount + missedCount)) * 100)
                .toStringAsFixed(0),
            'readyInMinutes': readyInMinutes,
           
            'dishTypes': dishType,

            
          });
         print("✅ Recipe: $title (Dish Type: $dishType)");
  ;
         
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
}

Future<Map<String, dynamic>> getRecipeInformation(int recipeId) async {
    final String apiKey = 'bd24cc0518a546b3a16d79dee986ea98';
    final String apiUrl =
        'https://api.spoonacular.com/recipes/$recipeId/information?apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
      var data = json.decode(response.body);

       List<String> dishTypes = [];
        if (data['dishTypes'] != null && data['dishTypes'] is List) {
          dishTypes = (data['dishTypes'] as List)
              .map((x) => x.toString())
              .toList();
        }
      
      return {
        'readyInMinutes': data['readyInMinutes']?.toString() ?? 'N/A',
        'calories': data['nutrition']?['nutrients']?.firstWhere(
          (nutrient) => nutrient['name'] == 'Calories',
          orElse: () => {'amount': 0}
        )['amount']?.toString() ?? '0',
        'title': data['title'] ?? '',
        'image': data['image'] ?? '',
       'dishTypes': dishTypes,
       
       
      
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