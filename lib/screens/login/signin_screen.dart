import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/screens/login/forget_password.dart';
import 'package:food_project/screens/login/signup_screen.dart';
import 'package:food_project/screens/root_screen.dart';
import 'package:food_project/services/auth_service.dart';
import 'package:food_project/widgets/custom_textfield.dart';
import 'package:food_project/widgets/password_textfield.dart';
import 'package:page_transition/page_transition.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  void signInUser(String email, String password, BuildContext context) async {
  if (email.isEmpty || password.isEmpty) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Error',
      text: 'Email and Password cannot be empty',
      confirmBtnText: 'OK',
      onConfirmBtnTap: () {
        Navigator.of(context).pop();
      },
    );
    return;
  }

  if (!RegExp(r"^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Invalid Email Format',
      text: 'Please enter a valid email address.',
      confirmBtnText: 'OK',
      onConfirmBtnTap: () {
        Navigator.of(context).pop();
      },
    );
    return;
  }

  try {
    // ลงชื่อเข้าใช้ Firebase ด้วยอีเมลและรหัสผ่าน
    User? user = await _authService.signIn(email, password);

    if (user == null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Sign In Failed',
        text: 'Authentication failed. Please check your credentials.',
        confirmBtnText: 'OK',
        onConfirmBtnTap: () {
          Navigator.of(context).pop();
        },
      );
      return;
    }

    bool isInFirestore = await _authService.isUserInFirestore(user.uid);

    if (!isInFirestore) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Access Denied',
        text: 'This account is not authorized to log in.',
        confirmBtnText: 'OK',
        onConfirmBtnTap: () {
          Navigator.of(context).pop();
          FirebaseAuth.instance.signOut(); 
        },
      );
      return;
    }

    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: 'Sign In Successful',
      text: 'Welcome back!',
      confirmBtnText: 'OK',
      onConfirmBtnTap: () {
        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          PageTransition(
            child: const RootPage(),
            type: PageTransitionType.bottomToTop,
          ),
        );
      },
    );
  } on FirebaseAuthException catch (e) {
    String errorMessage;
    QuickAlertType alertType = QuickAlertType.error;

    if (e.code == 'user-not-found') {
      errorMessage = 'This email is not registered.';
      alertType = QuickAlertType.warning;
    } else if (e.code == 'wrong-password') {
      errorMessage = 'Incorrect password. Please try again.';
      alertType = QuickAlertType.error;
    } else if (e.code == 'invalid-credential' || e.code == 'expired-action-code') {
      errorMessage = 'The supplied auth credential is incorrect, malformed, or expired.';
      alertType = QuickAlertType.error;
    } else {
      errorMessage = 'An unknown error occurred:: ${e.message}';
    }

    QuickAlert.show(
      context: context,
      type: alertType,
      title: 'Sign In Failed',
      text: errorMessage,
      confirmBtnText: 'OK',
      onConfirmBtnTap: () {
        Navigator.of(context).pop();
      },
    );
  } catch (e) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Sign In Failed',
      text: "An error occurred: ${e.toString()}",
      confirmBtnText: 'OK',
      onConfirmBtnTap: () {
        Navigator.of(context).pop();
      },
    );
  }
}




  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 30,
          left: 20,
          right: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/signin.png',
              width: size.width * 0.9,
              height: size.height * 0.4,
            ),
            const Padding(
              padding: EdgeInsets.only(top: 0),
              child: Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 35.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            CustomTextfield(
              controller: emailController,
              obscureText: false,
              hintText: 'Enter Email',
              icon: FaIcon(FontAwesomeIcons.at),
            ),
            PasswordTextfield(
              controller: passwordController,
              obscureText: true,
              hintText: 'Enter Password',
              icon: FaIcon(FontAwesomeIcons.lock),
            ),
            const SizedBox(height: 20),
            GestureDetector(
                onTap: () {
                signInUser(
                  emailController.text,
                  passwordController.text,
                  context,
                );
              },
              child: Container(
                width: size.width,
                decoration: BoxDecoration(
                  color: Color(0xFF042628),
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 25),
                child: const Center(
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  PageTransition(
                    child: ForgotPassword(),
                    type: PageTransitionType.bottomToTop,
                  ),
                );
              },
              child: Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Forgot Password ? ',
                        style: TextStyle(color: Constants.blackColor),
                      ),
                      TextSpan(
                        text: 'Reset Here',
                        style: TextStyle(color:Color(0xFF042628),
                        fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('OR'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: size.width,
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF042628)),
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              child: GestureDetector(
                  onTap: () async {
                    User? user = await _authService.signInWithGoogle();

                    if (user != null) {
                      QuickAlert.show(
                        context: context,
                        type: QuickAlertType.success,
                        title: 'Sign In Successful',
                        text: 'Welcome back, ${user.displayName ?? user.email}!',
                        confirmBtnText: 'OK',
                        onConfirmBtnTap: () {
                          Navigator.of(context).pop();
                          Navigator.pushReplacement(
                            context,
                            PageTransition(
                              child: const RootPage(),
                              type: PageTransitionType.bottomToTop,
                            ),
                          );
                        },
                      );
                    } else {
                      QuickAlert.show(
                        context: context,
                        type: QuickAlertType.error,
                        title: 'Sign In Failed',
                        text: 'This account is not registered.',
                        confirmBtnText: 'OK',
                        onConfirmBtnTap: () {
                          Navigator.of(context).pop();
                        },
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 30,
                        child: Image.asset('assets/images/google.png'),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Sign In with Google',
                        style: TextStyle(
                          color: Constants.blackColor,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  PageTransition(
                    child: const SignUpScreen(),
                    type: PageTransitionType.bottomToTop,
                  ),
                );
              },
              child: Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "Don't have any account ? ",
                        style: TextStyle(color: Constants.blackColor),
                      ),
                      TextSpan(
                        text: 'Sign up now!',
                        style: TextStyle(color: Color(0xFF042628),
                        fontWeight: FontWeight.bold
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
    )
    );
  }
}
