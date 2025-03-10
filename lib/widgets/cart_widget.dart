import 'package:flutter/material.dart';

class CartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const CartWidget({Key? key, required this.cartItems}) : super(key: key);

  @override
  _CartWidgetState createState() => _CartWidgetState();
}

class _CartWidgetState extends State<CartWidget> {
  // เก็บสถานะของ checkbox แต่ละอัน
  Map<String, bool> selectedItems = {};

  @override
  void initState() {
    super.initState();
    // กำหนดค่าเริ่มต้นให้ checkbox ทุกตัวเป็น false
    for (var item in widget.cartItems) {
      selectedItems[item['name']] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // หัวข้อ Cart
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Shopping Cart',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.cartItems.length,
            itemBuilder: (context, index) {
              final item = widget.cartItems[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: ListTile(
                  leading: Checkbox(
                    value: selectedItems[item['name']] ?? false,
                    onChanged: (bool? value) {
                      setState(() {
                        selectedItems[item['name']] = value ?? false;
                      });
                    },
                  ),
                  title: Text(item['name']),
                  subtitle: Text('Quantity: ${item['quantity']} ${item['unit']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        widget.cartItems.removeAt(index);
                        selectedItems.remove(item['name']);
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
