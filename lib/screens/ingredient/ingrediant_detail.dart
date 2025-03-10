import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/services/pairing_service.dart';
import 'package:intl/intl.dart';

class IngredientDetailPage extends StatefulWidget {
  final Ingredient ingredient;

  const IngredientDetailPage({super.key, required this.ingredient});

  @override
  _IngredientDetailPageState createState() => _IngredientDetailPageState();
}

class _IngredientDetailPageState extends State<IngredientDetailPage> {
  List<String> pairingIngredients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPairingIngredients();
  }

  Future<void> fetchPairingIngredients() async {
    try {
      List<String> fetchedIngredients =
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
        padding: const EdgeInsets.only(top: 20, left: 10),
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
                const SizedBox(width: 73),
                Text(
                  "Expiring",
                  style: TextStyle(
                    color: expiryColor,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 65),
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 1),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Image.asset(
                    widget.ingredient.source == 'home' ||
                            widget.ingredient.source == 'Home'
                        ? 'assets/images/house_detail.png'
                        : 'assets/images/cart_detail.png',
                    width: 20,
                    height: 20,
                  ),
                ),
                const SizedBox(width: 45),
                Text(
                  expiryText,
                  style: TextStyle(
                    color: expiryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 50),
                Text(
                  "${widget.ingredient.quantity} ${widget.ingredient.unit[0].toLowerCase()}${widget.ingredient.unit.substring(1)}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
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
            const SizedBox(height: 25),
            // Display pairing ingredients
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: isLoading
                  ? CircularProgressIndicator()
                  : Column(
                      children: pairingIngredients.map((ingredient) {
                        return Text(
                          ingredient,
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
