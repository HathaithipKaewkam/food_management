import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/constants.dart';
import 'package:food_project/models/user_model.dart';
import 'package:food_project/screens/login/complete_profile.dart';
import 'package:food_project/screens/login/signin_screen.dart';
import 'package:food_project/widgets/custom_textfield.dart';
import 'package:food_project/widgets/password_textfield.dart';
import 'package:page_transition/page_transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:food_project/services/auth_service.dart';  // นำเข้า AuthService

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();  // สร้างตัวแปร AuthService

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String hashPassword(String password) {
    var bytes = utf8.encode(password); 
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> isEmailAlreadyRegistered(String email) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    return result.docs.isNotEmpty;
  }

  Future<bool> isUsernameAlreadyRegistered(String username) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    return result.docs.isNotEmpty;
  }

  Future<void> saveUserToFirestore(UserModel user) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String userId = user.userId;  
      await firestore.collection('users').doc(userId).set(user.toMap()); 
      print('User saved successfully!');
    } catch (e) {
      print('Error saving user: $e');
    }
  }

  void signUpUser(
    String email, 
    String password,
    String username, 
    BuildContext context) async {
    if (email.isEmpty || username.isEmpty || password.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Email, Username, and Password cannot be empty',
        confirmBtnText: 'OK',
        onConfirmBtnTap: () {
          Navigator.of(context).pop(); 
        },
      );
      return;
    }

    if (password.length < 6) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Warning',
        text: 'Password must be at least 6 characters',
        confirmBtnText: 'OK',
        onConfirmBtnTap: () {
          Navigator.of(context).pop(); 
        },
      );
      return;
    }

    if (await isUsernameAlreadyRegistered(username)) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Warning',
        text: 'Username is already registered',
        confirmBtnText: 'OK',
        onConfirmBtnTap: () {
          Navigator.of(context).pop(); 
        },
      );
      return;
    }

    if (await isEmailAlreadyRegistered(email)) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Warning',
        text: 'Email is already registered',
        confirmBtnText: 'OK',
        onConfirmBtnTap: () {
          Navigator.of(context).pop(); 
        },
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      
      var user = await _authService.signUp(email, password); 

      if (user != null) {
        String hashedPassword = hashPassword(password);

        UserModel newUser = UserModel(
          userId: user.uid,
          email: email,
          username: username,
          password: hashedPassword,
        );

        await saveUserToFirestore(newUser);

        Navigator.pop(context); 

        QuickAlert.show(
          context: context, 
          type: QuickAlertType.success,
          title: 'Success',
          text: 'Sign Up Successful',
          confirmBtnColor: const Color(0xFF325b51),
          confirmBtnText: 'OK',
          onConfirmBtnTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const CompleteProfile(),
              ),
            );
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign Up Failed: ${e.message}')),
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
                'assets/images/signup.png',
                width: size.width * 0.9,
                height: size.height * 0.4,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 0),
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 35.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              CustomTextfield(
                controller: emailController,
                obscureText: false,
                hintText: 'Enter Email',
                icon: FaIcon(FontAwesomeIcons.at),
              ),
              CustomTextfield(
                controller: usernameController,
                obscureText: false,
                hintText: 'Enter Username',
                icon: FaIcon(FontAwesomeIcons.solidUser),
              ),
              PasswordTextfield(
                controller: passwordController,
                obscureText: true,
                hintText: 'Enter Password',
                icon: FaIcon(FontAwesomeIcons.lock),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  signUpUser(
                    emailController.text,
                    passwordController.text,
                    usernameController.text,
                    context,
                  );
                },
                child: Container(
                  width: size.width,
                  decoration: BoxDecoration(
                    color: Color(0xFF042628),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 25),
                  child: const Center(
                    child: Text(
                      'Sign Up',
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
                  border: Border.all(
                    color: Color(0xFF042628)),
                  borderRadius: BorderRadius.circular(15),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 30,
                      child: Image.asset('assets/images/google.png'),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Sign Up with Google',
                      style: TextStyle(
                        color: Constants.blackColor,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    PageTransition(
                      child: const SignInScreen(),
                      type: PageTransitionType.bottomToTop,
                    ),
                  );
                },
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Already have an Account ? ',
                          style: TextStyle(
                            color: Constants.blackColor,
                          ),
                        ),
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(
                            color: Color(0xFF042628),
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
      ),
    );
  }
}
