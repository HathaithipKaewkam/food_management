import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

   String userName = '';
  String userEmail = '';
  String profileImage = ''; 

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
        print("📄 Document data: $data");
        
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

@override
void initState() {
  super.initState();
  _fetchUserName();
  _fetchProfileImage();
}
  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.only(top: 20, left: 10),
      child: ListView(
        children: [
          // ส่วนหัว (Settings)
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                color: Colors.black,
                iconSize: 20,
              ),
              const SizedBox(width: 110),
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 15), // เพิ่มระยะห่าง
          
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                   
                    child: CircleAvatar(
                      radius: 35,
                      backgroundImage: profileImage.isNotEmpty
                          ? _getProfileImageProvider()
                          : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                    ),
                  ),
                  const SizedBox(width: 15), 
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                    
                        Text(
                          userName.isNotEmpty ? userName : 'User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        
                        const SizedBox(height: 5), 
                        Text(
                          userEmail.isNotEmpty ? userEmail : '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 25),
          
          _buildSettingsAccount(),
          const SizedBox(height: 15),
          _buildSettings(),
          const SizedBox(height: 15),
           _buildHelp(),
        ],
      ),
    ),
  );
}

ImageProvider _getProfileImageProvider() {
  if (profileImage.startsWith('assets/')) {
    return AssetImage(profileImage);
  } else if (profileImage.startsWith('http')) {
    return NetworkImage(profileImage);
  } else if (profileImage.contains('data:image')) {
  
    String base64String = profileImage.split(',')[1];
    return MemoryImage(base64Decode(base64String));
  } else {
  
    return AssetImage('assets/images/default_profile.png');
  }
}


Widget _buildSettingsAccount() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
          padding: const EdgeInsets.only(top: 15 , left: 15),
          child: Text(
            'Account',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
              _buildSettingsTile(
                icon: Icons.person,
                title: 'Profile Data',
                onTap: () {
                 
                },
              ),
                _buildSettingsTile(
                icon: Icons.favorite,
                title: 'Favorite Foods',
                onTap: () {
                 
                },
              ),
                _buildSettingsTile(
                icon: Icons.warning_amber,
                title: 'Food Allergies',
                onTap: () {
                 
                },
              ),
             
              _buildSettingsTile(
                icon: Icons.flag,
                title: 'My Goal',
                onTap: () {
                
                },
              )
             
            ],
          ),
        ),
       
      ],
    ),
  );
}

Widget _buildSettings() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
          padding: const EdgeInsets.only(top: 15 , left: 15),
          child: Text(
            'Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
              _buildSettingsTile(
                icon: Icons.notifications,
                title: 'Notifications',
                onTap: () {
                 
                },
              ),
             
              _buildSettingsTile(
                icon: Icons.password,
                title: 'Change Password',
                onTap: () {
                
                },
              )
             
            ],
          ),
        ),
       
      ],
    ),
  );
}

Widget _buildHelp() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
          padding: const EdgeInsets.only(top: 15 , left: 15),
          child: Text(
            'Help',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
              _buildSettingsTile(
                icon: Icons.contact_support_outlined,
                title: 'Support and Feedback',
                onTap: () {
                 
                },
              ),
             
              _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {
                
                },
              )
             
            ],
          ),
        ),
       
      ],
    ),
  );
}

Widget _buildSettingsTile({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: Color(0xFF16a34a)),
    title: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    trailing: Icon(Icons.arrow_forward_ios, size: 18),
    onTap: onTap,
  );
}


}

