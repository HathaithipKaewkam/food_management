import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/ingredient/ingrediant_detail.dart';
import 'package:page_transition/page_transition.dart';
import 'package:intl/intl.dart';

class IngredientWidget extends StatelessWidget {
   final int index;
  final List<Ingredient> ingredientList;
  final Ingredient ingredient;
   final Function(int)? onItemDismissed;
  
  const IngredientWidget({
    Key? key,
    required this.index,
    required this.ingredientList,
    required this.ingredient,
    this.onItemDismissed,
  }) : super(key: key);

  Future<void> throwItemByNameAndStorage(BuildContext context, Ingredient ingredient) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: User is not logged in");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print("Attempting to find and mark item as thrown by name: ${ingredient.ingredientsName} and storage: ${ingredient.storage}");
    
    // ค้นหาด้วยทั้งชื่อและที่เก็บ
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userIngredients')
        .where('ingredientsName', isEqualTo: ingredient.ingredientsName)
        .where('storage', isEqualTo: ingredient.storage)  // เพิ่มเงื่อนไข storage
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      print("No ingredient found with name: ${ingredient.ingredientsName} and storage: ${ingredient.storage}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Ingredient "${ingredient.ingredientsName}" not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // ถ้ามีหลายรายการที่ตรงกับทั้งชื่อและที่เก็บ ให้ตรวจสอบวันหมดอายุด้วย
    DocumentSnapshot? matchingDoc;
    if (querySnapshot.docs.length > 1) {
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // แปลง Timestamp จาก Firestore เป็น DateTime
        Timestamp expiryTimestamp = data['expirationDate'] as Timestamp;
        DateTime expiryDate = expiryTimestamp.toDate();
        
        // เปรียบเทียบวันหมดอายุ (ต้องแปลงเป็นสตริงเพื่อเปรียบเทียบ format เดียวกัน)
        String docExpiryStr = DateFormat('yyyy-MM-dd').format(expiryDate);
        String ingredientExpiryStr = DateFormat('yyyy-MM-dd').format(ingredient.expirationDate);
        
        if (docExpiryStr == ingredientExpiryStr) {
          matchingDoc = doc;
          break;
        }
      }
    } else {
      // ถ้ามีเพียงรายการเดียวที่ตรงกับทั้งชื่อและที่เก็บ ใช้รายการนั้นเลย
      matchingDoc = querySnapshot.docs.first;
    }
    
    if (matchingDoc == null) {
      print("No exact matching ingredient found");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Could not find exact match for "${ingredient.ingredientsName}"'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // ใช้ document ID ที่ได้จากการค้นหา
    String docId = matchingDoc.id;
    print("Found document ID: $docId for ingredient: ${ingredient.ingredientsName}");
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userIngredients')
        .doc(docId)
        .update({
          'isThrowed': true,
          'quantity': 0, 
        });

    print("Item marked as thrown successfully");

     if (onItemDismissed != null) {
      // ตรวจสอบว่าเรายังอยู่ในต้นไม้ UI หรือไม่
      if (context.mounted) {
        // เรียก callback บน UI thread
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onItemDismissed!(index);
        });
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${ingredient.ingredientsName} thrown successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    return;
  } catch (e) {
    print("Error throwing item: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final ingredient = ingredientList[index];
    String formattedDate = DateFormat('dd-MM-yyyy').format(ingredient.expirationDate);
    final DateTime now = DateTime.now();
    final DateTime expiryDate = ingredient.expirationDate;
    final int daysToExpiry = expiryDate.difference(now).inDays;
     String safeKey = "ingredient_${ingredient.ingredientsName}_$index";

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
  key: ValueKey(safeKey),
  background: swipeActionBackground(Alignment.centerRight, Colors.red, Icons.delete, 'Throw'),
  confirmDismiss: (direction) async {
    if (direction == DismissDirection.startToEnd ||
        direction == DismissDirection.endToStart) {
      return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Choose an action'),
            content: Text('What would you like to do with ${ingredient.ingredientsName}?'),
            actions: [
              TextButton(
                onPressed: () {
                  // ยกเลิกการ dismiss
                  Navigator.pop(context, false);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
  onPressed: () async {
    // เปลี่ยนลำดับการทำงาน: ทิ้งในฐานข้อมูลก่อน
    try {
      await throwItemByNameAndStorage(context, ingredient);
      
      // แล้วค่อยลบออกจาก UI
      if (onItemDismissed != null) {
        onItemDismissed!(index);
      }
      
      // ปิดกล่องโต้ตอบ
      Navigator.pop(context, true);
    } catch (e) {
      print("Error during item throw: $e");
      // ถ้ามีข้อผิดพลาด อย่าลบออกจาก UI
      Navigator.pop(context, false);
    }
  },
  child: const Text(
    'Thrown',
    style: TextStyle(color: Colors.red),
  ),
),
                              ],
                            );
                          },
                        ) ?? false; 
                      }
                      return false;
                    },
                    onDismissed: (direction) {
                 
                  try {
                    if (onItemDismissed != null) {
                     
                      onItemDismissed!(index);
                    } else {
                      print("Warning: onItemDismissed callback is not provided");
                    }
                  } catch (e) {
                    print("Error in onDismissed: $e");
                  }
                },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageTransition(
              child: IngredientDetailPage(
                ingredient: ingredient, recipes: [],
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
              Container(
                  width: 70.0,
                  height: 70.0,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFfff),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ingredient.imageUrl != null && ingredient.imageUrl!.isNotEmpty
                        ? Image.network(
                            ingredient.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/default_ing.png',
                                fit: BoxFit.contain,
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
                          )
                        : Image.asset(
                            'assets/images/default_ing.png',
                            fit: BoxFit.contain,
                          ),
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
                        const SizedBox(width: 4),
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
                    '${ingredient.quantity.toStringAsFixed(1)} ${_formatUnit(ingredient.unit)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ingredient.quantity == 0 
                          ? Colors.red 
                          : ingredient.quantity <= ingredient.minQuantity 
                              ? Colors.orange 
                              : Colors.black,
                      fontSize: 16,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

 String _formatUnit(String unit) {
  final Map<String, String> unitAbbreviations = {
    'Kilograms (kg)': 'kg',
    'Grams (g)': 'g',
    'Pounds (lbs)': 'lbs',
    'Ounces (oz)': 'oz',
    'Liters (L)': 'L',
    'Milliliters (mL)': 'mL',
  };

  // ถ้าหน่วยมีวงเล็บให้เอาแค่ตัวย่อในวงเล็บ
  if (unit.contains('(') && unit.contains(')')) {
    final start = unit.indexOf('(') + 1;
    final end = unit.indexOf(')');
    return unit.substring(start, end);
  }

  // ถ้าไม่มีวงเล็บ ให้ใช้ map หาตัวย่อ
  return unitAbbreviations[unit] ?? unit;
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
