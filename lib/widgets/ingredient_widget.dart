import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/ingredient/ingrediant_detail.dart';
import 'package:page_transition/page_transition.dart';
import 'package:intl/intl.dart';

class IngredientWidget extends StatelessWidget {
  const IngredientWidget({
    super.key,
    required this.index,
    required this.ingredientList, required List IngredientList,
  });

  final int index;
  final List<Ingredient> ingredientList;

  @override
  Widget build(BuildContext context) {
    final ingredient = ingredientList[index];
    String formattedDate = DateFormat('dd-MM-yyyy').format(ingredient.expirationDate);
    final DateTime now = DateTime.now();
    final DateTime expiryDate = ingredient.expirationDate;
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
      expiryText = 'Expires on: ${DateFormat('dd/MM/yyyy').format(expiryDate)}';
      expiryColor = Colors.green;
    }

    double progressValue = daysToExpiry < 0
        ? 1.0
        : daysToExpiry > 3
            ? 0.0
            : (3 - daysToExpiry) / 3;

    return Dismissible(
      key: ValueKey(ingredient.ingredientId),  // Unique ID for each ingredient
      background: swipeActionBackground(Alignment.centerLeft, Colors.green, Icons.check, 'Consume'),
      secondaryBackground: swipeActionBackground(Alignment.centerRight, Colors.red, Icons.delete, 'Throw'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd ||
            direction == DismissDirection.endToStart) {
          // Show dialog when swiped
          return await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Choose an action'),
                content: Text('What would you like to do with ${ingredient.ingredientsName}?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      print('Consumed ${ingredient.ingredientsName}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Consumed ${ingredient.ingredientsName}')),
                      );
                      Navigator.pop(context, true); // Confirm action
                    },
                    child: const Text(
                      'Consume',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      print('Thrown ${ingredient.ingredientsName}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Thrown ${ingredient.ingredientsName}')),
                      );
                      Navigator.pop(context, false); // Confirm action
                    },
                    child: const Text(
                      'Thrown',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          );
        }
        return false; // Prevent accidental dismissal
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageTransition(
              child: IngredientDetailPage(
                ingredient: ingredient,
              ),
              type: PageTransitionType.bottomToTop,
            ),
          );
        },
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Wrap(
                children: [
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.rightLeft),
                    title: const Text('Move'),
                    onTap: () {
                      print('Move action selected');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.pen),
                    title: const Text('Edit'),
                    onTap: () {
                      print('Edit action selected');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.cartShopping),
                    title: const Text('Buy'),
                    onTap: () {
                      print('Buy action selected');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.trash),
                    title: const Text('Delete'),
                    onTap: () {
                      print('Delete action selected');
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 70.0,
                height: 70.0,
                child: Image.network(
                  ingredient.imageUrl ?? "assets/images/default.png",
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          ingredient.ingredientsName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Constants.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            ingredient.storage ?? "Unknown",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      expiryText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: expiryColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: Colors.grey.shade300,
                      color: expiryColor,
                    ),
                  ],
                ),
              ),
              Text(
                '${ingredient.quantity.toString()} ${ingredient.unit}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget swipeActionBackground(Alignment alignment, Color color, IconData icon, String label) {
    return Container(
      alignment: alignment,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
