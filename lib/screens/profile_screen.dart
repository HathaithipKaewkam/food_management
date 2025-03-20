import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/widgets/profile_widget.dart';
import 'package:food_project/screens/login/signin_screen.dart';
import 'package:page_transition/page_transition.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;
  bool _isLoading = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _refreshUserData();
  }

  Future<void> _refreshUserData() async {
    _user = _auth.currentUser!;
    await _user.reload();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> logoutUser() async {
    bool confirmLogout = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Logout"),
            content: const Text("Are you sure you want to log out?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Log Out"),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmLogout) {
      setState(() {
        _isLoggingOut = true;
      });

      await _auth.signOut();

      setState(() {
        _isLoggingOut = false;
      });

      Navigator.pushReplacement(
        context,
        PageTransition(
          child: const SignInScreen(),
          type: PageTransitionType.fade,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('userProfiles') // Keep userProfiles for profile image
            .doc(_user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User data not found"));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          // Fetch username from 'users' collection
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users') // Fetch username from 'users'
                .doc(_user.uid)
                .snapshots(),
            builder: (context, usernameSnapshot) {
              if (usernameSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!usernameSnapshot.hasData || !usernameSnapshot.data!.exists) {
                return const Center(child: Text("Username data not found"));
              }

              final usernameData =
                  usernameSnapshot.data!.data() as Map<String, dynamic>;

              String defaultProfileImage = "assets/images/default_profile.png";
              if (userData['gender'] == 'Male') {
                defaultProfileImage = "assets/images/profile_men.png";
              } else if (userData['gender'] == 'Female') {
                defaultProfileImage = "assets/images/profile_women.png";
              }

              return Container(
                padding: const EdgeInsets.only(
                    top: 100, left: 16, right: 16, bottom: 16),
                height: size.height,
                width: size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Constants.primaryColor.withOpacity(.5),
                          width: 5.0,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: userData['profilePictureUrl'] !=
                                    null &&
                                userData['profilePictureUrl'].startsWith('http')
                            ? NetworkImage(userData['profilePictureUrl'])
                            : AssetImage(defaultProfileImage) as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: size.width * .3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            usernameData['username'] ??
                                "username", // Fetch username from 'users' collection
                            style: TextStyle(
                              color: Constants.blackColor,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(width: 5),
                          SizedBox(
                            height: 24,
                            child: Image.asset("assets/images/verified.png"),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      userData['email'] ?? _user.email ?? "email@example.com",
                      style: TextStyle(
                        color: Constants.blackColor.withOpacity(.3),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            // onTap: () {
                            //   // เมื่อคลิก "My Profile" ให้ไปที่หน้า MyProfileScreen
                            //   Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //       // builder: (context) => const MyProfileScreen(),
                            //     ),
                            //   );
                            // },
                            child: const ProfileWidget(
                                icon: Icons.person, title: 'My Profile'),
                          ),
                          const ProfileWidget(
                              icon: Icons.settings, title: 'Settings'),
                          const ProfileWidget(
                              icon: Icons.notifications,
                              title: 'Notifications'),
                          const ProfileWidget(icon: Icons.chat, title: 'FAQs'),
                          const ProfileWidget(
                              icon: Icons.share, title: 'Share'),
                          GestureDetector(
                            onTap: logoutUser,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isLoggingOut
                                    ? Colors.red.shade700
                                    : Colors.red,
                                boxShadow: _isLoggingOut
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text(
                                    'Log Out',
                                    style: TextStyle(
                                      color: Colors.white,
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
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
