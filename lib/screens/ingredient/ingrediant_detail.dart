import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/services/pairing_service.dart';
import 'package:food_project/services/recipe_service.dart';
import 'package:intl/intl.dart';

class IngredientDetailPage extends StatefulWidget {
  final Ingredient ingredient;
  final List<Map<String, String>> recipes;

  const IngredientDetailPage(
      {super.key, required this.ingredient, required this.recipes});

  @override
  _IngredientDetailPageState createState() => _IngredientDetailPageState();
}

class _IngredientDetailPageState extends State<IngredientDetailPage> {
  List<Map<String, String>> pairingIngredients = [];
  List<Map<String, String>> recipes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPairingIngredients();
    fetchRecipe();
  }

  Future<void> fetchRecipe() async {
    try {
      List<String> userIngredients =
          widget.ingredient.ingredientsName.split(',');

      List<Map<String, String>> fetchedRecipes =
          await getRecipesWithImages(userIngredients);

      setState(() {
        recipes = fetchedRecipes;
        isLoading = false;
      });

      print("Fetched recipes: $fetchedRecipes");
    } catch (e) {
      setState(() {
        recipes = [];
        isLoading = false;
      });
      print("Error fetching recipes: $e");
    }
  }

  Future<void> fetchPairingIngredients() async {
    try {
      List<Map<String, String>> fetchedIngredients =
          await getRecipeAndPairings(widget.ingredient.ingredientsName);
      setState(() {
        pairingIngredients = fetchedIngredients;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching pairing ingredients: $e");
      setState(() {
        pairingIngredients = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    String formattedDate =
        DateFormat('dd-MM-yyyy').format(widget.ingredient.expirationDate);
    final DateTime now = DateTime.now();
    final DateTime expiryDate = widget.ingredient.expirationDate;
    final int daysToExpiry = expiryDate.difference(now).inDays;

    String expiryText;
    Color expiryColor;

    if (daysToExpiry < 0) {
      expiryText = 'Expired ${-daysToExpiry} days ago!';
      expiryColor = Colors.red;
    } else if (daysToExpiry <= 3) {
      expiryText = 'Expiring in $daysToExpiry days!';
      expiryColor = Colors.orange;
    } else {
      expiryText = '$daysToExpiry days in';
      expiryColor = Colors.green;
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 20, left: 5, right: 3),
        child: ListView(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: FaIcon(FontAwesomeIcons.arrowLeft),
                  color: Colors.black,
                  iconSize: 20,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: FaIcon(FontAwesomeIcons.basketShopping),
                  color: Colors.black,
                  iconSize: 20,
                ),
                IconButton(
                  onPressed: () {},
                  icon: FaIcon(FontAwesomeIcons.trash),
                  color: Colors.black,
                  iconSize: 20,
                ),
                IconButton(
                  onPressed: () {},
                  icon: FaIcon(FontAwesomeIcons.pencil),
                  color: Colors.black,
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.ingredient.ingredientsName[0].toUpperCase() +
                        widget.ingredient.ingredientsName.substring(1),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Image.network(
                    widget.ingredient.imageUrl,
                    fit: BoxFit.contain,
                    width: 20,
                    height: 20,
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    widget.ingredient.category,
                    style: const TextStyle(
                      color: Color(0xFF595959),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    "in",
                    style: const TextStyle(
                      color: Color(0xFF595959),
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    widget.ingredient.storage,
                    style: const TextStyle(
                      color: Color(0xFF595959),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    "Source",
                    style: const TextStyle(
                      color: Color(0xFF595959),
                      fontSize: 18,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  "Expiring",
                  style: TextStyle(
                    color: expiryColor,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                Text(
                  "Amount",
                  style: const TextStyle(
                    color: Color(0xFF595959),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    widget.ingredient.source,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 1),
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Image.asset(
                    widget.ingredient.source == 'home' ||
                            widget.ingredient.source == 'Home'
                        ? 'assets/images/house_detail.png'
                        : 'assets/images/cart_detail.png',
                    width: 20,
                    height: 20,
                  ),
                ),
                const SizedBox(width: 25),
                Text(
                  expiryText,
                  style: TextStyle(
                    color: expiryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  "${widget.ingredient.quantity} ${widget.ingredient.unit[0].toLowerCase()}${widget.ingredient.unit.substring(1)}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Let's cook it !",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pick the best pairing",
                    style: const TextStyle(
                      color: Color(0xFF595959),
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            pairingIngredients.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'No pairing ingredients available.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: pairingIngredients.map((ingredient) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            // ครอบรูปและชื่อให้อยู่ด้วยกัน
                            children: [
                              // รูปภาพ
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: ClipOval(
                                    child: Image.network(
                                      ingredient['image'] ?? '',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit
                                          .cover, // ปรับให้รูปพอดีกับวงกลม
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                  height: 8), // ระยะห่างระหว่างรูปกับชื่อ

                              // ชื่อส่วนผสม
                              Text(
                                ingredient['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF595959),
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Or cook with what you have",
                    style: const TextStyle(
                      color: Color(0xFF595959),
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (recipes.isNotEmpty) // Check if recipes is not empty
                    Column(
                      children: recipes.map((recipe) {
                        int index = recipes.indexOf(recipe);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      recipe['image'] ?? '',
                                      width: 150,
                                      height: 120,
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
                                        border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 1),
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            String currentFavorite =
                                                recipes[index]['isFavorite'] ??
                                                    'false';
                                            recipes[index]['isFavorite'] =
                                                (currentFavorite == 'true')
                                                    ? 'false'
                                                    : 'true';
                                          });
                                        },
                                        icon: Icon(
                                          recipes[index]['isFavorite'] == 'true'
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: recipes[index]['isFavorite'] ==
                                                  'true'
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
                              Expanded(
                                  child: SingleChildScrollView(
                                
                                child: Text(
                                  recipe['title'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF595959),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  softWrap: true,
                                ),
                              )),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "No recipes found.",
                        style: TextStyle(color: Colors.grey),
                      ),
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
