import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/screens/recipe/edit.recipe.dart';
import 'package:food_project/widgets/instruction_widget.dart';
import 'package:food_project/widgets/recipe_ingredient_widget.dart';

class RecipeDetail extends StatefulWidget {
 final Recipe recipe; 
  final int recipeId;
  final String recipeDocId; 

  const RecipeDetail({super.key,  required this.recipe, 
    required this.recipeId,
    required this.recipeDocId,});

  @override
  State<RecipeDetail> createState() => _RecipeDetailState();
}

class _RecipeDetailState extends State<RecipeDetail> {
  int currentNumber = 1;
  bool showIngredients = true;
  List<Map<String, dynamic>> userIngredients = [];
  List<Recipe> recipeList = [];
  late Recipe currentRecipe;
   late String currentRecipeDocId;

  // Toggle Favorite button
  bool toggleIsFavorated(bool isFavorited) {
    return !isFavorited;
  }

  Widget _buildMealChip(String meal, String selectedMeal, Function(String) onSelected) {
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
        double quantity = (data['quantity'] is num) ? (data['quantity'] as num).toDouble() : 0.0;
        
        if (ingredientName.isNotEmpty) {
          ingredients.add({
            'ingredient': {
              'ingredientsName': ingredientName,
              'unit': unit,
            },
            'quantity': quantity,
          });
          print('Added user ingredient: $ingredientName');
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
          Protein: (data['Protein'] is num) ? (data['Protein'] as num).toDouble() : 0.0,
          Fat: (data['Fat'] is num) ? (data['Fat'] as num).toDouble() : 0.0,
          Carbo: (data['Carbo'] is num) ? (data['Carbo'] as num).toDouble() : 0.0,
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
  child: currentRecipe.imageUrl.isEmpty ? 
    Container(
      height: MediaQuery.of(context).size.width,
      color: Colors.grey[200],
      child: Center(
        child: Image.asset(
          'assets/images/placeholder.png',
          width: 300,
          height: 250,
        ),
      ),
    ) : 
    Container(
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
                                      leading: const Icon(Icons.edit, color: Color(0xFF78d454)),
                                      title: const Text('Edit Recipe'),
                                      onTap: () async {
                                        Navigator.pop(context); // ปิด bottom sheet
                                        
                                        final user = FirebaseAuth.instance.currentUser;
                                        if (user == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Please login to edit recipes"), backgroundColor: Colors.redAccent),
                                          );
                                          return;
                                        }
                                        
                                        final bool isUserRecipe = user.uid == currentRecipe.createdBy;
                                        
                                       final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditRecipeScreen(
                                                isEditingOwnRecipe: isUserRecipe,
                                                initialData: {
                                                  'docId': currentRecipeDocId,    
                                                  'recipeId': currentRecipe.recipeId,
                                                  'recipeName': currentRecipe.recipeName,
                                                  'description': currentRecipe.description,
                                                  'imageUrl': currentRecipe.imageUrl,
                                                  'category': currentRecipe.category,
                                                  'servings': currentRecipe.servings,
                                                  'preparationTime': currentRecipe.preparationTime, 
                                                  'cookingTime': currentRecipe.cookingTime,
                                                  'ingredients': currentRecipe.ingredients.map((ingredient) => {
                                                    'name': ingredient.ingredient.ingredientsName,
                                                    'amount': ingredient.quantityUsed,
                                                    'unit': ingredient.ingredient.unit,
                                                  }).toList(),
                                                  'instructions': currentRecipe.instructions,
                                                  'Protein': currentRecipe.Protein,
                                                  'Fat': currentRecipe.Fat,
                                                  'Carbo': currentRecipe.Carbo,
                                                  'Kcal': currentRecipe.Kcal,
                                                  'originalId': currentRecipe.recipeId,
                                                },
                                                onRecipeCreated: () {
                                                  // Callback เมื่อสร้างสูตรใหม่เสร็จสิ้น
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(isUserRecipe ? "Recipe updated successfully!" : "Recipe added to your collection!"),
                                                      backgroundColor: const Color(0xFF78d454),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          );

                                          if (result != null && result['updated'] == true) {
                                            print("Recipe updated, refreshing data...");
                                            _refreshRecipeData(currentRecipeDocId);
                                          }
                                                                                },
                                    ),
                                  ListTile(
                                      leading: const Icon(Icons.no_meals, color: Colors.redAccent),
                                      title: const Text('Not recommended this recipe'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        
                                        // แสดง Dialog ยืนยันการไม่แนะนำสูตรอาหาร
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text("Not Recommended this Recipe"),
                                              content: const Text("Are you sure you want to not recommend this recipe?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context); // ปิด Dialog
                                                  },
                                                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    Navigator.pop(context); // ปิด Dialog
                                                    
                                                    // บันทึกลง Firebase
                                                    final user = FirebaseAuth.instance.currentUser;
                                                    if (user != null) {
                                                      try {
                                                        
                                                        await FirebaseFirestore.instance
                                                          .collection('users')
                                                          .doc(user.uid)
                                                          .collection('notRecommendedRecipes')
                                                          .doc(currentRecipe.id.toString())
                                                          .set({
                                                            'recipeId': currentRecipe.id,
                                                            'recipeName': currentRecipe.recipeName,
                                                            'addedAt': FieldValue.serverTimestamp(),
                                                          });
                                                        
                                                        // แสดงข้อความยืนยัน
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(
                                                            content: Text("Not recommended this recipe successfully!"),
                                                            backgroundColor: Color(0xFF78d454),
                                                          ),
                                                        );
                                                      } catch (e) {
                                                        // แสดงข้อความเมื่อเกิดข้อผิดพลาด
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text("เกิดข้อผิดพลาด: $e"),
                                                            backgroundColor: Colors.redAccent,
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  child: const Text("Confirm", style: TextStyle(color: Colors.redAccent)),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ListTile(
  leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
  title: const Text('Delete Recipe'),
  onTap: () {
    Navigator.pop(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && currentRecipe.createdBy == user.uid) {
      // แสดง Dialog ยืนยันการลบ
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Delete Recipe"),
            content: const Text("Are you sure you want to delete this recipe?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // ปิด Dialog
                },
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
  onPressed: () async {
  Navigator.pop(context); // ปิด Dialog
  
  final scaffoldContext = ScaffoldMessenger.of(context); // เก็บ context ของ ScaffoldMessenger
  final navigationContext = Navigator.of(context); // เก็บ context ของ Navigator
  
  // แสดง loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Center(child: CircularProgressIndicator());
    },
  );
  
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // ลบ recipe จาก Firebase
      await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userRecipe')
        .doc(currentRecipeDocId)
        .delete();
      
      print("✅ Recipe deleted successfully with ID: $currentRecipeDocId");
      
      // ปิด loading dialog โดยใช้ context ปัจจุบัน
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      // แสดง SnackBar และกลับไปหน้าหลัก โดยใช้ context ที่เก็บไว้
      scaffoldContext.showSnackBar(
        const SnackBar(
          content: Text("Recipe deleted successfully!"),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      
      // กลับไปยังหน้าก่อนหน้า
      navigationContext.pop(true); // ส่งค่า true กลับไปเพื่อบอกว่ามีการลบ
    }
  } catch (e) {
    // ปิด loading dialog ถ้า context ยังใช้ได้
    if (context.mounted) {
      Navigator.pop(context);
      
      print("❌ Error deleting recipe: $e");
      // แสดงข้อความเมื่อเกิดข้อผิดพลาด
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting recipe: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
},
  child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ํYou do not have permission to delete this recipe"),
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
                Text(
                  currentRecipe.recipeName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Time cooking
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            padding: const EdgeInsets.only(left: 20, right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/images/protein.png',
                            width: 20, height: 20),
                        const SizedBox(width: 2),
                        Text('${currentRecipe.Protein} g',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 45),
                        Image.asset('assets/images/fat.png',
                            width: 20, height: 20),
                        const SizedBox(width: 2),
                        Text('${currentRecipe.Fat} g',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 35),
                        Image.asset('assets/images/carbo.png',
                            width: 23, height: 20),
                        const SizedBox(width: 2),
                        Text('${currentRecipe.Carbo} g',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 50),
                        Image.asset('assets/images/kcal.png',
                            width: 23, height: 17),
                        const SizedBox(width: 1),
                        Text('${currentRecipe.Kcal} Kcal',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
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
            padding: const EdgeInsets.only(left: 20 , bottom: 10),
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
                      onPressed: () {
                        
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
            padding: const EdgeInsets.only(bottom: 10 , right: 20),
          child: Container(
            height: 60,
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      
                    ),
                    child: ElevatedButton(
  onPressed: () {
    // Show meal planner bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        
        DateTime selectedDate = DateTime.now();
        String selectedMeal = "Breakfast"; 
        
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
             
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // หัวข้อ
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
                          // รูปภาพอาหาร
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: currentRecipe.imageUrl.isNotEmpty
                                    ? _getImageProvider(currentRecipe.imageUrl)
                                    : const AssetImage('assets/images/placeholder.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // ข้อมูลอาหาร
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentRecipe.recipeName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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
                  
                  // เลือกมื้ออาหาร
                  const Text(
                    "Choose Meal",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ตัวเลือกมื้ออาหาร
                  Wrap(
                    spacing: 10,
                    children: [
                      _buildMealChip("Breakfast", selectedMeal, (meal) {
                        setState(() => selectedMeal = meal);
                      }),
                      _buildMealChip("Lunch", selectedMeal, (meal) {
                        setState(() => selectedMeal = meal);
                      }),
                      _buildMealChip("Dinner", selectedMeal, (meal) {
                        setState(() => selectedMeal = meal);
                      }),
                      _buildMealChip("Snack", selectedMeal, (meal) {
                        setState(() => selectedMeal = meal);
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // เลือกวันที่
                  const Text(
                    "Choose Date",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ปุ่มเลือกวันที่
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // ปุ่ม Cancel และ Add
                  Row(
                    children: [
                      // ปุ่ม Cancel
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
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
                      // ปุ่ม Add
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // เพิ่มโค้ดสำหรับบันทึกลงแผนมื้ออาหารที่นี่
                            // เช่น บันทึกลง Firebase
                            print("Save to meal plan: ${currentRecipe.recipeName} for $selectedMeal on ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}");
                            
                            // แสดงข้อความยืนยัน
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Added to Meal Plan successfully!"),
                                backgroundColor: Color(0xFF78d454),
                              ),
                            );
                            
                            // ปิด bottom sheet
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: const Color(0xFF78d454),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
