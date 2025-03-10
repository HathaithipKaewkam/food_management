import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

Future<List<String>> getRecipesByIngredients(List<String> ingredients) async {
  if (ingredients.isEmpty) {
    print("No ingredients provided for the recipe search.");
    return [];
  }

  String ingredientString = ingredients.join(',');

  final response = await http.get(
    Uri.parse(
      'https://api.spoonacular.com/recipes/findByIngredients?ingredients=$ingredientString&apiKey=bd24cc0518a546b3a16d79dee986ea98',
    ),
  );

  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    return data.map<String>((recipe) => recipe['title'].toString()).toList();
  } else {
    throw Exception(
        'Failed to load recipes, status code: ${response.statusCode}');
  }
}

Future<List<String>> getRecipeAndPairings(String ingredientName) async {
  final response = await http.get(
    Uri.parse(
        'https://api.spoonacular.com/recipes/findByIngredients?ingredients=$ingredientName&apiKey=bd24cc0518a546b3a16d79dee986ea98'),
  );

  if (response.statusCode == 200) {
    var data = json.decode(response.body);

    if (data is List && data.isNotEmpty) {
      Set<String> pairingIngredients = {};

      for (var recipe in data.take(20)) {
        List<dynamic> missedIngredients = recipe['missedIngredients'];
        for (var ingredient in missedIngredients) {
          String ingredientName = ingredient['originalName'] ?? ingredient['name'] ?? "Unknown Ingredient";
          if (ingredientName.split(' ').length <= 2) {
            pairingIngredients.add(ingredientName);
          }
          if (pairingIngredients.length >= 10) {
            break;
          }
        }
        if (pairingIngredients.length >= 10) {
          break;
        }
      }

      return pairingIngredients.toList();
    } else {
      throw Exception('No recipe data found.');
    }
  } else {
    throw Exception('Failed to load recipe');
  }
}

void main() async {
  List<String> userIngredients = await fetchUserIngredients();
  print("User has these ingredients: $userIngredients");

  if (userIngredients.isNotEmpty) {
    List<String> recipes = await getRecipesByIngredients(userIngredients);
    print('Recipes: $recipes');
  } else {
    print("No ingredients found to search recipes.");
  }

  await getRecipeAndPairings('1');
}
