import 'package:flutter/material.dart';
import 'package:food_project/screens/ingrediant/add_ingredient.dart';


class SearchIngredientScreen extends StatefulWidget {
  @override
  _SearchIngredientScreenState createState() => _SearchIngredientScreenState();
}

class _SearchIngredientScreenState extends State<SearchIngredientScreen> {
  TextEditingController _searchController = TextEditingController();

  String selectedIngredientName = '';

  // ข้อมูลตัวอย่าง
  List<Map<String, String>> ingredientList = [
    {'name': 'Tomato', 'image': 'assets/images/tomato.png'},
    {'name': 'Cucumber', 'image': 'assets/images/cucumber.png'},
    {'name': 'Onion', 'image': 'assets/images/onion.png'},
  ];

  void _setSelectedIngredient(String name) {
    setState(() {
      selectedIngredientName = name;
    });
  }

  // ค้นหาวัตถุดิบ
  List<Map<String, String>> _searchIngredients(String query) {
    return ingredientList
        .where((ingredient) =>
            ingredient['name']!.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Ingredients'),
          centerTitle: true,
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [
              // ช่องค้นหา
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search / Add Ingredient',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.0), // สีเส้นเมื่อไม่โฟกัส
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(
                        color: Colors.black, width: 1.0), // สีเส้นเมื่อโฟกัส
                  ),
                  suffixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),

              // แสดงรายการที่ค้นหา
              Expanded(
                  child: ListView(children: [
                ..._searchIngredients(_searchController.text).map((ingredient) {
                  return ListTile(
                    leading: Image.asset(ingredient['image']!,
                        width: 40, height: 40),
                    title: Text(ingredient['name']!),
                    onTap: () {
                      // นำไปยังหน้ากรอกข้อมูล
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddIngredientScreen(ingredient: ingredient),
                        ),
                      );
                    },
                  );
                }).toList(),

                // ถ้าไม่มีผลลัพธ์ให้แสดง Add New Product
                if (_searchController.text.isNotEmpty &&
                    _searchIngredients(_searchController.text).isEmpty)
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 10),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                          'Add new Ingredient',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Padding(padding: const EdgeInsets.only(left: 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFd7d8d8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                          child: SizedBox(
                            child: Image.asset(
                            'assets/images/default_ing.png',
                            fit: BoxFit.contain,
                            width: 50,
                            height: 50,
                            
                          ),

                          )
                          
                        ),
                      ),
                        const SizedBox(width: 30),
                        Expanded(
                            child: Text(
                              _searchController.text,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                          ),
                        ),

                      ],
                    ),
                    )
                       
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddIngredientScreen(
                            ingredient: {
                              'name': _searchController.text,
                              'image': 'assets/images/default_ing.png',
                            },
                          ),
                        ),
                      );
                    },
                  )
              ]
              )
              )
            ]
            )
            )
            );
  }
}
