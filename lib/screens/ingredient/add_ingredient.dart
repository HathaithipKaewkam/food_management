import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/ingredient/ingredient_screen.dart';
import 'package:food_project/screens/root_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

class AddIngredientScreen extends StatefulWidget {
  final Map<String, dynamic>? ingredient;

  const AddIngredientScreen({Key? key, this.ingredient}) : super(key: key);

  @override
  _AddIngredientScreenState createState() => _AddIngredientScreenState();
}

class _AddIngredientScreenState extends State<AddIngredientScreen> {
  final _formKey = GlobalKey<FormState>();
  late String selectedIngredientImage;
  late String selectedIngredientName;
  late String selectedCategory;
  int selectedStorageIndex = 0;
  late String selectedUnit;
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _unitController;
  late TextEditingController _quantityController;
  late TextEditingController _minQuantityController;
  late TextEditingController _shelflifeController;
  late TextEditingController _storageController;
  late String imageUrl;
  late String originalImageUrl;
  DateTime? selectedDate;
  DateTime? _expirationDate;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
   double ingredientKcal = 0.0; 
  String originalUnit = ''; 
  double originalQuantity = 1.0; 
  bool isIngredientInDatabase = false; 


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ingredient?['ingredientsName'] ?? '');
    _categoryController =TextEditingController(text: widget.ingredient?['category'] ?? 'Fruits');
    _unitController =TextEditingController(text: widget.ingredient?['unit'] ?? 'Kilograms (kg)');
    String initialQuantity = widget.ingredient?['quantity']?.toString() ?? "1";
    _quantityController = TextEditingController(text: initialQuantity);
    String initialMinQuantity =
        widget.ingredient?['minQuantity']?.toString() ?? "1";
    _minQuantityController = TextEditingController(text: initialMinQuantity);
    _shelflifeController = TextEditingController(text: widget.ingredient?['shelflife']?.toString() ?? '7');
    _storageController =TextEditingController(text: widget.ingredient?['storage'] ?? 'Fridge');

  
   
    imageUrl = widget.ingredient?['imageUrl'] ?? '';
    selectedIngredientImage = imageUrl.isNotEmpty ? imageUrl : 'assets/images/default_ing.png';
    originalImageUrl = selectedIngredientImage;
  
     if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
    _loadImageUrl();
  } else {
    selectedIngredientImage = imageUrl.isNotEmpty ? imageUrl : 'assets/images/default_ing.png';
    originalImageUrl = selectedIngredientImage;
  }

    selectedIngredientName = widget.ingredient?['name'] ?? '';
    selectedCategory = widget.ingredient?['category'] ?? 'Fruits';
    selectedUnit = widget.ingredient?['unit'] ?? 'Kilograms (kg)';

    String storage = widget.ingredient?['storage'] ?? 'Fridge';
    selectedStorageIndex =
        recipeTypes.contains(storage) ? recipeTypes.indexOf(storage) : 0;

   
    if (widget.ingredient?['expirationDate'] != null) {
      selectedDate = DateTime.tryParse(widget.ingredient!['expirationDate']);
    } else {
      int shelflife = int.tryParse(_shelflifeController.text) ?? 0;
      selectedDate =
          shelflife > 0 ? DateTime.now().add(Duration(days: shelflife)) : null;
    }
    ingredientKcal = widget.ingredient?['kcal']?.toDouble() ?? 0.0;
    _nameController.addListener(() {
    // หน่วงเวลาเล็กน้อยเพื่อไม่ให้ query บ่อยเกินไป
    Future.delayed(Duration(milliseconds: 500), () {
      if (_nameController.text == _nameController.text.trim()) {
        _checkIngredientInDatabase();
      }
    });
  });
  if (widget.ingredient != null && _nameController.text.isNotEmpty) {
    _checkIngredientInDatabase();
  }
  }

  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _shelflifeController.dispose();
    _storageController.dispose();
     _nameController.removeListener(() {});
    super.dispose();
    
  }

Future<void> _checkIngredientInDatabase() async {
  if (_nameController.text.isEmpty) return;
  
  try {
    print("🔍 Checking ingredient: ${_nameController.text.trim()}");
    
    QuerySnapshot ingredientSnapshot = await FirebaseFirestore.instance
        .collection('ingredients')
        .where('ingredientsName', isEqualTo: _nameController.text.trim())
        .get();
    
    print("📊 Found ${ingredientSnapshot.docs.length} ingredients matching the name");
    
    if (ingredientSnapshot.docs.isNotEmpty) {
      DocumentSnapshot doc = ingredientSnapshot.docs.first;
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      setState(() {
        isIngredientInDatabase = true;
        originalUnit = data['unit'] ?? 'Pieces';
        
        // เก็บค่า kcal ต่อหน่วยโดยตรง
        ingredientKcal = (data['kcal'] is int) 
            ? (data['kcal'] as int).toDouble() 
            : (data['kcal'] as num?)?.toDouble() ?? 0.0;
            
        originalQuantity = 1.0; // ค่าเริ่มต้น 1 หน่วย
        
        if (selectedUnit.isEmpty) {
          selectedUnit = originalUnit;
          _unitController.text = originalUnit;
        }
      });
      
      print("✅ Found ingredient in database: ${_nameController.text} - ${ingredientKcal} kcal per $originalUnit");
    } else {
      setState(() {
        isIngredientInDatabase = false;
        ingredientKcal = 0.0;
        print("⚠️ Ingredient not found in database, setting kcal to 0");
      });
    }
  } catch (e) {
    print("❌ Error checking ingredient in database: $e");
    setState(() {
      isIngredientInDatabase = false;
      ingredientKcal = 0.0;
    });
  }
}

Future<void> _loadImageUrl() async {
  try {
    String imagePath = imageUrl;
    if (!imagePath.toLowerCase().endsWith('.png') && !imagePath.toLowerCase().endsWith('.jpg')) {
      imagePath = '$imagePath.png';
    }
    
    String storagePath = imagePath.startsWith('ingredients/') ? imagePath : 'ingredients/$imagePath';
    print("🔍 Loading image from path: $storagePath");
    
    Reference ref = FirebaseStorage.instance.ref().child(storagePath);
    String downloadUrl = await ref.getDownloadURL();
    
    if (mounted) {
      setState(() {
        imageUrl = downloadUrl;
        selectedIngredientImage = downloadUrl;
        originalImageUrl = downloadUrl;
      });
    }
  } catch (e) {
    print("❌ Error loading image URL: $e");
    if (mounted) {
      setState(() {
        imageUrl = '';
        selectedIngredientImage = 'assets/images/default_ing.png';
        originalImageUrl = 'assets/images/default_ing.png';
      });
    }
  }
}
  
  double calculateKcal() {
    if (!isIngredientInDatabase) return 0.0;
    
    double quantity = double.tryParse(_quantityController.text) ?? 1.0;
    
    if (selectedUnit == originalUnit) {
      return ingredientKcal * quantity;
    }
    
    switch (originalUnit) {

      case 'Kilograms (kg)':
        if (selectedUnit == 'Grams (g)') {
    
          return (ingredientKcal / 1000) * quantity;
        }
        break;
        
      case 'Grams (g)':
        if (selectedUnit == 'Kilograms (kg)') {
        
          return (ingredientKcal * 1000) * quantity;
        }
        break;
        
      default:
        return ingredientKcal * quantity;
    }
    
    return ingredientKcal * quantity;
  }

  List<String> recipeTypes = ['Fridge', 'Freezer', 'Pantry'];

  Future<void> _saveIngredient(Map<String, dynamic> newIngredient) async {
    int shelflife =
        int.tryParse(newIngredient['shelflife']?.toString() ?? '0') ?? 0;
    if (!_formKey.currentState!.validate()) return;

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      CollectionReference userIngredients = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('userIngredients');

      CollectionReference historyCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('ingredientsHistory');

      QuerySnapshot existingIngredients = await userIngredients
          .where('ingredientsName', isEqualTo: newIngredient['ingredientsName'])
           .where('storage', isEqualTo: newIngredient['storage'])
          .get();

       double calculatedKcal = isIngredientInDatabase ? calculateKcal() : 0.0;

      if (existingIngredients.docs.isNotEmpty) {
  DocumentSnapshot doc = existingIngredients.docs.first;
  Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;

  // เพิ่มค่า kcal ต่อหน่วย โดยไม่คำนวณ
  double kcalPerUnit = 0.0;
  if (isIngredientInDatabase) {
    // ถ้าเป็นวัตถุดิบที่มีในฐานข้อมูล ใช้ค่า ingredientKcal (ต่อหน่วย) โดยตรง
    kcalPerUnit = ingredientKcal;
  } else if (docData.containsKey('kcal')) {
    // ถ้าไม่มีในฐานข้อมูลแต่มีค่า kcal เดิม ให้ใช้ค่าเดิม
    kcalPerUnit = (docData['kcal'] is int)
        ? (docData['kcal'] as int).toDouble()
        : (docData['kcal'] as num?)?.toDouble() ?? 0.0;
  }

  print("📊 Using kcal per unit: $kcalPerUnit for ${newIngredient['ingredientsName']}");

  await userIngredients.doc(doc.id).update({
    'quantity': FieldValue.increment(newIngredient['quantity']),
    'expirationDate': newIngredient['expirationDate'] ??
        (shelflife > 0
            ? DateTime.now()
                .add(Duration(days: shelflife))
                .toIso8601String()
            : doc['expirationDate'] ??
                DateTime.now().add(Duration(days: 7)).toIso8601String()),
    'updateDate': Timestamp.now(),
    'kcal': kcalPerUnit, // เก็บค่า kcal ต่อหน่วย โดยตรง ไม่ใช่ FieldValue.increment
  });

  // บันทึกประวัติการเพิ่มวัตถุดิบ
  await historyCollection.add({
    'ingredientsName': newIngredient['ingredientsName'],
    'category': newIngredient['category'],
    'unit': newIngredient['unit'],
    'quantityAdded': newIngredient['quantity'],
    'addedDate': Timestamp.now(),
    'source': 'home',
    'imageUrl': newIngredient['imageUrl'] ?? '',
    'storage': newIngredient['storage'],
    'kcal': kcalPerUnit, // ใช้ค่า kcal ต่อหน่วย
  });
} else {
  // กรณีเป็นวัตถุดิบใหม่
  // ใช้ค่า kcal ต่อหน่วยจากฐานข้อมูล ไม่ใช่ค่าที่คำนวณ
  double kcalPerUnit = isIngredientInDatabase ? ingredientKcal : 0.0;
  
  newIngredient['kcal'] = kcalPerUnit; // เก็บค่า kcal ต่อหน่วย
  newIngredient['createDate'] = Timestamp.now();

  DocumentReference newDoc = await userIngredients.add(newIngredient);

  // บันทึกประวัติการเพิ่มวัตถุดิบ
  await historyCollection.add({
    'ingredientsName': newIngredient['ingredientsName'],
    'category': newIngredient['category'],
    'unit': newIngredient['unit'],
    'quantityAdded': newIngredient['quantity'],
    'addedDate': Timestamp.now(),
    'source': 'home',
    'imageUrl': newIngredient['imageUrl'] ?? '',
    'storage': newIngredient['storage'],
    'kcal': kcalPerUnit, // ใช้ค่า kcal ต่อหน่วย
  });
}
    } catch (e) {
      print("❌ Error saving ingredient: $e");
      throw e;
    }
  }

  Future<List<Ingredient>> fetchIngredients() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('userIngredients')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Ingredient.fromJson(data);
    }).toList();
  }

  void showSuccessAlert(
      BuildContext context, List<Ingredient> updatedIngredientList) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: 'Success',
      text: 'Ingredient add successfully!',
      confirmBtnText: 'OK',
      onConfirmBtnTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => RootPage(initialIndex: 1),
          ),
          (route) => false,
        );
      },
    );
  }

  void _onPressedAdd() async {
  try {

    if (_nameController.text.trim().isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Please enter ingredient name',
        confirmBtnColor: const Color(0xFF325b51),
      );
      return;
    }

    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
    }

    DateTime expirationDate = _expirationDate ??
        (int.tryParse(_shelflifeController.text) != null
            ? DateTime.now().add(Duration(days: int.parse(_shelflifeController.text)))
            : DateTime.now().add(Duration(days: 7)));

    double quantity = double.tryParse(_quantityController.text) ?? 1.0;
    double minQuantity = double.tryParse(_minQuantityController.text) ?? 1.0;
    double kcalPerUnit = isIngredientInDatabase ? ingredientKcal : 0.0;

    Map<String, dynamic> newIngredient = {
      'ingredientsName': _nameController.text.trim(),
      'category': _categoryController.text,
      'storage': recipeTypes[selectedStorageIndex],
      'unit': _unitController.text,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'expirationDate': expirationDate.toIso8601String(),
      'imageUrl': imageUrl,
      'source': 'home',
      'kcal':  kcalPerUnit,
    };

    await _saveIngredient(newIngredient);
    List<Ingredient> updatedIngredientList = await fetchIngredients();
    showSuccessAlert(context, updatedIngredientList);
  } catch (e) {
    print("❌ Error in _onPressedAdd: $e");
  }
}

  // 🔹 ฟังก์ชันเลือกวันหมดอายุ
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
              // ใช้ Theme ที่ต้องการ
              primaryColor: Color(0xFFb2e6b2), // สีของการเลือกวันที่
              primaryColorLight: Colors.white, // สีพื้นหลังของปฏิทิน
              dialogBackgroundColor: Colors.white, // สีพื้นหลังของกล่องเลือกวัน
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                ),
              ),
              colorScheme: ColorScheme.fromSwatch().copyWith(
                primary: Color(0xFFb2e6b2),
                onSurface: Colors.black,
                surface: Colors.white,
              )),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
        _expirationDate = pickedDate;
      });
    }
  }

  Widget _buildDatePicker(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFf8f8f7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                child: Text(
                  selectedDate != null
                      ? DateFormat('d MMMM yyyy').format(selectedDate!)
                      : "Choose Expiry Date",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selectedDate != null ? Colors.black : Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: const FaIcon(
              FontAwesomeIcons.calendar,
              color: Color(0xFF094507),
            ),
          )
        ],
      ),
    );
  }

  Future<List<String>> fetchUserAllergies(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('userAllergies')
          .doc(userId)
          .get();

      if (doc.exists) {
        return List<String>.from(doc.data()?['allergies'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print("❌ Error fetching user allergies: $e");
      return [];
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void resetToOriginalImage() {
    setState(() {
      _imageFile = null;
      selectedIngredientImage = originalImageUrl;
    });
  }

  Future<String> _uploadImage(File imageFile) async {
  try {
    final String fileName = 'ingredient_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = FirebaseStorage.instance.ref().child('ingredient_images/$fileName');
    final uploadTask = await storageRef.putFile(imageFile);
    final downloadUrl = await storageRef.getDownloadURL();
    print("✅ Image uploaded successfully: $downloadUrl");
    return downloadUrl;
  } catch (e) {
    print("❌ Error uploading image: $e");
    throw e;
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Ingredient'),
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
        padding: const EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    // รูปภาพ
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: _imageFile != null
                          ? Image.file(_imageFile!, height: 100, width: 100, fit: BoxFit.contain)
    : imageUrl.isNotEmpty && imageUrl.startsWith('http')
        ? Image.network(
            imageUrl,
            height: 100,
            width: 100,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              print("❌ Error loading image: $error");
              return Image.asset(
                'assets/images/default_ing.png',
                height: 100,
                width: 100,
                fit: BoxFit.contain,
              );
            },
          )
        : Image.asset(
            'assets/images/default_ing.png',
            height: 100,
            width: 100,
            fit: BoxFit.contain,
          ),
                      ),
                    ),

                    // ปุ่มไอคอนแก้ไขที่มุมขวาล่าง
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Choose an option'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading:
                                          FaIcon(FontAwesomeIcons.photoFilm),
                                      title: Text('Select photo'),
                                      onTap: () {
                                        _pickImage(ImageSource.gallery);
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ListTile(
                                      leading: FaIcon(FontAwesomeIcons.camera),
                                      title: Text('Open camera'),
                                      onTap: () {
                                        _pickImage(ImageSource.camera);
                                        Navigator.pop(context);
                                      },
                                    ),
                                    if (_imageFile != null ||
                                        selectedIngredientImage !=
                                            originalImageUrl)
                                      ListTile(
                                        leading: FaIcon(FontAwesomeIcons.trash,
                                            color: Colors.red),
                                        title: Text('Delete Photo',
                                            style:
                                                TextStyle(color: Colors.red)),
                                        onTap: () {
                                          resetToOriginalImage();
                                          Navigator.pop(context);
                                        },
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.green,
                          radius: 16,
                          child:
                              Icon(Icons.edit, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),
              //ชื่อวัตถุดิบ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Ingredient Name',
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
                        controller: _nameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Color(0xFFf8f8f7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black),
                        onChanged: (value) {
                          setState(() {
                            selectedIngredientName = value;
                          });
                        },
                      ),
                    ]),
              ),
              //Category
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Category',
                            style: TextStyle(
                              color: Color(0xFF094507),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFFf8f8f7)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          underline: const SizedBox(),
                          value: selectedCategory.isNotEmpty
                              ? selectedCategory
                              : null,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCategory = newValue!;
                            });
                          },
                          items: <String>[
                            'Fruits',
                            'Vegetables',
                            'Meat',
                            'Seafood',
                            'Cold Cuts',
                            'Dairy',
                            'Bread',
                            'Cake & Biscuits',
                            'Alcoholic Beverages',
                            'Beverages',
                            'Coffee & Tea',
                            'Snacks',
                            'Sweets',
                            'Condiments & Dips',
                            'Dry Goods',
                            'Nuts & Seeds',
                            'Canned Food',
                            'Cereals',
                            'Leftovers',
                            'Easy Meals',
                            'Household Essentials',
                            'Baking Goods',
                            'Other goods',
                            'Frozen foods',
                            'Spices',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                        ),
                      )
                    ]),
              ),
              //Storage
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Storage',
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
                      children: List.generate(recipeTypes.length, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedStorageIndex = index;
                              _storageController.text = recipeTypes[index];
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            decoration: BoxDecoration(
                              color: selectedStorageIndex == index
                                  ? Color(0xFFb2e6b2)
                                  : Color(0xFFf8f8f7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                recipeTypes[index],
                                style: TextStyle(
                                  color: selectedStorageIndex == index
                                      ? Colors.black
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              //Quantity
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Quantity',
                          style: TextStyle(
                            color: Color(0xFF094507),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 30),
                        Text(
                          'Unit',
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
                        Expanded(
                          flex: 1,
                          child: TextField(
                              controller: _quantityController,
                             keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Color(0xFFf8f8f7),
                                hintText: "1",
                                hintStyle:
                                    TextStyle(fontWeight: FontWeight.bold),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')), 
                              ],
                              onTap: () {
                                _quantityController.clear();
                              },
                              onChanged: (value) {
                                if (value == ".") {
                                  _quantityController.text = "0.";
                                  _quantityController.selection =
                                      TextSelection.collapsed(offset: 2);
                                }
                              },
                              onEditingComplete: () {
                                if (_quantityController.text.isEmpty ||
                                    double.tryParse(_quantityController.text) ==
                                        null) {
                                  setState(() {
                                    _quantityController.text = "1.0";
                                  });
                                }
                              }),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFFf8f8f7)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedUnit.isNotEmpty
                                      ? selectedUnit
                                      : null,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedUnit = newValue!;
                                    });
                                  },
                                  items: <String>[
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
                                    'Cob',
                                  ].map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                ),
                              )),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              //Min Quantity
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Min Quantity',
                          style: TextStyle(
                            color: Color(0xFF094507),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 30),
                        Text(
                          'Unit',
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
                        Expanded(
                          flex: 1,
                          child: TextField(
                              controller: _minQuantityController,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Color(0xFFf8f8f7),
                                hintText: "1",
                                hintStyle:
                                    TextStyle(fontWeight: FontWeight.bold),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')), 
                              ],
                              onTap: () {
                                _minQuantityController.clear();
                              },
                              onChanged: (value) {
                                if (value == ".") {
                                  _minQuantityController.text = "0.";
                                  _minQuantityController.selection =
                                      TextSelection.collapsed(offset: 2);
                                }
                              },
                              onEditingComplete: () {
                                if (_minQuantityController.text.isEmpty ||
                                    double.tryParse(
                                            _minQuantityController.text) ==
                                        null) {
                                  setState(() {
                                    _minQuantityController.text = "1.0";
                                  });
                                }
                              }),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                           flex: 3,
                           child: Container(
                               padding:
                                   const EdgeInsets.symmetric(horizontal: 10),
                               decoration: BoxDecoration(
                                 border: Border.all(color: Color(0xFFf8f8f7)),
                                borderRadius: BorderRadius.circular(10),
                               ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                   isExpanded: true,
                                  value: selectedUnit,
                                   onChanged: (String? newValue) {
                                    setState(() {
                                       selectedUnit = newValue!;
                                    });
                                  },
                                   items: <String>[
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
                                    'Cob',
                                  ].map<DropdownMenuItem<String>>(
                                      (String value) {
                                     return DropdownMenuItem<String>(
                                       value: value,
                                      child: Text(value,
                                           style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                     );
                                   }).toList(),
                               ),
                              )),
                         ),
                      ],
                    ),
                  ],
                ),
              ),
              //Expiry Date
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expiry Date',
                            style: TextStyle(
                              color: Color(0xFF094507),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: _buildDatePicker(context),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                    ]),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _onPressedAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF325b51),
                    minimumSize: const Size(50, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 80),
                  ),
                  child: const Text(
                    'Add Ingredient',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
