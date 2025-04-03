import 'package:calendar_agenda/calendar_agenda.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/screens/home/add_schedule.dart';
import 'package:food_project/screens/recipe/recipe_screen.dart';

import '../../../common/colo_extension.dart';
import '../../../common/common.dart';
import '../../../common_widget/round_button.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({
    super.key,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  CalendarAgendaController _calendarAgendaControllerAppBar =
      CalendarAgendaController();
  late DateTime _selectedDateAppBBar;

  List eventArr = [
    {
      "name": "Lunch",
      "start_time": "08/12/2024 01:00 PM",
    }
  ];

  List selectDayEventArr = [];

  @override
  void initState() {
    super.initState();
    _selectedDateAppBBar = DateTime.now();
    setDayEventList();
  }

  void setDayEventList() {
    var date = dateToStartDate(_selectedDateAppBBar);
    selectDayEventArr = eventArr.map((wObj) {
      return {
        "name": wObj["name"],
        "start_time": wObj["start_time"],
        "date": stringToDate(wObj["start_time"].toString(),
            formatStr: "dd/MM/yyyy hh:mm aa")
      };
    }).where((wObj) {
      return dateToStartDate(wObj["date"] as DateTime) == date;
    }).toList();

    if (mounted) {
      setState(() {});
    }
  }

  void _addNewMeal(String mealName, String mealType) {
  DateTime now = _selectedDateAppBBar;
  int hour;
  
  switch (mealType) {
    case "breakfast":
      hour = 8; // 8:00 AM
      break;
    case "lunch":
      hour = 13; // 1:00 PM
      break;
    case "snack":
      hour = 16; // 4:00 PM
      break;
    case "dinner":
      hour = 19; // 7:00 PM
      break;
    default:
      hour = 12; // default
  }
  
  // สร้างวันที่และเวลาใหม่
  DateTime mealTime = DateTime(now.year, now.month, now.day, hour, 0);
  // ฟอร์แมตวันที่เป็นสตริง
  String formattedDate = "${mealTime.day.toString().padLeft(2, '0')}/${mealTime.month.toString().padLeft(2, '0')}/${mealTime.year}";
  String formattedTime = "${hour > 12 ? (hour - 12).toString().padLeft(2, '0') : hour.toString().padLeft(2, '0')}:00 ${hour >= 12 ? 'PM' : 'AM'}";
  String formattedDateTime = "$formattedDate $formattedTime";
  
  // สร้างออบเจ็กต์มื้ออาหารใหม่
  Map<String, dynamic> newMeal = {
    "name": mealName,
    "start_time": formattedDateTime,
    "meal_type": mealType,
    "menu_items": [],
  };
  
  // เพิ่มมื้ออาหารใหม่เข้าไปใน eventArr
  setState(() {
    eventArr.add(newMeal);
    setDayEventList(); // อัพเดทรายการกิจกรรมของวัน
  });
  
  
}

 String _getFormattedDate() {
    final now = DateTime.now();
    final List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return "${months[now.month - 1]} ${now.day} ${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
              child: Row(
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
                  const SizedBox(width: 5),
                  const Text(
                    'Add Meals',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
             Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                   Text(
              'Today, ${_getFormattedDate()}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
                ],
              ),
            ),
           

            // Calendar Agenda
            Container(
  height: 120, 
  child: CalendarAgenda(
    controller: _calendarAgendaControllerAppBar,
    appbar: false,
    selectedDayPosition: SelectedDayPosition.center,
    weekDay: WeekDay.short,
    dayNameFontSize: 12,
    dayNumberFontSize: 16,
    dayBGColor: Colors.grey.withOpacity(0.15),
    titleSpaceBetween: 15,
    backgroundColor: Colors.transparent,
    fullCalendarScroll: FullCalendarScroll.horizontal,
    fullCalendarDay: WeekDay.short,
    selectedDateColor: Colors.white,
    dateColor: Colors.black,
    locale: 'en',
    initialDate: DateTime.now(),
    calendarEventColor: TColor.primaryColor2,
    firstDate: DateTime.now().subtract(const Duration(days: 140)),
    lastDate: DateTime.now().add(const Duration(days: 60)),
    onDateSelected: (date) {
      _selectedDateAppBBar = date;
      setDayEventList();
    },
    selectedDayLogo: Container(
      width: double.maxFinite,
      height: double.maxFinite,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: TColor.primaryG,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(10.0),
      ),
    ),
  ),
),
 SizedBox(height: 10),
          Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                 
                  children: [
                    _buildBreakfast(),
                    const SizedBox(height: 10),
                    _buildLunch(),
                     const SizedBox(height: 10),
                    _buildSnack(),
                     const SizedBox(height: 10),
                    _buildDinner(),
                  ],
                ),
              ),
            
          
        ],
      ),
    ),
  );
}

Widget _buildBreakfast() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Column(
      children: [
        Container(
           
          width: 420, 
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // ส่วนเนื้อหาด้านซ้าย
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 15, left: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Breakfast',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Add your breakfast meal',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                    // ปุ่ม Add
                    Padding(
                      padding: const EdgeInsets.only(left: 15, bottom: 15),
                      child: InkWell(
                        onTap: () {
                          // นำทางไปยังหน้า Recipe เมื่อผู้ใช้คลิกปุ่ม
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => RecipeScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          width: 120,
                          decoration: BoxDecoration(
                            color: Color(0xFF78d454),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Add',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
             ClipRRect(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.only(right: 15),
                child: Image.asset(
                  'assets/images/breakfast.png',
                  width: 100,
                  
                  fit: BoxFit.cover,
                ),
              ),
            ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildLunch() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Column(
      children: [
        Container(
          
          width: 420, 
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // ส่วนเนื้อหาด้านซ้าย
             ClipRRect(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.only(left: 15),
                child: Image.asset(
                  'assets/images/lunch.png',
                  width: 100,
                  
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 15, left: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lunch',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Add your lunch meal',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: InkWell(
                        onTap: () {
                          // นำทางไปยังหน้า Recipe เมื่อผู้ใช้คลิกปุ่ม
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => RecipeScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          width: 120,
                          decoration: BoxDecoration(
                            color: Color(0xFF78d454),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Add',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                        ],
                      ),
                    ),
                    // ปุ่ม Add
                    
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildSnack() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Column(
      children: [
        Container(
           
          width: 420, 
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // ส่วนเนื้อหาด้านซ้าย
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 15, left: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Snack',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Add your snack meal',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                    // ปุ่ม Add
                    Padding(
                      padding: const EdgeInsets.only(left: 15, bottom: 15),
                      child: InkWell(
                        onTap: () {
                          // นำทางไปยังหน้า Recipe เมื่อผู้ใช้คลิกปุ่ม
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => RecipeScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          width: 120,
                          decoration: BoxDecoration(
                            color: Color(0xFF78d454),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Add',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
             ClipRRect(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.only(right: 15),
                child: Image.asset(
                  'assets/images/snack.png',
                  width: 100,
                  
                  fit: BoxFit.cover,
                ),
              ),
            ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildDinner() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Column(
      children: [
        Container(
           
          width: 420, 
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // ส่วนเนื้อหาด้านซ้าย
             ClipRRect(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.only(left: 15),
                child: Image.asset(
                  'assets/images/dinner.png',
                  width: 100,
                  
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 15, left: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dinner',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Add your dinner meal',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: InkWell(
                        onTap: () {
                          // นำทางไปยังหน้า Recipe เมื่อผู้ใช้คลิกปุ่ม
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => RecipeScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          width: 120,
                          decoration: BoxDecoration(
                            color: Color(0xFF78d454),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Add',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                        ],
                      ),
                    ),
                    // ปุ่ม Add
                    
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}