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
  Map<String, TextEditingController> textControllers = {};

  @override
  void initState() {
    super.initState();
    editedQuantities = Map.from(widget.selectedQuantities);

    for (var item in widget.items) {
    textControllers[item['id']] = TextEditingController(
      text: editedQuantities[item['id']]?.toString() ?? 
          item['recommendedQuantity'].toString(),
    );
  }
  }

  @override
void dispose() {
  for (var controller in textControllers.values) {
    controller.dispose();
  }
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7, 
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    child: Column(
      mainAxisSize: MainAxisSize.min, 
      children: [
        Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2.5),
          ),
          margin: const EdgeInsets.only(bottom: 16),
        ),
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
                      controller: textControllers[item['id']],
                      onTap: () {
                        textControllers[item['id']]?.clear();
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
