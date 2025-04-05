import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dukaan_diary/components/input_field.dart';
import 'package:dukaan_diary/components/my_app_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController gstNumberController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController businessTypeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isEditing = false;
  bool isLoading = true;
  User? user = FirebaseAuth.instance.currentUser;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    // Clean up controllers when the widget is disposed
    fullNameController.dispose();
    addressController.dispose();
    shopNameController.dispose();
    gstNumberController.dispose();
    phoneNumberController.dispose();
    businessTypeController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // Fetch user data from Firestore
  Future<void> _loadUserData() async {
    if (user != null) {
      try {
        setState(() {
          isLoading = true;
          errorMessage = '';
        });

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            fullNameController.text = data['name'] ?? "";
            addressController.text = data['address'] ?? "";
            shopNameController.text = data['shopName'] ?? "";
            gstNumberController.text = data['gstNumber'] ?? "";
            phoneNumberController.text = data['phone'] ?? "";
            businessTypeController.text = data['businessType'] ?? "";
            emailController.text = data['email'] ?? user!.email ?? "";
          });
        } else {
          // Set email from Firebase Auth if no document exists yet
          emailController.text = user!.email ?? "";
        }
      } catch (e) {
        setState(() {
          errorMessage = "Failed to load profile data. Please try again.";
        });
        print("Error fetching user data: $e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Update user data in Firestore
  Future<void> _updateUserData() async {
    if (user != null) {
      try {
        setState(() {
          isLoading = true;
          errorMessage = '';
        });

        // Validate required fields
        if (fullNameController.text.trim().isEmpty || 
            phoneNumberController.text.trim().isEmpty) {
          setState(() {
            errorMessage = "Name and phone number are required";
            isLoading = false;
          });
          return;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .set({
              'name': fullNameController.text.trim(),
              'address': addressController.text.trim(),
              'shopName': shopNameController.text.trim(),
              'gstNumber': gstNumberController.text.trim(),
              'phone': phoneNumberController.text.trim(),
              'businessType': businessTypeController.text.trim(),
              'email': emailController.text.trim(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        setState(() {
          isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        setState(() {
          errorMessage = "Failed to update profile. Please try again.";
        });
        print("Error updating user data: $e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Logout function
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  setState(() {
                    isLoading = true;
                  });
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                  }
                } catch (e) {
                  setState(() {
                    isLoading = false;
                    errorMessage = "Failed to log out. Please try again.";
                  });
                  print("Logout Error: $e");
                }
              },
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: MyAppBar(pageinfo: isEditing ? 'Edit Profile' : 'My Profile'),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profile header section
          _buildProfileHeader(),
          
          // Error message if any
          if (errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          
          // Profile form
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Personal Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildProfileFields(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          _buildActionButtons(),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: const AssetImage('lib/images/profile_pic.png'),
                  backgroundColor: Colors.grey[200],
                ),
              ),
              if (isEditing)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      // Image picker functionality would go here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Profile photo update not implemented"),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fullNameController.text.isNotEmpty 
                ? fullNameController.text 
                : "Complete Your Profile",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (shopNameController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                shopNameController.text,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileFields() {
    return Column(
      children: [
        MyInputField(
          heading: 'Full Name*',
          controller: fullNameController,
          hintText: 'Enter Full Name',
          enabled: isEditing,
          prefixIcon: const Icon(Icons.person),
        ),
        MyInputField(
          heading: 'Email',
          controller: emailController,
          hintText: 'Enter Email',
          enabled: isEditing,
          prefixIcon: const Icon(Icons.email),
          keyboardType: TextInputType.emailAddress,
        ),
        MyInputField(
          heading: 'Phone Number*',
          controller: phoneNumberController,
          hintText: 'Enter Phone Number',
          enabled: isEditing,
          prefixIcon: const Icon(Icons.phone),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        const Text(
          "Business Information",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(height: 24),
        MyInputField(
          heading: 'Shop Name',
          controller: shopNameController,
          hintText: 'Enter Shop Name',
          enabled: isEditing,
          prefixIcon: const Icon(Icons.store),
        ),
        MyInputField(
          heading: 'Business Type',
          controller: businessTypeController,
          hintText: 'Enter Business Type',
          enabled: isEditing,
          prefixIcon: const Icon(Icons.category),
        ),
        MyInputField(
          heading: 'GST Number',
          controller: gstNumberController,
          hintText: 'Enter GST Number',
          enabled: isEditing,
          prefixIcon: const Icon(Icons.receipt),
        ),
        MyInputField(
          heading: 'Address',
          controller: addressController,
          hintText: 'Enter Address',
          enabled: isEditing,
          prefixIcon: const Icon(Icons.location_on),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            label: Text(
              isEditing ? 'Save Profile' : 'Edit Profile',
              style: const TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: isEditing ? _updateUserData : () {
              setState(() {
                isEditing = true;
              });
            },
          ),
        ),
        if (isEditing)
          TextButton(
            onPressed: () {
              setState(() {
                isEditing = false;
                _loadUserData(); // Reload original data
                errorMessage = '';
              });
            },
            child: const Text('Cancel Editing'),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text(
            'Log Out',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _logout,
        ),
      ],
    );
  }
}