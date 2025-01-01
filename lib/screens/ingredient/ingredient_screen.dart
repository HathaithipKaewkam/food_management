import 'package:flutter/material.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/ingredient/expired_ingredient.dart';
import 'package:food_project/screens/ingredient/search_ingredient.dart';
import 'package:food_project/widgets/ingredient_noexp.dart';
import 'package:intl/intl.dart';


class IngredientScreen extends StatefulWidget {
  const IngredientScreen({
    super.key,
    required this.index,
    required this.ingredientList,
  });

  final int index;
  final List<Ingredient> ingredientList;

  @override
  State<IngredientScreen> createState() => _IngredientScreenState();
}

class _IngredientScreenState extends State<IngredientScreen> {
  int selectedCategoryIndex = 0;
  String selectedType = 'All';

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd-MM-yyyy')
        .format(widget.ingredientList[widget.index].expDate);

    Size size = MediaQuery.of(context).size;

    final nonExpiredIngredients = widget.ingredientList
        .where((ingredient) => ingredient.expDate.isAfter(DateTime.now()))
        .toList();

    // ดึงรายการ Ingredient
    List<Ingredient> ingredientList = Ingredient.ingredientList;

    // Ingredient category
    List<String> ingredientTypes = [
      'All',
      'Fridge',
      'Pantry',
      'Freezer',
    ];
    List<Ingredient> filteredIngredientTypes = [];
    if (selectedType == 'All') {
      // กรองเฉพาะรายการที่ยังไม่หมดอายุ หรือใกล้หมดอายุ
      filteredIngredientTypes = widget.ingredientList
          .where((ingredient) =>
              ingredient.expDate.isAfter(DateTime.now()) ||
              ingredient.expDate.isBefore(DateTime.now().add(Duration(
                  days: 3)))) // รวมรายการที่ยังไม่หมดอายุและใกล้หมดอายุ
          .toList();
    } else {
      // กรองรายการตาม storage และรายการที่ยังไม่หมดอายุ หรือใกล้หมดอายุ
      filteredIngredientTypes = widget.ingredientList
          .where((ingredient) =>
              ingredient.storage == selectedType &&
              (ingredient.expDate.isAfter(DateTime.now()) ||
                  ingredient.expDate.isBefore(DateTime.now().add(Duration(
                      days: 3))))) // รวมรายการที่ยังไม่หมดอายุและใกล้หมดอายุ
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ingredients'),
        backgroundColor: Colors.white,
        elevation: 1,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
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
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      width: size.width * .65,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1),
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
                              showCursor: true,
                              decoration: InputDecoration(
                                hintText: 'Search Ingredient',
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade400),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(color: Colors.black),
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
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1),
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
                            context, MaterialPageRoute(
                              builder: (context) => SearchIngredientScreen()));
                        },
                      ),
                    ),
                    const SizedBox(width: 7),
                    // History button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1),
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
                          print("history icon pressed");
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                                color: Colors.grey.shade300, width: 1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // แสดงรูปภาพของประเภท
                              Image.asset(
                                ingredientTypeImages[index], // โหลดรูปจาก path
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
                                  color: selectedCategoryIndex == index
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
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        children: [
                          Text(
                            'You have ${widget.ingredientList.where((ingredient) => ingredient.expDate.isBefore(DateTime.now())).toList().length} expired items',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const Spacer(), // ใช้ Spacer เพื่อให้ปุ่ม "See All" อยู่ขวามือ
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ExpiredItemsScreen(), // หน้ารายการหมดอายุ
                                ),
                              );
                            },
                            child: const Text(
                              'See All',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // แสดงรายการวัตถุดิบที่หมดอายุ
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: widget.ingredientList
                              .where((ingredient) =>
                                  ingredient.expDate.isBefore(DateTime.now()))
                              .toList()
                              .isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ExpiredItemsScreen(), // หน้ารายการหมดอายุ
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFfbcdd0),
                                      borderRadius: BorderRadius.circular(16),
                                      image: DecorationImage(
                                        image: AssetImage(widget.ingredientList
                                            .where((ingredient) => ingredient
                                                .expDate
                                                .isBefore(DateTime.now()))
                                            .first
                                            .imageUrl), // แสดงเฉพาะภาพของรายการแรกที่หมดอายุ
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    width: 260,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              widget.ingredientList
                                                  .where((ingredient) =>
                                                      ingredient.expDate
                                                          .isBefore(
                                                              DateTime.now()))
                                                  .first
                                                  .ingrediantsName,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            Text(
                                              '${widget.ingredientList.where((ingredient) => ingredient.expDate.isBefore(DateTime.now())).first.quantity} ${widget.ingredientList.where((ingredient) => ingredient.expDate.isBefore(DateTime.now())).first.unit}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Expired ${widget.ingredientList.where((ingredient) => ingredient.expDate.isBefore(DateTime.now())).first.expDate.difference(DateTime.now()).inDays.abs()} days ago!',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                            Text(
                                              widget.ingredientList
                                                  .where((ingredient) =>
                                                      ingredient.expDate
                                                          .isBefore(
                                                              DateTime.now()))
                                                  .toList()
                                                  .first
                                                  .storage,
                                              style: const TextStyle(
                                                fontSize: 14.0,
                                                color: Colors.grey,
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
                          child: IngredientNoexp(ingredient: ingredient),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
