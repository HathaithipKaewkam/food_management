import 'package:flutter/material.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/screens/recipe/recipe_detail.dart';
import 'package:food_project/screens/recipe/schedule_screen.dart';
import 'package:food_project/services/meal_plan_service.dart';
import 'package:page_transition/page_transition.dart';

class RecipeWidget extends StatefulWidget {
  final int index;
  final List<Recipe>? recipeScreenList;
  final Recipe? recipe;
  final bool isSelecting;
  final DateTime? preselectedDate;
  final String? preselectedMealType;


  const RecipeWidget({
    required this.index,
    this.recipeScreenList,
    this.recipe,
    this.isSelecting = false,
    this.preselectedDate,
    this.preselectedMealType,
  });

  @override
  _RecipeWidgetState createState() => _RecipeWidgetState();
}

Widget _buildRecipeImage(String imageUrl) {
  if (imageUrl.isEmpty) {
    return Container(
      width: 140,
      height: 140,
      color: Color(0xFFF5F5F5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 50,
            color: Color(0xFF5CB77E),
          ),
        ],
      ),
    );
  } else if (imageUrl.startsWith('http')) {
    // ใช้ Network Image สำหรับ URL จากอินเทอร์เน็ต (Firebase Storage)
    return Image.network(
      imageUrl,
      width: 140,
      height: 140,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 140,
          height: 140,
          color: Color(0xFFF5F5F5),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: Color(0xFF5CB77E),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // แสดงไอคอนเมื่อโหลดรูปไม่สำเร็จ
        return Container(
          width: 140,
          height: 140,
          color: Color(0xFFF5F5F5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                size: 50,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text(
                'Image Error',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  } else {
    // ใช้ Asset Image สำหรับรูปภาพในแอป
    try {
      return Image.asset(
        imageUrl,
        width: 140,
        height: 140,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // แสดงไอคอนเมื่อโหลดรูปไม่สำเร็จ
          return Container(
            width: 140,
            height: 140,
            color: Color(0xFFF5F5F5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 50,
                  color: Color(0xFF5CB77E),
                ),
                SizedBox(height: 8),
                Text(
                  'No Image',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      // แสดงไอคอนเมื่อเกิดข้อผิดพลาด
      return Container(
        width: 140,
        height: 140,
        color: Color(0xFFF5F5F5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 50,
              color: Color(0xFF5CB77E),
            ),
            SizedBox(height: 8),
            Text(
              'No Image',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
  }
}

class _RecipeWidgetState extends State<RecipeWidget> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    Recipe currentRecipe;

    if (widget.recipe != null) {
      currentRecipe = widget.recipe!;
    } else if (widget.recipeScreenList != null &&
        widget.index < widget.recipeScreenList!.length) {
      currentRecipe = widget.recipeScreenList![widget.index];
    } else {
      // Fallback ถ้าไม่มีข้อมูล
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'Recipe not available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // เพิ่ม debug print ไว้ตรงนี้สำหรับทุกกรณี
        print("DEBUG: RecipeWidget tapped: ${currentRecipe.recipeName}");
        print("DEBUG: isSelecting value: ${widget.isSelecting}");

        if (widget.isSelecting) {
            print("DEBUG: Recipe selected in selection mode: ${currentRecipe.recipeName}");
  print("DEBUG: Widget preselectedDate: ${widget.preselectedDate}");
  print("DEBUG: Widget preselectedMealType: ${widget.preselectedMealType}");
          try {
            _showAddToMealPlanBottomSheet(
              context,
              currentRecipe,
              preselectedDate: widget.preselectedDate,
              preselectedMeal: widget.preselectedMealType,
            );
            print("DEBUG: Bottom sheet shown successfully");
          } catch (e) {
            print("DEBUG: Error showing bottom sheet: $e");

            // แสดงข้อความแจ้งเตือนเมื่อเกิดข้อผิดพลาด
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error: $e"),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          Navigator.push(
            context,
            PageTransition(
              child: RecipeDetail(
                recipe: currentRecipe,
                recipeId: currentRecipe.recipeId,
                recipeDocId: currentRecipe.recipeDocId ?? '0',
              ),
              type: PageTransitionType.bottomToTop,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // รูปภาพที่มีปุ่มหัวใจ
           Stack(
  children: [
    // รูปภาพ
    Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: _buildRecipeImage(currentRecipe.imageUrl),
      ),
    ),
  ],
),
            const SizedBox(width: 12),
            // ข้อมูลสูตรอาหาร
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ชื่อสูตรอาหาร
                  Text(
                    currentRecipe.recipeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // ประเภทของสูตรอาหาร
                  Text(
                    currentRecipe.category,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled_outlined,
                        size: 18,
                        color: Color(0xFF5CB77E),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${currentRecipe.totalCookingTime()} min',
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.local_fire_department_sharp,
                        size: 18,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${currentRecipe.Kcal} Kcal',
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToMealPlanBottomSheet(BuildContext context, Recipe recipe,
      {DateTime? preselectedDate, String? preselectedMeal}) {
  DateTime selectedDate = preselectedDate ?? DateTime.now();
  
  String selectedMeal;
  if (preselectedMeal != null) {
    selectedMeal = preselectedMeal[0].toUpperCase() + preselectedMeal.substring(1).toLowerCase();
    print("DEBUG: Converted preselectedMeal from '$preselectedMeal' to '$selectedMeal'");
  } else {
    selectedMeal = "Breakfast";
  }
    int servingCount = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
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
                  // Title
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

                  // Recipe Card
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
                          // Recipe Image
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: _getRecipeImageProvider(recipe.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Recipe Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe.recipeName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${recipe.totalCookingTime()} mins • ${recipe.Kcal} kcal",
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

                  // Servings Selection
                  const Text(
                    "Servings",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.people,
                          color: Color(0xFF78d454),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Number of servings",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (servingCount > 1) {
                                  setState(() {
                                    servingCount--;
                                  });
                                }
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.redAccent,
                            ),
                            Text(
                              "$servingCount",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  servingCount++;
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              color: Color(0xFF78d454),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Meal Selection
                  const Text(
                    "Choose Meal",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
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

                  // Date Selection
                  const Text(
                    "Date",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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

                  const SizedBox(height: 30),

                  // Buttons
                  Row(
                    children: [
                      // Cancel Button
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
                      // Add Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Convert meal type to lowercase for database consistency
                            String mealTypeKey = selectedMeal.toLowerCase();

                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                            );

                            try {
                              // Use the MealPlanService to add recipe to meal plan
                              final mealPlanService = MealPlanService();
                              final success =
                                  await mealPlanService.addRecipeToMealPlan(
                                recipe: recipe,
                                date: selectedDate,
                                mealType: mealTypeKey,
                                servings: servingCount,
                              );

                              // Close loading dialog
                              if (context.mounted) Navigator.pop(context);

                              if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Added to Meal Plan successfully!"),
          backgroundColor: Color(0xFF78d454),
        ),
      );
      
     if (context.mounted) {
  Navigator.of(context).pop(true);
  // Navigate to meal schedule screen with refresh
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => const ScheduleScreen(),
    ),
  );
}
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to add to Meal Plan. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
                            } catch (e) {
                              if (context.mounted) Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error: $e"),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
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
  }

  Widget _buildMealChip(
      String meal, String selectedMeal, Function(String) onSelected) {
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

  ImageProvider _getRecipeImageProvider(String imageUrl) {
    if (imageUrl.isEmpty) {
      return AssetImage('assets/images/placeholder.png');
    } else if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
      return NetworkImage(imageUrl);
    } else {
      return AssetImage(imageUrl);
    }
  }
}
