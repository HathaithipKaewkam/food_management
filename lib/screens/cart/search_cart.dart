import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/cart/cart_screen.dart';
import 'package:food_project/screens/ingredient/add_ingredient.dart';
import 'package:food_project/screens/root_screen.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Map<String, double> userIngredientsMap = {};
  List<Map<String, dynamic>> addedToCartIngredients = [];
  List<Ingredient> selectedItems = [];
  bool _isUsingCache = false;

  Future<void> _fetchIngredients({bool useCache = false}) async {
  try {
    if (useCache && _isUsingCache) {
      print("🔄 Already using cache, fetching fresh data in background");
    }
    
    // โหลดข้อมูลใหม่จาก Firestore 
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('ingredients')
        .orderBy('ingredientsName', descending: false)
        .get();

    print("✅ Fetched ${querySnapshot.docs.length} ingredients from Firestore");

    List<Map<String, dynamic>> tempList = [];
    
    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      // เก็บชื่อไฟล์ไว้โดยไม่ต้องแก้ไข
      String imageUrl = data['imageUrl'] ?? '';
      
      // ตรวจสอบว่า imageUrl ไม่ใช่ URL เต็ม (อาจเป็นชื่อไฟล์)
      if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
        // ตรวจสอบว่ามีนามสกุลไฟล์หรือไม่
        if (!imageUrl.toLowerCase().endsWith('.png') && 
            !imageUrl.toLowerCase().endsWith('.jpg') && 
            !imageUrl.toLowerCase().endsWith('.jpeg')) {
          // ไม่ต้องเพิ่มนามสกุลไฟล์เอง - ให้ _getDownloadUrl จัดการ
        }
      }
      
      tempList.add({
        'ingredientsName': data['ingredientsName'] ?? '',
        'imageUrl': imageUrl, // เก็บค่าเดิมโดยไม่ต้องแก้ไข
        'category': data['category'] ?? '',
        'unit': data['unit'] ?? '',
        'shelflife': data['shelflife'] ?? 0,
        'storage': data['storage'] ?? '',
        'quantity': data['quantity'] ?? 1,
        'minQuantity': data['minQuantity'] ?? 1,
        'kcal': data['kcal'] ?? 0,
      });
    }
    
    // บันทึกข้อมูลลงแคช
    await _saveIngredientsToCache(tempList);
    
    // อัปเดต state เฉพาะเมื่อจำเป็น
    if (!useCache || !_isUsingCache) {
      setState(() {
        ingredientList = tempList;
      });
    } else {
      // ถ้าใช้แคช ให้อัปเดตแบบเงียบๆ โดยไม่ setState
      ingredientList = tempList;
    }
  } catch (e) {
    print("❌ Error fetching ingredients: $e");
  }
}

  // ค้นหาวัตถุดิบ
  List<Map<String, dynamic>> _searchIngredients(String query) {
  if (query.isEmpty) return [];
  
  final lowerQuery = query.toLowerCase();
  // ค้นหาจากข้อมูลที่มีอยู่แล้ว ไม่ต้องดึงจาก Firebase ใหม่
  return ingredientList.where((ingredient) {
    final ingredientName = ingredient['ingredientsName'].toString().toLowerCase();
    return ingredientName.contains(lowerQuery);
  }).take(10).toList(); // จำกัดผลลัพธ์เพียง 10 รายการ
}


  void _setSelectedIngredient(String ingredientName) {
    setState(() {
      selectedIngredientName = ingredientName;
    });
  }

  void _onSearchChanged(String value) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  _debounce = Timer(const Duration(milliseconds: 300), () {
    setState(() {});
  });
}

  Future<void> _saveCart(Map<String, dynamic> ingredient) async {
  try {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    CollectionReference userCart = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('userCart');

    CollectionReference historyCart = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('historyCart');

    QuerySnapshot query = await userCart
        .where('ingredientsName', isEqualTo: ingredient['ingredientsName'])
        .get();

    if (query.docs.isNotEmpty) {
      DocumentSnapshot existingDoc = query.docs.first;
      double existingQuantity = (existingDoc['quantity'] is int)
          ? (existingDoc['quantity'] as int).toDouble()
          : (existingDoc['quantity'] as num?)?.toDouble() ?? 0.0;
      
      double newQuantity = existingQuantity + (ingredient['quantity'] as num).toDouble();
      
      
      double existingKcal = 0.0;
      if (existingDoc['kcal'] != null) {
        existingKcal = (existingDoc['kcal'] is int)
            ? (existingDoc['kcal'] as int).toDouble()
            : (existingDoc['kcal'] as num?)?.toDouble() ?? 0.0;
      }
      
      double newKcal = existingKcal + (ingredient['kcal'] as num).toDouble();
      

      await existingDoc.reference.update({
        'quantity': newQuantity,
        'kcal': newKcal, // อัปเดตค่า kcal
      });
      
      print("✅ Updated quantity and kcal for ${ingredient['ingredientsName']}");
    } else {
      
      Map<String, dynamic> newIngredient = {...ingredient};
      
      
      if (newIngredient['kcal'] != null && newIngredient['kcal'] is! double) {
        newIngredient['kcal'] = (newIngredient['kcal'] as num).toDouble();
      }
      
      DocumentReference newDoc = await userCart.add(newIngredient);
      
      
    }

    // บันทึกประวัติ
    Map<String, dynamic> historyItem = {
      ...ingredient,
      'addedAt': FieldValue.serverTimestamp(),
    };
    
    // ตรวจสอบว่า kcal เป็น double
    if (historyItem['kcal'] != null && historyItem['kcal'] is! double) {
      historyItem['kcal'] = (historyItem['kcal'] as num).toDouble();
    }
    
    await historyCart.add(historyItem);

    print("📜 History saved for ${ingredient['ingredientsName']} with ${ingredient['kcal']} kcal");
  } catch (e) {
    print("❌ Error saving cart: $e");
  }
}

Future<void> _saveIngredientsToCache(List<Map<String, dynamic>> ingredients) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(ingredients);
    await prefs.setString('cached_cart_ingredients', jsonData);
    await prefs.setInt('cart_cache_timestamp', DateTime.now().millisecondsSinceEpoch);
    print("✅ Saved ${ingredients.length} ingredients to cache");
  } catch (e) {
    print("❌ Error saving to cache: $e");
  }
}

// เพิ่มเมธอดดึงข้อมูลจากแคช
Future<List<Map<String, dynamic>>> _getIngredientsFromCache() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString('cached_cart_ingredients');
    final timestamp = prefs.getInt('cart_cache_timestamp') ?? 0;
    
    // แคชมีอายุ 24 ชั่วโมง
    final cacheValid = DateTime.now().millisecondsSinceEpoch - timestamp < 24 * 60 * 60 * 1000;
    
    if (jsonData != null && cacheValid) {
      final List<dynamic> decoded = jsonDecode(jsonData);
      print("✅ Loaded ${decoded.length} ingredients from cache");
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    }
  } catch (e) {
    print("❌ Error loading from cache: $e");
  }
  
  return [];
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

     Map<String, double> tempUserIngredients = {};
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String name = data['ingredientsName'];
      double quantity = (data['quantity'] is int) 
          ? (data['quantity'] as int).toDouble()
          : (data['quantity'] as num).toDouble(); 
      
      tempUserIngredients.update(
        name, 
        (existingQuantity) => existingQuantity + quantity,
        ifAbsent: () => quantity,
      );

    }

    setState(() {
      userIngredientsMap = tempUserIngredients;
    });
    userIngredientsMap.forEach((name, total) {
     
    });

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

  Future<void> _loadInitialData() async {
  final cachedIngredients = await _getIngredientsFromCache();
  if (cachedIngredients.isNotEmpty) {
    setState(() {
      ingredientList = cachedIngredients;
      _isUsingCache = true;
    });
    print("✅ Using cached ingredients: ${cachedIngredients.length}");
  }
  
  _fetchIngredients(useCache: true);
}


  

  

  

  @override
void initState() {
  super.initState();
  _loadInitialData();
  _fetchUserIngredients();
  _searchController.addListener(() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {});
    });
  });
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
    ? const SizedBox() // ถ้าไม่มีการค้นหา ไม่แสดงอะไร
    : ListView.builder(
        itemCount: _searchIngredients(_searchController.text).length + 
                    (_searchController.text.isNotEmpty && 
                     _searchIngredients(_searchController.text).isEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          // กรณีไม่พบผลลัพธ์การค้นหา แสดงตัวเลือกเพิ่มใหม่
          if (_searchController.text.isNotEmpty && 
              _searchIngredients(_searchController.text).isEmpty && 
              index == 0) {
            return ListTile(
              contentPadding: const EdgeInsets.only(left: 10),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Add Ingredient to Shopping List',
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
                    'category': 'Fruits',
                    'unit': 'Kilograms (kg)',
                    'storage': 'Fridge',
                    'source': 'Supermarket',
                  },
                );
              },
            );
          }
          
          // กรณีพบผลลัพธ์การค้นหา แสดงรายการวัตถุดิบ
          final searchResults = _searchIngredients(_searchController.text);
          final ingredient = searchResults[index - (_searchController.text.isNotEmpty && 
                                                 searchResults.isEmpty ? 1 : 0)];
          
          return ListTile(
            leading: _buildIngredientImage(ingredient['imageUrl']),
            title: Text(ingredient['ingredientsName']!),
            onTap: () {
              _showIngredientPopup(context, ingredient);
            },
          );
        },
      ),
),
        ],
      ),
    ));
  }

  Widget _buildIngredientImage(String imagePath) {
  if (imagePath.startsWith('assets/')) {
    return Image.asset(
      imagePath,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
    );
  } else if (imagePath.isEmpty) {
    return Image.asset(
      'assets/images/default_ing.png',
      width: 40,
      height: 40,
      fit: BoxFit.cover,
    );
  } else {
    // ใช้ FutureBuilder แทนการสร้าง URL โดยตรง
    return FutureBuilder(
      future: _getDownloadUrl(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 40, 
            height: 40,
            color: Colors.grey[200],
            child: Icon(Icons.hourglass_empty, color: Colors.grey[400]),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          print("❌ Cannot load image for $imagePath: ${snapshot.error}");
          return Image.asset(
            'assets/images/default_ing.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          );
        }
        
        final imageUrl = snapshot.data as String;
        print("✅ Image URL generated: $imageUrl");
        
        return CachedNetworkImage(
          imageUrl: imageUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 40, 
            height: 40,
            color: Colors.grey[200],
            child: Icon(Icons.image, color: Colors.grey[400]),
          ),
          errorWidget: (context, url, error) {
            print("❌ CachedNetworkImage error: $error");
            return Image.asset(
              'assets/images/default_ing.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            );
          },
        );
      }
    );
  }
}

Future<String> _getDownloadUrl(String imagePath) async {
  try {
    if (!imagePath.toLowerCase().endsWith('.png') && !imagePath.toLowerCase().endsWith('.jpg')) {
      imagePath = '$imagePath.png';
    }
    
    String storagePath = imagePath.startsWith('ingredients/') ? imagePath : 'ingredients/$imagePath';
    print("🔍 Getting download URL for path: $storagePath");
    
    Reference ref = FirebaseStorage.instance.ref().child(storagePath);
    
    // ลองดึงข้อมูลเมต้าเพื่อตรวจสอบว่าไฟล์มีอยู่จริง
    try {
      await ref.getMetadata();
      print("✅ File exists at path: $storagePath");
    } catch (e) {
      print("⚠️ File metadata error (might not exist): $e");
    }
    
    String downloadUrl = await ref.getDownloadURL();
    print("✅ Got download URL: $downloadUrl");
    return downloadUrl;
  } catch (e) {
    // ถ้าเป็น .png แล้วไม่พบ ลองเปลี่ยนเป็น .jpg
    if (imagePath.toLowerCase().endsWith('.png')) {
      try {
        String jpgPath = imagePath.toLowerCase().replaceAll('.png', '.jpg');
        String storagePath = jpgPath.startsWith('ingredients/') ? jpgPath : 'ingredients/$jpgPath';
        print("🔄 Trying jpg path: $storagePath");
        
        Reference ref = FirebaseStorage.instance.ref().child(storagePath);
        String downloadUrl = await ref.getDownloadURL();
        print("✅ Got jpg download URL: $downloadUrl");
        return downloadUrl;
      } catch (e2) {
        print("❌ Also failed with jpg: $e2");
      }
    }
    
    throw e;
  }
}

  void _showIngredientPopup(BuildContext context, Map<String, dynamic> ingredient) {
    print("📸 Showing popup for: ${ingredient['ingredientsName']} with image: ${ingredient['imageUrl']}");
      
    double quantity = 1.0;
    TextEditingController priceController = TextEditingController();
    double ingredientKcal = 0.0;
  String originalUnit = '';
  bool isIngredientInDatabase = false;

   if (ingredient.containsKey('kcal') && ingredient['kcal'] != null) {
    isIngredientInDatabase = true;
    ingredientKcal = (ingredient['kcal'] is int)
        ? (ingredient['kcal'] as int).toDouble()
        : (ingredient['kcal'] as num?)?.toDouble() ?? 0.0;
    originalUnit = ingredient['unit'] ?? 'Pieces';
    
  }
  
    

    List<Map<String, dynamic>> userIngredients = userIngredientsMap.entries.map((entry) {
    return {
      'ingredientsName': entry.key,
      'quantity': entry.value,
    };
  }).toList();

   
  userIngredients.forEach((ing) {
    
  });

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

                String selectedCategory = ingredient['category'] ?? 'Fruits';
                String selectedUnit = ingredient['unit'] ?? 'Kilograms (kg)';
                String selectedStorage = ingredient['storage'] ?? 'Fridge';
                String selectedSource = ingredient['source'] ?? 'Supermarket'; 
double calculateKcal(double qty, String unit) {
  if (!isIngredientInDatabase) {
    print("⚠️ Ingredient not in database, kcal = 0");
    return 0.0;
  }
  
  print("🔢 Getting base kcal for ${unit}");
  
  // กรณีหน่วยเดียวกัน ใช้ค่า kcal เดิม
  if (unit == originalUnit) {
    print("✅ Same unit: returning base kcal ${ingredientKcal}");
    return ingredientKcal; // ไม่คูณกับปริมาณ
  }
  
  // กรณีหน่วยต่างกัน ต้องแปลงหน่วย
  switch (originalUnit) {
    // กรณี แปลงจาก kg เป็นหน่วยอื่น
    case 'Kilograms (kg)':
      if (unit == 'Grams (g)') {
        // 1 kg = 1000 g
        double result = ingredientKcal / 1000;
        print("✅ kg→g: ${ingredientKcal} kcal/kg ÷ 1000 = ${result} kcal/g");
        return result;
      }
      break;
      
    // กรณี แปลงจาก g เป็นหน่วยอื่น
    case 'Grams (g)':
      if (unit == 'Kilograms (kg)') {
        // 1000 g = 1 kg
        double result = ingredientKcal * 1000;
        print("✅ g→kg: ${ingredientKcal} kcal/g × 1000 = ${result} kcal/kg");
        return result;
      }
      break;
  }
  
  // กรณีไม่สามารถแปลงหน่วยได้
  print("⚠️ Unit conversion not supported: ${originalUnit} → ${unit}");
  print("⚠️ Returning original kcal: ${ingredientKcal}");
  return ingredientKcal; // ไม่คูณกับปริมาณ
}

 Widget buildImage() {
  if (ingredient['imageUrl'] == null || ingredient['imageUrl'].toString().isEmpty) {
    return Image.asset('assets/images/default_ing.png', width: 100, height: 100);
  } else if (ingredient['imageUrl'].toString().startsWith('assets/')) {
    return Image.asset(ingredient['imageUrl'], width: 100, height: 100);
  } else {
    // ใช้ FutureBuilder เหมือนกับใน _buildIngredientImage
    return FutureBuilder<String>(
      future: _getDownloadUrl(ingredient['imageUrl']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 100, 
            height: 100,
            color: Colors.grey[200],
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          print("❌ Error loading popup image: ${snapshot.error}");
          return Image.asset('assets/images/default_ing.png', width: 100, height: 100);
        }
        
        return CachedNetworkImage(
          imageUrl: snapshot.data!,
          width: 100,
          height: 100,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(
            width: 100, 
            height: 100, 
            color: Colors.grey[200],
            child: Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) {
            print("❌ Error loading popup image: $error");
            return Image.asset('assets/images/default_ing.png', width: 100, height: 100);
          },
        );
      }
    );
  }
}
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
               double calculatedKcal = calculateKcal(quantity, selectedUnit);
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
              child: buildImage(),
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
                    buildCustomDropdown('Category', categoryOptions, selectedCategory, (newValue) {
                      setDialogState(() => selectedCategory = newValue);
                    }),

                    buildCustomDropdown('Unit', unitOptions, selectedUnit, (newValue) {
                      setDialogState(() => selectedUnit = newValue);
                       calculatedKcal = calculateKcal(quantity, selectedUnit);
                    }),

                    buildCustomDropdown('Storage', storageOptions, selectedStorage, (newValue) {
                      setDialogState(() => selectedStorage = newValue);
                    }),
                    buildCustomDropdown('Source', sourceOptions, selectedSource, (newValue) {
                      setDialogState(() => selectedSource = newValue);
                    }),
                    _buildPriceField(priceController),
                    const SizedBox(height: 10),
                   ElevatedButton(
                  onPressed: () async {
                    double calculatedKcal = calculateKcal(quantity, selectedUnit);
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
                      'kcal': calculatedKcal,
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
                             'kcal': calculatedKcal,
                          });
                        });

                        print(
                            '✅ Added ${ingredient['ingredientsName']} to cart');
                        

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
                      child: const Text('Add to Shopping list',
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


Widget buildCustomDropdown(String title, List<String> itemList,
    String? currentValue, Function(String) onItemSelected) {
 
  final uniqueItems = itemList.toSet().toList();

  if (currentValue != null && !uniqueItems.contains(currentValue)) {
    currentValue = null;
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: title,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: uniqueItems.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: (newItem) => onItemSelected(newItem!),
    ),
  );
}

Future<Map<String, double>> _getIngredientStats(String ingredientName) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    // 1. Get usage history
    final usageQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userIngredients')
        .where('ingredientsName', isEqualTo: ingredientName)
        .get();

    double totalUsed = 0;
    int usageCount = 0;
    double wastedAmount = 0;

    for (var doc in usageQuery.docs) {
      Map<String, dynamic> data = doc.data();
      
      // Fix expiration date handling
      if (data['expirationDate'] != null) {
        DateTime? expirationDate;
        if (data['expirationDate'] is Timestamp) {
          expirationDate = (data['expirationDate'] as Timestamp).toDate();
        } else if (data['expirationDate'] is String) {
          expirationDate = DateTime.tryParse(data['expirationDate'] as String);
        }

        if (expirationDate != null && 
            expirationDate.isBefore(DateTime.now()) && 
            data['quantity'] != null) {
          double remainingQuantity = (data['quantity'] as num).toDouble();
          wastedAmount += remainingQuantity;
        }
      }

      // Calculate usage history
      List<dynamic> history = data['usageHistory'] ?? [];
      for (var usage in history) {
        totalUsed += (usage['quantity_used'] as num).toDouble();
        usageCount++;
      }
    }

    final purchaseQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('historyCart')
        .where('ingredientsName', isEqualTo: ingredientName)
        .get();

    double avgPurchaseQty = 0;
    if (purchaseQuery.docs.isNotEmpty) {
      double totalPurchased = purchaseQuery.docs
          .fold(0.0, (sum, doc) => sum + (doc.data()['quantity'] as num).toDouble());
      avgPurchaseQty = totalPurchased / purchaseQuery.docs.length;
    }

    return {
      'avgUsagePerTime': usageCount > 0 ? totalUsed / usageCount : 0,
      'avgPurchaseQty': avgPurchaseQty,
      'wastedAmount': wastedAmount,
    };
  } catch (e) {
    print('❌ Error calculating stats: $e');
    return {};
  }
}

// Quantity Selector Widget (+ -)
Widget _buildQuantitySelector(
  Map<String, dynamic> ingredient,
  List<Map<String, dynamic>> userIngredients,
  double quantity,
  Function(double) onQuantityChanged,
) {
  return FutureBuilder<Map<String, double>>(
    future: _getIngredientStats(ingredient['ingredientsName']),
    builder: (context, snapshot) {
      double totalQuantity = userIngredients
          .where((item) => item['ingredientsName'].toLowerCase() == 
                         ingredient['ingredientsName'].toLowerCase())
          .fold(0.0, (sum, item) {
            final itemQuantity = (item['quantity'] is int)
                ? (item['quantity'] as int).toDouble()
                : (item['quantity'] as num).toDouble();
            return sum + itemQuantity;
          });

      double minQuantity = (ingredient['minQuantity'] as num?)?.toDouble() ?? 1.0;
      double recommendedQuantity = 1.0;

      if (snapshot.hasData) {
        double avgUsage = snapshot.data!['avgUsagePerTime'] ?? 0;
        double avgPurchase = snapshot.data!['avgPurchaseQty'] ?? 0;
        double wastedAmount = snapshot.data!['wastedAmount'] ?? 0;

       // คำนวณ recommendedQuantity ใหม่
  if (totalQuantity <= minQuantity) {
    // กรณีของเหลือน้อยกว่าหรือเท่ากับค่าขั้นต่ำ
    if (avgUsage > 0) {
      // ถ้ามีประวัติการใช้ ให้ซื้อเผื่อไว้ใช้ 2 ครั้ง
      recommendedQuantity = (avgUsage * 2);
    } else {
      // ถ้าไม่มีประวัติการใช้ ใช้ค่าเฉลี่ยการซื้อ
      recommendedQuantity = avgPurchase > 0 ? avgPurchase : minQuantity;
    }
  } else {
    // กรณีของยังเหลือมากกว่าค่าขั้นต่ำ
    if (avgUsage > 0) {
      // คำนวณจากอัตราการใช้
      double neededAmount = (avgUsage * 2) - totalQuantity;
      recommendedQuantity = neededAmount > 0 ? neededAmount : avgUsage;
    } else {
      // ไม่มีประวัติการใช้ ใช้ค่าเฉลี่ยการซื้อ
      recommendedQuantity = avgPurchase;
    }
  }

  // ปรับตามประวัติของเสีย
  if (wastedAmount > 0) {
    recommendedQuantity *= 0.8; // ลด 20% ถ้ามีประวัติของเสีย
  }

  // ต้องไม่ต่ำกว่าค่าขั้นต่ำที่กำหนด
  if (recommendedQuantity < minQuantity) {
    recommendedQuantity = minQuantity;
  }

  // ปัดเศษขึ้น
  recommendedQuantity = recommendedQuantity.ceilToDouble();
} else {
  // กรณีไม่มีข้อมูลประวัติ
  recommendedQuantity = minQuantity > totalQuantity 
      ? (minQuantity - totalQuantity).ceilToDouble()
      : minQuantity;
}

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
                    Text(
                      quantity.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    IconButton(
                      onPressed: () => onQuantityChanged(quantity + 1),
                      icon: const Icon(Icons.add, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
            if (totalQuantity > 0)
              Row(
                children: [
                  Image.asset(
                    'assets/images/about.png',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$totalQuantity ${ingredient['unit']} in stock',  
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              'Recommended purchase: ${recommendedQuantity.toStringAsFixed(1)} ${_formatUnit(ingredient['unit'])}',
              style: TextStyle(
                fontSize: 16,
                 color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    },
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
