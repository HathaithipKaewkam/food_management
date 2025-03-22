import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_project/screens/login/signin_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:food_project/widgets/custom_textfield.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quickalert/quickalert.dart';

class ForgotPassword extends StatefulWidget {
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isEmailSent = false; // เพิ่มตัวแปรเพื่อตรวจสอบว่าอีเมลส่งแล้วหรือยัง

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void resetPassword(BuildContext context) async {
    String email = emailController.text.trim();

    // ✅ ตรวจสอบว่าอีเมลอยู่ในรูปแบบที่ถูกต้องหรือไม่
    if (email.isEmpty ||
        !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
            .hasMatch(email)) {
      // ✅ ใช้ QuickAlert แจ้งเตือนเมื่ออีเมลไม่ถูกต้อง
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Invalid Email',
        text: 'Please enter a valid email address.',
        confirmBtnText: 'OK',
        confirmBtnColor: Colors.black,
      );
      return;
    }

    // แสดง Loading Indicator
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ));

    try {
      // ✅ ตรวจสอบว่าอีเมลเคยลงทะเบียนหรือไม่
      List<String> signInMethods =
          await _auth.fetchSignInMethodsForEmail(email);
      if (signInMethods.isEmpty) {
        Navigator.pop(context); // ปิด Loading Dialog

        // ✅ ใช้ QuickAlert แจ้งเตือนเมื่ออีเมลไม่มีในระบบ
        QuickAlert.show(
          context: context,
          type: QuickAlertType.warning,
          title: 'Email Not Found',
          text: 'This email is not registered.',
          confirmBtnText: 'OK',
          confirmBtnColor: Colors.black,
        );
        return;
      }

      // ✅ ถ้าอีเมลมีอยู่แล้วให้ส่งลิงก์รีเซ็ตรหัสผ่าน
      await _auth.sendPasswordResetEmail(email: email);
      Navigator.pop(context); // ปิด Loading Dialog

      // ✅ ใช้ QuickAlert แจ้งเตือนเมื่อส่งลิงก์สำเร็จ
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'Email Sent!',
        widget: Column(
          children: [
            // const Text(
            //   'Email Sent!',
            //   style: TextStyle(
            //     fontSize: 20,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(color: Colors.black, fontSize: 16),
                children: [
                  const TextSpan(
                      text: 'A password reset link has been sent to '),
                  TextSpan(
                    text: email,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // const TextSpan(text: '.\nCheck your inbox.'),
                ],
              ),
            ),
          ],
        ),
        confirmBtnText: 'OK',
        confirmBtnColor: Colors.black,
        onConfirmBtnTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignInScreen()),
          );
        },
      );
    } catch (e) {
      Navigator.pop(context); // ปิด Loading Dialog ถ้ามีข้อผิดพลาด
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: e.toString(),
        confirmBtnText: 'OK',
        confirmBtnColor: Colors.black,
      );
    }
  }

  Future<void> resendEmail(BuildContext context, String email) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _auth.sendPasswordResetEmail(email: email);
      Navigator.pop(context); // ปิด Loading Dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset link resent! Check your inbox.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/images/reset-password.png'),
              const Text(
                'Forgot Password',
                style: TextStyle(fontSize: 35.0, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              CustomTextfield(
                controller: emailController,
                obscureText: false,
                hintText: 'Enter Email',
                icon: const FaIcon(FontAwesomeIcons.at),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => resetPassword(context),
                child: Container(
                  width: size.width,
                  decoration: BoxDecoration(
                    color: const Color(0xFF042628),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 25),
                  child: const Center(
                    child: Text(
                      'Reset Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      PageTransition(
                        child: const SignInScreen(),
                        type: PageTransitionType.bottomToTop,
                      ),
                    );
                  }
                },
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Have an Account? ',
                          style: TextStyle(color: Colors.black),
                        ),
                        const TextSpan(
                          text: 'Login',
                          style: TextStyle(
                            color: Color(0xFF042628),
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
