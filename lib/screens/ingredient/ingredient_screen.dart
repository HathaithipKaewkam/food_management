import 'dart:async';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/ingredient/expired_ingredient.dart';
import 'package:food_project/screens/ingredient/history_ingredient.dart';
import 'package:food_project/screens/ingredient/ingrediant_detail.dart';
import 'package:food_project/screens/ingredient/search_ingredient.dart';
import 'package:food_project/widgets/ingredient_noexp.dart';
import 'package:intl/intl.dart';

class IngredientScreen extends StatefulWidget {
  final int index;
  final List<Ingredient> ingredientList;

  const IngredientScreen({
    Key? key,
    required this.index,
    required this.ingredientList,
  }) : super(key: key);

  @override
  _IngredientScreenState createState() => _IngredientScreenState();
}

class _IngredientScreenState extends State<IngredientScreen> {
  List<Ingredient> ingredientList = [];
  bool isLoading = true;
  int selectedCategoryIndex = 0;
  String selectedType = 'All';
  List<Ingredient> filteredIngredientTypes = [];

  List<String> ingredientTypes = ['All', 'Fridge', 'Pantry', 'Freezer'];

  StreamSubscription<QuerySnapshot>? _ingredientSubscription;

  TextEditingController searchController = TextEditingController();

  Future<void> fetchUserIngredients() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('userIngredients')
            .get();

        print("✅ Fetched ${snapshot.docs.length} ingredients.");

        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data();
          print(
              "📸 Ingredient ${data['ingredientsName']} has imageUrl: ${data['imageUrl']}");
        }

        setState(() {
          ingredientList = snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();

            data['ingredientId'] = doc.id;

            return Ingredient.fromJson(data);
          }).toList();

          filterIngredientsByType();
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

  void filterIngredientsByType() {
    setState(() {
      DateTime now = DateTime.now();

      List<Ingredient> notExpiredIngredients =
          ingredientList.where((ingredient) {
        return ingredient.expirationDate.isAfter(now) &&
            !(ingredient.isThrowed ?? false);
      }).toList();

      if (selectedType == 'All') {
        filteredIngredientTypes = notExpiredIngredients;
      } else {
        filteredIngredientTypes = notExpiredIngredients.where((ingredient) {
          return ingredient.storage == selectedType;
        }).toList();
      }

      filteredIngredientTypes.sort((a, b) {
        int dateComparison = a.expirationDate.compareTo(b.expirationDate);
        if (dateComparison != 0) {
          return dateComparison;
        }

        return a.ingredientsName
            .toLowerCase()
            .compareTo(b.ingredientsName.toLowerCase());
      });
    });
  }

  void searchIngredients(String query) {
    setState(() {
      if (query.isEmpty) {
        filterIngredientsByType();
      } else {
        List<Ingredient> searchResults = ingredientList.where((ingredient) {
          bool matchesSearch = ingredient.ingredientsName
              .toLowerCase()
              .contains(query.toLowerCase());
          bool matchesType =
              selectedType == 'All' || ingredient.storage == selectedType;
          bool notExpired = ingredient.expirationDate.isAfter(DateTime.now());
          bool notThrowed = !(ingredient.isThrowed ?? false);
          return matchesSearch && matchesType && notExpired && notThrowed;
        }).toList();

        searchResults.sort((a, b) {
          int dateComparison = a.expirationDate.compareTo(b.expirationDate);
          if (dateComparison != 0) {
            return dateComparison;
          }
          return a.ingredientsName
              .toLowerCase()
              .compareTo(b.ingredientsName.toLowerCase());
        });

        filteredIngredientTypes = searchResults;
      }
    });
  }

  Widget _buildExpiredIngredientImage(Ingredient ingredient) {
    print(
        "🔍 Building expired image for: ${ingredient.ingredientsName} with URL: ${ingredient.imageUrl}");

    if (ingredient.imageUrl.isEmpty) {
      return const Icon(
        Icons.restaurant,
        color: Colors.white,
        size: 40,
      );
    }

    if (ingredient.imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: ingredient.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: const Color(0xFFfbcdd0),
          child: const Center(
              child: CircularProgressIndicator(color: Colors.white)),
        ),
        errorWidget: (context, error, stackTrace) {
          print("❌ Image error: $error");
          return const Icon(
            Icons.image_not_supported,
            color: Colors.white,
            size: 40,
          );
        },
      );
    } else {
      // ใช้ getImageUrl ของ Ingredient
      try {
        String imageUrl = ingredient.getImageUrl();
        print("🔍 Using generated URL for expired: $imageUrl");

        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: const Color(0xFFfbcdd0),
            child: const Center(
                child: CircularProgressIndicator(color: Colors.white)),
          ),
          errorWidget: (context, error, stackTrace) {
            print("❌ Expired image error: $error for URL: $imageUrl");
            return const Icon(
              Icons.image_not_supported,
              color: Colors.white,
              size: 40,
            );
          },
        );
      } catch (e) {
        print("❌ Error creating expired image URL: $e");
        return const Icon(
          Icons.image_not_supported,
          color: Colors.white,
          size: 40,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserIngredients();
    setupIngredientListener();
  }

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
        setState(() {
          ingredientList = snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            return Ingredient.fromJson(data);
          }).toList();
          ingredientList = ingredientList
              .where((ingredient) => !(ingredient.isThrowed ?? false))
              .toList();
          filterIngredientsByType();
        });
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _ingredientSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      Size size = MediaQuery.of(context).size;
      print("isLoading: $isLoading");
      if (isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Scaffold(
          body: Padding(
              padding: const EdgeInsets.only(top: 20, left: 0),
              child: ListView(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        'My Ingredients',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.only(top: 10, left: 0),
                    child: SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  width: size.width * .65,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.grey.shade300, width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                            searchIngredients(value);
                                          },
                                          decoration: InputDecoration(
                                            hintText: 'Search Ingredient',
                                            hintStyle: TextStyle(
                                                color: Colors.grey.shade400),
                                            border: InputBorder.none,
                                          ),
                                          style: const TextStyle(
                                              color: Colors.black),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                // Add button
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.grey.shade300, width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.black,
                                      size: 25,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  SearchIngredientScreen()));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 7),
                                // History button
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.grey.shade300, width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.history,
                                      color: Colors.black,
                                      size: 25,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  HistoryIngredient()));
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Category Selector
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: SizedBox(
                              height: 120,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                scrollDirection: Axis.horizontal,
                                shrinkWrap: true,
                                itemCount: ingredientTypes.length,
                                itemBuilder: (BuildContext context, int index) {
                                  // เพิ่มรายการรูปภาพให้ตรงกับแต่ละประเภท
                                  List<String> ingredientTypeImages = [
                                    'assets/images/all.png', // รูปประเภท All
                                    'assets/images/fridge.png', // รูปประเภท Fridge
                                    'assets/images/pantry.png', // รูปประเภท Pantry
                                    'assets/images/freezer.png', // รูปประเภท Freezer
                                  ];

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedCategoryIndex = index;
                                        selectedType = ingredientTypes[index];
                                        filterIngredientsByType();
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 10),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: selectedCategoryIndex == index
                                            ? Color(0xFFb2e6b2)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 1),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // แสดงรูปภาพของประเภท
                                          Image.asset(
                                            ingredientTypeImages[
                                                index], // โหลดรูปจาก path
                                            height: 60, // ขนาดความสูงของรูปภาพ
                                            width: 60, // ขนาดความกว้างของรูปภาพ
                                            fit: BoxFit.cover,
                                          ),
                                          const SizedBox(
                                              height:
                                                  8), // เว้นระยะห่างระหว่างรูปและข้อความ
                                          // แสดงชื่อประเภท
                                          Text(
                                            ingredientTypes[index],
                                            style: TextStyle(
                                              color:
                                                  selectedCategoryIndex == index
                                                      ? Colors.black
                                                      : Colors.black,
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
                          ),

                          const SizedBox(height: 10),

                          // แสดงรายการ Ingredients
                          Padding(
                            padding: const EdgeInsets.only(right: 12, left: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  child: Row(
                                    children: [
                                      Text(
                                        'You have ${ingredientList.where((ingredient) => ingredient.expirationDate.isBefore(DateTime.now()) && ingredient.quantity > 0).toList().length} expired items',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ExpiredItemsScreen(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'See All',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.red.shade700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // แสดงรายการวัตถุดิบที่หมดอายุ
                                Padding(
                                  padding: const EdgeInsets.only(top: 0),
                                  child: ingredientList
                                          .where((ingredient) =>
                                              ingredient.expirationDate
                                                  .isBefore(DateTime.now()) &&
                                              ingredient.quantity > 0 &&
                                              !(ingredient.isThrowed ?? false))
                                          .toList()
                                          .isNotEmpty
                                      ? GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ExpiredItemsScreen(),
                                              ),
                                            );
                                          },
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Container(
                                                  width: 100,
                                                  height: 100,
                                                  color:
                                                      const Color(0xFFfbcdd0),
                                                  child: _buildExpiredIngredientImage(
                                                      ingredientList
                                                          .where((ingredient) =>
                                                              ingredient
                                                                  .expirationDate
                                                                  .isBefore(DateTime
                                                                      .now()) &&
                                                              ingredient
                                                                      .quantity >
                                                                  0)
                                                          .first),
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                width: 282,
                                                height: 100,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey
                                                          .withOpacity(0.3),
                                                      blurRadius: 5,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          ingredientList
                                                              .where((ingredient) =>
                                                                  ingredient
                                                                      .expirationDate
                                                                      .isBefore(
                                                                          DateTime
                                                                              .now()))
                                                              .first
                                                              .ingredientsName,
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.grey,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${ingredientList.where((ingredient) => ingredient.expirationDate.isBefore(DateTime.now())).first.quantity.toDouble()} ${ingredientList.where((ingredient) => ingredient.expirationDate.isBefore(DateTime.now())).first.unit}',
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.grey,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          'Expired ${ingredientList.where((ingredient) => ingredient.expirationDate.isBefore(DateTime.now())).first.expirationDate.difference(DateTime.now()).inDays.abs()} days ago!',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                        Text(
                                                          ingredientList
                                                              .where((ingredient) =>
                                                                  ingredient
                                                                      .expirationDate
                                                                      .isBefore(
                                                                          DateTime
                                                                              .now()))
                                                              .toList()
                                                              .first
                                                              .storage,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14.0,
                                                            color: Colors.grey,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(),
                                ),
                                SizedBox(height: 5),

                                // แสดงรายการที่ไม่หมดอายุ
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    'Ingredients Available',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredIngredientTypes.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final ingredient =
                                        filteredIngredientTypes[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 3.0),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  IngredientDetailPage(
                                                ingredient: ingredient,
                                                recipes: [],
                                              ),
                                            ),
                                          );
                                        },
                                        onLongPress: () {
                                          print(
                                              "🔍 Debug - Long Pressed on Ingredient: ${ingredient.ingredientsName}");
                                          print(
                                              "🔍 Debug - Ingredient ID: ${ingredient.ingredientId}");

                                          if (ingredient.quantity == 0) {
                                            return;
                                          }
                                          if (ingredient
                                              .ingredientId.isNotEmpty) {
                                            final ingredientMap = {
                                              'id': ingredient.ingredientId,
                                              'ingredientsName':
                                                  ingredient.ingredientsName,
                                              'quantity': ingredient.quantity,
                                              'unit': ingredient.unit,
                                              'usageHistory': [],
                                            };
                                            showUsedDialog(
                                              context,
                                              ingredientMap,
                                              index,
                                            );
                                          }
                                        },
                                        child: IngredientNoexp(
                                            ingredient: ingredient),
                                      ),
                                    );
                                  },
                                )
                              ],
                            ),
                          )
                        ])))
              ])));
    });
  }
}

Future<void> showUsedDialog(
  BuildContext context,
  Map<String, dynamic> ingredient,
  int index,
) async {
  double currentQuantity = (ingredient['quantity'] is int)
      ? (ingredient['quantity'] as int).toDouble()
      : (ingredient['quantity'] as num).toDouble();
  double maxQuantity = currentQuantity;
  TextEditingController quantityController =
      TextEditingController(text: currentQuantity.toStringAsFixed(1));
  TextEditingController noteController = TextEditingController();

  void validateAndUpdateQuantity(String value) {
    if (value.isEmpty || value == '.') {
      currentQuantity = 0;
      return;
    }

    if (value.contains('.')) {
      var parts = value.split('.');
      if (parts[1].length > 2) {
        value = '${parts[0]}.${parts[1].substring(0, 2)}';
        quantityController.text = value;
        quantityController.selection = TextSelection.fromPosition(
          TextPosition(offset: value.length),
        );
      }
    }

    double? newQuantity = double.tryParse(value);
    if (newQuantity != null) {
      if (newQuantity > maxQuantity) {
        value = maxQuantity.toStringAsFixed(2);
        quantityController.text = value;
        currentQuantity = maxQuantity;
      } else if (newQuantity < 0.0) {
        value = '0.00';
        quantityController.text = value;
        currentQuantity = 0.0;
      } else {
        currentQuantity = newQuantity;
      }
      quantityController.selection = TextSelection.fromPosition(
        TextPosition(offset: value.length),
      );
    }
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height *
                0.8, // จำกัดขนาดไม่เกิน 80% ของหน้าจอ
          ),
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // ป้องกัน overflow
                    children: [
                      // Header with close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Use Ingredient',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Ingredient Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.kitchen, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ingredient['ingredientsName']
                                            ?.toString()
                                            .toUpperCase() ??
                                        '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Available: ${ingredient['quantity']} ${ingredient['unit']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quantity input
                      const Text(
                        'How much did you use?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Minus button
                            IconButton(
                              onPressed: currentQuantity >= 1
                                  ? () {
                                      setState(() {
                                        currentQuantity -= 1.0;
                                        quantityController.text =
                                            currentQuantity.toStringAsFixed(1);
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                              color: currentQuantity >= 1
                                  ? Colors.red
                                  : Colors.grey,
                              padding: EdgeInsets.zero, // Reduce padding
                            ),

                            // Quantity input and unit
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: TextField(
                                      controller: quantityController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      textAlign: TextAlign.center,
                                      onTap: () {
                                        quantityController.clear();
                                        quantityController.selection =
                                            TextSelection(
                                          baseOffset: 0,
                                          extentOffset:
                                              quantityController.text.length,
                                        );
                                      },
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d*\.?\d{0,2}')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          validateAndUpdateQuantity(value);
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16, // Slightly smaller font
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4), // Small gap
                                  Text(
                                    ingredient['unit'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Plus button
                            IconButton(
                              onPressed: currentQuantity < maxQuantity
                                  ? () {
                                      setState(() {
                                        currentQuantity += 1.0;
                                        quantityController.text =
                                            currentQuantity.toStringAsFixed(1);
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                              color: currentQuantity < maxQuantity
                                  ? Colors.green
                                  : Colors.grey,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Add note (optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Note Input
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: TextField(
                          controller: noteController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            alignLabelWithHint: true,
                            hintText: ' e.g. Used for making pasta',
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Confirm Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;

                            String ingredientId = ingredient['id'];
                            if (ingredientId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid ingredient ID'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            // Convert double to int for Firebase storage
                            double usedQuantity =
                                double.parse(quantityController.text);
                            if (usedQuantity <= 0 ||
                                usedQuantity > maxQuantity) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid quantity'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            String note = noteController.text.trim();

                            Navigator.of(context).pop();

                            try {
                              DocumentReference ingredientRef =
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('userIngredients')
                                      .doc(ingredientId);

                              Map<String, dynamic> resultData =
                                  await FirebaseFirestore.instance
                                      .runTransaction<Map<String, dynamic>>(
                                          (transaction) async {
                                DocumentSnapshot snapshot =
                                    await transaction.get(ingredientRef);
                                if (!snapshot.exists) {
                                  throw Exception("Ingredient not found");
                                }

                                Map<String, dynamic> data =
                                    snapshot.data() as Map<String, dynamic>;
                                double currentStock = (data['quantity'] is int)
                                    ? (data['quantity'] as int).toDouble()
                                    : (data['quantity'] as num).toDouble();

                                if (usedQuantity > currentStock) {
                                  throw Exception("Not enough stock");
                                }

                                double newQuantity =
                                    currentStock - usedQuantity;

                                List<dynamic> history =
                                    List.from(data["usageHistory"] ?? []);
                                history.add({
                                  "date": Timestamp.now(),
                                  "quantity_used": usedQuantity,
                                  "note": note.isNotEmpty ? note : "No note"
                                });

                                transaction.update(ingredientRef, {
                                  "quantity": newQuantity,
                                  "usageHistory": history,
                                  "updateDate": Timestamp.now(),
                                });
                                return {
                                  'ingredientsName':
                                      data['ingredientsName'] ?? 'Unknown',
                                  'unit': data['unit'] ?? 'Pieces',
                                  'kcal': data['kcal'],
                                  'currentStock': currentStock,
                                };
                              });
                              double usedKcal = 0.0;
                              if (resultData['kcal'] != null) {
                                double kcalPerUnit = (resultData['kcal'] is int)
                                    ? (resultData['kcal'] as int).toDouble()
                                    : (resultData['kcal'] as num?)
                                            ?.toDouble() ??
                                        0.0;

                                usedKcal = kcalPerUnit * usedQuantity;
                              }

                              if (usedKcal > 0) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('calorieConsumption')
                                    .add({
                                  "date": Timestamp.now(),
                                  "dateStr": DateFormat('yyyy-MM-dd')
                                      .format(DateTime.now()),
                                  "ingredientId": ingredientId,
                                  "ingredientName":
                                      resultData['ingredientsName'],
                                  "quantity": usedQuantity,
                                  "unit": resultData['unit'],
                                  "kcal": usedKcal,
                                  "mealType": "",
                                  "note": note.isNotEmpty ? note : "No note",
                                });
                              }

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Successfully used $usedQuantity ${ingredient['unit']}'),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              if (context.mounted) {
                                final state = context.findAncestorStateOfType<
                                    _IngredientScreenState>();
                                if (state != null) {
                                  state.setState(() {
                                    state.setupIngredientListener();
                                  });
                                }
                              }
                            } catch (e) {
                              // แสดง error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              print('Error using ingredient: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade100,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Confirm Usage',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}
