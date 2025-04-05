import 'package:flutter/material.dart';
class MyInputField extends StatelessWidget {
  final String heading;
  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final Icon? prefixIcon;
  final TextInputType? keyboardType;
  final int? maxLines;

  const MyInputField({
    Key? key,
    required this.heading,
    required this.controller,
    required this.hintText,
    this.enabled = true,
    this.prefixIcon,
    this.keyboardType,
    this.maxLines = 1,
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
              prefixIcon: prefixIcon,
            ),
          ),
        ],
      ),
    );
  }
}