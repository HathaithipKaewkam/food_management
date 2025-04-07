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
  print("Starting fetchUserRecipes...");
  try {
    setState(() {
      isLoading = true;
    });
    
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in");
      setState(() {
        isLoading = false;
      });
      return;
    }
    
    // ดึงข้อมูลจาก Firestore
    print("Fetching recipes for user: ${user.uid}");
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userRecipe')
        .get();

    print("Found ${querySnapshot.docs.length} recipes in Firestore");
    
    // ตรวจสอบว่าการโหลดสำเร็จหรือไม่
    if (querySnapshot.docs.isEmpty) {
      print("No recipes found, setting isLoading = false");
      setState(() {
        userRecipes = [];
        isLoading = false;
      });
      return;
    }
    
    List<Recipe> recipes = [];
    
    // แปลงข้อมูลจาก Firestore เป็น Recipe objects
    for (var doc in querySnapshot.docs) {
      try {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print("Processing document ${doc.id}: ${data['recipeName']}");
        
        // เรียกใช้ Recipe.fromFirestore แทนการแปลงเอง
        Recipe recipe = Recipe.fromFirestore(data, doc.id);
        recipes.add(recipe);
        print("Added recipe: ${recipe.recipeName}");
      } catch (e) {
        print('❌ Error parsing document ${doc.id}: $e');
        // ข้ามข้อมูลที่มีปัญหา
      }
    }
    
    print("Successfully parsed ${recipes.length} recipes, setting isLoading = false");
    setState(() {
      userRecipes = recipes;
      isLoading = false;
    });
  } catch (e) {
    print('❌ Error in fetchUserRecipes: $e');
    // ที่สำคัญ: อย่าลืมเซ็ต isLoading = false เมื่อเกิดข้อผิดพลาด
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
        padding: const EdgeInsets.only(top : 10 ,left: 7 , right: 7),
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
                  childAspectRatio: 0.85, 
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
    // เพิ่มเส้นขอบและสีพื้นหลังเฉพาะเมื่อไม่มีรูปภาพ
    border: userRecipes[index].imageUrl.isEmpty
        ? Border.all(color: Colors.grey.shade300, width: 1.0)
        : null,
    color: userRecipes[index].imageUrl.isEmpty
        ? Colors.grey.shade50
        : null,
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
SizedBox(height: 5),
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