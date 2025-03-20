import 'package:flutter/material.dart';

class MyListTile extends StatelessWidget {
  final int index;
  const MyListTile({super.key,required this.index});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.person, color: Colors.blue),
      title: Text(
        ' Name of Shop to pay',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Transaction details here: ${index % 2 == 0 ? "Cash" : "UPI"}',
        style: const TextStyle(fontSize: 14),
      ),
      
    );
    ;
  }
}
