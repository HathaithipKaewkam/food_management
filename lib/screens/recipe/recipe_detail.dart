import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/screens/recipe/edit.recipe.dart';
import 'package:food_project/services/meal_plan_service.dart';
import 'package:food_project/services/recipe_service.dart';
import 'package:food_project/widgets/instruction_widget.dart';
import 'package:food_project/widgets/recipe_ingredient_widget.dart';

class RecipeDetail extends StatefulWidget {
  final Recipe recipe;
  final int recipeId;
  final String recipeDocId;
  final bool loadFullData;

  const RecipeDetail({
    super.key,
    required this.recipe,
    required this.recipeId,
    required this.recipeDocId,
    this.loadFullData = false,
  });

  @override
  State<RecipeDetail> createState() => _RecipeDetailState();
}

class _RecipeDetailState extends State<RecipeDetail> {
  final RecipeService _recipeService = RecipeService();
  int currentNumber = 1;
  bool showIngredients = true;
  List<Map<String, dynamic>> userIngredients = [];
  List<Recipe> recipeList = [];
  late Recipe currentRecipe;
  late String currentRecipeDocId;

 

  Widget _buildMealChip(
      String meal, String selectedMeal, Function(String) onSelected) {
    final isSelected = meal == selectedMeal;

    return GestureDetector(
      onTap: () => onSelected(meal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF78d454) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF78d454) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          meal,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  ImageProvider<Object> _getImageProvider(String imageUrl) {
    if (imageUrl.isEmpty) {
      return AssetImage('assets/images/placeholder.png');
    } else if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
      return NetworkImage(imageUrl);
    } else if (imageUrl.startsWith('assets/')) {
      return AssetImage(imageUrl);
    } else {
      return AssetImage('assets/images/placeholder.png');
    }
  }

  

  @override
void initState() {
  super.initState();
  currentRecipe = widget.recipe;
  currentRecipeDocId = widget.recipeDocId;
  

  
  fetchUserIngredients();

  if (widget.loadFullData || 
      currentRecipe.ingredients.length <= 1 || 
      currentRecipe.instructions.length <= 1) {
    print("🔄 Loading full recipe data because data is incomplete or loadFullData=true");
    _loadFullRecipeData();
  } else {
    print("✅ Recipe already has complete data, skipping API fetch");
  }
  
  // แก้ไขเงื่อนไขให้ตรวจสอบค่าโภชนาการด้วย
  if (widget.loadFullData && 
      (currentRecipe.ingredients.isEmpty || 
       currentRecipe.instructions.isEmpty ||
       currentRecipe.Protein <= 0 || // เพิ่มการตรวจสอบค่าโภชนาการ
       currentRecipe.Fat <= 0 ||
       currentRecipe.Carbo <= 0 ||
       currentRecipe.Kcal <= 0)) {
    print("🔄 Loading full recipe data because data is incomplete");
    _loadFullRecipeData();
  } else {
    print("✅ Recipe already has complete data, skipping API fetch");
  }
}

  @override
void dispose() {
  Navigator.pop(context, true);
  super.dispose();
}

 

Future<void> _loadFullRecipeData() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
 
    // 1. ดึงข้อมูลจาก API ก่อนถ้ามี recipeId และมาจากหน้า Ingredient Detail
    if (currentRecipe.recipeId > 0 && (widget.loadFullData || currentRecipe.ingredients.length <= 1)) {
     
      try {
        final recipeData = await _recipeService.getRecipeById(currentRecipe.recipeId);
        
        if (recipeData != null && recipeData.isNotEmpty) {
         
          
          // แปลงข้อมูลวัตถุดิบ
          List<IngredientUsage> ingredients = [];
          
          
          // ลำดับการใช้ข้อมูลวัตถุดิบ: extendedIngredients -> usedIngredients+missedIngredients
          if (recipeData['extendedIngredients'] != null && recipeData['extendedIngredients'] is List) {
            print("📦 Using extendedIngredients: ${(recipeData['extendedIngredients'] as List).length} items");
            
            for (var ing in recipeData['extendedIngredients']) {
              final ingredient = Ingredient.fromAPI(
                id: ing['id']?.toString() ?? '',
                name: ing['name'] ?? '',
                amount: ing['amount'] is num ? ing['amount'].toDouble() : 0.0,
                unit: ing['unit'] ?? '',
              );
              
              ingredients.add(IngredientUsage(
                ingredient: ingredient,
                quantityUsed: ing['amount'] is num ? ing['amount'].toDouble() : 0.0,
              ));
            }
          } 
          else if (recipeData['usedIngredients'] != null) {
            print("📦 Using usedIngredients: ${(recipeData['usedIngredients'] as List).length} items");
            
            // เพิ่มทั้ง usedIngredients
            for (var ing in recipeData['usedIngredients']) {
              final ingredient = Ingredient.fromAPI(
                id: ing['id']?.toString() ?? '',
                name: ing['name'] ?? '',
                amount: ing['amount'] is num ? ing['amount'].toDouble() : 0.0,
                unit: ing['unit'] ?? '',
              );
              
              ingredients.add(IngredientUsage(
                ingredient: ingredient,
                quantityUsed: ing['amount'] is num ? ing['amount'].toDouble() : 0.0,
              ));
            }
            
            // เพิ่ม missedIngredients ด้วยถ้ามี
            if (recipeData['missedIngredients'] != null) {
              print("📦 Adding missedIngredients: ${(recipeData['missedIngredients'] as List).length} items");
              
              for (var ing in recipeData['missedIngredients']) {
                final ingredient = Ingredient.fromAPI(
                  id: ing['id']?.toString() ?? '',
                  name: ing['name'] ?? '',
                  amount: ing['amount'] is num ? ing['amount'].toDouble() : 0.0,
                  unit: ing['unit'] ?? '',
                );
                
                ingredients.add(IngredientUsage(
                  ingredient: ingredient,
                  quantityUsed: ing['amount'] is num ? ing['amount'].toDouble() : 0.0,
                ));
              }
            }
          }
          
          // แปลงขั้นตอนการทำ
          List<String> instructions = [];
  
if (recipeData['instructions'] != null) {
 
}

          
        if (recipeData['analyzedInstructions'] != null && 
    recipeData['analyzedInstructions'] is List && 
    (recipeData['analyzedInstructions'] as List).isNotEmpty) {
  
  for (var instruction in recipeData['analyzedInstructions']) {
    if (instruction != null && instruction['steps'] != null && instruction['steps'] is List) {
      for (var step in instruction['steps']) {
        if (step != null && step['step'] != null) {
          instructions.add(step['step'].toString());
         
        }
      }
    }
  }
  
 
} 
else if (recipeData['instructions'] != null) {
 
  
  if (recipeData['instructions'] is String) {
    // ถ้าเป็น string อาจมีขั้นตอนแยกด้วย \n หรือ .
    String instructionText = recipeData['instructions'].toString();
    List<String> parts = [];
    
    // ลองแยกด้วย \n ก่อน
    if (instructionText.contains('\n')) {
      parts = instructionText.split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } 
    // ถ้าไม่มี \n ลองแยกด้วยประโยค
    else if (instructionText.contains('. ')) {
      parts = instructionText.split('. ')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .map((s) => s.endsWith('.') ? s : '$s.')
          .toList();
    } 
    // ถ้าไม่สามารถแยกได้ ใช้ทั้งประโยคเลย
    else {
      parts = [instructionText];
    }
    
    instructions = parts;
    print("📝 Extracted ${instructions.length} steps from simple instructions");
  } 
  else if (recipeData['instructions'] is List) {
    instructions = (recipeData['instructions'] as List)
      .map((instruction) => instruction.toString())
      .toList();
    print("📝 Found ${instructions.length} steps from instructions list");
  }
}

// หากไม่พบข้อมูลขั้นตอนการทำเลย ให้สร้างขั้นตอนพื้นฐาน
if (instructions.isEmpty && recipeData['summary'] != null) {
  String summary = recipeData['summary'].toString();
  instructions = ["This recipe doesn't include detailed instructions.", 
                 "You can try following these general steps:",
                 "1. Prepare all ingredients as listed",
                 "2. Cook according to common methods for this type of dish",
                 "3. Combine ingredients and serve",
                 "\nRecipe summary: ${summary.replaceAll(RegExp(r'<[^>]*>'), '').substring(0, summary.length > 200 ? 200 : summary.length)}..."];
  print("📝 Using fallback instructions");
}
          
          // ดึงข้อมูลโภชนาการ
          double protein = 0.0, fat = 0.0, carbs = 0.0;
          int calories = 0;
          
          if (recipeData['nutrition'] != null) {
            if (recipeData['nutrition'] is Map) {
              if (recipeData['nutrition']['nutrients'] is List) {
                // กรณีรูปแบบ nutrition: {nutrients: [{name: "Protein", amount: 10}, ...]}
                for (var nutrient in recipeData['nutrition']['nutrients']) {
                  if (nutrient['name'] == 'Protein') {
                    protein = nutrient['amount'] is num ? nutrient['amount'].toDouble() : 0.0;
                  } else if (nutrient['name'] == 'Fat') {
                    fat = nutrient['amount'] is num ? nutrient['amount'].toDouble() : 0.0;
                  } else if (nutrient['name'] == 'Carbohydrates') {
                    carbs = nutrient['amount'] is num ? nutrient['amount'].toDouble() : 0.0;
                  } else if (nutrient['name'] == 'Calories') {
                    calories = nutrient['amount'] is num ? nutrient['amount'].toInt() : 0;
                  }
                }
              } else {
                // กรณีรูปแบบ nutrition: {protein: 10, fat: 5, ...}
                protein = recipeData['nutrition']['protein'] is num ? recipeData['nutrition']['protein'].toDouble() : 0.0;
                fat = recipeData['nutrition']['fat'] is num ? recipeData['nutrition']['fat'].toDouble() : 0.0;
                carbs = recipeData['nutrition']['carbs'] is num ? recipeData['nutrition']['carbs'].toDouble() : 0.0;
                calories = recipeData['nutrition']['calories'] is num ? recipeData['nutrition']['calories'].toInt() : 0;
              }
            }
          }
          
          // อัพเดตข้อมูลสูตรอาหาร
          setState(() {
            currentRecipe = Recipe(
              recipeId: currentRecipe.recipeId,
              recipeName: recipeData['title'] ?? currentRecipe.recipeName,
              description: recipeData['summary'] ?? currentRecipe.description,
              ingredients: ingredients.isNotEmpty ? ingredients : currentRecipe.ingredients,
              instructions: instructions.isNotEmpty ? instructions : currentRecipe.instructions,
              preparationTime: recipeData['preparationMinutes'] ?? currentRecipe.preparationTime,
              cookingTime: recipeData['cookingMinutes'] ?? currentRecipe.cookingTime,
              servings: recipeData['servings'] ?? currentRecipe.servings,
              category: currentRecipe.category,
              imageUrl: recipeData['image'] ?? currentRecipe.imageUrl,
              Protein: protein > 0 ? protein : currentRecipe.Protein,
              Fat: fat > 0 ? fat : currentRecipe.Fat,
              Carbo: carbs > 0 ? carbs : currentRecipe.Carbo,
              Kcal: calories > 0 ? calories : currentRecipe.Kcal,
              isFavorite: currentRecipe.isFavorite,
              recipeDocId: currentRecipeDocId,
              createdBy: currentRecipe.createdBy,
            );
          });
          print("✅ Recipe updated from API successfully");
          
          // กรณีอัพเดตจาก API สำเร็จแล้ว ไม่จำเป็นต้องโหลดจาก Firebase อีก
          return;
        }
      } catch (e) {
        print("⚠️ Error fetching from API, will try Firebase: $e");
      }
    }
    
    // 2. ถ้าไม่สามารถโหลดจาก API ได้ ลองดูใน Firebase
    try {
      // ลองโหลดข้อมูลจาก userRecipe collection โดยใช้ recipeDocId
      var recipeDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userRecipe')
        .doc(currentRecipeDocId)
        .get();
        
      if (recipeDoc.exists) {
        print("✅ Found recipe in userRecipe collection");
        _refreshRecipeData(currentRecipeDocId);
        return;
      }
      
      // ลองค้นหาด้วย recipeId
      final userRecipeSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userRecipe')
        .where('recipeId', isEqualTo: currentRecipe.recipeId)
        .limit(1)
        .get();
        
      if (userRecipeSnapshot.docs.isNotEmpty) {
        print("✅ Found recipe by recipeId in user's collection");
        _refreshRecipeData(userRecipeSnapshot.docs.first.id);
        return;
      }
    } catch (e) {
      print("⚠️ Error searching in Firebase: $e");
    }
    
    print("❌ Could not find full recipe data");
    
  } catch (e) {
    print("❌ Error in _loadFullRecipeData: $e");
  }
}

  void fetchUserIngredients() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userIngredients')
          .get();

      if (snapshot.docs.isNotEmpty) {
        print('Raw data structure of first user ingredient:');
        print(snapshot.docs.first.data());
      }

      List<Map<String, dynamic>> ingredients = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();

        // ดึงข้อมูลตามโครงสร้างที่แท้จริงของ userIngredients
        if (data.containsKey('ingredientsName')) {
          String ingredientName = data['ingredientsName'] ?? '';
          String unit = data['unit'] ?? '';
          double quantity = (data['quantity'] is num)
              ? (data['quantity'] as num).toDouble()
              : 0.0;

          if (ingredientName.isNotEmpty) {
            ingredients.add({
              'ingredient': {
                'ingredientsName': ingredientName,
                'unit': unit,
              },
              'quantity': quantity,
            });
           
          } else {
            print('Warning: Document ${doc.id} has invalid data structure');
          }
        } else {
          print('Warning: Document ${doc.id} has invalid data structure');
        }
      }

      setState(() {
        userIngredients = ingredients;
      });

      print('Fetched user ingredients: ${ingredients.length} items');
      if (ingredients.isNotEmpty) {
        print('First item structure: ${ingredients.first}');
      }
    } catch (e) {
      print('Error fetching user ingredients: $e');
    }
  }

  Future<void> _refreshRecipeData(String recipeDocId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userRecipe')
          .doc(recipeDocId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final List<IngredientUsage> ingredients = [];

        if (data['ingredients'] != null) {
          for (var ing in data['ingredients']) {
            final ingredient = Ingredient(
              ingredientsName: ing['name'],
              unit: ing['unit'],
              imageUrl: 'assets/images/default_ing.png',
              ingredientId: '0',
              userId: user.uid,
              category: 'Fruits',
              storage: 'Fridge',
              quantity: 0,
              minQuantity: 0,
              expirationDate: DateTime.now(),
              source: 'Supermarket',
              kcal: 0,
            );

            ingredients.add(IngredientUsage(
              ingredient: ingredient,
              quantityUsed: ing['amount'].toDouble(),
            ));
          }
        }

        setState(() {
          currentRecipe = Recipe(
            recipeId: data['recipeId'] ?? 0,
            recipeName: data['recipeName'] ?? '',
            description: data['description'] ?? '',
            ingredients: ingredients,
            instructions: List<String>.from(data['instructions'] ?? []),
            preparationTime: data['preparationTime'] ?? 0,
            cookingTime: data['cookingTime'] ?? 0,
            servings: data['servings'] ?? 1,
            category: data['category'] ?? '',
            imageUrl: data['imageUrl'] ?? '',
            Protein: (data['Protein'] is num)
                ? (data['Protein'] as num).toDouble()
                : 0.0,
            Fat: (data['Fat'] is num) ? (data['Fat'] as num).toDouble() : 0.0,
            Carbo: (data['Carbo'] is num)
                ? (data['Carbo'] as num).toDouble()
                : 0.0,
            Kcal: data['Kcal'] ?? 0,
            isFavorite: data['isFavorite'] ?? false,
            createdBy: data['createdBy'],
            recipeDocId: doc.id,
          );
        });

        print("✅ Recipe data refreshed successfully");
      }
    } catch (e) {
      print("❌ Error refreshing recipe data: $e");
    }
  }

  

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(
            children: [
              Positioned(
                child: currentRecipe.imageUrl.isEmpty
                    ? Container(
                        height: MediaQuery.of(context).size.width,
                        color: Colors.grey[200],
                        child: Center(
                          child: Image.asset(
                            'assets/images/placeholder.png',
                            width: 300,
                            height: 250,
                          ),
                        ),
                      )
                    : Container(
                        height: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: _getImageProvider(currentRecipe.imageUrl),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {
                              print('Error loading image: $exception');
                            },
                          ),
                        ),
                      ),
              ),
              Positioned(
                top: 55,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (BuildContext context) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit,
                                        color: Color(0xFF78d454)),
                                    title: const Text('Edit Recipe'),
                                    onTap: () async {
                                      Navigator.pop(
                                          context); // ปิด bottom sheet

                                      final user =
                                          FirebaseAuth.instance.currentUser;
                                      if (user == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  "Please login to edit recipes"),
                                              backgroundColor:
                                                  Colors.redAccent),
                                        );
                                        return;
                                      }

                                      final bool isUserRecipe =
                                          user.uid == currentRecipe.createdBy;
                                      
                                       if (!isUserRecipe) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("You can only edit recipes that you created"),
                                            backgroundColor: Colors.redAccent
                                          ),
                                        );
                                        return;
                                      }

                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditRecipeScreen(
                                            isEditingOwnRecipe: isUserRecipe,
                                            initialData: {
                                              'docId': currentRecipeDocId,
                                              'recipeId':
                                                  currentRecipe.recipeId,
                                              'recipeName':
                                                  currentRecipe.recipeName,
                                              'description':
                                                  currentRecipe.description,
                                              'imageUrl':
                                                  currentRecipe.imageUrl,
                                              'category':
                                                  currentRecipe.category,
                                              'servings':
                                                  currentRecipe.servings,
                                              'preparationTime':
                                                  currentRecipe.preparationTime,
                                              'cookingTime':
                                                  currentRecipe.cookingTime,
                                              'ingredients':
                                                  currentRecipe.ingredients
                                                      .map((ingredient) => {
                                                            'name': ingredient
                                                                .ingredient
                                                                .ingredientsName,
                                                            'amount': ingredient
                                                                .quantityUsed,
                                                            'unit': ingredient
                                                                .ingredient
                                                                .unit,
                                                          })
                                                      .toList(),
                                              'instructions':
                                                  currentRecipe.instructions,
                                              'Protein': currentRecipe.Protein,
                                              'Fat': currentRecipe.Fat,
                                              'Carbo': currentRecipe.Carbo,
                                              'Kcal': currentRecipe.Kcal,
                                              'originalId':
                                                  currentRecipe.recipeId,
                                            },
                                            onRecipeCreated: () {
                                              // Callback เมื่อสร้างสูตรใหม่เสร็จสิ้น
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(isUserRecipe
                                                      ? "Recipe updated successfully!"
                                                      : "Recipe added to your collection!"),
                                                  backgroundColor:
                                                      const Color(0xFF78d454),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );

                                      if (result != null &&
                                          result['updated'] == true) {
                                        print(
                                            "Recipe updated, refreshing data...");
                                        _refreshRecipeData(currentRecipeDocId);
                                      }
                                    },
                                  ),
                                 
                                  ListTile(
                                    leading: const Icon(Icons.delete_forever,
                                        color: Colors.redAccent),
                                    title: const Text('Delete Recipe'),
                                    onTap: () {
                                      Navigator.pop(context);

                                      final user =
                                          FirebaseAuth.instance.currentUser;
                                      if (user != null &&
                                          currentRecipe.createdBy == user.uid) {
                                        // แสดง Dialog ยืนยันการลบ
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title:
                                                  const Text("Delete Recipe"),
                                              content: const Text(
                                                  "Are you sure you want to delete this recipe?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(
                                                        context); // ปิด Dialog
                                                  },
                                                  child: const Text("Cancel",
                                                      style: TextStyle(
                                                          color: Colors.grey)),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    Navigator.pop(
                                                        context); // ปิด Dialog

                                                    final scaffoldContext =
                                                        ScaffoldMessenger.of(
                                                            context); // เก็บ context ของ ScaffoldMessenger
                                                    final navigationContext =
                                                        Navigator.of(
                                                            context); // เก็บ context ของ Navigator

                                                    // แสดง loading indicator
                                                    showDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      builder: (BuildContext
                                                          context) {
                                                        return const Center(
                                                            child:
                                                                CircularProgressIndicator());
                                                      },
                                                    );

                                                    try {
                                                      final user = FirebaseAuth
                                                          .instance.currentUser;
                                                      if (user != null) {
                                                        // ลบ recipe จาก Firebase
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection('users')
                                                            .doc(user.uid)
                                                            .collection(
                                                                'userRecipe')
                                                            .doc(
                                                                currentRecipeDocId)
                                                            .delete();

                                                        print(
                                                            "✅ Recipe deleted successfully with ID: $currentRecipeDocId");

                                                        // ปิด loading dialog โดยใช้ context ปัจจุบัน
                                                        if (context.mounted) {
                                                          Navigator.pop(
                                                              context);
                                                        }

                                                        // แสดง SnackBar และกลับไปหน้าหลัก โดยใช้ context ที่เก็บไว้
                                                        scaffoldContext
                                                            .showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                                "Recipe deleted successfully!"),
                                                            backgroundColor:
                                                                Colors
                                                                    .redAccent,
                                                            duration: Duration(
                                                                seconds: 2),
                                                          ),
                                                        );

                                                        navigationContext.pop({
        'deleted': true,
        'recipeId': currentRecipe.recipeId,
        'recipeDocId': currentRecipeDocId
      });
    }
                                                    } catch (e) {
                                                      // ปิด loading dialog ถ้า context ยังใช้ได้
                                                      if (context.mounted) {
                                                        Navigator.pop(context);

                                                        print(
                                                            "❌ Error deleting recipe: $e");
                                                        // แสดงข้อความเมื่อเกิดข้อผิดพลาด
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                "Error deleting recipe: $e"),
                                                            backgroundColor:
                                                                Colors
                                                                    .redAccent,
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  child: const Text("Delete",
                                                      style: TextStyle(
                                                          color: Colors
                                                              .redAccent)),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                "You do not have permission to delete this recipe"),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                        ),
                        child: const Icon(Icons.more_horiz),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: MediaQuery.of(context).size.width - 30,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      )),
                ),
              )
            ],
          ),
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Recipe name
          const SizedBox(height: 10),
         Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(  // เพิ่ม Flexible เพื่อจำกัดพื้นที่
        child: Text(
          currentRecipe.recipeName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          maxLines: 1,
        ),
      ),
      const SizedBox(width: 10),  // เพิ่มระยะห่าง
      // Time cooking
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF78d454),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "${currentRecipe.totalCookingTime()} mins",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    ],
  ),
),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Protein',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Fat',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Carbo',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Calories',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Protein Column
      Column(
        children: [
          Image.asset('assets/images/protein.png', width: 20, height: 20),
          const SizedBox(height: 4),
          Text('${currentRecipe.Protein} g',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
      
      // Fat Column
      Column(
        children: [
          Image.asset('assets/images/fat.png', width: 20, height: 20),
          const SizedBox(height: 4),
          Text('${currentRecipe.Fat} g',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
      
      // Carbo Column
      Column(
        children: [
          Image.asset('assets/images/carbo.png', width: 23, height: 20),
          const SizedBox(height: 4),
          Text('${currentRecipe.Carbo} g',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
      
      
      // Calories Column
   Column(
  children: [
    Image.asset('assets/images/kcal.png', width: 23, height: 17),
    const SizedBox(height: 4),
    Text('${(currentRecipe.Kcal / currentRecipe.servings * currentNumber).round()} Kcal',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
    Text('for $currentNumber ${currentNumber > 1 ? "servings" : "serving"}',
        style:  TextStyle(fontSize: 12, color: Colors.grey[600])),
  ],
),
    ],
  ),
),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 10),
                          Image.asset(
                            'assets/images/group.png',
                            width: 35,
                            height: 35,
                          ),
                          const SizedBox(
                              width: 10), // เว้นระยะระหว่างไอคอนและข้อความ
                          const Text(
                            "Persons",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87, // สีข้อความ
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (currentNumber > 1) {
                                setState(() {
                                  currentNumber--;
                                });
                              }
                            },
                            icon: const Icon(Icons.remove),
                            iconSize: 20,
                            color: Colors.redAccent,
                          ),
                          Text(
                            "$currentNumber",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                currentNumber++;
                              });
                            },
                            icon: const Icon(Icons.add),
                            iconSize: 20,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          //ปุ่ม ingredient/step

          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(
                maxWidth: 300,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        showIngredients = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: showIngredients
                            ? Color(0xFF78d454)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Ingredients',
                        style: TextStyle(
                          color:
                              showIngredients ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        showIngredients = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: !showIngredients
                            ? Color(0xFF78d454)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Instructions',
                        style: TextStyle(
                          color: !showIngredients
                              ? Colors.white
                              : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: showIngredients
                ? RecipeIngredientWidget(
                    ingredients: currentRecipe.ingredients,
                    recipe: currentRecipe,
                    currentNumber: currentNumber,
                    userIngredients: userIngredients,
                  )
                : InstructionsWidget(
                    instructions:
                        currentRecipe.instructions, // แสดง instructions
                  ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 10),
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () async {
                      // 1. Check for missing ingredients
                      List<Map<String, dynamic>> missingIngredients = [];

                      // Calculate the adjusted quantities based on currentNumber (serving adjustment)
                      for (var recipeIngredient in currentRecipe.ingredients) {
                        // Calculate the required amount adjusted for servings
                        double requiredAmount = recipeIngredient.quantityUsed *
                            (currentNumber / currentRecipe.servings);
                        String ingredientName =
                            recipeIngredient.ingredient.ingredientsName;
                        String unit = recipeIngredient.ingredient.unit;

                        // Check if user has this ingredient
                        bool isFound = false;
                        double availableAmount = 0;

                        for (var userIngredient in userIngredients) {
                          if (userIngredient['ingredient'] != null &&
                              userIngredient['ingredient']['ingredientsName'] ==
                                  ingredientName) {
                            isFound = true;
                            availableAmount = userIngredient['quantity'] ?? 0;
                            break;
                          }
                        }

                        // If ingredient not found or quantity insufficient, add to missing list
                        if (!isFound || availableAmount < requiredAmount) {
                          missingIngredients.add({
                            'ingredientName': ingredientName,
                            'requiredAmount': requiredAmount,
                            'unit': unit,
                            'availableAmount': isFound ? availableAmount : 0,
                          });
                        }
                      }

                      if (missingIngredients.isNotEmpty) {
                        bool shouldProceed = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text(
                                    "Missing Ingredients",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent),
                                  ),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                            "You don't have enough of these ingredients:"),
                                        const SizedBox(height: 14),
                                        ...missingIngredients.map((ingredient) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 5),
                                            child: Text(
                                              "• ${ingredient['ingredientName']} ${ingredient['requiredAmount'].toStringAsFixed(1)} ${ingredient['unit']}",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          );
                                        }).toList(),
                                        const SizedBox(height: 10),
                                        const Text(
                                            "Do you still want to record your consumption ?"),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text("Cancel",
                                          style: TextStyle(color: Colors.grey)),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text("Eat Anyway",
                                          style:
                                              TextStyle(color: Colors.green)),
                                    ),
                                  ],
                                );
                              },
                            ) ??
                            false;

                        if (!shouldProceed) {
                          return; // Exit if user cancelled
                        }
                      }

                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("Please login to record consumption"),
                              backgroundColor: Colors.redAccent),
                        );
                        return;
                      }

                      try {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const Center(
                                child: CircularProgressIndicator());
                          },
                        );

                        final now = DateTime.now();
                        final dateStr =
                            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

                        double adjustedKcal = currentRecipe.Kcal *
                            (currentNumber / currentRecipe.servings);

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('calorieConsumption')
                            .add({
                          'date': now,
                          'dateStr': dateStr,
                          'recipeId': currentRecipe.recipeId.toString(),
                          'recipeName': currentRecipe.recipeName,
                          'kcal': adjustedKcal.round(),
                          'protein': currentRecipe.Protein *
                              (currentNumber / currentRecipe.servings),
                          'fat': currentRecipe.Fat *
                              (currentNumber / currentRecipe.servings),
                          'carbo': currentRecipe.Carbo *
                              (currentNumber / currentRecipe.servings),
                          'mealType': "",
                          'note': "No note",
                          'quantity': currentNumber,
                          'unit': "servings",
                        });

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('eatingHistory')
                            .add({
                          'date': now,
                          'dateStr': dateStr,
                          'recipeId': currentRecipe.recipeId.toString(),
                          'recipeName': currentRecipe.recipeName,
                          'imageUrl': currentRecipe.imageUrl,
                          'kcal': adjustedKcal.round(),
                          'protein': currentRecipe.Protein *
                              (currentNumber / currentRecipe.servings),
                          'fat': currentRecipe.Fat *
                              (currentNumber / currentRecipe.servings),
                          'carbo': currentRecipe.Carbo *
                              (currentNumber / currentRecipe.servings),
                          'mealType': "",
                          'servings': currentNumber,
                        });

                        for (var recipeIngredient
                            in currentRecipe.ingredients) {
                          String ingredientName =
                              recipeIngredient.ingredient.ingredientsName;
                          double requiredAmount =
                              recipeIngredient.quantityUsed *
                                  (currentNumber / currentRecipe.servings);

                          for (var userIngredient in userIngredients) {
                            if (userIngredient['ingredient'] != null &&
                                userIngredient['ingredient']
                                        ['ingredientsName'] ==
                                    ingredientName) {
                              double availableAmount =
                                  userIngredient['quantity'] ?? 0;

                              if (availableAmount >= requiredAmount) {
                                String? docId;
                                try {
                                  final snapshot = await FirebaseFirestore
                                      .instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('userIngredients')
                                      .where('ingredientsName',
                                          isEqualTo: ingredientName)
                                      .get();

                                  if (snapshot.docs.isNotEmpty) {
                                    docId = snapshot.docs.first.id;

                                    // Update the quantity
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('userIngredients')
                                        .doc(docId)
                                        .update({
                                      'quantity':
                                          availableAmount - requiredAmount
                                    });
                                  }
                                } catch (e) {
                                  print(
                                      "Error updating ingredient $ingredientName: $e");
                                }
                              }
                              break;
                            }
                          }
                        }

                        if (context.mounted) {
                          Navigator.pop(context);

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("Consumption recorded successfully!"),
                              backgroundColor: Color(0xFF78d454),
                            ),
                          );
                        }
                      } catch (e) {
                        // Close loading dialog if there's an error
                        if (context.mounted) {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error recording consumption: $e"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.restaurant_outlined,
                      color: Colors.black,
                      size: 25,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 10, right: 20),
                child: Container(
                  height: 60,
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      // Show meal planner bottom sheet
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (BuildContext context) {
                          DateTime selectedDate = DateTime.now();
                          String selectedMeal = "Breakfast";
                          int servingCount = currentNumber;

                          return StatefulBuilder(
                            builder: (context, setState) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height * 0.7,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Title
                                    const Center(
                                      child: Text(
                                        "Add to Meal Plan",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Recipe Card
                                    Card(
                                      elevation: 0,
                                      color: Colors.grey[100],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            // Recipe Image
                                            Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                image: DecorationImage(
                                                  image: currentRecipe
                                                          .imageUrl.isNotEmpty
                                                      ? _getImageProvider(
                                                          currentRecipe
                                                              .imageUrl)
                                                      : const AssetImage(
                                                          'assets/images/placeholder.png'),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Recipe Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    currentRecipe.recipeName,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "${currentRecipe.totalCookingTime()} mins • ${currentRecipe.Kcal} kcal",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Servings Selection
                                    const Text(
                                      "Servings",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Number of servings",
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  if (servingCount > 1) {
                                                    setState(() {
                                                      servingCount--;
                                                    });
                                                  }
                                                },
                                                icon: const Icon(Icons
                                                    .remove_circle_outline),
                                                color: Colors.grey[700],
                                              ),
                                              Text(
                                                "$servingCount",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    servingCount++;
                                                  });
                                                },
                                                icon: const Icon(
                                                    Icons.add_circle_outline),
                                                color: Color(0xFF78d454),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 20),
                                    // Meal Selection
                                    const Text(
                                      "Choose Meal",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 10,
                                      children: [
                                        _buildMealChip(
                                            "Breakfast", selectedMeal, (meal) {
                                          setState(() => selectedMeal = meal);
                                        }),
                                        _buildMealChip("Lunch", selectedMeal,
                                            (meal) {
                                          setState(() => selectedMeal = meal);
                                        }),
                                        _buildMealChip("Dinner", selectedMeal,
                                            (meal) {
                                          setState(() => selectedMeal = meal);
                                        }),
                                        _buildMealChip("Snack", selectedMeal,
                                            (meal) {
                                          setState(() => selectedMeal = meal);
                                        }),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Date Selection
                                    const Text(
                                      "Choose Date",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    InkWell(
                                      onTap: () async {
                                        final DateTime? picked =
                                            await showDatePicker(
                                          context: context,
                                          initialDate: selectedDate,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now()
                                              .add(const Duration(days: 365)),
                                          builder: (context, child) {
                                            return Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme:
                                                    const ColorScheme.light(
                                                  primary: Color(0xFF78d454),
                                                  onPrimary: Colors.white,
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (picked != null) {
                                          setState(() {
                                            selectedDate = picked;
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey[300]!),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                            const Icon(Icons.calendar_today,
                                                size: 20),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 30),

                                    // Buttons
                                    Row(
                                      children: [
                                        // Cancel Button
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 15),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              side: BorderSide(
                                                  color: Colors.grey[300]!),
                                            ),
                                            child: const Text(
                                              "Cancel",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        // Add Button
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              // Convert meal type to lowercase for database consistency
                                              String mealTypeKey =
                                                  selectedMeal.toLowerCase();

                                              // Show loading indicator
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder:
                                                    (BuildContext context) {
                                                  return const Center(
                                                      child:
                                                          CircularProgressIndicator());
                                                },
                                              );

                                              try {
                                                // Use the MealPlanService to add recipe to meal plan
                                                final mealPlanService =
                                                    MealPlanService();
                                                final success =
                                                    await mealPlanService
                                                        .addRecipeToMealPlan(
                                                  recipe: currentRecipe,
                                                  date: selectedDate,
                                                  mealType: mealTypeKey,
                                                  servings: servingCount,
                                                );

                                                // Close loading dialog
                                                Navigator.pop(context);

                                                // Show success message and close bottom sheet
                                                if (success) {
                                                  Navigator.pop(
                                                      context); // Close bottom sheet

                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          "Added to Meal Plan successfully!"),
                                                      backgroundColor:
                                                          Color(0xFF78d454),
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          "Failed to add to Meal Plan. Please try again."),
                                                      backgroundColor:
                                                          Colors.redAccent,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                // Close loading dialog
                                                Navigator.pop(context);

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text("Error: $e"),
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                  ),
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 15),
                                              backgroundColor:
                                                  const Color(0xFF78d454),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text(
                                              "Add",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Add to Meal Plan",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        ]),
      ),
    );
  }
}
