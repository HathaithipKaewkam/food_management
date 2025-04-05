import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_project/models/recipe.dart';
import 'package:food_project/screens/recipe/recipe_detail.dart';

class MyrecipeScreen extends StatefulWidget {
  final List<Recipe> recipes;

  const MyrecipeScreen({Key? key, required this.recipes}) : super(key: key);

  @override
  State<MyrecipeScreen> createState() => _MyrecipeScreen();
}

class _MyrecipeScreen extends State<MyrecipeScreen> {

    bool isLoading = true;
  List<Recipe> userRecipes = [];
  
  @override
  void initState() {
    super.initState();
    fetchUserRecipes();
  }

 Future<void> fetchUserRecipes() async {
  try {
    setState(() {
      isLoading = true;
    });
    
    User? user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userRecipe')
          .get();

      print("Found ${querySnapshot.docs.length} recipes in Firebase");
      
      List<Recipe> recipes = [];
      
      for (var doc in querySnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          // ตรวจสอบและแสดง ingredients ในเอกสาร
          if (data['ingredients'] != null) {
            print("Ingredients in document ${doc.id}: ${data['ingredients']}");
          } else {
            print("No ingredients found in document ${doc.id}");
          }
          
          Recipe recipe = Recipe.fromFirestore(data, doc.id);
          print("Recipe ${recipe.recipeName} has ${recipe.ingredients.length} ingredients after parsing");
          
          // ตรวจสอบว่า ingredient ถูกแปลงได้ถูกต้องหรือไม่
          for (var ing in recipe.ingredients) {
            print("Parsed ingredient: ${ing.ingredient.ingredientsName}, Unit: ${ing.ingredient.unit}, Quantity: ${ing.quantityUsed}");
          }
          
          recipes.add(recipe);
        } catch (e) {
          print('Error parsing recipe document ${doc.id}: $e');
          // ข้ามข้อมูลที่มีปัญหาและทำงานต่อ
        }
      }
      
      setState(() {
        userRecipes = recipes;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  } catch (e) {
    print('เกิดข้อผิดพลาดในการดึงข้อมูล: $e');
    setState(() {
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.only(left: 7, right: 7),
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
                "My Recipe",
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
            ]),
           if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 100.0),
                  child: CircularProgressIndicator(),
                ),
              )
            // ถ้าไม่มีข้อมูลให้แสดงหน้า empty state
            else if (userRecipes.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 150),
                    Image.asset(
                      'assets/images/no_recipe.png',
                      height: 200,
                      width: 200,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "You haven't created any recipes yet",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Your created recipes will appear here",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            // แสดงข้อมูลสูตรอาหารที่ดึงมาจาก Firebase
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 20,
                ),
                itemCount: userRecipes.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => RecipeDetail(
      recipe: userRecipes[index],
      recipeId: userRecipes[index].recipeId,
      recipeDocId: userRecipes[index].recipeDocId ?? userRecipes[index].recipeId.toString(),
    ),
  ),
).then((_) {
  // โหลดข้อมูลใหม่หลังจากกลับมา
  fetchUserRecipes();
}),
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
                                        image: userRecipes[index].imageUrl.isEmpty 
                                            ? null  
                                            : DecorationImage(
                                                image: userRecipes[index].imageUrl.startsWith('http') 
                                                    ? NetworkImage(userRecipes[index].imageUrl) as ImageProvider
                                                    : AssetImage(userRecipes[index].imageUrl),
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                      child: userRecipes[index].imageUrl.isEmpty 
                                          ? Center(
                                              child: Icon(
                                                Icons.restaurant_menu,
                                                size: 50,
                                                color: Color(0xFF5CB77E),
                                              ),
                                            ) 
                                          : null,
                                    ),
                                Text(
                                  userRecipes[index].recipeName,
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
                                      '${userRecipes[index].totalCookingTime()} min',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const Text(
                                      " · ",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    const Icon(
                                      Icons.local_fire_department_sharp,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${userRecipes[index].Kcal} Kcal',
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
                                      color: Colors.grey.shade300,
                                      width: 1),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      userRecipes[index].isFavorite =
                                          !userRecipes[index].isFavorite;
                                    });
                                  },
                                  icon: Icon(
                                    userRecipes[index].isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: userRecipes[index].isFavorite
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
      )),
    ));
  }
}