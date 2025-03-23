import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/models/ingredient.dart';
import 'package:food_project/screens/home/schedule_screen.dart';
import 'package:food_project/screens/ingredient/ingrediant_detail.dart';
import 'package:food_project/screens/ingredient/search_ingredient.dart';
import 'package:food_project/widgets/ingredient_widget.dart';
import 'package:page_transition/page_transition.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required selectedGoal});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Ingredient> ingredientList = [];
  bool isLoading = true;
  int selectedIndex = 0;
  String userName = "";
  String selectedType = 'Expire In 3 Days';
  List<Ingredient> filteredIngredients = [];

  List<String> ingredientTypes = [
    'Expire In 3 Days',
    'Expired Items',
    'Running Out Of',
  ];

  TextEditingController searchController = TextEditingController();


  Future<void> fetchUserIngredients() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userIngredients')
          .get();

      setState(() {
        ingredientList = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          data['ingredientId'] = doc.id;
          return Ingredient.fromJson(data);
        }).toList();

        filterIngredient();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching ingredients: $e");
      setState(() {
        isLoading = false;
      });
    }
  }
}

 void filterIngredient() {
  setState(() {
    print("📌 Selected Filter: $selectedType");
    
    for (var ingredient in ingredientList) {
     
    }

    if (selectedType == 'Expire In 3 Days') {
      filteredIngredients = ingredientList.where((ingredient) {
        return ingredient.expirationDate != null &&
            ingredient.expirationDate!.isAfter(DateTime.now()) &&
            ingredient.expirationDate!.isBefore(DateTime.now().add(const Duration(days: 3)));
      }).toList();
    } else if (selectedType == 'Expired Items') {
      filteredIngredients = ingredientList.where((ingredient) {
        
        return ingredient.expirationDate != null &&
            ingredient.expirationDate!.isBefore(DateTime.now());
      }).toList();
    } else {
     filteredIngredients = ingredientList.where((ingredient) {
        double quantity = ingredient.quantity; 
        double minQuantity = ingredient.minQuantity; 
        return quantity <= minQuantity;
      }).toList();
    }

  });
}


  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userName = userDoc['username'] ?? '';
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    } else {
      print("User not logged in");
    }
  }

  void setupIngredientListener() {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    setState(() {
      isLoading = true; 
    });

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('userIngredients')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          ingredientList = snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['ingredientId'] = doc.id;
            return Ingredient.fromJson(data);
          }).toList();
          
          filterIngredient();
          isLoading = false; 
        });
      }
    }, onError: (error) {
      print("❌ Error listening to ingredients: $error");
      if (mounted) {
        setState(() {
          isLoading = false;
          ingredientList = [];
          filterIngredient(); 
        });
      }
    });
  } else {
    setState(() {
      isLoading = false; 
      ingredientList = [];
      filterIngredient();
    });
  }
}


  Future<void> refreshIngredients() async {
  try {
    setState(() {
      isLoading = true;
    });
    
    
    filterIngredient();
    
    setState(() {
      isLoading = false;
    });
  } catch (e) {
    print("❌ Error refreshing ingredients: $e");
    setState(() {
      isLoading = false;
    });
  }
}

@override
  void initState() {
    super.initState();
    _fetchUserName();
    setupIngredientListener();
  }


  void searchIngredients(String query) {
  setState(() {
    if (query.isEmpty) {
     
      filterIngredient();
    } else {
    
      filteredIngredients = ingredientList.where((ingredient) {
       
        bool matchesSearch = ingredient.ingredientsName
            .toLowerCase()
            .contains(query.toLowerCase());

       
        bool matchesFilter = false;
        if (selectedType == 'Expire In 3 Days') {
          matchesFilter = ingredient.expirationDate.isAfter(DateTime.now()) &&
              ingredient.expirationDate
                  .isBefore(DateTime.now().add(const Duration(days: 3)));
        } else if (selectedType == 'Expired Items') {
          matchesFilter = ingredient.expirationDate.isBefore(DateTime.now());
        } else if (selectedType == 'Running Out Of') {
          matchesFilter = ingredient.quantity <= ingredient.minQuantity;
        }

        
        return matchesSearch && matchesFilter;
      }).toList();

      
      filteredIngredients.sort((a, b) {
        return a.expirationDate.compareTo(b.expirationDate);
      });
    }
  });
}

@override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }


  

  @override
  Widget build(BuildContext context) {
    print("isLoading: $isLoading");
    Size size = MediaQuery.of(context).size;

    

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top :20 , left: 0),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Hi, $userName',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                     color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 10),
              child: Text(
                'Ingredient Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Constants.blackColor,
                ),
              ),
            ),
            const SizedBox(height: 15),

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
                      filterIngredient();  
                    },

                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
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
            const SizedBox(
                height: 18), // เพิ่มช่องว่างระหว่างหมวดหมู่และช่องค้นหา

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
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search ingredient',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade500,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (value) {
                         searchIngredients(value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(
                      width: 7), // เพิ่มช่องว่างระหว่างช่องค้นหาและไอคอน
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

            // show ingredient
            isLoading
            ? const Center(child: CircularProgressIndicator())
            : filteredIngredients.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 55),
                    Image.asset(
                      'assets/images/case.png',
                     width: 250,
                     height: 250,
                    ),
                    SizedBox(height: 10),
                    Text(
                      selectedType == 'Expire In 3 Days'
                        ?  "You don't have ingredients expire in 3 days"
                        : selectedType == 'Expired Items'
                          ? "You don't have ingredient expired"
                          : "You don't have ingredients running out of",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ))
              : ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredIngredients.length,
              itemBuilder: (BuildContext context, int index) {
                final ingredient = filteredIngredients[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        child: IngredientDetailPage(
                          ingredient: ingredient,
                          recipes: [],
                        ),
                        type: PageTransitionType.bottomToTop,
                      ),
                    );
                  },
                  child: IngredientWidget(
                    index: index,
                    ingredientList: filteredIngredients,
                    ingredient: ingredient,
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
