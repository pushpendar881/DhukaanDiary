import 'package:flutter/material.dart';

class MyInputField extends StatelessWidget {
  final String heading;
  final TextEditingController controller;
  final String hintText;
  final bool enabled; // ✅ Add this parameter

  const MyInputField({
    Key? key,
    required this.heading,
    required this.controller,
    required this.hintText,
    this.enabled = true, // ✅ Default true
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          TextField(
            controller: controller,
            enabled: enabled, // ✅ Fix: Enable/Disable Editing
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
