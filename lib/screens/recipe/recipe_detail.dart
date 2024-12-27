import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/constants.dart';
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

  // Toggle Favorite button
  bool toggleIsFavorated(bool isFavorited) {
    return !isFavorited;
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
                  child: Container(
                height: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(widget.recipe.imageUrl),
                        fit: BoxFit.fill)),
              )),
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
                        child: const FaIcon(
                    FontAwesomeIcons.arrowLeft,
                    color: Colors.black,
                  ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          bool isFavorited =
                              toggleIsFavorated(widget.recipe.isFavorite);
                          widget.recipe.isFavorite = isFavorited;
                        });
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                        ),
                        child: Icon(
                          widget.recipe.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Constants.blackColor,
                        ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipe.description,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                    maxLines: null,
                  ),
                ],
              )),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Protein', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Fat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Carbo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Calories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/images/protein.png', width: 20, height: 20),
                        const SizedBox(width: 2),
                        Text('${widget.recipe.Protein} g', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 30),
                        Image.asset('assets/images/fat.png', width: 20, height: 20),
                        const SizedBox(width: 2),
                        Text('${widget.recipe.Fat} g', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 27),
                        Image.asset('assets/images/carbo.png', width: 23, height: 20),
                        const SizedBox(width: 2),
                        Text('${widget.recipe.Carbo} g', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 30),
                        Image.asset('assets/images/kcal.png', width: 23, height: 17),
                        const SizedBox(width: 1),
                        Text('${widget.recipe.Kcal} Kcal', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                  Container(
                  padding: const EdgeInsets.only(left: 20,right: 20),
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(100), 
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05), 
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
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
                          const SizedBox(width: 10), // เว้นระยะระหว่างไอคอนและข้อความ
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

                      // ปุ่มลด, ตัวเลข, และปุ่มเพิ่ม
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
                            color: Colors.redAccent, // สีปุ่มลบ
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
                            color: Colors.green, // สีปุ่มเพิ่ม
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
                    maxWidth: 300, // จำกัดขนาดความกว้าง
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
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          decoration: BoxDecoration(
                            color: showIngredients ? Color(0xFF78d454) : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Ingredients',
                            style: TextStyle(
                              color: showIngredients ? Colors.white : Colors.grey[700],
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
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          decoration: BoxDecoration(
                            color: !showIngredients ? Color(0xFF78d454) : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Instructions',
                            style: TextStyle(
                              color: !showIngredients ? Colors.white : Colors.grey[700],
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
                  )
                : InstructionsWidget(
                    instructions: widget.recipe.instructions, // แสดง instructions
                  ),
                ),
              ]
            ),
          ),
        );
      }
    }