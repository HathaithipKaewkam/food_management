import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/search_cart.dart';
import 'package:food_project/widgets/cart_widget.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> addedToCartIngredients;

  const CartScreen({Key? key, this.addedToCartIngredients = const []})
      : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];
  List<Ingredient> ingredientList = [];
  bool isLoading = true;

  @override
  void initState() {
    fetchUserCart();
    super.initState();
    cartItems = List<Map<String, dynamic>>.from(widget.addedToCartIngredients);
    print("✅ cartItems in CartScreen: $cartItems");
  }

  Future<void> fetchUserCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('userCart')
            .get();

        print("✅ Fetched ${snapshot.docs.length} ingredients.");

         setState(() {
          cartItems = snapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>?; 
                return data ?? {};  
              })
              .toList();

          isLoading = false;
        });
        print("🎉 Fetch complete! isLoading: $isLoading");
      } catch (e) {
        print("Error fetching ingredients: $e");
        setState(() {
          isLoading = false;
        });
      }
    }
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
            Padding(
              padding: const EdgeInsets.only(top: 90),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 40),
                    child: Image.asset(
                      'assets/images/cart.png',
                      height: 280,
                      width: 300,
                    ),
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
                  const SizedBox(height: 40),
                  // ปุ่ม Add Items
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        final List<Ingredient>? addedItems =
                            await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchCartScreen(
                              addedToCartIngredients: cartItems,
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
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: cartItems.length,
                itemBuilder: (BuildContext context, int index) {
                  final ingredient = cartItems[index];

                  return GestureDetector(
                    onTap: () {
                      _showEditDialog(context, ingredient, index, cartItems);
                    },
                    child: CartWidget(
                      cartItems: [ingredient],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

void _showEditDialog(BuildContext context, Map<String, dynamic> ingredient,
    int index, List<Map<String, dynamic>> cartItems) {
  int quantity = ingredient['quantity'];
  TextEditingController quantityController =
      TextEditingController(text: quantity.toString());
  TextEditingController priceController =
      TextEditingController(text: ingredient['price'].toString());

  List<String> categoryOptions = [
    'Fruits',
    'Vegetables',
    'Meat',
    'Seafood',
    'Cold Cuts',
    'Dairy',
    'Bread',
    'Cake & Biscuits',
    'Alcoholic Beverages',
    'Beverages',
    'Coffee & Tea',
    'Snacks',
    'Sweets',
    'Condiments & Dips',
    'Dry Goods',
    'Nuts & Seeds',
    'Canned Food',
    'Cereals',
    'Leftovers',
    'Easy Meals',
    'Household Essentials',
    'Baking Goods',
    'Other goods',
    'Frozen foods',
    'Spices'
  ];
  List<String> unitOptions = [
    'Kilograms (kg)',
    'Grams (g)',
    'Pounds (lbs)',
    'Ounces (oz)',
    'Liters (L)',
    'Milliliters (mL)',
    'Gallons',
    'Bottles',
    'Pieces',
    'Boxes',
    'Cups',
    'Cans',
    'Packs',
    'Bulb',
    'Leaves',
    'Loaf',
    'Bunch',
    'Head',
    'Jar',
    'Sheet',
    'Bar',
    'Container',
    'Cob'
  ];
  List<String> storageOptions = ['Fridge', 'Freezer', 'Pantry'];
  List<String> sourceOptions = ['Supermarket', 'Market', 'Online', 'Homegrown'];

  String selectedCategory = ingredient['category'] ?? categoryOptions[0];
  String selectedUnit = ingredient['unit'] ?? unitOptions[0];
  String selectedStorage = ingredient['storage'] ?? storageOptions[0];
  String selectedSource = ingredient['source'] ?? sourceOptions[0];

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Text(
                    ingredient['ingredientsName'].isNotEmpty
                        ? ingredient['ingredientsName'][0].toUpperCase() +
                            ingredient['ingredientsName']
                                .substring(1)
                                .toLowerCase()
                        : '',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Quantity input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: quantity > 1
                                ? () {
                                    setState(() => quantity -= 1);
                                    quantityController.text =
                                        quantity.toString();
                                  }
                                : null,
                            icon: const Icon(Icons.remove, color: Colors.red),
                          ),
                          SizedBox(
                            width: 50,
                            child: TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder()),
                              onTap: () {
                                setState(() {
                                  quantityController.clear();
                                });
                              },
                              onChanged: (value) {
                                if (value.isNotEmpty &&
                                    int.tryParse(value) != null) {
                                  setState(() {
                                    quantity = int.parse(value);
                                    ingredient['quantity'] = quantity;
                                    cartItems[index]['quantity'] = quantity;
                                  });
                                }
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                quantity += 1;
                                quantityController.text = quantity.toString();
                              });
                            },
                            icon: const Icon(Icons.add, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Price input
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price'),
                    onTap: () {
                      setState(() {
                        priceController.clear();
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  // Category dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: categoryOptions.map((category) {
                      return DropdownMenuItem(
                          value: category, child: Text(category));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),

                  const SizedBox(height: 10),

                  // Unit dropdown
                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    items: unitOptions.map((unit) {
                      return DropdownMenuItem(value: unit, child: Text(unit));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedUnit = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),

                  const SizedBox(height: 10),

                  // Storage dropdown
                  DropdownButtonFormField<String>(
                    value: selectedStorage,
                    items: storageOptions.map((storage) {
                      return DropdownMenuItem(
                          value: storage, child: Text(storage));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStorage = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Storage'),
                  ),

                  const SizedBox(height: 10),

                  // Source dropdown
                  DropdownButtonFormField<String>(
                    value: selectedSource,
                    items: sourceOptions.map((source) {
                      return DropdownMenuItem(
                          value: source, child: Text(source));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSource = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Source'),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      double price = double.tryParse(priceController.text) ??
                          ingredient['price'];

                      setState(() {
                        cartItems[index] = {
                          ...ingredient,
                          'quantity': quantity,
                          'price': price,
                          'category': selectedCategory,
                          'unit': selectedUnit,
                          'storage': selectedStorage,
                          'source': selectedSource,
                        };
                      });

                      print('✅ Updated ingredient: ${cartItems[index]}');
                      Navigator.pop(context);
                    },
                    child: const Text('Save Changes'),
                  ),

                  const SizedBox(height: 10),

                  // Delete button
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        cartItems.removeAt(index);
                      });
                      print(
                          '❌ Removed ingredient: ${ingredient['ingredientsName']}');
                      Navigator.pop(context);
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Delete Item',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
