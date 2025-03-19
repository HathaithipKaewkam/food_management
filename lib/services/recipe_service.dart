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
    print("No ingredients provided for the recipe search.");
    return [];
  }

  String ingredientString = ingredients.join(',');

  // เรียก API ของ Spoonacular
  final response = await http.get(
    Uri.parse(
      'https://api.spoonacular.com/recipes/findByIngredients?ingredients=$ingredientString&apiKey=bd24cc0518a546b3a16d79dee986ea98',
    ),
  );

  if (response.statusCode == 200) {
    var data = json.decode(response.body);

    // สร้าง List ที่เก็บชื่อสูตรและภาพ
    List<Map<String, String>> recipes = [];

    for (var recipe in data.take(5)) { // จำกัดให้ได้แค่ 5 สูตร
      String title = utf8.decode(recipe['title'].runes.toList()) ?? 'Unknown Recipe';
      String image = recipe['image'] ?? '';

      // ตรวจสอบว่าในสูตรอาหารมีส่วนผสมที่ตรงกับ userIngredients เท่าไหร่
      int matchedIngredients = 0;

      // เอาส่วนผสมที่มีในสูตรอาหารมานับว่าเจอส่วนผสมจาก ingredients ที่ผู้ใช้ให้มาเท่าไหร่
      List<String> recipeIngredients = List<String>.from(recipe['usedIngredients']?.map((ingredient) => ingredient['name']) ?? []);

      // นับส่วนผสมที่ตรง
      for (var ingredient in ingredients) {
        if (recipeIngredients.contains(ingredient)) {
          matchedIngredients++;
        }
      }

      // ถ้ามีส่วนผสมตรงกันแม้จะไม่ครบทุกอย่าง ก็จะเพิ่มสูตรอาหารเข้าไป
      // ในที่นี้เราใช้ว่า ถ้ามีส่วนผสมตรง 1 อย่างก็แสดงสูตรนั้น
      if (matchedIngredients > 0) {
        recipes.add({
          'title': title,
          'image': image,
        });
      }
    }

    return recipes;
  } else {
    throw Exception('Failed to load recipes, status code: ${response.statusCode}');
  }
}
