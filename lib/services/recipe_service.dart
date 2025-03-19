import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// ดึงรายการวัตถุดิบของผู้ใช้จาก Firebase
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

Future<List<Map<String, String>>> getRecipesWithImages(List<String> ingredients) async {
  if (ingredients.isEmpty) {
    print("❌ No ingredients provided for the recipe search.");
    return [];
  }

  String ingredientString = ingredients
      .map((e) => e.trim().toLowerCase())
      .map((e) => Uri.encodeComponent(e))
      .join(',');
  
  print("🔍 Searching recipes for: $ingredientString");

  final String apiUrl = 'https://api.spoonacular.com/recipes/findByIngredients';
  final String apiKey = 'bd24cc0518a546b3a16d79dee986ea98';
  // Set number=10 for exact number of recipes and ranking=2 for best matches
  final Uri uri = Uri.parse('$apiUrl?ingredients=$ingredientString&apiKey=$apiKey&number=10&ranking=2&limitLicense=true');

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      var data = json.decode(response.body) as List;
      List<Map<String, String>> recipes = [];
      
      // Take only the first 10 recipes
      for (var recipe in data.take(10)) {
        String title = recipe['title'] ?? 'Unknown Recipe';
        String image = recipe['image'] ?? '';
        int usedCount = recipe['usedIngredientCount'] ?? 0;
        int missedCount = recipe['missedIngredientCount'] ?? 0;
        
        recipes.add({
          'title': title,
          'image': image,
          'usedIngredientCount': usedCount.toString(),
          'missedIngredientCount': missedCount.toString(),
          'matchPercentage': ((usedCount / (usedCount + missedCount)) * 100).toStringAsFixed(0)
        });
        
        print("✅ Recipe: $title (Matching: $usedCount, Missing: $missedCount)");
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