import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

        double quantity = (data['quantity'] is int)
          ? (data['quantity'] as int).toDouble()
          : (data['quantity'] as num?)?.toDouble() ?? 1.0;

      double minQuantity = (data['minQuantity'] is int)
          ? (data['minQuantity'] as int).toDouble()
          : (data['minQuantity'] as num?)?.toDouble() ?? 1.0;

        tempList.add({
          'ingredientsName': data['ingredientsName'] ?? '',
          'imageUrl': imageUrl ?? 'assets/images/default_ing.png',
          'category': data['category'] ?? '',
          'unit': data['unit'] ?? '',
          'shelflife': data['shelflife'] ?? 0,
          'storage': data['storage'] ?? '',
          'quantity': quantity,
          'minQuantity': minQuantity,
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = _searchIngredients(_searchController.text);

    return Scaffold(
      body: Padding(
       padding: const EdgeInsets.only(top: 40, left: 10),
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
            // รายการค้นหา
            Expanded(
              child: ListView(
                children: [
                  if (_searchController.text.isNotEmpty &&
                      searchResults.isEmpty)
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 10),
                      title: const Text(
                        'Add new Ingredient',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(_searchController.text),
                      leading: Image.asset(
                        'assets/images/default_ing.png',
                        width: 50,
                        height: 50,
                      ),
                      onTap: () {
                         if (!mounted) return; 
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddIngredientScreen(
                              ingredient: {
                                'ingredientsName': _searchController.text,
                                'imageUrl': '',
                                'category': 'Fruits',
                                'unit': 'Kilograms (kg)',
                                'shelflife': '7',
                                'storage': 'Fridge',
                                'quantity': '1.0',
                                'minQuantity': '1.0',
                              },
                            ),
                          ),
                        );
                      },
                    ),

                  ...searchResults.map((ingredient) {
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
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddIngredientScreen(
                              ingredient: ingredient,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
