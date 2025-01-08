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
import 'package:food_project/services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();

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
      await firestore.collection('users').doc(user.userId).set(user.toMap());
      print('User saved successfully!');
    } catch (e) {
      print('Error saving user: $e');
    }
  }

  void showQuickAlert(BuildContext context, QuickAlertType type, String title, String text) {
    QuickAlert.show(
      context: context,
      type: type,
      title: title,
      text: text,
      confirmBtnText: 'OK',
      onConfirmBtnTap: () => Navigator.of(context).pop(),
    );
  }

  Future<void> handleGoogleSignIn(BuildContext context) async {
    try {
      User? user = await _authService.signUpWithGoogle();
      if (user != null) {
        String email = user.email ?? '';
        String userId = user.uid;
        String username = user.displayName ?? '';

        bool emailExists = await isEmailAlreadyRegistered(email);
        if (emailExists) {
          showQuickAlert(
            context,
            QuickAlertType.warning,
            'Email Already Registered',
            'This email is already in use. Please try with a different email.',
          );
          return;
        }

        UserModel newUser = UserModel(
          userId: userId,
          email: email,
          username: username,
          password: '',
        );
        await saveUserToFirestore(newUser);

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
    } catch (e) {
      showQuickAlert(
        context,
        QuickAlertType.error,
        'Error',
        'Failed to sign up with Google: ${e.toString()}',
      );
    }
  }

  void signUpUser(String email, String password, String username, BuildContext context) async {
    if (email.isEmpty || username.isEmpty || password.isEmpty) {
      showQuickAlert(context, QuickAlertType.error, 'Error', 'Email, Username, and Password cannot be empty');
      return;
    }

    if (password.length < 6) {
      showQuickAlert(context, QuickAlertType.warning, 'Warning', 'Password must be at least 6 characters');
      return;
    }

    if (await isUsernameAlreadyRegistered(username)) {
      showQuickAlert(context, QuickAlertType.warning, 'Warning', 'Username is already registered');
      return;
    }

    if (await isEmailAlreadyRegistered(email)) {
      showQuickAlert(context, QuickAlertType.warning, 'Warning', 'Email is already registered');
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
      if (e.code == 'email-already-in-use') {
        showQuickAlert(context, QuickAlertType.warning, 'Warning', 'Email is already registered');
      } else if (e.code == 'invalid-email') {
        showQuickAlert(context, QuickAlertType.error, 'Error', 'Invalid email format');
      } else {
        showQuickAlert(context, QuickAlertType.error, 'Error', 'An unknown error occurred: ${e.message}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/signup.png',
                width: size.width * 0.9,
                height: size.height * 0.4,
              ),
              const Text(
                'Sign Up',
                style: TextStyle(fontSize: 35.0, fontWeight: FontWeight.w700),
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
                    color: const Color(0xFF042628),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 25),
                  child: const Center(
                    child: Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
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
              GestureDetector(
                onTap: () => handleGoogleSignIn(context),
                child: Container(
                  width: size.width,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF042628)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 30,
                        child: Image.asset('assets/images/google.png'),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Sign Up with Google',
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
                )
          ]
          )
        )
      )
    );
              }
            }
