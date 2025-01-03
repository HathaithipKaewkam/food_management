import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_project/constants.dart';

class PasswordTextfield extends StatefulWidget {
  final TextEditingController? controller;
  final FaIcon icon;
  final bool obscureText;
  final String hintText;

  const PasswordTextfield({
    Key? key,
    this.controller,
    required this.obscureText,
    required this.hintText,
    required this.icon,
  }) : super(key: key);

  @override
  _PasswordTextfieldState createState() => _PasswordTextfieldState();
}

class _PasswordTextfieldState extends State<PasswordTextfield> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText; 
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: FaIcon(
            widget.icon.icon,
            color: Colors.grey.withOpacity(0.7),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: TextField(
            controller: widget.controller,
            obscureText: _obscureText,
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
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
              suffixIcon:
              Padding(padding: const EdgeInsets.only(bottom: 5),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _obscureText = !_obscureText; 
                  });
                },
                child: Icon(
                  _obscureText
                      ? FontAwesomeIcons.eyeSlash
                      : FontAwesomeIcons.eye, 
                  color: Colors.grey.withOpacity(0.7),
                ),
              ),
              ) 
            ),
            cursorColor: Constants.blackColor.withOpacity(.5),
          ),
        ),
        ),
      ],
    );
  }
}
