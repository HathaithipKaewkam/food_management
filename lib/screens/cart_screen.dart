import 'package:flutter/material.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/search_cart.dart';
import 'package:food_project/widgets/cart_widget.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> addedToCartIngredients;

  const CartScreen({Key? key, this.addedToCartIngredients = const []}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}
class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    cartItems = List<Map<String, dynamic>>.from(widget.addedToCartIngredients); 
    print("✅ cartItems in CartScreen: $cartItems");

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
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
          if (cartItems.isEmpty)
            Expanded(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/cart.png',
                    height: 280,
                    width: 300,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nothing here yet!',
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
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: cartItems.length,
                itemBuilder: (BuildContext context, int index) {
                  final ingredient = cartItems[index];

                  return GestureDetector(
                    child: CartWidget(
                      cartItems: [ingredient], 
                    ),
                  );
                },
              ),
            ),
          
          // ปุ่มเพิ่มสินค้า
          Center(
            child: ElevatedButton(
              onPressed: () async {
                final List<Ingredient>? addedItems = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchCartScreen(
                      addedToCartIngredients: cartItems, // ส่งค่าที่อัปเดตแล้วไป
                    ),
                  ),
                );

                if (addedItems != null && addedItems.isNotEmpty) {
                  setState(() {
                    cartItems.addAll(addedItems.map((ingredient) => {
                      'ingredientsName': ingredient.ingredientsName,
                      'imageUrl': ingredient.imageUrl,
                      'unit': ingredient.unit,
                      'storage': ingredient.storage,
                      'source': ingredient.source,
                      'quantity': ingredient.quantity,
                      'price': ingredient.price,
                    }));
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF325b51),
                minimumSize: const Size(50, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 80),
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
    );
  }
}
