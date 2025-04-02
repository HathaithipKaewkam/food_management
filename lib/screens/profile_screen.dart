import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/widgets/profile_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = '';
  String userEmail = '';
  String profileImage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchProfileImage();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // อัปเดตอีเมลจาก Firebase Auth
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
      setState(() {
        userEmail = user.email ?? 'No email';
      });

      try {
        DocumentSnapshot profileDoc = await FirebaseFirestore.instance
            .collection('userProfiles')
            .doc(user.uid)
            .get();

        if (profileDoc.exists && profileDoc['profileImage'] != null) {
          setState(() {
            profileImage = profileDoc['profileImage'];
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    } else {
      print("User not logged in");
    }
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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 20, left: 0),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Padding(padding: const EdgeInsets.only(left: 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
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
                  ),
                   const SizedBox(width: 105),
                  Container(
                    width: 70,
                    height: 70,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25), 
                      child: Image.network(
                        profileImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/profile_women.png',
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              
            ),
           
           
          ],
        ),
      ),
    );
  }
}
