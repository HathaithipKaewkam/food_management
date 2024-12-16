import 'package:flutter/material.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';


class IngredientNoexp extends StatelessWidget {
  final Ingredient ingredient;

  IngredientNoexp({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd-MM-yyyy').format(ingredient.expDate);
    final DateTime now = DateTime.now();
    final DateTime expiryDate = ingredient.expDate;
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

  if (daysToExpiry < 0) {
      return SizedBox.shrink(); // หากหมดอายุแล้วไม่แสดง
    }

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Color(0xFFe6ebf1),
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: AssetImage(ingredient.imageUrl),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Container(
              height: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ingredient.ingrediantsName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${ingredient.quantity} ${ingredient.unit}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        expiryText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: expiryColor,
                        ),
                      ),
                      Text(
                        ingredient.storage,
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
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
