import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_project/models/recipe.dart';

class AddRecipeingredient extends StatefulWidget {
  final List<IngredientUsage> ingredients;
  final Recipe recipe;
  final int currentNumber;
  final Function(Map<String, dynamic>)? onAddIngredient;
  final Function(int)? onRemoveIngredient;

  const AddRecipeingredient({
    super.key,
    required this.ingredients,
    required this.recipe,
    required this.currentNumber,
    this.onAddIngredient,
    this.onRemoveIngredient,
  });

  @override
  State<AddRecipeingredient> createState() => _RecipeIngredientWidgetState();
}

class _RecipeIngredientWidgetState extends State<AddRecipeingredient> {
  final List<String> _commonUnits = [
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
  ];

  void _showAddIngredientBottomSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    String selectedUnit = _commonUnits[0]; // ค่าเริ่มต้น
    final _formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Add Ingredient',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      
                      // Ingredient Name
                      Text(
                        'Ingredient Name',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      // แก้ไขการ validate ของ Ingredient Name
TextFormField(
  controller: nameController,
  decoration: InputDecoration(
    hintText: 'Enter ingredient name',
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    prefixIcon: Icon(Icons.food_bank),
  ),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
  ],
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an ingredient name';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Only alphabets are allowed';
    }
    return null;
  },
),


                      SizedBox(height: 16),
                      
                     
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Amount Column
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Amount',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
  controller: amountController,
  keyboardType: TextInputType.numberWithOptions(decimal: true),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
  ],
  decoration: InputDecoration(
    hintText: 'e.g. 100',
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    double? parsedValue = double.tryParse(value);
    if (parsedValue == null) {
      return 'Enter a valid number';
    }
    if (parsedValue <= 0) {
      return 'Must be greater than 0';
    }
    return null;
  },
),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          
                          // Unit Column with Dropdown
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unit',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedUnit,
                                      isExpanded: true,
                                      items: _commonUnits.map((String unit) {
                                        return DropdownMenuItem<String>(
                                          value: unit,
                                          child: Text(unit),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            selectedUnit = newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Buttons
                      Row(
                        children: [
                          // Cancel Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black,
                                backgroundColor: Colors.grey[200],
                                padding: EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          
                          // Add Button - แก้ไขเป็นส่งข้อมูลแบบ Map
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // เก็บข้อมูลจากฟอร์ม
                                  String ingredientName = nameController.text.trim();
                                  double amount = double.parse(amountController.text);
                                  String unit = selectedUnit;
                                  
                                  // ส่งข้อมูลกลับในรูปแบบ Map อย่างง่าย
                                  final ingredientData = {
                                    'name': ingredientName,
                                    'amount': amount,
                                    'unit': unit,
                                  };
                                  
                                  // ส่งข้อมูลกลับไปที่หน้า create_recipe
                                  if (widget.onAddIngredient != null) {
                                    widget.onAddIngredient!(ingredientData);
                                  }
                                  
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Color(0xFF78d454),
                                padding: EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Add',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (widget.onAddIngredient != null)
                  ElevatedButton.icon(
                    onPressed: _showAddIngredientBottomSheet,
                    icon: Icon(Icons.add, size: 18 , color: Colors.white,),
                    label: Text("Add Ingredient"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF78d454),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
          ],
        ),
ListView.builder(
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  padding: EdgeInsets.symmetric(vertical: 8), // เพิ่ม padding ให้กับ ListView
  itemCount: widget.ingredients.length,
  itemBuilder: (context, index) {
    final ingredient = widget.ingredients[index];
    
    return Container(
      margin: EdgeInsets.only(bottom: 8), // เพิ่มระยะห่างระหว่างรายการ
      width: double.infinity, // ให้กว้างเต็มพื้นที่
      child: Dismissible(
        key: Key(ingredient.ingredient.ingredientId),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.0),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10), // ปรับให้ตรงกับ Card
          ),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        onDismissed: (direction) {
          if (widget.onRemoveIngredient != null) {
            widget.onRemoveIngredient!(index);
          }
        },
        child: Card(
          elevation: 1,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shadowColor: Colors.grey[200], // ทำให้เงาอ่อนลง
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                // Avatar ด้านซ้าย
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF78d454).withOpacity(0.2),
                  child: Icon(Icons.dining, color: Color(0xFF78d454), size: 22),
                ),
                SizedBox(width: 16),
                
                // เนื้อหาหลัก
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ingredient.ingredient.ingredientsName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${ingredient.quantityUsed} ${ingredient.ingredient.unit}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
              ],
            ),
          ),
        ),
      ),
    );
  },
),
      ],
    );
  }
}