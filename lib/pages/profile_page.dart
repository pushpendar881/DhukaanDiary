import 'package:dukaan_diary/components/input_field.dart';
import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(shopname: 'Shop Name', pageinfo: 'Edit Profile'),
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
            ),
            MyInputField(
              heading: 'Address',
              controller: addressController,
              hintText: 'Enter Address',
            ),
            MyInputField(
              heading: 'Shop Name',
              controller: shopNameController,
              hintText: 'Enter Shop Name',
            ),
            MyInputField(
              heading: 'GST Number',
              controller: gstNumberController,
              hintText: 'Enter GST Number',
            ),
            MyInputField(
              heading: 'Phone Number',
              controller: phoneNumberController,
              hintText: 'Enter Phone Number',
            ),
            MyInputField(
              heading: 'Business Type',
              controller: businessTypeController,
              hintText: 'Enter Business Type',
            ),
            MyInputField(
              heading: 'Email',
              controller: emailController,
              hintText: 'Enter Email',
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Save', style: TextStyle(fontSize: 18)),
                ),
                ElevatedButton(
                  onPressed: () {},
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
