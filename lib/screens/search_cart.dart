import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/add_cart.dart';
import 'package:food_project/screens/cart_screen.dart';
import 'package:food_project/screens/ingredient/add_ingredient.dart';
import 'package:food_project/screens/root_screen.dart';

class SearchCartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> addedToCartIngredients;
  const SearchCartScreen({Key? key, required this.addedToCartIngredients})
      : super(key: key);
  @override
  _SearchCartScreenState createState() => _SearchCartScreenState();
}

class _SearchCartScreenState extends State<SearchCartScreen> {
  TextEditingController _searchController = TextEditingController();
  String selectedIngredientName = '';
  List<Map<String, dynamic>> ingredientList = [];
  Timer? _debounce;
  Map<String, int> userIngredientsMap = {};
  List<Map<String, dynamic>> addedToCartIngredients = [];
  List<Ingredient> selectedItems = [];

  Future<void> _fetchIngredients() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('ingredients')
          .orderBy('ingredientsName', descending: false)
          .get();

      List<Map<String, dynamic>> tempList = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String imageName = data['imageUrl'] ?? '';
        String? imageUrl =
            imageName.isNotEmpty ? await getStorageImageUrl(imageName) : null;

        tempList.add({
          'ingredientsName': data['ingredientsName'] ?? '',
          'imageUrl': imageUrl ?? 'assets/images/default_ing.png',
          'category': data['category'] ?? '',
          'unit': data['unit'] ?? '',
          'shelflife': data['shelflife'] ?? 0,
          'storage': data['storage'] ?? '',
          'quantity': data['quantity'] ?? 1,
          'minQuantity': data['minQuantity'] ?? 1,
        });
      }

      print("✅ Loaded ingredients: ${tempList.length}");
      setState(() {
        ingredientList = tempList;
      });
    } catch (e) {
      print("❌ Error fetching ingredients: $e");
    }
  }

  // ค้นหาวัตถุดิบ
  List<Map<String, dynamic>> _searchIngredients(String query) {
    return ingredientList.where((ingredient) {
      final ingredientName = ingredient['ingredientsName'];
      return ingredientName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  Future<String?> getStorageImageUrl(String fileName) async {
    try {
      if (fileName.isEmpty) return null;

      Reference ref =
          FirebaseStorage.instance.ref().child('ingredients/$fileName');
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("❌ Error getting image URL: $e");
      return null;
    }
  }

  void _setSelectedIngredient(String ingredientName) {
    setState(() {
      selectedIngredientName = ingredientName;
    });
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {});
    });
  }

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
  void initState() {
    super.initState();
    _fetchIngredients();
    _fetchUserIngredients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
      padding: const EdgeInsets.only(top: 40, left: 10, right: 10),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                color: Colors.black,
                iconSize: 20,
              ),
              const SizedBox(width: 5),
              const Text(
                'Add Ingredients',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              labelText: 'Search / Add Ingredient',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: const BorderSide(color: Colors.black, width: 1.0),
              ),
              suffixIcon: const Icon(Icons.search),
            ),
          ),
          // แสดงรายการที่ค้นหา
          Expanded(
            child: _searchController.text.isEmpty
                ? const SizedBox()
                : ListView(
                    children: [
                      if (_searchController.text.isNotEmpty &&
                          _searchIngredients(_searchController.text).isEmpty)
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 10),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    'Add Ingredient To Cart',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.only(left: 0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFd7d8d8),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: ClipRRect(
                                        child: SizedBox(
                                          child: Image.asset(
                                            'assets/images/default_ing.png',
                                            fit: BoxFit.contain,
                                            width: 50,
                                            height: 50,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 30),
                                    Expanded(
                                      child: Text(
                                        _searchController.text,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            _showIngredientPopup(
                              context,
                              {
                                'ingredientsName': _searchController.text,
                                'imageUrl': 'assets/images/default_ing.png',
                                'unit': 'N/A',
                                'storage': 'N/A',
                              },
                            );
                          },
                        ),
                      ..._searchIngredients(_searchController.text)
                          .map((ingredient) {
                        return ListTile(
                          leading: Image.network(
                            ingredient['imageUrl']!,
                            width: 40,
                            height: 40,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                  'assets/images/default_ing.png',
                                  width: 40,
                                  height: 40);
                            },
                          ),
                          title: Text(ingredient['ingredientsName']!),
                          onTap: () {
                            _showIngredientPopup(context, ingredient);
                          },
                        );
                      }).toList(),
                    ],
                  ),
          ),
        ],
      ),
    ));
  }

  void _showIngredientPopup(
      BuildContext context, Map<String, dynamic> ingredient) {
    int quantity = 1;
    TextEditingController priceController = TextEditingController();

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
    List<String> sourceOptions = [
      'Supermarket',
      'Market',
      'Online',
      'Homegrown'
    ];

    String selectedCategory = ingredient['category'] ?? categoryOptions[0]; 
    String selectedUnit = ingredient['unit'] ?? unitOptions[0]; 
    String selectedStorage = ingredient['storage'] ?? storageOptions[0]; 
    String selectedSource = sourceOptions[0];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    _buildQuantitySelector(ingredient, userIngredientsMap, quantity,
                        (newQuantity) {
                      setDialogState(() => quantity = newQuantity);
                    }),

                    const SizedBox(height: 10),
                    _buildDropdown('Category', categoryOptions, selectedCategory,
                        (newValue) {
                      setDialogState(() => selectedCategory = newValue);
                    }),
                    _buildDropdown('Unit', unitOptions, selectedUnit,
                        (newValue) {
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
                        setState(() {
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

                        print(
                            '✅ Added ${ingredient['ingredientsName']} to cart');
                        

                        Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RootPage(
                            initialIndex: 3, 
                          ),
                        ),
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
    Map<String, int> userIngredientsMap,
    int quantity,
    Function(int) onQuantityChanged) {
    int userQuantity = userIngredientsMap[ingredient['ingredientsName']] ?? 0;



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
                '$userQuantity ${ingredient['unit']} in stock',
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
