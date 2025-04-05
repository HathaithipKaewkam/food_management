import 'package:calendar_agenda/calendar_agenda.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/screens/home/add_schedule.dart';
import 'package:food_project/screens/recipe/recipe_screen.dart';
import 'package:food_project/services/meal_plan_service.dart';
import 'package:food_project/widgets/meal_plan.dart';

import '../../../common/colo_extension.dart';
import '../../../common/common.dart';
import '../../../common_widget/round_button.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({
    super.key,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  CalendarAgendaController _calendarAgendaControllerAppBar =
      CalendarAgendaController();
  late DateTime _selectedDateAppBBar;


  final MealPlanService _mealPlanService = MealPlanService();
Map<String, dynamic> mealPlans = {
  'breakfast': {'recipes': [], 'totalCalories': 0},
  'lunch': {'recipes': [], 'totalCalories': 0},
  'dinner': {'recipes': [], 'totalCalories': 0},
  'snack': {'recipes': [], 'totalCalories': 0},
};

Future<void> _loadMealPlans() async {
  try {
    final plans = await _mealPlanService.getMealPlansForDate(_selectedDateAppBBar);
    setState(() {
      mealPlans = plans;
    });
  } catch (e) {
    print('Error loading meal plans: $e');
  }
}
  

  List eventArr = [
    {
      "name": "Lunch",
      "start_time": "08/12/2024 01:00 PM",
    }
  ];

  List selectDayEventArr = [];

  @override
  void initState() {
    super.initState();
    _selectedDateAppBBar = DateTime.now();
    setDayEventList();
    _loadMealPlans();
  }

  void setDayEventList() {
    var date = dateToStartDate(_selectedDateAppBBar);
    selectDayEventArr = eventArr.map((wObj) {
      return {
        "name": wObj["name"],
        "start_time": wObj["start_time"],
        "date": stringToDate(wObj["start_time"].toString(),
            formatStr: "dd/MM/yyyy hh:mm aa")
      };
    }).where((wObj) {
      return dateToStartDate(wObj["date"] as DateTime) == date;
    }).toList();

    if (mounted) {
      setState(() {});
    }
  }

  void _addNewMeal(String mealName, String mealType) {
  DateTime now = _selectedDateAppBBar;
  int hour;
  
  switch (mealType) {
    case "breakfast":
      hour = 8; 
      break;
    case "lunch":
      hour = 13; 
      break;
    case "snack":
      hour = 16; 
      break;
    case "dinner":
      hour = 19; 
      break;
    default:
      hour = 12;
  }
  
  // สร้างวันที่และเวลาใหม่
  DateTime mealTime = DateTime(now.year, now.month, now.day, hour, 0);
  // ฟอร์แมตวันที่เป็นสตริง
  String formattedDate = "${mealTime.day.toString().padLeft(2, '0')}/${mealTime.month.toString().padLeft(2, '0')}/${mealTime.year}";
  String formattedTime = "${hour > 12 ? (hour - 12).toString().padLeft(2, '0') : hour.toString().padLeft(2, '0')}:00 ${hour >= 12 ? 'PM' : 'AM'}";
  String formattedDateTime = "$formattedDate $formattedTime";
  
  // สร้างออบเจ็กต์มื้ออาหารใหม่
  Map<String, dynamic> newMeal = {
    "name": mealName,
    "start_time": formattedDateTime,
    "meal_type": mealType,
    "recipes": [], // Add an empty list to store recipes
    "total_calories": 0, // Add total calories counter
  };
  
  // เพิ่มมื้ออาหารใหม่เข้าไปใน eventArr
  setState(() {
    eventArr.add(newMeal);
    setDayEventList(); // อัพเดทรายการกิจกรรมของวัน
  });
}

 String _getFormattedDate(DateTime date) {
  final now = DateTime.now();
  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  
  final List<String> weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  
  // ตรวจสอบว่าเป็นวันนี้หรือไม่
  bool isToday = date.year == now.year && date.month == now.month && date.day == now.day;
  
  if (isToday) {
    return "Today, ${months[date.month - 1]} ${date.day}, ${date.year}";
  } else {
    // ตรวจสอบว่าเป็นวันพรุ่งนี้หรือไม่
    final tomorrow = now.add(Duration(days: 1));
    bool isTomorrow = date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
    
    if (isTomorrow) {
      return "Tomorrow, ${months[date.month - 1]} ${date.day}, ${date.year}";
    } else {
      // วันอื่นๆ แสดงชื่อวัน
      return "${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}";
    }
  }
}

// ตรวจสอบให้แน่ใจว่ามีเมธอดนี้ในคลาส _ScheduleScreenState

List<IngredientUsage> _convertIngredientsFromFirestore(dynamic ingredientsData) {
  List<IngredientUsage> result = [];
  
  if (ingredientsData == null) {
    print("DEBUG: ingredientsData is null");
    return result;
  }
  
  if (!(ingredientsData is List)) {
    print("DEBUG: ingredientsData is not a List, it's a ${ingredientsData.runtimeType}");
    return result;
  }
  
  try {
    for (var ingData in ingredientsData) {
      print("DEBUG: Processing ingredient: $ingData");
      
      String name = '';
      String unit = '';
      double amount = 0.0;
      
      if (ingData is Map<String, dynamic>) {
        name = ingData['name'] ?? '';
        unit = ingData['unit'] ?? '';
        
        if (ingData['amount'] is num) {
          amount = (ingData['amount'] as num).toDouble();
        } else if (ingData['amount'] is String) {
          amount = double.tryParse(ingData['amount']) ?? 0.0;
        }
        
        final ingredient = Ingredient(
          ingredientsName: name,
          unit: unit,
          quantity: 0,
          minQuantity: 0,
          category: 'Other',
          storage: 'Pantry',
          source: 'Recipe',
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
          ingredientId: DateTime.now().millisecondsSinceEpoch.toString(),
          imageUrl: 'assets/images/ingredient_placeholder.png',
          expirationDate: DateTime.now().add(Duration(days: 30)),
          kcal: 0,
        );
        
        result.add(IngredientUsage(
          ingredient: ingredient,
          quantityUsed: amount,
        ));
        
        print("DEBUG: Added ingredient: $name, $amount $unit");
      }
    }
  } catch (e) {
    print("DEBUG: Error converting ingredients: $e");
  }
  
  return result;
}

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
         child: SingleChildScrollView( 
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                    color: Colors.black,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Add Meals',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
             Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                   Text(
              _getFormattedDate(_selectedDateAppBBar),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
                ],
              ),
            ),
           

            // Calendar Agenda
            Container(
  height: 120, 
  child: CalendarAgenda(
    controller: _calendarAgendaControllerAppBar,
    appbar: false,
    selectedDayPosition: SelectedDayPosition.center,
    weekDay: WeekDay.short,
    dayNameFontSize: 12,
    dayNumberFontSize: 16,
    dayBGColor: Colors.grey.withOpacity(0.15),
    titleSpaceBetween: 15,
    backgroundColor: Colors.transparent,
    fullCalendarScroll: FullCalendarScroll.horizontal,
    fullCalendarDay: WeekDay.short,
    selectedDateColor: Colors.white,
    dateColor: Colors.black,
    locale: 'en',
    initialDate: DateTime.now(),
    calendarEventColor: TColor.primaryColor2,
    firstDate: DateTime.now().subtract(const Duration(days: 140)),
    lastDate: DateTime.now().add(const Duration(days: 60)),
    onDateSelected: (date) {
  _selectedDateAppBBar = date;
  _loadMealPlans();
},
    selectedDayLogo: Container(
      width: double.maxFinite,
      height: double.maxFinite,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
                colors: [Colors.green, Colors.lightGreen],
              ),
        borderRadius: BorderRadius.circular(10.0),
      ),
    ),
  ),
),
 SizedBox(height: 10),
          Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                 
                  children: [
                    _buildBreakfast(),
                    const SizedBox(height: 10),
                    _buildLunch(),
                     const SizedBox(height: 10),
                    _buildSnack(),
                     const SizedBox(height: 10),
                    _buildDinner(),
                  ],
                ),
              ),
            
          
        ],
      ),
    ),
  ))
  ;
}

Widget _buildBreakfast() {
  // Get breakfast data from Firebase
  List<dynamic> recipes = mealPlans['breakfast']['recipes'] ?? [];
  int totalCalories = mealPlans['breakfast']['totalCalories'] ?? 0;
  
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Column(
      children: [
        Container(
          width: 420, 
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section with Breakfast title and calories
                    Padding(
                      padding: const EdgeInsets.only(top: 15, left: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Breakfast title and info
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Breakfast',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 10),
                              // Display total calories if there are recipes
                              if (recipes.isNotEmpty)
                                Text(
                                  'Total: ${totalCalories} Kcal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                )
                              else
                                Text(
                                  'Add your breakfast meal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black.withOpacity(0.6),
                                  ),
                                ),
                            ],
                          ),
                          
                          // Add button for when recipes exist - right aligned
                          if (recipes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: InkWell(
                                onTap: () async {
                                  print("DEBUG: About to navigate to RecipeScreen with isSelecting=true");
                                  final Recipe? selectedRecipe = await Navigator.push(
                                    context, 
                                    MaterialPageRoute(
                                      builder: (context) => RecipeScreen(
                                        isSelecting: true,
                                        preselectedDate: _selectedDateAppBBar,  
                                        preselectedMealType: 'breakfast',       
                                      ),
                                    ),
                                  );
                                  
                                  if (selectedRecipe != null) {
                                    bool success = await _mealPlanService.addRecipeToMealPlan(
                                      recipe: selectedRecipe,
                                      date: _selectedDateAppBBar,
                                      mealType: 'breakfast',
                                    );
                                    
                                    if (success) {
                                      _loadMealPlans();
                                    }
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF78d454),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    
                    // Display recipes if any
                    if (recipes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          children: recipes.map((recipeData) {
                            // Convert recipeData to Recipe object
                            Recipe recipe = Recipe(
                              recipeId: int.tryParse(recipeData['recipeId'] ?? '0') ?? 0,
                              recipeName: recipeData['recipeName'] ?? '',
                              description: '',
                            ingredients: _convertIngredientsFromFirestore(recipeData['ingredients']),
  instructions: recipeData['instructions'] != null 
      ? List<String>.from(recipeData['instructions']) 
      : [],
                              preparationTime: 0,
                              cookingTime: 0,
                              servings: recipeData['servings'] ?? 1,
                              category: '',
                              imageUrl: recipeData['imageUrl'] ?? '',
                              Protein: recipeData['protein']?.toDouble() ?? 0.0,
                              Fat: recipeData['fat']?.toDouble() ?? 0.0,
                              Carbo: recipeData['carbo']?.toDouble() ?? 0.0,
                              Kcal: recipeData['kcal'] ?? 0,
                              isFavorite: false,
                              recipeDocId: recipeData['recipeId']?.toString(),
                            );
                            
                            return MealPlanRecipeWidget(
                              recipe: recipe,
                              recipeId: recipeData['recipeId'],

                              onDelete: () async {
                                // Remove recipe from the meal plan
                                bool success = await _mealPlanService.removeRecipeFromMealPlan(
                                  recipeId: recipe.recipeId.toString(),
                                  date: _selectedDateAppBBar,
                                  mealType: 'breakfast',
                                );
                                
                                if (success) {
                                  _loadMealPlans(); // Refresh the UI
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    
                    // Add button for when no recipes exist
                    if (recipes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 15, bottom: 15, top: 10),
                        child: InkWell(
                          onTap: () async {
                            print("DEBUG: About to navigate to RecipeScreen with isSelecting=true");
                            final Recipe? selectedRecipe = await Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => RecipeScreen(
                                  isSelecting: true,
                                  preselectedDate: _selectedDateAppBBar,  
                                  preselectedMealType: 'breakfast',       
                                ),
                              ),
                            );
                            
                            if (selectedRecipe != null) {
                              bool success = await _mealPlanService.addRecipeToMealPlan(
                                recipe: selectedRecipe,
                                date: _selectedDateAppBBar,
                                mealType: 'breakfast',
                              );
                              
                              if (success) {
                                _loadMealPlans();
                              }
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 5),
                            width: 120,
                            decoration: BoxDecoration(
                              color: Color(0xFF78d454),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    // Add padding at the bottom
                    if (recipes.isNotEmpty)
                      SizedBox(height: 15),
                  ],
                ),
              ),
              
              // Right image - only shown when no recipes
              if (recipes.isEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(right: 15),
                    child: Image.asset(
                      'assets/images/breakfast.png',
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildLunch() {
  // Get lunch data from Firebase
  List<dynamic> recipes = mealPlans['lunch']['recipes'] ?? [];
  int totalCalories = mealPlans['lunch']['totalCalories'] ?? 0;
  
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Column(
      children: [
        Container(
          width: 420, 
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left image - only shown when no recipes
              if (recipes.isEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                  child: Padding(
                padding: EdgeInsets.only(left: 15),
                child: Image.asset(
                  'assets/images/lunch.png',
                  width: 100,
                  
                  fit: BoxFit.cover,
                ),
              ),
                ),
              
              // Right content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section with Lunch title and calories
                    Padding(
                      padding: const EdgeInsets.only(top: 15, left: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Lunch title and info
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lunch',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 10),
                              // Display total calories if there are recipes
                              if (recipes.isNotEmpty)
                                Text(
                                  'Total: ${totalCalories} Kcal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                )
                              else
                                Text(
                                  'Add your lunch meal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black.withOpacity(0.6),
                                  ),
                                ),
                            ],
                          ),
                          
                          // Add button for when recipes exist - right aligned
                          if (recipes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: InkWell(
                                onTap: () async {
                                  print("DEBUG: About to navigate to RecipeScreen with isSelecting=true");
                                  final Recipe? selectedRecipe = await Navigator.push(
                                    context, 
                                    MaterialPageRoute(
                                      builder: (context) => RecipeScreen(
                                        isSelecting: true,
                                        preselectedDate: _selectedDateAppBBar,  
                                        preselectedMealType: 'lunch',       
                                      ),
                                    ),
                                  );
                                  
                                  if (selectedRecipe != null) {
                                    bool success = await _mealPlanService.addRecipeToMealPlan(
                                      recipe: selectedRecipe,
                                      date: _selectedDateAppBBar,
                                      mealType: 'lunch',
                                    );
                                    
                                    if (success) {
                                      _loadMealPlans();
                                    }
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF78d454),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    
                    // Display recipes if any
                    if (recipes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          children: recipes.map((recipeData) {
                            // Convert recipeData to Recipe object
                            Recipe recipe = Recipe(
                              recipeId: int.tryParse(recipeData['recipeId'] ?? '0') ?? 0,
                              recipeName: recipeData['recipeName'] ?? '',
                              description: '',
                              ingredients: _convertIngredientsFromFirestore(recipeData['ingredients']),
                              instructions: recipeData['instructions'] != null 
                                  ? List<String>.from(recipeData['instructions']) 
                                  : [],
                              preparationTime: recipeData['preparationTime'] ?? 0,
                              cookingTime: recipeData['cookingTime'] ?? 0,
                              servings: recipeData['servings'] ?? 1,
                              category: recipeData['category'] ?? '',
                              imageUrl: recipeData['imageUrl'] ?? '',
                              Protein: recipeData['protein']?.toDouble() ?? 0.0,
                              Fat: recipeData['fat']?.toDouble() ?? 0.0,
                              Carbo: recipeData['carbo']?.toDouble() ?? 0.0,
                              Kcal: recipeData['kcal'] ?? 0,
                              isFavorite: false,
                              recipeDocId: recipeData['recipeId']?.toString(),
                            );
                            
                            return MealPlanRecipeWidget(
                              recipe: recipe,
                              recipeId: recipeData['recipeId'],
                              onDelete: () async {
                                // Remove recipe from the meal plan
                                bool success = await _mealPlanService.removeRecipeFromMealPlan(
                                  recipeId: recipe.recipeId.toString(),
                                  date: _selectedDateAppBBar,
                                  mealType: 'lunch',
                                );
                                
                                if (success) {
                                  _loadMealPlans(); // Refresh the UI
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    
                    // Add button for when no recipes exist
                    if (recipes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 40, bottom: 15, top: 10),
                        child: InkWell(
                          onTap: () async {
                            print("DEBUG: About to navigate to RecipeScreen with isSelecting=true");
                            final Recipe? selectedRecipe = await Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => RecipeScreen(
                                  isSelecting: true,
                                  preselectedDate: _selectedDateAppBBar,  
                                  preselectedMealType: 'lunch',       
                                ),
                              ),
                            );
                            
                            if (selectedRecipe != null) {
                              bool success = await _mealPlanService.addRecipeToMealPlan(
                                recipe: selectedRecipe,
                                date: _selectedDateAppBBar,
                                mealType: 'lunch',
                              );
                              
                              if (success) {
                                _loadMealPlans();
                              }
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 5),
                            width: 120,
                            decoration: BoxDecoration(
                              color: Color(0xFF78d454),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    // Add padding at the bottom
                    if (recipes.isNotEmpty)
                      SizedBox(height: 15),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildSnack() {
  // Get snack data from Firebase
  List<dynamic> recipes = mealPlans['snack']['recipes'] ?? [];
  int totalCalories = mealPlans['snack']['totalCalories'] ?? 0;
  
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Column(
      children: [
        Container(
          width: 420, 
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section with Snack title and calories
                    Padding(
                      padding: const EdgeInsets.only(top: 15, left: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Snack title and info
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Snack',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 10),
                              // Display total calories if there are recipes
                              if (recipes.isNotEmpty)
                                Text(
                                  'Total: ${totalCalories} Kcal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                )
                              else
                                Text(
                                  'Add your snack meal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black.withOpacity(0.6),
                                  ),
                                ),
                            ],
                          ),
                          
                          // Add button for when recipes exist - right aligned
                          if (recipes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: InkWell(
                                onTap: () async {
                                  print("DEBUG: About to navigate to RecipeScreen with isSelecting=true");
                                  final Recipe? selectedRecipe = await Navigator.push(
                                    context, 
                                    MaterialPageRoute(
                                      builder: (context) => RecipeScreen(
                                        isSelecting: true,
                                        preselectedDate: _selectedDateAppBBar,  
                                        preselectedMealType: 'snack',       
                                      ),
                                    ),
                                  );
                                  
                                  if (selectedRecipe != null) {
                                    bool success = await _mealPlanService.addRecipeToMealPlan(
                                      recipe: selectedRecipe,
                                      date: _selectedDateAppBBar,
                                      mealType: 'snack',
                                    );
                                    
                                    if (success) {
                                      _loadMealPlans();
                                    }
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF78d454),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    
                    // Display recipes if any
                    if (recipes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          children: recipes.map((recipeData) {
                            // Convert recipeData to Recipe object
                            Recipe recipe = Recipe(
                              recipeId: int.tryParse(recipeData['recipeId'] ?? '0') ?? 0,
                              recipeName: recipeData['recipeName'] ?? '',
                              description: '',
                             ingredients: _convertIngredientsFromFirestore(recipeData['ingredients']),
  instructions: recipeData['instructions'] != null 
      ? List<String>.from(recipeData['instructions']) 
      : [],
                              preparationTime: 0,
                              cookingTime: 0,
                              servings: recipeData['servings'] ?? 1,
                              category: '',
                              imageUrl: recipeData['imageUrl'] ?? '',
                              Protein: recipeData['protein']?.toDouble() ?? 0.0,
                              Fat: recipeData['fat']?.toDouble() ?? 0.0,
                              Carbo: recipeData['carbo']?.toDouble() ?? 0.0,
                              Kcal: recipeData['kcal'] ?? 0,
                              isFavorite: false,
                              recipeDocId: recipeData['recipeId']?.toString(),
                            );
                            
                            return MealPlanRecipeWidget(
                              recipe: recipe,
                              recipeId: recipeData['recipeId'],
                              onDelete: () async {
                                // Remove recipe from the meal plan
                                bool success = await _mealPlanService.removeRecipeFromMealPlan(
                                  recipeId: recipe.recipeId.toString(),
                                  date: _selectedDateAppBBar,
                                  mealType: 'snack',
                                );
                                
                                if (success) {
                                  _loadMealPlans(); // Refresh the UI
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    
                    // Add button for when no recipes exist
                    if (recipes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 15, bottom: 15, top: 10),
                        child: InkWell(
                          onTap: () async {
                            print("DEBUG: About to navigate to RecipeScreen with isSelecting=true");
                            final Recipe? selectedRecipe = await Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => RecipeScreen(
                                  isSelecting: true,
                                  preselectedDate: _selectedDateAppBBar,  
                                  preselectedMealType: 'snack',       
                                ),
                              ),
                            );
                            
                            if (selectedRecipe != null) {
                              bool success = await _mealPlanService.addRecipeToMealPlan(
                                recipe: selectedRecipe,
                                date: _selectedDateAppBBar,
                                mealType: 'snack',
                              );
                              
                              if (success) {
                                _loadMealPlans();
                              }
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 5),
                            width: 120,
                            decoration: BoxDecoration(
                              color: Color(0xFF78d454),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    // Add padding at the bottom
                    if (recipes.isNotEmpty)
                      SizedBox(height: 15),
                  ],
                ),
              ),
              
              // Right image - only shown when no recipes
              if (recipes.isEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(right: 15),
                    child: Image.asset(
                      'assets/images/snack.png',
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildDinner() {
  // Get dinner data from Firebase
  List<dynamic> recipes = mealPlans['dinner']['recipes'] ?? [];
  int totalCalories = mealPlans['dinner']['totalCalories'] ?? 0;
  
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Column(
      children: [
        Container(
          width: 420, 
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left image - only shown when no recipes
              if (recipes.isEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                  child: Padding(
                padding: EdgeInsets.only(left: 15),
                child: Image.asset(
                  'assets/images/dinner.png',
                  width: 100,
                  
                  fit: BoxFit.cover,
                ),
              ),
                ),
              
              // Right content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section with Dinner title and calories
                    Padding(
                      padding: const EdgeInsets.only(top: 15, left: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Dinner title and info
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dinner',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 10),
                              // Display total calories if there are recipes
                              if (recipes.isNotEmpty)
                                Text(
                                  'Total: ${totalCalories} Kcal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                )
                              else
                                Text(
                                  'Add your dinner meal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black.withOpacity(0.6),
                                  ),
                                ),
                            ],
                          ),
                          
                          // Add button for when recipes exist - right aligned
                          if (recipes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: InkWell(
                                onTap: () async {
                                  print("DEBUG: About to navigate to RecipeScreen with isSelecting=true");
                                  final Recipe? selectedRecipe = await Navigator.push(
                                    context, 
                                    MaterialPageRoute(
                                      builder: (context) => RecipeScreen(
                                        isSelecting: true,
                                        preselectedDate: _selectedDateAppBBar,  
                                        preselectedMealType: 'dinner',       
                                      ),
                                    ),
                                  );
                                  
                                  if (selectedRecipe != null) {
                                    bool success = await _mealPlanService.addRecipeToMealPlan(
                                      recipe: selectedRecipe,
                                      date: _selectedDateAppBBar,
                                      mealType: 'dinner',
                                    );
                                    
                                    if (success) {
                                      _loadMealPlans();
                                    }
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF78d454),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    
                    // Display recipes if any
                    if (recipes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          children: recipes.map((recipeData) {
                            // Convert recipeData to Recipe object
                            Recipe recipe = Recipe(
                              recipeId: int.tryParse(recipeData['recipeId'] ?? '0') ?? 0,
                              recipeName: recipeData['recipeName'] ?? '',
                              description: '',
                              ingredients: _convertIngredientsFromFirestore(recipeData['ingredients']),
  instructions: recipeData['instructions'] != null 
      ? List<String>.from(recipeData['instructions']) 
      : [],
                              preparationTime: recipeData['preparationTime'] ?? 0,
                              cookingTime: recipeData['cookingTime'] ?? 0,
                              servings: recipeData['servings'] ?? 1,
                              category: recipeData['category'] ?? '',
                              imageUrl: recipeData['imageUrl'] ?? '',
                              Protein: recipeData['protein']?.toDouble() ?? 0.0,
                              Fat: recipeData['fat']?.toDouble() ?? 0.0,
                              Carbo: recipeData['carbo']?.toDouble() ?? 0.0,
                              Kcal: recipeData['kcal'] ?? 0,
                              isFavorite: false,
                              recipeDocId: recipeData['recipeId']?.toString(),
                            );
                            
                            return MealPlanRecipeWidget(
                              recipe: recipe,
                              recipeId: recipeData['recipeId'],
                              onDelete: () async {
                                // Remove recipe from the meal plan
                                bool success = await _mealPlanService.removeRecipeFromMealPlan(
                                  recipeId: recipe.recipeId.toString(),
                                  date: _selectedDateAppBBar,
                                  mealType: 'dinner',
                                );
                                
                                if (success) {
                                  _loadMealPlans(); // Refresh the UI
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    
                    // Add button for when no recipes exist
                    if (recipes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 40, bottom: 15, top: 10),
                        child: InkWell(
                          onTap: () async {
                            print("DEBUG: About to navigate to RecipeScreen with isSelecting=true");
                            final Recipe? selectedRecipe = await Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => RecipeScreen(
                                  isSelecting: true,
                                  preselectedDate: _selectedDateAppBBar,  
                                  preselectedMealType: 'dinner',       
                                ),
                              ),
                            );
                            
                            if (selectedRecipe != null) {
                              bool success = await _mealPlanService.addRecipeToMealPlan(
                                recipe: selectedRecipe,
                                date: _selectedDateAppBBar,
                                mealType: 'dinner',
                              );
                              
                              if (success) {
                                _loadMealPlans();
                              }
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 5),
                            width: 120,
                            decoration: BoxDecoration(
                              color: Color(0xFF78d454),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    // Add padding at the bottom
                    if (recipes.isNotEmpty)
                      SizedBox(height: 15),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}