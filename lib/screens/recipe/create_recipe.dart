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

class CreateRecipeScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function? onRecipeCreated;
  const CreateRecipeScreen({
    Key? key,
    this.initialData,
    this.onRecipeCreated,
  }) : super(key: key);

  @override
  _CreateRecipeScreenState createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
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
  bool isCalculatingNutrition = false;
  TextEditingController get kcalController => _caloriesController;
  TextEditingController get proteinController => _proteinController;
  TextEditingController get fatController => _fatController;
  TextEditingController get carboController => _carbsController;

  String _selectedCategory = 'Breakfast';
  List<String> _categories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Appetizers',
    'Main Dishes',
    'Side Dishes',
    'Soups',
    'Snacks',
    'Desserts',
    'Beverages',
  ];
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

  // เพิ่มฟังก์ชันคำนวณโภชนาการอัตโนมัติ
  Future<void> _calculateNutritionFromIngredients() async {
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add ingredients first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isCalculatingNutrition = true;
    });

    try {
      double totalKcal = 0;
      double totalProtein = 0;
      double totalFat = 0;
      double totalCarbo = 0;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          isCalculatingNutrition = false;
        });
        return;
      }

      // ดึงข้อมูลวัตถุดิบจาก Firebase โดยใช้ชื่อวัตถุดิบ
      for (var ingredientData in ingredients) {
        String ingredientName = ingredientData['name'];
        double amount = ingredientData['amount'];

        // ค้นหาวัตถุดิบในฐานข้อมูล
        final QuerySnapshot ingredientSnapshot = await FirebaseFirestore
            .instance
            .collection('ingredients')
            .where('ingredientsName', isEqualTo: ingredientName)
            .limit(1)
            .get();

        // ถ้าพบวัตถุดิบในฐานข้อมูลทั่วไป
        if (ingredientSnapshot.docs.isNotEmpty) {
          final data =
              ingredientSnapshot.docs.first.data() as Map<String, dynamic>;

          // ดึงค่าโภชนาการต่อหน่วย (ถ้ามี)
          double kcalPerUnit =
              data['kcal'] is num ? (data['kcal'] as num).toDouble() : 0;
          double proteinPerUnit =
              data['protein'] is num ? (data['protein'] as num).toDouble() : 0;
          double fatPerUnit =
              data['fat'] is num ? (data['fat'] as num).toDouble() : 0;
          double carboPerUnit =
              data['carbs'] is num ? (data['carbs'] as num).toDouble() : 0;

          // คำนวณตามปริมาณที่ใช้
          totalKcal += kcalPerUnit * amount;
          totalProtein += proteinPerUnit * amount;
          totalFat += fatPerUnit * amount;
          totalCarbo += carboPerUnit * amount;
        } else {
          // ถ้าไม่พบในฐานข้อมูลทั่วไป ให้ค้นหาในวัตถุดิบของผู้ใช้
          final QuerySnapshot userIngredientSnapshot = await FirebaseFirestore
              .instance
              .collection('users')
              .doc(user.uid)
              .collection('userIngredients')
              .where('ingredientsName', isEqualTo: ingredientName)
              .limit(1)
              .get();

          if (userIngredientSnapshot.docs.isNotEmpty) {
            final data = userIngredientSnapshot.docs.first.data()
                as Map<String, dynamic>;

            // ดึงค่าโภชนาการจากวัตถุดิบของผู้ใช้
            double kcalPerUnit =
                data['kcal'] is num ? (data['kcal'] as num).toDouble() : 0;
            double proteinPerUnit = data['protein'] is num
                ? (data['protein'] as num).toDouble()
                : 0;
            double fatPerUnit =
                data['fat'] is num ? (data['fat'] as num).toDouble() : 0;
            double carboPerUnit =
                data['carbo'] is num ? (data['carbo'] as num).toDouble() : 0;

            // คำนวณตามปริมาณที่ใช้
            totalKcal += kcalPerUnit * amount;
            totalProtein += proteinPerUnit * amount;
            totalFat += fatPerUnit * amount;
            totalCarbo += carboPerUnit * amount;
          }
        }
      }

      setState(() {
        _caloriesController.text = totalKcal.round().toString();
        _proteinController.text = totalProtein.toStringAsFixed(1);
        _fatController.text = totalFat.toStringAsFixed(1);
        _carbsController.text = totalCarbo.toStringAsFixed(1);
        _showNutritionFields = true;
        isCalculatingNutrition = false;
      });

      // แสดงข้อความยืนยัน
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nutrition calculated from ingredients'),
          backgroundColor: Color(0xFF78d454),
        ),
      );
    } catch (e) {
      print('Error calculating nutrition: $e');
      setState(() {
        isCalculatingNutrition = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculating nutrition: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _recipeNameController.addListener(_validateForm);
    _servingsController.addListener(_validateForm);
    _cookingTimeController.addListener(_validateForm);

    if (widget.initialData != null) {
      _recipeNameController.text = widget.initialData!['recipeName'] ?? '';
      _cookingTimeController.text =
          widget.initialData!['totalCookingTime']?.toString() ?? '';
      _servingsController.text =
          widget.initialData!['servings']?.toString() ?? '';

      servingCount =
          int.tryParse(widget.initialData!['servings']?.toString() ?? '1') ?? 1;

      currentRecipe = Recipe(
        recipeId: 0,
        recipeName: widget.initialData!['recipeName'] ?? 'New Recipe',
        description: widget.initialData!['description'] ?? '',
        imageUrl: '',
        category: _selectedCategory,
        ingredients: [],
        instructions: [],
        servings: servingCount,
        preparationTime: 0,
        cookingTime: int.tryParse(
                widget.initialData!['totalCookingTime']?.toString() ?? '0') ??
            0,
        Protein: 0.0,
        Fat: 0.0,
        Carbo: 0.0,
        Kcal: 0,
      );

      _caloriesController.text = widget.initialData!['Kcal']?.toString() ?? '';
      _proteinController.text =
          widget.initialData!['Protein']?.toString() ?? '';
      _carbsController.text = widget.initialData!['Carbo']?.toString() ?? '';
      _fatController.text = widget.initialData!['Fat']?.toString() ?? '';

      _showNutritionFields = _caloriesController.text.isNotEmpty ||
          _proteinController.text.isNotEmpty ||
          _carbsController.text.isNotEmpty ||
          _fatController.text.isNotEmpty;
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
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _validateForm() {
    bool isValid = _recipeNameController.text.isNotEmpty &&
        _servingsController.text.isNotEmpty &&
        int.tryParse(_servingsController.text) != null &&
        _cookingTimeController.text.isNotEmpty &&
        int.tryParse(_cookingTimeController.text) != null;

    _isFormValid.value = isValid;
  }

  Future<String> _uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('recipe_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
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

  Future<void> _createRecipe() async {
    if (!_formKey.currentState!.validate()) {
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
        const SnackBar(
            content: Text('Please add at least one instruction step')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ต้องแก้ไขส่วนนี้ให้รองรับกรณีไม่มีรูปภาพ
      String imageUrl = '';
      if (_ingredientImage != null) {
        // อัปโหลดรูปภาพเฉพาะเมื่อมีรูปภาพ
        imageUrl = await _uploadImage(_ingredientImage!);
      }

      int kcal = _caloriesController.text.isEmpty
          ? 0
          : int.tryParse(_caloriesController.text) ?? 0;
      double protein = _proteinController.text.isEmpty
          ? 0.0
          : double.tryParse(_proteinController.text) ?? 0.0;
      double carbs = _carbsController.text.isEmpty
          ? 0.0
          : double.tryParse(_carbsController.text) ?? 0.0;
      double fat = _fatController.text.isEmpty
          ? 0.0
          : double.tryParse(_fatController.text) ?? 0.0;

      // สร้างข้อมูลสูตรอาหาร
     final recipeData = {
  'recipeId': DateTime.now().millisecondsSinceEpoch,
  'recipeName': _recipeNameController.text,
  'description': '',
  'instructions': instructions,
  'imageUrl': imageUrl,
  'category': _selectedCategory,
  'servings': int.parse(_servingsController.text),
  'preparationTime': 0,
  'cookingTime': int.parse(_cookingTimeController.text),
  'ingredients': ingredients,
  'Protein': protein,
  'Fat': fat,
  'Carbo': carbs,
  'Kcal': kcal,
  'isFavorite': false,
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(), // เพิ่ม updatedAt ด้วย
  'createdBy': FirebaseAuth.instance.currentUser?.uid,
};

      final String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('userRecipe')
          .add(recipeData);


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe created successfully!')),
      );
      if (widget.onRecipeCreated != null) {
        widget.onRecipeCreated!();
      }

      Navigator.pop(context, {
  'created': true,
   'recipeName': _recipeNameController.text,
});
    } catch (e) {
      print('Error creating recipe: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating recipe: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  InputDecoration getCustomDecoration(
      {String? hintText, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Color(0xFFf8f8f7),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Color(0xFF094507))
          : null,
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
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with back button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 10.0),
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
                            'Create Recipe',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                        child: SingleChildScrollView(
                            child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              image: _ingredientImage != null
                                                  ? DecorationImage(
                                                      image: FileImage(
                                                          _ingredientImage!),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child: _ingredientImage == null
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 0),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Recipe Name',
                                                    style: TextStyle(
                                                      color: Color(0xFF094507),
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                controller:
                                                    _recipeNameController,
                                                decoration: getCustomDecoration(
                                                  hintText: 'Enter recipe name',
                                                  prefixIcon:
                                                      Icons.restaurant_menu,
                                                ),
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Please enter a recipe name';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ]),
                                      ),

                                      const SizedBox(height: 16),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                  color: Colors.black),
                                              icon: Icon(Icons.arrow_drop_down,
                                                  color: Color(0xFF094507)),
                                              items: _categories
                                                  .map((String category) {
                                                return DropdownMenuItem<String>(
                                                  value: category,
                                                  child: Text(category),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                if (newValue != null) {
                                                  setState(() {
                                                    _selectedCategory =
                                                        newValue;
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                                                  color: Colors.black),
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Please enter servings';
                                                }
                                                if (int.tryParse(value) ==
                                                    null) {
                                                  return 'Please enter a valid number';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 16),

                                          // Cooking Time
                                          Expanded(
                                            child: TextFormField(
                                              controller:
                                                  _cookingTimeController,
                                              decoration: getCustomDecoration(
                                                hintText:
                                                    'Cooking time in minutes',
                                                prefixIcon: Icons.timer,
                                              ),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black),
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Please enter cooking time';
                                                }
                                                if (int.tryParse(value) ==
                                                    null) {
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                          Expanded(
                                            child: Text(
                                              'Nutritional Information',
                                              style: TextStyle(
                                                color: Color(0xFF094507),
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                               TextButton(
                                                  child: Text(
        _showNutritionFields ? 'Hide' : 'Show',
        style: TextStyle(color: Color(0xFF78d454)),
      ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _showNutritionFields =
                                                          !_showNutritionFields;
                                                    });
                                                  },
                                                 
                                                ),
                                                SizedBox(width: 8),
                                               
                                              ],
                                            ),

                                    ]),
                                      const SizedBox(height: 10),
                                      
                                          if (_showNutritionFields) ...[
                                              ElevatedButton.icon(
                                                  onPressed: isCalculatingNutrition
                                                      ? null
                                                      : _calculateNutritionFromIngredients,
                                                  icon: isCalculatingNutrition
                                                      ? SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child:
                                                              CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  color: Colors
                                                                      .white))
                                                      : Icon(Icons.calculate,
                                                          size: 18),
                                                  label: Text('Auto Calculate'),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Color(0xFF78d454),
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 8),
                                                    textStyle:
                                                        TextStyle(fontSize: 14),
                                                  ),
                                                ),

                                              // Calories and Protein
                                              Row(
                                                children: [
                                                  // Calories
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller:
                                                          _caloriesController,
                                                      decoration:
                                                          getCustomDecoration(
                                                        hintText:
                                                            'Calories (kcal)',
                                                        prefixIcon: Icons
                                                            .local_fire_department,
                                                      ),
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter
                                                            .digitsOnly,
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),

                                                  // Protein
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller:
                                                          _proteinController,
                                                      decoration:
                                                          getCustomDecoration(
                                                        hintText: 'Protein (g)',
                                                        prefixIcon: Icons
                                                            .fitness_center,
                                                      ),
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter
                                                            .allow(RegExp(
                                                                r'^\d*\.?\d*$')),
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
                                                      controller:
                                                          _carbsController,
                                                      decoration:
                                                          getCustomDecoration(
                                                        hintText: 'Carbs (g)',
                                                        prefixIcon: Icons.grain,
                                                      ),
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter
                                                            .allow(RegExp(
                                                                r'^\d*\.?\d*$')),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),

                                                  // Fat
                                                  Expanded(
                                                    child: TextFormField(
                                                      controller:
                                                          _fatController,
                                                      decoration:
                                                          getCustomDecoration(
                                                        hintText: 'Fat (g)',
                                                        prefixIcon:
                                                            Icons.opacity,
                                                      ),
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter
                                                            .allow(RegExp(
                                                                r'^\d*\.?\d*$')),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],

                                            const SizedBox(height: 16),

                                            // Tab Selector (Ingredients/Instructions)

                                            SizedBox(
                                              width: double
                                                  .infinity, // กำหนดความกว้างที่ชัดเจน
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                ),
                                                margin: EdgeInsets.zero,
                                                child: Row(
                                                  children: [
                                                    // Ingredients Tab
                                                    Expanded(
                                                      child: Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: InkWell(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(30),
                                                          onTap: () {
                                                            setState(() {
                                                              showIngredients =
                                                                  true;
                                                            });
                                                          },
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        12),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: showIngredients
                                                                  ? Color(
                                                                      0xFF78d454)
                                                                  : Colors
                                                                      .transparent,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          30),
                                                            ),
                                                            alignment: Alignment
                                                                .center,
                                                            child: Text(
                                                              'Ingredients',
                                                              style: TextStyle(
                                                                color: showIngredients
                                                                    ? Colors
                                                                        .white
                                                                    : Colors.grey[
                                                                        700],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    // Instructions Tab
                                                    Expanded(
                                                      child: Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: InkWell(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(30),
                                                          onTap: () {
                                                            setState(() {
                                                              showIngredients =
                                                                  false;
                                                            });
                                                          },
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        12),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: !showIngredients
                                                                  ? Color(
                                                                      0xFF78d454)
                                                                  : Colors
                                                                      .transparent,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          30),
                                                            ),
                                                            alignment: Alignment
                                                                .center,
                                                            child: Text(
                                                              'Instructions',
                                                              style: TextStyle(
                                                                color: !showIngredients
                                                                    ? Colors
                                                                        .white
                                                                    : Colors.grey[
                                                                        700],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),

                                            // Ingredient/Instruction Content
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20),
                                              child: showIngredients
                                                  ? AddRecipeingredient(
                                                      ingredients:
                                                          recipeIngredientsUI,
                                                      recipe: currentRecipe,
                                                      currentNumber:
                                                          servingCount,
                                                      onAddIngredient:
                                                          (newIngredient) {
                                                        setState(() {
                                                          // เพิ่มวัตถุดิบใหม่ลงในตัวแปร ingredients
                                                          ingredients.add(
                                                              newIngredient);

                                                          // สร้าง Ingredient สำหรับแสดงผลใน UI
                                                          final uiIngredient =
                                                              Ingredient(
                                                            ingredientsName:
                                                                newIngredient[
                                                                    'name'],
                                                            unit: newIngredient[
                                                                'unit'],
                                                            imageUrl:
                                                                'assets/images/ingredient_placeholder.png',
                                                            userId: FirebaseAuth
                                                                    .instance
                                                                    .currentUser
                                                                    ?.uid ??
                                                                'unknown',
                                                            ingredientId: DateTime
                                                                    .now()
                                                                .millisecondsSinceEpoch
                                                                .toString(),
                                                            category: 'Other',
                                                            storage: 'Pantry',
                                                            quantity: 0.0,
                                                            minQuantity: 0.0,
                                                            expirationDate:
                                                                DateTime.now()
                                                                    .add(Duration(
                                                                        days:
                                                                            30)),
                                                            source: 'Recipe',
                                                            kcal: 0.0,
                                                          );

                                                          final uiIngredientUsage =
                                                              IngredientUsage(
                                                            ingredient:
                                                                uiIngredient,
                                                            quantityUsed:
                                                                newIngredient[
                                                                    'amount'],
                                                          );

                                                          recipeIngredientsUI.add(
                                                              uiIngredientUsage);
                                                          _validateForm();
                                                        });
                                                      },
                                                      onRemoveIngredient:
                                                          (index) {
                                                        setState(() {
                                                          // ลบวัตถุดิบออกจากทั้งสองตัวแปร
                                                          ingredients
                                                              .removeAt(index);
                                                          recipeIngredientsUI
                                                              .removeAt(index);
                                                          _validateForm();
                                                        });
                                                      },
                                                    )
                                                  : AddInstruction(
                                                      instructions:
                                                          instructions,
                                                      onAddInstruction:
                                                          (stepDescription) {
                                                        setState(() {
                                                          instructions.add(
                                                              stepDescription);
                                                        });
                                                      },
                                                      onRemoveInstruction:
                                                          (index) {
                                                        setState(() {
                                                          instructions
                                                              .removeAt(index);
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
                                                      if (!_formKey
                                                          .currentState!
                                                          .validate()) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                              content: Text(
                                                                  'Please fill out all required fields correctly')),
                                                        );
                                                        return;
                                                      }
                                                      if (ingredients.isEmpty) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                              content: Text(
                                                                  'Please add at least one ingredient')),
                                                        );
                                                        return;
                                                      }
                                                      if (instructions
                                                          .isEmpty) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                              content: Text(
                                                                  'Please add at least one instruction step')),
                                                        );
                                                        return;
                                                      }

                                                      _createRecipe();
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Color(0xFF78d454),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 15),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Add Recipe',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ])
              ))))],
                                  ),
                                ));
                  
            
    
  }
}
