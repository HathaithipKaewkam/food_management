import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/widgets/edit_button.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AutoShoppingList extends StatefulWidget {
  @override
  _AutoShoppingListState createState() => _AutoShoppingListState();
}

class _AutoShoppingListState extends State<AutoShoppingList> {
  Map<String, double> selectedQuantities = {};
  Set<String> selectedItems = {};
  Future<List<Map<String, dynamic>>>? _shoppingListFuture;

  @override
  void initState() {
    super.initState();
    _shoppingListFuture = _getShoppingList();
  }


  Future<List<Map<String, dynamic>>> _getShoppingList() async  {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    try {
      List<Map<String, dynamic>> shoppingList = [];

      // Get all items currently in userCart
      final userCartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userCart')
          .get();

      // Create a set of items already in cart
      Set<String> itemsInCart = userCartSnapshot.docs
          .map((doc) => doc.data()['ingredientsName'] as String)
          .toSet();

      // Get all ingredients
      final ingredients = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userIngredients')
          .get();

      for (var doc in ingredients.docs) {
        final data = doc.data();

        // Skip if item is already in cart
        if (itemsInCart.contains(data['ingredientsName'])) {
          continue;
        }

        // ... rest of your existing ingredient processing code ...
        final stats = await _getIngredientStats(data['ingredientsName']);

        final double currentQuantity = (data['quantity'] as num).toDouble();
        final double minQuantity = (data['minQuantity'] as num).toDouble();
        final double avgUsage = stats['avgUsagePerTime'] ?? 0;
        final double avgPurchase = stats['avgPurchaseQty'] ?? 0;
        final double wastedAmount = stats['wastedAmount'] ?? 0;

        // Calculate recommended quantity
        double recommendedQuantity = 0;
        String reason = '';

        if (currentQuantity <= 0) {
          if (avgPurchase > 0) {
            recommendedQuantity = avgPurchase;
            reason = 'Out of stock - Based on purchase history';
          } else {
            recommendedQuantity = minQuantity > 0 ? minQuantity : 1;
            reason = 'Out of stock - Minimum required quantity';
          }
        } else if (currentQuantity <= minQuantity) {
          recommendedQuantity = minQuantity * 2;
          reason = 'Below minimum quantity';
        } else if (avgUsage > 0) {
          double neededAmount = (avgUsage * 2) - currentQuantity;
          recommendedQuantity = neededAmount > 0 ? neededAmount : avgUsage;
          reason = 'Based on usage history';
        } else if (avgPurchase > 0) {
          recommendedQuantity = avgPurchase;
          reason = 'Based on purchase history';
        }

        if (wastedAmount > 0) {
          recommendedQuantity *= 0.8;
          reason += ' (adjusted for waste history)';
        }

        // Add to shopping list if needs purchasing
        if (recommendedQuantity > 0) {
          shoppingList.add({
            'id': doc.id,
            'ingredientsName': data['ingredientsName'],
            'currentQuantity': currentQuantity,
            'recommendedQuantity': recommendedQuantity.ceilToDouble(),
            'unit': data['unit'],
            'category': data['category'],
            'imageUrl': data['imageUrl'],
            'priority': currentQuantity <= minQuantity ? 'High' : 'Medium',
            'reason': reason,
          });
        }
      }

      return shoppingList;
    } catch (e) {
      print('Error generating shopping list: $e');
       return [];
    }
  }

  Future<Map<String, double>> _getIngredientStats(String ingredientName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {};

      // 1. Get usage history
      final usageQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userIngredients')
          .where('ingredientsName', isEqualTo: ingredientName)
          .get();

      double totalUsed = 0;
      int usageCount = 0;
      double wastedAmount = 0;

      for (var doc in usageQuery.docs) {
        Map<String, dynamic> data = doc.data();

        // Fix expiration date handling
        if (data['expirationDate'] != null) {
          DateTime? expirationDate;
          if (data['expirationDate'] is Timestamp) {
            expirationDate = (data['expirationDate'] as Timestamp).toDate();
          } else if (data['expirationDate'] is String) {
            expirationDate =
                DateTime.tryParse(data['expirationDate'] as String);
          }

          if (expirationDate != null &&
              expirationDate.isBefore(DateTime.now()) &&
              data['quantity'] != null) {
            double remainingQuantity = (data['quantity'] as num).toDouble();
            wastedAmount += remainingQuantity;
          }
        }

        // Calculate usage history
        List<dynamic> history = data['usageHistory'] ?? [];
        for (var usage in history) {
          totalUsed += (usage['quantity_used'] as num).toDouble();
          usageCount++;
        }
      }

      final purchaseQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('historyCart')
          .where('ingredientsName', isEqualTo: ingredientName)
          .get();

      double avgPurchaseQty = 0;
      if (purchaseQuery.docs.isNotEmpty) {
        double totalPurchased = purchaseQuery.docs.fold(0.0,
            (sum, doc) => sum + (doc.data()['quantity'] as num).toDouble());
        avgPurchaseQty = totalPurchased / purchaseQuery.docs.length;
      }

      return {
        'avgUsagePerTime': usageCount > 0 ? totalUsed / usageCount : 0,
        'avgPurchaseQty': avgPurchaseQty,
        'wastedAmount': wastedAmount,
      };
    } catch (e) {
      print('❌ Error calculating stats: $e');
      return {};
    }
  }

  Future<void> _addToCart(List<Map<String, dynamic>> items) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Reference to userCart collection
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userCart');

      for (var item in items) {
        if (!selectedItems.contains(item['id'])) continue;

        double quantity =
            selectedQuantities[item['id']] ?? item['recommendedQuantity'];

        // Add to userCart only
        await cartRef.add({
          'ingredientsName': item['ingredientsName'],
          'imageUrl': item['imageUrl'],
          'unit': item['unit'],
          'category': item['category'],
          'storage': item['storage'] ?? 'Pantry',
          'source': item['source'] ?? 'Supermarket',
          'quantity': quantity,
          'price': 0,
          'addedAt': Timestamp.now(),
          'purchased': false,
        });
      }

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Error adding items to cart: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add items to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buildHeader() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const FaIcon(FontAwesomeIcons.arrowLeft),
            color: Colors.black,
            iconSize: 20,
          ),
          const Text(
            'Smart Shopping List',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 40),
        ],
      );
    }
        return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 30, left: 10),
        child: Column(
          children: [
            buildHeader(), 
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _shoppingListFuture, 
                builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 180),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/thinking.png', 
            height: 220,
            width: 220,
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Finding items to recommend',
                style: TextStyle(
                  fontSize: 16, 
                  color: Color(0xFF325b51),
                  fontWeight: FontWeight.bold,
                ),
              ),
              DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 16, 
                  color: Color(0xFF325b51),
                  fontWeight: FontWeight.bold,
                ),
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      '...',
                      speed: const Duration(milliseconds: 300),
                    ),
                    TypewriterAnimatedText(
                      '.',
                      speed: const Duration(milliseconds: 300),
                    ),
                    TypewriterAnimatedText(
                      '..',
                      speed: const Duration(milliseconds: 300),
                    ),
                  ],
                  repeatForever: true,
                  displayFullTextOnTap: false,
                  isRepeatingAnimation: true,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
                  
                  // ถ้ามีข้อผิดพลาด
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  // ถ้าข้อมูลว่างเปล่า
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 160),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Image.asset('assets/images/empty_list.png',
                              height: 200),
                          const SizedBox(height: 20),
                          const Text('No items needed at the moment!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF094507),
                              )),
                        ],
                      ),
                    );
                  }

            final shoppingList = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: shoppingList.length,
                          padding: const EdgeInsets.only(bottom: 100),
                          itemBuilder: (context, index) {
                            final item = shoppingList[index];
                            final isSelected =
                                selectedItems.contains(item['id']);
                            final double recommendedQty =
                                item['recommendedQuantity'];
                            final double currentQty =
                                selectedQuantities[item['id']] ??
                                    recommendedQty;

                            String changeText = '';
                            Widget? changeIcon;
                            Color changeColor = Colors.grey[600]!;

                            if (currentQty > recommendedQty) {
                              changeText =
                                  '(Increased from ${recommendedQty.toStringAsFixed(1)} ${item['unit']})';
                              changeIcon = const Icon(Icons.arrow_upward,
                                  size: 14, color: Color(0xFF78d454));
                              changeColor = const Color(0xFF78d454);
                            } else if (currentQty < recommendedQty) {
                              changeText =
                                  '(Decreased from ${recommendedQty.toStringAsFixed(1)} ${item['unit']})';
                              changeIcon = const Icon(Icons.arrow_downward,
                                  size: 14, color: Colors.red);
                              changeColor = Colors.red;
                            }

                            return Dismissible(
                              key: Key(item['id']),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onDismissed: (direction) {
                                setState(() {
                                  selectedItems.remove(item['id']);
                                  selectedQuantities.remove(item['id']);
                                  shoppingList.removeAt(index);
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Transform.scale(
                                      scale: 1.2,
                                      child: Checkbox(
                                        value: isSelected,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value == true) {
                                              selectedItems.add(item['id']);
                                              selectedQuantities[item['id']] =
                                                  recommendedQty;
                                            } else {
                                              selectedItems.remove(item['id']);
                                              selectedQuantities
                                                  .remove(item['id']);
                                            }
                                          });
                                        },
                                        activeColor: const Color(0xFF78d454),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text.rich(
                                            TextSpan(
                                              text: item['ingredientsName'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (changeIcon != null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 4),
                                                  child: changeIcon,
                                                ),
                                              Expanded(
                                                child: Text.rich(
                                                  TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text:
                                                            '${currentQty.toStringAsFixed(1)} ${item['unit']}  ',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: changeText,
                                                        style: TextStyle(
                                                          color: changeColor,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
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
                          },
                        ),
                      ),
                      const Divider(
                        thickness: 1,
                        color: Colors.grey,
                        indent: 16,
                        endIndent: 16,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    if (selectedItems.length ==
                                        shoppingList.length) {
                                      // Unselect all
                                      selectedItems.clear();
                                      selectedQuantities.clear();
                                    } else {
                                      // Select all
                                      selectedItems.clear();
                                      selectedQuantities.clear();
                                      shoppingList.forEach((item) {
                                        selectedItems.add(item['id']);
                                        selectedQuantities[item['id']] =
                                            item['recommendedQuantity'];
                                      });
                                    }
                                  });
                                },
                                icon: const Icon(Icons.check_circle_outline,
                                    color: Colors.white),
                                label: Text(
                                  selectedItems.length == shoppingList.length
                                      ? 'Unselect All'
                                      : 'Select All',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF325b51),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Show edit dialog
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                    ),
                                    constraints: BoxConstraints(
                                      maxHeight:
                                          MediaQuery.of(context).size.height *
                                              0.8,
                                    ),
                                    builder: (context) => Padding(
                                      padding: EdgeInsets.only(
                                        bottom: MediaQuery.of(context)
                                            .viewInsets
                                            .bottom,
                                      ),
                                      child: EditQuantitiesBottomSheet(
                                        items: shoppingList,
                                        selectedQuantities: selectedQuantities,
                                        onSave: (newQuantities) {
                                          final currentSelected =
                                              Set<String>.from(selectedItems);
                                          setState(() {
                                            selectedQuantities = newQuantities;
                                            selectedItems = currentSelected;
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit_outlined,
                                    color: Colors.white),
                                label: const Text(
                                  'Edit Quantities',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF325b51),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectedItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () => _addToCart(shoppingList),
                      icon: const Icon(Icons.shopping_cart_checkout,
                          color: Colors.white),
                      label: const Text(
                        'Add Selected to Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF325b51),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ])));
  }
}
