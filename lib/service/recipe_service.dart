import 'dart:convert';
import 'package:food_project/models/recipe.dart';
import 'package:http/http.dart' as http;



class RecipeService {
  final String apiKey = 'bd24cc0518a546b3a16d79dee986ea98';
  final String baseUrl = 'https://api.spoonacular.com/recipes/'; // URL พื้นฐานของ API

  // ดึงข้อมูล Recipe ทั้งหมด
  Future<List<Recipe>> fetchRecipes() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/recipes"));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Recipe.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load recipes");
      }
    } catch (error) {
      throw Exception("Error: $error");
    }
  }

  // ดึงข้อมูล Recipe ตาม ID
  Future<Recipe> fetchRecipeById(int id) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/recipes/$id"));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        return Recipe.fromJson(data);
      } else {
        throw Exception("Recipe not found");
      }
    } catch (error) {
      throw Exception("Error: $error");
    }
  }

  // เพิ่ม Recipe ใหม่
  Future<bool> addRecipe(Recipe recipe) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/recipes"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(recipe.toJson()),
      );

      return response.statusCode == 201; // 201 = Created
    } catch (error) {
      throw Exception("Error: $error");
    }
  }

  // อัปเดต Recipe
  Future<bool> updateRecipe(Recipe recipe) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/recipes/${recipe.recipeId}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(recipe.toJson()),
      );

      return response.statusCode == 200; // 200 = OK
    } catch (error) {
      throw Exception("Error: $error");
    }
  }

  // ลบ Recipe
  Future<bool> deleteRecipe(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/recipes/$id"),
      );

      return response.statusCode == 200; // 200 = OK
    } catch (error) {
      throw Exception("Error: $error");
    }
  }

  // search recipe 
  Future<void> searchRecipe(String query) async {
    final url = Uri.parse('$baseUrl/complexSearch?query=$query&apiKey=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Found recipes: ${data['results']}');
    } else {
      print('Failed to load recipes');
    }
  }
}

void main() async {
  RecipeService recipeService = RecipeService();
  await recipeService.searchRecipe('spaghetti');
}

