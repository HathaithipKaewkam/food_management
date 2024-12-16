import 'package:flutter/material.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/screens/recipe/recipe_detail.dart';


class PoupularScreen extends StatefulWidget {
  final List<Recipe> recipes;
  
  const PoupularScreen({Key? key, required this.recipes}) : super(key: key);

  @override
  State<PoupularScreen> createState() => _PoupularScreen();
}

class _PoupularScreen extends State<PoupularScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.only(left: 7 , right: 7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // จัดให้อยู่กลาง
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  fixedSize: const Size(40, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.arrow_back),
                color: Colors.black,
              ),
              const Spacer(),
              const Text(
                "Recipe of The Week",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  fixedSize: const Size(40, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22)),
                ),
                icon: const Icon(Icons.more_horiz),
                color: Colors.black,
              ),
            ]
            ),
            GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // จำนวนคอลัมน์
                    crossAxisSpacing: 15, // ระยะห่างระหว่างคอลัมน์
                    mainAxisSpacing: 20, // ระยะห่างระหว่างแถว
                  ),
                  itemCount: Recipe.recipeList.length,
                  itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecipeDetail(
                                      recipe: Recipe.recipeList[index],
                                      recipeId: Recipe.recipeList[index].recipeId,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Stack(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            height: 130,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(15),
                                              image: DecorationImage(
                                                image: AssetImage(Recipe.recipeList[index].imageUrl),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            Recipe.recipeList[index].recipeName,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.access_time_filled_outlined,
                                                size: 18,
                                                color: Color(0xFF5CB77E),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                '${Recipe.recipeList[index].totalCookingTime()} min',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const Text(
                                                " · ",
                                                style: TextStyle(color: Colors.black),
                                              ),
                                              const Icon(
                                                Icons.local_fire_department_sharp,
                                                size: 18,
                                                color: Colors.red,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${Recipe.recipeList[index].Kcal} Kcal',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Positioned(
                                        top: 1,
                                        right: 4,
                                        child: Container(
                                          height: 40,
                                          width: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(25),
                                            border: Border.all(
                                                color: Colors.grey.shade300, width: 1),
                                          ),
                                          child: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                Recipe.recipeList[index].isFavorite =
                                                    !Recipe.recipeList[index].isFavorite;
                                              });
                                            },
                                            icon: Icon(
                                              Recipe.recipeList[index].isFavorite
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: Recipe.recipeList[index].isFavorite
                                                  ? Colors.red
                                                  : Colors.black54,
                                            ),
                                            iconSize: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ),
                              );
                            },

                  
                          ),
                        ],
                      ),
                    )
                  ),
                )
              );
            }
          }
