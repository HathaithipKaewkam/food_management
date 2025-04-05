import 'package:flutter/material.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/screens/recipe/recipe_detail.dart';
import 'package:page_transition/page_transition.dart';


class RecipeWidget extends StatefulWidget {
  final int index;
  final List<Recipe>? recipeScreenList; 
  final Recipe? recipe;

  const RecipeWidget({
    required this.index,
    this.recipeScreenList,
    this.recipe,
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
    ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: _buildRecipeImage(currentRecipe.imageUrl),
    ),
    Positioned(
      top: 3,
      right: 4,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: IconButton(
          onPressed: () {
            setState(() {
              currentRecipe.isFavorite = !currentRecipe.isFavorite;
            });
          },
          icon: Icon(
            currentRecipe.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: currentRecipe.isFavorite
                            ? Colors.red
                            : Colors.black54,
          ),
          iconSize: 20,
        ),
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
}
