import 'package:dukaan_diary/pages/add_employee.dart';
import 'package:dukaan_diary/pages/add_product_page.dart';
import 'package:dukaan_diary/pages/contact_page.dart';
import 'package:dukaan_diary/pages/home_page.dart';
import 'package:dukaan_diary/pages/profile_page.dart';
import 'package:flutter/material.dart';

class SelectedPage extends StatefulWidget {
  const SelectedPage({super.key});

  @override
  State<SelectedPage> createState() => _SelectedPageState();
}

class _SelectedPageState extends State<SelectedPage> {
  int _selectedIndex = 2; // Set home as the default selected index

  final List<Widget> _pages = [
    const ContactPage(),
    const AddEmployee(),
    const HomePages(),
    const AddProductPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: "Contacts",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_people_outlined),
            label: "Staff",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.production_quantity_limits),
            label: "Product",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
