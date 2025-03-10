import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/search_cart.dart';
import 'package:food_project/widgets/cart_widget.dart';
import 'package:food_project/widgets/ingredient_widget.dart';

class CartScreen extends StatefulWidget {
  final List<Ingredient> addedToCartIngredients;
  const CartScreen({super.key, required this.addedToCartIngredients, required Map<String, Object> ingredient});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.only(top: 35, left: 12, right: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'Cart',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.more_horiz),
                  color: Colors.black,
                  iconSize: 25,
                ),
              ],
            ),
          ),
          // Empty Cart View
          if (widget.addedToCartIngredients.isEmpty)
            Expanded(
              child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 120, right: 30),
                  child: Image.asset(
                    'assets/images/cart.png',
                    height: 280,
                    width: 300,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                        'Nothing here yet !',
                        style: TextStyle(
                          color: Color(0xFF094507),
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Let\'s add some items to stay organized',
                        style: TextStyle(
                          color: Color(0xFF094507),
                          fontWeight: FontWeight.w500,
                          fontSize: 20,
                        ),
                      ),
                       const SizedBox(height: 30),
                     Center(
                child: ElevatedButton(
                  onPressed:
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchCartScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF325b51),
                    minimumSize: const Size(50, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 80),
                  ),
                  child: const Text(
                    'ADD ITEMS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              ],
            ),
            )
          else
            // Cart Items List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 30),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                  itemCount: widget.addedToCartIngredients.length,
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    return CartWidget(
                      cartItems: [widget.addedToCartIngredients[index].toMap()], // ✅ ห่อเป็น List
                    );
                  },
                ),

                    ),
                    Column(
                      children: [
                        const Divider(thickness: 1.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Totals',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            Text(
                              r'$65',
                              style: TextStyle(
                                fontSize: 24.0,
                                color: Constants.primaryColor,
                                fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }
}
