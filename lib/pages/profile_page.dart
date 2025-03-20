import 'package:dukaan_diary/components/input_field.dart';
import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final shop_name_controller = TextEditingController();
  final shop_password_controller = TextEditingController();
  final shop_phone_number_controller = TextEditingController();
  bool isToggled = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(shopname: 'Shop Name', pageinfo: 'Edit Profile'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(child: Image.asset('lib/images/profile_pic.png')),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    'Notifications',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 35.0),
                  child: Switch(
                    activeColor: Colors.blue[700],
                    value: isToggled,
                    onChanged: (value) {
                      setState(() {
                        isToggled = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            MyInputField(
              heading: 'Shop Name',
              controller: shop_name_controller,
              hintText: 'Enter Shop Name',
            ),
            MyInputField(
              heading: 'Password',
              controller: shop_password_controller,
              hintText: 'Change Shop Password',
            ),
            MyInputField(
              heading: 'Phone  Number',
              controller: shop_phone_number_controller,
              hintText: 'Enter Shop Phone Number',
            ),
            Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      decoration: BoxDecoration(color: Colors.blue),
                      child: Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 25),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      decoration: BoxDecoration(color: Colors.red),
                      child: Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
