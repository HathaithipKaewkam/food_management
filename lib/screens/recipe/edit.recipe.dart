import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/widgets/add_instruction.dart';
import 'package:food_project/widgets/add_recipeingredient.dart';
import 'package:image_picker/image_picker.dart';

class EditRecipeScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function? onRecipeCreated;
  final bool isEditingOwnRecipe;

  const EditRecipeScreen({
    Key? key, 
    this.initialData,
    this.onRecipeCreated,
    this.isEditingOwnRecipe = false, 
  }) : super(key: key);

  @override
  _EditRecipeScreenState createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _recipeNameController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _cookingTimeController = TextEditingController();
  final ValueNotifier<bool> _isFormValid = ValueNotifier<bool>(false);
  final TextEditingController _caloriesController = TextEditingController();
final TextEditingController _proteinController = TextEditingController();
final TextEditingController _carbsController = TextEditingController();
final TextEditingController _fatController = TextEditingController();
bool _showNutritionFields = false;
  
  String _selectedCategory = 'Breakfast';
  List<String> _categories = ['Breakfast',   
        'Lunch',       
        'Dinner',       
        'Appetizers',  
        'Main Dishes',  
        'Side Dishes',  
        'Soups',       
        'Snacks',       
        'Desserts',    
        'Beverages',    ];
  List<Map<String, dynamic>> ingredients = [];
  List<String> instructions = [];
  
  File? _ingredientImage;
  bool _isLoading = false;
  bool showIngredients = true;
  
  // เพิ่มตัวแปรที่จำเป็นสำหรับ UI
  List<IngredientUsage> recipeIngredientsUI = [];
  Recipe currentRecipe = Recipe(
  recipeId: 0, 
  recipeName: 'New Recipe',
  description: '',
  imageUrl: '',
  category: 'Breakfast',
  ingredients: [],
  instructions: [],
  servings: 1,
  preparationTime: 0,
  cookingTime: 0,
  Protein: 0.0,
  Fat: 0.0,
  Carbo: 0.0,
  Kcal: 0,
);
  int servingCount = 1;

  @override
void initState() {
  super.initState();
  print("🔍 isEditingOwnRecipe: ${widget.isEditingOwnRecipe}");
  _recipeNameController.addListener(_validateForm);
  _servingsController.addListener(_validateForm);
  _cookingTimeController.addListener(_validateForm);
    
  if (widget.initialData != null) {
    // ตั้งค่า text field controllers
    _recipeNameController.text = widget.initialData!['recipeName'] ?? '';
    _cookingTimeController.text = widget.initialData!['cookingTime']?.toString() ?? '';
    _servingsController.text = widget.initialData!['servings']?.toString() ?? '';
     _caloriesController.text = widget.initialData!['Kcal']?.toString() ?? '';
    _proteinController.text = widget.initialData!['Protein']?.toString() ?? '';
    _carbsController.text = widget.initialData!['Carbo']?.toString() ?? '';
    _fatController.text = widget.initialData!['Fat']?.toString() ?? '';

     _showNutritionFields = _caloriesController.text.isNotEmpty || 
                          _proteinController.text.isNotEmpty || 
                          _carbsController.text.isNotEmpty || 
                          _fatController.text.isNotEmpty;
    
    // ตั้งค่าหมวดหมู่
    if (widget.initialData!['category'] != null) {
      _selectedCategory = widget.initialData!['category'];
    }
    
    servingCount = int.tryParse(widget.initialData!['servings']?.toString() ?? '1') ?? 1;
    
    // โหลดข้อมูล ingredients
    if (widget.initialData!['ingredients'] != null) {
      List<dynamic> ingredientsData = widget.initialData!['ingredients'];
      
      for (var ingData in ingredientsData) {
        // เพิ่มข้อมูลลงใน ingredients array ที่ใช้บันทึกลง Firebase
        ingredients.add({
          'name': ingData['name'],
          'amount': ingData['amount'],
          'unit': ingData['unit'],
        });
        
        // สร้าง Ingredient object สำหรับแสดงใน UI
        final uiIngredient = Ingredient(
          ingredientsName: ingData['name'],
          unit: ingData['unit'],
          imageUrl: 'assets/images/ingredient_placeholder.png',
          userId: FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
          ingredientId: DateTime.now().millisecondsSinceEpoch.toString(),
          category: 'Other',
          storage: 'Pantry',
          quantity: 0.0,
          minQuantity: 0.0,
          expirationDate: DateTime.now().add(Duration(days: 30)),
          source: 'Recipe',
          kcal: 0.0,
        );
        
        
        final uiIngredientUsage = IngredientUsage(
          ingredient: uiIngredient,
          quantityUsed: ingData['amount'].toDouble(),
        );
        
        recipeIngredientsUI.add(uiIngredientUsage);
      }
    }
    
    
    if (widget.initialData!['instructions'] != null) {
      List<dynamic> instructionsData = widget.initialData!['instructions'];
      instructions = List<String>.from(instructionsData);
    }
    
    currentRecipe = Recipe(
      recipeId: 0,
      recipeName: widget.initialData!['recipeName'] ?? 'New Recipe',
      description: widget.initialData!['description'] ?? '',
      imageUrl: widget.initialData!['imageUrl'] ?? '',
      category: _selectedCategory,
      ingredients: recipeIngredientsUI,
      instructions: instructions,
      servings: servingCount,
      preparationTime: widget.initialData!['preparationTime'] ?? 0, 
      cookingTime: widget.initialData!['cookingTime'] ?? 0,
      Protein: widget.initialData!['Protein'] ?? 0.0,
      Fat: widget.initialData!['Fat'] ?? 0.0,
      Carbo: widget.initialData!['Carbo'] ?? 0.0,
      Kcal: widget.initialData!['Kcal'] ?? 0,
    );
  }
}
  @override
  void dispose() {
     _recipeNameController.removeListener(_validateForm);
  _servingsController.removeListener(_validateForm);
  _cookingTimeController.removeListener(_validateForm);
  _isFormValid.dispose();
  _recipeNameController.dispose();
  _instructionsController.dispose();
  _imageUrlController.dispose();
  _servingsController.dispose();
  _cookingTimeController.dispose();
  super.dispose();
  }

  void _validateForm() {
  bool isValid = 
    _recipeNameController.text.isNotEmpty &&
    _servingsController.text.isNotEmpty && 
    int.tryParse(_servingsController.text) != null &&
    _cookingTimeController.text.isNotEmpty && 
    int.tryParse(_cookingTimeController.text) != null;
    
  
  
  _isFormValid.value = isValid;
}

// เพิ่มฟังก์ชันนี้ในคลาส _EditRecipeScreenState

void _updateNutritionValues() {
  double totalKcal = 0.0;
  double totalProtein = 0.0;
  double totalFat = 0.0;
  double totalCarbs = 0.0;
  
  // คำนวณคุณค่าทางโภชนาการจากวัตถุดิบทั้งหมด
  for (var ingredient in ingredients) {
    double amount = ingredient['amount'] is num 
      ? (ingredient['amount'] as num).toDouble() 
      : 0.0;
      
    // คำนวณ kcal ตามสัดส่วนที่ใช้
    if (ingredient.containsKey('kcal')) {
      double kcalPerUnit = ingredient['kcal'] is num 
        ? (ingredient['kcal'] as num).toDouble() 
        : 0.0;
        
      totalKcal += amount * kcalPerUnit;
    }
    
    // ถ้ามีข้อมูลโปรตีน ไขมัน และคาร์โบไฮเดรตของวัตถุดิบ ก็นำมารวมด้วย
    if (ingredient.containsKey('protein')) {
      totalProtein += amount * (ingredient['protein'] is num 
        ? (ingredient['protein'] as num).toDouble() 
        : 0.0);
    }
    
    if (ingredient.containsKey('fat')) {
      totalFat += amount * (ingredient['fat'] is num 
        ? (ingredient['fat'] as num).toDouble() 
        : 0.0);
    }
    
    if (ingredient.containsKey('carbs')) {
      totalCarbs += amount * (ingredient['carbs'] is num 
        ? (ingredient['carbs'] as num).toDouble() 
        : 0.0);
    }
  }
  
  // อัพเดทค่าในฟอร์ม
  _caloriesController.text = totalKcal.round().toString();
  _proteinController.text = totalProtein.toStringAsFixed(1);
  _fatController.text = totalFat.toStringAsFixed(1);
  _carbsController.text = totalCarbs.toStringAsFixed(1);
  
  // เปิดส่วนของข้อมูลโภชนาการให้แสดงอัตโนมัติถ้ามีข้อมูล
  if (totalKcal > 0) {
    _showNutritionFields = true;
  }
}

Future<Map<String, dynamic>?> _fetchUserIngredientData(String ingredientName) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    
    // ค้นหาวัตถุดิบจากคอลเลคชัน userIngredients ของผู้ใช้
    final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('userIngredients')
      .where('ingredientsName', isEqualTo: ingredientName)
      .limit(1)
      .get();
    
    if (snapshot.docs.isNotEmpty) {
      print("✅ พบวัตถุดิบ: $ingredientName ในฐานข้อมูลของผู้ใช้");
      return snapshot.docs.first.data();
    }
    
    return null;
  } catch (e) {
    print("❌ เกิดข้อผิดพลาดในการค้นหาวัตถุดิบ: $e");
    return null;
  }
}

  Future<String> _uploadImage(File image) async {
  try {
    final storageRef = FirebaseStorage.instance.ref().child('recipe_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await storageRef.putFile(image);
    return await storageRef.getDownloadURL();
  } catch (e) {
    print('Error uploading image: $e');
    throw e;
  }
}

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _ingredientImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateRecipe() async {
  setState(() {
    _isLoading = true;
  });

  try {
    // จัดการกับรูปภาพ
    String imageUrl = '';
    if (_ingredientImage != null) {
      // อัปโหลดรูปภาพเฉพาะเมื่อมีรูปภาพใหม่
      imageUrl = await _uploadImage(_ingredientImage!);
    } else if (widget.initialData != null && widget.initialData!['imageUrl'] != null) {
      // ใช้รูปภาพเดิมถ้ามี
      imageUrl = widget.initialData!['imageUrl'];
    }
    _updateNutritionValues();

    // อ่านค่าโภชนาการ
    int kcal = int.tryParse(_caloriesController.text) ?? 0;
    double protein = double.tryParse(_proteinController.text) ?? 0.0;
    double carbs = double.tryParse(_carbsController.text) ?? 0.0;
    double fat = double.tryParse(_fatController.text) ?? 0.0;
    
    // สร้างข้อมูลสูตรอาหาร
    final recipeData = {
      'recipeId': widget.initialData!['recipeId'],
      'recipeName': _recipeNameController.text,
      'description': widget.initialData?['description'] ?? '',
      'instructions': instructions,
      'imageUrl': imageUrl,
      'category': _selectedCategory,
      'servings': int.parse(_servingsController.text),
      'preparationTime': widget.initialData?['preparationTime'] ?? 0,
      'cookingTime': int.parse(_cookingTimeController.text),
      'ingredients': ingredients,
      'Protein': protein,
      'Fat': fat,
      'Carbo': carbs,
      'Kcal': kcal,
      'isFavorite': widget.initialData?['isFavorite'] ?? false,
      'createdAt': widget.initialData?['createdAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(), // เพิ่มเวลาที่อัพเดต
      'createdBy': FirebaseAuth.instance.currentUser?.uid,
    };
    
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // ตรวจสอบว่ามี docId ที่ถูกต้องหรือไม่
    if (widget.initialData!.containsKey('docId') && 
        widget.initialData!['docId'] != null && 
        widget.initialData!['docId'] != "0" && 
        widget.initialData!['docId'] != 0) {
      
      String docId = widget.initialData!['docId'];
      print("📝 Attempting to update document with ID: $docId");
      
      // ตรวจสอบว่าเอกสารมีอยู่จริงก่อนอัปเดต
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('userRecipe')
        .doc(docId)
        .get();
      
      if (docSnapshot.exists) {
        print("✅ Document exists, updating...");
        await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('userRecipe')
          .doc(docId)
          .update(recipeData);
        
        print("✅ Document updated successfully with ID: $docId");
        
        if (widget.onRecipeCreated != null) {
          widget.onRecipeCreated!();
        }
        
        Navigator.pop(context, {
          'updated': true,
          'recipeData': recipeData,
          'docId': docId,
        });
      } else {
        print("⚠️ Document with ID $docId does not exist, searching by recipeId...");
        await _findAndUpdateByRecipeId(userId, recipeData);
        
        if (widget.onRecipeCreated != null) {
          widget.onRecipeCreated!();
        }
        
        Navigator.pop(context, {
          'updated': true,
          'recipeData': recipeData,
          'docId': widget.initialData!['docId'],
        });
      }
    } else {
      print("⚠️ Invalid docId, searching by recipeId instead");
      await _findAndUpdateByRecipeId(userId, recipeData);
      
      if (widget.onRecipeCreated != null) {
        widget.onRecipeCreated!();
      }
      
      Navigator.pop(context, {
        'updated': true,
        'recipeData': recipeData,
      });
    }
  } catch (e) {
    print('❌ Error updating recipe: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating recipe: $e')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<void> _createRecipe() async {
  setState(() {
    _isLoading = true;
  });

  try {
    // จัดการกับรูปภาพ
    String imageUrl = '';
    if (_ingredientImage != null) {
      // อัปโหลดรูปภาพเฉพาะเมื่อมีรูปภาพ
      imageUrl = await _uploadImage(_ingredientImage!);
    } else if (widget.initialData != null && widget.initialData!['imageUrl'] != null) {
      // ใช้รูปภาพเดิมถ้ามี
      imageUrl = widget.initialData!['imageUrl'];
    }

    _updateNutritionValues();

    // อ่านค่าโภชนาการ
    int kcal = int.tryParse(_caloriesController.text) ?? 0;
    double protein = double.tryParse(_proteinController.text) ?? 0.0;
    double carbs = double.tryParse(_carbsController.text) ?? 0.0;
    double fat = double.tryParse(_fatController.text) ?? 0.0;
    
    // สร้างข้อมูลสูตรอาหาร
    final recipeData = {
      'recipeId': DateTime.now().millisecondsSinceEpoch, // สร้าง recipeId ใหม่
      'recipeName': _recipeNameController.text,
      'description': widget.initialData?['description'] ?? '',
      'instructions': instructions,
      'imageUrl': imageUrl,
      'category': _selectedCategory,
      'servings': int.parse(_servingsController.text),
      'preparationTime': widget.initialData?['preparationTime'] ?? 0,
      'cookingTime': int.parse(_cookingTimeController.text),
      'ingredients': ingredients,
      'Protein': protein,
      'Fat': fat,
      'Carbo': carbs,
      'Kcal': kcal,
      'isFavorite': false,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': FirebaseAuth.instance.currentUser?.uid,
      'originalRecipeId': widget.initialData?['recipeId'], // เก็บ ID ของสูตรต้นฉบับ
    };
    
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) {
      throw Exception('User not logged in');
    }
    
    // สร้างสูตรใหม่
    DocumentReference docRef = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('userRecipe')
      .add(recipeData);
    
    print("✅ Created new recipe with ID: ${docRef.id}");
    
    if (widget.onRecipeCreated != null) {
      widget.onRecipeCreated!();
    }
    
    Navigator.pop(context, {
      'updated': true,
      'recipeData': recipeData,
      'docId': docRef.id,
    });
  } catch (e) {
    print('❌ Error creating recipe: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error creating recipe: $e')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

// เพิ่มฟังก์ชันนี้เพื่อค้นหาและอัปเดตด้วย recipeId
Future<void> _findAndUpdateByRecipeId(String userId, Map<String, dynamic> recipeData) async {
  try {
    int recipeId = recipeData['recipeId'];
    print("🔍 Searching for document with recipeId: $recipeId");
    
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('userRecipe')
      .where('recipeId', isEqualTo: recipeId)
      .get();
    
    if (snapshot.docs.isNotEmpty) {
      String docId = snapshot.docs.first.id;
      print("🔍 Found document ID: $docId using recipeId: $recipeId");
      
      await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('userRecipe')
        .doc(docId)
        .update(recipeData);
      
      print("✅ Document updated successfully by recipeId");
    } else {
      print("⚠️ No document found with recipeId: $recipeId, creating new");
      DocumentReference docRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('userRecipe')
        .add(recipeData);
      
      print("✅ Created new recipe with ID: ${docRef.id}");
    }
  } catch (e) {
    print("❌ Error in _findAndUpdateByRecipeId: $e");
    throw e;
  }
}

InputDecoration getCustomDecoration({String? hintText, IconData? prefixIcon}) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: Color(0xFFf8f8f7),
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Color(0xFF094507)) : null,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Color(0xFF78d454), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.red, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.red, width: 2),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     body: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : SafeArea(
          child: SingleChildScrollView( 
            child: Column(
              children: [
                // Header with back button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                  child: Row(
                    children: [
                      // Back button
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                        color: Colors.black,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                      const SizedBox(width: 5),
                      // Title
                      Text(
                        'Edit Recipe',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Recipe Image Section
                         Center(
  child: GestureDetector(
    onTap: _pickImage,
    child: Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        image: _ingredientImage != null
            ? DecorationImage(
                image: FileImage(_ingredientImage!),
                fit: BoxFit.cover,
              )
            : (widget.initialData != null && 
               widget.initialData!['imageUrl'] != null && 
               widget.initialData!['imageUrl'].isNotEmpty)
                ? DecorationImage(
                    image: widget.initialData!['imageUrl'].startsWith('http')
                        ? NetworkImage(widget.initialData!['imageUrl'])
                        : AssetImage(widget.initialData!['imageUrl']) as ImageProvider,
                    fit: BoxFit.cover,
                  )
                : null,
      ),
      child: (_ingredientImage == null && 
             (widget.initialData == null || 
              widget.initialData!['imageUrl'] == null || 
              widget.initialData!['imageUrl'].isEmpty))
          ? const Icon(
              Icons.add_a_photo,
              size: 50,
              color: Colors.grey,
            )
          : null,
    ),
  ),
),
                          const SizedBox(height: 20),
                          Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Recipe Name',
                            style: TextStyle(
                              color: Color(0xFF094507),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                     TextFormField(
                      controller: _recipeNameController,
                      decoration: getCustomDecoration(
                        hintText: 'Enter recipe name',
                        prefixIcon: Icons.restaurant_menu,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Colors.black
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a recipe name';
                        }
                        return null;
                      },
                    ),
                                        ]),
                                  ),
                          
                          
                          const SizedBox(height: 16),
                          Padding(
  padding: const EdgeInsets.symmetric(horizontal: 0), 
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Category',
        style: TextStyle(
          color: Color(0xFF094507),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: getCustomDecoration(
          hintText: 'Select category',
          prefixIcon: Icons.category,
        ),
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          color: Colors.black
        ),
        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF094507)),
        items: _categories.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedCategory = newValue;
            });
          }
        },
      ),
    ],
  ),
),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                            'Servings',
                            style: TextStyle(
                              color: Color(0xFF094507),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                         
                           Text(
                            'Cooking Time (min)',
                            style: TextStyle(
                              color: Color(0xFF094507),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ],
                          
                          ),
                          
                         const SizedBox(height: 10),
                          Row(
                            children: [
                              // Servings
                              Expanded(
                                
                                child: TextFormField(
  controller: _servingsController,
  decoration: getCustomDecoration(
    hintText: 'Number of servings',
    prefixIcon: Icons.people,
  ),
  style: TextStyle(
    fontWeight: FontWeight.bold, 
    color: Colors.black
  ),
  keyboardType: TextInputType.number,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter servings';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  },
),
                              ),
                              const SizedBox(width: 16),
                              
                              // Cooking Time
                              Expanded(
                                child:TextFormField(
  controller: _cookingTimeController,
  decoration: getCustomDecoration(
    hintText: 'Cooking time in minutes',
    prefixIcon: Icons.timer,
  ),
  style: TextStyle(
    fontWeight: FontWeight.bold, 
    color: Colors.black
  ),
  keyboardType: TextInputType.number,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter cooking time';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  },
),
                              ),
                            ],
                          ),
                                                                              const SizedBox(height: 16),
// Nutritional Information Section Header
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      'Nutritional Information (Optional)',
      style: TextStyle(
        color: Color(0xFF094507),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    TextButton(
      onPressed: () {
        setState(() {
          _showNutritionFields = !_showNutritionFields;
        });
      },
      child: Text(
        _showNutritionFields ? 'Hide' : 'Show',
        style: TextStyle(color: Color(0xFF78d454)),
      ),
    ),
  ],
),

// Nutrition Fields - จะแสดงเมื่อกดปุ่ม Show เท่านั้น
if (_showNutritionFields) ...[
  const SizedBox(height: 10),
  
  // Calories and Protein
  Row(
    children: [
      // Calories
      Expanded(
        child: TextFormField(
          controller: _caloriesController,
          decoration: getCustomDecoration(
            hintText: 'Calories (kcal)',
            prefixIcon: Icons.local_fire_department,
          ),
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.black
          ),
          keyboardType: TextInputType.number,
           inputFormatters: [
          FilteringTextInputFormatter.digitsOnly, 
        ],
        ),
      ),
      const SizedBox(width: 16),
      
      // Protein
      Expanded(
        child: TextFormField(
          controller: _proteinController,
          decoration: getCustomDecoration(
            hintText: 'Protein (g)',
            prefixIcon: Icons.fitness_center,
          ),
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.black
          ),
          keyboardType: TextInputType.number,
           inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
        ],
        ),
      ),
    ],
  ),
  
  const SizedBox(height: 16),
  
  // Carbs and Fat
  Row(
    children: [
      // Carbs
      Expanded(
        child: TextFormField(
          controller: _carbsController,
          decoration: getCustomDecoration(
            hintText: 'Carbs (g)',
            prefixIcon: Icons.grain,
          ),
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.black
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
        ],
        ),
      ),
      const SizedBox(width: 16),
      
      // Fat
      Expanded(
        child: TextFormField(
          controller: _fatController,
          decoration: getCustomDecoration(
            hintText: 'Fat (g)',
            prefixIcon: Icons.opacity,
          ),
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.black
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
        ],
        ),
      ),
    ],
  ),
],

  const SizedBox(height: 16),
                          
                    
Container(
  width: double.infinity, // ให้กว้างเต็มหน้าจอ
  padding: const EdgeInsets.all(8),
  margin: const EdgeInsets.symmetric(horizontal: 20), // เพิ่ม margin ด้านข้าง
  decoration: BoxDecoration(
    color: Colors.grey[300],
    borderRadius: BorderRadius.circular(30),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly, // จัดให้อยู่ห่างกันเท่าๆ กัน
    children: [
      Expanded( // ให้แต่ละปุ่มขยายเท่าๆ กัน
        child: InkWell(
          onTap: () {
            setState(() {
              showIngredients = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            alignment: Alignment.center, // จัดตัวอักษรให้อยู่ตรงกลาง
            decoration: BoxDecoration(
              color: showIngredients
                  ? Color(0xFF78d454)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Ingredients',
              style: TextStyle(
                color: showIngredients ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      Expanded( // ให้แต่ละปุ่มขยายเท่าๆ กัน
        child: InkWell(
          onTap: () {
            setState(() {
              showIngredients = false;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            alignment: Alignment.center, // จัดตัวอักษรให้อยู่ตรงกลาง
            decoration: BoxDecoration(
              color: !showIngredients
                  ? Color(0xFF78d454)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Instructions',
              style: TextStyle(
                color: !showIngredients ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ],
  ),
),
                          const SizedBox(height: 10),
                          
                          // Ingredient/Instruction Content
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: showIngredients
                                    ? AddRecipeingredient(
          ingredients: recipeIngredientsUI,
          recipe: currentRecipe,
          currentNumber: servingCount,
          onAddIngredient: (newIngredient) async {
            // ค้นหาข้อมูลวัตถุดิบจากฐานข้อมูลของผู้ใช้
            final ingredientData = await _fetchUserIngredientData(newIngredient['name']);
            
            // ดึงค่า kcal จากฐานข้อมูล ถ้ามี
            double kcalValue = 0.0;
            if (ingredientData != null && ingredientData.containsKey('kcal')) {
              kcalValue = ingredientData['kcal'] is num 
                ? (ingredientData['kcal'] as num).toDouble() 
                : 0.0;
              
              print("📊 ใช้ค่า kcal: $kcalValue จากฐานข้อมูลสำหรับวัตถุดิบ: ${newIngredient['name']}");
            }
            
            setState(() {
              // เพิ่มข้อมูล kcal ลงในวัตถุดิบ
              Map<String, dynamic> ingredientWithKcal = {
                ...newIngredient,
                'kcal': kcalValue,
              };
              
              // เพิ่มวัตถุดิบใหม่ลงในตัวแปร ingredients
              ingredients.add(ingredientWithKcal);
              
              // สร้าง Ingredient สำหรับแสดงผลใน UI
              final uiIngredient = Ingredient(
                ingredientsName: newIngredient['name'],
                unit: newIngredient['unit'],
                imageUrl: 'assets/images/ingredient_placeholder.png',
                userId: FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
                ingredientId: DateTime.now().millisecondsSinceEpoch.toString(),
                category: 'Other',
                storage: 'Pantry',
                quantity: 0.0,
                minQuantity: 0.0,
                expirationDate: DateTime.now().add(Duration(days: 30)),
                source: 'Recipe',
                kcal: kcalValue, // ใส่ค่า kcal ที่ได้จากฐานข้อมูล
              );
              
              final uiIngredientUsage = IngredientUsage(
                ingredient: uiIngredient,
                quantityUsed: newIngredient['amount'],
              );
              
              recipeIngredientsUI.add(uiIngredientUsage);
              
              // คำนวณค่าโภชนาการรวมและอัพเดทใน UI
              _updateNutritionValues();
              _validateForm();
            });
          },
          onRemoveIngredient: (index) {
            setState(() {
              // ลบวัตถุดิบออกจากทั้งสองตัวแปร
              ingredients.removeAt(index);
              recipeIngredientsUI.removeAt(index);
              _updateNutritionValues();
              _validateForm();
            });
          },
        )
                                : AddInstruction(
                                    instructions: instructions,
                                    onAddInstruction: (stepDescription) {
                                      setState(() {
                                        instructions.add(stepDescription);
                                      });
                                    },
                                    onRemoveInstruction: (index) {
                                      setState(() {
                                        instructions.removeAt(index);
                                      });
                                    },
                                  ),
                          ),
                          
                          const SizedBox(height: 120),
                          
                          // Save Button
                        Column(
  children: [
    const SizedBox(height: 5),
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
  if (!_formKey.currentState!.validate()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill out all required fields correctly')),
    );
    return;
  }
  if (ingredients.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please add at least one ingredient')),
    );
    return;
  }
  if (instructions.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please add at least one instruction step')),
    );
    return;
  }
  
  // เรียกใช้ฟังก์ชันที่ต่างกันขึ้นอยู่กับว่าเป็นการแก้ไขสูตรของตัวเองหรือไม่
  if (widget.isEditingOwnRecipe) {
    _updateRecipe();
  } else {
    _createRecipe();
  }
},
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF78d454),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
    widget.isEditingOwnRecipe ? 'Update Recipe' : 'Add to My Recipes',
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
      ),
    ),
  ],
),
                        
                        ],
                      ),
                    ),
                  ),
                ]),
              
            ),
      ),
    );
  }
}