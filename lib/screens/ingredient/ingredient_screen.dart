import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

        setState(() {
          ingredientList = snapshot.docs
              .map((doc) {
                final data =
                    doc.data() as Map<String, dynamic>?; // แปลงเป็น Map
                return data != null ? Ingredient.fromJson(data) : null;
              })
              .whereType<Ingredient>()
              .toList(); // กรองค่า null ออก

          filterIngredientsByType();

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

  void filterIngredientsByType() {
    setState(() {
      if (selectedType == 'All') {
        // ถ้าเลือก 'All', ให้แสดงวัตถุดิบทั้งหมดที่ยังไม่หมดอายุ
        filteredIngredientTypes = ingredientList
            .where((ingredient) =>
                ingredient.expirationDate.isAfter(DateTime.now()) ||
                ingredient.expirationDate == null) // กรองวันหมดอายุ
            .toList();
      } else {
        // ถ้าเลือกประเภทอื่น, กรองทั้งประเภทและวันหมดอายุ
        filteredIngredientTypes = ingredientList
            .where((ingredient) =>
                ingredient.storage == selectedType &&
                ingredient.expirationDate.isAfter(DateTime.now()))
            .toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchUserIngredients();
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
              child: ListView(
                children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        'My Ingredients',
                        style: TextStyle(
                          fontSize: 20,
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
                        // ใช้ SingleChildScrollView เพื่อเลื่อนทั้งหน้าจอ
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          // Search Bar + Button
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
                                          showCursor: true,
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
                                      Icon(
                                        Icons.tune,
                                        color: Colors.black54.withOpacity(.6),
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
                                // ข้อความแสดงจำนวนวัตถุดิบที่หมดอายุ พร้อมปุ่ม "See All"
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  child: Row(
                                    children: [
                                      Text(
                                        'You have ${ingredientList.where((ingredient) => ingredient.expirationDate.isBefore(DateTime.now())).toList().length} expired items',
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
                                        child: const Text(
                                          'See All',
                                          style: TextStyle(
                                              fontSize: 16, color: Colors.blue),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // แสดงรายการวัตถุดิบที่หมดอายุ
                                Padding(
                                  padding: const EdgeInsets.only(top: 0),
                                  child: ingredientList
                                          .where((ingredient) => ingredient
                                              .expirationDate
                                              .isBefore(DateTime.now()))
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
                                              Container(
                                                width: 100,
                                                height: 100,
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFfbcdd0),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  image: DecorationImage(
                                                    image: NetworkImage(ingredientList
                                                        .where((ingredient) =>
                                                            ingredient
                                                                .expirationDate
                                                                .isBefore(
                                                                    DateTime
                                                                        .now()))
                                                        .first
                                                        .imageUrl),
                                                  ),
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
                                                          '${ingredientList.where((ingredient) => ingredient.expirationDate.isBefore(DateTime.now())).first.quantity} ${ingredientList.where((ingredient) => ingredient.expirationDate.isBefore(DateTime.now())).first.unit}',
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
                                    itemBuilder: (BuildContext context, int index) {
                                      final ingredient = filteredIngredientTypes[index]; 
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => IngredientDetailPage(ingredient: ingredient),
                                              ),
                                            );
                                          },
                                          child: IngredientNoexp(ingredient: ingredient),
                                        ),
                                      );
                                    },
                                  ),

                              ],
                            ),
                          )
                        ])))
              ])));
    });
  }
}
