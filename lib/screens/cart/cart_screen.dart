import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/cart/auto_shoppinglist.dart';
import 'package:food_project/screens/cart/history_buy.dart';
import 'package:food_project/screens/cart/search_cart.dart';
import 'package:food_project/widgets/cart_widget.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> addedToCartIngredients;

  const CartScreen({Key? key, this.addedToCartIngredients = const []})
      : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];
  List<Ingredient> ingredientList = [];
  bool isLoading = true;
  bool markAllSelected = false;
  StreamSubscription<QuerySnapshot>? _cartSubscription;

  @override
  void initState() {
    fetchUserCart();
    super.initState();
    cartItems = List<Map<String, dynamic>>.from(widget.addedToCartIngredients);
    setupCartListener();
  }

  void setupCartListener() {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    _cartSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userCart')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        cartItems = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['docId'] = doc.id;
          return data;
        }).toList();
        isLoading = false;
      });
    });
  }
}


  Future<void> fetchUserCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('userCart')
            .get();

        print("✅ Fetched ${snapshot.docs.length} ingredients.");

        setState(() {
          cartItems = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            data['docId'] = doc.id; // เพิ่ม docId เข้าไปในข้อมูล
            return data;
          }).toList();

          isLoading = false;
        });
        print("🎉 Fetch complete! isLoading: $isLoading");
      } catch (e) {
        print("Error fetching ingredients: $e");
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  double getTotalPrice(List<Map<String, dynamic>> cartItems) {
    double total = 0;
    for (var item in cartItems) {
      total += item['price'] ?? 0;
    }
    return total;
  }

  
Future<void> onMarkAllPurchased(bool isPurchased) async {
  try {
    setState(() {
      markAllSelected = isPurchased; 
      for (var item in cartItems) {
        final docId = item['docId'];
        if (docId != null) {
          _togglePurchased(docId, isPurchased);
          item['purchased'] = isPurchased;
        }
      }
    });
    print("✅ All items marked as ${isPurchased ? 'purchased' : 'unpurchased'}");
  } catch (e) {
    print("❌ Error marking all items: $e");
  }
}

  Future<void> _togglePurchased(String docId, bool isPurchased) async {
  String uid = FirebaseAuth.instance.currentUser!.uid;

  try {
    setState(() {
      var item = cartItems.firstWhere((item) => item['docId'] == docId);
      item['purchased'] = isPurchased;
      
      if (!isPurchased) {
        markAllSelected = false;
      }
    });

    // Then update Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('userCart')
        .doc(docId)
        .update({
      'purchased': isPurchased,
      'purchaseDate': isPurchased ? FieldValue.serverTimestamp() : null,
    });

    // Handle purchase history
    if (!isPurchased) {
      // Remove from purchase history
      QuerySnapshot purchaseHistory = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('purchaseHistory')
          .where('itemId', isEqualTo: docId)
          .get();

      for (var doc in purchaseHistory.docs) {
        await doc.reference.delete();
      }
      print("✅ Removed item from purchaseHistory: $docId");
    } else {
      // Add to purchase history
      DocumentSnapshot cartItem = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('userCart')
          .doc(docId)
          .get();

      if (cartItem.exists) {
        Map<String, dynamic> cartData = cartItem.data() as Map<String, dynamic>;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('purchaseHistory')
            .add({
          'itemId': docId,
          'purchaseDate': FieldValue.serverTimestamp(),
          'price': cartData['price'],
          'quantity': cartData['quantity'],
          'source': cartData['source'],
          'unit': cartData['unit'],
          'ingredientsName': cartData['ingredientsName'],
          'imageUrl': cartData['imageUrl'],
          'category': cartData['category']
        });
        print("✅ Added item to purchaseHistory: $docId");
      }
    }

    print("✅ Updated item: $docId, Purchased: $isPurchased");
  } catch (e) {
    // Revert local state on error
    setState(() {
      var item = cartItems.firstWhere((item) => item['docId'] == docId);
      item['purchased'] = !isPurchased;
    });
    print("❌ Error updating item: $e");
  }
}




  Future<void> _deleteAllItems() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      var cartCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('userCart');

      var snapshot = await cartCollection.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print("✅ All items deleted successfully.");
    } catch (e) {
      print("❌ Error deleting items: $e");
    }
  }

  Future<void> _moveToStorage(String docId, Map<String, dynamic> item) async {
  String uid = FirebaseAuth.instance.currentUser!.uid;
  DateTime now = DateTime.now();
  DateTime expirationDate = now.add(Duration(days: 7));

  var userIngredientsRef = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('userIngredients');

   String imageUrl = item['imageUrl'] ?? '';
  String imageUrlToStore = '';
 try {
    // กรณีที่ URL เป็น URL แบบเต็ม (http)
    if (imageUrl.startsWith('http')) {
      // เก็บ URL เต็มเลย
      imageUrlToStore = imageUrl;
      print("🔍 Using existing full URL: $imageUrlToStore");
    }
    // กรณีที่ URL เป็น asset
    else if (imageUrl.startsWith('assets/')) {
      // เก็บ path ของ asset เลย
      imageUrlToStore = imageUrl;
      print("🔍 Using asset path: $imageUrlToStore");
    }
    // กรณีที่เป็น path แบบสัมพัทธ์
    else if (imageUrl.isNotEmpty) {
      // ใช้ฟังก์ชัน _getDownloadUrl เพื่อดึง URL จริงจาก Firebase Storage
      try {
        String fullUrl = await _getDownloadUrl(imageUrl);
        if (fullUrl.startsWith('http')) {
          // ถ้าดึง URL สำเร็จ ให้เก็บ URL เต็ม
          imageUrlToStore = fullUrl;
          print("✅ Fetched full download URL: $imageUrlToStore");
        } else {
          // ถ้าไม่สำเร็จ แต่ได้ default image กลับมา
          imageUrlToStore = 'assets/images/default_ing.png';
          print("⚠️ Using default image instead");
        }
      } catch (e) {
        // กรณีมีข้อผิดพลาดในการดึง URL
        print("❌ Error fetching download URL: $e");
        imageUrlToStore = 'assets/images/default_ing.png';
      }
    } else {
      // กรณีไม่มี URL
      imageUrlToStore = 'assets/images/default_ing.png';
    }
  } catch (e) {
    print("❌ General error processing image URL: $e");
    imageUrlToStore = 'assets/images/default_ing.png';
  }

  // Query for existing ingredient with same name AND storage
  var existingIngredientSnapshot = await userIngredientsRef
      .where('ingredientsName', isEqualTo: item['ingredientsName'])
      .where('storage', isEqualTo: item['storage'])
      .get();

  try {
    // ตรวจสอบว่ามีค่า kcal ในรายการนี้หรือไม่
    double kcalValue = 0.0;
    if (item.containsKey('kcal') && item['kcal'] != null) {
      kcalValue = (item['kcal'] is int)
          ? (item['kcal'] as int).toDouble()
          : (item['kcal'] as num?)?.toDouble() ?? 0.0;
      
      // ลบการคำนวณที่หารด้วยจำนวนออก
      // ใช้ค่า kcal จาก userCart โดยตรง
    }
    
    print("🔢 Item kcal value directly: $kcalValue for ${item['ingredientsName']}");
    
    if (existingIngredientSnapshot.docs.isNotEmpty) {
      var existingDoc = existingIngredientSnapshot.docs.first;
      var existingData = existingDoc.data();
      var currentQuantity = existingData['quantity'] ?? 0;
      
      // ถ้ามีค่า kcal ใหม่ใช้ค่าใหม่ ถ้าไม่มีใช้ค่าเดิม
      double finalKcal = kcalValue > 0 ? kcalValue : 
                       (existingData['kcal'] is num ? (existingData['kcal'] as num).toDouble() : 0.0);
      
      print("📊 Updating existing ingredient with kcal: $finalKcal");
      
      await existingDoc.reference.update({
        'quantity': currentQuantity + item['quantity'],
        'updateDate': now,
        'expirationDate': expirationDate,
        'price': item['price'],
        'kcal': finalKcal,
         'imageUrl': imageUrlToStore,
      });
      
      print("✅ Updated existing ingredient in ${item['storage']} with kcal: $finalKcal");
    } else {
      await userIngredientsRef.add({
        'ingredientsName': item['ingredientsName'],
        'quantity': item['quantity'],
        'createDate': now,
        'expirationDate': expirationDate,
        'minQuantity': 1,
        'allergenInfo': item['allergenInfo'] ?? [],
        'price': item['price'],
         'imageUrl': imageUrlToStore,
        'category': item['category'],
        'unit': item['unit'],
        'storage': item['storage'],
        'source': item['source'],
        'updateDate': now,
        'kcal': kcalValue, // ใช้ค่า kcal โดยตรง ไม่ผ่านการคำนวณ
        'usageHistory': [],
      });
      print("🧾 Moving item with imageUrl: ${item['imageUrl']}");

      print("✅ Added new ingredient in ${item['storage']} with kcal: $kcalValue");
    }

    await _addToPurchaseHistory(docId, item);
    await _removeFromUserCart(docId);
    await _addToIngredientsHistory(item);

  } catch (e) {
    print("❌ Error moving item to storage: $e");
    throw e;
  }
}


Future<String> _getDownloadUrl(String imagePath) async {
  try {
    // ถ้าเป็น path เต็มแล้ว
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    
    // ถ้าเป็น asset
    if (imagePath.startsWith('assets/')) {
      return imagePath;
    }
    
    // เพิ่มนามสกุลไฟล์ถ้าไม่มี
    if (!imagePath.toLowerCase().endsWith('.png') && 
        !imagePath.toLowerCase().endsWith('.jpg') && 
        !imagePath.toLowerCase().endsWith('.jpeg')) {
      imagePath = '$imagePath.png';
    }
    
    // ปรับ path ให้ถูกต้อง
    String storagePath = imagePath.startsWith('ingredients/') ? imagePath : 'ingredients/$imagePath';
    print("🔍 Getting download URL for path: $storagePath");
    
    // ทดสอบว่าไฟล์มีอยู่จริงหรือไม่
    try {
      Reference ref = FirebaseStorage.instance.ref().child(storagePath);
      await ref.getMetadata(); // ถ้าไฟล์ไม่มีอยู่จะ throw error
      String downloadUrl = await ref.getDownloadURL();
      print("✅ Got download URL: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("⚠️ File might not exist, trying alternatives: $e");
      
      // ลองดูว่าถ้าเปลี่ยน .png เป็น .jpg จะได้หรือไม่
      if (storagePath.toLowerCase().endsWith('.png')) {
        try {
          String jpgPath = storagePath.toLowerCase().replaceAll('.png', '.jpg');
          Reference jpgRef = FirebaseStorage.instance.ref().child(jpgPath);
          String jpgUrl = await jpgRef.getDownloadURL();
          print("✅ Found JPG alternative: $jpgUrl");
          return jpgUrl;
        } catch (e2) {
          print("❌ JPG alternative also failed: $e2");
        }
      }
      
      // ลองใช้ชื่อย่อ (ไม่มี path ingredients/)
      try {
        String baseFileName = imagePath.contains('/') 
            ? imagePath.split('/').last 
            : imagePath;
            
        Reference baseRef = FirebaseStorage.instance.ref().child(baseFileName);
        String baseUrl = await baseRef.getDownloadURL();
        print("✅ Found with base name: $baseUrl");
        return baseUrl;
      } catch (e3) {
        print("❌ Base name search failed: $e3");
      }
      
      // ถ้าไม่สำเร็จเลย ให้ใช้รูป default
      return 'assets/images/default_ing.png';
    }
  } catch (e) {
    print("❌ Error in _getDownloadUrl: $e");
    return 'assets/images/default_ing.png';
  }
}

Future<void> _addToPurchaseHistory(String docId, Map<String, dynamic> item) async {
  String uid = FirebaseAuth.instance.currentUser!.uid;
  var userCartRef = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('userCart')
      .doc(docId);

  try {
    // เพิ่มข้อมูลใน purchaseHistory
    await userCartRef.update({
      'purchaseHistory': FieldValue.arrayUnion([{
        'moveToStorageDate': DateTime.now(),
        'itemDetails': item,
      }]),
    });
    print("✅ Item added to purchase history.");
  } catch (e) {
    print("❌ Error adding to purchase history: $e");
  }
}

Future<void> _removeFromUserCart(String docId) async {
  String uid = FirebaseAuth.instance.currentUser!.uid;
  var userCartRef = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('userCart')
      .doc(docId);

  try {
    // ลบข้อมูลจาก userCart
    await userCartRef.delete();
    print("✅ Item removed from userCart.");
  } catch (e) {
    print("❌ Error removing item from userCart: $e");
  }
}


Future<void> _addToIngredientsHistory(Map<String, dynamic> item) async {
  String uid = FirebaseAuth.instance.currentUser!.uid;
  DateTime now = DateTime.now();

  double kcalValue = 0.0;
  if (item.containsKey('kcal') && item['kcal'] != null) {
    kcalValue = (item['kcal'] is int)
        ? (item['kcal'] as int).toDouble()
        : (item['kcal'] as num?)?.toDouble() ?? 0.0;
  }

  var ingredientsHistoryRef = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('ingredientsHistory');

  try {
    await ingredientsHistoryRef.add({
      'ingredientsName': item['ingredientsName'],
      'quantityAdded': item['quantity'], 
      'addedDate': now,  
      'category': item['category'],  
      'imageUrl': item['imageUrl'],  
      'storage': item['storage'],  
      'source': item['source'], 
      'unit': item['unit'], 
      'kcal': kcalValue, 
    });
    print("✅ Item added to ingredientsHistory with kcal: $kcalValue");
  } catch (e) {
    print("❌ Error adding to ingredientsHistory: $e");
  }
}

@override
void dispose() {
  _cartSubscription?.cancel();
  super.dispose();
}



  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
        body: user == null
            ? Center(child: Text('User not logged in'))
            : isLoading 
            ? Center(child: CircularProgressIndicator())
            : Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 35, left: 12, right: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              'Shopping list',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchCartScreen(
                                        addedToCartIngredients: []),
                                  ),
                                );
                              },
                              icon: Icon(Icons.add_shopping_cart),
                              color: Colors.black,
                              iconSize: 25,
                            ),
                             IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AutoShoppingList(),
                                  ),
                                );
                              },
                              icon: Icon(Icons.tips_and_updates),
                              color: Colors.black,
                              iconSize: 25,
                            ),
                            IconButton(
                              onPressed: () {
                                 Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HistoryBuy(),
                                  ),
                                );
                              },
                              icon: Icon(Icons.history),
                              color: Colors.black,
                              iconSize: 25,
                            ),
                            PopupMenuButton<String>(
                              onSelected: (String value) async {
                                if (value == 'Mark all as bought') {
                                  onMarkAllPurchased(true);
                                } else if (value == 'Delete all') {
                                  bool? confirmDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Confirm Deletion"),
                                        content: Text(
                                            "Are you sure you want to delete all items?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(false);
                                            },
                                            child: Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(true);
                                            },
                                            child: Text("Delete",
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (confirmDelete == true) {
                                    await _deleteAllItems();

                                    setState(() {
                                      cartItems.clear();
                                    });
                                  }
                                }
                               else if (value == 'Move to storage') { 
  List<Map<String, dynamic>> itemsToMove = [];
  for (var item in cartItems) {
    if (item['purchased'] == true) {
      itemsToMove.add(Map<String, dynamic>.from(item));
    }
  }
  
  for (var item in itemsToMove) {
    try {
      await _moveToStorage(item['docId'], item);
      print("✅ Moved ${item['ingredientsName']} from ${item['storage']} to storage successfully");
    } catch (e) {
      print("❌ Failed to move ${item['ingredientsName']} from ${item['storage']}: $e");
    }
  }
} else if (value == 'Move all items to storage') { 
  // ดึงรายการที่ถูกเลือกทั้งหมดออกมาก่อน
  List<Map<String, dynamic>> itemsToMove = [];
  for (var item in cartItems) {
    if (item['purchased'] == true) {
      itemsToMove.add(Map<String, dynamic>.from(item));
    }
  }
  
  // ทำการย้ายทีละรายการ
  for (var item in itemsToMove) {
    try {
      await _moveToStorage(item['docId'], item);
      print("✅ Moved ${item['ingredientsName']} from ${item['storage']} to storage successfully");
    } catch (e) {
      print("❌ Failed to move ${item['ingredientsName']} from ${item['storage']}: $e");
    }
  }
}
                              },
                              icon: Icon(Icons.more_horiz,
                                  color: Colors.black, size: 25),
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  value: 'Mark all as bought',
                                  child: Text('Mark all as bought'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Move to storage',
                                  child: Text('Move to storage'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Move all items to storage',
                                  child: Text('Move all items to storage'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Delete all',
                                  child: DefaultTextStyle(
                                    style: TextStyle(color: Colors.red),
                                    child: Text('Delete all'),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      if (cartItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 90),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 40),
                                child: Image.asset(
                                  'assets/images/cart.png',
                                  height: 280,
                                  width: 300,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Nothing here yet!',
                                style: TextStyle(
                                  color: Color(0xFF094507),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Let\'s add some items to stay organized',
                                style: TextStyle(
                                  color: Color(0xFF094507),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 40),
                              // ปุ่ม Add Items
                              Center(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final List<Ingredient>? addedItems =
                                        await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SearchCartScreen(
                                          addedToCartIngredients: cartItems,
                                        ),
                                      ),
                                    );

                                    if (addedItems != null &&
                                        addedItems.isNotEmpty) {
                                      setState(() {
                                        cartItems.addAll(
                                            addedItems.map((ingredient) => {
                                                  'ingredientsName': ingredient
                                                      .ingredientsName,
                                                  'imageUrl':
                                                      ingredient.imageUrl,
                                                  'unit': ingredient.unit,
                                                  'storage': ingredient.storage,
                                                  'source': ingredient.source,
                                                  'quantity':
                                                      ingredient.quantity,
                                                  'price': ingredient.price,
                                                }));
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF325b51),
                                    minimumSize: const Size(50, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15, horizontal: 80),
                                  ),
                                  child: const Text(
                                    'ADD ITEMS',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 5, left: 15, right: 10,),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                              const Text(
                                'Total',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 230),
                              Text(
                                '${getTotalPrice(cartItems).toStringAsFixed(2)} ฿',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total items',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 250),
                              Text(
                                '${cartItems.length}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),   
                      Expanded(
                        child: Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: cartItems.length,
                          itemBuilder: (BuildContext context, int index) {
                            final ingredient = cartItems[index];
                            return GestureDetector(
                              onTap: () {
                                _showEditDialog(
                                    context, ingredient, index, cartItems);
                              },
                              child: CartWidget(
                                cartItems: [ingredient],
                                onPurchasedChanged:
                                    (String docId, bool isPurchased) async {
                                  await _togglePurchased(docId, isPurchased);
                                  setState(() {
                                    ingredient['purchased'] = isPurchased;
                                  });
                                },
                                onMarkAllPurchased: onMarkAllPurchased,  
                                isMarkAllSelected: markAllSelected,
                              ),
                            );
                          },
                        ),
                      ),
                      ),
                    
                 ]
                 ) 
                 );
                }
  }


void _showEditDialog(BuildContext context, Map<String, dynamic> ingredient,
    int index, List<Map<String, dynamic>> cartItems) {
  double quantity = (ingredient['quantity'] is int)
      ? (ingredient['quantity'] as int).toDouble()
      : (ingredient['quantity'] as num).toDouble();
  TextEditingController quantityController =
      TextEditingController(text: quantity.toStringAsFixed(1));
  TextEditingController priceController =
      TextEditingController(text: ingredient['price'].toString());

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
    'Spices'
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
    'Cob'
  ];
  List<String> storageOptions = ['Fridge', 'Freezer', 'Pantry'];
  List<String> sourceOptions = ['Supermarket', 'Market', 'Online', 'Homegrown'];

  String selectedCategory = ingredient['category'] ?? categoryOptions[0];
  String selectedUnit = ingredient['unit'] ?? unitOptions[0];
  String selectedStorage = ingredient['storage'] ?? storageOptions[0];
  String selectedSource = ingredient['source'] ?? sourceOptions[0];

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Text(
                    ingredient['ingredientsName'].isNotEmpty
                        ? ingredient['ingredientsName'][0].toUpperCase() +
                            ingredient['ingredientsName']
                                .substring(1)
                                .toLowerCase()
                        : '',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Quantity input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: quantity > 1
                                ? () {
                                    setState(() => quantity -= 1);
                                    quantityController.text =
                                        quantity.toString();
                                  }
                                : null,
                            icon: const Icon(Icons.remove, color: Colors.red),
                          ),
                          SizedBox(
                            width: 50,
                            child: TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder()),
                              onTap: () {
                                setState(() {
                                  quantityController.clear();
                                });
                              },
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                              double? parsedValue = double.tryParse(value);
                              if (parsedValue != null) {
                                setState(() {
                                  quantity = parsedValue;
                                  ingredient['quantity'] = quantity;
                                  cartItems[index]['quantity'] = quantity;
                                });
                                }
                              }
                                }
                                ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                quantity += 1;
                                quantityController.text = quantity.toString();
                              });
                            },
                            icon: const Icon(Icons.add, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Price input
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price'),
                    onTap: () {
                      setState(() {
                        priceController.clear();
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  // Category dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: categoryOptions.map((category) {
                      return DropdownMenuItem(
                          value: category, child: Text(category));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),

                  const SizedBox(height: 10),

                  // Unit dropdown
                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    items: unitOptions.map((unit) {
                      return DropdownMenuItem(value: unit, child: Text(unit));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedUnit = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),

                  const SizedBox(height: 10),

                  // Storage dropdown
                  DropdownButtonFormField<String>(
                    value: selectedStorage,
                    items: storageOptions.map((storage) {
                      return DropdownMenuItem(
                          value: storage, child: Text(storage));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStorage = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Storage'),
                  ),

                  const SizedBox(height: 10),

                  // Source dropdown
                  DropdownButtonFormField<String>(
                    value: selectedSource,
                    items: sourceOptions.map((source) {
                      return DropdownMenuItem(
                          value: source, child: Text(source));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSource = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Source'),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100),
                    onPressed: () async {
                      double price = double.tryParse(priceController.text) ??
                          ingredient['price'];

                      setState(() {
                        cartItems[index] = {
                          ...ingredient,
                          'quantity': quantity,
                          'price': price,
                          'category': selectedCategory,
                          'unit': selectedUnit,
                          'storage': selectedStorage,
                          'source': selectedSource,
                        };
                      });

                      print('✅ Updated ingredient: ${cartItems[index]}');

                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        try {
                          // ค่าที่จะใช้ตรวจสอบใน Firestore
                          String ingredientsName =
                              cartItems[index]['ingredientsName'];

                          // ค้นหาว่ามีรายการที่ตรงกับ ingredientsName ใน Firestore
                          var querySnapshot = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('userCart')
                              .where('ingredientsName',
                                  isEqualTo: ingredientsName)
                              .get();

                          if (querySnapshot.docs.isNotEmpty) {
                            // ถ้ามีรายการที่ตรงกันใน Firestore
                            String docId = querySnapshot
                                .docs.first.id; // ใช้ ID ของเอกสารที่พบ

                            // อัปเดทข้อมูลทั้งหมด
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('userCart')
                                .doc(docId) // อัปเดทเอกสารเดิม
                                .update({
                              'quantity': cartItems[index]['quantity'],
                              'price': cartItems[index]['price'],
                              'category':
                                  selectedCategory, // อัปเดต category ใหม่
                              'unit': selectedUnit, // อัปเดต unit ใหม่
                              'storage': selectedStorage, // อัปเดต storage ใหม่
                              'source': selectedSource, // อัปเดต source ใหม่
                              'imageUrl': cartItems[index]['imageUrl'],
                            }).then((_) {
                              print('Item updated successfully');
                            }).catchError((e) {
                              print('Error updating item: $e');
                            });
                          } else {
                            // ถ้าไม่มีรายการที่ตรงกันใน Firestore
                            String docId = ingredientsName +
                                '-' +
                                selectedCategory; // ใช้ combination นี้เป็น docId
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('userCart')
                                .doc(docId) 
                                .set({
                              'ingredientsName': ingredientsName,
                              'quantity': cartItems[index]['quantity'],
                              'price': cartItems[index]['price'],
                              'category': selectedCategory,
                              'unit': selectedUnit,
                              'storage': selectedStorage,
                              'source': selectedSource,
                              'imageUrl': cartItems[index]['imageUrl'],
                            }).then((_) {
                              print('New item added');
                            }).catchError((e) {
                              print('Error adding new item: $e');
                            });
                          }
                        } catch (e) {
                          print('Error: $e');
                        }
                      }
                      Navigator.pop(context);
                    },
                    child: Text('Update Item',
                    style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  ),

                  const SizedBox(height: 10),

                  // Delete button
                  ElevatedButton(
                      onPressed: () async {
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // Find the document ID
                            String docId = ingredient['docId'];
                            
                            // Delete from Firestore
                            await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('userCart')
                              .doc(docId)
                              .delete();

                            // Update local state
                            setState(() {
                              cartItems.removeAt(index);
                            });

                            print('❌ Removed ingredient: ${ingredient['ingredientsName']}');
                            
                            // Close the dialog and update parent widget
                            Navigator.pop(context);
                            
                            // Force rebuild of parent widget
                            if (context.mounted) {
                              final state = context.findAncestorStateOfType<_CartScreenState>();
                              if (state != null) {
                                state.setState(() {});
                              }
                            }
                          }
                        } catch (e) {
                          print('Error deleting item: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error deleting item: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text(
                        'Delete Item',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        )
                      ),
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
