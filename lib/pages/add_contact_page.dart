import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddContactPage extends StatefulWidget {
  final String? ContactId;
  const AddContactPage({super.key, this.ContactId});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = false;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.ContactId != null) {
      isEditing = true;
      _loadContactData();
    }
  }

  Future<void> _loadContactData() async {
    if (user == null) return;
    setState(() {
      isLoading = true;
    });
    try {
      DocumentSnapshot contactDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .collection("contact")
          .doc(widget.ContactId)
          .get();
      if (contactDoc.exists) {
        Map<String, dynamic> data = contactDoc.data() as Map<String, dynamic>;
        nameController.text = data['name'] ?? '';
        phoneController.text = data['phone'] ?? '';
        emailController.text = data['email'] ?? '';
        addressController.text = data['address'] ?? '';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contact not found")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error loading contact data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading contact data: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveContact() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You need to be logged in to save contacts")),
      );
      return;
    }

    String name = nameController.text.trim();
    String phone = phoneController.text.trim();
    String email = emailController.text.trim();
    String address = addressController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Phone Number are required!")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final contactData = {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!isEditing) {
        // Add createdAt only for new contacts
        contactData['createdAt'] = FieldValue.serverTimestamp();
      }

      if (isEditing && widget.ContactId != null) {
        // Update existing contact
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .collection("contact")
            .doc(widget.ContactId)
            .update(contactData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contact updated successfully!")),
        );
      } else {
        // Create new contact
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .collection("contact")
            .add(contactData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contact added successfully!")),
        );
      }
      
      Navigator.pop(context, true); // Return true to indicate a successful operation
    } catch (e) {
      print("Error saving contact: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving contact: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(pageinfo: isEditing ? 'Edit Contact' : 'Add Contact'),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Full Name"),
                    ),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: "Phone Number"),
                    ),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: "Email (Optional)"),
                    ),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: "Address (Optional)"),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _saveContact,
                          child: Text(isEditing ? "Update" : "Save"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text("Cancel"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}