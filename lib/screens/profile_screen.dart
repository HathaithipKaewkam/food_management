import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/screens/login/signin_screen.dart';
import 'package:food_project/screens/setting/setting_screen.dart';
import 'package:food_project/widgets/profile_widget.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = '';
  String userEmail = '';
  String profileImage = ''; 
   double targetCalories = 0.0;
  double consumedCalories = 0.0;
  bool isLoadingCalories = true;
  int totalIngredients = 0;
  int usedIngredients = 0;
  double usedIngredientsPercentage = 0.0;
  bool isLoadingIngredients = true;
  int expiredItemsCount = 0;
double expiredItemsValue = 0.0;
bool isLoadingExpired = true;
int purchasedItemsCount = 0;
double purchasedItemsValue = 0.0;
bool isLoadingPurchases = true;
int cookedMealsCount = 0;
bool isLoadingCookedMeals = true;
 String today = DateFormat('yyyy-MM-dd').format(DateTime.now()); 
  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchProfileImage();
    _fetchCaloriesData();
    _fetchIngredientsData();
    _fetchExpiredItems();
    _fetchPurchaseHistory();
     _fetchCookedMeals();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
     
      setState(() {
        userEmail = user.email ?? 'No email';
      });

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userName = userDoc['username'] ?? 'User';
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    } else {
      print("User not logged in");
    }
  }

Future<void> _fetchProfileImage() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
     
      
      DocumentSnapshot profileDoc = await FirebaseFirestore.instance
          .collection('userProfiles')
          .doc(user.uid)
          .get();

     
      
      if (profileDoc.exists && profileDoc.data() is Map<String, dynamic>) {
        Map<String, dynamic> data = profileDoc.data() as Map<String, dynamic>;
       
        
        if (data.containsKey('profileImage') && data['profileImage'] != null) {
          String imageValue = data['profileImage'].toString();
          
          
         
          if (imageValue.startsWith('assets/')) {
            setState(() {
              profileImage = imageValue;
            });
           
          }
        
          else if (imageValue.startsWith('http')) {
            setState(() {
              profileImage = imageValue;
            });
           
          } 
         
          else if (!imageValue.contains('data:image')) {
            try {
            
              final ref = FirebaseStorage.instance.ref().child('profile_images/${user.uid}/$imageValue');
              
              
              final url = await ref.getDownloadURL();
             
              
              setState(() {
                profileImage = url;
              });
            } catch (e) {
             
             
              try {
                
                final ref = FirebaseStorage.instance.ref().child(imageValue);
                final url = await ref.getDownloadURL();
                setState(() {
                  profileImage = url;
                });
               
              } catch (e2) {
               
              }
            }
          }
          else if (imageValue.contains('data:image')) {
            setState(() {
              profileImage = imageValue;
            });
           
          }
        } 
      } 
    } catch (e) {
      print('❌ Error fetching profile image: $e');
    }
  } 
}

Future<void> _fetchCookedMeals() async {
  print("🔍 Starting to fetch cooked meals data");
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      DateTime now = DateTime.now();
      DateTime startOfWeek = now.subtract(Duration(days: 7));
      
      // คิวรี่ข้อมูลจาก eatingHistory collection โดยจำกัดเฉพาะรายการในช่วง 7 วันที่ผ่านมา
      QuerySnapshot eatingHistoryQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('eatingHistory')
          .where('date', isGreaterThanOrEqualTo: startOfWeek)
          .get();
      
      // นับจำนวนมื้ออาหารทั้งหมด
      int mealCount = eatingHistoryQuery.docs.length;
      
      setState(() {
        cookedMealsCount = mealCount;
        isLoadingCookedMeals = false;
      });
      
      print("✅ Cooked meals data loaded - Count: $mealCount in the past 7 days");
    } catch (e) {
      print('❌ Error fetching cooked meals data: $e');
      setState(() {
        isLoadingCookedMeals = false;
      });
    }
  } else {
    print("⚠️ No user logged in");
    setState(() {
      isLoadingCookedMeals = false;
    });
  }
}


Future<void> _fetchIngredientsData() async {
  print("🔍 Starting to fetch ingredients data");
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      DateTime now = DateTime.now();
      DateTime startOfWeek = now.subtract(Duration(days: 7));
      
      QuerySnapshot allIngredientsQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userIngredients')
          .get();
      
      int usedCount = 0;
      int totalUsageCount = 0;
      int totalQuantityUsed = 0;
      int total = allIngredientsQuery.docs.length;
      
      for (var doc in allIngredientsQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> usageHistory = [];
        
        if (data.containsKey('usageHistory')) {
          List<dynamic> allUsageHistory = data['usageHistory'] ?? [];
          usageHistory = allUsageHistory.where((usage) {
              if (usage is Map && usage.containsKey('date')) {
                try {
                  DateTime usageDate;
                  
                  if (usage['date'] is Timestamp) {
                    usageDate = (usage['date'] as Timestamp).toDate();
                  } else if (usage['date'] is String) {
                    try {
                      if (usage['date'].contains('T')) {
                        usageDate = DateTime.parse(usage['date']);
                      } else {
                        usageDate = DateFormat('yyyy-MM-dd').parse(usage['date']);
                      }
                    } catch (e) {
                      print("⚠️ Error parsing date: ${e.toString()}");
                      return false;
                    }
                  } else {
                    
                    return false;
                  }
                  
                 
                  return usageDate.isAfter(startOfWeek) || isSameDay(usageDate, startOfWeek);
                } catch (e) {
                  print("❌ Error in date comparison: ${e.toString()}");
                  return false;
                }
              }
              return false;
            }).toList();
          
          if (usageHistory.isNotEmpty) {
            usedCount++;
            totalUsageCount += usageHistory.length;
            
            for (var usage in usageHistory) {
              if (usage is Map && usage.containsKey('quantity_used')) {
                int qty = (usage['quantity_used'] is num) 
                    ? (usage['quantity_used'] as num).toInt() 
                    : 1;
                totalQuantityUsed += qty;
              }
            }
          }
        }
      }
      
      double percentage = targetCalories > 0 ? 
  (consumedCalories / targetCalories).clamp(0.0, 1.0) : 0.0;
      setState(() {
        totalIngredients = total;
        usedIngredients = usedCount;    
        usedIngredientsPercentage = percentage;
        isLoadingIngredients = false;
      });
    } catch (e) {
      print('❌ Error fetching ingredients data: $e');
      setState(() {
        isLoadingIngredients = false;
      });
    }
  }
}

 Future<void> _fetchCaloriesData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot macroDoc = await FirebaseFirestore.instance
            .collection('usersCaloriesMacronutrient')
            .doc(user.uid)
            .get();

        if (macroDoc.exists && macroDoc.data() is Map<String, dynamic>) {
          Map<String, dynamic> macroData = macroDoc.data() as Map<String, dynamic>;
          double calories = 0.0;
          
          if (macroData.containsKey('caloriesPerDay')) {
            if (macroData['caloriesPerDay'] is num) {
              calories = (macroData['caloriesPerDay'] as num).toDouble();
            } else if (macroData['caloriesPerDay'] is String) {
              calories = double.tryParse(macroData['caloriesPerDay']) ?? 0.0;
            }
          }
          
          String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          
          QuerySnapshot consumptionDocs = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('calorieConsumption')
              .where('dateStr', isEqualTo: today)
              .get();
          
          double totalConsumed = 0.0;
          for (var doc in consumptionDocs.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('kcal')) {
              if (data['kcal'] is num) {
                totalConsumed += (data['kcal'] as num).toDouble();
              } else if (data['kcal'] is String) {
                totalConsumed += double.tryParse(data['kcal']) ?? 0.0;
              }
            }
          }
          
          setState(() {
            targetCalories = calories;
            consumedCalories = totalConsumed;
            isLoadingCalories = false;
          });
          
          print("✅ Calories data loaded - Target: $targetCalories, Consumed: $consumedCalories");
        }
      } catch (e) {
        print('❌ Error fetching calories data: $e');
        setState(() {
          isLoadingCalories = false;
        });
      }
    }
  }

  Future<void> _fetchExpiredItems() async {
  print("🔍 Starting to fetch expired items data");
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {

      DateTime now = DateTime.now();
      DateTime startOfWeek = now.subtract(Duration(days: 7));
      QuerySnapshot allIngredientsQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userIngredients')
          .get();
      
      int expiredCount = 0;
      double totalLostValue = 0.0;
      DateTime today = DateTime.now();
      
      for (var doc in allIngredientsQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
       
        if (data.containsKey('expirationDate') && data['expirationDate'] != null) {
        
          DateTime expirationDate;
          
        
          if (data['expirationDate'] is Timestamp) {
            expirationDate = (data['expirationDate'] as Timestamp).toDate();
          } else if (data['expirationDate'] is String) {
            try {
             
              if (data['expirationDate'].contains('T')) {
                expirationDate = DateTime.parse(data['expirationDate']);
              } else {
                expirationDate = DateFormat('yyyy-MM-dd').parse(data['expirationDate']);
              }
            } catch (e) {
              print("⚠️ Failed to parse date: ${data['expirationDate']} - Error: $e");
              continue;
            }
          } else {
            continue;
          }
          
        
          if ((expirationDate.isBefore(now) || isSameDay(expirationDate, now)) && 
              expirationDate.isAfter(startOfWeek)) {
            
            expiredCount++;
          
            
           
            if (data.containsKey('price')) {
              double price = 0.0;
              double quantity = 1.0; 
           
              double remainingQty = 0.0;
              
             
              if (data['price'] is num) {
                price = (data['price'] as num).toDouble();
              } else if (data['price'] is String) {
                price = double.tryParse(data['price']) ?? 0.0;
              }
              
             
              if (data.containsKey('quantity')) {
                if (data['quantity'] is num) {
                  quantity = (data['quantity'] as num).toDouble();
                } else if (data['quantity'] is String) {
                  quantity = double.tryParse(data['quantity']) ?? 1.0;
                }
              }
              
             
              if (data.containsKey('remainingQuantity')) {
                if (data['remainingQuantity'] is num) {
                  remainingQty = (data['remainingQuantity'] as num).toDouble();
                } else if (data['remainingQuantity'] is String) {
                  remainingQty = double.tryParse(data['remainingQuantity']) ?? 0.0;
                }
              } else {
              
                remainingQty = quantity;
              }
              
              
              double pricePerUnit = (quantity > 0) ? price / quantity : price;
              
             
              double lostValue = pricePerUnit * remainingQty;
              totalLostValue += lostValue;
              
              
            } else {
             
            }
          }
        }
      }
      
      setState(() {
        expiredItemsCount = expiredCount;
        expiredItemsValue = totalLostValue;
        isLoadingExpired = false;
      });
      
      print("✅ Expired items data loaded - Count: $expiredCount, Total lost value: ฿${totalLostValue.toStringAsFixed(2)}");
    } catch (e) {
      print('❌ Error fetching expired items data: $e');
      setState(() {
        isLoadingExpired = false;
      });
    }
  } else {
    print("⚠️ No user logged in");
  }
}

Future<void> _fetchPurchaseHistory() async {
 
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
     
      QuerySnapshot purchaseHistoryQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('purchaseHistory')
          .get();
      
      
      DateTime now = DateTime.now();
     
      DateTime startOfWeek = now.subtract(Duration(days: 7));
      
      
      int itemCount = 0;
      double totalValue = 0.0;
      
 
      for (var doc in purchaseHistoryQuery.docs) {
      
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        
      
        if (data.containsKey('date')) {
        
        } else if (data.containsKey('createdAt')) {
        
        } else {
        
          List<dynamic> items = [];
          if (data.containsKey('items') && data['items'] is List) {
            items = data['items'];
          
            itemCount += items.length;
          } else {
           
            itemCount += 1;
          }
          
         
          if (data.containsKey('totalPrice')) {
           
            if (data['totalPrice'] is num) {
              double price = (data['totalPrice'] as num).toDouble();
              totalValue += price;
            
            }
          } else if (data.containsKey('price')) {
          
            if (data['price'] is num) {
              double price = (data['price'] as num).toDouble();
              totalValue += price;
            
            }
          } else {
         
          }
          
          continue; 
        }
        
       
        DateTime? purchaseDate;
        bool dateParseSuccess = false;
        
        
        if (data.containsKey('date') && data['date'] != null) {
          try {
            if (data['date'] is Timestamp) {
              purchaseDate = (data['date'] as Timestamp).toDate();
              dateParseSuccess = true;
             
            } else if (data['date'] is String) {
              try {
                if (data['date'].contains('T')) {
                  purchaseDate = DateTime.parse(data['date']);
                } else {
                  purchaseDate = DateFormat('yyyy-MM-dd').parse(data['date']);
                }
                dateParseSuccess = true;
              
              } catch (e) {
              
              }
            } else {
             
            }
          } catch (e) {
           
          }
        }
        
      
        if (!dateParseSuccess && data.containsKey('createdAt') && data['createdAt'] != null) {
          try {
            if (data['createdAt'] is Timestamp) {
              purchaseDate = (data['createdAt'] as Timestamp).toDate();
              dateParseSuccess = true;
           
            } else if (data['createdAt'] is String) {
              try {
                if (data['createdAt'].contains('T')) {
                  purchaseDate = DateTime.parse(data['createdAt']);
                } else {
                  purchaseDate = DateFormat('yyyy-MM-dd').parse(data['createdAt']);
                }
                dateParseSuccess = true;
              
              } catch (e) {
             
              }
            }
          } catch (e) {
            print("❌ Error parsing createdAt: $e");
          }
        }
        
       
        if (!dateParseSuccess) {
         
          List<dynamic> items = [];
          if (data.containsKey('items') && data['items'] is List) {
            items = data['items'];
            itemCount += items.length;
         
          } else {
            itemCount += 1;
         
          }
          
      
          if (data.containsKey('totalPrice')) {
           
            if (data['totalPrice'] is num) {
              double price = (data['totalPrice'] as num).toDouble();
              totalValue += price;
          
            } else if (data['totalPrice'] is String) {
              double price = double.tryParse(data['totalPrice']) ?? 0.0;
              totalValue += price;
            
            }
          } else if (data.containsKey('price')) {
          
            if (data['price'] is num) {
              double price = (data['price'] as num).toDouble();
              totalValue += price;
            
            } else if (data['price'] is String) {
              double price = double.tryParse(data['price']) ?? 0.0;
              totalValue += price;
           
            }
          }
          
          continue;
        }
        
        if (purchaseDate!.isAfter(startOfWeek)) {
        
       
          List<dynamic> items = [];
          if (data.containsKey('items') && data['items'] is List) {
            items = data['items'];
            itemCount += items.length;
        
          } else {
            itemCount += 1;
           
          }
          
       
          if (data.containsKey('totalPrice')) {
          
            if (data['totalPrice'] is num) {
              double price = (data['totalPrice'] as num).toDouble();
              totalValue += price;
             
            } else if (data['totalPrice'] is String) {
              double price = double.tryParse(data['totalPrice']) ?? 0.0;
              totalValue += price;
             
            }
          } else if (data.containsKey('price')) {
           
            if (data['price'] is num) {
              double price = (data['price'] as num).toDouble();
              totalValue += price;
              
            } else if (data['price'] is String) {
              double price = double.tryParse(data['price']) ?? 0.0;
              totalValue += price;
            
            }
          }
        } else {
         
        }
      }
      
      setState(() {
        purchasedItemsCount = itemCount;
        purchasedItemsValue = totalValue;
        isLoadingPurchases = false;
      });
      
     
    } catch (e) {
      print('❌ Error fetching purchase history: $e');
      setState(() {
        isLoadingPurchases = false;
      });
    }
  } else {
    print("⚠️ No user logged in");
  }
}


bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year && 
         date1.month == date2.month && 
         date1.day == date2.day;
}

Widget _buildCircularCaloriesProgress() {
  double percentage = targetCalories > 0 ? 
  (consumedCalories / targetCalories).clamp(0.0, 1.0) : 0.0;
  
  Color progressColor;
  if (percentage < 0.5) {
    progressColor = Color(0xFF16a34a); 
  } else if (percentage < 0.75) {
    progressColor = Colors.amber; 
  } else if (percentage < 1.0) {
    progressColor = Colors.orange; 
  } else {
    progressColor = Colors.red; 
  }
  
  return Stack(
  children: [
    Container(
      margin: EdgeInsets.symmetric(vertical: 2.0, horizontal: 12.0), 
      padding: EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0), 
            child: Row(
              children: [
                Text(
                  'Calories Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: CircularPercentIndicator(
              radius: 90.0, 
              lineWidth: 12.0, 
              percent: percentage,
              arcType: ArcType.HALF,
              arcBackgroundColor: Colors.grey.shade200,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${consumedCalories.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    ' of ${targetCalories.toStringAsFixed(0)} kcal',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              progressColor: progressColor,
              animation: true,
              animationDuration: 1000,
              startAngle: 180,
            ),
          ),
        ],
      ),
    ),
    Positioned(
      bottom: 30, 
      left: 10,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12), 
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, color: progressColor, size: 18),
            SizedBox(width: 6),
            Text(
              'Eaten today: ',
              style: TextStyle(
                fontSize: 14, // ลดขนาดฟอนต์
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              '${consumedCalories.toStringAsFixed(0)} kcal',
              style: TextStyle(
                fontSize: 14, // ลดขนาดฟอนต์
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
      ),
    ),
  ],
);

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
    return "${months[now.month - 1]} ${now.day}";
  }
void _logout() async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16a34a)),
          ),
        ),
      );
    },
  );

  try {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pop();
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => SignInScreen()),
      (route) => false, 
    );
  } catch (e) {

    Navigator.of(context).pop();
    
    print('Error during logout: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to logout. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _refreshAllData() async {
  setState(() {
    isLoadingCalories = true;
    isLoadingIngredients = true;
    isLoadingExpired = true;
    isLoadingPurchases = true;
    isLoadingCookedMeals = true;
  });
  await Future.delayed(Duration(milliseconds: 300));
  await Future.wait([
    _fetchUserName(),
    _fetchProfileImage(),
    _fetchIngredientsData(),
    _fetchExpiredItems(),
    _fetchPurchaseHistory(),
    _fetchCookedMeals(),
  ]);
}

  @override
  Widget build(BuildContext context) {
     String today = DateFormat('yyyy-MM-dd').format(DateTime.now()); 
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: RefreshIndicator(
      onRefresh: _refreshAllData,
      color: Color(0xFF16a34a),
      child: StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usersCaloriesMacronutrient')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          if (data.containsKey('caloriesPerDay')) {
            if (data['caloriesPerDay'] is num) {
              targetCalories = (data['caloriesPerDay'] as num).toDouble();
            } else if (data['caloriesPerDay'] is String) {
              targetCalories = double.tryParse(data['caloriesPerDay']) ?? 0.0;
            }
          }
          }

         return StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser?.uid)
      .collection('calorieConsumption')
      .where('dateStr', isEqualTo: today)
      .snapshots(),
  builder: (context, consumptionSnapshot) {
    // คำนวณ totalConsumed โดยไม่เรียก setState
    double totalConsumed = 0.0;
    if (consumptionSnapshot.hasData) {
      for (var doc in consumptionSnapshot.data!.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('kcal')) {
          if (data['kcal'] is num) {
            totalConsumed += (data['kcal'] as num).toDouble();
          } else if (data['kcal'] is String) {
            totalConsumed += double.tryParse(data['kcal']) ?? 0.0;
          }
        }
      }
      consumedCalories = totalConsumed;
    }


        
        return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12 , right: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
      
                   Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $userName !',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 5),
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
                    
      
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: GestureDetector( 
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SettingsScreen()),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: profileImage.isNotEmpty
                            ? (profileImage.startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(profileImage.split(',')[1]),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading Base64 image: $error');
                                      return Center(child: Icon(Icons.person, size: 40, color: Colors.grey));
                                    },
                                  )
                                : profileImage.startsWith('assets/')
                                    ? Image.asset(
                                        profileImage,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Error loading asset image: $error');
                                          return Center(child: Icon(Icons.person, size: 40, color: Colors.grey));
                                        },
                                      )
                                    : Image.network(
                                        profileImage,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Error loading network image: $error');
                                          return Center(child: Icon(Icons.person, size: 40, color: Colors.grey));
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                              color: Color(0xFF16a34a),
                                            ),
                                          );
                                        },
                                      ))
                            : Center(child: Icon(Icons.person, size: 40, color: Colors.grey)),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
         
            _buildCircularCaloriesProgress(),
             const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                'Weekly Ingredients Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 12.0),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.boxArchive, color: Color(0xFF16a34a), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Ingredients Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  GridView.count(
                    crossAxisCount: 2,  
                    childAspectRatio: 1.5,  
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(), 
                    crossAxisSpacing: 10, 
                    mainAxisSpacing: 10, 
                    padding: EdgeInsets.zero,
                    children: [
                      _buildStatCard(
                        icon: FontAwesomeIcons.carrot,
                        iconColor: Color(0xFF16a34a),
                        title: 'Used Ingredients',
                       mainStat: '$usedIngredients items',
                        subText: '${usedIngredientsPercentage.toStringAsFixed(0)}% of total',
                      ),
                      
                      _buildStatCard(
                        icon: FontAwesomeIcons.trashCan,
                        iconColor: Colors.red.shade400,
                        title: 'Expired Items',
                       mainStat: isLoadingExpired ? 'Loading...' : '$expiredItemsCount items',
                        subText: isLoadingExpired ? 'Calculating...' : 'Lost value: ฿${expiredItemsValue.toStringAsFixed(0)}',
                      ),
                      
                      _buildStatCard(
                        icon: FontAwesomeIcons.cartShopping,
                        iconColor: Colors.blue,
                        title: 'Purchased Items',
                        mainStat: isLoadingPurchases ? 'Loading...' : '$purchasedItemsCount items',
                        subText: isLoadingPurchases ? 'Calculating...' : 'Total: ฿${purchasedItemsValue.toStringAsFixed(0)}',
                      ),
                      
                      _buildStatCard(
                        icon: FontAwesomeIcons.kitchenSet,
                        iconColor: Colors.amber.shade700,
                        title: 'Cooked Meals',
                        mainStat: isLoadingCookedMeals ? 'Loading...' : '$cookedMealsCount meals',
                        subText: 'Past 7 days',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: ElevatedButton(
              onPressed: () {
                _logout(); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.red.shade200),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
                                ],
                              ),
                            );
                            
  }
  );
  })
  ));
                        }

                        
                      }

Widget _buildStatCard({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String mainStat,
  required String subText,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.grey.shade200),
    ),
    padding: EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(icon, color: iconColor, size: 14),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Expanded(
          child: Center(
            child: Text(
              mainStat,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        Text(
          subText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    ),
  );
}




