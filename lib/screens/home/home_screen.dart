import 'package:flutter/material.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/home/schedule_screen.dart';
import 'package:food_project/screens/ingrediant/ingrediant_detail.dart';
import 'package:food_project/widgets/ingredient_widget.dart';
import 'package:page_transition/page_transition.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0; 
  String userName = "Moodeng"; 
  String selectedType = 'Expire In 3 Days';

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    // ดึงรายการ Ingredient
    List<Ingredient> ingredientList = Ingredient.ingredientList;

    // Ingredient category
    List<String> ingredientTypes = [
      'Expire In 3 Days',
      'Expired Items',
      'Running Out Of',
    ];
    List<Ingredient> filteredIngredients;
    if (selectedType == 'Expire In 3 Days') {
      filteredIngredients = ingredientList
          .where((ingredient) => ingredient.expDate.isAfter(DateTime.now()) && ingredient.expDate.isBefore(DateTime.now().add(Duration(days: 3))))
          .toList();
    } else if (selectedType == 'Expired Items') {
      filteredIngredients = ingredientList
          .where((ingredient) => ingredient.expDate.isBefore(DateTime.now()))
          .toList();
    } else {
      filteredIngredients = ingredientList
          .where((ingredient) => ingredient.quantity < 5) 
          .toList();
    }


    

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: ListView(
          children: [
            // ส่วน Header ที่ไม่ต้องเลื่อน
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $userName',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Constants.blackColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    child: IconButton(
                      icon: Icon(
                        Icons.calendar_month,
                        size: 30,
                        color: Constants.blackColor,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScheduleScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Ingredient Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Constants.blackColor,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ส่วนหมวดหมู่ (ต้องเลื่อน)
            SizedBox(
              height: 50.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: ingredientTypes.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                        selectedType = ingredientTypes[index];
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedIndex == index
                            ? Color(0xFF78d454)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          ingredientTypes[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selectedIndex == index
                                ? FontWeight.bold
                                : FontWeight.bold,
                            color: selectedIndex == index
                                ? Colors.white
                                : Colors.black,
                                
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18), // เพิ่มช่องว่างระหว่างหมวดหมู่และช่องค้นหา

            // ช่องค้นหา + ไอคอนสี่เหลี่ยมมน
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // ช่องค้นหาที่มีการจัดแต่ง
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search ingredients',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade500,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (value) {
                          print('ค้นหา: $value');
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 7), // เพิ่มช่องว่างระหว่างช่องค้นหาและไอคอน
                  // ไอคอนในรูปสี่เหลี่ยมมน
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12), // มุมมน
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2), // เงาด้านล่าง
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.tune,
                        color: Constants.blackColor,
                        size: 25,
                      ),
                      onPressed: () {
                        print("List icon clicked");
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                   Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.more_horiz,
                        color: Constants.blackColor,
                        size: 25,
                      ),
                      onPressed: () {
                        print("sort");
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),

            // ส่วนที่ต้องเลื่อน
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredIngredients.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        child: IngredientDetailPage(
                          ingredient: ingredientList[index],
                        ),
                        type: PageTransitionType.bottomToTop,
                      ),
                    );
                  },
                  child: IngredientWidget(
                    index: index,
                     ingredientList: filteredIngredients,
                     IngredientList: const [],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
