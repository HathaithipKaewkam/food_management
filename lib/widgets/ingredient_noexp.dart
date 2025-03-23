import 'package:flutter/material.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';


class IngredientNoexp extends StatelessWidget {
  final Ingredient ingredient;

  IngredientNoexp({required this.ingredient});

  @override
  Widget build(BuildContext context) {
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

  if (daysToExpiry < 0) {
      return SizedBox.shrink(); 
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
            ),
             child: ingredient.imageUrl.isNotEmpty
      ? ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            ingredient.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/default_ing.png',
                fit: BoxFit.cover,
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
        )
      : Image.asset(
          'assets/images/default_ing.png',
          fit: BoxFit.cover,
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
                        ingredient.ingredientsName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    Text(
                        '${ingredient.quantity.toStringAsFixed(1)} ${ingredient.unit}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ingredient.quantity == 0.0 
                              ? Colors.red 
                              : ingredient.quantity <= ingredient.minQuantity 
                                  ? Colors.orange 
                                  : Colors.black,
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
