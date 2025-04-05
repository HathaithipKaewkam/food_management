import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_project/models/ingredient.dart';

class Recipe {
  final int recipeId; 
  final String recipeName;
  final String description; 
  final List<IngredientUsage> ingredients;
  final List<String> instructions;
  final int preparationTime; 
  final int cookingTime; 
  final int servings; 
  final String category; 
  final String imageUrl; 
  final double Protein;
  final double Fat;
  final double Carbo;
  final int Kcal;
  bool isFavorite;
  String? createdBy;

  Recipe({
    required this.recipeId,
    required this.recipeName,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.preparationTime,
    required this.cookingTime,
    required this.servings,
    required this.category,
    required this.imageUrl,
    required this.Protein,
    required this.Fat,
    required this.Carbo,
    required this.Kcal,
    this.isFavorite = false,
    this.createdBy,
  });

  // คำนวณเวลารวมในการทำอาหาร
  int totalCookingTime() {
    return preparationTime + cookingTime;
  }

  // ตรวจสอบว่าส่วนผสมครบหรือไม่
  bool hasAllIngredients(List<Ingredient> ingredients) {
  return ingredients.every((ingredient) => ingredient.isSelected);
}

  // ฟังก์ชันแปลง JSON -> Recipe
factory Recipe.fromJson(Map<String, dynamic> json) {
  return Recipe(
    recipeId: json['recipeId'],
    recipeName: json['recipeName'],
    description: json['description'],
    ingredients: (json['ingredients'] as List)
        .map((item) => IngredientUsage.fromJson(item))
        .toList(),
    instructions: List<String>.from(json['instructions']),
    preparationTime: json['preparationTime'],
    cookingTime: json['cookingTime'],
    servings: json['servings'],
    category: json['category'],
    imageUrl: json['imageUrl'],
    Protein: json['Protein'].toDouble(),
    Fat: json['Fat'].toDouble(),
    Carbo: json['Carbo'].toDouble(),
    Kcal: json['Kcal'],
    isFavorite: json['isFavorite'] ?? false, 
     createdBy: json['createdBy'],
  );
}

  String? get title => null;
  int get id => recipeId;

// ฟังก์ชันแปลง Recipe -> JSON
Map<String, dynamic> toJson() {
  return {
    'recipeId': recipeId,
    'recipeName': recipeName,
    'description': description,
    'ingredients': ingredients.map((item) => item.toJson()).toList(),
    'instructions': instructions,
    'preparationTime': preparationTime,
    'cookingTime': cookingTime,
    'servings': servings,
    'category': category,
    'imageUrl': imageUrl,
    'Protein': Protein,
    'Fat': Fat,
    'Carbo': Carbo,
    'Kcal': Kcal,
    'isFavorite': isFavorite,
    'createdBy': createdBy,
  };
}

factory Recipe.fromFirestore(Map<String, dynamic> data, String docId) {
  List<IngredientUsage> ingredientList = [];
  
  if (data['ingredients'] != null) {
    try {
      List<dynamic> ingredientsData = data['ingredients'];
      print("Processing ingredients data from Firebase: $ingredientsData");
      
      for (var ingData in ingredientsData) {
        if (ingData is Map<String, dynamic>) {
          // สร้าง Ingredient object จากข้อมูลใน Firebase
          final ingredient = Ingredient(
            ingredientsName: ingData['name'] ?? 'Unknown',
            unit: ingData['unit'] ?? '',
            imageUrl: 'assets/images/ingredient_placeholder.png', // default image
            userId: FirebaseAuth.instance.currentUser?.uid ?? '',
            ingredientId: DateTime.now().millisecondsSinceEpoch.toString(),
            category: 'Other',
            storage: 'Pantry',
            quantity: 0.0,
            minQuantity: 0.0,
            expirationDate: DateTime.now().add(Duration(days: 30)),
            source: 'Recipe',
            kcal: 0.0,
          );
          
          // แปลง amount เป็น double
          double amount = 0.0;
          if (ingData['amount'] != null) {
            amount = (ingData['amount'] is int) 
                ? (ingData['amount'] as int).toDouble() 
                : (ingData['amount'] is double) 
                    ? (ingData['amount'] as double) 
                    : double.tryParse(ingData['amount'].toString()) ?? 0.0;
          }
          
          // สร้าง IngredientUsage object
          final ingredientUsage = IngredientUsage(
            ingredient: ingredient,
            quantityUsed: amount,
          );
          
          ingredientList.add(ingredientUsage);
          print("Added ingredient: ${ingredient.ingredientsName}, amount: $amount");
        }
      }
    } catch (e) {
      print('Error parsing ingredients from Firestore: $e');
    }
  }
  
  return Recipe(
    recipeId: int.tryParse(docId) ?? 0,
    recipeName: data['recipeName'] ?? '',
    description: data['description'] ?? '',
    ingredients: ingredientList,
    instructions: List<String>.from(data['instructions'] ?? []),
    preparationTime: data['preparationTime'] ?? 0,
    cookingTime: data['cookingTime'] ?? 0,
    servings: data['servings'] ?? 0,
    category: data['category'] ?? '',
    imageUrl: data['imageUrl'] ?? '',
    Protein: (data['Protein'] ?? 0.0).toDouble(),
    Fat: (data['Fat'] ?? 0.0).toDouble(),
    Carbo: (data['Carbo'] ?? 0.0).toDouble(),
    Kcal: data['Kcal'] ?? 0,
    isFavorite: data['isFavorite'] ?? false,
    createdBy: data['createdBy'] ?? '',
  );
}


  static List<Recipe> getFavoritedRecipe(List<Recipe> recipeList) {
    return recipeList.where((element) => element.isFavorite).toList();
  }
}

class IngredientUsage {
  final Ingredient ingredient;
  final double quantityUsed; // จำนวนที่ใช้

  IngredientUsage({required this.ingredient, required this.quantityUsed});

  // ✅ ฟังก์ชันแปลง JSON -> IngredientUsage
  factory IngredientUsage.fromJson(Map<String, dynamic> json) {
    return IngredientUsage(
      ingredient: Ingredient.fromJson(json['ingredient'] ?? {}),
      quantityUsed: (json['quantityUsed'] ?? 0.0).toDouble(),
    );
  }

  // ✅ ฟังก์ชันแปลง IngredientUsage -> JSON
  Map<String, dynamic> toJson() {
    return {
      'ingredient': ingredient.toJson(),
      'quantityUsed': quantityUsed,
    };
  }
}

