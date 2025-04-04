import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/widgets/instruction_widget.dart';
import 'package:food_project/widgets/recipe_ingredient_widget.dart';

class RecipeDetail extends StatefulWidget {
  final Recipe recipe; // รับ Recipe แทน RecipeId
  final int recipeId; // รับ recipeId

  const RecipeDetail({super.key, required this.recipe, required this.recipeId});

  @override
  State<RecipeDetail> createState() => _RecipeDetailState();
}

class _RecipeDetailState extends State<RecipeDetail> {
  int currentNumber = 1;
  bool showIngredients = true;
  List<Map<String, dynamic>> userIngredients = [];
  List<Recipe> recipeList = Recipe.recipeList;

  // Toggle Favorite button
  bool toggleIsFavorated(bool isFavorited) {
    return !isFavorited;
  }

  Widget _buildMealChip(String meal, String selectedMeal, Function(String) onSelected) {
  final isSelected = meal == selectedMeal;
  
  return GestureDetector(
    onTap: () => onSelected(meal),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF78d454) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF78d454) : Colors.grey[300]!,
        ),
      ),
      child: Text(
        meal,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ),
  );
}

  ImageProvider<Object> _getImageProvider(String imageUrl) {
    if (imageUrl.isEmpty) {
      return AssetImage('assets/images/placeholder.png');
    } else if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
      return NetworkImage(imageUrl);
    } else if (imageUrl.startsWith('assets/')) {
      return AssetImage(imageUrl);
    } else {
      return AssetImage('assets/images/placeholder.png');
    }
  }

  @override
void initState() {
  super.initState();
  fetchUserIngredients();
}

void fetchUserIngredients() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userIngredients')
        .get();
    
    setState(() {
      userIngredients = snapshot.docs.map((doc) {
        return doc.data();
      }).toList();
    });
  } catch (e) {
    print('Error fetching user ingredients: $e');
  }
}

bool _hasIngredient(Ingredient recipeIngredient) {
  return userIngredients.any((userIngredient) => 
    userIngredient['ingredient']['ingredientsName'].trim().toLowerCase() == 
    recipeIngredient.ingredientsName.trim().toLowerCase());
}



  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(
            children: [
           Positioned(
  child: widget.recipe.imageUrl.isEmpty ? 
    Container(
      height: MediaQuery.of(context).size.width,
      color: Colors.grey[200],
      child: Center(
        child: Image.asset(
          'assets/images/placeholder.png',
          width: 300,
          height: 250,
        ),
      ),
    ) : 
    Container(
      height: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: _getImageProvider(widget.recipe.imageUrl),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            print('Error loading image: $exception');
          },
        ),
      ),
    ),
),
              Positioned(
                top: 55,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (BuildContext context) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.share,
                                        color: Color(0xFF78d454)),
                                    title: const Text('แชร์สูตรอาหาร'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      // เพิ่มฟังก์ชันแชร์ที่นี่
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.edit,
                                        color: Color(0xFF78d454)),
                                    title: const Text('แก้ไขสูตรอาหาร'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      // นำทางไปยังหน้าแก้ไขสูตรอาหาร
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.bookmark,
                                        color: Color(0xFF78d454)),
                                    title: const Text('บันทึกลงคอลเลคชัน'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      // เพิ่มฟังก์ชันบันทึก
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.report_problem,
                                        color: Colors.redAccent),
                                    title: const Text('รายงานปัญหา'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      // เพิ่มฟังก์ชันรายงาน
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                        ),
                        child: const Icon(Icons.more_horiz),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: MediaQuery.of(context).size.width - 30,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      )),
                ),
              )
            ],
          ),
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Recipe name
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.recipe.recipeName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Time cooking
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF78d454),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${widget.recipe.totalCookingTime()} mins",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Protein',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Fat',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Carbo',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Calories',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/images/protein.png',
                            width: 20, height: 20),
                        const SizedBox(width: 2),
                        Text('${widget.recipe.Protein} g',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 30),
                        Image.asset('assets/images/fat.png',
                            width: 20, height: 20),
                        const SizedBox(width: 2),
                        Text('${widget.recipe.Fat} g',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 27),
                        Image.asset('assets/images/carbo.png',
                            width: 23, height: 20),
                        const SizedBox(width: 2),
                        Text('${widget.recipe.Carbo} g',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 50),
                        Image.asset('assets/images/kcal.png',
                            width: 23, height: 17),
                        const SizedBox(width: 1),
                        Text('${widget.recipe.Kcal} Kcal',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 10),
                          Image.asset(
                            'assets/images/group.png',
                            width: 35,
                            height: 35,
                          ),
                          const SizedBox(
                              width: 10), // เว้นระยะระหว่างไอคอนและข้อความ
                          const Text(
                            "Persons",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87, // สีข้อความ
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (currentNumber > 1) {
                                setState(() {
                                  currentNumber--;
                                });
                              }
                            },
                            icon: const Icon(Icons.remove),
                            iconSize: 20,
                            color: Colors.redAccent,
                          ),
                          Text(
                            "$currentNumber",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                currentNumber++;
                              });
                            },
                            icon: const Icon(Icons.add),
                            iconSize: 20,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          //ปุ่ม ingredient/step

          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(
                maxWidth: 300,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        showIngredients = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: showIngredients
                            ? Color(0xFF78d454)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Ingredients',
                        style: TextStyle(
                          color:
                              showIngredients ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        showIngredients = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: !showIngredients
                            ? Color(0xFF78d454)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Instructions',
                        style: TextStyle(
                          color: !showIngredients
                              ? Colors.white
                              : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: showIngredients
                ? RecipeIngredientWidget(
                    ingredients: widget.recipe.ingredients,
                    recipe: widget.recipe,
                    currentNumber: currentNumber,
                    userIngredients: userIngredients,
                  )
                : InstructionsWidget(
                    instructions:
                        widget.recipe.instructions, // แสดง instructions
                  ),
          ),
          SizedBox(height: 20),
          Row( 
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
            padding: const EdgeInsets.only(left: 20 , bottom: 10),
          child: Container(
            height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        
                      },
                      icon: const Icon(
                        Icons.restaurant_outlined,
                        color: Colors.black,
                        size: 25,
                      ),
                    ),
                  ),
          ),
          SizedBox(width: 10),
           Padding(
            padding: const EdgeInsets.only(bottom: 10 , right: 20),
          child: Container(
            height: 60,
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      
                    ),
                    child: ElevatedButton(
  onPressed: () {
    // Show meal planner bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        
        DateTime selectedDate = DateTime.now();
        String selectedMeal = "Breakfast"; 
        
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
             
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // หัวข้อ
                  const Center(
                    child: Text(
                      "Add to Meal Plan",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
              
                  Card(
                    elevation: 0,
                    color: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // รูปภาพอาหาร
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: widget.recipe.imageUrl.isNotEmpty
                                    ? _getImageProvider(widget.recipe.imageUrl)
                                    : const AssetImage('assets/images/placeholder.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // ข้อมูลอาหาร
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.recipe.recipeName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${widget.recipe.totalCookingTime()} mins • ${widget.recipe.Kcal} kcal",
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
                  const SizedBox(height: 20),
                  
                  // เลือกมื้ออาหาร
                  const Text(
                    "Choose Meal",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ตัวเลือกมื้ออาหาร
                  Wrap(
                    spacing: 10,
                    children: [
                      _buildMealChip("Breakfast", selectedMeal, (meal) {
                        setState(() => selectedMeal = meal);
                      }),
                      _buildMealChip("Lunch", selectedMeal, (meal) {
                        setState(() => selectedMeal = meal);
                      }),
                      _buildMealChip("Dinner", selectedMeal, (meal) {
                        setState(() => selectedMeal = meal);
                      }),
                      _buildMealChip("Snack", selectedMeal, (meal) {
                        setState(() => selectedMeal = meal);
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // เลือกวันที่
                  const Text(
                    "Choose Date",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ปุ่มเลือกวันที่
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF78d454),
                                onPrimary: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // ปุ่ม Cancel และ Add
                  Row(
                    children: [
                      // ปุ่ม Cancel
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // ปุ่ม Add
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // เพิ่มโค้ดสำหรับบันทึกลงแผนมื้ออาหารที่นี่
                            // เช่น บันทึกลง Firebase
                            print("Save to meal plan: ${widget.recipe.recipeName} for $selectedMeal on ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}");
                            
                            // แสดงข้อความยืนยัน
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Added to Meal Plan successfully!"),
                                backgroundColor: Color(0xFF78d454),
                              ),
                            );
                            
                            // ปิด bottom sheet
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: const Color(0xFF78d454),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Add",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    elevation: 0,
    padding: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: const Text(
    "Add to Meal Plan",
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Color(0xFF78d454),
    ),
  ),
),
                  ),
          ),
            ],
            
          )
         
          
        ]),
      ),
    );
  }
}
