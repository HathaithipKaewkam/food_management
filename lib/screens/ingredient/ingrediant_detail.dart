import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/ingredient/add_ingredient.dart';
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
  Map<String, int> userIngredientsMap = {};
  bool isLoading = true;
  final RecipeService _recipeService = RecipeService();

  @override
  void initState() {
    super.initState();
    fetchPairingIngredients();
    fetchRecipe();
    _fetchUserIngredients();
  }

  Future<void> fetchRecipe() async {
    try {
  
      String ingredientName = widget.ingredient.ingredientsName.trim();
      List<String> userIngredients = [ingredientName];

      
      String formattedIngredient = ingredientName
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '') 
          .trim();

      List<Map<String, dynamic>> fetchedRecipes =
    await _recipeService.getRecipesWithImages([formattedIngredient]);

      if (fetchedRecipes.isEmpty) {
        print("⚠️ No recipes found in API response");
      } else {
        print("✅ Found ${fetchedRecipes.length} recipes");
        fetchedRecipes.forEach((recipe) {
          print("  - ${recipe['title']}");
        });
      }

      setState(() {
        recipes = fetchedRecipes;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching recipes: $e");
      setState(() {
        recipes = [];
        isLoading = false;
      });
    }
  }

  Future<void> fetchPairingIngredients() async {
    try {
      List<Map<String, String>> fetchedIngredients =
          await getRecipeAndPairings(widget.ingredient.ingredientsName);
      setState(() {
        pairingIngredients = fetchedIngredients;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching pairing ingredients: $e");
      setState(() {
        pairingIngredients = [];
        isLoading = false;
      });
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

      Map<String, int> tempUserIngredients = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String name = data['ingredientsName'];
        int quantity = data['quantity'] ?? 0;
        tempUserIngredients[name] = quantity;

        print("Loaded ingredient: $name with quantity: $quantity");
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
        padding: const EdgeInsets.only(top: 20, left: 5, right: 3),
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
                        builder: (context) => AddIngredientScreen(
                          ingredient: {
                            'ingredientsName': widget.ingredient.ingredientsName,
                            'category': widget.ingredient.category,
                            'storage': widget.ingredient.storage,
                            'unit': widget.ingredient.unit,
                            'quantity': widget.ingredient.quantity.toString(), 
                            'minQuantity': widget.ingredient.minQuantity.toString(), 
                            'price': widget.ingredient.price.toString(),
                            'expirationDate': widget.ingredient.expirationDate.toIso8601String(),
                            'imageUrl': widget.ingredient.imageUrl,
                            'allergenInfo': widget.ingredient.allergenInfo,
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
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Image.network(
                    widget.ingredient.imageUrl,
                    fit: BoxFit.contain,
                    width: 25,
                    height: 25,
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    widget.ingredient.category,
                    style: const TextStyle(
                      color: Color(0xFF595959),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    "in",
                    style: const TextStyle(
                      color: Color(0xFF595959),
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    widget.ingredient.storage,
                    style: const TextStyle(
                      color: Color(0xFF595959),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Padding(padding: const EdgeInsets.only(left: 5, right: 5 ),
            child:  Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          Text(
                            widget.ingredient.source,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Image.asset(
                            widget.ingredient.source.toLowerCase() == 'home'
                                ? 'assets/images/house_detail.png'
                                : 'assets/images/cart_detail.png',
                            width: 20,
                            height: 20,
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
                      "${widget.ingredient.quantity} ${widget.ingredient.unit[0].toLowerCase()}${widget.ingredient.unit.substring(1)}",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
            pairingIngredients.isEmpty
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
                  if (recipes.isNotEmpty)
                    Column(
                      children: recipes.map((recipe) {
                        int index = recipes.indexOf(recipe);
                        int matchedIngredients =
                            int.parse(recipe['usedIngredientCount'] ?? '0');
                        int totalIngredients = matchedIngredients +
                            int.parse(recipe['missedIngredientCount'] ?? '0');
                        return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5.0, vertical: 10.0),
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
                                      Positioned(
                                        top: 3,
                                        right: 4,
                                        child: Container(
                                          height: 40,
                                          width: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(25),
                                            border: Border.all(
                                                color: Colors.grey.shade300,
                                                width: 1),
                                          ),
                                          child: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                String currentFavorite =
                                                    recipes[index]
                                                            ['isFavorite'] ??
                                                        'false';
                                                recipes[index]['isFavorite'] =
                                                    (currentFavorite == 'true')
                                                        ? 'false'
                                                        : 'true';
                                              });
                                            },
                                            icon: Icon(
                                              recipes[index]['isFavorite'] ==
                                                      'true'
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: recipes[index]
                                                          ['isFavorite'] ==
                                                      'true'
                                                  ? Colors.red
                                                  : Colors.black54,
                                            ),
                                            iconSize: 20,
                                          ),
                                        ),
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
                                ]));
                      }).toList(),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "No recipes found.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
  int quantity = 1;
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
                    child: const Text('Add to Cart',
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
  int quantity,
  Function(int) onQuantityChanged,
) {
  // ใช้ quantity ที่มาอัปเดตจาก userIngredientsMap
  int userQuantity = userIngredients
      .where((item) => item['ingredientsName'] == ingredient['ingredientsName'])
      .fold(0, (sum, item) => sum + (item['quantity'] as int));

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
