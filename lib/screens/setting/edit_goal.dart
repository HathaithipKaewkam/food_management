import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/screens/root_screen.dart';

class EditGoal extends StatefulWidget {
  const EditGoal({super.key});

  @override
  State<EditGoal> createState() => _EditGoalState();
}

class _EditGoalState extends State<EditGoal> {
  final CarouselSliderController? buttonCarouselController = CarouselSliderController();
  int selectedGoalIndex = 0;
  bool _isLoading = true;

  List goalArr = [
    {
      "image": "assets/images/goal_build_muscle.png",
      "title": "Build Muscle",
      "subtitle": "Focus on protein-rich meals to\nsupport muscle growth."
    },
    {
      "image": "assets/images/goal_lose_weight.png",
      "title": "Lose Weight",
      "subtitle":
          "Low-calorie meals with balanced\nnutrition to support weight loss."
    },
    {
      "image": "assets/images/goal_balanced_diet.png",
      "title": "Balanced Diet",
      "subtitle": "Meals that provide a balance of\ncarbs, proteins, and fats."
    },
    {
      "image": "assets/images/goal_healthy_food.png",
      "title": "Healthy Eating",
      "subtitle": "Focus on nutrient-dense and\nminimally processed foods."
    },
  ];

   @override
  void initState() {
    super.initState();
    _loadExistingGoal();
  }

  Future<void> _loadExistingGoal() async {
    setState(() {
      _isLoading = true;
    });
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final goalDoc = await FirebaseFirestore.instance
            .collection('userGoals')
            .doc(user.uid)
            .get();
            
        if (goalDoc.exists && goalDoc.data() != null) {
          final data = goalDoc.data()!;
          if (data.containsKey('goal')) {
            final existingGoal = data['goal'] as String;
            
            // หา index ของ goal ที่ตรงกับค่าที่เก็บไว้
            for (int i = 0; i < goalArr.length; i++) {
              if (goalArr[i]['title'] == existingGoal) {
                setState(() {
                  selectedGoalIndex = i;
                });
                // ย้าย Carousel ไปที่ index ที่ถูกต้อง
                if (buttonCarouselController != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    buttonCarouselController!.animateToPage(selectedGoalIndex);
                  });
                }
                break;
              }
            }
            
            print('✅ Existing goal loaded: $existingGoal');
          }
        } else {
          print('⚠️ No existing goal found');
        }
      } catch (e) {
        print('❌ Error loading goal: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print('⚠️ User not logged in');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> saveGoalToDatabase(String goal) async {
  setState(() {
    _isLoading = true;
  });
  
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      await FirebaseFirestore.instance
          .collection('userGoals')
          .doc(user.uid)
          .set({
            'goal': goal, 
            'timestamp': FieldValue.serverTimestamp()
          });
      
      print('✅ Goal saved successfully: $goal');
      
      // แสดง snackbar ว่าบันทึกสำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Goal updated successfully!'),
          backgroundColor: Color(0xFF325b51),
        ),
      );
      
      // กลับไปยังหน้า Settings แทนที่จะไปหน้า RootPage
      Navigator.pop(context);
      
    } catch (e) {
      print('❌ Error saving goal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update goal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  } else {
    setState(() {
      _isLoading = false;
    });
    print('⚠️ User not logged in');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You must be logged in to save a goal'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading && selectedGoalIndex == 0
        ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF325b51)),
            ),
          )
        :  Stack(
          children: [
            Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                   icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                color: Colors.black,
                iconSize: 20,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            Center(
              child: CarouselSlider(
                items: goalArr
                    .map(
                      (gObj) => Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Colors.greenAccent, Colors.lightGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: EdgeInsets.symmetric(
                            vertical: media.width * 0.1, horizontal: 25),
                        alignment: Alignment.center,
                        child: FittedBox(
                          child: Column(
                            children: [
                              Image.asset(
                                gObj["image"].toString(),
                                width: media.width * 0.5,
                                fit: BoxFit.fitWidth,
                              ),
                              SizedBox(
                                height: media.width * 0.1,
                              ),
                              Text(
                                gObj["title"].toString(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700),
                              ),
                              Container(
                                width: media.width * 0.1,
                                height: 1,
                                color: Colors.white,
                              ),
                              SizedBox(
                                height: media.width * 0.02,
                              ),
                              Text(
                                gObj["subtitle"].toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
                carouselController: buttonCarouselController,
                options: CarouselOptions(
                  autoPlay: false,
                  enlargeCenterPage: true,
                  viewportFraction: 0.7,
                  aspectRatio: 0.74,
                  initialPage: selectedGoalIndex,
                  onPageChanged: (index, reason) {
                  setState(() {
                    selectedGoalIndex = index;
                  });
                },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 40),
              width: media.width,
              child: Column(
                children: [
                  SizedBox(
                    height: media.width * 0.05,
                  ),
                  const Text(
                    "What is your goal ?",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    "It will help us to choose a best\nmeal for you",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: media.width * 0.05,
                  ),
                  const Spacer(),
                  Padding(
                      padding: EdgeInsets.only(bottom: media.height * 0.05),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: _isLoading
                            ? null // ปิดการใช้งานปุ่มขณะกำลังโหลด
                            : () async {
                                String selectedGoal = goalArr[selectedGoalIndex]["title"];
                                await saveGoalToDatabase(selectedGoal);
                              },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF325b51),
                            minimumSize: const Size(50, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 80),
                          ),
                          child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Update Your Goal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
