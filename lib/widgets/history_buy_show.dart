import 'package:flutter/material.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:intl/intl.dart';



class HistoryBuyShow extends StatelessWidget {
  final Ingredient ingredient;

  HistoryBuyShow({required this.ingredient});

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
            width: 80,
            height: 110,
            decoration: BoxDecoration(
              color: Color(0xFFe6ebf1),
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(ingredient.imageUrl),
                fit: BoxFit.none,
                scale: 7.0,
                alignment: Alignment.center,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Container(
              height: 110,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(right: 14),
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
                        '${ingredient.price} ฿',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16a34a),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  //source
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                              children: [
                                // Source
                                Row(
                                  children: [
                                    Image.asset(
                                      ingredient.source == 'home' 
                                        ? 'assets/images/home_history.png'  
                                        : 'assets/images/cart_history.png',
                                      width: 18, 
                                      height: 18,
                                    ),
                                    const SizedBox(width: 5), 
                                    Text(
                                      ingredient.source == 'home' ? 'Home' : ingredient.source,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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
                  const SizedBox(height: 7),
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
