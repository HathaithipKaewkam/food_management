import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ExpiredItemsScreen extends StatefulWidget {
  const ExpiredItemsScreen({super.key});

  @override
  State<ExpiredItemsScreen> createState() => _ExpiredItemsScreenState();
}

class _ExpiredItemsScreenState extends State<ExpiredItemsScreen> {
  List<String> ingredientTypes = ['All', 'Fridge', 'Pantry', 'Freezer'];
  TextEditingController searchController = TextEditingController();
  List<Ingredient> ingredientList = [];
  List<Ingredient> filteredExpiredItems = [];
  String selectedType = 'All';
  int selectedCategoryIndex = 0;
  bool isLoading = true;
  StreamSubscription<QuerySnapshot>? _ingredientSubscription;
  Map<int, String> ingredientDocIds = {};

  @override
  void initState() {
    super.initState();
    fetchUserIngredients();
    setupIngredientListener();
  }

  @override
  void dispose() {
    _ingredientSubscription?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchUserIngredients() async {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user != null) {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userIngredients')
          .get();

      // กำหนด ingredientDocIds หลังจากได้ snapshot แล้ว
      int index = 0;
      ingredientDocIds.clear();
      for (var doc in snapshot.docs) {
        String docId = doc.id;
        ingredientDocIds[index] = docId;
        index++;
      }
      
      setState(() {
        ingredientList = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          String docId = doc.id;
          print("Document ID: $docId"); // เพิ่ม log
          data['ingredientId'] = docId;
          
          Ingredient ingredient = Ingredient.fromJson(data);
          print("Ingredient ID after creation: ${ingredient.ingredientId}"); // เพิ่ม log
          
          return ingredient;
        }).toList();

        filterExpiredIngredients();
        isLoading = false;
      });

      print("✅ Fetched ${snapshot.docs.length} ingredients");
    } catch (e) {
      print("Error fetching ingredients: $e");
      setState(() {
        isLoading = false;
      });
    }
  }
}

// แก้ไขฟังก์ชัน setupIngredientListener ดังนี้
void setupIngredientListener() {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user != null) {
    _ingredientSubscription?.cancel();

    _ingredientSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userIngredients')
        .snapshots()
        .listen((snapshot) {
      // กำหนด ingredientDocIds ภายใน callback
      int index = 0;
      ingredientDocIds.clear();
      for (var doc in snapshot.docs) {
        String docId = doc.id;
        ingredientDocIds[index] = docId;
        index++;
      }
      
      setState(() {
        ingredientList = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          data['ingredientId'] = doc.id;
          return Ingredient.fromJson(data);
        }).toList();

        filterExpiredIngredients();
      });
    });
  }
}

  void filterExpiredIngredients() {
  setState(() {
    DateTime now = DateTime.now();
    List<Ingredient> expiredIngredients = ingredientList.where((ingredient) {
      return ingredient.expirationDate.isBefore(now) && ingredient.quantity > 0;
    }).toList();

    if (selectedType == 'All') {
      filteredExpiredItems = expiredIngredients;
    } else {
      filteredExpiredItems = expiredIngredients.where((ingredient) {
        return ingredient.storage == selectedType;
      }).toList();
    }
    filteredExpiredItems.sort((a, b) {
      return a.expirationDate.compareTo(b.expirationDate);
    });
  });
}

  void searchExpiredIngredients(String query) {
  setState(() {
    if (query.isEmpty) {
      filterExpiredIngredients();
    } else {
      DateTime now = DateTime.now();
      List<Ingredient> searchResults = ingredientList.where((ingredient) {
        bool matchesSearch = ingredient.ingredientsName
            .toLowerCase()
            .contains(query.toLowerCase());
        bool matchesType =
            selectedType == 'All' || ingredient.storage == selectedType;
        bool isExpired = ingredient.expirationDate.isBefore(now);
        bool hasQuantity = ingredient.quantity > 0; 
        
        return matchesSearch && matchesType && isExpired && hasQuantity;
      }).toList();

      searchResults.sort((a, b) {
        return a.expirationDate.compareTo(b.expirationDate);
      });

      filteredExpiredItems = searchResults;
    }
  });
}

  // ปรับฟังก์ชัน deleteItem
Future<void> deleteItem(String? itemId) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: User is not logged in");
      return;
    }

    if (itemId == null || itemId.isEmpty) {
      print("Error: Item ID is empty or null");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Cannot delete item with empty ID'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    print("Attempting to delete item with ID: $itemId");
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userIngredients')
        .doc(itemId)
        .delete();

    print("Item deleted successfully");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item deleted from inventory'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  } catch (e) {
    print("Error deleting item: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


Future<void> throwItem(String? itemId) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: User is not logged in");
      return;
    }

    if (itemId == null || itemId.isEmpty) {
      print("Error: Item ID is empty or null");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Cannot throw item with empty ID'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    print("Attempting to mark item as throw with ID: $itemId");
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userIngredients')
        .doc(itemId)
        .update({
          'isThrowed': true,
          'quantity': 0, 
        });

    print("Item marked as thrown successfully");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item thrown from inventory'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  } catch (e) {
    print("Error throwing item: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 30, left: 5, right: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                  color: Colors.black,
                  iconSize: 20,
                ),
                const SizedBox(width: 5),
                const Text(
                  'Expired Ingredients',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.only(left: 19),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    width: size.width * .90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.black54.withOpacity(.6),
                        ),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            showCursor: true,
                            onChanged: (value) {
                              searchExpiredIngredients(value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search Expired Items',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        if (searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              searchController.clear();
                              searchExpiredIngredients('');
                            },
                            child: Icon(
                              Icons.clear,
                              color: Colors.black54.withOpacity(.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                
                ],
              ),
            ),

            const SizedBox(height: 15),
            
            // Category Selector
            SizedBox(
              height: 120,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: ingredientTypes.length,
                itemBuilder: (BuildContext context, int index) {
                  List<String> ingredientTypeImages = [
                    'assets/images/all.png',
                    'assets/images/fridge.png',
                    'assets/images/pantry.png',
                    'assets/images/freezer.png',
                  ];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategoryIndex = index;
                        selectedType = ingredientTypes[index];
                        filterExpiredIngredients();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: selectedCategoryIndex == index
                            ? const Color.fromARGB(255, 247, 201, 200) 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            ingredientTypeImages[index],
                            height: 55,
                            width: 55,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 55,
                                width: 55,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ingredientTypes[index],
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // ส่วนแสดงรายการหรือข้อความว่างเปล่า
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredExpiredItems.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 120),
                          child: Center(
                            child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 80,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No expired items found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                searchController.text.isNotEmpty
                                    ? 'Try different search terms'
                                    : selectedType != 'All'
                                        ? 'No expired items in $selectedType'
                                        : 'All your ingredients are still fresh!',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              )],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredExpiredItems.length,
                          itemBuilder: (context, index) {
                            final ingredient = filteredExpiredItems[index];
                            Color cardColor = Colors.white;
                            String safeKey = ingredient.ingredientId?.isNotEmpty == true
                              ? ingredient.ingredientId!
                              : 'item_$index';
                           return GestureDetector(
                              onLongPress: () {
                                // แสดงกล่องโต้ตอบเมื่อกดค้าง (สำหรับการลบออกจากระบบ)
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Permanently delete'),
                                      content: const Text(
                                          'Are you sure you want to delete this item from your inventory? This action cannot be undone.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            
                                            int originalIndex = -1;
                                            for (int i = 0; i < ingredientList.length; i++) {
                                              if (ingredientList[i].ingredientsName == ingredient.ingredientsName &&
                                                  ingredientList[i].expirationDate == ingredient.expirationDate) {
                                                originalIndex = i;
                                                break;
                                              }
                                            }
                                            
                                            setState(() {
                                              filteredExpiredItems.remove(ingredient);
                                            });
                                            
                                            if (originalIndex >= 0 && ingredientDocIds.containsKey(originalIndex)) {
                                              String docId = ingredientDocIds[originalIndex]!;
                                              deleteItem(docId);
                                              
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Item permanently deleted from inventory'),
                                                  backgroundColor: Colors.red,
                                                  duration: Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          },
                                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              // ใน child ใส่ Dismissible เดิม แต่แก้ไขข้อความให้สื่อถึงการทิ้งวัตถุดิบ
                              child: Dismissible(
                                key: Key(safeKey),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.delete_outline, color: Colors.white),  // เปลี่ยนไอคอนเป็น delete_outline
                                      SizedBox(height: 4),
                                      Text(
                                        'Throw',  
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Confirm discarding'),
                                        content: const Text(
                                            'Are you sure you want to throw this expired item?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text('Throw', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                onDismissed: (direction) {
                                  int originalIndex = -1;
                                  for (int i = 0; i < ingredientList.length; i++) {
                                    if (ingredientList[i].ingredientsName == ingredient.ingredientsName &&
                                        ingredientList[i].expirationDate == ingredient.expirationDate) {
                                      originalIndex = i;
                                      break;
                                    }
                                  }
                                  
                                  setState(() {
                                    filteredExpiredItems.remove(ingredient);
                                  });
                                  
                                  if (originalIndex >= 0 && ingredientDocIds.containsKey(originalIndex)) {
                                    String docId = ingredientDocIds[originalIndex]!;
                                    throwItem(docId);  
                                  } else {
                                  }
                                },
                              child: Card(
                                elevation: 2,
                                color: cardColor,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.red.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // รูปสินค้า
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: ingredient.imageUrl.isNotEmpty
                                            ? Image.network(
                                                ingredient.imageUrl,
                                                width: 70,
                                                height: 70,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  print("Image error: $error");
                                                  return Container(
                                                    width: 70,
                                                    height: 70,
                                                    color: Colors.grey.shade300,
                                                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                                  );
                                                },
                                              )
                                            : Container(
                                                width: 70,
                                                height: 70,
                                                color: Colors.grey.shade300,
                                                child: Icon(
                                                  Icons.restaurant,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    ingredient.ingredientsName,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                              '${ingredient.quantity} ${_formatUnit(ingredient.unit)}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                               
                                              ],
                                            ),
                                            
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Exp: ${DateFormat('dd/MM/yyyy').format(ingredient.expirationDate)}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                Text(
                                                    ingredient.storage,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black54,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ));
                          },
                        ),
            )] ) ) );

  }
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
