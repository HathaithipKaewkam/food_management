import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/cart/analysis_buy.dart';
import 'package:food_project/widgets/history_buy_show.dart';
import 'package:intl/intl.dart';

class AnalysisBuy extends StatefulWidget {
  const AnalysisBuy({Key? key}) : super(key: key);

  @override
  _AnalysisBuyState createState() => _AnalysisBuyState();
}

class _AnalysisBuyState extends State<AnalysisBuy> {
  List<Ingredient> ingredientList = [];
  bool isLoading = true;
  List<Ingredient> filteredHistoryMonth = [];

  String selectedMonthYear = "";
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  DateTime firstAddedDate = DateTime.now();
  int selectedIndex = 0;
  int currentYear = DateTime.now().year;
  int currentMonth = DateTime.now().month;
  List<String> availableMonths = [];

  String selectedStorage = "All";

  String selectedType = 'Expenses';

  Future<Map<DateTime, List<Ingredient>>>? _futureHistory;

  List<String> showchartType = [
    'Expenses',
    'Category',
    'Source',
  ];

  List<String> source = ['Supermarket', 'Market', 'Online', 'Homegrown'];

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

      DateTime date =
          DateTime(purchaseDate.year, purchaseDate.month, purchaseDate.day);

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

  List<String> categories = [
    'Fruits',
    'Vegetables',
    'Meat',
    'Seafood',
    'Cold Cuts',
    'Dairy',
    'Bread',
    'Cake & Biscuits',
    'Alcoholic Beverages',
    'Beverages',
    'Coffee & Tea',
    'Snacks',
    'Sweets',
    'Condiments & Dips',
    'Dry Goods',
    'Nuts & Seeds',
    'Canned Food',
    'Cereals',
    'Leftovers',
    'Easy Meals',
    'Household Essentials',
    'Baking Goods',
    'Other goods',
    'Frozen foods',
    'Spices',
  ];

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    String selectedMonthString =
        DateFormat('MMMM yyyy').format(DateTime(selectedYear, selectedMonth));

    return Scaffold(
        body: Padding(
            padding: const EdgeInsets.only(top: 40, left: 10),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                    color: Colors.black,
                    iconSize: 20,
                  ),
                  Text(
                    'Summary of expenses',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
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
              SizedBox(
                height: 50.0,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: showchartType.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                          selectedType = showchartType[index];
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedIndex == index
                              ? Color(0xFFb2e6b2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            showchartType[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: selectedIndex == index
                                  ? FontWeight.bold
                                  : FontWeight.bold,
                              color: selectedIndex == index
                                  ? Colors.black
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
             // แก้ไขส่วนที่สร้าง Category Chart
Expanded(
  child: filteredHistoryMonth.isEmpty 
      ? Center(
          child: Text(
            'No data available for selected month',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        )
      : selectedType == 'Expenses'
          ? buildBarChart(filteredHistoryMonth)
          : selectedType == 'Category'
              ? buildPieChartWithLegend(filteredHistoryMonth) // ใช้ฟังก์ชันใหม่
              : selectedType == 'Source'
                  ? buildSourceChartWithLegend(filteredHistoryMonth) // ใช้ฟังก์ชันใหม่
                  : Container(),
)
            ])));
  }
}

Widget buildBarChart(List<Ingredient> ingredients) {
  // คำนวณจำนวนครั้งการซื้อต่อสัปดาห์
  Map<int, int> weeklyPurchaseCount = {
    1: 0,
    2: 0,
    3: 0,
    4: 0,
    5: 0,
  };

  // คำนวณค่าใช้จ่ายต่อสัปดาห์
  Map<int, double> weeklyExpenses = {
    1: 0,
    2: 0,
    3: 0,
    4: 0,
    5: 0,
  };

  for (var ingredient in ingredients) {
    DateTime purchaseDate = ingredient.purchaseDate ?? DateTime.now();
    int weekOfMonth = (purchaseDate.day - 1) ~/ 7 + 1;
    weeklyPurchaseCount[weekOfMonth] =
        (weeklyPurchaseCount[weekOfMonth] ?? 0) + 1;
    weeklyExpenses[weekOfMonth] =
        (weeklyExpenses[weekOfMonth] ?? 0) + ingredient.price;
  }

  List<BarChartGroupData> barGroups = weeklyPurchaseCount.entries.map((entry) {
    double expenses = weeklyExpenses[entry.key] ?? 0;
    return BarChartGroupData(
      x: entry.key,
      barRods: [
        BarChartRodData(
          toY: entry.value.toDouble(),
          color: Color(0xFF86C7B5),
          width: 16,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: entry.value.toDouble() + 1,
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
      ],
      showingTooltipIndicators: [0],
    );
  }).toList();

  return Container(
    width: double.infinity,
    height: 300,
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 2,
          blurRadius: 5,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          'Purchase Frequency by Week',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 20),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: barGroups,
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '${value.toInt()}×',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      String weekText = 'Week ${value.toInt()}';
                      double expenses = weeklyExpenses[value.toInt()] ?? 0;
                      return Column(
                        children: [
                          Text(
                            weekText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${expenses.toStringAsFixed(0)}฿',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.1),
                  strokeWidth: 1,
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    int weekNumber = group.x.toInt();
                    int purchaseCount = weeklyPurchaseCount[weekNumber] ?? 0;
                    double expenses = weeklyExpenses[weekNumber] ?? 0;
                    return BarTooltipItem(
                      'Week $weekNumber\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '$purchaseCount times\n',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        TextSpan(
                          text: '${expenses.toStringAsFixed(0)}฿',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// เพิ่มฟังก์ชันใหม่
Widget buildPieChartWithLegend(List<Ingredient> ingredients) {
  // สร้าง categoryData จากข้อมูล
  Map<String, double> categoryData = {};
  
  for (var ingredient in ingredients) {
    String category = ingredient.category ?? 'Unknown';
    double price = ingredient.price; // ใช้ค่าจริง
    categoryData[category] = (categoryData[category] ?? 0) + price;
  }
  
  if (categoryData.isEmpty) {
    return Center(
      child: Text(
        'No category data available',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  return Column(
    children: [
      buildPieChart(ingredients),
      buildCategoryLegend(
        categoryData.keys.toList(),
        categoryData,
      ),
    ],
  );
}

Widget buildSourceChartWithLegend(List<Ingredient> ingredients) {
  // สร้าง sourceData จากข้อมูล
  Map<String, double> sourceData = {};
  
  for (var ingredient in ingredients) {
    String source = ingredient.source ?? 'Unknown';
    double price = ingredient.price; // ใช้ค่าจริง
    sourceData[source] = (sourceData[source] ?? 0) + price;
  }
  
  if (sourceData.isEmpty) {
    return Center(
      child: Text(
        'No source data available',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  return Column(
    children: [
      buildDonutChart(ingredients),
      buildCategorySource(
        sourceData.keys.toList(),
        sourceData,
      ),
    ],
  );
}


Widget buildPieChart(List<Ingredient> ingredients) {
  Map<String, double> categoryData = {};

  for (var ingredient in ingredients) {
    String category = ingredient.category ?? 'Unknown';
    double price = ingredient.price; 
    categoryData[category] = (categoryData[category] ?? 0) + price;
    
    
  }

  if (categoryData.isEmpty) {
    print("❌ No category data available");
    return Center(
      child: Text(
        'No data available for this month',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  double total = categoryData.values.reduce((a, b) => a + b);
  if (total <= 0) {
    print("❌ Total price is zero");
    return Center(
      child: Text(
        'No price data available for this month',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  List<PieChartSectionData> sections = [];
  
 
  categoryData.forEach((key, value) {
    
    double percentage = total > 0 ? (value / total) * 100 : 0;
    
    sections.add(PieChartSectionData(
      color: getColorForCategory(key),
      value: value,
      title: value > 0 ? '${percentage.toStringAsFixed(1)}%' : '0%',
      radius: 60,
      titleStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ));
  });
  
  return Container(
    width: 300,
    height: 300,
    child: PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 50,
        sectionsSpace: 4,
        borderData: FlBorderData(show: false),
      ),
    ),
  );
}



Widget buildCategoryLegend(List<String> categories, Map<String, double> categoryData) {
  if (categoryData.isEmpty) {
    return Center(
      child: Text(
        'No category data available',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  // สร้าง list ใหม่เพื่อเรียงลำดับตามมูลค่ามากไปน้อย
  List<MapEntry<String, double>> sortedEntries = categoryData.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  double total = categoryData.values.reduce((a, b) => a + b);
  
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedEntries.map((entry) {
          String category = entry.key;
          double categoryAmount = entry.value;
          // ป้องกันการหารด้วย 0
          double percentage = total > 0 ? (categoryAmount / total) * 100 : 0;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: getColorForCategory(category),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${categoryAmount.toStringAsFixed(1)}฿',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '(${percentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ),
  );
}


Widget buildCategorySource(List<String> sources, Map<String, double> sourceData) {
  if (sourceData.isEmpty) {
    return Center(
      child: Text(
        'No source data available',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  List<MapEntry<String, double>> sortedEntries = sourceData.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  double total = sourceData.values.reduce((a, b) => a + b);
  
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedEntries.map((entry) {
          String source = entry.key;
          double sourceAmount = entry.value;
          double percentage = total > 0 ? (sourceAmount / total) * 100 : 0;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: getColorForSource(source),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    source,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${sourceAmount.toStringAsFixed(1)}฿',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '(${percentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ),
  );
}

Widget buildDonutChart(List<Ingredient> ingredients) {
  Map<String, double> sourceData = {};

  for (var ingredient in ingredients) {
    String source = ingredient.source ?? 'Unknown';
    sourceData[source] = (sourceData[source] ?? 0) + ingredient.price; // ใช้ price แทน quantity
  }

  if (sourceData.isEmpty) {
    return Center(
      child: Text(
        'No data available for this month',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  double total = sourceData.values.reduce((a, b) => a + b);
  if (total <= 0) {
    return Center(
      child: Text(
        'No price data available for this month',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  List<PieChartSectionData> sections = [];
  
  sourceData.forEach((key, value) {
    double percentage = (value / total) * 100;
    sections.add(PieChartSectionData(
      color: getColorForSource(key),
      value: value,
      title: value > 0 ? '${percentage.toStringAsFixed(1)}%' : '0%',
      radius: 60,
      titleStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ));
  });

  return Container(
    width: 300,
    height: 300,
    child: PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 50,
        sectionsSpace: 4,
        borderData: FlBorderData(show: false),
      ),
    ),
  );
}

Color getColorForCategory(String category) {
  switch (category) {
    case 'Fruits':
      return Colors.red;
    case 'Vegetables':
      return Colors.green;
    case 'Meat':
      return Colors.brown;
    case 'Seafood':
      return Colors.blue;
    case 'Cold Cuts':
      return Colors.pink;
    case 'Dairy':
      return Colors.yellow;
    case 'Bread':
      return Colors.orange;
    case 'Cake & Biscuits':
      return Colors.purple;
    case 'Alcoholic Beverages':
      return Colors.deepPurple;
    case 'Beverages':
      return Colors.cyan;
    case 'Coffee & Tea':
      return Colors.brown[300]!;
    case 'Snacks':
      return Colors.amber;
    case 'Sweets':
      return Colors.pinkAccent;
    case 'Condiments & Dips':
      return Colors.greenAccent;
    case 'Dry Goods':
      return Colors.indigo;
    case 'Nuts & Seeds':
      return Colors.deepOrange;
    case 'Canned Food':
      return Colors.teal;
    case 'Cereals':
      return Colors.yellowAccent;
    case 'Leftovers':
      return Colors.grey;
    case 'Easy Meals':
      return Colors.blueGrey;
    case 'Household Essentials':
      return Colors.lime;
    case 'Baking Goods':
      return Colors.brown[200]!;
    case 'Other goods':
      return Colors.grey[500]!;
    case 'Frozen foods':
      return Colors.lightBlue;
    case 'Spices':
      return Colors.redAccent;
    default:
      return Colors.grey;
  }
}

Color getColorForSource(String source) {
  switch (source) {
    case 'Supermarket':
      return Colors.blue;
    case 'Market':
      return Colors.orange;
    case 'Online':
      return Colors.purple;
    case 'Homegrown':
      return Colors.green;
    default:
      return Colors.grey;
  }
}
