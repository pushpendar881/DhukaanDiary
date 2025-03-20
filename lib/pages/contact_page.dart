import 'package:dukaan_diary/components/contact_card.dart';
import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final List<String> names = ['Alice', 'Bob', 'Charlie'];
  final List<String> descriptions = ['Friend', 'Colleague', 'Family'];
  final List<String> phoneNumbers = ['1234567890', '0987654321', '1122334455'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(shopname: 'Shop name', pageinfo: 'Contacts'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search",
                hintStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                prefixIcon: const Icon(Icons.search_outlined, size: 30),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: names.length,
              itemBuilder: (context, index) {
                return ContactCard(
                  name: names[index],
                  description: descriptions[index],
                  phoneNumber: phoneNumbers[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
