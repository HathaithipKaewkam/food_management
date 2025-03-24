import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/root_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

class EditIngredientScreen extends StatefulWidget {
  final Map<String, dynamic>? ingredient;

  const EditIngredientScreen({Key? key, this.ingredient}) : super(key: key);

  @override
  _EditIngredientScreenState createState() => _EditIngredientScreenState();
}

class _EditIngredientScreenState extends State<EditIngredientScreen> {
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
  
    if (imageUrl != null && imageUrl!.startsWith('http')) {
      selectedIngredientImage = imageUrl; // ใช้ URL ถ้า imageUrl เป็น URL
    } else {
      selectedIngredientImage =
          'assets/images/default_ing.png'; // ใช้ asset ถ้าไม่ใช่ URL
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
  }

  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _shelflifeController.dispose();
    _storageController.dispose();
    super.dispose();
  }

  List<String> recipeTypes = ['Fridge', 'Freezer', 'Pantry'];

  Future<void> _updateIngredient() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // If new image was selected, upload it
    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
    }

    // Get expiration date
    DateTime expirationDate = _expirationDate ?? 
      selectedDate ?? 
      DateTime.now().add(Duration(days: int.parse(_shelflifeController.text)));

    // Create update data
    Map<String, dynamic> updateData = {
      'ingredientsName': _nameController.text,
      'category': selectedCategory,
      'storage': recipeTypes[selectedStorageIndex],
      'unit': selectedUnit,
      'quantity': double.parse(_quantityController.text),
      'minQuantity': double.parse(_minQuantityController.text),
      'expirationDate': expirationDate.toIso8601String(),
      'imageUrl': imageUrl,
      'updateDate': Timestamp.now(),
    };

    // Get the correct document ID from the ingredient passed to widget
    String docId = widget.ingredient?['id'] ?? // Try to get the 'id' field first
                  widget.ingredient?['ingredientId'] ?? // Then try 'ingredientId'
                  widget.ingredient?['docId']; // Finally try 'docId'

    if (docId == null || docId.isEmpty) {
      throw Exception('Invalid document ID');
    }

    print("📝 Updating ingredient with ID: $docId");

    // Update the document
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userIngredients')
        .doc(docId)
        .update(updateData);

    if (context.mounted) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'Success',
        text: 'Ingredient updated successfully!',
        confirmBtnText: 'OK',
        onConfirmBtnTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => RootPage(initialIndex: 1)),
            (route) => false,
          );
        },
      );
    }
  } catch (e) {
    print("❌ Error updating ingredient: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating ingredient: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        title: const Text('Edit Ingredient'),
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
                             : imageUrl.isNotEmpty
                             ? Image.network(
                          imageUrl,
                          height: 100,
                          width: 100,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
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
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*$')),
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
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*$')),
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
                  onPressed: _updateIngredient, 
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
                    'Update Ingredient',
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
