import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:food_project/screens/ingredient/add_ingredient.dart';

class SearchIngredientScreen extends StatefulWidget {
  @override
  _SearchIngredientScreenState createState() => _SearchIngredientScreenState();
}

class _SearchIngredientScreenState extends State<SearchIngredientScreen> {
  TextEditingController _searchController = TextEditingController();
  String selectedIngredientName = '';
  List<Map<String, dynamic>> ingredientList = [];
  Timer? _debounce;

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
    _fetchIngredients(); // เรียกใช้ฟังก์ชันเพื่อดึงข้อมูลตอนเริ่มต้น
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
                labelText: 'Search / Add Ingredient',
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
            const SizedBox(height: 16),

            // แสดงรายการที่ค้นหา

            Expanded(
              child: ListView(
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddIngredientScreen(
                              ingredient: {
                                'ingredientsName': _searchController.text,
                                'imageUrl': 'assets/images/default_ing.png',
                                'category': '',
                                'unit': '',
                                'shelflife': '',
                                'storage': '',
                                'quantity': '',
                                'minQuantity': '',
                              },
                            ),
                          ),
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
                          return Image.asset('assets/images/default_ing.png',
                              width: 40, height: 40);
                        },
                      ),
                      title: Text(ingredient['ingredientsName']!),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddIngredientScreen(
                                      ingredient: {
                                        'name': ingredient['ingredientsName'],
                                        'image': ingredient['imageUrl'],
                                        'category': ingredient['category'],
                                        'unit': ingredient['unit'],
                                        'shelflife': ingredient['shelflife'],
                                        'storage': ingredient['storage'],
                                        'quantity': ingredient['quantity'],
                                        'minQuantity': ingredient['minQuantity'],
                                      },
                                    )
                                  )
                                );
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ]
                ),
              )
            );
          }
        }
