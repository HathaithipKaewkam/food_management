import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Map<String, List<Map<String, String>>> _pairingCache = {};
Map<String, List<String>> _recipeCache = {};
Map<String, Map<String, dynamic>> _comprehensiveCache = {};
DateTime _lastCacheCleanup = DateTime.now();

const String _apiKey = '36440b5c03cb475c993bed762cee0c75';
Future<List<String>> fetchUserIngredients() async {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user != null) {
    try {
    
      final cacheDoc = await FirebaseFirestore.instance
          .collection('apiCache')
          .doc('userIngredients')
          .get();
      
      if (cacheDoc.exists) {
        Map<String, dynamic> data = cacheDoc.data()!;
        DateTime cacheTime = (data['timestamp'] as Timestamp).toDate();
        
       
        if (DateTime.now().difference(cacheTime).inHours < 1) {
          print("✅ Using cached user ingredients");
          return List<String>.from(data['ingredients']);
        }
      }
      
    
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userIngredients')
          .get();

      List<String> ingredients = snapshot.docs.map((doc) => doc['name'].toString()).toList();

      
      await FirebaseFirestore.instance
          .collection('apiCache')
          .doc('userIngredients')
          .set({
            'ingredients': ingredients,
            'timestamp': FieldValue.serverTimestamp()
          });
      
      return ingredients;
    } catch (e) {
      print("Error fetching ingredients: $e");
      return [];
    }
  } else {
    print("No user is logged in.");
    return [];
  }
}


Future<List<String>> getRecipesByIngredients(List<String> ingredients) async {
  if (ingredients.isEmpty) {
    print("No ingredients provided for the recipe search.");
    return [];
  }

  List<String> sortedIngredients = [...ingredients]..sort();
  String cacheKey = sortedIngredients.join(',');
  

  if (_recipeCache.containsKey(cacheKey)) {
    return _recipeCache[cacheKey]!;
  }
  
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cacheDoc = await FirebaseFirestore.instance
          .collection('apiCache')
          .doc('recipes')
          .collection('byIngredients')
          .doc(cacheKey.hashCode.toString())
          .get();
      
      if (cacheDoc.exists) {
        Map<String, dynamic> data = cacheDoc.data()!;
        DateTime cacheTime = (data['timestamp'] as Timestamp).toDate();
        
        // ใช้แคชถ้าไม่เกิน 3 วัน
        if (DateTime.now().difference(cacheTime).inDays < 3) {
          List<String> cachedRecipes = List<String>.from(data['recipes']);
          _recipeCache[cacheKey] = cachedRecipes; // บันทึกใน memory cache
          print('✅ Using Firebase cached recipes for ingredients: $cacheKey');
          return cachedRecipes;
        }
      }
    }
  } catch (e) {
    print('Error checking Firebase recipe cache: $e');
  }

  String ingredientString = ingredients.join(',');

  try {
    final response = await http.get(
      Uri.parse(
        'https://api.spoonacular.com/recipes/findByIngredients?ingredients=$ingredientString&number=5&apiKey=$_apiKey',
      ),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      List<String> recipes = data.map<String>((recipe) => recipe['title'].toString()).toList();
      
      _recipeCache[cacheKey] = recipes;
      

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('apiCache')
              .doc('recipes')
              .collection('byIngredients')
              .doc(cacheKey.hashCode.toString())
              .set({
                'ingredients': ingredients,
                'recipes': recipes,
                'timestamp': FieldValue.serverTimestamp()
              });
        }
      } catch (e) {
        print('Error saving recipes to Firebase cache: $e');
      }
      
      return recipes;
    } else {
      print('API error: ${response.statusCode}, ${response.body}');
      return [];
    }
  } catch (e) {
    print('Error getting recipes: $e');
    return [];
  }
}

/// ดึงวัตถุดิบที่เข้ากันกับวัตถุดิบที่กำหนด
Future<List<Map<String, String>>> getRecipeAndPairings(String ingredientName) async {
  // ล้างแคชเมื่อครบกำหนด
  if (DateTime.now().difference(_lastCacheCleanup).inHours > 24) {
    _pairingCache.clear();
    _recipeCache.clear();
    _comprehensiveCache.clear();
    _lastCacheCleanup = DateTime.now();
  }

  // ตรวจสอบว่ามีในแคชหรือไม่
  if (_pairingCache.containsKey(ingredientName)) {
    print('✅ Using memory cached pairings for $ingredientName');
    return _pairingCache[ingredientName]!;
  }
  
  // ตรวจสอบใน Firebase cache
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cacheDoc = await FirebaseFirestore.instance
          .collection('apiCache')
          .doc('pairings')
          .collection('ingredients')
          .doc(ingredientName)
          .get();
      
      if (cacheDoc.exists) {
        Map<String, dynamic> data = cacheDoc.data()!;
        DateTime cacheTime = (data['timestamp'] as Timestamp).toDate();
        
        // แคช 7 วัน
        if (DateTime.now().difference(cacheTime).inDays < 7) {
          List<Map<String, String>> cachedPairings = List<Map<String, String>>.from(
            (data['pairings'] as List).map((item) => 
              {'name': item['name'], 'image': item['image']}
            )
          );
          print('✅ Using Firebase cached pairings for $ingredientName');
          
          // เก็บใน memory cache
          _pairingCache[ingredientName] = cachedPairings;
          
          return cachedPairings;
        }
      }
    }
  } catch (e) {
    print('Error checking Firebase cache: $e');
  }

  // ดึงข้อมูลจาก API เมื่อไม่มีในแคช
  try {
    final response = await http.get(
      Uri.parse(
          'https://api.spoonacular.com/recipes/findByIngredients?ingredients=$ingredientName&number=5&apiKey=$_apiKey'),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      if (data is List && data.isNotEmpty) {
        List<Map<String, String>> pairingIngredients = [];
        Set<String> uniqueNames = {}; 

        // ลดจำนวนข้อมูลที่ต้องประมวลผลโดยดึงมาเพียง 5 รายการ
        for (var recipe in data) {
          List<dynamic> missedIngredients = recipe['missedIngredients'];
          for (var ingredient in missedIngredients) {
            String image = ingredient['image'] ?? "";
            String ingredientName = ingredient['originalName'] ?? ingredient['name'] ?? "Unknown Ingredient";
           
            // ปรับรูปแบบชื่อวัตถุดิบ ขึ้นต้นด้วยตัวใหญ่
            ingredientName = ingredientName.toLowerCase().replaceFirstMapped(RegExp(r'^\w'), (match) => match.group(0)!.toUpperCase());
            
            // เก็บเฉพาะชื่อที่ไม่ซ้ำและมีไม่เกิน 2 คำ
            if (!uniqueNames.contains(ingredientName) && ingredientName.split(' ').length <= 2) {
              uniqueNames.add(ingredientName);
              pairingIngredients.add({
                'name': ingredientName,
                'image': image,
              });
            }
            
            // จำกัดจำนวนผลลัพธ์ไม่เกิน 10 รายการ
            if (pairingIngredients.length >= 5) {
              break;
            }
          }
          
          if (pairingIngredients.length >= 5) {
            break;
          }
        }

        // บันทึกใน memory cache
        _pairingCache[ingredientName] = pairingIngredients;
        
        // บันทึกใน Firebase cache
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('apiCache')
                .doc('pairings')
                .collection('ingredients')
                .doc(ingredientName)
                .set({
                  'pairings': pairingIngredients,
                  'timestamp': FieldValue.serverTimestamp(),
                });
          }
        } catch (e) {
          print('Error saving to Firebase cache: $e');
        }
        
        return pairingIngredients;
      } else {
        print('No recipe data found for ingredient: $ingredientName');
        return [];
      }
    } else {
      print('API error: ${response.statusCode}, ${response.body}');
      return [];
    }
  } catch (e) {
    print('Error getting pairings: $e');
    return [];
  }
}

Future<Map<String, dynamic>> getComprehensiveRecipeData(List<String> ingredients) async {
  if (ingredients.isEmpty) {
    return {'recipes': [], 'pairings': []};
  }

  List<String> sortedIngredients = [...ingredients]..sort();
  String cacheKey = sortedIngredients.join(',');
  
  if (_comprehensiveCache.containsKey(cacheKey)) {
    print('✅ Using cached comprehensive data for: $cacheKey');
    return _comprehensiveCache[cacheKey]!;
  }
  
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cacheDoc = await FirebaseFirestore.instance
          .collection('apiCache')
          .doc('comprehensive')
          .collection('byIngredients')
          .doc(cacheKey.hashCode.toString())
          .get();
      
      if (cacheDoc.exists) {
        Map<String, dynamic> data = cacheDoc.data()!;
        DateTime cacheTime = (data['timestamp'] as Timestamp).toDate();
        
        // ใช้แคชถ้าไม่เกิน 3 วัน
        if (DateTime.now().difference(cacheTime).inDays < 3) {
          Map<String, dynamic> cachedData = {
            'recipes': data['recipes'],
            'pairings': data['pairings']
          };
          _comprehensiveCache[cacheKey] = cachedData;
          print('✅ Using Firebase cached comprehensive data for: $cacheKey');
          return cachedData;
        }
      }
    }
  } catch (e) {
    print('Error checking Firebase comprehensive cache: $e');
  }
  
  String ingredientString = ingredients.join(',');
  
  try {
    // เรียก API เพียงครั้งเดียว
    final response = await http.get(
      Uri.parse(
        'https://api.spoonacular.com/recipes/findByIngredients?ingredients=$ingredientString&number=10&apiKey=$_apiKey',
      ),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      
      if (data is List && data.isNotEmpty) {
        // ประมวลผลสูตรอาหาร
        List<String> recipes = data.map<String>((recipe) => recipe['title'].toString()).toList();
        
        // ประมวลผลวัตถุดิบที่เข้ากัน
        List<Map<String, String>> pairingIngredients = [];
        Set<String> uniqueNames = {};
        
        for (var recipe in data) {
          List<dynamic> missedIngredients = recipe['missedIngredients'];
          for (var ingredient in missedIngredients) {
            String image = ingredient['image'] ?? "";
            String ingredientName = ingredient['originalName'] ?? ingredient['name'] ?? "Unknown Ingredient";
            
            ingredientName = ingredientName.toLowerCase().replaceFirstMapped(RegExp(r'^\w'), (match) => match.group(0)!.toUpperCase());
            
            if (!uniqueNames.contains(ingredientName) && ingredientName.split(' ').length <= 2) {
              uniqueNames.add(ingredientName);
              pairingIngredients.add({
                'name': ingredientName,
                'image': image,
              });
            }
            
            if (pairingIngredients.length >= 5) {
              break;
            }
          }
          
          if (pairingIngredients.length >= 5) {
            break;
          }
        }
        
        Map<String, dynamic> result = {
          'recipes': recipes,
          'pairings': pairingIngredients
        };
        
        // บันทึกใน memory cache
        _comprehensiveCache[cacheKey] = result;
        
        // บันทึกใน Firebase cache
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('apiCache')
                .doc('comprehensive')
                .collection('byIngredients')
                .doc(cacheKey.hashCode.toString())
                .set({
                  'ingredients': ingredients,
                  'recipes': recipes,
                  'pairings': pairingIngredients,
                  'timestamp': FieldValue.serverTimestamp()
                });
          }
        } catch (e) {
          print('Error saving comprehensive data to Firebase cache: $e');
        }
        
        return result;
      } else {
        return {'recipes': [], 'pairings': []};
      }
    } else {
      print('API error: ${response.statusCode}, ${response.body}');
      return {'recipes': [], 'pairings': []};
    }
  } catch (e) {
    print('Error getting comprehensive recipe data: $e');
    return {'recipes': [], 'pairings': []};
  }
}

/// ดึงข้อมูลวัตถุดิบที่เข้ากันสำหรับหลายวัตถุดิบในครั้งเดียว
Future<Map<String, List<Map<String, String>>>> getPairingsForMultipleIngredients(List<String> ingredients) async {
  Map<String, List<Map<String, String>>> results = {};
  List<String> ingredientsToFetch = [];
  
  // ตรวจสอบแคช
  for (String ingredient in ingredients) {
    if (_pairingCache.containsKey(ingredient)) {
      results[ingredient] = _pairingCache[ingredient]!;
    } else {
      ingredientsToFetch.add(ingredient);
    }
  }
  
  // ถ้ายังมีวัตถุดิบที่ต้องดึงจาก API
  if (ingredientsToFetch.isNotEmpty) {
    for (String ingredient in ingredientsToFetch) {
      results[ingredient] = await getRecipeAndPairings(ingredient);
    }
  }
  
  return results;
}


Future<void> clearAllCaches() async {
  _pairingCache.clear();
  _recipeCache.clear();
  _comprehensiveCache.clear();
  _lastCacheCleanup = DateTime.now();
  
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('apiCache')
          .doc('pairings')
          .delete();
      
      await FirebaseFirestore.instance
          .collection('apiCache')
          .doc('recipes')
          .delete();
      
      await FirebaseFirestore.instance
          .collection('apiCache')
          .doc('comprehensive')
          .delete();
      
      await FirebaseFirestore.instance
          .collection('apiCache')
          .doc('userIngredients')
          .delete();
    }
  } catch (e) {
    print('Error clearing Firebase caches: $e');
  }
}

void main() async {
  List<String> userIngredients = await fetchUserIngredients();
  print("User has these ingredients: $userIngredients");

  if (userIngredients.isNotEmpty) {
    Map<String, dynamic> comprehensiveData = await getComprehensiveRecipeData(userIngredients);
    print('Recipes: ${comprehensiveData['recipes']}');
    print('Pairing ingredients: ${comprehensiveData['pairings']}');
  } else {
    print("No ingredients found to search recipes.");
  }
  await getRecipeAndPairings('Chicken');
}