import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddIngredientScreen extends StatefulWidget {
  final Map<String, String> ingredient;

  AddIngredientScreen({required this.ingredient});

  @override
  _AddIngredientScreenState createState() => _AddIngredientScreenState();
}

class _AddIngredientScreenState extends State<AddIngredientScreen> {
  final _formKey = GlobalKey<FormState>();
  String ingredientName = '';
  String selectedIngredientImage = '';
  String selectedIngredientName = '';
  String selectedCategory = 'Dairy';
  int selectedStorageIndex = -1;
  String selectedUnit = 'Kilograms (kg)';
  double quantity = 0.0;
  double price = 0.0;
  String unit = '';
  DateTime expDate = DateTime.now();
  String storage = 'Fridge'; // Default storage
  late TextEditingController _ingredientController;

  TextEditingController _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ingredientName = widget.ingredient['name']!;
    selectedIngredientImage = widget.ingredient['image']!;
    selectedIngredientName = widget.ingredient['name'] ?? 'Unnamed Ingredient';
    _ingredientController = TextEditingController(text: selectedIngredientName);
     _quantityController.text = '1';
  }

  void dispose() {
    _ingredientController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  List<String> recipeTypes = ['Fridge', 'Freezer', 'Pantry'];

  // ฟังก์ชั่นบันทึกข้อมูล
  void _saveIngredient() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // ส่งข้อมูลไปยังฐานข้อมูลหรือหน้าจออื่น
      print('Ingredient Name: $ingredientName');
      print('Quantity: $quantity');
      print('Price: $price');
      print('Unit: $unit');
      print('Expiration Date: $expDate');
      print('Storage: $storage');
      Navigator.pop(context);
    }
  }

  

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Ingredient'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(16), 
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.0,
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(10.0), 
                    child: Image.asset(
                      selectedIngredientImage,
                      height: 100, 
                      width: 100, 
                      fit: BoxFit.contain, 
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

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
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _ingredientController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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
                              color: Colors.black,
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
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          underline: const SizedBox(),
                          value: selectedCategory,
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
                            'Cold cuts',
                            'Dairy',
                            'Bread',
                            'Cake & biscuits',
                            'Alcoholic beverages',
                            'Beverages',
                            'Coffee & tea',
                            'Snacks',
                            'Sweets',
                            'Condiments & dips',
                            'Dry goods',
                            'Nuts & seeds',
                            'Canned food',
                            'Cereals',
                            'Leftovers',
                            'Easy meals',
                            'Household essentials',
                            'Baking goods',
                            'Other goods',
                            'Frozen foods',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
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
                                color: Colors.black,
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
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                decoration: BoxDecoration(
                                  color: selectedStorageIndex == index
                                      ? const Color(0xFFb2e6b2)
                                      : Colors.white, 
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey),
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
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 30),
                        Text(
                          'Unit',
                          style: TextStyle(
                            color: Colors.black,
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
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "1",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  if (int.tryParse(value) != null && int.parse(value) <= 0) {
                                    _quantityController.text = '1';  
                                    _quantityController.selection = TextSelection.fromPosition(TextPosition(offset: _quantityController.text.length));
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3, 
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
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
                                    'Pieces',
                                    'Boxes',
                                    'Cups',
                                    'Cans',
                                    'Packs',
                                  ].map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
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
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 30),
                        Text(
                          'Unit',
                          style: TextStyle(
                            color: Colors.black,
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
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "1",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  if (int.tryParse(value) != null && int.parse(value) <= 0) {
                                    _quantityController.text = '1';  
                                    _quantityController.selection = TextSelection.fromPosition(TextPosition(offset: _quantityController.text.length));
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3, 
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
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
                                    'Pieces',
                                    'Boxes',
                                    'Cups',
                                    'Cans',
                                    'Packs',
                                  ].map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Expiration Date',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      
                    ]),
              ),
                  
                  ],
                ),
              ),

                 



              
              
            
          ),
        );
      
    
  }
}
