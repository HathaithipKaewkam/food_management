import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  final Future<void> Function(String docId, bool isPurchased) onPurchasedChanged;
  final Function(bool isPurchased) onMarkAllPurchased;

  const CartWidget({
    Key? key,
    required this.cartItems,
    required this.onPurchasedChanged,
    required this.onMarkAllPurchased,
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

  @override
void initState() {
  super.initState();
  for (var item in widget.cartItems) {
    if (item['docId'] != null) {
      selectedItems[item['docId']] = item['purchased'] ?? false;
    } else {
      print("DocId is null for item: ${item['ingredientsName']}");
    }
  }
}
void _markAllPurchased(bool isPurchased) {
    setState(() {
      for (var item in widget.cartItems) {
        final docId = item['docId'];
        if (docId != null) {
          selectedItems[docId] = isPurchased;
          item['purchased'] = isPurchased;
          widget.onPurchasedChanged(docId, isPurchased);
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final item = widget.cartItems[0]; 
    dynamic purchasedAt = item['purchasedAt'] ?? 'N/A';
    String formattedDate = formatDate(purchasedAt);

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
      child: Padding(
         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.translate(
              offset: const Offset(-5, 0),
              child: Checkbox(
  value: selectedItems.containsKey(item['docId'] ?? 'defaultDocId')
      ? selectedItems[item['docId']]
      : false, // เช็คว่า docId ที่ถูกต้องมีค่า

  activeColor: const Color(0xFF78d454),
  onChanged: (bool? value) async {
    final docId = item['docId']; // ตอนนี้ docId ควรจะมีค่าถูกต้อง

    print("DocId: $docId"); // แสดงค่า docId ใน console
    print("SelectedItems: $selectedItems"); // แสดงค่า selectedItems ใน console

    // ตรวจสอบว่า docId ที่ใช้สามารถอัปเดตได้ใน Firestore หรือไม่
    if (docId == null || docId == 'defaultDocId') {
      // ถ้า docId เป็น null หรือ defaultDocId ก็จะไม่ทำการอัปเดต
      print("DocId is invalid, cannot update Firestore.");
      return;
    }

    // อัปเดต Firestore โดยตรงโดยไม่ต้องเรียก setState
    try {
      await widget.onPurchasedChanged(docId, value ?? false); // อัปเดต Firestore

      // อัปเดต selectedItems หลังจากการอัปเดต Firestore สำเร็จ
      setState(() {
        selectedItems[docId] = value ?? false; // อัปเดต selectedItems
        item['purchased'] = value; // อัปเดตค่า purchased ใน item ด้วย
      });
    } catch (e) {
      print("❌ Error updating item: $e");
    }
  },
)





            ),
            const SizedBox(width: 10), 
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

                      Text(
                        '${item['price']} ฿',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                     ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Storage : ${item['storage']}',
                        style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${item['quantity']} ${item['unit']}',
                        style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.shop, size: 16, color: Colors.green.shade900),
                      const SizedBox(width: 8),
                      Text(
                        '${item['source'] ?? 'Unknown'}',
                        style: const TextStyle(fontSize: 16, color: Colors.black , fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                   Text(
                  'Last buy: $formattedDate',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
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
