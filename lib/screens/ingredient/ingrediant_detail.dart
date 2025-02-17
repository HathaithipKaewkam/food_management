import 'package:flutter/material.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/models/ingredient.dart';


class IngredientDetailPage extends StatelessWidget {
  final Ingredient ingredient; // เปลี่ยนเป็นรับวัตถุ Ingredient แทน

  const IngredientDetailPage({super.key, required this.ingredient});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ingredient.ingredientsName, // ใช้ข้อมูลจาก object ingredient
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ภาพส่วนหัว
            Container(
              width: size.width,
              height: size.height * 0.4,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(ingredient.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // รายละเอียด
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ชื่อวัตถุดิบ
                  Text(
                    ingredient.ingredientsName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // หมวดหมู่
                  Text(
                    "Category: ${ingredient.category}",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // วันที่หมดอายุ
                  Text(
                    "Expiry Date: ${ingredient.expDate}",
                    style: TextStyle(
                      fontSize: 16,
                      color: Constants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ปริมาณและหน่วย
                  Text(
                    "Quantity: ${ingredient.quantity} ${ingredient.unit}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  // ราคา
                  Text(
                    "Price: \$${ingredient.price.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ปุ่มดำเนินการ
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // การดำเนินการเมื่อกดปุ่ม Add to Cart
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to cart!'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Add to Cart"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // การดำเนินการเมื่อกดปุ่ม Remove
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Removed from cart!'),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Constants.primaryColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "Remove",
                            style: TextStyle(color: Constants.primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
