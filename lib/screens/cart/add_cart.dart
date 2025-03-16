import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:food_project/screens/ingredient/add_ingredient.dart';

class SearchCartScreen extends StatefulWidget {
  @override
  _SearchCartScreenState createState() => _SearchCartScreenState();
}

class _SearchCartScreenState extends State<SearchCartScreen> {
  TextEditingController _searchController = TextEditingController();
  String selectedIngredientName = '';
  List<Map<String, dynamic>> ingredientList = [];
  Timer? _debounce;
  TextEditingController _priceController = TextEditingController();
  TextEditingController _sourceController = TextEditingController();
  final FocusNode _priceFocusNode = FocusNode();
  final FocusNode _sourceFocusNode = FocusNode();

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

  @override
  void initState() {
    super.initState();
    _fetchIngredients();
     _priceFocusNode.requestFocus();
     _sourceFocusNode.requestFocus();
    
  }

  @override
  void dispose() {
    _searchController.dispose();
     _priceFocusNode.dispose();
    _sourceFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _showAddToCartBottomSheet(
      BuildContext context, Map<String, dynamic> ingredient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool isOtherSelected = false;
        int quantity = 1;
        String? selectedStorage = ingredient['storage'] ?? 'Fridge';
        String? selectedUnit = ingredient['unit'] ?? 'grams';
        String? selectedSource = ingredient['source'] ?? 'Lotus\'s';

        TextEditingController priceController = TextEditingController();
        TextEditingController sourceController = TextEditingController();
        final FocusNode _sourceFocusNode = FocusNode();
        final FocusNode _priceFocusNode = FocusNode();

        List<String> sourceOptions = [
          'Lotus\'s',
          'Big C',
          'Makro',
          'Tops',
          '7-11',
          'Other'
        ];
        List<String> storageOptions = ['Fridge', 'Freezer', 'Pantry'];
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
        

        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // รูปภาพและชื่อวัตถุดิบ
                Row(
                  children: [
                    Image.network(
                      ingredient['imageUrl']!,
                      width: 60,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset('assets/images/default_ing.png',
                            width: 60, height: 60);
                      },
                    ),
                    const SizedBox(width: 12),
                    Text(
                      ingredient['ingredientsName']!,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // เลือกจำนวน
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quantity', style: TextStyle(fontSize: 18)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (quantity > 1) {
                              setState(() => quantity--);
                            }
                          },
                          icon: const Icon(Icons.remove),
                        ),
                        Text(quantity.toString(),
                            style: const TextStyle(fontSize: 18)),
                        IconButton(
                          onPressed: () {
                            setState(() => quantity++);
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // หน่วยของวัตถุดิบ
                DropdownButtonFormField<String>(
                  value: selectedUnit,
                  items: unitOptions.map((unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Text(unit),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedUnit = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Unit',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 20), // ✅ ถูกต้อง

                // ประเภทการเก็บรักษา
                DropdownButtonFormField<String>(
                  value: selectedStorage,
                  items: storageOptions.map((storage) {
                    return DropdownMenuItem(
                      value: storage,
                      child: Text(storage),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStorage = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Storage',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
            value: selectedSource,
            items: sourceOptions.map((source) {
              return DropdownMenuItem(
                value: source,
                child: Text(source),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedSource = value;
                isOtherSelected = (value == 'Other');
                if (!isOtherSelected) {
                  sourceController.clear();
                } else {
                  // การใช้ Future.delayed เพื่อให้การขอ focus เกิดหลังจากที่ TextField ถูกสร้างขึ้น
                  Future.delayed(Duration(milliseconds: 100), () {
                    _sourceFocusNode.requestFocus();
                    // ถ้าเคยเปิดคีย์บอร์ดแล้วคีย์บอร์ดไม่แสดง ใช้ showSoftInput()
                    FocusScope.of(context).requestFocus(_sourceFocusNode);
                  });
                }
              });
            },
            decoration: const InputDecoration(
              labelText: 'Select Source',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          if (isOtherSelected)
            TextField(
              controller: sourceController,
              focusNode: _sourceFocusNode,
              decoration: const InputDecoration(
                labelText: 'Enter Source',
                border: OutlineInputBorder(),
              ),
            ),



                const SizedBox(height: 20),
               TextField(
                  controller: priceController,
                  focusNode: _priceFocusNode,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price (฿)',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () {
                    _priceFocusNode.requestFocus();  // ตั้งค่า focus ด้วยตนเอง
                  },
                ),



                const SizedBox(height: 20),

                // ปุ่มยืนยัน
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // เพิ่มไปยังตะกร้า
                      Navigator.pop(context); // ปิด Bottom Sheet
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF325b51),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Add to Cart',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Ingredients'),
          backgroundColor: Colors.white,
          elevation: 1,
          scrolledUnderElevation: 0,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            // ช่องค้นหา
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Search / Add Ingredients',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide:
                      BorderSide(color: Colors.grey.shade300, width: 1.0),
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
                                        'Add new Ingredient',
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFd7d8d8),
                                            borderRadius:
                                                BorderRadius.circular(16),
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
                                _showAddToCartBottomSheet(context, {
                                  'ingredientsName': _searchController.text,
                                  'imageUrl': 'assets/images/default_ing.png',
                                  'unit': 'N/A',
                                  'storage': 'N/A',
                                });
                              }),
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
                              _showAddToCartBottomSheet(context, ingredient);
                            },
                          );
                        }).toList(),
                      ],
                    ),
            ),
          ]),
        ));
  }
}
