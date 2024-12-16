import 'package:flutter/material.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/screens/recipe/recipe_detail.dart';
import 'package:page_transition/page_transition.dart';


class RecipeWidget extends StatefulWidget {
  const RecipeWidget({
    super.key,
    required this.index,
    required this.recipeScreenList,
    required recipe,
  });

  final int index;
  final List<Recipe> recipeScreenList;

  @override
  _RecipeWidgetState createState() => _RecipeWidgetState();
}

class _RecipeWidgetState extends State<RecipeWidget> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageTransition(
            child: RecipeDetail(
              recipe: widget.recipeScreenList[widget.index],
              recipeId: widget.recipeScreenList[widget.index].recipeId,
            ),
            type: PageTransitionType.bottomToTop,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 8), // เพิ่มระยะห่างระหว่างแต่ละกรอบ
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
                  child: Image.asset(
                    widget.recipeScreenList[widget.index].imageUrl,
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
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
                          widget.recipeScreenList[widget.index].isFavorite =
                              !widget.recipeScreenList[widget.index].isFavorite;
                        });
                      },
                      icon: Icon(
                        widget.recipeScreenList[widget.index].isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.recipeScreenList[widget.index].isFavorite
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
                    widget.recipeScreenList[widget.index].recipeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // ประเภทของสูตรอาหาร
                  Text(
                    widget.recipeScreenList[widget.index].category,
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
                        '${widget.recipeScreenList[widget.index].totalCookingTime()} min',
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
                        '${widget.recipeScreenList[widget.index].Kcal} Kcal',
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
