import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditQuantitiesBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Map<String, double> selectedQuantities;
  final Function(Map<String, double>) onSave;

  const EditQuantitiesBottomSheet({
    required this.items,
    required this.selectedQuantities,
    required this.onSave,
  });

  @override
  _EditQuantitiesBottomSheetState createState() => _EditQuantitiesBottomSheetState();
}

class _EditQuantitiesBottomSheetState extends State<EditQuantitiesBottomSheet> {
  late Map<String, double> editedQuantities;

  @override
  void initState() {
    super.initState();
    editedQuantities = Map.from(widget.selectedQuantities);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Edit Quantities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return ListTile(
                  title: Text(item['ingredientsName']),
                  subtitle: Text('${item['recommendedQuantity']} ${item['unit']}'),
                  trailing: SizedBox(
                    width: 100,
                    child: TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      controller: TextEditingController(
                        text: editedQuantities[item['id']]?.toString() ?? 
                            item['recommendedQuantity'].toString(),
                      ),
                      onTap: () {
                      final controller = TextEditingController();
                      setState(() {
                        controller.clear();
                      });
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')), 
                    ],
                     onChanged: (value) {
                      if (value.isNotEmpty) {
                        double? qty = double.tryParse(value);
                        if (qty != null && qty >= 0) {
                          setState(() {
                            editedQuantities[item['id']] = qty;
                          });
                        }
                      }
                    },
                    decoration: InputDecoration(
                      suffix: Text(_formatUnit(item['unit'])),
                    ),
                  ),
                )
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onSave(editedQuantities);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF325b51),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Save', 
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
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
  if (unit.contains('(') && unit.contains(')')) {
    final start = unit.indexOf('(') + 1;
    final end = unit.indexOf(')');
    return unit.substring(start, end);
  }
  return unitAbbreviations[unit] ?? unit;
}
