import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/constants.dart';

class CustomTextfield extends StatelessWidget {
  final TextEditingController? controller;
  final FaIcon icon;
  final bool obscureText;
  final String hintText;
  final TextInputType? keyboardType;


  const CustomTextfield({
    Key? key,
    this.controller,
    required this.obscureText,
    required this.hintText,
    required this.icon,
    this.keyboardType,
  }) : super(key: key);
  

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only( left: 10 , right: 10), 
          child: FaIcon(
            icon.icon,
            color: Colors.grey.withOpacity(0.7), 
          ),
        ),
        SizedBox(width: 10),
         Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: TextStyle(
              color: Colors.black,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 2.0,
                ),
              ),
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
            cursorColor: Constants.blackColor.withOpacity(.5),
          ),
        ),
      ),
      ],
    );
  }
}