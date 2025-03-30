import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final List<Map<String, String>> contacts = [
    {
      'name': 'Alice',
      'phone': '1234567890',
      'email': 'alice@example.com',
      'address': 'Mumbai',
    },
    {
      'name': 'Bob',
      'phone': '0987654321',
      'email': 'bob@example.com',
      'address': 'Delhi',
    },
    {
      'name': 'Charlie',
      'phone': '1122334455',
      'email': 'charlie@example.com',
      'address': 'Bangalore',
    },
  ];

  void _viewContactDetails(Map<String, String> contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailPage(contact: contact),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: MyAppBar( pageinfo: 'Contacts'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Contacts",
                prefixIcon: const Icon(Icons.search, size: 30),
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
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.blue,
                    ),
                    title: Text(
                      contacts[index]['name']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text("Phone: ${contacts[index]['phone']}"),
                    onTap: () => _viewContactDetails(contacts[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_contact_page');
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class ContactDetailPage extends StatelessWidget {
  final Map<String, String> contact;
  const ContactDetailPage({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar( pageinfo: 'Contact Details'),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Icon(Icons.person, size: 80, color: Colors.blue)),
            const SizedBox(height: 20),
            Text(
              "Name: ${contact['name']}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Phone: ${contact['phone']}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Email: ${contact['email']}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Address: ${contact['address']}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/view_transactions_page',
                      arguments: contact['phone'],
                    );
                  },
                  child: const Text("View Transactions"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/add_transaction_page',
                      arguments: contact['phone'],
                    );
                  },
                  child: const Text("Add Transaction"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
