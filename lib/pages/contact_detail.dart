import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dukaan_diary/pages/add_contact_page.dart';
import 'package:dukaan_diary/pages/add_transaction_page_contact.dart'; 
import 'package:dukaan_diary/pages/view_transactions_page.dart'; // Import for transactions page

class ContactDetailPage extends StatelessWidget {
  final String contactId;
  final Map<String, String> contact;
  
  const ContactDetailPage({
    super.key, 
    required this.contactId,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(pageinfo: 'Contact Details'),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Icon(Icons.person, size: 80, color: Colors.blue)),
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
              "Email: ${contact['email'] ?? 'Not provided'}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Address: ${contact['address'] ?? 'Not provided'}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Replace named route with direct navigation
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewTransactionsPage(
                          contactId: contactId,
                          contactName: contact['name'] ?? '',
                          phoneNumber: contact['phone'] ?? '',
                        ),
                      ),
                    );
                  },
                  child: const Text("View Transactions"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddTransactionPageContact(
                          contactId: contactId,
                          phoneNumber: contact['phone'] ?? '',
                        ),
                      ),
                    );
                  },
                  child: const Text("Add Transaction"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Edit Contact Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddContactPage(ContactId: contactId),
                    ),
                  );
                  
                  if (result == true) {
                    Navigator.pop(context); // Return to contact list after edit
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text("Edit Contact"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Delete Contact Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final User? user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;
                  
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Contact'),
                      content: const Text('Are you sure you want to delete this contact?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('contact')
                          .doc(contactId)
                          .delete();
                          
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contact deleted successfully')),
                      );
                      Navigator.pop(context); // Return to contact list
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting contact: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.delete),
                label: const Text("Delete Contact"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}