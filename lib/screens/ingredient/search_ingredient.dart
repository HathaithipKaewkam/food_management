import 'dart:async';
import 'dart:convert'; 
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/screens/ingredient/add_ingredient.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class SearchIngredientScreen extends StatefulWidget {
  @override
  _SearchIngredientScreenState createState() => _SearchIngredientScreenState();
}

class _SearchIngredientScreenState extends State<SearchIngredientScreen> {
  TextEditingController _searchController = TextEditingController();
  String selectedIngredientName = '';
  Timer? _debounce;
  List<Map<String, dynamic>> ingredientList = [];
  bool isLoading = true;
  DocumentSnapshot? lastDocument;
  final int pageSize = 15; 
  Timer? _loadMoreDebounce;
  bool _isLoadingMore = false;
  Map<String, String> _imageUrlCache = {};
  

  Future<void> _fetchIngredients({bool refresh = false}) async {
  
  if ((isLoading || _isLoadingMore) && !refresh) {
    return;
  }
  
  setState(() {
    if (refresh) {
      isLoading = true;
      _isLoadingMore = false;
      lastDocument = null;
      ingredientList = [];
    } else {
      _isLoadingMore = true;
    }
  });
  
  try {
    logImage("🔍 Fetching ingredients...");
    Query query = FirebaseFirestore.instance
        .collection('ingredients')
        .orderBy('ingredientsName')
        .limit(pageSize);
    
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }
    
    QuerySnapshot querySnapshot = await query.get();
    logImage("📋 Found ${querySnapshot.docs.length} ingredients");
    
    if (querySnapshot.docs.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }
    
    lastDocument = querySnapshot.docs.last;
    
    List<Map<String, dynamic>> tempList = [];
    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String imageName = data['imageUrl'] ?? '';
      
      logImage("🔹 Ingredient: ${data['ingredientsName']} - Image: $imageName");
      
      tempList.add({
        'id': doc.id,
        'ingredientsName': data['ingredientsName'] ?? '',
        'imageUrl': imageName,
        'category': data['category'] ?? '',
        'unit': data['unit'] ?? '',
        'shelflife': data['shelflife'] ?? 0,
        'storage': data['storage'] ?? '',
        'quantity': _parseDoubleValue(data['quantity']),
        'minQuantity': _parseDoubleValue(data['minQuantity']),
      });
    }
    
    setState(() {
      // ถ้าเป็นการรีเฟรช ให้แทนที่ทั้งหมด
      if (refresh) {
        ingredientList = tempList;
      } else {
        // ตรวจสอบความซ้ำซ้อนก่อนเพิ่มข้อมูล
        Set<String> existingIds = ingredientList.map((e) => e['id'].toString()).toSet();
        List<Map<String, dynamic>> uniqueItems = tempList.where((item) => 
          !existingIds.contains(item['id'].toString())).toList();
        
        logImage("✅ Adding ${uniqueItems.length} new unique ingredients");
        ingredientList.addAll(uniqueItems);
      }
      isLoading = false;
      _isLoadingMore = false;
    });
    
    // บันทึกลงแคชเฉพาะเมื่อรีเฟรชหรือเป็นการโหลดครั้งแรก
    if (refresh || lastDocument == querySnapshot.docs.last) {
      _saveIngredientsToCache(ingredientList);
    }
  } catch (e) {
    logImage("❌ Error fetching ingredients: $e");
    setState(() {
      isLoading = false;
    });
  }
}

void logImage(String message) {
  developer.log(message, name: 'ImageDebug');
  print(message);
}
// Helper method to parse numeric values
double _parseDoubleValue(dynamic value) {
  if (value == null) return 1.0;
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) return double.tryParse(value) ?? 1.0;
  return 1.0;
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

  Future<List<Map<String, dynamic>>> _getIngredientsFromCache() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString('cached_ingredients');
    final timestamp = prefs.getInt('cache_timestamp') ?? 0;
    
    // แคชมีอายุ 24 ชั่วโมง
    final cacheValid = DateTime.now().millisecondsSinceEpoch - timestamp < 24 * 60 * 60 * 1000;
    
    if (jsonData != null && cacheValid) {
      final List<dynamic> decoded = jsonDecode(jsonData);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    }
  } catch (e) {
    print("❌ Error loading from cache: $e");
  }
  
  return [];
}

 Future<void> _saveIngredientsToCache(List<Map<String, dynamic>> ingredients) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    // ตรวจสอบความซ้ำซ้อนก่อนบันทึก
    final Set<String> uniqueIds = {};
    final List<Map<String, dynamic>> uniqueIngredients = ingredients.where((ingredient) {
      final id = ingredient['id'].toString();
      final isUnique = !uniqueIds.contains(id);
      if (isUnique) uniqueIds.add(id);
      return isUnique;
    }).toList();
    
    final jsonData = jsonEncode(uniqueIngredients);
    await prefs.setString('cached_ingredients', jsonData);
    await prefs.setInt('cache_timestamp', DateTime.now().millisecondsSinceEpoch);
    logImage("✅ Saved ${uniqueIngredients.length} ingredients to cache");
  } catch (e) {
    logImage("❌ Error saving to cache: $e");
  }
}

Future<void> _loadInitialData() async {
  final cachedIngredients = await _getIngredientsFromCache();
  if (cachedIngredients.isNotEmpty) {
    setState(() {
      ingredientList = cachedIngredients;
      isLoading = false;
    });
  }
  
  // จากนั้นดึงข้อมูลใหม่
  await _fetchIngredients(refresh: cachedIngredients.isEmpty);
  
  // บันทึกลงแคช
  if (ingredientList.isNotEmpty) {
    _saveIngredientsToCache(ingredientList);
  }
}

@override
void initState() {
  super.initState();
  _searchController.addListener(() {
    _onSearchChanged(_searchController.text);
  });
  
  _loadInitialData();
}

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _loadMoreDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
     final searchResults = _searchController.text.isEmpty 
      ? ingredientList 
      : _searchIngredients(_searchController.text);

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
             if (isLoading && ingredientList.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 16),
                    Text("Loading ingredients...")
                  ],
                ),
              ),
            )
          else
            Expanded(
              child:NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!isLoading && !_isLoadingMore && 
                      scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                    if (_loadMoreDebounce?.isActive ?? false) _loadMoreDebounce!.cancel();
                    
                    _loadMoreDebounce = Timer(Duration(milliseconds: 300), () {
                      if (!isLoading && !_isLoadingMore) {
                        _fetchIngredients();
                      }
                    });
                    return true;
                  }
                  return false;
                },
                child: ListView(
                  children: [
                    if (_searchController.text.isNotEmpty && searchResults.isEmpty)
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
    leading: _buildIngredientImage(ingredient['imageUrl']!),
    title: Text(ingredient['ingredientsName']!),
    onTap: () async {
      if (!mounted) return;
      
      // ถ้ามีการดาวน์โหลด URL แล้ว ให้เก็บไว้ใน ingredient
      if (ingredient['imageUrl'] != null && ingredient['imageUrl'].isNotEmpty) {
        try {
          // โหลด URL เต็มก่อนส่งไปหน้าถัดไป
          String fullImageUrl = await _getDownloadUrl(ingredient['imageUrl']);
          
          // สร้างข้อมูลใหม่ที่มี URL เต็ม
          Map<String, dynamic> updatedIngredient = Map.from(ingredient);
          updatedIngredient['imageUrl'] = fullImageUrl;
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddIngredientScreen(
                ingredient: updatedIngredient,
              ),
            ),
          );
        } catch (e) {
          print("❌ Error getting full URL: $e");
          // กรณีเกิดข้อผิดพลาด ส่งข้อมูลเดิมไป
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddIngredientScreen(
                ingredient: ingredient,
              ),
            ),
          );
        }
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddIngredientScreen(
              ingredient: ingredient,
            ),
          ),
        );
      }
    },
  );
}).toList(),
                    if (isLoading && ingredientList.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(16.0),
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(color: Colors.green),
                      ),
                ],
              ),
            ),
         ) ],
        ),
      ),
    );
  }

 Widget _buildIngredientImage(String imagePath) {
  if (imagePath.startsWith('assets/') || imagePath.isEmpty) {
    return Image.asset(
      imagePath.isEmpty ? 'assets/images/default_ing.png' : imagePath,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
    );
  } else {
    if (_imageUrlCache.containsKey(imagePath)) {
      return CachedNetworkImage(
        imageUrl: _imageUrlCache[imagePath]!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 40, height: 40,
          color: Colors.grey[200],
          child: Icon(Icons.image, color: Colors.grey[400]),
        ),
        errorWidget: (context, url, error) {
          return Image.asset(
            'assets/images/default_ing.png',
            width: 40, height: 40,
            fit: BoxFit.cover,
          );
        },
      );
    }
    
    // ใช้ FutureBuilder เฉพาะเมื่อไม่มีในแคช
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
  // ตรวจสอบว่ามี URL ในแคชหรือไม่
  if (_imageUrlCache.containsKey(imagePath)) {
    return _imageUrlCache[imagePath]!;
  }
  
  try {
    if (!imagePath.toLowerCase().endsWith('.png') && !imagePath.toLowerCase().endsWith('.jpg')) {
      imagePath = '$imagePath.png';
    }
    
    String storagePath = imagePath.startsWith('ingredients/') ? imagePath : 'ingredients/$imagePath';
    print("🔍 Getting download URL for path: $storagePath");
    
    Reference ref = FirebaseStorage.instance.ref().child(storagePath);
    
    String downloadUrl = await ref.getDownloadURL();
    
    _imageUrlCache[imagePath] = downloadUrl;
    
    print("✅ Got download URL: $downloadUrl");
    return downloadUrl;
  } catch (e) {
    if (imagePath.toLowerCase().endsWith('.png')) {
      try {
        String jpgPath = imagePath.toLowerCase().replaceAll('.png', '.jpg');
        String storagePath = jpgPath.startsWith('ingredients/') ? jpgPath : 'ingredients/$jpgPath';
        
        Reference ref = FirebaseStorage.instance.ref().child(storagePath);
        String downloadUrl = await ref.getDownloadURL();
        

        _imageUrlCache[imagePath] = downloadUrl;
        
        return downloadUrl;
      } catch (e2) {
        print("❌ Also failed with jpg: $e2");
      }
    }
    
    throw e;
  }
}

}

