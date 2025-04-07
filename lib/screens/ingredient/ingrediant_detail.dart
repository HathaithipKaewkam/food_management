import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/screens/ingredient/add_ingredient.dart';
import 'package:food_project/screens/ingredient/edit_ingredient.dart';
import 'package:food_project/screens/recipe/recipe_detail.dart';
import 'package:food_project/screens/root_screen.dart';
import 'package:food_project/services/pairing_service.dart';
import 'package:food_project/services/recipe_service.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

class IngredientDetailPage extends StatefulWidget {
  final Ingredient ingredient;
  final List<Map<String, String>> recipes;
  

  const IngredientDetailPage(
      {super.key, required this.ingredient, required this.recipes});

  @override
  _IngredientDetailPageState createState() => _IngredientDetailPageState();
}

class _IngredientDetailPageState extends State<IngredientDetailPage> {
  List<Map<String, String>> pairingIngredients = [];
  List<Map<String, dynamic>> recipes = [];
  Map<String, dynamic> userIngredientsMap = {}; 
  bool isLoading = true;
  final RecipeService _recipeService = RecipeService();
  bool isLoadingPairing = true;
bool isLoadingRecipes = true;

  @override
  void initState() {
    super.initState();
     setState(() {
    isLoadingPairing = true;
    isLoadingRecipes = true;
  });
    fetchPairingIngredients();
    fetchRecipe();
    _fetchUserIngredients();
  }

  int extractIngredientCount(Map<String, dynamic> recipe, String key) {
  if (recipe[key] is int) {
    return recipe[key];
  } else if (recipe[key] is num) {
    return (recipe[key] as num).toInt();
  } else {
    return int.tryParse(recipe[key]?.toString() ?? '0') ?? 0;
  }
}

Future<void> fetchRecipe() async {
  try {
    setState(() {
      isLoadingRecipes = true;
    });
  
    String ingredientName = widget.ingredient.ingredientsName.trim();
    
    String formattedIngredient = ingredientName
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') 
        .trim();
    

    List<String> userIngredientNames = userIngredientsMap.keys.toList();
    

    if (!userIngredientNames.contains(formattedIngredient)) {
      userIngredientNames.add(formattedIngredient);
    }

    userIngredientNames = userIngredientNames.take(5).toList();

    List<Map<String, dynamic>> thaiRecipes = await _recipeService.getRecipesByCuisine(
      primaryCuisine: 'Thai',
      fallbackCuisines: [],
      limit: 5,
      includeIngredients: userIngredientNames
    );
    
    List<Map<String, dynamic>> filteredThaiRecipes = [];
    
    for (var recipe in thaiRecipes) {
      var usedIngredients = recipe['usedIngredients'] as List<dynamic>? ?? [];
      bool containsMainIngredient = false;
      
      for (var ingredient in usedIngredients) {
        String ingredientName = ingredient['name']?.toString().toLowerCase() ?? '';
        if (ingredientName.contains(formattedIngredient)) {
          containsMainIngredient = true;
          break;
        }
      }
      
      if (containsMainIngredient) {
        recipe['isThaiCuisine'] = true;
        filteredThaiRecipes.add(recipe);
      }
    }
    
    int remainingRecipes = 5 - filteredThaiRecipes.length;
    
    List<Map<String, dynamic>> otherRecipes = [];
    
    if (remainingRecipes > 0) {
      otherRecipes = await _recipeService.getRecipesWithImages(
        userIngredientNames,
        number: remainingRecipes 
      );
      
    
      List<Map<String, dynamic>> filteredOtherRecipes = [];
      
      for (var recipe in otherRecipes) {
        var usedIngredients = recipe['usedIngredients'] as List<dynamic>? ?? [];
        bool containsMainIngredient = false;
        
        for (var ingredient in usedIngredients) {
          String ingredientName = ingredient['name']?.toString().toLowerCase() ?? '';
          if (ingredientName.contains(formattedIngredient)) {
            containsMainIngredient = true;
            break;
          }
        }
        
        if (containsMainIngredient) {
          recipe['isThaiCuisine'] = (recipe['cuisine'] == 'Thai');
          
          bool isDuplicate = false;
          for (var thaiRecipe in filteredThaiRecipes) {
            if (thaiRecipe['id'] == recipe['id']) {
              isDuplicate = true;
              break;
            }
          }
          
          if (!isDuplicate) {
            filteredOtherRecipes.add(recipe);
          }
        }
      }
      
      filteredOtherRecipes = filteredOtherRecipes.take(remainingRecipes).toList();
      
      
    }

    List<Map<String, dynamic>> allRecipes = [...filteredThaiRecipes, ...otherRecipes];
    
    allRecipes.sort((a, b) {
    
      if (a['isThaiCuisine'] != b['isThaiCuisine']) {
        return a['isThaiCuisine'] == true ? -1 : 1;
      }
      
      int aMatch = extractIngredientCount(a, 'usedIngredientCount');
      int bMatch = extractIngredientCount(b, 'usedIngredientCount');
      
      return bMatch.compareTo(aMatch);
    });
    
    allRecipes = allRecipes.take(5).toList();
    
   
    
    if (mounted) {
      setState(() {
        recipes = allRecipes;
        isLoadingRecipes = false;
      });
    }
  } catch (e) {
    print("❌ Error fetching recipes: $e");
    if (mounted) {
      setState(() {
        recipes = [];
        isLoadingRecipes = false;
      });
    }
  }
}

Future<void> fetchPairingIngredients() async {
  try {
    setState(() {
      isLoadingPairing = true;
    });
    
    List<Map<String, String>> fetchedIngredients =
        await getRecipeAndPairings(widget.ingredient.ingredientsName);
    
    List<Map<String, String>> limitedIngredients = fetchedIngredients.take(5).toList();
    
    if (mounted) {
      setState(() {
        pairingIngredients = limitedIngredients;
        isLoadingPairing = false;
      });
    }
    
   
  } catch (e) {
    print("Error fetching pairing ingredients: $e");
    if (mounted) {
      setState(() {
        pairingIngredients = [];
        isLoadingPairing = false;
      });
    }
  }
}

  Future<void> checkUserIngredients() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('userIngredients')
        .get();

    print("📌 userIngredients มีทั้งหมด: ${snapshot.docs.length}");
  }

  Future<void> _fetchUserIngredients() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('userIngredients')
          .get();

      Map<String, dynamic> tempUserIngredients = {};
       for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String name = data['ingredientsName'];
      
      double quantity = data['quantity'] is int 
          ? (data['quantity'] as int).toDouble() 
          : (data['quantity'] as num).toDouble();
      
      tempUserIngredients[name] = quantity;
    }

      setState(() {
        userIngredientsMap = tempUserIngredients;
      });

      print("✅ Loaded user ingredients: ${userIngredientsMap.length}");
    } catch (e) {
      print("❌ Error fetching user ingredients: $e");
    }
  }

  Future<List<Ingredient>> fetchIngredients() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('userIngredients')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Ingredient.fromJson(data);
    }).toList();
  }


// แก้ไขฟังก์ชัน _extractNutritionValue
double _extractNutritionValue(Map<String, dynamic> recipe, String nutrientName) {
  if (recipe['nutrition'] == null) return 0.0;
  
  // กรณีที่ nutrition มาในรูปแบบ nutrition: {protein: 10, fat: 5, ...}
  if (recipe['nutrition'] is Map && recipe['nutrition'][nutrientName] != null) {
    var value = recipe['nutrition'][nutrientName];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  
  // กรณีที่ nutrition มาในรูปแบบ nutrition: {nutrients: [{name: "Protein", amount: 10}, ...]}
  if (recipe['nutrition'] is Map && recipe['nutrition']['nutrients'] is List) {
    List nutrients = recipe['nutrition']['nutrients'];
    for (var nutrient in nutrients) {
      if (nutrient is Map && 
          nutrient['name'] != null && 
          nutrient['name'].toString().toLowerCase() == nutrientName.toLowerCase()) {
        var amount = nutrient['amount'];
        if (amount is num) return amount.toDouble();
        if (amount is String) return double.tryParse(amount) ?? 0.0;
        return 0.0;
      }
    }
  }
  
  // ถ้าไม่พบข้อมูลในทั้งสองรูปแบบ ลองดึงจาก usedIngredients
  if (recipe['usedIngredients'] is List) {
    double total = 0.0;
    for (var ingredient in recipe['usedIngredients']) {
      if (ingredient is Map && ingredient['nutrition'] != null) {
        if (ingredient['nutrition'][nutrientName] != null) {
          var value = ingredient['nutrition'][nutrientName];
          if (value is num) total += value.toDouble();
          if (value is String) total += double.tryParse(value) ?? 0.0;
        }
      }
    }
    if (total > 0) return total;
  }
  
  // ค่าเริ่มต้นถ้าไม่พบข้อมูล - ใช้ค่าที่มีความเป็นไปได้มากกว่า 0
  switch (nutrientName.toLowerCase()) {
    case 'protein': return 10.0;
    case 'fat': return 5.0;
    case 'carbs': return 20.0;
    case 'calories': return 200.0;
    default: return 0.0;
  }
}
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    String formattedDate =
        DateFormat('dd-MM-yyyy').format(widget.ingredient.expirationDate);
    final DateTime now = DateTime.now();
    final DateTime expiryDate = widget.ingredient.expirationDate;
    final int daysToExpiry = expiryDate.difference(now).inDays;

    String expiryText;
    Color expiryColor;

    if (daysToExpiry < 0) {
      expiryText = 'Expired ${-daysToExpiry} days ago!';
      expiryColor = Colors.red;
    } else if (daysToExpiry <= 3) {
      expiryText = 'Expiring in $daysToExpiry days!';
      expiryColor = Colors.orange;
    } else {
      expiryText = '$daysToExpiry days in';
      expiryColor = Colors.green;
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 15, left: 5, right: 3),
        child: ListView(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: FaIcon(FontAwesomeIcons.arrowLeft),
                  color: Colors.black,
                  iconSize: 20,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    _showIngredientPopup(
                        context,
                        {
                          'ingredientsName': widget.ingredient.ingredientsName,
                          'imageUrl': widget.ingredient.imageUrl,
                          'category': widget.ingredient.category,
                          'unit': widget.ingredient.unit,
                          'storage': widget.ingredient.storage,
                          'source': widget.ingredient.source,
                          'quantity': widget.ingredient.quantity,
                        },
                        userIngredientsMap);
                  },
                  icon: FaIcon(FontAwesomeIcons.basketShopping),
                  color: Colors.black,
                  iconSize: 20,
                ),
                IconButton(
                onPressed: () async {
                  QuickAlert.show(
                    context: context,
                    type: QuickAlertType.confirm,
                    title: 'Delete Ingredient',
                    text: 'Are you sure you want to delete ${widget.ingredient.ingredientsName}?',
                    confirmBtnText: 'Delete',
                    cancelBtnText: 'Cancel',
                    confirmBtnColor: Colors.red,
                    onConfirmBtnTap: () async {
                      try {
                        String uid = FirebaseAuth.instance.currentUser!.uid;
                        var querySnapshot = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('userIngredients')
                            .where('ingredientsName', isEqualTo: widget.ingredient.ingredientsName)
                            .get();

                        if (querySnapshot.docs.isNotEmpty) {
                          await querySnapshot.docs.first.reference.delete();
                          print("✅ Deleted ${widget.ingredient.ingredientsName}");

                          
                          Navigator.pop(context); 
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.success,
                            title: 'Success',
                            text: '${widget.ingredient.ingredientsName} has been deleted',
                            onConfirmBtnTap: () {
                              Navigator.pop(context); 
                              Navigator.pop(context); 
                            }
                          );
                        }
                      } catch (e) {
                        print("❌ Error deleting ingredient: $e");
                        QuickAlert.show(
                          context: context,
                          type: QuickAlertType.error,
                          title: 'Error',
                          text: 'Failed to delete ingredient'
                        );
                      }
                    }
                  );
                },
                icon: FaIcon(FontAwesomeIcons.trash),
                color: Colors.black,
                iconSize: 20,
              ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditIngredientScreen(
                          ingredient: {
                              ...widget.ingredient.toJson(), 
                            'id': widget.ingredient.ingredientId, 
                          },
                        ),
                      ),
                    );
                  },
                  icon: FaIcon(FontAwesomeIcons.pencil),
                  color: Colors.black,
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.ingredient.ingredientsName[0].toUpperCase() +
                        widget.ingredient.ingredientsName.substring(1),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
           Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Image.network(
                        widget.ingredient.imageUrl,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/default_ing.png',
                            width: 25,
                            height: 25,
                          );
                        },
                        width: 25,
                        height: 25,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.ingredient.category,
                        style: const TextStyle(
                          color: Color(0xFF595959),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "in",
                        style: const TextStyle(
                          color: Color(0xFF595959),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.ingredient.storage,
                        style: const TextStyle(
                          color: Color(0xFF595959),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 15),
            Padding(padding: const EdgeInsets.only(left: 5, right: 5 ),
            child:  Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                       Text(
                        "Source",
                        style: const TextStyle(
                          color: Color(0xFF595959),
                          fontSize: 18,
                        ),
                      ),
                    
                    const SizedBox(height: 10),
                    Row(
                        children: [
                          Image.asset(
                            widget.ingredient.source.toLowerCase() == 'home'
                                ? 'assets/images/house_detail.png'
                                : 'assets/images/cart_detail.png',
                            width: 20,
                            height: 20,
                          ),
                           const SizedBox(width: 5),
                           Text(
                          widget.ingredient.source?.isEmpty ?? true 
                              ? 'Unknown' 
                              : widget.ingredient.source,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ],
                      ),
                    
                  ],
                ),
              ),
              // Expiring column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Expiring",
                      style: TextStyle(
                        color: expiryColor,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        expiryText,
                        style: TextStyle(
                          color: expiryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                ),
              ),
              // Amount column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Amount",
                      style: const TextStyle(
                        color: Color(0xFF595959),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${widget.ingredient.quantity.toStringAsFixed(1)} ${_formatUnit(widget.ingredient.unit)}",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    
                  ],
                ),
              ),
            ],
          ),
          ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Let's cook it !",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pick the best pairing",
                    style: const TextStyle(
                      color: Color(0xFF595959),
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            isLoadingPairing
            ?  Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF5CB77E)),
                    SizedBox(height: 10),
                    Text(
                      "Finding ingredients that pair well...",
                      style: TextStyle(
                        color: Color(0xFF595959),
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
            : pairingIngredients.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'No pairing ingredients available.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: pairingIngredients.map((ingredient) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            // ครอบรูปและชื่อให้อยู่ด้วยกัน
                            children: [
                              // รูปภาพ
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: ClipOval(
                                    child: Image.network(
                                      ingredient['image'] ?? '',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit
                                          .cover, // ปรับให้รูปพอดีกับวงกลม
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                  height: 8), // ระยะห่างระหว่างรูปกับชื่อ

                              // ชื่อส่วนผสม
                              Text(
                                ingredient['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF595959),
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Or cook with what you have",
                    style: const TextStyle(
                      color: Color(0xFF595959),
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                   isLoadingRecipes
                      ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Color(0xFF5CB77E)),
                              SizedBox(height: 10),
                              Text(
                                "Finding recipes...",
                                style: TextStyle(
                                  color: Color(0xFF595959),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                        
                      :recipes.isEmpty
                       ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
                    child: Text(
                      "No recipes found for this ingredient.",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  
                )
              :
                    Column(
                      children: recipes.map((recipe) {
                        int index = recipes.indexOf(recipe);
                        int matchedIngredients = 0;
                        if (recipe['usedIngredientCount'] is int) {
                          matchedIngredients = recipe['usedIngredientCount'];
                        } else if (recipe['usedIngredientCount'] is num) {
                          matchedIngredients = (recipe['usedIngredientCount'] as num).toInt();
                        } else {
                          matchedIngredients = int.tryParse(recipe['usedIngredientCount']?.toString() ?? '0') ?? 0;
                        }
                        int missedIngredients = 0;
                        if (recipe['missedIngredientCount'] is int) {
                          missedIngredients = recipe['missedIngredientCount'];
                        } else if (recipe['missedIngredientCount'] is num) {
                          missedIngredients = (recipe['missedIngredientCount'] as num).toInt();
                        } else {
                          missedIngredients = int.tryParse(recipe['missedIngredientCount']?.toString() ?? '0') ?? 0;
                        }

                        int totalIngredients = matchedIngredients + missedIngredients;
                       return Padding(
  padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
  child: GestureDetector( // เพิ่ม GestureDetector ครอบ Row เดิม
    onTap: () {
      print("⚙️ DEBUG - Navigating to recipe detail with ID: ${recipe['id']}");
  print("⚙️ DEBUG - Recipe structure: ${recipe.keys.toList()}");
   if (recipe['extendedIngredients'] == null && 
      recipe['usedIngredients'] != null) {
    // สร้าง extendedIngredients จาก usedIngredients
    recipe['extendedIngredients'] = recipe['usedIngredients'];
    print("⚙️ DEBUG - Created extendedIngredients from usedIngredients: ${recipe['extendedIngredients'].length} items");
  }
  
      // แปลงข้อมูลจาก API เป็น Recipe object
      final ingredients = (recipe['extendedIngredients'] as List<dynamic>? ?? []).map((ingredient) {
        return IngredientUsage(
          ingredient: Ingredient.fromAPI(
            id: ingredient['id']?.toString() ?? '',
      name: ingredient['name'] ?? '',
      amount: ingredient['amount'] is num ? ingredient['amount'].toDouble() : double.tryParse(ingredient['amount']?.toString() ?? '0') ?? 0.0,
      unit: ingredient['unit'] ?? '',
          ),
           quantityUsed: ingredient['amount'] is num ? ingredient['amount'].toDouble() : double.tryParse(ingredient['amount']?.toString() ?? '0') ?? 0.0,
        );
      }).toList();

      // แปลง instructions ให้เป็น List<String>
      List<String> instructions = [];
      if (recipe['analyzedInstructions'] != null && recipe['analyzedInstructions'] is List && recipe['analyzedInstructions'].isNotEmpty) {
        for (var instruction in recipe['analyzedInstructions']) {
          if (instruction != null && instruction.containsKey('steps')) {
            for (var step in instruction['steps']) {
              if (step != null && step.containsKey('step')) {
                instructions.add(step['step'].toString());
              }
            }
          }
        }
      } else if (recipe['instructions'] != null) {
        // กรณีที่ instructions เป็น String เดียว
        instructions = [recipe['instructions'].toString()];
      }

      // สร้าง Recipe object
      Recipe recipeObj = Recipe(
        
        recipeId: recipe['id'] is int ? recipe['id'] : int.parse(recipe['id'].toString()),
        recipeName: recipe['title'] ?? '',
        description: recipe['summary'] ?? '',
        ingredients: ingredients,
        instructions: instructions,
        preparationTime: int.tryParse(recipe['readyInMinutes']?.toString() ?? '0') ?? 0,
        cookingTime: int.tryParse(recipe['cookingMinutes']?.toString() ?? '0') ?? 0,
        servings: int.tryParse(recipe['servings']?.toString() ?? '1') ?? 1,
        category: (recipe['dishTypes'] as List<dynamic>? ?? []).isNotEmpty 
            ? recipe['dishTypes'][0].toString() 
            : 'Main Course',
        imageUrl: recipe['image'] ?? '',
         Protein: _extractNutritionValue(recipe, 'protein'),
  Fat: _extractNutritionValue(recipe, 'fat'),
  Carbo: _extractNutritionValue(recipe, 'carbs'),
  Kcal: _extractNutritionValue(recipe, 'calories').toInt(),
  
        isFavorite: recipe['isFavorite'] == 'true',
      
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeDetail(
            recipe: recipeObj,
            recipeId: recipeObj.recipeId,
            recipeDocId: recipe['id'].toString(),
            loadFullData: true,
          ),
        ),
      );
    },
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.network(
                                            recipe['image'] ?? '',
                                            width: 150,
                                            height: 120,
                                            fit: BoxFit.cover, errorBuilder:
                                                (context, error, stackTrace) {
                                          return Container(
                                            width: 150,
                                            height: 120,
                                            color: Colors.grey[200],
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.image_not_supported,
                                                    color: Colors.grey[400]),
                                                Text(
                                                  'Image not available',
                                                  style: TextStyle(
                                                      color: Colors.grey[600]),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ),
                                     
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          recipe['title'] ?? '',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF595959),
                                            fontWeight: FontWeight.bold,
                                            height: 1.2,
                                          ),
                                          softWrap: true,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFe7f8f0),
                                            borderRadius:
                                                BorderRadius.circular(7),
                                          ),
                                          child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '$matchedIngredients/$totalIngredients ingredients match',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color.fromARGB(255, 2, 190, 100),
                                                  ),
                                                ),
                                              ]),
                                        ),
                                      ],
                                    ),
                                  )
                                ]))
                       );
                      }).toList(),
                    )
                 
          ],
        ),
      ),
    ])
      ));
  }
}

List<Map<String, dynamic>> addedToCartIngredients = [];

Future<void> _saveCart(Map<String, dynamic> ingredient) async {
  try {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // อ้างอิงไปยัง collection "userCart" และ "historyCart"
    CollectionReference userCart = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('userCart');

    CollectionReference historyCart = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('historyCart');

    // ตรวจสอบว่ามี ingredient นี้อยู่ใน cart แล้วหรือยัง
    QuerySnapshot query = await userCart
        .where('ingredientsName', isEqualTo: ingredient['ingredientsName'])
        .get();

    if (query.docs.isNotEmpty) {
      // ถ้ามีอยู่แล้ว → อัปเดตจำนวน (quantity)
      DocumentSnapshot existingDoc = query.docs.first;
      int existingQuantity = existingDoc['quantity'] ?? 0;
      num newQuantity = existingQuantity + (ingredient['quantity'] ?? 1);

      await existingDoc.reference.update({'quantity': newQuantity});
      print("✅ Updated quantity for ${ingredient['ingredientsName']}");
    } else {
      // ถ้ายังไม่มี → เพิ่มเข้า cart
      await userCart.add(ingredient);
      print("✅ Added ${ingredient['ingredientsName']} to cart");
    }

    // 🔥 เก็บประวัติการเพิ่มของลง historyCart พร้อม timestamp
    await historyCart.add({
      ...ingredient,
      'addedAt': FieldValue.serverTimestamp(), // เพิ่ม timestamp
    });

    print("📜 History saved for ${ingredient['ingredientsName']}");
  } catch (e) {
    print("❌ Error saving cart: $e");
  }
}

void _showIngredientPopup(BuildContext context, Map<String, dynamic> ingredient,
    dynamic userIngredientsMap) {
  double quantity = 1.0;
  TextEditingController priceController = TextEditingController();

  List<Map<String, dynamic>> userIngredients = userIngredientsMap.entries
      .map<Map<String, dynamic>>((entry) => {
            'ingredientsName': entry.key,
            'quantity': entry.value,
          })
      .toList();

  List<String> categoryOptions = [
    'Fruits',
    'Vegetables',
    'Meat',
    'Seafood',
    'Cold Cuts',
    'Dairy',
    'Bread',
    'Cake & Biscuits',
    'Alcoholic Beverages',
    'Beverages',
    'Coffee & Tea',
    'Snacks',
    'Sweets',
    'Condiments & Dips',
    'Dry Goods',
    'Nuts & Seeds',
    'Canned Food',
    'Cereals',
    'Leftovers',
    'Easy Meals',
    'Household Essentials',
    'Baking Goods',
    'Other goods',
    'Frozen foods',
    'Spices',
  ];

  List<String> unitOptions = [
    'Kilograms (kg)',
    'Grams (g)',
    'Pounds (lbs)',
    'Ounces (oz)',
    'Liters (L)',
    'Milliliters (mL)',
    'Gallons',
    'Bottles',
    'Pieces',
    'Boxes',
    'Cups',
    'Cans',
    'Packs',
    'Bulb',
    'Leaves',
    'Loaf',
    'Bunch',
    'Head',
    'Jar',
    'Sheet',
    'Bar',
    'Container',
    'Cob',
  ];
  List<String> storageOptions = ['Fridge', 'Freezer', 'Pantry'];
  List<String> sourceOptions = ['Supermarket', 'Market', 'Online', 'Homegrown'];

  String selectedCategory = ingredient['category'] ?? categoryOptions[0];
  String selectedUnit = ingredient['unit'] ?? unitOptions[0];
  String selectedStorage = ingredient['storage'] ?? storageOptions[0];
  String selectedSource = sourceOptions[0];

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.black),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  ClipRRect(
                    child: Image.network(
                      ingredient['imageUrl'],
                      width: 100,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset('assets/images/default_ing.png',
                            width: 100, height: 100);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ingredient['ingredientsName'],
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildQuantitySelector(ingredient, userIngredients, quantity,
                      (newQuantity) {
                    setDialogState(() => quantity = newQuantity);
                  }),
                  const SizedBox(height: 10),
                  _buildDropdown('Category', categoryOptions, selectedCategory,
                      (newValue) {
                    setDialogState(() => selectedCategory = newValue);
                  }),
                  _buildDropdown('Unit', unitOptions, selectedUnit, (newValue) {
                    setDialogState(() => selectedUnit = newValue);
                  }),
                  _buildDropdown('Storage', storageOptions, selectedStorage,
                      (newValue) {
                    setDialogState(() => selectedStorage = newValue);
                  }),
                  _buildDropdown('Source', sourceOptions, selectedSource,
                      (newValue) {
                    setDialogState(() => selectedSource = newValue);
                  }),
                  _buildPriceField(priceController),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await _saveCart({
                        'ingredientsName': ingredient['ingredientsName'],
                        'imageUrl': ingredient['imageUrl'],
                        'unit': selectedUnit,
                        'category': selectedCategory,
                        'storage': selectedStorage,
                        'source': selectedSource,
                        'quantity': quantity,
                        'price': priceController.text.isEmpty
                            ? 0
                            : double.tryParse(priceController.text) ?? 0,
                      });
                      setDialogState(() {
                        addedToCartIngredients.add({
                          'ingredientsName': ingredient['ingredientsName'],
                          'imageUrl': ingredient['imageUrl'],
                          'unit': selectedUnit,
                          'category': selectedCategory,
                          'storage': selectedStorage,
                          'source': selectedSource,
                          'quantity': quantity,
                          'price': priceController.text.isEmpty
                              ? 0
                              : double.tryParse(priceController.text) ?? 0,
                        });
                      });

                      print('✅ Added ${ingredient['ingredientsName']} to cart');

                      QuickAlert.show(
                        context: context,
                        type: QuickAlertType.success,
                        title: 'Success!',
                        text: '${ingredient['ingredientsName']} added to cart.',
                        confirmBtnText: 'OK',
                        onConfirmBtnTap: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RootPage(initialIndex: 3),
                            ),
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add to Shoppping List',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

// Dropdown Widget
Widget _buildDropdown(String label, List<String> options, String selectedValue,
    Function(String) onChanged) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: options.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (newValue) => onChanged(newValue!),
    ),
  );
}

// Quantity Selector Widget (+ -)
Widget _buildQuantitySelector(
  Map<String, dynamic> ingredient,
  List<Map<String, dynamic>> userIngredients,
  double quantity,
  Function(double) onQuantityChanged,
) {
 double userQuantity = userIngredients
      .where((item) => item['ingredientsName'] == ingredient['ingredientsName'])
      .fold(0.0, (sum, item) {
        final itemQuantity = item['quantity'] is int 
            ? (item['quantity'] as int).toDouble() 
            : (item['quantity'] as num).toDouble();
        return sum + itemQuantity;
      });

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quantity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: quantity > 1
                      ? () => onQuantityChanged(quantity - 1)
                      : null,
                  icon: const Icon(Icons.remove, color: Colors.red),
                ),
                Text(quantity.toString(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => onQuantityChanged(quantity + 1),
                  icon: const Icon(Icons.add, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
        // ตรวจสอบว่า ingredient มี `quantity` หรือไม่จาก userIngredientsMap
        if (userQuantity > 0)
          Row(
            children: [
              Image.asset(
                'assets/images/about.png',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$userQuantity ${ingredient['unit']} in stock', // แสดงจำนวนที่มีใน stock
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ],
          )
        else
          const SizedBox(),
      ],
    ),
  );
}

// ช่องกรอกราคา (Price)
Widget _buildPriceField(TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Price (฿)',
        suffixText: '฿',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onChanged: (value) {
        if (value.isNotEmpty && double.tryParse(value) == null) {
          controller.text = '0';
        }
      },
    ),
  );
}

String _formatUnit(String unit) {
  final Map<String, String> unitAbbreviations = {
    'Kilograms (kg)': 'kg',
    'Grams (g)': 'g',
    'Pounds (lbs)': 'lbs',
    'Ounces (oz)': 'oz',
    'Liters (L)': 'L',
    'Milliliters (mL)': 'mL',
  };

  // ถ้าหน่วยมีวงเล็บให้เอาแค่ตัวย่อในวงเล็บ
  if (unit.contains('(') && unit.contains(')')) {
    final start = unit.indexOf('(') + 1;
    final end = unit.indexOf(')');
    return unit.substring(start, end);
  }

  // ถ้าไม่มีวงเล็บ ให้ใช้ map หาตัวย่อ
  return unitAbbreviations[unit] ?? unit;
}

