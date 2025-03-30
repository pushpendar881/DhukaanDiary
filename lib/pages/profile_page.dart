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
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ✅ Firestore se user data fetch karna
  Future<void> _loadUserData() async {
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .get();

        if (userDoc.exists) {
          setState(() {
            fullNameController.text = userDoc['name'] ?? "";
            addressController.text = userDoc['address'] ?? "";
            shopNameController.text = userDoc['shopName'] ?? "";
            gstNumberController.text = userDoc['gstNumber'] ?? "";
            phoneNumberController.text = userDoc['phone'] ?? "";
            businessTypeController.text = userDoc['businessType'] ?? "";
            emailController.text =  emailController.text.isEmpty ? user!.email ?? "" : emailController.text;
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
  }

  // ✅ Firestore me data update karna
  Future<void> _updateUserData() async {
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .set({
              'name': fullNameController.text,
              'address': addressController.text,
              'shopName': shopNameController.text,
              'gstNumber': gstNumberController.text,
              'phone': phoneNumberController.text,
              'businessType': businessTypeController.text,
              'email': emailController.text,
            }, SetOptions(merge: true));

        setState(() {
          isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile Updated Successfully!")),
        );
      } catch (e) {
        print("Error updating user data: $e");
      }
    }
  }

  // ✅ Logout function
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      print("User logged out successfully!");

      // Home ya Login screen pe bhejne ka correct method
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      print("Logout Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout Failed! Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar( pageinfo: 'Edit Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('lib/images/profile_pic.png'),
              ),
            ),
            const SizedBox(height: 20),
            MyInputField(
              heading: 'Full Name',
              controller: fullNameController,
              hintText: 'Enter Full Name',
              enabled: isEditing || fullNameController.text.isEmpty,
            ),
            MyInputField(
              heading: 'Address',
              controller: addressController,
              hintText: 'Enter Address',
              enabled: isEditing || addressController.text.isEmpty,
            ),
            MyInputField(
              heading: 'Shop Name',
              controller: shopNameController,
              hintText: 'Enter Shop Name',
              enabled: isEditing || shopNameController.text.isEmpty,
            ),
            MyInputField(
              heading: 'GST Number',
              controller: gstNumberController,
              hintText: 'Enter GST Number',
              enabled: isEditing || gstNumberController.text.isEmpty,
            ),
            MyInputField(
              heading: 'Phone Number',
              controller: phoneNumberController,
              hintText: 'Enter Phone Number',
              enabled: isEditing || phoneNumberController.text.isEmpty,
            ),
            MyInputField(
              heading: 'Business Type',
              controller: businessTypeController,
              hintText: 'Enter Business Type',
              enabled: isEditing || businessTypeController.text.isEmpty,
            ),
            MyInputField(
              heading: 'Email',
              controller: emailController,
              hintText: 'Enter Email',
              enabled: isEditing || emailController.text.isEmpty,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                isEditing
                    ? ElevatedButton(
                      onPressed: _updateUserData,
                      child: const Text('Save', style: TextStyle(fontSize: 18)),
                    )
                    : ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isEditing = true;
                        });
                      },
                      child: const Text('Edit', style: TextStyle(fontSize: 18)),
                    ),
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Log Out', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
