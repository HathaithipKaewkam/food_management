import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/cart/analysis_buy.dart';
import 'package:food_project/widgets/history_buy_show.dart';
import 'package:intl/intl.dart';

class HistoryBuy extends StatefulWidget {
  const HistoryBuy({Key? key}) : super(key: key);

  @override
  _HistoryBuyState createState() => _HistoryBuyState();
}

class _HistoryBuyState extends State<HistoryBuy> {
  List<Ingredient> ingredientList = [];
  bool isLoading = true;
  List<Ingredient> filteredHistoryMonth = [];

  String selectedMonthYear = "";
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  DateTime firstAddedDate = DateTime.now();
  List<String> availableMonths = [];

  String selectedStorage = "All";

  Future<Map<DateTime, List<Ingredient>>>? _futureHistory;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // ในฟังก์ชัน initState
    await fetchUserIngredients();
    setState(() {
      availableMonths = getAvailableMonths(firstAddedDate);
      if (availableMonths.isNotEmpty &&
          availableMonths.first.trim().isNotEmpty) {
        try {
          selectedMonthYear = availableMonths.first;
          DateTime parsedDate =
              DateFormat('MMMM yyyy').parse(selectedMonthYear);
          selectedMonth = parsedDate.month;
          selectedYear = parsedDate.year;
        } catch (e) {
          print("Error parsing date: ${availableMonths.first}");
          selectedMonth = DateTime.now().month;
          selectedYear = DateTime.now().year;
          selectedMonthYear = DateFormat('MMMM yyyy').format(DateTime.now());
        }
      }
    });
  }

  void _loadHistory() {
    setState(() {
      _futureHistory = fetchHistoryGroupedByDate();
    });
  }

  Future<List<Ingredient>> fetchUserIngredients() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('purchaseHistory')
          .get();

      List<Ingredient> ingredients = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return data != null ? Ingredient.fromJson(data) : null;
          })
          .whereType<Ingredient>()
          .toList();

      setState(() {
        ingredientList = ingredients;
        if (ingredientList.isNotEmpty) {
          firstAddedDate = ingredientList.first.purchaseDate ?? DateTime.now();
        } else {
          firstAddedDate = DateTime.now();
        }

        availableMonths = getAvailableMonths(firstAddedDate);
        if (availableMonths.isNotEmpty && availableMonths.first.isNotEmpty) {
          try {
            // ตั้งค่าเริ่มต้นให้เป็นเดือนล่าสุดในรายการ
            selectedMonthYear = availableMonths.first;
            DateTime parsedDate =
                DateFormat('MMMM yyyy').parse(selectedMonthYear);
            selectedMonth = parsedDate.month;
            selectedYear = parsedDate.year;
          } catch (e) {
            print(
                "Error parsing date: ${availableMonths.first}, setting default month.");
            selectedMonth = DateTime.now().month;
            selectedYear = DateTime.now().year;
            selectedMonthYear = DateFormat('MMMM yyyy').format(DateTime.now());
          }
        } else {
          selectedMonth = DateTime.now().month;
          selectedYear = DateTime.now().year;
          selectedMonthYear = DateFormat('MMMM yyyy').format(DateTime.now());
        }

        filteredHistoryMonth = ingredientList;
        isLoading = false;
      });

      return ingredients;
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      return []; // ถ้า error ให้คืนค่าเป็น list ว่าง
    }
  }

  List<String> getAvailableMonths(DateTime firstAddedDate) {
    List<String> months = [];
    DateTime currentDate = DateTime.now();

    for (var ingredient in ingredientList) {
      DateTime purchaseDate = ingredient.purchaseDate ?? DateTime.now();
      String formattedMonth = DateFormat('MMMM yyyy').format(purchaseDate);
      if (!months.contains(formattedMonth)) {
        months.add(formattedMonth);
      }
    }

    int diffMonths = (currentDate.year - firstAddedDate.year) * 12 +
        currentDate.month -
        firstAddedDate.month;

    for (int i = 0; i <= diffMonths; i++) {
      DateTime monthDate =
          DateTime(firstAddedDate.year, firstAddedDate.month + i);
      String formattedMonth = DateFormat('MMMM yyyy').format(monthDate);
      if (!months.contains(formattedMonth)) {
        months.add(formattedMonth);
      }
    }

    months.sort((a, b) {
      DateTime dateA = DateFormat('MMMM yyyy').parse(a);
      DateTime dateB = DateFormat('MMMM yyyy').parse(b);
      return dateA.compareTo(dateB);
    });

    return months;
  }

  void filteredHistoryMonthList() {
    print("Filtering items for Month: $selectedMonth, Year: $selectedYear");
    setState(() {
      filteredHistoryMonth = ingredientList.where((ingredient) {
        DateTime purchaseDate = ingredient.purchaseDate ?? DateTime(2000);
        return purchaseDate.month == selectedMonth &&
            purchaseDate.year == selectedYear;
      }).toList();
      print("Filtered History List Updated: ${filteredHistoryMonth.length}");
    });
  }

  Future<Map<DateTime, List<Ingredient>>> fetchHistoryGroupedByDate() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    CollectionReference historyCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('purchaseHistory');

    QuerySnapshot snapshot =
        await historyCollection.orderBy('purchaseDate', descending: true).get();

    List<Ingredient> allIngredients = await fetchUserIngredients();

    Map<DateTime, List<Ingredient>> groupedHistory = {};
    for (var ingredient in allIngredients) {
      DateTime? purchaseDate = ingredient.purchaseDate;
      if (purchaseDate == null) continue;

      DateTime date = DateTime(purchaseDate.year, purchaseDate.month, purchaseDate.day);

      if (selectedMonth < 1 || selectedMonth > 12) {
        print("Error: selectedMonth มีค่าผิดพลาด $selectedMonth");
        selectedMonth = DateTime.now().month;
      }

      if (date.month == selectedMonth && date.year == selectedYear) {
        groupedHistory.putIfAbsent(date, () => []).add(ingredient);
      }
    }

    return groupedHistory;
  }

  double getTotalPriceForMonth(List<Map<String, dynamic>> cartItems, int year, int month) {
  double total = 0;
  
  for (var item in cartItems) {
    if (item['purchaseDate'] != null && item['price'] != null) {
      DateTime date = item['purchaseDate'] is Timestamp
          ? (item['purchaseDate'] as Timestamp).toDate()
          : DateTime.parse(item['purchaseDate']);

      if (date.year == year && date.month == month) {
        total += (item['price'] as num).toDouble(); 
      }
    }
  }
  return total;
}

int currentYear = DateTime.now().year;
int currentMonth = DateTime.now().month;


  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    String selectedMonthString =
        DateFormat('MMMM yyyy').format(DateTime(selectedYear, selectedMonth));

    return Scaffold(
        body: Padding(
            padding: const EdgeInsets.only(top: 10, left: 10),
            child: ListView(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                    color: Colors.black,
                    iconSize: 20,
                  ),
                  IconButton(
                    onPressed: () {
                    Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AnalysisBuy(
                                       ),
                                  ),
                                );
                    },
                    icon: const Icon(FontAwesomeIcons.chartLine),
                    color: Colors.black,
                    iconSize: 20,
                  ),
                  
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
              child: const Text(
                    'Purchase History',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      width: size.width * .92,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            color: Colors.black54.withOpacity(.6),
                          ),
                          Expanded(
                            child: TextField(
                              showCursor: true,
                              decoration: InputDecoration(
                                hintText: 'Search Ingredient',
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade400),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          Icon(
                            Icons.tune,
                            color: Colors.black54.withOpacity(.6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
             
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Row(
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        value: selectedMonthString.isNotEmpty
                            ? selectedMonthString
                            : null,
                        buttonStyleData: const ButtonStyleData(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            color: Color(0xFFb2e6b2),
                          ),
                        ),
                        dropdownStyleData: const DropdownStyleData(
                          maxHeight: 200, // กำหนดความสูงของ dropdown
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            color: Colors.white,
                          ),
                          direction: DropdownDirection
                              .textDirection, // ให้ dropdown แสดงลงล่าง
                        ),
                        iconStyleData: const IconStyleData(
                          icon: FaIcon(FontAwesomeIcons.caretDown,
                              color: Colors.black),
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        items: availableMonths.map((String month) {
                          return DropdownMenuItem<String>(
                            value: month,
                            child: Text(month),
                          );
                        }).toList(),
                        onChanged: (String? newMonth) {
                          if (newMonth != null) {
                            setState(() {
                              DateTime parsedDate =
                                  DateFormat('MMMM yyyy').parse(newMonth);
                              selectedMonth = parsedDate.month;
                              selectedYear = parsedDate.year;

                              print(
                                  "Dropdown Changed: Month $selectedMonth, Year $selectedYear");

                              filteredHistoryMonthList();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
               const SizedBox(height: 10),
              Padding(
                          padding: const EdgeInsets.only(top: 5, left: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 250),
                              Text(
                              '${getTotalPriceForMonth(ingredientList.map((ingredient) => ingredient.toJson()).toList(), currentYear, currentMonth).toStringAsFixed(2)} ฿',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF16a34a),
                              ),
                            ),
                            ],
                          ),
                        ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('purchaseHistory')
                    .where('purchaseDate',
                        isGreaterThanOrEqualTo:
                            DateTime(selectedYear, selectedMonth, 1))
                    .where('purchaseDate',
                        isLessThan:
                            DateTime(selectedYear, selectedMonth + 1, 1))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Loading...',
                        style: TextStyle(fontSize: 14, color: Colors.black54));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No ingredient for this month',
                        style: TextStyle(fontSize: 14, color: Colors.black54));
                  }

                  List<Ingredient> allIngredients =
                      snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Ingredient.fromJson(data);
                  }).toList();

                  

                  Map<DateTime, List<Ingredient>> filteredGroupedHistory = {};
                  for (var ingredient in allIngredients) {
                    if (ingredient.purchaseDate != null) {
                      DateTime date = DateTime(
                        ingredient.purchaseDate!.year,
                        ingredient.purchaseDate!.month,
                        ingredient.purchaseDate!.day
                      );
                      
                      
                      if (date.month == selectedMonth && date.year == selectedYear) {
                       
                        filteredGroupedHistory.putIfAbsent(date, () => []).add(ingredient);
                      }
                    }
                  }

                  // Add debug print
                  print('📅 Selected Month/Year: $selectedMonth/$selectedYear');
                  print('📊 Number of dates: ${filteredGroupedHistory.length}');
                  if (filteredGroupedHistory.isEmpty) {
                    return const Text('No ingredient for this month',
                        style: TextStyle(fontSize: 14, color: Colors.black54));
                  }

                  return ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: filteredGroupedHistory.entries.map((entry) {
                      DateTime date = entry.key;
                      List<Ingredient> ingredients = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              DateFormat('dd MMMM yyyy').format(date),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount:
                                ingredients.isNotEmpty ? ingredients.length : 0,
                            itemBuilder: (context, index) {
                              if (index >= ingredients.length)
                                return const SizedBox.shrink();
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3.0),
                                child: HistoryBuyShow(
                                    ingredient: ingredients[index]),
                              );
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  );
                },
              )
            ])));
  }
}
