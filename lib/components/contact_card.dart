import 'package:flutter/material.dart';

class ContactCard extends StatelessWidget {
  final String name;
  final String description;
  final String phoneNumber;

  const ContactCard({
    super.key,
    required this.name,
    required this.description,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          '$description\nPhone: $phoneNumber',
          style: const TextStyle(fontSize: 14),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: Colors.green),
          onPressed: () {
            // Placeholder for calling functionality
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Calling $phoneNumber...')),
            );
          },
        ),
      ),
    );
  }
}
