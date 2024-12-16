import 'package:flutter/material.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/widgets/profile_widget.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
        height: size.height, // กำหนดให้ Container ครอบคลุมหน้าจอทั้งหมด
        width: size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // รูปโปรไฟล์
            Container(
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Constants.primaryColor.withOpacity(.5),
                  width: 5.0,
                ),
              ),
              child: const CircleAvatar(
                radius: 60,
                backgroundImage: ExactAssetImage('assets/images/profile.jpg'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: size.width * .3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'John Doe',
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
              'johndoe@gmail.com',
              style: TextStyle(
                color: Constants.blackColor.withOpacity(.3),
              ),
            ),
            const SizedBox(height: 20),

            // เมนูโปรไฟล์
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ProfileWidget(
                    icon: Icons.person,
                    title: 'My Profile',
                  ),
                  ProfileWidget(
                    icon: Icons.settings,
                    title: 'Settings',
                  ),
                  ProfileWidget(
                    icon: Icons.notifications,
                    title: 'Notifications',
                  ),
                  ProfileWidget(
                    icon: Icons.chat,
                    title: 'FAQs',
                  ),
                  ProfileWidget(
                    icon: Icons.share,
                    title: 'Share',
                  ),
                  ProfileWidget(
                    icon: Icons.logout,
                    title: 'Log Out',
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
