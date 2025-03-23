import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  final Function(String, bool) onPurchasedChanged;
  final Function(bool) onMarkAllPurchased;
   final bool isMarkAllSelected;

  const CartWidget({
    Key? key,
    required this.cartItems,
    required this.onPurchasedChanged,
    required this.onMarkAllPurchased,
    this.isMarkAllSelected = false,
  }) : super(key: key);

  @override
  _CartWidgetState createState() => _CartWidgetState();
}

String formatDate(dynamic dateValue) {
  try {
    DateTime dateTime;

    if (dateValue is Timestamp) {
      dateTime = dateValue.toDate();
    } else if (dateValue is String) {
      dateTime = DateTime.parse(dateValue);
    } else {
      return 'N/A';
    }

    final DateFormat formatter = DateFormat('dd/MM/yy');
    return formatter.format(dateTime);
  } catch (e) {
    print("Error parsing date: $e");
    return 'N/A';
  }
}

class _CartWidgetState extends State<CartWidget> {
  Map<String, bool> selectedItems = {};
  bool markAllSelected = false;

  @override
  void initState() {
    super.initState();
    for (var item in widget.cartItems) {
      if (item['docId'] != null) {
        selectedItems[item['docId']] = item['purchased'] ?? false;
      } 
    }
  }

  void _markAllPurchased(bool isPurchased) async {
    try {
      setState(() {
        markAllSelected = isPurchased;
        // Update all items in the local state
        for (var item in widget.cartItems) {
          if (item['docId'] != null) {
            selectedItems[item['docId']] = isPurchased;
            item['purchased'] = isPurchased;
          }
        }
      });

      // Update Firestore through parent widget
      await widget.onMarkAllPurchased(isPurchased);
      print("✅ All items marked as ${isPurchased ? 'purchased' : 'unpurchased'}");
    } catch (e) {
      print("❌ Error marking all items: $e");
      // Revert state on error
      setState(() {
        markAllSelected = !isPurchased;
        for (var item in widget.cartItems) {
          if (item['docId'] != null) {
            selectedItems[item['docId']] = !isPurchased;
            item['purchased'] = !isPurchased;
          }
        }
      });
    }
  }

  IconData _getStorageIcon(String? storage) {
    switch (storage?.toLowerCase()) {
      case 'freezer':
        return Icons.ac_unit;
      case 'fridge':
        return Icons.kitchen;
      case 'pantry':
        return Icons.store;
      default:
        return Icons.help_outline;
    }
  }

  IconData _getSourceIcon(String? source) {
    switch (source?.toLowerCase()) {
      case 'supermarket':
        return Icons.shopping_cart;
      case 'market':
        return Icons.shopping_bag_outlined;
      case 'online':
        return Icons.shopping_basket_outlined;
      case 'homegrown':
        return Icons.home_filled;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.cartItems[0];
    dynamic purchaseDate = item['purchaseDate'] ?? 'N/A';
    String formattedDate = formatDate(purchaseDate);

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.only(top: 10, left: 5, right: 2, bottom: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.translate(
                offset: const Offset(-5, 0),
                child: Checkbox(
                    value: widget.isMarkAllSelected || selectedItems[item['docId']] == true,
                    activeColor: const Color(0xFF78d454),
                    onChanged: (bool? value) async {
                      final docId = item['docId'];
                      if (docId != null) {
                        try {
                          setState(() {
                            selectedItems[docId] = value ?? false;
                            item['purchased'] = value;
                          });
                          await widget.onPurchasedChanged(docId, value ?? false);
                        } catch (e) {
                          print("❌ Error updating item: $e");
                          setState(() {
                            selectedItems[docId] = !(value ?? false);
                            item['purchased'] = !(value ?? false);
                          });
                        }
                      }
                    },
                  ),
                ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['ingredientsName'] != null
                            ? '${item['ingredientsName']![0].toUpperCase()}${item['ingredientsName']!.substring(1).toLowerCase()}'
                            : 'Unknown',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(right: 5),
                        child: Text(
                          '${item['price']} ฿',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF16a34a),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 1, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFf3f4f6),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                            _getSourceIcon(item['source']),
                            color: Color(0xFF22c55e),
                            size: 18,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            '${item['source'] ?? 'Unknown'}',
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ]),
                      ),
                      SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color(0xFFf3f4f6),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                            _getStorageIcon(item['storage']),
                            color: Colors.blue,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${item['storage']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ]),
                      ),
                      Spacer(),
                       Container(
                        padding: const EdgeInsets.only(right: 5),
                        child:  Text(
                        '${item['quantity']} ${_formatUnit(item['unit'])}',
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Padding(padding: const EdgeInsets.only(left: 2)),
                      Icon(Icons.calendar_today,
                          size: 18, color: Colors.green.shade900),
                      const SizedBox(width: 8),
                      Text(
                        'Last buy: $formattedDate',
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
