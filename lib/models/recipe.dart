import 'package:food_project/models/ingredient.dart';

class Recipe {
  final int recipeId; // รหัสสูตรอาหาร
  final String recipeName; // ชื่อสูตรอาหาร
  final String description; // คำอธิบาย
  final List<IngredientUsage> ingredients; // รายการส่วนผสม
  final List<String> instructions; // วิธีทำ
  final int preparationTime; // เวลาที่ใช้เตรียม (นาที)
  final int cookingTime; // เวลาที่ใช้ทำอาหาร (นาที)
  final int servings; // จำนวนเสิร์ฟ
  final String category; // หมวดหมู่ (เช่น อาหารเช้า อาหารเย็น)
  final String imageUrl; // URL รูปภาพ
  final double Protein;
  final double Fat;
  final double Carbo;
  final int Kcal;
  bool isFavorite; // สถานะเป็นสูตรโปรด

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
    this.isFavorite = false, // ค่าเริ่มต้นเป็น false
  });

  // คำนวณเวลารวมในการทำอาหาร
  int totalCookingTime() {
    return preparationTime + cookingTime;
  }

  // ตรวจสอบว่าส่วนผสมครบหรือไม่
  bool hasAllIngredients(List<Ingredient> ingredients) {
  return ingredients.every((ingredient) => ingredient.isSelected);
}


  // สร้างรายการสูตรอาหารตัวอย่าง
  static List<Recipe> recipeList = [
    Recipe(
      recipeId: 1,
      recipeName: 'Spaghetti Carbonara',
      description: 'Classic Italian pasta dish with creamy sauce.',
       ingredients: Ingredient.ingredientList != null && Ingredient.ingredientList.length > 4
      ? [
          IngredientUsage(ingredient: Ingredient.ingredientList[2], quantityUsed: 1.0),
          IngredientUsage(ingredient: Ingredient.ingredientList[1], quantityUsed: 1.0),
          IngredientUsage(ingredient: Ingredient.ingredientList[4], quantityUsed: 1.0),
        ]
      : [],
      instructions: [
        'Boil water in a large pot.',
        'Add pasta and cook according to package instructions.',
        'In a separate pan, heat milk and egg to make the creamy sauce.',
        'Drain pasta and mix with sauce.',
        'Serve hot and garnish with cheese.',
      ],
      preparationTime: 10,
      cookingTime: 15,
      servings: 2,
      category: 'Main Course',
      Protein: 13,
      Fat: 1.5,
      Carbo: 74.7,
      Kcal: 371,
      imageUrl: 'assets/images/spaghetti.png',
    ),
    Recipe(
      recipeId: 2,
      recipeName: 'Grilled Pork Chops',
      description: 'Juicy pork chops seasoned and grilled to perfection.',
       ingredients: Ingredient.ingredientList != null && Ingredient.ingredientList.length > 3
      ? [
          IngredientUsage(ingredient: Ingredient.ingredientList[3], quantityUsed: 2.0),
        ]
      : [],
      instructions: [
        'Preheat your grill to medium-high heat.',
        'Season the pork chops with olive oil, salt, pepper, and your preferred spices.',
        'Place the pork chops on the grill and cook for 4-5 minutes on each side, or until the internal temperature reaches 145°F (63°C).',
        'Remove the pork chops from the grill and let them rest for 3-5 minutes.',
        'Serve with your favorite sides and enjoy!',
      ],
      preparationTime: 5,
      cookingTime: 20,
      servings: 2,
      category: 'Main Course',
      Protein: 24,
      Fat: 14,
      Carbo: 0,
      Kcal: 231,
      imageUrl: 'assets/images/grilled_pork.png',
    ),
  ];

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
    isFavorite: json['isFavorite'] ?? false, // ค่าเริ่มต้นเป็น false ถ้าไม่มีใน JSON
  );
}

  String? get title => null;

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
  };
}


  static List<Recipe> getFavoritedRecipe() {
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

