import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dukaan_diary/pages/contact_detail.dart';
import 'package:dukaan_diary/pages/add_contact_page.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  late Stream<QuerySnapshot> contactsStream;
  List<DocumentSnapshot> contacts = [];
  List<DocumentSnapshot> filteredContacts = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initContactsStream();
    
    searchController.addListener(() {
      _filterContacts();
    });
  }

  void _initContactsStream() {
    if (user != null) {
      contactsStream = FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .collection("contact")
          .orderBy('name')
          .snapshots();
          
      contactsStream.listen((snapshot) {
        setState(() {
          contacts = snapshot.docs;
          _filterContacts();
          isLoading = false;
        });
      }, onError: (error) {
        print("Error fetching contacts: $error");
        setState(() {
          isLoading = false;
        });
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterContacts() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredContacts = List.from(contacts);
      } else {
        filteredContacts = contacts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] as String?)?.toLowerCase() ?? '';
          final phone = (data['phone'] as String?)?.toLowerCase() ?? '';
          return name.contains(query) || phone.contains(query);
        }).toList();
      }
    });
  }

  void _viewContactDetails(DocumentSnapshot contact) {
    final data = contact.data() as Map<String, dynamic>;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailPage(
          contactId: contact.id,
          contact: {
            'name': data['name'] ?? '',
            'phone': data['phone'] ?? '',
            'email': data['email'] ?? '',
            'address': data['address'] ?? '',
          },
        ),
      ),
    );
  }

  Future<void> _addContact() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddContactPage(),
      ),
    );
    
    if (result == true) {
      // Contact was added successfully, no need to refresh as we're using streams
    }
  }

  Future<void> _deleteContact(String contactId) async {
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
            .doc(user!.uid)
            .collection('contact')
            .doc(contactId)
            .delete();
            
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting contact: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: MyAppBar(pageinfo: 'Contacts'),
        body: const Center(
          child: Text('Please login to view your contacts'),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: MyAppBar(pageinfo: 'Contacts'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: searchController,
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
          if (isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredContacts.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No contacts found',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = filteredContacts[index];
                  final data = contact.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Dismissible(
                      key: Key(contact.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        color: Colors.red,
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
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
                      },
                      onDismissed: (direction) {
                        _deleteContact(contact.id);
                      },
                      child: ListTile(
                        leading: const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.blue,
                        ),
                        title: Text(
                          data['name'] ?? 'No Name',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text("Phone: ${data['phone'] ?? 'No Phone'}"),
                        onTap: () => _viewContactDetails(contact),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

