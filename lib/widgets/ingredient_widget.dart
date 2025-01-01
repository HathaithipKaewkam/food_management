import 'package:flutter/material.dart';
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

    return GestureDetector(
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
            // วงกลมและรูปภาพ
            Container(
              width: 70.0,
              height: 70.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Transform.scale(
                scale: 0.7,
                child: ClipOval(
                  child: Image.asset(
                    ingredient.imageUrl ?? "assets/images/default.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            // ชื่อและวันหมดอายุ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ingredient.ingrediantsName,
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
                ],
              ),
            ),
            // จำนวน
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
    );
  }
}
